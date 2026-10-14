# ============================================================================
# Lab 2：VAR、SVAR 与 Local Projection
# 数据作图 -> 平稳性 -> 选阶 -> 诊断 -> 结构冲击 -> 预测比较
# ============================================================================
# 使用方法：把 Lab 2.R 和 lab 2.csv 放在同一文件夹，用 RStudio 打开本文件。
# 菜单 Session -> Set Working Directory -> To Source File Location。
# 第一次使用时，去掉下一行开头的 #，安装已有包；以后不必重复安装。
# install.packages(c("vars", "urca", "svars", "lpirfs", "forecast"))
# 所有估计、检验、IRF、FEVD、HD、LP 均调用已有包；逐段运行，无需写循环。
# 代码中的 png()/dev.off() 将图保存到 Lab2_output；用文件浏览器打开即可查看。

library(vars)
library(urca)
library(svars)
library(lpirfs)
library(forecast)

dir.create("Lab2_output", showWarnings = FALSE)
set.seed(20261014)

# 1. 读取数据，先确认变量是什么 -----------------------------------------------
# 国家：美国。CSV 来自 svars 1.3.12 的 USA 数据集，冻结为1965Q1--2008Q3的175个季度。
# 章节的部分简短示例使用 vars::Canada（加拿大，e/prod/rw/U）；本实验使用 USA（x/pi/i）。
# x：100 * log(实际GDP / CBO潜在GDP)，即产出缺口，单位为百分比对数点。
# pi：GDP 平减指数的环比年化通胀率，单位为 %。
# i：联邦基金利率，单位为 %。
# x 不是 GDP，pi 不是价格指数；pi、i 已是比率，不再取对数。
# 来源：https://search.r-project.org/CRAN/refmans/svars/html/USA.html
# CSV 的时间来自实际数据的 ts 属性；部分旧版文档将行数误写为 174。

raw <- read.csv("lab 2.csv", check.names = FALSE)
head(raw)
tail(raw)
str(raw)
colSums(is.na(raw))

# stopifnot：条件不成立就停止，避免缺失、重复、日期错位后仍继续建模。
quarter_id <- zoo::as.yearqtr(raw$quarter, format = "%Y Q%q")
stopifnot(nrow(raw) == 175, !anyNA(raw), !anyNA(quarter_id))
stopifnot(!anyDuplicated(quarter_id), all(diff(as.numeric(quarter_id)) == 0.25))
stopifnot(raw$quarter[1] == "1965 Q1", tail(raw$quarter, 1) == "2008 Q3")
y_all <- ts(raw[, c("x", "pi", "i")], start = c(1965, 1), frequency = 4)

# 2. 画全历史序列，明确样本范围 -----------------------------------------------
png("Lab2_output/01_full_history.png", width = 1500, height = 1100, res = 150)
plot(y_all, main = "USA: output gap, inflation and interest rate", xlab = "Year")
dev.off()

# 主分析限定于 1984Q1 以后，大缓和时期提供样本划分的经济背景。
# https://www.federalreserve.gov/boarddocs/speeches/2004/20040220/default.htm
# 这个历史背景不保证参数稳定，也不意味着 1984Q1 是检验估计的断点。
# 1960--1980 年代与其后可能有不同动态，最后保留全历史训练样本作对照。
# 选择较短样本与差分会损失信息；研究长期均衡时还需考虑协整/VECM。
y <- window(y_all, start = c(1984, 1))

# 最后 12 个季度留作测试集。所有检验、选阶、估计和冲击分析只用训练集。
# 训练期 1984Q1--2005Q3：87 个水平观测；测试期 2005Q4--2008Q3：12 个。
y_train <- window(y, end = c(2005, 3))
y_test <- window(y, start = c(2005, 4))
start(y_train)
end(y_train)
nrow(y_train)
nrow(y_test)

png("Lab2_output/02_training_levels.png", width = 1500, height = 1100, res = 150)
plot(y_train, main = "Training sample: levels", xlab = "Year")
dev.off()

# 观察均值、趋势、异常波动。图只能提供线索，不能替代平稳性检验。
# 一元 ACF/PACF 也不能直接决定多变量 VAR 的共同滞后阶数。
png("Lab2_output/03_level_acf.png", width = 1500, height = 1100, res = 150)
par(mfrow = c(3, 2))
acf(y_train[, "x"], main = "x: ACF")
pacf(y_train[, "x"], main = "x: PACF")
acf(y_train[, "pi"], main = "pi: ACF")
pacf(y_train[, "pi"], main = "pi: PACF")
acf(y_train[, "i"], main = "i: ACF")
pacf(y_train[, "i"], main = "i: PACF")
dev.off()

