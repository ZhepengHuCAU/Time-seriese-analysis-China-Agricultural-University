# 第4章：Zivot-Andrews 检验示例
# 说明：本示例优先使用成熟 R package，不手写检验统计量。
# packages: urca, ggplot2

library(urca)
library(ggplot2)

# 使用 urca 包自带 Nelson-Plosser 宏观经济数据
data(nporg)

# 取实际 GNP，并保留年份以解释断点位置
d <- na.omit(nporg[, c("year", "gnp.r")])
gnp <- d$gnp.r

# 先画出实际 GNP 序列，便于观察长期趋势和可能的结构变化。
# 这里用 1929 年作为图中的参考断点；下方 Zivot-Andrews 检验会给出同一断点位置。
fig <- ggplot(d, aes(x = year, y = gnp.r)) +
  geom_line(color = "#1f5f99", linewidth = 0.9) +
  geom_point(color = "#1f5f99", size = 1.8) +
  geom_vline(xintercept = 1929, linetype = "dashed", color = "#b23a48", linewidth = 0.8) +
  annotate("label", x = 1929, y = max(d$gnp.r, na.rm = TRUE), label = "Break: 1929",
           hjust = -0.05, vjust = 1, size = 4, color = "#7a1f2b", fill = "white", label.size = 0.2) +
  labs(
    title = "Real GNP in the Nelson-Plosser nporg Data",
    subtitle = "Dashed line marks the break year selected by the Zivot-Andrews example",
    x = "Year",
    y = "Real GNP",
    caption = "Data source: urca::nporg"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(face = "bold", color = "#1f2933"),
    plot.subtitle = element_text(color = "#4b5563"),
    panel.grid.minor = element_blank()
  )

ggsave(
  filename = "../图片/nporg_实际GNP序列.png",
  plot = fig,
  width = 9,
  height = 5.4,
  dpi = 220
)

# Zivot-Andrews 检验
# model = "both"：同时允许截距和趋势斜率发生一次结构突变
# lag = 2：检验回归中加入 2 阶滞后差分项
za_gnp <- ur.za(gnp, model = "both", lag = 2)

# 完整结果
summary(za_gnp)

# 提取主要结果
break_position <- za_gnp@bpoint
break_year <- d$year[break_position]

result <- list(
  test_statistic = za_gnp@teststat,
  critical_values = za_gnp@cval,
  break_position = break_position,
  break_year = break_year
)

print(result)

# 如需查看滚动 t 统计量图，可取消下一行注释
# plot(za_gnp)
