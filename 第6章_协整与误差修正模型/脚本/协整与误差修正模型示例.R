# 第6章：协整与误差修正模型示例
# 说明：本脚本优先使用成熟 R package，不手写已有估计程序。
# packages: urca, vars

library(urca)
library(vars)

# urca 包内置 denmark 数据，常用于货币需求、协整和 VECM 示例。
data(denmark)

denmark_data <- denmark[, c("LRM", "LRY", "IBO", "IDE")]
head(denmark_data)

# 1. 单位根检验：以 LRM 为例
adf_lrm <- ur.df(denmark_data$LRM, type = "trend", lags = 4)
summary(adf_lrm)

# 2. Engle-Granger 思路：先估计长期关系，再检验残差是否平稳
# 这里只作为教学演示。正式检验应使用适合残差协整检验的临界值。
eg_long_run <- lm(LRM ~ LRY + IBO + IDE, data = denmark_data)
summary(eg_long_run)

eg_resid <- residuals(eg_long_run)
eg_resid_adf <- ur.df(eg_resid, type = "none", lags = 4)
summary(eg_resid_adf)

# 也可以直接使用 urca::ca.po() 进行 Phillips-Ouliaris 协整检验
po_test <- ca.po(denmark_data, demean = "constant", type = "Pz")
summary(po_test)

# 3. Johansen 协整检验
# K 是 VAR 的水平滞后阶数。VECM 中差分滞后阶数为 K - 1。
lag_selection <- VARselect(denmark_data, lag.max = 6, type = "const")
print(lag_selection$selection)

jo_trace <- ca.jo(
  denmark_data,
  type = "trace",
  ecdet = "const",
  K = 2,
  spec = "transitory"
)
summary(jo_trace)

jo_eigen <- ca.jo(
  denmark_data,
  type = "eigen",
  ecdet = "const",
  K = 2,
  spec = "transitory"
)
summary(jo_eigen)

# 4. 估计 VECM：假定协整秩 r = 1
vecm_r1 <- cajorls(jo_trace, r = 1)
summary(vecm_r1$rlm)

# 协整向量 beta 和调整系数 alpha
beta_hat <- jo_trace@V[, 1, drop = FALSE]
alpha_hat <- jo_trace@W[, 1, drop = FALSE]
print(beta_hat)
print(alpha_hat)

# 5. 将 VECM 转换为水平 VAR 表示，用于脉冲响应分析
vec_as_var <- vec2var(jo_trace, r = 1)

irf_vecm <- irf(
  vec_as_var,
  impulse = "IBO",
  response = "LRM",
  n.ahead = 20,
  boot = FALSE
)

# 正式实证报告中可考虑 bootstrap 置信区间。
if (FALSE) {
  irf_vecm_boot <- irf(
    vec_as_var,
    impulse = "IBO",
    response = "LRM",
    n.ahead = 20,
    boot = TRUE,
    ci = 0.90,
    runs = 1000
  )
  plot(irf_vecm_boot)
}

# 如需查看图形，可取消以下注释：
# plot(irf_vecm)