# 3. 水平序列：ADF、PP、KPSS --------------------------------------------------
# ADF/PP 的 H0：有单位根。统计量比临界值更负才拒绝 H0。
# KPSS 的 H0：水平平稳。统计量大于临界值才拒绝 H0。
# 本例使用常数、不含时间趋势；季度 ADF 最多 4 个差分滞后，由 BIC 选阶。
# PP/KPSS 用 short 带宽；带宽和确定性项改变可能影响结论，应报告设定。
# 重点读 summary() 底部的检验统计量与对应临界值。
# ADF 上方回归表 z.lag.1 的普通 t 检验 p 值，不是单位根检验 p 值！
# ADF 看 tau2，不用 phi1 替代它。@teststat/@cval 是提取包保存的结果。

adf_x <- ur.df(y_train[, "x"], type = "drift", lags = 4, selectlags = "BIC")
adf_pi <- ur.df(y_train[, "pi"], type = "drift", lags = 4, selectlags = "BIC")
adf_i <- ur.df(y_train[, "i"], type = "drift", lags = 4, selectlags = "BIC")
summary(adf_x)
summary(adf_pi)
summary(adf_i)

pp_x <- ur.pp(y_train[, "x"], type = "Z-tau", model = "constant", lags = "short")
pp_pi <- ur.pp(y_train[, "pi"], type = "Z-tau", model = "constant", lags = "short")
pp_i <- ur.pp(y_train[, "i"], type = "Z-tau", model = "constant", lags = "short")
summary(pp_x)
summary(pp_pi)
summary(pp_i)

kpss_x <- ur.kpss(y_train[, "x"], type = "mu", lags = "short")
kpss_pi <- ur.kpss(y_train[, "pi"], type = "mu", lags = "short")
kpss_i <- ur.kpss(y_train[, "i"], type = "mu", lags = "short")
summary(kpss_x)
summary(kpss_pi)
summary(kpss_i)

# 5% 下，x 的 ADF/PP 不拒绝单位根，KPSS 也不拒绝平稳：证据不足、相互不决。
# pi 的 PP 拒绝单位根、KPSS 拒绝平稳；ADF 非常接近临界值，要看足够小数位。
# i 的 ADF/PP 不拒绝单位根、KPSS 拒绝平稳：支持进一步考虑非平稳处理。
# 不把三个检验当作投票；不拒绝 H0 也不是证明 H0 正确。

# 4. 一阶差分：定义改变了，经济解释也要随之改变 -------------------------------
# 本实验用三个变化量构建短期 VAR；这不是宣称三个水平变量都确定为 I(1)。
# dx = x_t - x_(t-1)：产出缺口的季度变化，约为实际与潜在GDP增速之差，非GDP增速。
# dpi = pi_t - pi_(t-1)：年化通胀率的季度变化，单位为百分点，非通胀率本身。
# di = i_t - i_(t-1)：利率的季度变化，单位为百分点。
# 若原变量实际上平稳，差分可能过度差分并引入 MA 动态；务必比较水平设定。
d_all <- diff(y)
colnames(d_all) <- c("dx", "dpi", "di")
d_train <- window(d_all, end = c(2005, 3))
d_test <- window(d_all, start = c(2005, 4))
stopifnot(nrow(d_train) == 86, nrow(d_test) == 12)

png("Lab2_output/04_training_changes.png", width = 1500, height = 1100, res = 150)
plot(d_train, main = "Training sample: quarterly changes", xlab = "Year")
dev.off()
png("Lab2_output/05_change_acf.png", width = 1500, height = 1100, res = 150)
par(mfrow = c(3, 2))
acf(d_train[, "dx"], main = "dx: ACF")
pacf(d_train[, "dx"], main = "dx: PACF")
acf(d_train[, "dpi"], main = "dpi: ACF")
pacf(d_train[, "dpi"], main = "dpi: PACF")
acf(d_train[, "di"], main = "di: ACF")
pacf(d_train[, "di"], main = "di: PACF")
dev.off()

# 5. 复检差分序列，不能只做 diff() 就假定平稳 ----------------------------------
adf_dx <- ur.df(d_train[, "dx"], type = "drift", lags = 4, selectlags = "BIC")
adf_dpi <- ur.df(d_train[, "dpi"], type = "drift", lags = 4, selectlags = "BIC")
adf_di <- ur.df(d_train[, "di"], type = "drift", lags = 4, selectlags = "BIC")
summary(adf_dx)
summary(adf_dpi)
summary(adf_di)
pp_dx <- ur.pp(d_train[, "dx"], type = "Z-tau", model = "constant", lags = "short")
pp_dpi <- ur.pp(d_train[, "dpi"], type = "Z-tau", model = "constant", lags = "short")
pp_di <- ur.pp(d_train[, "di"], type = "Z-tau", model = "constant", lags = "short")
summary(pp_dx)
summary(pp_dpi)
summary(pp_di)
kpss_dx <- ur.kpss(d_train[, "dx"], type = "mu", lags = "short")
kpss_dpi <- ur.kpss(d_train[, "dpi"], type = "mu", lags = "short")
kpss_di <- ur.kpss(d_train[, "di"], type = "mu", lags = "short")
summary(kpss_dx)
summary(kpss_dpi)
summary(kpss_di)

