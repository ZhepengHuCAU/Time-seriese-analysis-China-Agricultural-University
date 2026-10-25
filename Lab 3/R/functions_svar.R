# 辅助函数：把重复计算放在这里，正文文件只保留分析步骤。
# 这里的 VAR/SVAR 估计、脉冲响应、MA 系数均调用 vars 包。

irf_to_array <- function(irf_object) {
  names_var <- irf_object$response
  k <- length(names_var); H <- nrow(irf_object$irf[[1]])
  a <- array(0, c(k, k, H))
  for (j in seq_len(k)) a[, j, ] <- t(irf_object$irf[[j]][, names_var, drop = FALSE])
  a
}

paper_irf <- function(irf_object) {
  a <- irf_to_array(irf_object)
  for (j in 1:3) a[1, j, ] <- cumsum(a[1, j, ]) # 产量增长累计为产量响应
  a[, 1, ] <- -a[, 1, ]                       # 展示供给收缩
  a
}

aggregate_shocks <- function(e) {
  # 作者的约定：1975-01 冲击以 2、3 月均值补齐，用于聚合。
  padded <- rbind(colMeans(e[1:2, , drop = FALSE]), e)
  list(monthly_padded = padded,
       quarterly = rowsum(padded, rep(1:132, each = 3)) / 3,
       annual = rowsum(padded, rep(1:33, each = 12)) / 12)
}

historical_svar <- function(var_fit, svar_fit, e) {
  # 用 vars::Phi() 返回的 MA 系数，计算每期每类冲击的贡献。
  T <- nrow(e); k <- ncol(e); p <- var_fit$p
  phi <- vars::Phi(var_fit, nstep = T - 1L)
  psi <- array(0, dim(phi))
  impact <- solve(svar_fit$A, svar_fit$B)
  for (h in seq_len(T)) psi[, , h] <- phi[, , h] %*% impact
  effects <- array(0, c(T, k, k))
  for (tt in seq_len(T)) for (j in seq_len(k)) for (i in seq_len(k)) {
    effects[tt, i, j] <- sum(psi[i, j, seq_len(tt)] * e[tt:1, j])
  }
  # 常数与初始条件另外递推，不能用三条冲击线直接替代实际价格。
  aa <- vars::Acoef(var_fit)
  constant <- vars::Bcoef(var_fit)[, 'const']
  base <- matrix(0, nrow(var_fit$y), k); base[1:p, ] <- var_fit$y[1:p, ]
  for (tt in (p + 1L):nrow(base)) {
    base[tt, ] <- constant
    for (l in seq_len(p)) base[tt, ] <- base[tt, ] + aa[[l]] %*% base[tt - l, ]
  }
  list(contributions = effects, baseline = base[(p + 1L):nrow(base), , drop = FALSE])
}

wild_bootstrap_vars <- function(var_fit, svar_fit, restrictions, reps = 2000L, seed = 1234L) {
  # irf(..., boot=TRUE) 的默认残差 bootstrap 不等于原文 wild bootstrap。
  # 因此模拟步骤按原文写；每一次重估仍使用 vars::VAR() / vars::SVAR()。
  set.seed(seed)
  y <- var_fit$y; p <- var_fit$p; n <- nrow(y); k <- ncol(y)
  u <- residuals(var_fit); beta <- vars::Bcoef(var_fit)
  draws <- array(NA_real_, c(k, k, 16L, reps))
  for (b in seq_len(reps)) {
    pos <- sample.int(n - p + 1L, 1L)
    yy <- matrix(0, n, k, dimnames = list(NULL, colnames(y)))
    yy[1:p, ] <- y[pos:(pos + p - 1L), ]
    ub <- u * rnorm(nrow(u)) # 同月三方程共用一个正态乘子
    for (tt in (p + 1L):n) {
      x <- c(as.vector(t(yy[(tt - 1L):(tt - p), , drop = FALSE])), 1)
      yy[tt, ] <- drop(beta %*% x) + ub[tt - p, ]
    }
    vb <- vars::VAR(yy, p = p, type = 'const')
    sb <- vars::SVAR(vb, estmethod = 'scoring', Bmat = restrictions,
      start = svar_fit$B[is.na(restrictions)], max.iter = 1000, maxls = 5,
      conv.crit = 1e-10, lrtest = FALSE)
    if (sb$iter >= 999L) stop('SVAR bootstrap 未收敛，请检查本次重复。')
    draws[, , , b] <- paper_irf(vars::irf(sb, n.ahead = 15, boot = FALSE))
    if (b %% 100L == 0L) cat(sprintf('vars/SVAR wild bootstrap: %d/%d\n', b, reps))
  }
  apply(draws, 1:3, sd)
}

fit_macro_irf <- function(growth, shock) {
  lags <- embed(as.numeric(shock), 13L)
  colnames(lags) <- paste0('shock_lag', 0:12)
  regression_data <- data.frame(growth = growth[13:length(growth)], lags)
  model <- stats::lm(growth ~ ., data = regression_data)
  list(model = model, cumulative = cumsum(stats::coef(model)[-1]),
       X = model.matrix(model), y = model.response(model.frame(model)))
}

block_bootstrap_macro <- function(fit, reps = 20000L, seed = 1234L) {
  set.seed(seed)
  n <- length(fit$y); block <- 4L
  draws <- matrix(NA_real_, reps, 13)
  for (b in seq_len(reps)) {
    # 原作者抽取起点 1,...,n-4（保留其排除最后一个可用起点的约定）。
    starts <- sample.int(n - block, ceiling(n / block), replace = TRUE)
    ix <- as.vector(vapply(starts, function(s) s + 0:3, integer(4)))[seq_len(n)]
    coef <- stats::lm.fit(fit$X[ix, , drop = FALSE], fit$y[ix])$coefficients[-1]
    draws[b, ] <- cumsum(coef)
  }
  stopifnot(all(is.finite(draws)))
  apply(draws, 2L, sd)
}

