# Kilian (2009) R 教学复现：vars::SVAR 版

复现 Lutz Kilian (2009), *Not All Oil Price Shocks Are Alike: Disentangling Demand and Supply Shocks in the Crude Oil Market*, AER 99(3), 1053–1069 的核心 Figure 2–5。另输出模型输入序列和油价预测误差方差分解。

这里使用 CRAN 的 **vars** 包，主要函数为 `VAR()`、`SVAR()`、`irf()`、`fevd()`。SVAR 并非 R 基础安装自带的独立包。本项目不把自己编写的 VAR/SVAR 估计器作为正文估计方法。

## 一、按三个部分讲解

| 文件 | 用途 |
|---|---|
| `01_prepare_data.R` | 读取原始数据，确定日期、转换宏观增长率、检查数据，生成 Excel；不估计模型 |
| `data/kilian_analysis_data.xlsx` | 正文分析的唯一数据入口；保留数值精度，并提供变量说明和来源 |
| `02_analysis.R` | 只读取 Excel，估计 VAR/SVAR，计算冲击响应、历史分解和宏观响应，直接在绘图窗口作图 |

辅助文件：

- `00_install_packages.R`：将 vars、openxlsx 及依赖安装在项目的 `.r_library` 文件夹中。
- `03_validate_results.R`：独立核验 Excel、模型恒等式和原文点估计，不占用正文讲解篇幅。
- `R/functions_svar.R`：重抽样、季度冲击汇总、历史分解、结果导出等辅助函数。
- `R/plots.R`：绘图函数。
- `run_replication.R`：兼容旧入口，现在仅调用 `02_analysis.R`。

## 二、如何运行

在 RStudio 中打开 `kilian_2009_replication.Rproj`，保证工作目录是项目文件夹，依次运行：

```r
source("00_install_packages.R", encoding = "UTF-8") # 首次安装需要联网
source("01_prepare_data.R", encoding = "UTF-8")    # 原始数据 → Excel
source("02_analysis.R", encoding = "UTF-8")        # Excel → 正文分析和图表
source("03_validate_results.R", encoding = "UTF-8")# 独立核验
```

Excel 已生成；如果只讲解模型，可安装包后直接打开并分段执行 `02_analysis.R`。历史原始数据随项目提供，基准复现不需要重新下载。项目压缩包不包含已安装的 R 包。

第 10 节每行绘图调用均可单独运行，图形显示在 RStudio 的 **Plots** 窗口，用前后箭头切换，用 **Zoom** 放大。绘图代码不保存 PNG、SVG 或 PDF；建议先扩大 Plots 窗口，再运行九宫格等多面板图。例如，完成前面的估计后运行：

```r
plot_annual_shocks(aggregated)                # 原文图 2
plot_impulse_responses(irf_paper, bands$oil_se)# 原文图 3
plot_macro_responses(macro_irf, bands$macro_se)# 原文图 5
```

通过 Rscript 在没有绘图窗口的环境运行时，仅计算和保存数值结果，跳过显示，避免 R 自动生成 Rplots.pdf。需要查看图形时，请在 RStudio 中运行正文文件。

正文默认运行论文设定的 2,000 次月度 wild bootstrap 和 20,000 次宏观回归 block bootstrap。完整结果已生成，相同输入和版本会复用缓存。快速调试可使用：

```text
Rscript --vanilla 02_analysis.R --quick
```

快速模式使用 50/500 次重抽样，会覆盖数值结果；正式讲解前应重新运行默认模式。缓存包含数据文件、辅助代码、vars 版本和随机种子信息。

本次实际运行环境：R 4.5.2、vars 1.6-1、openxlsx 4.2.9。

## 三、Excel 中有什么

| 工作表 | 行数（不含表头） | 内容 |
|---|---:|---|
| monthly_svar | 419 | 1973-02 至 2007-12；date、dprod、rea、rpo |
| quarterly_macro | 132 | 1975Q1 至 2007Q4；GDP/CPI 水平、年率化 GDP 增长和 CPI 通胀 |
| gdp_raw | 133 | 原始实际 GDP，1974Q4 至 2007Q4 |
| cpi_raw | 397 | 原始月度 CPI，1974-12 至 2007-12 |
| dictionary | — | 字段定义、单位、日期处理和来源 |

`01_prepare_data.R` 明确执行以下处理：

1. 为作者月度模型输入添加连续日期，并与独立存档逐值核对。
2. 为 GDP 和 CPI 原始数据添加日期；CPI 使用每季末月数值。
3. 计算 `400 * diff(log(GDP))` 和 `400 * diff(log(CPI_quarter_end))`。
4. 按季度日期对齐，导出数值型 Excel，并回读检查精度。

结构冲击需要先估计模型才能得到，因此冲击的季度/年度汇总留在正文分析阶段。Excel 中不预先存入估计的冲击。

## 四、正文中的模型

变量顺序为全球石油产量增长、全球实际经济活动、实际油价。月度数据 419 期，使用 24 阶滞后和常数项，估计有效样本为 395 期（1975-02 至 2007-12）。