# 每一行保留本身的临界值，避免因样本数不同套错阈值。
stationarity <- data.frame(
  variable = c("x", "pi", "i", "dx", "dpi", "di"),
  ADF = c(adf_x@teststat[1], adf_pi@teststat[1], adf_i@teststat[1],
          adf_dx@teststat[1], adf_dpi@teststat[1], adf_di@teststat[1]),
  ADF_5pct = c(adf_x@cval["tau2", "5pct"], adf_pi@cval["tau2", "5pct"],
               adf_i@cval["tau2", "5pct"], adf_dx@cval["tau2", "5pct"],
               adf_dpi@cval["tau2", "5pct"], adf_di@cval["tau2", "5pct"]),
  PP = c(pp_x@teststat, pp_pi@teststat, pp_i@teststat,
         pp_dx@teststat, pp_dpi@teststat, pp_di@teststat),
  PP_5pct = c(pp_x@cval[1, "5pct"], pp_pi@cval[1, "5pct"], pp_i@cval[1, "5pct"],
              pp_dx@cval[1, "5pct"], pp_dpi@cval[1, "5pct"], pp_di@cval[1, "5pct"]),
  KPSS = c(kpss_x@teststat, kpss_pi@teststat, kpss_i@teststat,
           kpss_dx@teststat, kpss_dpi@teststat, kpss_di@teststat),
  KPSS_5pct = 0.463
)
print(stationarity, digits = 7)
write.csv(stationarity, "Lab2_output/stationarity.csv", row.names = FALSE)
# 差分后：三个序列 ADF/PP 均拒绝单位根、KPSS 均不拒绝平稳（5%）。
# 这支持继续估计变化量 VAR，但不能验证长期关系或所有结构假设。

# 6. VAR 选阶：系统中每个方程使用相同的 p -------------------------------------
# 三变量 VAR(2)：每个方程含 3*2=6 个滞后系数和 1 个常数。
# AIC 较侧重拟合，SC/BIC 对参数数量的惩罚较大，出现不同推荐阶数很常见。
lag_selection <- VARselect(d_train, lag.max = 4, type = "const")
lag_selection$selection
lag_selection$criteria
write.csv(lag_selection$criteria, "Lab2_output/lag_criteria.csv")
# 冻结样本中 AIC/FPE 推荐 2 阶，HQ/SC 推荐 1 阶；保留两个候选并做诊断。
var_1 <- VAR(d_train, p = 1, type = "const")
var_2 <- VAR(d_train, p = 2, type = "const")
summary(var_1)
summary(var_2)

# 7. 诊断：先问模型是否足以描述数据 -------------------------------------------
# roots() 返回伴随矩阵的特征根模；全部 <1 才满足估计 VAR 的动态稳定条件。
# 这不同于关于特征多项式根在单位圆外的等价表述，也不替代单位根检验。
roots(var_1)
roots(var_2)
# Portmanteau H0：至给定阶数的残差自相关为零；lags.pt 必须大于 p。
serial_1 <- serial.test(var_1, lags.pt = 12, type = "PT.adjusted")
serial_2 <- serial.test(var_2, lags.pt = 12, type = "PT.adjusted")
serial_1
serial_2
# 多变量 ARCH H0：无指定阶数的条件异方差。这里用 2 阶以控制检验参数数量。
arch_1 <- arch.test(var_1, lags.multi = 2)
arch_2 <- arch.test(var_2, lags.multi = 2)
arch_1
arch_2
# JB H0：残差联合正态；拒绝不等于条件均值估计全部无效，但影响正态推断。
normal_2 <- normality.test(var_2)
normal_2

diagnostics <- data.frame(
  model = c("VAR(1)", "VAR(2)"),
  max_root = c(max(roots(var_1)), max(roots(var_2))),
  serial_p = c(serial_1$serial$p.value, serial_2$serial$p.value),
  ARCH_p = c(arch_1$arch.mul$p.value, arch_2$arch.mul$p.value)
)
diagnostics
write.csv(diagnostics, "Lab2_output/diagnostics.csv", row.names = FALSE)
# 本例两模型根均 <1，serial/ARCH 均不拒绝 H0；VAR(2) 的 JB 拒绝正态。
# 不应概括成“所有诊断均通过”。下面沿用 AIC 推荐的 VAR(2)，VAR(1) 作预测比较。
var_model <- var_2

