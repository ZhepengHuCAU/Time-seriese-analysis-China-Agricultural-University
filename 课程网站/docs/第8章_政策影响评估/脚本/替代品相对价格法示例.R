# 第8章：替代品相对价格法（RPS）模拟示例
# 默认数据为模拟价格；不复现论文，不生成真实政策结论。
# 方法出处：Carter & Smith (2007), doi:10.1162/rest.89.3.522；
# Adjemian, Smith & He (2021), doi:10.1016/j.foodpol.2021.102152。
# 本脚本由课程按所列过程生成模拟数据，非原论文真实数据或完整复现代码。
# R 接口依据 urca/vars/strucchange/sandwich/lmtest 官方文档，原包许可分别保留。
# 软件引用：Pfaff (2008), doi:10.18637/jss.v027.i04；Zeileis et al. (2002), doi:10.18637/jss.v007.i02。
# 完整来源与许可：https://zhepenghucau.github.io/Time-seriese-analysis-China-Agricultural-University/版权与引用/
# 检验、估计和预测使用现成 R 包；本脚本只组织数据与包调用。

if (.Platform$OS.type == "windows") {
  # R 4.2 的 UTF-8 locale 支持中文文件夹及 Windows 命令行路径。
  invisible(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
}

required <- c("urca", "vars", "strucchange", "sandwich", "lmtest")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("请先安装缺失的包：install.packages(c(",
       paste(sprintf('"%s"', missing), collapse = ", "), "))")
}
invisible(lapply(required, function(pkg) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}))

# 真实数据：将 NULL 改成 CSV 路径，并填写首次受事件影响的日期。
# CSV 必须有 date、price_target、price_substitute 三列。
data_file <- NULL
event_date <- as.Date("2018-09-02")

args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
if (length(script_arg)) {
  script_dir <- dirname(normalizePath(sub("^--file=", "", script_arg[1])))
  chapter_dir <- dirname(script_dir)
} else {
  chapter_dir <- if (basename(getwd()) == "脚本") dirname(getwd()) else getwd()
}
out_dir <- file.path(chapter_dir, "导出文件")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (is.null(data_file)) {
  set.seed(20261007)
  n_pre <- 400L
  n_post <- 80L
  n <- n_pre + n_post
  dates <- seq(as.Date("2011-01-02"), by = "week", length.out = n)
  event_date <- dates[n_pre + 1L]
  common_trend <- log(100) + cumsum(rnorm(n, sd = 0.006))
  spread <- 0.05 + as.numeric(stats::arima.sim(
    model = list(ar = 0.65), n = n, sd = 0.012
  ))
  untreated_target <- common_trend + spread / 2
  untreated_substitute <- common_trend - spread / 2
  target_effect <- ifelse(seq_len(n) > n_pre, -0.08, 0)
  substitute_effect <- ifelse(seq_len(n) > n_pre, 0.03, 0)
  dat <- data.frame(
    date = dates,
    price_target = exp(untreated_target + target_effect),
    price_substitute = exp(untreated_substitute + substitute_effect)
  )
  label <- "SIMULATED DATA"
  cat("模拟示例：预设对数效应 target=-0.08, substitute=0.03, relative=-0.11\n")
  cat("以下反事实估计还包含随机预测误差，不必等于已知模拟效应。\n")
} else {
  dat <- read.csv(data_file, stringsAsFactors = FALSE)
  needed <- c("date", "price_target", "price_substitute")
  if (!all(needed %in% names(dat))) stop("CSV 缺少必要列。")
  dat$date <- as.Date(dat$date)
  label <- "USER-SUPPLIED PRICE DATA"
}

