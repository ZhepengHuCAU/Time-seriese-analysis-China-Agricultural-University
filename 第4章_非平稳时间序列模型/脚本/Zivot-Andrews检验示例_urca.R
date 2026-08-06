# 第4章：Zivot-Andrews 检验示例
# 说明：本示例优先使用成熟 R package，不手写检验统计量。
# package: urca

library(urca)

# 使用 urca 包自带 Nelson-Plosser 宏观经济数据
data(nporg)

# 取实际 GNP，并保留年份以解释断点位置
d <- na.omit(nporg[, c("year", "gnp.r")])
gnp <- d$gnp.r

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