png("Lab2_output/06_residuals.png", width = 1500, height = 1100, res = 150)
plot.ts(residuals(var_model), main = "VAR(2) residuals")
dev.off()
png("Lab2_output/07_residual_acf.png", width = 1500, height = 1100, res = 150)
acf(residuals(var_model), lag.max = 12, main = "Residual auto/cross-correlations")
dev.off()

# CUSUM 检验参数稳定性，与“动态根稳定”是两个问题。
# H0：方程参数稳定。图中越过边界或 p<.05 提示参数变化，不越界不能证明永远稳定。
stability_result <- vars::stability(var_model, type = "OLS-CUSUM")
png("Lab2_output/08_cusum.png", width = 1500, height = 1100, res = 150)
plot(stability_result)
dev.off()
cusum_dx <- strucchange::sctest(stability_result$stability$dx)
cusum_dpi <- strucchange::sctest(stability_result$stability$dpi)
cusum_di <- strucchange::sctest(stability_result$stability$di)
cusum_dx
cusum_dpi
cusum_di
write.csv(data.frame(equation = c("dx", "dpi", "di"),
  p_value = c(cusum_dx$p.value, cusum_dpi$p.value, cusum_di$p.value)),
  "Lab2_output/cusum.csv", row.names = FALSE)

# 8. 系数与 Granger：预测关系不自动等于经济因果 -------------------------------
summary(var_model$varresult$dx)
# 例如 di.l1 的系数：控制所有其他所列滞后之后，上季利率变化增加 1 个百分点，
# 本季产出缺口变化的条件均值改变多少。它不是一个完整的政策冲击响应。
# 看利率的两阶滞后是否共同提供预测信息，要用联合检验。
granger_rate <- causality(var_model, cause = "di")
granger_macro <- causality(var_model, cause = c("dx", "dpi"))
granger_rate$Granger
granger_macro$Granger
granger_rate$Instant
# 第一项检验 di 的滞后对 dx、dpi 两方程是否共同为零（不是只检验 dx）。
# 本例 p约.536，不拒绝“di不Granger导致dx,dpi”；不能据此说货币政策没有影响。
# 反向联合 p约.0084：宏观变量变化为利率变化提供预测信息。
# Instant 检验当期残差相关，不提供因果方向；遗漏信息与共同冲击都可能造成相关。

# 9. SVAR：把简约式残差 u_t 分解成结构创新 B * epsilon_t -----------------------
# 顺序为 dx, dpi, di；Cholesky 使 B 为下三角，结构创新方差标准化为 1。
# dx 当期只响应第一个创新；dpi 当期可响应前两个；di 当期可响应全部三个。
# 因此“利率创新对 dx/dpi 当期为零”是施加的限制，不是从显著性检验发现的事实。
# 在这些假设可信时，第三个创新可解释为未被系统当期信息解释的利率变动。
# 它仍可能混合遗漏信息，不自动等于干净的外生货币政策冲击。
# svars::id.chol() 直接估计递归 SVAR，无需手写优化程序或矩阵求解函数。
svar_model <- svars::id.chol(var_model)
svar_model$B
write.csv(svar_model$B, "Lab2_output/impact_matrix.csv")
# 第三列约 (0,0,.3934)：正的一个标准差利率创新，当期使 di 增加 .3934 个百分点。
# “一个标准差冲击”不等于“利率提高1个百分点”，也不等于提高1%。
# 相同简约式 VAR 的递归 SVAR，只改变结构解释，不改善其条件均值点预测。

# 10. IRF：方向、幅度、期限和区间要一起看 -------------------------------------
# 对 VAR 使用 ortho=TRUE，采用上述同顺序的 Cholesky 识别，与 id.chol 对应。
# n.ahead=12 返回 h=0,...,12 共13行；h=0 是冲击当期，不是第一季度之后。
# 残差 bootstrap 不要求正态，但依赖模型与重抽样假设；500次适合练习，正式分析增大。
# 已检测到非正态，区间仍是近似推断；ARCH 不拒绝也不能保证独立同分布完全成立。
set.seed(20261014)
irf_rate <- irf(var_model, impulse = "di", response = c("dx", "dpi", "di"),
                n.ahead = 12, ortho = TRUE, boot = TRUE, ci = 0.95, runs = 500)
