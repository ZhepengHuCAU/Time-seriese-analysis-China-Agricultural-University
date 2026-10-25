# 直接在当前绘图窗口显示，不创建 PNG、SVG 或其他图片文件。
shock_labels <- c('石油供给冲击', '全球总需求冲击', '石油特定需求冲击')
response_labels <- c('石油产量（原始数据尺度）', '全球实际经济活动（指数点）', '实际油价（100 × 对数）')
palette <- c('#265A85', '#B37B21', '#754B78')

draw_current <- function(draw) {
  # Rscript 没有绘图窗口时跳过显示，避免 R 自动生成 Rplots.pdf。
  if (dev.cur() == 1L && !interactive()) {
    message('请在 RStudio/R 控制台运行绘图语句以显示图形；未保存图片。')
    return(invisible(NULL))
  }
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par), add = TRUE)
  if (.Platform$OS.type == 'windows' && names(dev.cur()) %in% c('RStudioGD', 'windows')) {
    par(family = 'Microsoft YaHei')
  }
  draw()
  invisible(NULL)
}

panel <- function(x, estimate, se = NULL, title = '', ylab = '', xlab = '', col = palette[1], ylim = NULL) {
  par(mgp = c(2, .65, 0))
  if (is.null(ylim)) ylim <- range(c(0, estimate, if (!is.null(se)) c(estimate - 2 * se, estimate + 2 * se)), finite = TRUE)
  is_date <- inherits(x, 'Date')
  is_year <- !is_date && min(x) > 1900
  plot(x, estimate, type = 'n', ylim = ylim, xlab = xlab, ylab = '', main = title, xaxt = if (is_date || is_year) 'n' else 's',
       las = 1, bty = 'l', cex.main = 0.98, col.axis = '#444444', col.lab = '#333333')
  if (nzchar(ylab)) mtext(ylab, side = 2, line = 3.2, cex = par('cex'))
  if (is_date) {
    mid <- as.Date(paste0(seq(1970, 2030, 10), '-01-01'))
    mid <- mid[mid > min(x) + 730 & mid < max(x) - 730]
    axis.Date(1, at = c(min(x), mid, max(x)), labels = c(format(min(x), '%Y-%m'), format(mid, '%Y'), format(max(x), '%Y-%m')))
  }
  if (is_year) axis(1, at = c(min(x), 1980, 1990, 2000, max(x)))
  grid(col = '#E7E9EC')
  if (!is.null(se)) {
    polygon(c(x, rev(x)), c(estimate - 2 * se, rev(estimate + 2 * se)),
            col = adjustcolor(col, 0.12), border = NA)
    polygon(c(x, rev(x)), c(estimate - se, rev(estimate + se)),
            col = adjustcolor(col, 0.23), border = NA)
  }
  abline(h = 0, col = '#777777', lty = 3)
  lines(x, estimate, col = col, lwd = 2)
}

plot_model_inputs <- function(model, dates) {
  draw_current(function() {
    par(mfrow = c(3, 1), mar = c(2.6, 5.5, 2.3, 1.2), oma = c(2, 0, 3.2, 0))
    input_labels <- c('石油产量增长（原始数据尺度）', response_labels[2:3])
    for (i in 1:3) panel(dates, model$y[, i], title = input_labels[i], ylab = '', col = palette[i])
    mtext('Kilian (2009)｜原始样本的三个模型变量', outer = TRUE, side = 3, line = 1, font = 2, cex = 1.25)
    mtext('1973-02 至 2007-12；数据已变换，直接进入 VAR；产量保留作者归档尺度。', outer = TRUE, side = 1, line = 0.5, cex = .8)
  })
}

plot_annual_shocks <- function(q) {
  draw_current(function() {
    par(mfrow = c(3, 1), mar = c(2.8, 4.7, 2.3, 1), oma = c(2.3, 0, 3, 0))
    for (j in 1:3) panel(1975:2007, q$annual[, j], title = shock_labels[j],
                         ylab = '标准化冲击的年均值', col = palette[j], ylim = c(-1, 1))
    mtext('图 2 复现｜结构冲击的历史变化', outer = TRUE, side = 3, line = 1, font = 2, cex = 1.25)
    mtext('与作者图 2 一致：供给冲击正值代表供给扩张；1975 年 1 月按作者方法补值。', outer = TRUE, side = 1, line = 0.7, cex = .8)
  })
}

