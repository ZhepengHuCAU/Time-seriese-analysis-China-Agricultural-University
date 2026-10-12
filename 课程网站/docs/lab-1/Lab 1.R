# Lab 1：Brent价格、ARMA与GARCH ==============================================
# 使用方法：把工作目录设为含 lab 1.csv 的课程文件夹，逐段选中代码，Ctrl+Enter运行。
# 每个模型分别估计，便于对照其设定与结果。
# 分析流程：平稳性与结构变化 → ACF/PACF → 均值选阶 → ARCH检验 → GARCH → 预测。
# <- 表示赋值；$ 表示取出某一列；c()把几个数放在一起；#后面的文字是注释。

# 0. 安装和加载包 -----------------------------------------------------------
# 第一次使用时，去掉下一行开头的#，运行一次。以后不用重复安装。
# install.packages(c("forecast", "rugarch", "strucchange", "sandwich", "FinTS", "urca", "xts"))


library(forecast)
library(rugarch)
library(strucchange)
library(sandwich)
library(FinTS)
library(urca)
library(xts)
set.seed(123)

# 1. 读入数据、计算收益率 ----------------------------------------------------
data <- read.csv("lab 1.csv", fileEncoding = "UTF-8-BOM")
head(data)                              # 看前6行
str(data)                               # 看变量名称和类型
summary(data)                           # 看基本统计量

data$Date <- as.Date(data$Date, format = "%m/%d/%Y")  # 月/日/年
data <- data[order(data$Date), ]         # 按时间排序
sum(is.na(data))                        # 应为0，表示没有缺失值
sum(duplicated(data$Date))               # 应为0，表示日期没有重复
min(data$Brent)                         # 必须>0，才能取对数
stopifnot(!anyNA(data), !anyDuplicated(data$Date), all(data$Brent > 0))
month <- as.integer(format(data$Date, "%Y")) * 12 + as.integer(format(data$Date, "%m"))
stopifnot(all(diff(month) == 1))         # 月份必须连续，不能漏月

price <- data$Brent
r <- 100 * diff(log(price))             # 百分数形式的对数收益率
r_date <- data$Date[-1]                 # 差分后少一个观测，删去第一个日期
r_series <- xts(r, order.by = r_date)    # 给收益率附上日期，供预测包使用
# r=1近似表示价格上涨1%；准确涨幅为100*(exp(r/100)-1)。
# 数据是194个月度价格、193个收益率。CSV未注明价格单位和月均/月末口径。

# 2. 先留出测试集，后续选模型只能用训练集 ------------------------------------
n <- length(r)
n_train <- n - 36                       # 最后36个月留作预测评价
train <- r[1:n_train]
test <- r[(n_train + 1):n]
test_date <- r_date[(n_train + 1):n]
range(r_date[1:n_train])                # 训练：2006-02—2019-02
range(test_date)                        # 测试：2019-03—2022-02
# 不能随机划分时间序列，也不能先用全样本选断点和阶数，再评价所谓样本外预测。

par(mfrow = c(2, 1))                    # 同一页画两张图
plot(data$Date[1:(n_train + 1)], price[1:(n_train + 1)], type = "l",
     main = "Training price", xlab = "Month", ylab = "Price")
plot(r_date[1:n_train], train, type = "l",
     main = "Training returns", xlab = "Month", ylab = "Return (%)")
par(mfrow = c(1, 1))
# 观察：价格水平是否不断移动？收益率是否围绕较固定水平？大波动是否集中出现？

# 3. 平稳性与结构变化 -------------------------------------------------------
# 3.1 ADF检验：先区分原始价格、对数价格与收益率
price_train <- price[1:(n_train + 1)]    # 原始价格P：2006-01—2019-02，158期
logprice_train <- log(price_train)      # 对数价格log(P)，不是原始价格
# train是100*diff(log(P))，2006-02—2019-02，157期；差分后少一期。

