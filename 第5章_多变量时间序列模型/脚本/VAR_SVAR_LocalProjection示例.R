# 第5章：VAR、SVAR 与 Local Projection 示例
# 说明：本脚本优先使用成熟 R package，不手写估计程序。
# packages: vars, lpirfs

library(vars)
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

# 6. 递归 SVAR 示例
# 注意：这里的 B 矩阵限制仅用于课堂演示。
# 实际研究中，变量排序和零限制必须有明确经济依据。
B_matrix <- matrix(0, 4, 4)
B_matrix[lower.tri(B_matrix, diag = TRUE)] <- NA
colnames(B_matrix) <- rownames(B_matrix) <- colnames(Canada)

svar_model <- SVAR(var_model, Bmat = B_matrix, estmethod = "scoring")
print(summary(svar_model))

irf_svar <- irf(
  svar_model,
  impulse = "e",
  response = "prod",
  n.ahead = 20,
  boot = FALSE
)

# 7. Local Projection 示例
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
# plot(lp_model)