plot_impulse_responses <- function(irf, irf_se) {
  draw_current(function() {
    par(mfrow = c(3, 3), mar = c(3.3, 4.5, 2.7, 1.2), oma = c(3, 0, 4.3, 0))
    yl <- lapply(1:3, function(i) range(c(0, irf[i, , ] - 2 * irf_se[i, , ], irf[i, , ] + 2 * irf_se[i, , ])))
    for (j in 1:3) for (i in 1:3) panel(0:15, irf[i, j, ], irf_se[i, j, ],
       title = paste0(shock_labels[j], '\n', response_labels[i]), ylab = '', xlab = if (j == 3) '冲击后月数' else '', col = palette[j], ylim = yl[[i]])
    mtext('图 3 复现｜不同来源的冲击，产生不同的油价响应', outer = TRUE, side = 3, line = 2, font = 2, cex = 1.3)
    mtext('一标准差冲击；供给冲击取负向；产量响应累计；VAR(24) 含常数。', outer = TRUE, side = 3, line = .4, cex = .86)
    mtext('深／浅色带：点估计 ±1／±2 个 bootstrap 标准误；不是联合置信带。原始数据尺度。', outer = TRUE, side = 1, line = 1, cex = .83)
  })
}

plot_historical_decomposition <- function(hd, shock_dates) {
  draw_current(function() {
    par(mfrow = c(3, 1), mar = c(2.7, 5.3, 2.5, 1), oma = c(2.6, 0, 3.4, 0))
    lim <- range(c(-100, 100, hd$contributions[, 3, ]))
    for (j in 1:3) panel(shock_dates, hd$contributions[, 3, j], title = paste0(shock_labels[j], '对实际油价的历史贡献'),
                        ylab = '100 × 对数点', col = palette[j], ylim = lim)
    mtext('图 4 复现｜实际油价的历史分解', outer = TRUE, side = 3, line = 1.3, font = 2, cex = 1.3)
    mtext('展示全部有效期 1975-02 至 2007-12；三类冲击贡献 + 常数及初始条件项 = 观测油价。', outer = TRUE, side = 1, line = .9, cex = .8)
  })
}

plot_macro_responses <- function(macro, macro_se, log_percent = FALSE) {
    level <- log_percent
    factor <- if (level) 4 else 1
    draw_current(function() {
      par(mfrow = c(3, 2), mar = c(3.2, 4.4, 2.6, 1), oma = c(3.2, 0, 4, 0))
      for (j in 1:3) for (i in 1:2) panel(0:12, macro[, i, j] / factor, macro_se[, i, j] / factor,
        title = paste0(shock_labels[j], ' → ', c('美国实际 GDP', '美国 CPI')[i]),
        ylab = if (level) '100 × 对数点' else '原始代码尺度', xlab = if (j == 3) '冲击后季度数' else '', col = palette[j],
        ylim = range(c(0, macro[, i, ] - 2 * macro_se[, i, ], macro[, i, ] + 2 * macro_se[, i, ])) / factor)
      mtext(if (level) '图 5｜换算为对数百分比后的宏观响应' else '图 5 复现｜美国 GDP 与 CPI 对三类冲击的响应', outer = TRUE, side = 3, line = 1.7, font = 2, cex = 1.2)
      mtext('每类冲击分别回归：常数 + 当季冲击 + 12 季滞后；供给冲击取负向。', outer = TRUE, side = 3, line = .2, cex = .85)
      mtext(if (level) '本图将作者累计年化增长率系数及标准误除以 4；深／浅色为 ±1／±2 标准误。' else
              '原样保留作者年化增长率系数的累计尺度；未除以 4。深／浅色为 ±1／±2 标准误。', outer = TRUE, side = 1, line = 1, cex = .8)
    })
}

plot_fevd <- function(fevd_table) {
  draw_current(function() {
    d <- fevd_table[fevd_table$response == 3, ]
    mat <- matrix(d$share_pct, nrow = 3)
    par(mar = c(5, 5, 5, 2), oma = c(1, 0, 1, 0), las = 1)
    barplot(mat, names.arg = unique(d$horizon_months), col = palette, border = NA,
            ylim = c(0, 112), xlab = '预测期（月）', ylab = '预测误差方差占比（%）',
            main = '补充分析｜实际油价的预测误差方差分解')
    legend('top', legend = shock_labels, fill = palette, bty = 'n', horiz = TRUE, cex = .9)
    mtext('这是本复现包增加的诊断，不对应论文的一张原图。', side = 1, line = 4, cex = .8)
  })
}