if (anyNA(dat[, c("date", "price_target", "price_substitute")])) {
  stop("日期或价格含缺失值；请先整理共同观测时点。")
}
if (!is.numeric(dat$price_target) || !is.numeric(dat$price_substitute) ||
    any(!is.finite(dat$price_target)) || any(!is.finite(dat$price_substitute)) ||
    any(dat$price_target <= 0) || any(dat$price_substitute <= 0)) {
  stop("价格必须为有限正数。")
}
dat <- dat[order(dat$date), ]
if (anyDuplicated(dat$date)) stop("日期不能重复。")
if (is.na(event_date)) stop("event_date 必须是有效日期。")
dat$r <- log(dat$price_target) - log(dat$price_substitute)
dat$post <- as.integer(dat$date >= event_date)
pre <- dat[dat$post == 0, ]
post_dat <- dat[dat$post == 1, ]
if (nrow(pre) < 80 || nrow(post_dat) < 10) {
  stop("示例要求至少 80 个事件前观测和 10 个事件后观测。")
}
cat("事件起点：", as.character(event_date), "\n")
cat("样本量：pre=", nrow(pre), ", post=", nrow(post_dat), "\n", sep = "")

# 1. 政策前单位根检验；此处对预先给定的价格差直接检验。
cat("\n政策前 ADF：目标商品\n")
print(summary(urca::ur.df(log(pre$price_target), type = "drift",
                         lags = 8, selectlags = "BIC")))
cat("\n政策前 ADF：替代品\n")
print(summary(urca::ur.df(log(pre$price_substitute), type = "drift",
                         lags = 8, selectlags = "BIC")))
cat("\n政策前 ADF：对数相对价格\n")
print(summary(urca::ur.df(pre$r, type = "drift", lags = 8, selectlags = "BIC")))

# 2. Johansen 检验与特定协整向量检验。
y_pre <- cbind(target = log(pre$price_target),
               substitute = log(pre$price_substitute))
lag_choice <- vars::VARselect(y_pre, lag.max = 8, type = "const")
K <- max(2L, as.integer(lag_choice$selection["SC(n)"]))
cat("\n水平 VAR 阶数 K=", K, "；差分滞后阶数 K-1。\n", sep = "")
jo <- urca::ca.jo(y_pre, type = "trace", ecdet = "const", K = K)
print(summary(jo))
H_ratio <- cbind(c(1, -1, 0), c(0, 0, 1))
cat("\n在 rank=1 前提下检验 (1,-1) 价格斜率限制：\n")
print(summary(urca::blrtest(jo, H = H_ratio, r = 1)))

# 3. 已知日期的均值变化与 HAC 标准误。
mean_shift <- stats::lm(r ~ post, data = dat)
cat("\n事前指定事件日期的相对均值变化（HAC）：\n")
print(lmtest::coeftest(mean_shift, vcov. = sandwich::NeweyWest(
  mean_shift, prewhite = FALSE, adjust = TRUE
)))

# 4. 未知单断点的稳健 supF；分段最小二乘另用于断点估计。
fs <- strucchange::Fstats(
  r ~ 1, data = dat, from = 0.15,
  vcov. = function(m) sandwich::NeweyWest(m, prewhite = FALSE, adjust = TRUE)
)
cat("\n未知单断点 supF：\n")
print(strucchange::sctest(fs, type = "supF"))
bp_full <- strucchange::breakpoints(r ~ 1, data = dat, h = 0.15)
bp <- strucchange::breakpoints(bp_full)
cat("\n分段均值模型、BIC 选择（并非原文稳健序贯检验的复现）：\n")
print(summary(bp_full))
break_indices <- bp$breakpoints[!is.na(bp$breakpoints)]
if (length(break_indices)) print(dat$date[break_indices])
cat("断点日期指前一制度的最后一个观测；新区间从下一观测开始。\n")

# 5. 包估计的 VECM 反事实。
# 模拟已知秩为 1；真实数据必须先决定秩与确定性项。
# vec2var 保留 jo 估计的向量，不自动施加 blrtest 中检验的限制。
vec <- vars::vec2var(jo, r = 1)
cat("\n政策前系统残差的 Portmanteau 诊断：\n")
print(vars::serial.test(vec, lags.pt = 16, type = "PT.adjusted"))
H <- nrow(post_dat)
fc <- predict(vec, n.ahead = H, ci = 0.95)
cf_log <- cbind(target = fc$fcst$target[, "fcst"],
                substitute = fc$fcst$substitute[, "fcst"])
