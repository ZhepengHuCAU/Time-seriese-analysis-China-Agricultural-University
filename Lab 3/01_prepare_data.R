# 第一步：整理原始数据，生成供正文分析直接读取的 Excel。
# 在本项目根目录运行；本文件不估计 VAR/SVAR，也不计算结构冲击。
# 首次使用先运行：source('00_install_packages.R')
if (dir.exists('.r_library')) .libPaths(c(normalizePath('.r_library'), .libPaths()))
library(openxlsx)
options(stringsAsFactors = FALSE)

# 1. 原油市场月度数据：作者已经完成变量变换，直接保留数值。
oil <- read.table('references/author_mirror/data.txt')
names(oil) <- c('dprod', 'rea', 'rpo')
monthly <- data.frame(date = seq(as.Date('1973-02-01'), as.Date('2007-12-01'), by = 'month'), oil)

# 使用另一个独立下载来源核对数据，避免列错位或下载错误。
hansen <- read.table('data/raw/Kilian2009.txt')
stopifnot(nrow(monthly) == 419L, all(is.finite(as.matrix(oil))),
          !anyDuplicated(monthly$date), max(abs(as.matrix(oil) - as.matrix(hansen))) == 0)

# 2. 真实 GDP：原始季度水平，1974Q4—2007Q4。
gdp_raw <- read.table('references/author_mirror/beagdp.txt', col.names = c('year', 'quarter', 'real_gdp'))
gdp_raw$date <- as.Date(sprintf('%04d-%02d-01', gdp_raw$year, 3L * gdp_raw$quarter - 2L))
gdp_raw <- gdp_raw[, c('date', 'year', 'quarter', 'real_gdp')]
stopifnot(identical(gdp_raw$date, seq(as.Date('1974-10-01'), as.Date('2007-10-01'), by = '3 months')),
          all(gdp_raw$real_gdp > 0))
gdp_growth <- 400 * diff(log(gdp_raw$real_gdp))

# 3. CPI：原始月度水平，1974-12—2007-12。
cpi_raw <- read.table('references/author_mirror/cpi.txt', col.names = c('year', 'month', 'cpi'))
cpi_raw$date <- as.Date(sprintf('%04d-%02d-01', cpi_raw$year, cpi_raw$month))
cpi_raw <- cpi_raw[, c('date', 'year', 'month', 'cpi')]
stopifnot(identical(cpi_raw$date, seq(as.Date('1974-12-01'), as.Date('2007-12-01'), by = 'month')),
          all(cpi_raw$cpi > 0))

# 原文使用季度末月 CPI（不是季度平均 CPI），再算年化季度通胀。
cpi_quarter_end <- cpi_raw$cpi[cpi_raw$month %in% c(3, 6, 9, 12)]
cpi_inflation <- 400 * diff(log(cpi_quarter_end))
quarterly <- data.frame(
  date = gdp_raw$date[-1],
  quarter = paste0(gdp_raw$year[-1], 'Q', gdp_raw$quarter[-1]),
  real_gdp = gdp_raw$real_gdp[-1],
  cpi_quarter_end = cpi_quarter_end[-1],
  gdp_growth_ann = gdp_growth,
  cpi_inflation_ann = cpi_inflation
)
stopifnot(nrow(quarterly) == 132L, all(is.finite(as.matrix(quarterly[, 3:6]))),
          !anyDuplicated(quarterly$date))

# 4. 变量定义与整理口径。数据列使用简短英文名，方便讲解 R 调用。
dictionary <- data.frame(
  field = c('monthly_svar', 'date', 'dprod', 'rea', 'rpo', 'quarterly_macro', 'quarter',
            'real_gdp', 'cpi_quarter_end', 'gdp_growth_ann', 'cpi_inflation_ann',
            'gdp_raw', 'cpi_raw', '未纳入的数据', '样本版本', '源数据', '交叉核对', '处理程序', '使用顺序'),
  meaning = c('正文月度模型输入', '月初或季度起始日', '全球原油产量增长', '全球实际经济活动', '实际原油价格',
              '正文季度宏观输入', '季度标签', '美国实际 GDP 水平', '季度末月 CPI 水平',
              '实际 GDP 年化季度增长率', '年化季度通胀率', 'GDP 原始数据', 'CPI 原始数据',
              '结构冲击与响应', '原论文归档版本', '作者文件的公开镜像', 'Hansen 教学数据', '数据整理文件', '课堂讲解流程'),
  unit = c('419 个月；3 个变量', 'Excel 日期值', '原始归档尺度', '偏离趋势的指数点', '归一化的 100 × 对数尺度',
           '132 个季度；1975Q1—2007Q4', 'YYYYQn', '十亿美元；2000 年链式价格', '作者归档指数',
           '年化对数百分点', '年化对数百分点', '1974Q4—2007Q4；133 行', '1974-12—2007-12；397 行',
           '属于估计结果', '基准样本截止 2007-12', '参见下方来源地址', '月度数据数值完全一致', '01_prepare_data.R', '整理 → Excel → 分析'),
  processing = c('作者 data.txt 已变换；不再差分或取对数。', '日期连续，未做补行或插值。',
    '保留作者归档数值；不能把该列直接解释为通常百分比增长。', '保留原始指数；允许为负；不取对数。',
    '保留归档对数价格；不是美元/桶；不再取对数。', '增长率已经整理好，02_analysis.R 直接读取。',
    '仅用于标识季度，不进入回归。', '来自 beagdp.txt；保留修订前的原始历史版本。',
    '选 3、6、9、12 月；1974 年 12 月作为第一期基数。',
    '400 * diff(log(real_gdp))；第一期为 1975Q1。',
    '400 * diff(log(CPI季度末水平))；第一期为 1975Q1。',
    '未修改输入水平；新增可排序的季度起始日。', '未修改输入水平；新增可排序的月初日期。',
    '结构冲击需在估计 SVAR 后获得，所以由正文分析文件计算。',
    '新版 IGREA 的修订不纳入本基准，保持与论文数值可比较。',
    '公开复现库 commit d4e339300f8ee48f2ccb42051cb3a48f1fb9cfb0。',
    'data/raw/Kilian2009.txt 与作者 data.txt 逐值核对。',
    '所有导入、日期整理和增长率变换均在此文件完成。',
    '先运行 01_prepare_data.R；讲解正文时只运行 02_analysis.R。')
)
sources <- data.frame(
  source = c('论文与复现包', '月度原始数据', '季度 GDP', '月度 CPI', 'Hansen 对照数据'),
  url = c('https://doi.org/10.1257/aer.99.3.1053',
    paste0('https://github.com/richryan/jcre-oil/blob/d4e339300f8ee48f2ccb42051cb3a48f1fb9cfb0/kilianAER2009replication/', c('data.txt', 'beagdp.txt', 'cpi.txt')),
    'https://users.ssc.wisc.edu/~bhansen/econometrics/Kilian2009.txt')
)