paper_error_bands <- function(var_fit, svar_fit, restrictions, macro_fits,
                             reps_var = 2000L, reps_macro = 20000L) {
  key <- list(workbook = tools::md5sum('data/kilian_analysis_data.xlsx'),
              helper = tools::md5sum('R/functions_svar.R'),
              vars_version = as.character(packageVersion('vars')),
              reps = c(reps_var, reps_macro), seed = 1234L)
  path <- sprintf('output/cache/vars_bootstrap_%d_%d.rds', reps_var, reps_macro)
  if (file.exists(path)) {
    old <- readRDS(path)
    if (identical(old$key, key)) return(old)
  }
  oil_se <- wild_bootstrap_vars(var_fit, svar_fit, restrictions, reps_var)
  macro_se <- array(NA_real_, c(13, 2, 3))
  for (j in 1:3) for (i in 1:2) {
    cat(sprintf('Macro block bootstrap: shock=%d, outcome=%d, draws=%d\n', j, i, reps_macro))
    macro_se[, i, j] <- block_bootstrap_macro(macro_fits[[(j - 1) * 2 + i]], reps_macro)
  }
  out <- list(key = key, oil_se = oil_se, macro_se = macro_se)
  saveRDS(out, path)
  out
}

export_analysis <- function(result) {
  r <- result; shocks <- c('oil_supply', 'aggregate_demand', 'oil_specific_demand')
  x <- r$monthly; e <- r$shocks; p <- r$var$p
  colnames(e) <- shocks
  write.csv(data.frame(date = x$date[(p + 1):nrow(x)], e), 'output/shocks_monthly.csv', row.names = FALSE)
  write.csv(data.frame(date = r$quarterly$date, r$aggregated$quarterly), 'output/shocks_quarterly.csv', row.names = FALSE)
  write.csv(data.frame(year = 1975:2007, r$aggregated$annual), 'output/fig2_annual_shocks.csv', row.names = FALSE)
  write.csv(data.frame(date = x$date[(p + 1):nrow(x)], oil_supply = r$hd$contributions[, 3, 1],
    aggregate_demand = r$hd$contributions[, 3, 2], oil_specific_demand = r$hd$contributions[, 3, 3],
    deterministic_initial = r$hd$baseline[, 3], observed = x$rpo[(p + 1):nrow(x)]),
    'output/fig4_historical_decomposition.csv', row.names = FALSE)
  irf_rows <- macro_rows <- list()
  for (j in 1:3) for (i in 1:3) {
    z <- r$irf[i, j, ]; se <- r$bands$oil_se[i, j, ]
    irf_rows[[length(irf_rows) + 1L]] <- data.frame(month = 0:15, response = colnames(r$var$y)[i], shock = shocks[j],
      estimate = z, bootstrap_se = se, lower_1se = z-se, upper_1se = z+se, lower_2se = z-2*se, upper_2se = z+2*se)
  }
  for (j in 1:3) for (i in 1:2) {
    z <- r$macro[, i, j]; se <- r$bands$macro_se[, i, j]
    macro_rows[[length(macro_rows) + 1L]] <- data.frame(quarter = 0:12, response = c('real_gdp', 'cpi')[i], shock = shocks[j],
      estimate_original_scale = z, bootstrap_se_original_scale = se, lower_1se = z-se, upper_1se = z+se,
      lower_2se = z-2*se, upper_2se = z+2*se, estimate_log_percent = z/4, bootstrap_se_log_percent = se/4)
  }
  write.csv(do.call(rbind, irf_rows), 'output/fig3_impulse_responses.csv', row.names = FALSE)
  write.csv(do.call(rbind, macro_rows), 'output/fig5_macro_responses.csv', row.names = FALSE)
  write.csv(r$fevd, 'output/extra_fevd.csv', row.names = FALSE)
  write.csv(vars::Bcoef(r$var), 'output/var_coefficients.csv')
  write.csv(r$svar$B, 'output/cholesky_impact_positive_supply.csv')
  write.csv(crossprod(residuals(r$var)) / df.residual(r$var$varresult[[1]]), 'output/var_residual_covariance.csv')
  saveRDS(r, 'output/replication_results_vars.rds')
  writeLines(capture.output(sessionInfo()), 'output/sessionInfo.txt')
  writeLines(c(sprintf('vars %s; openxlsx %s', packageVersion('vars'), packageVersion('openxlsx')),
    sprintf('Completed: %s', Sys.time()),
    'Input: data/kilian_analysis_data.xlsx; preparation is separate from analysis.',
    'VAR(24), intercept; 419 inputs, 395 effective months; residual df=322.',
    'SVAR: lower triangular B-model, scoring estimation, positive diagonal.',
    sprintf('SVAR scoring iterations: %d; maximum root: %.9f', r$svar$iter, max(vars::roots(r$var))),
    sprintf('Wild bootstrap=%d; macro block bootstrap=%d per equation; seed=1234.', r$bands$key$reps[1], r$bands$key$reps[2]),
    'irf(..., boot=FALSE) supplies point estimates. Original-paper bootstrap is implemented separately.',
    'Production retains archived units. Figure 5 log-percent variant divides original scale by 4.'),
    'output/run_summary.txt')
}