actual_log <- cbind(target = log(post_dat$price_target),
                    substitute = log(post_dat$price_substitute))
errors <- actual_log - cf_log
PI <- colMeans(errors)
impact <- data.frame(
  series = c("target", "substitute", "relative"),
  mean_log_impact = c(PI, PI["target"] - PI["substitute"])
)
impact$percent_geometric <- 100 * expm1(impact$mean_log_impact)
cat("\n平均影响：几何平均价格比的百分比变化\n")
print(impact, row.names = FALSE)
cat("这些点估计不附正式政策效应置信区间；逐期预测区间不能替代它。\n")

# 6. 固定估计模型，只扩大事件后影响窗口。
windows <- unique(pmin(c(10L, 20L, 40L, H), H))
window_results <- do.call(rbind, lapply(windows, function(h) {
  pi_h <- colMeans(errors[seq_len(h), , drop = FALSE])
  data.frame(horizon = h, target = unname(pi_h["target"]),
             substitute = unname(pi_h["substitute"]),
             relative = unname(pi_h["target"] - pi_h["substitute"]))
}))
cat("\n扩展影响窗口（对数效应；没有用事件后数据重估模型）：\n")
print(window_results, row.names = FALSE)

write.csv(dat, file.path(out_dir, "教学价格数据.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
write.csv(impact, file.path(out_dir, "平均影响结果.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
write.csv(window_results, file.path(out_dir, "扩展影响窗口结果.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
forecast_table <- data.frame(date = post_dat$date,
  actual_log_target = actual_log[, "target"],
  actual_log_substitute = actual_log[, "substitute"],
  counterfactual_log_target = cf_log[, "target"],
  counterfactual_log_substitute = cf_log[, "substitute"],
  error_target = errors[, "target"], error_substitute = errors[, "substitute"])
write.csv(forecast_table, file.path(out_dir, "反事实预测与逐期误差.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# 输出基础 R 图；英文标签便于跨平台运行。
fig_dir <- file.path(chapter_dir, "图片", "图8-1_RPS教学模拟")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
png(file.path(fig_dir, "图8-1_RPS教学模拟.png"), width = 1600, height = 1440,
    res = 160)
par(mfrow = c(3, 1), mar = c(4.5, 4.8, 2.8, 1), lwd = 1.3)
plot(dat$date, log(dat$price_target), type = "l", col = "#2055A5",
     ylim = range(log(dat$price_target), log(dat$price_substitute)),
     xlab = "", ylab = "Log price", main = label)
lines(dat$date, log(dat$price_substitute), col = "#C65A28", lty = 3)
abline(v = as.numeric(event_date), lty = 2)
legend("topleft", c("Target", "Substitute", "Event"),
       col = c("#2055A5", "#C65A28", "black"), lty = c(1, 3, 2), bty = "n")
plot(dat$date, dat$r, type = "l", col = "#2055A5",
     xlab = "", ylab = "Log relative price", main = "Relative price and event")
abline(v = as.numeric(event_date), lty = 2)
if (length(break_indices)) abline(v = as.numeric(dat$date[break_indices]),
                                col = "#C65A28", lty = 3)
legend("bottomleft", c("Event", "Estimated break"), lty = c(2, 3),
       col = c("black", "#C65A28"), bty = "n")
matplot(seq_len(H), errors, type = "l", lty = c(1, 3),
        col = c("#2055A5", "#C65A28"), xlab = "Post-event horizon",
        ylab = "Actual minus counterfactual", main = "Forecast deviations (not pure causal effects)")
abline(h = 0, lty = 2)
legend("topleft", c("Target", "Substitute"),
       col = c("#2055A5", "#C65A28"), lty = c(1, 3), bty = "n")
dev.off()
capture.output(sessionInfo(), file = file.path(out_dir, "运行环境.txt"))
cat("\n导出文件：", normalizePath(out_dir), "\n")