png("Lab2_output/09_irf.png", width = 1500, height = 1100, res = 150)
plot(irf_rate)
dev.off()
irf_table <- data.frame(horizon = 0:12,
  dx = irf_rate$irf$di[, "dx"], dx_low = irf_rate$Lower$di[, "dx"],
  dx_up = irf_rate$Upper$di[, "dx"], dpi = irf_rate$irf$di[, "dpi"],
  di = irf_rate$irf$di[, "di"])
irf_table
write.csv(irf_table, "Lab2_output/irf.csv", row.names = FALSE)
# dx 的响应是“产出缺口变化的响应”。若95%区间跨0，该期方向证据不足。
# h=0 的 dx/dpi 恰为0源于识别限制，不能解释成精确估计的经济零效应。

# 11. 累计 IRF：从变化量恢复到原变量 ------------------------------------------
# 把 dx 响应从0累加到h，才得到“产出缺口水平相对无冲击基线”的响应。
# 同理，累计 dpi/di 响应分别是通胀率/利率水平的百分点变化。
# cumulative=TRUE 在每次 bootstrap 内先累计再形成区间；不能把区间端点直接相加。
set.seed(20261014)
irf_cumulative <- irf(var_model, impulse = "di", response = c("dx", "dpi", "di"),
  n.ahead = 12, ortho = TRUE, cumulative = TRUE, boot = TRUE, ci = 0.95, runs = 500)
png("Lab2_output/10_cumulative_irf.png", width = 1500, height = 1100, res = 150)
plot(irf_cumulative)
dev.off()
cum_table <- data.frame(horizon = 0:12,
  x = irf_cumulative$irf$di[, "dx"], x_low = irf_cumulative$Lower$di[, "dx"],
  x_up = irf_cumulative$Upper$di[, "dx"],
  pi = irf_cumulative$irf$di[, "dpi"], i = irf_cumulative$irf$di[, "di"])
cum_table
write.csv(cum_table, "Lab2_output/cumulative_irf.csv", row.names = FALSE)
# 本例h=4的缺口累计点估计约-.104，但区间跨0；不能声称有显著紧缩效应。
# 差分模型允许原变量冲击有持久累计效应，这是模型设定的含义而非长期因果证明。

# 12. 改变变量顺序：检验结论对识别假设的敏感性 -------------------------------
# 把 di 放在第一位，允许利率创新当期影响其他变量，但不让利率当期响应它们。
# 两种限制不能同时当成经济事实；比较结果时保持当期利率响应同为 +1 个百分点。
var_reordered <- VAR(d_train[, c("di", "dx", "dpi")], p = 2, type = "const")
irf_reordered <- irf(var_reordered, impulse = "di", response = c("dx", "dpi", "di"),
                     n.ahead = 12, ortho = TRUE, boot = FALSE)
order_comparison <- data.frame(horizon = 0:12,
  rate_last = irf_rate$irf$di[, "dx"] / irf_rate$irf$di[1, "di"],
  rate_first = irf_reordered$irf$di[, "dx"] / irf_reordered$irf$di[1, "di"])
order_comparison
write.csv(order_comparison, "Lab2_output/order_comparison.csv", row.names = FALSE)
png("Lab2_output/11_order_sensitivity.png", width = 1400, height = 900, res = 150)
matplot(0:12, order_comparison[, 2:3], type = "l", lty = 1:2, col = c("navy", "firebrick"),
  xlab = "Quarters after shock", ylab = "Response of change in output gap",
  main = "Order sensitivity: +1 percentage-point impact on interest rate")
abline(h = 0, col = "grey60")
legend("topright", c("Rate last", "Rate first"), col = c("navy", "firebrick"), lty = 1:2)
dev.off()
# 这里是同尺度的点估计比较；没有重新构造归一化区间，不作显著性比较。

# 13. FEVD：某个预测期限的误差方差由哪些创新解释？ -----------------------------
fevd_result <- fevd(var_model, n.ahead = 12)
fevd_result$dx
write.csv(data.frame(horizon = 1:12, fevd_result$dx),
  "Lab2_output/fevd_dx.csv", row.names = FALSE)
png("Lab2_output/12_fevd.png", width = 1500, height = 1100, res = 150)
plot(fevd_result)
dev.off()
# 每行和为1（乘100为百分比）；h=1是一步预测误差，只含当期创新的影响。
# 本例h=12，di创新约解释dx预测误差方差的1.28%。
# 这是变化量dx的FEVD，不是GDP水平、缺口水平的FEVD，也不是“解释经济增长1.28%”。
# FEVD 依赖变量集合和识别顺序；遗漏变量不因使用 SVAR 而消失。