# 分别检验三个对象。ADF的H0：有单位根；H1：平稳。
# drift表示含常数、不含线性时间趋势；最多6个差分滞后，由BIC选择。
adf_price <- ur.df(price_train, type = "drift", lags = 6, selectlags = "BIC")
adf_logprice <- ur.df(logprice_train, type = "drift", lags = 6, selectlags = "BIC")
adf_return <- ur.df(train, type = "drift", lags = 6, selectlags = "BIC")
summary(adf_price)
summary(adf_logprice)
summary(adf_return)

# 如何读输出：看底部的tau2统计量与tau2临界值，统计量更负才拒绝H0。
# 在5%水平，三者的ADF临界值都是-2.88：
# 原始价格：-2.432 > -2.88，不拒绝单位根。
# 对数价格：-2.377 > -2.88，不拒绝单位根。
# 收益率：  -6.816 < -2.88，拒绝单位根，支持此设定下收益率平稳。
# “不拒绝单位根”不等于“已经证明非平稳”，结论限定于样本、设定及显著性水平。
#
# 易错点1：上方Coefficients中的Pr(>|t|)是普通回归p值，不是ADF的p值。
# 对数价格z.lag.1的普通p值约0.0187，虽小于0.05，也不能据此拒绝单位根！
# 易错点2：phi1是联合限制的F型统计量，不能替代tau2作同一种判断。
# 易错点3：若用tseries::adf.test()，输出“alternative hypothesis: stationary”
# 只是写明备择假设，并不是报告“结论为平稳”。仍要读检验p值。
# adf.test默认含常数和趋势、使用固定滞后规则，不等同于这里的drift+BIC。
# 易错点4：全样本与训练集可能结论不同；完整样本的检验结果见脚本末尾。

# 3.2 PP检验：同样以“有单位根”为H0
# 使用urca::ur.pp()，与上面的ADF保持含常数、不含趋势的设定。
# Z-tau表示使用修正后的t型单位根统计量；不要看普通回归系数p值。
# lags="short"是长期方差估计的短带宽规则，不是AR模型的阶数。
pp_price <- ur.pp(price_train, type = "Z-tau", model = "constant", lags = "short")
pp_logprice <- ur.pp(logprice_train, type = "Z-tau", model = "constant", lags = "short")
pp_return <- ur.pp(train, type = "Z-tau", model = "constant", lags = "short")
summary(pp_price)
summary(pp_logprice)
summary(pp_return)

# 看底部Z-tau统计量与相应临界值；统计量更负才拒绝单位根。
# 5%临界值约-2.880：
# 原始价格约-2.169，对数价格约-2.209，均不拒绝单位根。
# 收益率约-8.686，拒绝单位根。
# PP对误差自相关和异方差作修正，但不保证小样本表现一定优于ADF。

# 3.3 KPSS检验：注意原假设方向相反！
# H0：围绕固定均值平稳；H1：单位根型非平稳。
# type="mu"检验水平平稳，对应前面含常数、无趋势的比较框架。
# 若研究趋势平稳，须将ADF/PP的趋势设定与KPSS的type="tau"一并考虑。
kpss_price <- ur.kpss(price_train, type = "mu", lags = "short")
kpss_logprice <- ur.kpss(logprice_train, type = "mu", lags = "short")
kpss_return <- ur.kpss(train, type = "mu", lags = "short")
summary(kpss_price)
summary(kpss_logprice)
summary(kpss_return)

# KPSS统计量大于临界值才拒绝H0，与ADF/PP的比较方向不同！
# 5%临界值为0.463：
# 原始价格约0.578、对数价格约0.595，均拒绝水平平稳。
# 收益率约0.065，不拒绝水平平稳；不拒绝也不等于“证明平稳”。
# PP和KPSS可改用lags="long"检查带宽敏感性，但不要挑选有利结果报告。

# 3.4 联合解释与建模选择
# 本训练期、上述设定与5%水平下：
# 原始/对数价格：ADF与PP不拒绝单位根，KPSS拒绝水平平稳。
# 收益率：ADF与PP拒绝单位根，KPSS不拒绝水平平稳。
# 这些结果为收益率建模提供依据，但不能靠“三个检验投票”证明真实过程。
# 高持续性、小样本、结构变化和设定选择都可能影响检验结论。
# 本实验用收益率研究涨跌与波动风险，而不是预先假定所有价格都非平稳。
# 即便其他设定支持价格平稳，研究收益率波动仍有意义；
# 若目标改为价格水平建模，则应另行识别价格模型，不要机械要求先差分。

