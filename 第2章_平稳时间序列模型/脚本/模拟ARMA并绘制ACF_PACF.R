# 第2章：AR、MA 与 ARMA 模型的模拟及 ACF/PACF 图
# 说明：
# 1. 本脚本只使用 R 自带的 stats 包；
# 2. 运行后会生成两张图片：
#    - 图2-1_不同ARMA模型的模拟序列.png
#    - 图2-2_不同ARMA模型的样本ACF与PACF.png

set.seed(20260723)

n <- 500
max_lag <- 16

models <- list(
  list(
    name = "AR(1): y[t] = 0.7 y[t-1] + e[t]",
    model = list(ar = 0.7)
  ),
  list(
    name = "AR(1): y[t] = -0.7 y[t-1] + e[t]",
    model = list(ar = -0.7)
  ),
  list(
    name = "MA(1): y[t] = e[t] - 0.7 e[t-1]",
    model = list(ma = -0.7)
  ),
  list(
    name = "AR(2): y[t] = 0.7 y[t-1] - 0.49 y[t-2] + e[t]",
    model = list(ar = c(0.7, -0.49))
  ),
  list(
    name = "ARMA(1,1): y[t] = -0.7 y[t-1] + e[t] - 0.7 e[t-1]",
    model = list(ar = -0.7, ma = -0.7)
  )
)

series_list <- lapply(models, function(m) {
  as.numeric(arima.sim(model = m$model, n = n))
})

output_dir_1 <- "../图片/图2-1_不同ARMA模型的模拟序列"
output_dir_2 <- "../图片/图2-2_ACF与PACF模式"
dir.create(output_dir_1, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir_2, recursive = TRUE, showWarnings = FALSE)

png(
  filename = file.path(output_dir_1, "图2-1_不同ARMA模型的模拟序列.png"),
  width = 1800,
  height = 1500,
  res = 180
)
par(mfrow = c(5, 1), mar = c(3, 4, 3, 1), oma = c(0, 0, 2, 0))
for (i in seq_along(models)) {
  plot(
    series_list[[i]],
    type = "l",
    col = "#1f4e79",
    lwd = 1.5,
    xlab = "Time",
    ylab = "Value",
    main = models[[i]]$name
  )
  abline(h = 0, col = "gray70", lty = 2)
}
mtext("Simulated AR, MA and ARMA Series", outer = TRUE, cex = 1.2, font = 2)
dev.off()

png(
  filename = file.path(output_dir_2, "图2-2_不同ARMA模型的样本ACF与PACF.png"),
  width = 1800,
  height = 2400,
  res = 180
)
par(mfrow = c(5, 2), mar = c(3, 4, 3, 1), oma = c(0, 0, 2, 0))
for (i in seq_along(models)) {
  acf(
    series_list[[i]],
    lag.max = max_lag,
    main = paste("ACF:", models[[i]]$name),
    ylim = c(-1, 1),
    col = "#333333",
    lwd = 2
  )
  pacf(
    series_list[[i]],
    lag.max = max_lag,
    main = paste("PACF:", models[[i]]$name),
    ylim = c(-1, 1),
    col = "#333333",
    lwd = 2
  )
}
mtext("Sample ACF and PACF Patterns", outer = TRUE, cex = 1.2, font = 2)
dev.off()

