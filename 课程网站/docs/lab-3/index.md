# Lab 3

**石油价格冲击的来源：用 R 复现 Kilian（2009）**

同样是油价上涨，背后可能是石油供给收缩、全球总需求扩张，也可能是石油市场特定需求变化。本实验使用 `vars` 包的 `VAR()`、`SVAR()`、`irf()` 和 `fevd()`，复现 Kilian（2009）论文的核心图 2—5，学习如何识别不同来源的结构冲击，并解释冲击响应与历史贡献。

实验按“**整理数据 → Excel → 正文分析**”组织。数据处理与模型分析放在不同 R 文件中，绘图直接显示在 RStudio 的 **Plots** 窗口，不自动保存图片。

## 下载复现包

- [下载完整复现包：Kilian2009_Lab3.zip](Kilian2009_Lab3.zip){ download="Kilian2009_Lab3.zip" }
- [下载整理后的 Excel 数据](kilian_analysis_data.xlsx){ download="kilian_analysis_data.xlsx" }
- [查看或下载数据整理代码：01_prepare_data.R](01_prepare_data.R){ download="01_prepare_data.R" }
- [查看或下载正文分析代码：02_analysis.R](02_analysis.R){ download="02_analysis.R" }
- [在 GitHub 查看完整 Lab 3 源文件](https://github.com/ZhepengHuCAU/Time-seriese-analysis-China-Agricultural-University/tree/main/Lab%203)

**首次使用请下载并解压完整复现包，保留文件夹结构。** 单独下载的 R 文件用于阅读或替换；正文还需要包内 `R/` 目录中的辅助函数。Excel 已生成，只讲解模型时可以直接进入正文分析。

## 1. 如何运行

1. 解压后，在 RStudio 中打开 `kilian_2009_replication.Rproj`，使工作目录指向该项目。
2. 首次运行 `00_install_packages.R`，联网安装 `vars`、`openxlsx` 及其依赖。
3. 讲解数据处理时运行 `01_prepare_data.R`，生成 `data/kilian_analysis_data.xlsx`。
4. 打开 `02_analysis.R`，按章节选中代码，按 **Ctrl+Enter** 逐段运行。
5. 完成后运行 `03_validate_results.R`，检查数据、模型恒等式及与存档点估计的一致性。

也可以在 RStudio 控制台按顺序运行：

```r
source("00_install_packages.R", encoding = "UTF-8") # 首次安装
source("01_prepare_data.R", encoding = "UTF-8")    # 整理数据，可单独讲解
source("02_analysis.R", encoding = "UTF-8")        # 正文分析
source("03_validate_results.R", encoding = "UTF-8")# 独立核验
```

`SVAR()` 是 **vars 包中的函数**，需要安装该包。项目把所需包安装在自己的 `.r_library` 目录中，下载包不附带已安装的软件库。本次核验环境为 R 4.5.2、vars 1.6-1、openxlsx 4.2.9。

## 2. 数据与样本

基准实验使用原论文复现材料的历史数据版本，月度样本为 **1973-02 至 2007-12，共 419 期**。24 阶滞后后，有效估计期为 1975-02 至 2007-12，共 395 期。

| 月度变量 | 含义 | 使用方式 |
|---|---|---|
| `dprod` | 全球石油产量增长 | 保留作者归档尺度，不再差分；不能直接按通常百分比增长解释 |
| `rea` | 全球实际经济活动指数 | 保留指数点，可以为负，不取对数 |
| `rpo` | 实际油价的归一化对数尺度 | 已完成变换，不是美元/桶，不再取对数 |

季度宏观样本为 **1975Q1—2007Q4，共 132 期**，用于研究美国实际 GDP 与 CPI 对已识别冲击的响应。Excel 中的工作表如下：

| 工作表 | 内容 |
|---|---|
| `monthly_svar` | 正文月度 VAR/SVAR 输入 |
| `quarterly_macro` | GDP、季度末 CPI 及整理好的年率化增长率 |
| `gdp_raw`、`cpi_raw` | GDP 与 CPI 原始水平和日期 |
| `dictionary` | 字段含义、单位、处理方法与来源 |

`01_prepare_data.R` 为原始数据添加连续日期，选取每季末月 CPI，再计算 `400 * diff(log(GDP))` 与 `400 * diff(log(CPI))`。正文直接读取 Excel 中已经整理好的增长率。结构冲击只能在估计 SVAR 后得到，因此冲击的季度、年度汇总属于分析步骤。

作者目前发布的全球实际经济活动指数可能经过修订；直接替换它会改变输入数据。本实验首先复现历史版本，修订版比较保留为包内的可选扩展。

## 3. VAR 与递归结构识别

变量按“产量增长 → 全球实际经济活动 → 实际油价”排列。先估计带常数的 VAR(24)，再对当期影响矩阵施加递归限制：

```r
var_fit <- vars::VAR(y, p = 24, type = "const")
B_restrictions <- matrix(c(
  NA,  0,  0,
  NA, NA,  0,
  NA, NA, NA
), nrow = 3, byrow = TRUE)

svar_fit <- vars::SVAR(
  var_fit, estmethod = "scoring", Bmat = B_restrictions,
  max.iter = 1000, conv.crit = 1e-10, lrtest = FALSE
)
svar_fit$B
```

这里 `NA` 表示待估计的参数，`0` 表示当期零限制。将约简式残差写为：

$$
u_t=B\varepsilon_t,\qquad E(\varepsilon_t\varepsilon_t')=I.
$$

三列分别对应石油供给、全球总需求和石油特定需求冲击。第一行的两个零限制假设石油产量不在同一个月响应两类需求冲击；第二行的第三个零限制假设全球实际经济活动不在同一个月响应石油特定需求冲击；实际油价可以当期响应所有冲击。这些是识别所依赖的经济假设，不是数据自动证明的事实。

本实验的估计结果最大伴随矩阵特征根模约为 **0.988592**，小于 1。动态稳定并不等于识别假设已得到验证。

## 4. 从结构冲击到论文图 2—5

| 分析 | 代码中的主要对象 | 解释重点 |
|---|---|---|
| 图 2：结构冲击历史 | `structural_shocks`、`aggregated` | 由残差和估计 B 提取冲击，再按年平均 |
| 图 3：结构脉冲响应 | `irf_package`、`irf_paper` | 比较三种来源的冲击对产量、经济活动和油价的动态影响 |
| 图 4：实际油价历史分解 | `historical` | 区分三类历史冲击的贡献，并保留常数与初值形成的基线 |
| 图 5：GDP 与 CPI 响应 | `macro_fits`、`macro_irf` | 分别对一类季度冲击的当期及 12 阶滞后回归，再累积系数 |
| 补充：方差分解 | `fevd_package`、`fevd_table` | 衡量各类冲击对给定预测期油价预测误差方差的贡献 |

图 3 调用 `irf(svar_fit, n.ahead = 15, boot = FALSE)`。只累积产量增长响应，将其转为产量水平响应；经济活动和油价不能再次累积。图 3 和图 5 把供给冲击反号，展示不利供给冲击；图 2 保留供给扩张为正的原始符号。

历史分解满足“**三类冲击贡献 + 常数与初始条件项 = 实际观测值**”。三条冲击贡献线不能直接替代完整油价路径，也不能把历史贡献的符号与 FEVD 的非负份额混为一谈。

图 5 使用论文的第二阶段单方程回归，因此调用 `lm()`。GDP 和通胀输入均为年率化季度变化，包内同时提供原作者累计尺度与除以 4 的对数百分比尺度。比较经济幅度时，应先核对使用的是哪一种尺度。

有效月度冲击从 1975 年 2 月开始。为构造 1975Q1，沿用作者程序，以 2、3 月冲击均值补充 1 月，再计算季度平均。

## 5. 直接运行代码作图

完成前面的模型估计后，在 `02_analysis.R` 第 10 节逐行运行：

```r
plot_model_inputs(var_fit, monthly$date)
plot_annual_shocks(aggregated)
plot_impulse_responses(irf_paper, bands$oil_se)
plot_historical_decomposition(
  historical, monthly$date[(var_fit$p + 1L):nrow(monthly)]
)
plot_macro_responses(macro_irf, bands$macro_se)
plot_macro_responses(macro_irf, bands$macro_se, log_percent = TRUE)
plot_fevd(fevd_table)
```

图形显示在 **Plots** 窗口；用前后箭头切换，用 **Zoom** 放大。九宫格等多面板图建议先扩大绘图窗口，再运行相应语句。代码不自动生成 PNG、SVG 或 PDF 文件。在没有绘图窗口的命令行环境运行时，会跳过图形显示。

## 6. 重抽样与数值核验

月度误差带使用 **2,000 次 wild bootstrap**，每次重新调用 vars 包估计 VAR/SVAR；宏观方程使用 **20,000 次、长度为 4 的区块重抽样**。这些方法保留论文设定，没有直接以 `irf()` 默认的普通残差 bootstrap 替代。图中深、浅色带对应点估计加减 1、2 个 bootstrap 标准误，是逐点误差带，不是联合置信带。

完整默认重抽样已经运行，**12 项独立核验全部通过**。图 3—5 点估计与存档 MATLAB 输出的最大绝对误差低于 `1.5e-11`；误差带由于 R 与 MATLAB 随机数不同，不要求逐点完全一致。包内 `output/validation_checks.csv` 保存具体检查结果。

首次运行或数据、代码、包版本变化时会重新计算重抽样；有效缓存可被复用。数值表、模型对象和运行信息仍保存到 `output/`，绘图不保存为图片。本实验覆盖核心图 2—5，不代表已复现全文所有表格和稳健性检验。

## 7. 实验报告问题

1. B 矩阵中的三个零分别对应什么经济假设？如果变量排序改变，冲击解释为什么可能改变？
2. 为什么同样的油价上涨不能自动解释为石油供给收缩？用图 3 比较不同冲击来源。
3. 为什么只累积产量响应？对已经是对数水平的油价再次累积，会改变什么研究对象？
4. 图 2 与图 3 的供给冲击符号有什么区别？一个标准差的冲击与一个标准误的误差带有何区别？
5. 历史分解与预测误差方差分解分别回答什么问题？为什么历史分解需要基线和初始条件？
6. 图 5 为什么另做季度单方程回归？年率化输入如何影响累计响应的单位？
7. 若把活动指数换成今天的修订版本，结果变化能否直接解释为模型方法不同？

## 文献、数据与代码来源

- Kilian, L. (2009). *Not All Oil Price Shocks Are Alike: Disentangling Demand and Supply Shocks in the Crude Oil Market*. *American Economic Review*, 99(3), 1053–1069. [论文与 DOI](https://doi.org/10.1257/aer.99.3.1053)。
- [Kilian 数据网页](https://sites.google.com/site/lkilian2019/research/data-sets)。本实验基准使用原论文历史版本，作者复现材料见[固定版本镜像](https://github.com/richryan/jcre-oil/tree/d4e339300f8ee48f2ccb42051cb3a48f1fb9cfb0/kilianAER2009replication)。
- [Hansen 教材配套数据](https://users.ssc.wisc.edu/~bhansen/econometrics/Kilian2009.txt)，用于月度输入的逐值交叉核验。
- Pfaff, B. (2008). *VAR, SVAR and SVEC Models: Implementation Within R Package vars*. *Journal of Statistical Software*, 27(4). [DOI](https://doi.org/10.18637/jss.v027.i04)、[vars 官方手册](https://cran.r-project.org/web/packages/vars/vars.pdf)。

复现包保留原始材料的许可文本、来源记录和校验值。新增 R 代码与整理说明的许可见包内 `LICENSE.txt`；作者归档材料的许可见 `references/author_mirror/LICENSE.txt`。软件、数据和论文出版物分别按对应来源使用，详见[课程版权与引用](../版权与引用/index.md)。

相关课程内容：[多变量时间序列模型](../第5章_多变量时间序列模型/index.md)、[Lab 2：VAR、SVAR 与局部投影](../lab-2/index.md)。