# 3.5 未知断点检验：暂用r_t=c+phi*r_(t-1)+u_t作简单筛查方程。
# y取第2期到最后一期，lag1取第1期到倒数第2期，使两列一一对应。
break_data <- data.frame(y = train[-1], lag1 = head(train, -1))
fs <- Fstats(y ~ lag1, data = break_data, from = 0.20, vcov. = vcovHAC)
sctest(fs, type = "supF")
plot(fs)
# H0：常数项与AR(1)系数在训练期内不变；p<0.05支持参数不稳定。
# from=0.20表示不在样本两端20%的范围内找断点，避免两边观测过少。
# vcovHAC用于缓和异方差和序列相关的影响。本样本p约0.532，未拒绝稳定性。
# 这不等于“证明没有突变”，也没有检验所有可能模型或2020年测试期的变化。

# 3.6 多断点定位：在最多3个断点中用BIC选择，每段至少36期。
bp <- breakpoints(y ~ lag1, data = break_data, h = 36, breaks = 3)
summary(bp)
plot(summary(bp))
# 看BIC最低对应几个断点。本数据为0个；RSS越低本身不是增加断点的理由。
# 若BIC选择了断点，下面可提取每个旧分段的最后一个月。无断点时输出NA。
break_index <- breakpoints(bp)$breakpoints
r_date[break_index + 1]
# +1是因为前面为构造lag1删去了训练期第一个收益率。
# 若有明显断点，应讨论分段或滚动窗口；不能不作说明地当成稳定参数模型。

# 4. 看ACF和PACF，提出候选模型 ------------------------------------------------
par(mfrow = c(1, 2))
acf(train, lag.max = 24, main = "ACF of returns")
pacf(train, lag.max = 24, main = "PACF of returns")
par(mfrow = c(1, 1))
# AR(p)：PACF在p阶之后理论上截尾，ACF拖尾。
# MA(q)：ACF在q阶之后理论上截尾，PACF拖尾。
# ARMA(p,q)：ACF和PACF通常都拖尾。
# 蓝线是近似逐点界限；不能因为某个高阶偶然超线就不断增加阶数。
# 本数据lag1比较明显，先试AR(1)、MA(1)，并加入2阶和ARMA(1,1)对照。

# 5. 一个一个估计模型，比较滞后阶数 ------------------------------------------
# order=c(p,d,q)：AR阶数、差分次数、MA阶数。
# train已经是对数价格的一阶差分，因此此处d=0，不再差分。
m0 <- Arima(train, order = c(0, 0, 0), include.mean = TRUE, method = "ML")
ar1 <- Arima(train, order = c(1, 0, 0), include.mean = TRUE, method = "ML")
ar2 <- Arima(train, order = c(2, 0, 0), include.mean = TRUE, method = "ML")
ma1 <- Arima(train, order = c(0, 0, 1), include.mean = TRUE, method = "ML")
ma2 <- Arima(train, order = c(0, 0, 2), include.mean = TRUE, method = "ML")
arma11 <- Arima(train, order = c(1, 0, 1), include.mean = TRUE, method = "ML")

AIC(m0, ar1, ar2, ma1, ma2, arma11)
BIC(m0, ar1, ar2, ma1, ma2, arma11)
# 都是越小越好。这里事先以BIC为主；不能等看完测试期误差再改变选择标准。
# 比较表中BIC最小的候选模型是AR(1)，因此采用以下均值模型。
mean_model <- ar1
summary(mean_model)
# AR(1)系数约0.339：上个月收益率较高时，本月收益率也倾向较高。
# 输出中的mean是长期均值，不等于未中心化AR方程中的截距。
# 本节summary附带的是训练期拟合误差，不能拿它代表样本外预测水平。