# 14. 历史分解 HD 与反事实路径 ------------------------------------------------
# 本段沿用同一递归 SVAR，没有额外引入异方差识别或重新命名冲击。
# hd 的默认 transition=0 保留全部可分解时期；首期有初始条件影响。
hd_dx <- svars::hd(svar_model, series = 1)
head(hd_dx$hidec)
png("Lab2_output/13_historical_decomposition.png", width = 1600, height = 1100, res = 150)
plot(hd_dx)
dev.off()
hd_table <- data.frame(quarter = format(zoo::as.yearqtr(time(hd_dx$hidec)), "%Y Q%q"),
  as.data.frame(hd_dx$hidec))
write.csv(hd_table, "Lab2_output/historical_decomposition.csv", row.names = FALSE)
# 包返回去均值的 dx、由冲击历史重构的 dx，以及各创新的累计贡献。
# 各创新贡献之和=重构序列；它与实际去均值序列可能有初始条件/基线差异。
# 图中的“累计贡献”指历史各期冲击对当期dx的叠加，不是把dx积分成GDP或缺口水平。
# 第一个残差季度是1984Q4：差分损失一期，VAR(2)再损失两期。

cf_dx <- svars::cf(svar_model, series = 1)
head(cf_dx$actual)
head(cf_dx$counter)
png("Lab2_output/14_counterfactual.png", width = 1600, height = 1100, res = 150)
plot(cf_dx)
dev.off()
cf_table <- data.frame(quarter = format(zoo::as.yearqtr(time(cf_dx$actual)), "%Y Q%q"),
  as.data.frame(cf_dx$counter))
write.csv(cf_table, "Lab2_output/counterfactual.csv", row.names = FALSE)
# cf 对目标dx返回剔除dpi创新、剔除di创新历史贡献后的去均值路径。
# 后者回答“在原模型参数和其他创新不变时，移去识别出的利率创新贡献会怎样”。
# 它不是“央行从未加息”的政策制度反事实；政策规则变化可能改变其他行为和参数。

# 15. Local Projection：同一识别顺序，不同动态估计方法 ------------------------
# 列顺序仍为 dx,dpi,di，固定2阶控制变量、常数项。
# trend=0 包含常数但不加时间趋势；shock_type=1 先使 di 当期增加1个百分点。
# 注意：lpirfs 的 shock_type=0 按冲击变量的简约式残差标准差归一化，
# 与 vars::irf 的一个结构标准差冲击并非相同尺度，不能直接比较。
# use_nw=TRUE 使用 Newey-West 标准误；num_cores=1 避免初学者处理并行设置。
lp_model <- lpirfs::lp_lin(as.data.frame(d_train), lags_endog_lin = 2,
  trend = 0, shock_type = 1, confint = 1.96, hor = 12,
  use_nw = TRUE, num_cores = 1)
# 数组的维度依次是：响应变量、期限(h=0,...,12)、冲击变量。
# 用 VAR 的当期利率响应缩放 LP：两条曲线都对应同样大小的利率创新。
lp_scale <- irf_rate$irf$di[1, "di"]
# lp_scale 为正数，点估计和区间端点均乘它；这是条件于估计尺度的近似区间，
# 未另外计入识别矩阵及 lp_scale 的估计误差。
lp_comparison <- data.frame(horizon = 0:12,
  VAR = irf_rate$irf$di[, "dx"],
  VAR_low = irf_rate$Lower$di[, "dx"], VAR_up = irf_rate$Upper$di[, "dx"],
  LP = lp_model$irf_lin_mean[1, , 3] * lp_scale,
  LP_low = lp_model$irf_lin_low[1, , 3] * lp_scale,
  LP_up = lp_model$irf_lin_up[1, , 3] * lp_scale)
lp_comparison
write.csv(lp_comparison, "Lab2_output/var_lp_comparison.csv", row.names = FALSE)
png("Lab2_output/15_var_lp.png", width = 1400, height = 1000, res = 150)
matplot(0:12, lp_comparison[, c("VAR", "VAR_low", "VAR_up", "LP", "LP_low", "LP_up")],
  type = "l", lty = c(1, 2, 2, 1, 3, 3), col = c(rep("navy", 3), rep("firebrick", 3)),
  xlab = "Quarters after shock", ylab = "Response of change in output gap",
  main = "VAR and LP: rate innovation, pointwise 95% intervals")
abline(h = 0, col = "grey60")
legend("bottomright", c("VAR", "LP"), col = c("navy", "firebrick"), lty = 1)
dev.off()
# LP 各期限单独回归，曲线可能更不平滑、长端区间更宽；不自动优于 VAR。
# 这里两者用相同递归识别；LP 不会替你解决遗漏变量或因果识别。
# 两种区间的构造不同（VAR残差bootstrap；LP Newey-West），都是逐点而非同时区间。
# 不能因许多期限中的一个区间不跨0，就声称整个动态路径显著。

