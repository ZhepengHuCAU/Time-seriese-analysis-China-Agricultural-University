# 第5章：VAR、SVAR 与 Local Projection 示例
# 说明：本脚本优先使用成熟 R package，不手写估计程序。
# 代码出处：vars 文档的 Canada 接口示例及 svars::id.cv/id.garch/hd/cf、lpirfs::lp_lin 文档例程改编。
# 课程调整参数、对象名及展示顺序；该脚本不是上述论文完整复现程序。
# 作者引用：Pfaff (2008), doi:10.18637/jss.v027.i04；Lange et al. (2021), doi:10.18637/jss.v097.i05；
# Adämmer (2019), doi:10.32614/RJ-2019-052。
# 原例程许可：vars/lpirfs 为 GPL>=2；svars 1.3.12 为 MIT（版权与许可须保留）。
# 来源：https://search.r-project.org/CRAN/refmans/svars/html/id.cv.html
# 完整来源与许可：https://zhepenghucau.github.io/Time-seriese-analysis-China-Agricultural-University/版权与引用/
# packages: vars, svars, lpirfs

library(vars)
library(svars)
library(lpirfs)

data(Canada)

# 1. VAR 滞后阶数选择
lag_selection <- VARselect(Canada, lag.max = 8, type = "const")
print(lag_selection$selection)

# 2. 估计 VAR
var_model <- VAR(Canada, p = 2, type = "const")
print(summary(var_model))

# 3. 稳定性检查
print(roots(var_model))

# 4. Granger 因果检验
print(causality(var_model, cause = "e"))

# 5. VAR 脉冲响应
irf_var <- irf(
  var_model,
  impulse = "e",
  response = "prod",
  n.ahead = 20,
  boot = FALSE
)

# 正式实证报告中可使用 bootstrap 置信区间。
# 为节省课堂运行时间，下面代码默认不运行；需要时把 FALSE 改为 TRUE。
if (FALSE) {
  irf_var_boot <- irf(
    var_model,
    impulse = "e",
    response = "prod",
    n.ahead = 20,
    boot = TRUE,
    ci = 0.90,
    runs = 1000
  )
  plot(irf_var_boot)
}

# 6. 递归 SVAR 示例
# 注意：这里的 B 矩阵限制仅用于课堂演示。
# 实际研究中，变量排序和零限制必须有明确经济依据。
B_matrix <- matrix(0, 4, 4)
B_matrix[lower.tri(B_matrix, diag = TRUE)] <- NA
colnames(B_matrix) <- rownames(B_matrix) <- colnames(Canada)

svar_model <- vars::SVAR(var_model, Bmat = B_matrix, estmethod = "scoring")
print(summary(svar_model))

irf_svar <- vars::irf(
  svar_model,
  impulse = "e",
  response = "prod",
  n.ahead = 20,
  boot = FALSE
)

# 7. 基于异方差的 SVAR 识别示例
# svars 包内置 USA 数据，常用于演示 changes in volatility 识别。
data(USA, package = "svars")
var_usa <- VAR(USA, lag.max = 10, ic = "AIC")

# 7.1 无条件波动变化识别：Rigobon 型思想
# SB = 59 对应 svars 文档中的 1979Q3 前后波动变化示例。
svar_cv <- id.cv(var_usa, SB = 59)
print(summary(svar_cv))
print(svar_cv$Lambda)
print(svar_cv$B)

# 7.2 条件异方差识别：SVAR-GARCH 思想
# 课堂演示时可先运行 id.cv，再把 id.garch 作为扩展示例。
svar_garch <- id.garch(var_usa)
print(summary(svar_garch))

# 8. Historical decomposition（历史分解）
# 这里以 id.cv() 得到的 svar_cv 为例。
hd_x <- hd(svar_cv, series = 1)
print(head(hd_x[[1]]))

# 9. Counterfactual analysis（反事实分析）
cf_x <- cf(svar_cv, series = 1)
print(head(cf_x[[1]]))

# 10. Local Projection 示例
canada_df <- as.data.frame(Canada)

lp_model <- lp_lin(
  endog_data = canada_df,
  lags_endog_lin = 2,
  trend = 0,
  shock_type = 0,
  confint = 1.96,
  hor = 20
)

# 如需查看图形，可取消以下注释：
# plot(irf_var)
# plot(irf_svar)
# plot(irf(svar_cv, n.ahead = 30), scales = "free_y")
# plot(irf(svar_garch, n.ahead = 30), scales = "free_y")
# plot(hd_x)
# plot(cf_x)
# plot(lp_model)