# 6. 均值残差诊断：先看相关性，再看ARCH效应 ----------------------------------
u <- residuals(mean_model)
par(mfrow = c(1, 2))
acf(u, main = "ACF of residuals")
acf(u^2, main = "ACF of squared residuals")
par(mfrow = c(1, 1))
Box.test(u, lag = 12, type = "Ljung-Box", fitdf = 1)
# H0：前12阶残差相关系数共同为0。fitdf=p+q，这里的AR(1)为1。
# p约0.616：没有明显剩余线性相关。如果拒绝，先重新检查均值模型。
ArchTest(u, lags = 12, demean = TRUE)
# H0：没有前12阶ARCH效应。p约0.000602，支持存在条件异方差。
# 关键：残差不自相关，不意味着残差平方也不自相关。

# 7. 建立ARCH(1)和GARCH(1,1) --------------------------------------------------
# rugarch需要先“设定模型”，再“估计模型”。list()只是把设定放在一起。
# armaOrder=c(1,0)：沿用刚才选出的AR(1)均值模型，估计时与方差联合估计。
# garchOrder=c(ARCH阶数, GARCH阶数)：注意这个包的顺序！
# norm表示条件创新服从正态分布。
spec_arch <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 0)),
  mean.model = list(armaOrder = c(1, 0), include.mean = TRUE),
  distribution.model = "norm")

spec_garch <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(1, 0), include.mean = TRUE),
  distribution.model = "norm")

fit_arch <- ugarchfit(spec_arch, data = r_series[1:n_train], solver = "hybrid")
fit_garch <- ugarchfit(spec_garch, data = r_series[1:n_train], solver = "hybrid")
show(fit_arch)
show(fit_garch)
# 输出包括系数、标准误、p值和多种诊断。先看系数，再看标准化残差检验。
# 若出现未收敛警告，先解决估计问题，不能把失败结果用于后面的比较。

rbind(ARCH1 = infocriteria(fit_arch)[1:2], GARCH11 = infocriteria(fit_garch)[1:2])
# 第一列AIC，第二列BIC，都是越小越好。
# rugarch按每个观测报告IC，不要直接与Arima输出的总量IC混排。
# 本数据ARCH(1)的BIC更低；GARCH不是因为名字更复杂就一定更好。

coef(fit_garch)
# GARCH(1,1)：h_t=omega+alpha1*u_(t-1)^2+beta1*h_(t-1)。
# alpha1：新冲击的影响；beta1：过去条件方差的影响。
persistence <- coef(fit_garch)["alpha1"] + coef(fit_garch)["beta1"]
persistence                              # 本数据约0.709
# 越接近1，波动越持久；小于1时才有下面的有限长期方差。
long_run_variance <- coef(fit_garch)["omega"] / (1 - persistence)
long_run_variance                       # 单位为百分数平方
sqrt(long_run_variance)                 # 长期月度标准差，约8.93%
# 若换数据后persistence>=1，不使用上述长期方差公式。

# 8. GARCH模型诊断 -----------------------------------------------------------
z <- as.numeric(residuals(fit_garch, standardize = TRUE))
# z_t=u_t/sigma_t。去除条件波动之后，应不再有明显线性相关或平方相关。
par(mfrow = c(2, 2))
plot(z, type = "l", main = "Standardized residuals")
acf(z, main = "ACF of z")
acf(z^2, main = "ACF of z squared")
qqnorm(z); qqline(z, col = "red")
par(mfrow = c(1, 1))
Box.test(z, lag = 12, type = "Ljung-Box", fitdf = 1)
Box.test(z^2, lag = 12, type = "Ljung-Box")
ArchTest(z, lags = 12, demean = TRUE)
# p小：均值/方差可能仍有遗漏；p大：未发现充分反对证据，不是证明模型正确。
# 对估计后的GARCH残差，上述普通检验只是近似筛查，结合show(fit_garch)
# 中包提供的加权残差检验阅读。QQ尾部偏离提示正态分布可能不合适。