```r
var_fit <- VAR(y, p = 24, type = "const")
B_restrictions <- matrix(c(
  NA, 0,  0,
  NA, NA, 0,
  NA, NA, NA
), nrow = 3, byrow = TRUE)
svar_fit <- SVAR(
  var_fit, estmethod = "scoring", Bmat = B_restrictions,
  max.iter = 1000, conv.crit = 1e-10, lrtest = FALSE
)
irf_package <- irf(svar_fit, n.ahead = 15, boot = FALSE)
fevd_package <- fevd(svar_fit, n.ahead = 60)
```

B 的上三角为零，分别识别石油供给、总需求、石油特定需求三类结构冲击；正对角线确定符号。残差协方差使用与原作者程序一致的自由度调整，分母为 322。独立核验确认估计 B 与该协方差的 Cholesky 分解一致。

- **Figure 2**：提取结构冲击并按年平均。
- **Figure 3**：使用 `irf(svar_fit)`，只累积产量响应，使其对应产量水平；供给冲击反号以表示不利供给冲击。
- **Figure 4**：利用 `vars::Phi()` 的移动平均系数和估计 B，计算实际油价的历史分解；同时导出常数项、初值对应的基线，检查各部分精确加总。
- **Figure 5**：按照原文，以三类季度冲击及其 12 阶滞后分别解释 GDP 增长和 CPI 通胀，累积回归系数得到水平响应。此处原文使用单方程回归，因此使用 `lm()`。
- **补充图**：使用 `fevd(svar_fit)` 给出实际油价的预测误差方差分解。

## 五、误差带与复现边界

月度重抽样沿用原作者的递归设计：随机选初始历史、同月三个残差使用共同的高斯乘数，每次重新调用 `vars::VAR()`、`vars::SVAR()`、`vars::irf()`。没有直接以包默认的普通残差 bootstrap 替代论文的 wild bootstrap。

宏观回归使用长度为 4 的成对区块重抽样，沿用作者的区块起点范围。图中带宽为点估计加减 1 或 2 个 bootstrap 标准差。R 与 MATLAB 的随机数生成不同，误差带不能要求逐点完全一致；点估计另有严格数值对照。

需保留的原文口径：

- **数据版本**：基准用作者论文存档数据。今天作者网页/FRED 的修订版实际经济活动指数不是原文当时的数据版本。
- **产量单位**：直接使用原始复现文件中的 dprod 数值与比例，不擅自乘 100；这会影响产量响应的轴单位。
- **Figure 5 比例**：作者宏观增长率按年率化构造，累积系数保留其原始比例；另外提供除以 4 的 log-percent 比例图，便于解释实际累计水平变化。
- **1975 年第一季度**：由于有效月度冲击从 2 月开始，1 月按 2、3 月的均值补齐，再求季度均值，沿用作者处理。
- **供给冲击符号**：冲击序列保留识别时的符号；Figure 3/5 统一展示不利供给冲击。
- 本项目覆盖原文核心 Figure 2–5 及相关估计，不声称复现全文每一个表格和稳健性检验。

## 六、已经完成的验证

完整默认重抽样已运行，12 项独立核验全部通过。最大绝对误差：

| 对照 | 最大绝对误差 |
|---|---:|
| B 与 Cholesky 识别 | 5.41e-13 以下 |
| Figure 3 与存档 MATLAB 点估计 | 8.59e-12 以下 |
| Figure 4 与存档 MATLAB 点估计 | 1.43e-11 以下 |
| Figure 5 GDP / CPI 与存档点估计 | 8.51e-13 以下 |
| 历史分解加总与观测值 | 3.60e-12 以下 |

其他检查包括 Excel 回读、协方差重建、冲击正交性、方差分解加总。具体结果见 `output/validation_checks.csv`；误差带比较见 `output/bootstrap_se_comparison.csv`。正文保存的模型对象分别是 vars 包的 `varest` 和 `svarest`。

图形直接显示在绘图窗口，不自动保存。逐点数值结果位于 `output` 中的 CSV，模型和结果保存在 `output/replication_results_vars.rds`，环境与运行信息见 `output/sessionInfo.txt`、`output/run_summary.txt`。新版压缩包不包含之前导出的 PNG/SVG。

## 七、可选：换用修订版活动指数

`R/compare_revised_index.R` 单独读取 FRED 的 IGREA 快照，只替换经济活动指数，保持原油产量、油价和样本期不变。它也使用 vars 包，结果写入独立子目录，不覆盖基准图表。本次未运行此项；它是数据版本敏感性实验，不是把完整模型更新到当前年份。

## 数据和文献

- [原论文（AEA）](https://www.aeaweb.org/articles?id=10.1257/aer.99.3.1053)
- [Kilian 数据网页](https://sites.google.com/site/lkilian2019/research/data-sets)
- [作者复现材料的固定版本镜像](https://github.com/richryan/jcre-oil/tree/d4e339300f8ee48f2ccb42051cb3a48f1fb9cfb0/kilianAER2009replication)
- [Bruce Hansen 教材数据](https://www.ssc.wisc.edu/~bhansen/econometrics/Econometrics%20Data.html)
- [vars 官方手册](https://cran.r-project.org/web/packages/vars/vars.pdf)

原始文件、下载来源和原作者数值输出保存在 `references/` 与 `data/raw/`。外部材料版权归各自作者；本项目新增 R 代码的授权见 LICENSE。