# 16. 固定原点的样本外预测：只比较未用于拟合的12期 ---------------------------
# 所有预测在2005Q3结束时一次形成；h=1,...,12不是12次滚动一步预测。
# 使用冻结历史数据做伪样本外比较；GDP及潜在产出可能经事后修订，
# 所以这不等同于完全使用2005Q3实时可得数据的预测实验。
# 比较VAR(1)、VAR(2)、单变量AR(2)，以及变化量为0的基准。
# AR(2)与VAR(2)保持相同滞后长度，区别在于有没有其他变量的滞后信息。
pred_1 <- predict(var_1, n.ahead = 12, ci = 0.95)
pred_2 <- predict(var_2, n.ahead = 12, ci = 0.95)
ar_dx <- forecast::Arima(d_train[, "dx"], order = c(2, 0, 0), include.mean = TRUE)
ar_dpi <- forecast::Arima(d_train[, "dpi"], order = c(2, 0, 0), include.mean = TRUE)
ar_di <- forecast::Arima(d_train[, "di"], order = c(2, 0, 0), include.mean = TRUE)
pred_ar_dx <- forecast::forecast(ar_dx, h = 12)
pred_ar_dpi <- forecast::forecast(ar_dpi, h = 12)
pred_ar_di <- forecast::forecast(ar_di, h = 12)

# cbind 把各变量的预测并列；矩阵每行一个期限，每列一个变量。
fc_var1 <- cbind(pred_1$fcst$dx[, "fcst"], pred_1$fcst$dpi[, "fcst"], pred_1$fcst$di[, "fcst"])
fc_var2 <- cbind(pred_2$fcst$dx[, "fcst"], pred_2$fcst$dpi[, "fcst"], pred_2$fcst$di[, "fcst"])
fc_ar <- cbind(as.numeric(pred_ar_dx$mean), as.numeric(pred_ar_dpi$mean), as.numeric(pred_ar_di$mean))
fc_zero <- matrix(0, nrow = 12, ncol = 3)

# 恢复水平：预测起点最后一个已知水平 + 逐期累加的预测变化。
# 不能把每一期真实测试值用于下一期还原，那会偷偷变成另一种预测实验。
last_level <- as.numeric(tail(y_train, 1))
level_var1 <- cbind(last_level[1] + cumsum(fc_var1[, 1]),
  last_level[2] + cumsum(fc_var1[, 2]), last_level[3] + cumsum(fc_var1[, 3]))
level_var2 <- cbind(last_level[1] + cumsum(fc_var2[, 1]),
  last_level[2] + cumsum(fc_var2[, 2]), last_level[3] + cumsum(fc_var2[, 3]))
level_ar <- cbind(last_level[1] + cumsum(fc_ar[, 1]),
  last_level[2] + cumsum(fc_ar[, 2]), last_level[3] + cumsum(fc_ar[, 3]))
level_naive <- matrix(rep(last_level, each = 12), nrow = 12)
# 零变化预测对应水平保持在2005Q3值；它是常用随机游走点预测基准。
# 只恢复点预测。累计差分预测区间需要跨期协方差，不能把上下界直接相加。

# 17. 用相同变量、相同12期比较 RMSE 和 MAE ------------------------------------
# colMeans 是已有矩阵函数，按列求平均，不需要自己写循环。
# RMSE 对大误差更敏感，MAE 是平均绝对误差；二者都越小越好。
error_d1 <- as.matrix(d_test) - fc_var1
error_d2 <- as.matrix(d_test) - fc_var2
error_da <- as.matrix(d_test) - fc_ar
error_d0 <- as.matrix(d_test) - fc_zero
rmse_changes <- rbind(VAR1 = sqrt(colMeans(error_d1^2)), VAR2 = sqrt(colMeans(error_d2^2)),
  AR2 = sqrt(colMeans(error_da^2)), Zero = sqrt(colMeans(error_d0^2)))
mae_changes <- rbind(VAR1 = colMeans(abs(error_d1)), VAR2 = colMeans(abs(error_d2)),
  AR2 = colMeans(abs(error_da)), Zero = colMeans(abs(error_d0)))
rmse_changes
mae_changes
write.csv(rmse_changes, "Lab2_output/rmse_changes.csv")
write.csv(mae_changes, "Lab2_output/mae_changes.csv")

error_l1 <- as.matrix(y_test) - level_var1
error_l2 <- as.matrix(y_test) - level_var2
error_la <- as.matrix(y_test) - level_ar
error_l0 <- as.matrix(y_test) - level_naive
rmse_levels <- rbind(VAR1 = sqrt(colMeans(error_l1^2)), VAR2 = sqrt(colMeans(error_l2^2)),
  AR2 = sqrt(colMeans(error_la^2)), Naive = sqrt(colMeans(error_l0^2)))