# 9. 在同一个时点预测未来12个月 ----------------------------------------------
fc12 <- ugarchforecast(fit_garch, n.ahead = 12)
fitted(fc12)                           # 条件均值预测
sigma(fc12)                            # 条件标准差预测
sigma(fc12)^2                          # 条件方差预测
# 这些预测全部从训练期终点出发，不能误称为每月更新的一步预测。

# 10. 逐月的一步样本外预测 ---------------------------------------------------
# 同方差AR(1)用rugarch包中的arfimaspec和arfimaroll。
# arfima=FALSE关闭分数差分，所以这里仍是普通AR(1)。
# 三个模型均值都是AR(1)，比较方差为常数、ARCH(1)、GARCH(1,1)三种情况。
# 与前面的Arima估计方法/初始化有细微差异，因此数值不必完全相同。
spec_constant <- arfimaspec(
  mean.model = list(armaOrder = c(1, 0), include.mean = TRUE, arfima = FALSE),
  distribution.model = "norm")

# n.start=n_train：先用前157期估计，随后预测剩余36期。
# refit.every=1：每观察到一个新月份，重新估计一次，再预测下个月。
# recursive：扩展窗口，只加入已经发生的数据；不会提前使用未来收益率。
# calculate.VaR=FALSE：不计算风险价值，仅输出收益率与波动预测。
roll_constant <- arfimaroll(spec_constant, data = r_series, n.start = n_train,
  refit.every = 1, refit.window = "recursive", solver = "hybrid", calculate.VaR = FALSE)
roll_arch <- ugarchroll(spec_arch, data = r_series, n.start = n_train,
  refit.every = 1, refit.window = "recursive", solver = "hybrid", calculate.VaR = FALSE)
roll_garch <- ugarchroll(spec_garch, data = r_series, n.start = n_train,
  refit.every = 1, refit.window = "recursive", solver = "hybrid", calculate.VaR = FALSE)

show(roll_constant)                     # 应列出36个成功的一步预测
convergence(roll_arch)
convergence(roll_garch)
# 两个convergence结果都应为0。若有未收敛警告，停止比较，先解决收敛。
stopifnot(convergence(roll_arch) == 0,
          convergence(roll_garch) == 0)

pred_constant <- as.data.frame(roll_constant)
pred_arch <- as.data.frame(roll_arch)
pred_garch <- as.data.frame(roll_garch)
head(pred_garch)
# Mu=预测均值；Sigma=预测标准差；Realized=实际收益率。
# 行名为实际预测月份；画图使用前面的test_date。
stopifnot(!anyNA(pred_constant), !anyNA(pred_arch), !anyNA(pred_garch))
stopifnot(nrow(pred_garch) == 36, nrow(pred_arch) == 36, nrow(pred_constant) == 36)
stopifnot(isTRUE(all.equal(as.numeric(pred_garch$Realized), as.numeric(test))),
          isTRUE(all.equal(as.numeric(pred_arch$Realized), as.numeric(test))),
          isTRUE(all.equal(as.numeric(pred_constant$Realized), as.numeric(test))))

# 11. 比较预测表现 -----------------------------------------------------------
# 11.1 收益率点预测：RMSE与MAE越小越好。
point_scores <- rbind(
  Zero_return = accuracy(rep(0, 36), test)[1, c("RMSE", "MAE")],
  Constant_variance = accuracy(pred_constant$Mu, test)[1, c("RMSE", "MAE")],
  ARCH1 = accuracy(pred_arch$Mu, test)[1, c("RMSE", "MAE")],
  GARCH11 = accuracy(pred_garch$Mu, test)[1, c("RMSE", "MAE")])
point_scores
# 零收益率基准相当于预测下个月价格不变。复杂模型应和简单基准比较。
# 收益率可能接近0或为负，不用MAPE。不要用训练期拟合误差替代这张表。

# 11.2 波动预测：GARCH主要解释波动，不一定显著改善均值预测。
# 真实条件方差不可见，用同方差AR(1)的预测误差平方作共同的噪声代理。
proxy <- (test - pred_constant$Mu)^2
h_constant <- pred_constant$Sigma^2
h_arch <- pred_arch$Sigma^2
h_garch <- pred_garch$Sigma^2
# QLIKE=log(预测方差)+代理/预测方差，越小越好。
volatility_scores <- data.frame(
  model = c("Constant variance", "ARCH1", "GARCH11"),
  QLIKE = c(mean(log(h_constant) + proxy / h_constant),
            mean(log(h_arch) + proxy / h_arch),
            mean(log(h_garch) + proxy / h_garch)))