# 5. 写 Excel。表头在第 1 行；数字保留完整精度，仅显示格式取 6 位小数。
wb <- createWorkbook(creator = 'Kilian 2009 R replication')
modifyBaseFont(wb, fontName = 'Microsoft YaHei', fontSize = 11)
tables <- list(monthly_svar = monthly, quarterly_macro = quarterly,
               gdp_raw = gdp_raw, cpi_raw = cpi_raw, dictionary = dictionary)
header <- createStyle(fontColour = '#FFFFFF', fgFill = '#254E70', textDecoration = 'bold',
                      halign = 'center', valign = 'center')
num_style <- createStyle(numFmt = '0.000000', halign = 'right')
date_style <- createStyle(numFmt = 'yyyy-mm-dd', halign = 'center')
for (sheet in names(tables)) {
  dat <- tables[[sheet]]
  addWorksheet(wb, sheet, gridLines = FALSE, tabColour = if (sheet %in% c('monthly_svar', 'quarterly_macro')) '#254E70' else '#A5B3BD')
  writeDataTable(wb, sheet, dat, tableName = paste0('tbl_', sheet), tableStyle = 'TableStyleMedium2',
                 headerStyle = header, withFilter = TRUE)
  freezePane(wb, sheet, firstRow = TRUE, firstCol = TRUE)
  setRowHeights(wb, sheet, 1, 30)
  setRowHeights(wb, sheet, 2:(nrow(dat) + 1L), 23)
  setColWidths(wb, sheet, cols = seq_len(ncol(dat)), widths = 22)
  if (sheet != 'dictionary') {
    addStyle(wb, sheet, date_style, rows = 2:(nrow(dat) + 1L), cols = 1, gridExpand = TRUE, stack = TRUE)
    numeric_cols <- which(vapply(dat, is.numeric, logical(1)))
    if (length(numeric_cols)) addStyle(wb, sheet, num_style, rows = 2:(nrow(dat) + 1L), cols = numeric_cols, gridExpand = TRUE, stack = TRUE)
    if (sheet %in% c('gdp_raw', 'cpi_raw')) addStyle(wb, sheet, createStyle(numFmt = '0'), rows = 2:(nrow(dat) + 1L), cols = 2:3, gridExpand = TRUE, stack = TRUE)
  }
}
setColWidths(wb, 'quarterly_macro', 2, 14)
setColWidths(wb, 'dictionary', 1:4, c(24, 28, 33, 80))
addStyle(wb, 'dictionary', createStyle(wrapText = TRUE, valign = 'center'), rows = 2:20, cols = 1:4, gridExpand = TRUE, stack = TRUE)
setRowHeights(wb, 'dictionary', 2:20, 42)
writeData(wb, 'dictionary', sources, startRow = 23, headerStyle = header)
addStyle(wb, 'dictionary', createStyle(wrapText = TRUE, valign = 'center'), rows = 24:28, cols = 2:4, gridExpand = TRUE, stack = TRUE)
for (r in 24:28) mergeCells(wb, 'dictionary', cols = 2:4, rows = r)
setRowHeights(wb, 'dictionary', 24:28, 44)
dir.create('data', showWarnings = FALSE)
saveWorkbook(wb, 'data/kilian_analysis_data.xlsx', overwrite = TRUE)

# 6. 立即回读 Excel，确保日期、精度与数值未发生变化。
monthly_check <- read.xlsx('data/kilian_analysis_data.xlsx', sheet = 'monthly_svar', detectDates = TRUE)
quarterly_check <- read.xlsx('data/kilian_analysis_data.xlsx', sheet = 'quarterly_macro', detectDates = TRUE)
stopifnot(identical(monthly_check$date, monthly$date), identical(quarterly_check$date, quarterly$date),
          max(abs(as.matrix(monthly_check[, 2:4]) - as.matrix(monthly[, 2:4]))) < 1e-12,
          max(abs(as.matrix(quarterly_check[, 3:6]) - as.matrix(quarterly[, 3:6]))) < 1e-10)
cat('数据整理完成：data/kilian_analysis_data.xlsx\n月度 419 行，季度 132 行。现在可运行 02_analysis.R。\n')
