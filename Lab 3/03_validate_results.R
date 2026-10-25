# 独立核验文件：不放进正文分析，以保持课堂讲解清楚。
# 在完成 02_analysis.R 后运行。
if (dir.exists('.r_library')) .libPaths(c(normalizePath('.r_library'), .libPaths()))
library(vars)
library(openxlsx)
r <- readRDS('output/replication_results_vars.rds')
ref <- function(file) as.matrix(read.csv(file.path('references/author_mirror', file), header = FALSE))
oil_original <- as.matrix(read.table('references/author_mirror/data.txt'))
gdp_original <- read.table('references/author_mirror/beagdp.txt')
cpi_original <- read.table('references/author_mirror/cpi.txt')
irf_unsigned <- r$irf; irf_unsigned[, 1, ] <- -irf_unsigned[, 1, ]
macro_unsigned <- r$macro; macro_unsigned[, , 1] <- -macro_unsigned[, , 1]
sigma <- crossprod(residuals(r$var)) / df.residual(r$var$varresult[[1]])
reconstruction <- r$hd$baseline + apply(r$hd$contributions, c(1, 2), sum)

checks <- data.frame(
  check = c('Excel_monthly_vs_original', 'Excel_GDP_growth_vs_original', 'Excel_CPI_inflation_vs_original',
    'SVAR_B_vs_Cholesky_benchmark', 'Figure3_vs_archived_MATLAB', 'Figure4_vs_archived_MATLAB',
    'Figure5_GDP_vs_archived_MATLAB', 'Figure5_CPI_vs_archived_MATLAB',
    'Historical_decomposition_reconstruction', 'Structural_covariance_reconstruction',
    'Structural_shock_orthogonality', 'FEVD_sums_to_100'),
  max_abs_difference = c(
    max(abs(as.matrix(r$monthly[, c('dprod','rea','rpo')]) - oil_original)),
    max(abs(r$quarterly$gdp_growth_ann - 400*diff(log(gdp_original[,3])))),
    max(abs(r$quarterly$cpi_inflation_ann - 400*diff(log(cpi_original[seq(1,397,3),3])))),
    max(abs(r$svar$B - t(chol(sigma)))),
    max(abs(matrix(irf_unsigned,9,16) - ref('dat_figure3-IRF.csv'))),
    max(abs(r$hd$contributions[,3,] - ref('dat_figure4-historical-decomposition.csv'))),
    max(abs(macro_unsigned[,1,] - ref('dat_figure5-irf2-gdp.csv')[,c(2,5,8)])),
    max(abs(macro_unsigned[,2,] - ref('dat_figure5-irf2-cpi.csv')[,c(2,5,8)])),
    max(abs(reconstruction - oil_original[25:419,])),
    max(abs(tcrossprod(r$svar$B) - sigma)),
    max(abs(crossprod(r$shocks)/322 - diag(3))),
    max(abs(aggregate(share_pct~horizon_months+response,r$fevd,sum)$share_pct-100)))
)
checks$tolerance <- 1e-7
checks$pass <- checks$max_abs_difference < checks$tolerance
write.csv(checks, 'output/validation_checks.csv', row.names = FALSE)
stopifnot(all(checks$pass), all(diag(r$svar$B) > 0), max(roots(r$var)) < 1)
stopifnot(inherits(r$var, 'varest'), inherits(r$svar, 'svarest'))
se_reference <- ref('dat_figure3-CI.csv')
se_compare <- data.frame(response=rep(colnames(r$var$y),3),shock=rep(1:3,each=3),
  mean_se_R=rowMeans(matrix(r$bands$oil_se,9,16)), mean_se_MATLAB=rowMeans(se_reference),
  max_abs_se_difference=apply(abs(matrix(r$bands$oil_se,9,16)-se_reference),1,max))
write.csv(se_compare, 'output/bootstrap_se_comparison.csv', row.names=FALSE)
print(checks, row.names=FALSE)
cat('12 项检查通过。估计对象确认为 vars::VAR / vars::SVAR 返回类型。\n')