volatility_scores
# 三个模型必须用同一个proxy。本指标依赖均值模型足够准确，不能当成真实方差误差。

# 11.3 DM检验：较低RMSE是否意味着显著更好？
e_constant <- test - pred_constant$Mu
e_garch <- test - pred_garch$Mu
dm.test(e_garch, e_constant, h = 1, power = 2)
# H0：两个模型的期望平方预测误差相同；p<0.05才有拒绝H0的证据。
# 负统计量倾向GARCH更好；p>=0.05不能声称GARCH显著胜出。
# 本测试期只有36个月，且模型可能嵌套，常规DM检验的推断可能不可靠，结论要谨慎。

# 11.4 画GARCH预测与95%区间（正态创新假设）
lower <- pred_garch$Mu - 1.96 * pred_garch$Sigma
upper <- pred_garch$Mu + 1.96 * pred_garch$Sigma
plot(test_date, test, type = "l", ylim = range(test, lower, upper),
     main = "One-step GARCH forecasts", xlab = "Month", ylab = "Return (%)")
lines(test_date, pred_garch$Mu, col = "blue")
lines(test_date, lower, col = "red", lty = 2)
lines(test_date, upper, col = "red", lty = 2)
legend("topleft", c("Actual", "Forecast", "95% interval"),
       col = c("black", "blue", "red"), lty = c(1, 1, 2), bty = "n")
mean(test >= lower & test <= upper)      # 实际区间覆盖率，目标接近0.95
# 区间暂不包含参数估计不确定性；覆盖率高也可能仅是区间更宽。
# 注意2020年附近的预测区间变化；不能因极端值难预测就把它删掉。

# 12. 保存两张比较表 ---------------------------------------------------------
dir.create("Lab1/results_beginner", recursive = TRUE, showWarnings = FALSE)
write.csv(point_scores, "Lab1/results_beginner/point_scores.csv")
write.csv(volatility_scores, "Lab1/results_beginner/volatility_scores.csv", row.names = FALSE)
# 图形直接显示在RStudio的Plots窗口，可用Export保存。

# 实验报告问题：
# 1. 结构变化检验是否拒绝？这能说明什么，不能说明什么？
# 2. 为什么选AR(1)？为什么残差不相关却还需要ARCH/GARCH？
# 3. alpha、beta和标准化残差诊断如何解释？
# 4. 点预测与波动预测的排名是否相同？较小误差是否统计显著？
# 官方接口说明：https://search.r-project.org/CRAN/refmans/rugarch/html/ugarchroll-methods.html


# 13. 样本区间对ADF检验结论的影响 --------------------------------------------
# 仅在完成样本外预测评价之后阅读；以下结果不用于前面的选阶或模型选择。
# price包含2006-01—2022-02的194个月度观测。
adf_price_full <- ur.df(price, type = "drift", lags = 6, selectlags = "BIC")
adf_logprice_full <- ur.df(log(price), type = "drift", lags = 6, selectlags = "BIC")
summary(adf_price_full)
summary(adf_logprice_full)
# 全样本原始价格tau2约-2.714：在5%水平不拒绝，但在10%水平拒绝单位根。
# 全样本对数价格tau2约-3.059：在5%水平拒绝单位根，支持该设定下的平稳备择。
# 因此“价格也是stationary”必须注明：原始/对数、训练/全样本、趋势项、滞后、显著性水平。
# 不能把全样本对数价格的结论移植给训练期原始价格，也不能从中挑最想要的结果。
# 方法说明：
# https://search.r-project.org/CRAN/refmans/urca/html/ur.df.html
# https://search.r-project.org/CRAN/refmans/urca/html/ur.pp.html
# https://search.r-project.org/CRAN/refmans/urca/html/ur.kpss.html