mae_levels <- rbind(VAR1 = colMeans(abs(error_l1)), VAR2 = colMeans(abs(error_l2)),
  AR2 = colMeans(abs(error_la)), Naive = colMeans(abs(error_l0)))
rmse_levels
mae_levels
write.csv(rmse_levels, "Lab2_output/rmse_levels.csv")
write.csv(mae_levels, "Lab2_output/mae_levels.csv")
# 各变量单位不同，不把三列RMSE直接平均为一个总排名。
# 这里只有一个预测原点、12个不同期限；不对它们机械做标准DM显著性检验。
# 测试期包含金融危机初期，误差不代表其他时期一定有相同排名。
# 不能利用这个测试集不断重新调参后仍把它称为独立测试集。

forecast_table <- data.frame(quarter = format(zoo::as.yearqtr(time(y_test)), "%Y Q%q"),
  x_actual = y_test[, "x"], x_VAR1 = level_var1[, 1], x_VAR2 = level_var2[, 1],
  x_AR2 = level_ar[, 1], x_naive = level_naive[, 1],
  pi_actual = y_test[, "pi"], pi_VAR2 = level_var2[, 2],
  i_actual = y_test[, "i"], i_VAR2 = level_var2[, 3])
write.csv(forecast_table, "Lab2_output/forecast_levels.csv", row.names = FALSE)
png("Lab2_output/16_forecast_gap.png", width = 1400, height = 900, res = 150)
matplot(1:12, forecast_table[, c("x_actual", "x_VAR1", "x_VAR2", "x_AR2", "x_naive")],
  type = "l", lty = c(1, 2, 1, 3, 4), col = c("black", "darkgreen", "navy", "firebrick", "grey50"),
  xlab = "Forecast horizon (quarters from 2005 Q3)", ylab = "Output gap (log percent)",
  main = "Fixed-origin forecasts: 2005 Q4 - 2008 Q3")
legend("bottomleft", c("Actual", "VAR(1)", "VAR(2)", "AR(2)", "Naive"),
  col = c("black", "darkgreen", "navy", "firebrick", "grey50"), lty = c(1, 2, 1, 3, 4))
dev.off()

# 18. 扩展：样本与变换的敏感性 ------------------------------------------------
# A. 恢复1965Q1起的全部历史训练样本，仍不使用测试期。
# 它可能混合不同制度；即使差分平稳，也不保证固定系数VAR刻画充分。
d_long <- diff(window(y_all, end = c(2005, 3)))
long_selection <- VARselect(d_long, lag.max = 8, type = "const")
long_selection$selection
var_long <- VAR(d_long, p = as.integer(long_selection$selection["AIC(n)"]), type = "const")
serial.test(var_long, lags.pt = 16, type = "PT.adjusted")
arch.test(var_long, lags.multi = 2)
# 若拒绝残差无自相关/无ARCH，不能只因根<1就把IRF当作可靠结论。
# 可进一步研究断点、制度、更多变量或不同动态设定，并保留样本选择的记录。

# B. 水平VAR仅作敏感性比较，前面单位根检验的不确定性并未消失。
var_levels <- VAR(y_train, p = 2, type = "const")
roots(var_levels)
level_irf <- irf(var_levels, impulse = "i", response = c("x", "i"),
  n.ahead = 12, ortho = TRUE, boot = FALSE)
# 同为当期利率+1个百分点：水平VAR的x响应与差分VAR的累计dx响应才是对应对象。
transformation_comparison <- data.frame(horizon = 0:12,
  levels_VAR = level_irf$irf$i[, "x"] / level_irf$irf$i[1, "i"],
  differenced_VAR_cumulative = irf_cumulative$irf$di[, "dx"] / irf_rate$irf$di[1, "di"])
transformation_comparison
write.csv(transformation_comparison, "Lab2_output/transformation_comparison.csv", row.names = FALSE)
# 水平VAR若有单位根/协整，标准稳定VAR的推断需重审；不能只挑喜欢的曲线。
# 研究共同长期均衡时应转向协整检验/VECM，而不是把本例差分当作统一模板。

# 19. 保存运行环境与重点输出 --------------------------------------------------
capture.output(sessionInfo(), file = "Lab2_output/sessionInfo.txt")
capture.output(summary(var_model), normal_2, granger_rate, granger_macro,
  file = "Lab2_output/model_summary.txt")
# 报告时同时写明：变量定义与单位、样本、变换、确定性项、滞后、诊断、识别假设、
# 冲击尺度、置信区间和预测设计。统计显著性与经济重要性需要分别说明。
# 所有图表已经保存到 Lab2_output；原CSV没有被改写。
