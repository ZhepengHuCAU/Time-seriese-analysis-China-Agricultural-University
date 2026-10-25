# Kilian (2009)：正文分析（vars 包版本）
# 在 RStudio 中打开本项目后运行，或按以下章节逐段讲解。
# 本文件只读取已整理的 Excel，不下载、清洗或重新变换源数据。

# 0. 加载包与辅助函数 --------------------------------------------------------
if (dir.exists('.r_library')) .libPaths(c(normalizePath('.r_library'), .libPaths()))
library(vars)
library(openxlsx)
source('R/functions_svar.R', encoding = 'UTF-8')
source('R/plots.R', encoding = 'UTF-8')
dir.create('output/cache', recursive = TRUE, showWarnings = FALSE)

# 1. 从 Excel 读取正文所需数据 ----------------------------------------------
data_file <- 'data/kilian_analysis_data.xlsx'
if (!file.exists(data_file)) stop('请先运行 01_prepare_data.R 生成 Excel。')
monthly <- read.xlsx(data_file, sheet = 'monthly_svar', detectDates = TRUE)
quarterly <- read.xlsx(data_file, sheet = 'quarterly_macro', detectDates = TRUE)
y <- as.matrix(monthly[, c('dprod', 'rea', 'rpo')])
stopifnot(nrow(y) == 419L, nrow(quarterly) == 132L, all(is.finite(y)))

# 2. 简约式 VAR：24 个月滞后，加常数项 ---------------------------------------
var_fit <- VAR(y, p = 24, type = 'const')
summary(var_fit)
roots(var_fit)                       # 稳定性：所有特征值模小于 1

# 3. SVAR：递归的 B-model ---------------------------------------------------
# u_t = B * epsilon_t；NA 表示待估计参数，0 表示当期零限制。
# 顺序：产量增长 → 全球经济活动 → 实际油价。
B_restrictions <- matrix(c(
  NA,  0,  0,
  NA, NA,  0,
  NA, NA, NA
), nrow = 3, byrow = TRUE)

svar_fit <- SVAR(var_fit, estmethod = 'scoring', Bmat = B_restrictions,
                 max.iter = 1000, conv.crit = 1e-10, lrtest = FALSE)
summary(svar_fit)
svar_fit$B                         # 估计得到的当期影响矩阵

# 4. 结构冲击：原文图 2 -----------------------------------------------------
reduced_residuals <- residuals(var_fit)
structural_shocks <- t(solve(svar_fit$B, t(reduced_residuals)))
colnames(structural_shocks) <- c('oil_supply', 'aggregate_demand', 'oil_specific_demand')
aggregated <- aggregate_shocks(structural_shocks)
# 图 2 使用年均冲击；季度均值用于下面的 GDP/CPI 第二阶段回归。

# 5. 结构脉冲响应：原文图 3 -------------------------------------------------
irf_package <- irf(svar_fit, n.ahead = 15, boot = FALSE)
# 不设 cumulative=TRUE，因为那样会把全部变量累计。
# 原文只累计产量增长响应；供给冲击转为负向，代表供给收缩。
irf_paper <- paper_irf(irf_package)

# 6. 实际油价历史分解：原文图 4 ---------------------------------------------
historical <- historical_svar(var_fit, svar_fit, structural_shocks)
# 历史油价 = 供给贡献 + 总需求贡献 + 石油特定需求贡献 + 常数/初始条件。

# 7. 美国 GDP、CPI 对冲击的响应：原文图 5 ------------------------------------
# 每个宏观变量分别对一类冲击的当期至 12 季滞后回归；不额外加入自身滞后。
# GDP 增长和 CPI 通胀已在 01_prepare_data.R 整理好。
macro_fits <- vector('list', 6)
macro_irf <- array(NA_real_, c(13, 2, 3))
for (shock in 1:3) {
  for (outcome in 1:2) {
    growth <- quarterly[, c('gdp_growth_ann', 'cpi_inflation_ann')[outcome]]
    fit <- fit_macro_irf(growth, aggregated$quarterly[, shock])
    macro_fits[[(shock - 1) * 2 + outcome]] <- fit
    macro_irf[, outcome, shock] <- fit$cumulative * if (shock == 1) -1 else 1
  }
}

# 8. 原文误差带：VAR wild bootstrap；宏观方程 4 季 block bootstrap ------------
# vars::irf() 的默认 bootstrap 与论文不同，所以不直接使用默认误差带。
# 辅助函数中的每次 VAR/SVAR 重估仍由 vars 包执行。
quick <- '--quick' %in% commandArgs(trailingOnly = TRUE)
bands <- paper_error_bands(var_fit, svar_fit, B_restrictions, macro_fits,
                          reps_var = if (quick) 50L else 2000L,
                          reps_macro = if (quick) 500L else 20000L)

# 9. 补充：预测误差方差分解（调用 vars::fevd）--------------------------------
fevd_package <- fevd(svar_fit, n.ahead = 60)
horizons <- c(1, 3, 6, 12, 24, 60)
fevd_rows <- list()
for (h in horizons) for (i in 1:3) {
  fevd_rows[[length(fevd_rows) + 1L]] <- data.frame(
    horizon_months = h, response = i, shock = 1:3,
    share_pct = 100 * fevd_package[[i]][h, ]
  )
}
fevd_table <- do.call(rbind, fevd_rows)

# 10. 直接作图：每行可单独运行，不保存图片 ----------------------------------
# 图形显示在 RStudio 的 Plots 窗口；用前后箭头查看，Zoom 放大。
# 多面板图建议先扩大 Plots 窗口，再运行相应语句。
plot_model_inputs(var_fit, monthly$date)                 # 三个模型变量
plot_annual_shocks(aggregated)                           # 原文图 2
plot_impulse_responses(irf_paper, bands$oil_se)            # 原文图 3
plot_historical_decomposition(
  historical, monthly$date[(var_fit$p + 1L):nrow(monthly)] # 原文图 4
)
plot_macro_responses(macro_irf, bands$macro_se)            # 原文图 5
plot_macro_responses(macro_irf, bands$macro_se,
                     log_percent = TRUE)                # 图 5 的对数百分比尺度
plot_fevd(fevd_table)                                    # 补充：方差分解

# 11. 保存数值结果，供独立核验使用（不保存图片）------------------------------
results <- list(monthly = monthly, quarterly = quarterly, var = var_fit, svar = svar_fit,
                shocks = structural_shocks, aggregated = aggregated,
                irf_package = irf_package, irf = irf_paper, hd = historical,
                macro_fits = macro_fits, macro = macro_irf, bands = bands,
                fevd_package = fevd_package, fevd = fevd_table)
export_analysis(results)
cat('正文分析完成。图形在绘图窗口显示；数值结果保存在 output 文件夹。\n')
