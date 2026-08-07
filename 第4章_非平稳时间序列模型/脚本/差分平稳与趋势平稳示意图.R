# 第4章：差分平稳与趋势平稳示意图
# 说明：本脚本用于生成课堂讲义中的概念示意图。
# packages: ggplot2

library(ggplot2)

if (.Platform$OS.type == "windows") {
  grDevices::windowsFonts(CourseCN = grDevices::windowsFont("Noto Sans SC"))
  font_family <- "CourseCN"
} else {
  font_family <- "sans"
}

set.seed(20260807)

t <- 1:100
shock_time <- 60
trend <- 20 + 0.18 * t

# 趋势平稳过程：
# y_t = alpha + beta t + u_t
# 其中 u_t 是平稳 AR(1)，第 60 期冲击只会逐渐消失。
u <- numeric(length(t))
eps_ts <- rnorm(length(t), sd = 0.7)
eps_ts[shock_time] <- eps_ts[shock_time] + 7
for (i in 2:length(t)) {
  u[i] <- 0.65 * u[i - 1] + eps_ts[i]
}
y_ts <- trend + u
u_hat <- y_ts - trend

# 差分平稳过程：
# y_t = y_{t-1} + delta + epsilon_t
# 第 60 期冲击进入水平值，此后会永久留在路径中。
eps_ds <- rnorm(length(t), sd = 0.7)
eps_ds[shock_time] <- eps_ds[shock_time] + 7
y_ds <- numeric(length(t))
y_ds[1] <- 20 + eps_ds[1]
for (i in 2:length(t)) {
  y_ds[i] <- y_ds[i - 1] + 0.18 + eps_ds[i]
}
dy_ds <- c(NA, diff(y_ds))

plot_data <- rbind(
  data.frame(t = t, value = y_ts, reference = trend,
             type = "趋势平稳\ntrend stationary", view = "水平值：围绕确定性趋势波动"),
  data.frame(t = t, value = u_hat, reference = 0,
             type = "趋势平稳\ntrend stationary", view = "去趋势后：平稳偏离"),
  data.frame(t = t, value = y_ds, reference = NA,
             type = "差分平稳\ndifference stationary", view = "水平值：冲击永久改变路径"),
  data.frame(t = t, value = dy_ds, reference = 0,
             type = "差分平稳\ndifference stationary", view = "一阶差分后：平稳变化")
)

plot_data$type <- factor(
  plot_data$type,
  levels = c("趋势平稳\ntrend stationary", "差分平稳\ndifference stationary")
)
plot_data$view <- factor(
  plot_data$view,
  levels = c(
    "水平值：围绕确定性趋势波动",
    "去趋势后：平稳偏离",
    "水平值：冲击永久改变路径",
    "一阶差分后：平稳变化"
  )
)

fig <- ggplot(plot_data, aes(x = t, y = value)) +
  geom_hline(data = subset(plot_data, !is.na(reference) & reference == 0),
             aes(yintercept = reference), color = "#8a8f98", linewidth = 0.5) +
  geom_line(color = "#1f5f99", linewidth = 0.8, na.rm = TRUE) +
  geom_line(data = subset(plot_data, !is.na(reference) & reference != 0),
            aes(y = reference), color = "#b23a48", linetype = "dashed", linewidth = 0.75) +
  geom_vline(xintercept = shock_time, color = "#d08c2f", linetype = "dotted", linewidth = 0.8) +
  facet_wrap(type ~ view, scales = "free_y", ncol = 2) +
  labs(
    title = "差分平稳与趋势平稳的基本区别",
    subtitle = "虚线表示确定性趋势，点线表示同一期冲击；关键区别在于冲击是否永久改变序列水平",
    x = "时间 t",
    y = "示意值",
    caption = "说明：图中数据为课堂模拟示意，不代表真实经济数据。"
  ) +
  theme_minimal(base_size = 16, base_family = font_family) +
  theme(
    plot.title = element_text(face = "bold", color = "#1f2933", size = 22, margin = margin(b = 8)),
    plot.subtitle = element_text(color = "#4b5563", size = 14, margin = margin(b = 16)),
    strip.text = element_text(face = "bold", color = "#1f2933", size = 15, lineheight = 1.12),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13, color = "#3f4650"),
    plot.caption = element_text(size = 11, color = "#4b5563", hjust = 1),
    panel.grid.minor = element_blank(),
    plot.margin = margin(18, 22, 14, 22)
  )

ggsave(
  filename = "../图片/差分平稳与趋势平稳示意图.png",
  plot = fig,
  width = 12.5,
  height = 7.6,
  dpi = 240
)
