# 广义脉冲响应（GIRF）：Canada 数据中的排序比较。
# 在 RStudio 中运行；图形显示在 Plots，不自动保存文件。
# 首次使用：install.packages('vars')
# 方法：Pesaran & Shin (1998), doi:10.1016/S0165-1765(97)00214-0。
# VAR、MA 系数与 OIRF 使用 vars 的公开接口；GIRF 按公式组合。
# 本示例只给点估计，不计算 GIRF 置信区间。

library(vars)
data('Canada', package = 'vars')

# 1. 线性 VAR 的 GIRF：指定约简式创新增加一个标准差。
girf_linear <- function(fit, impulse, n.ahead = 20L) {
  stopifnot(inherits(fit, 'varest'), length(impulse) == 1L,
            impulse %in% colnames(fit$y), length(n.ahead) == 1L,
            is.finite(n.ahead), n.ahead >= 0, n.ahead == as.integer(n.ahead))
  ma <- vars::Phi(fit, nstep = n.ahead) # 普通 MA 系数；本章记为 Psi_h
  u <- residuals(fit)
  # 与 vars::Psi() / irf(ortho=TRUE) 保持相同的残差自由度调整。
  Sigma <- crossprod(u) / df.residual(fit$varresult[[1]])
  impact <- Sigma[, impulse] / sqrt(Sigma[impulse, impulse])
  out <- t(vapply(seq_len(n.ahead + 1L), function(h) {
    drop(ma[, , h] %*% impact)
  }, numeric(ncol(u))))
  dimnames(out) <- list(0:n.ahead, colnames(u))
  out
}

# 2. 只改变变量排列，其他变量、样本、滞后阶数和确定性项保持相同。
H <- 20L
fit_last <- VAR(Canada[, c('e', 'prod', 'rw', 'U')], p = 2, type = 'const')
fit_first <- VAR(Canada[, c('U', 'e', 'prod', 'rw')], p = 2, type = 'const')
cat('Maximum companion root modulus:', max(roots(fit_last)), '\n')

g_last <- girf_linear(fit_last, 'U', H)
g_first <- girf_linear(fit_first, 'U', H)
g_first <- g_first[, colnames(g_last), drop = FALSE] # 按变量名对齐，而非列位置
o_last <- irf(fit_last, impulse = 'U', n.ahead = H,
              ortho = TRUE, boot = FALSE)$irf$U
o_first <- irf(fit_first, impulse = 'U', n.ahead = H,
               ortho = TRUE, boot = FALSE)$irf$U
o_first <- o_first[, colnames(g_last), drop = FALSE]
ordinary <- irf(fit_last, impulse = 'U', n.ahead = H,
                ortho = FALSE, boot = FALSE)$irf$U

# 一个标准差的约简式 U 创新，与正交化 U 创新的标准差不是同一个尺度。
# 比较图统一为 U 当期上升 1 个百分点；e 的单位是 100 * log(就业)。
g_unit <- g_last / g_last[1, 'U']
o_last_unit <- o_last / o_last[1, 'U']
o_first_unit <- o_first / o_first[1, 'U']

# 3. 数值核验：GIRF 排序不变；把 U 放第一时，对 U 的 OIRF 等于 GIRF。
checks <- c(
  GIRF_reordering_max_error = max(abs(g_last - g_first)),
  GIRF_vs_U_first_OIRF_max_error = max(abs(g_last - o_first)),
  OIRF_reordering_difference_same_scale = max(abs(o_last_unit - o_first_unit)),
  ordinary_IRF_vs_GIRF_same_scale = max(abs(ordinary - g_unit))
)
print(checks)
stopifnot(checks[1] < 1e-8, checks[2] < 1e-8,
          checks[3] > 1e-3, checks[4] > 1e-3)

comparison <- data.frame(
  quarter = 0:H,
  GIRF_employment = g_unit[, 'e'],
  OIRF_U_last_employment = o_last_unit[, 'e'],
  OIRF_U_first_employment = o_first_unit[, 'e'],
  ordinary_IRF_employment = ordinary[, 'e']
)
print(comparison[comparison$quarter %in% c(0, 1, 4, 8, 12, 20), ], row.names = FALSE)

# 4. 直接作图。命令行无窗口时跳过，避免自动生成 Rplots.pdf。
draw_girf_comparison <- function() {
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par), add = TRUE)
  if (.Platform$OS.type == 'windows' && names(dev.cur()) %in% c('RStudioGD', 'windows')) {
    par(family = 'Microsoft YaHei')
  }
  lines_to_plot <- as.matrix(comparison[, 2:4])
  matplot(comparison$quarter, lines_to_plot, type = 'l', lty = c(1, 2, 3),
          lwd = c(3, 2, 2), col = c('#265A85', '#B37B21', '#754B78'),
          xlab = '冲击后季度数', ylab = '就业响应（100 × 对数点）',
          main = 'GIRF 与 OIRF：统一为失业率当期上升 1 个百分点')
  abline(h = 0, col = 'grey60', lty = 3)
  legend('bottomleft', c('GIRF（两种排序相同）', 'OIRF：U 排最后', 'OIRF：U 排最前（与 GIRF 重合）'),
         col = c('#265A85', '#B37B21', '#754B78'), lty = c(1, 2, 3), lwd = c(3, 2, 2),
         bty = 'n', cex = 0.8)
}
if (interactive() || dev.cur() > 1L) draw_girf_comparison()

# Canada 的水平 VAR 用于展示计算与排序性质，不代替单位根/协整检验。
# GIRF 是条件响应；这里的 U 创新不能直接命名为外生政策冲击。
# 完整文档：
# https://search.r-project.org/CRAN/refmans/vars/html/Phi.html
# https://search.r-project.org/CRAN/refmans/vars/html/irf.html
# https://search.r-project.org/CRAN/refmans/vars/html/Canada.html
