# 版权与引用

本网站由胡哲鹏整理，用于中国农业大学经济时间序列课程。讲义、文献、软件例程、数据和图像的来源分别标注；本页用于保留第三方署名与适用许可，不为整站授予一个新的统一开放许可证。

## 讲义、论文与教材

正文为课程整理、演算和说明。方法名称及主要论证依据见各章参考文献；参考教材或论文，不表示本站取得其完整文本、原图、扫描页或授权译本的再发布权。引用译著时同时注明原著作者与译者，不能把译者列作原著作者。

本站对论文采用方法概述、必要的结果说明和来源链接；作者公开稿仍通过原机构链接访问。课程模拟的数值和图表另行标明，不作为原论文真实结果或完整复现程序。

引用本站可以注明：**胡哲鹏（编），《经济时间序列》课程讲义，具体章节标题、页面网址及访问日期**。继续使用其中注明改编的代码或第三方资料时，应同时保留原来源与适用许可。

公开教学网页应按公开传播的情形核对资料的使用范围，不能仅凭“教学用途”或“已注明出处”就视为可完整转载。相关规则参见[《中华人民共和国著作权法》第十三、二十四条等](https://www.ncac.gov.cn/xxfb/flfg/flfg_532/202103/t20210309_50530.html)。署名、引用与使用许可是不同事项。

## R 代码的来源与改编 {#code-sources}

| 位置 | 来源 | 本课程的组织或改动 |
|---|---|---|
| 多变量章节：VAR、递归 SVAR | Bernhard Pfaff 的 `vars` 文档、`Canada` 例程及 Pfaff（2008） | 调整阶数与对象名，合并诊断、IRF 和 FEVD；递归 B 限制按本章另行解释 |
| 多变量章节：异方差 SVAR | `svars::id.cv()`、`id.garch()` 帮助页的 `USA` 例程；Lange 等（2021） | 增加矩阵输出与解释；没有保留原例程的全部重排和限制演示 |
| 多变量章节：HD、CF | `svars::hd()`、`cf()` 文档例程 | 改用前节的识别对象与第一变量，并显式查看反事实输出 |
| 多变量章节：LP | Philipp Adämmer 的 `lpirfs::lp_lin()` 文档例程 | 改用加拿大数据，采用正文指定的阶数与期限 |
| 非平稳章节：Zivot–Andrews | `urca::ur.za()` 文档中的 `nporg` 例程 | 增加年份整理、作图及结果解释 |
| 协整章节：Johansen、VECM | `urca::ca.jo()` 的 `denmark` 例程，及 `cajorls()`、`vars::vec2var()` 文档 | 增加分步输出与 IRF；确定性项、协整秩和参数依本章设定 |
| 数据格式、ARMA、Lab 1、Lab 2、RPS 模拟 | 所列包的公开函数接口；各页注明的软件论文和方法文献 | 课程组织的模拟或分析流程，没有复制包的估计实现源码；不宣称完整复现外部论文 |

从文档例程改编的代码在对应位置保留来源说明。原例程与其适用改动继续按原软件许可处理；仅写出软件名称或引用论文，不能替代许可要求。使用 `citation()` 得到的软件引用与在代码中保留的版权/许可说明也不能互相替代。

## 软件作者、版本与许可 {#software}

核对日期：**2026年10月14日**。下表保留核验时的版本；“运行环境”指实际用于本课程检查的已安装包，“CRAN镜像元数据”指为核对来源读取的 CRAN GitHub 镜像 `DESCRIPTION`，不表示本次执行过该包的全部例程。完整作者名单以各版本 `Authors@R` 为准。

| 软件 | 主要作者或维护者 | 核验版本 | 包声明的许可 |
|---|---|---|---|
| [`forecast`](https://cran.r-project.org/package=forecast) | Rob J. Hyndman、Yeasmin Khandakar 及包贡献者 | 9.0.2（运行环境） | `GPL-3` |
| [`rugarch`](https://cran.r-project.org/package=rugarch) | Alexios Galanos | 1.5-6（运行环境） | `GPL-3` |
| [`strucchange`](https://cran.r-project.org/package=strucchange) | Achim Zeileis、Friedrich Leisch、Kurt Hornik、Christian Kleiber | 1.6-0（运行环境） | `GPL-2 | GPL-3` |
| [`sandwich`](https://cran.r-project.org/package=sandwich) | Achim Zeileis 及包贡献者 | 3.1-3（运行环境） | `GPL-2 | GPL-3` |
| [`FinTS`](https://cran.r-project.org/package=FinTS) | Spencer Graves；Georgi N. Boshnakov（维护） | 0.4-9（运行环境） | `GPL (>= 2)` |
| [`urca`](https://cran.r-project.org/package=urca) | Bernhard Pfaff；Eric Zivot、Matthieu Stigler（贡献） | 1.3-4（运行环境） | `GPL (>= 2)` |
| [`xts`](https://cran.r-project.org/package=xts) | Jeffrey A. Ryan、Joshua M. Ulrich | 0.14.3（运行环境） | `GPL (>= 2)` |
| [`vars`](https://cran.r-project.org/package=vars) | Bernhard Pfaff、Matthieu Stigler | 1.6-1（运行环境） | `GPL (>= 2)` |
| [`svars`](https://cran.r-project.org/package=svars) | Alexander Lange、Bernhard Dalheimer、Helmut Herwartz、Simone Maxand 等 | 1.3.12（运行环境） | `MIT + file LICENSE` |
| [`lpirfs`](https://cran.r-project.org/package=lpirfs) | Philipp Adämmer | 0.2.5（运行环境） | `GPL (>= 2)` |
| [`ggplot2`](https://cran.r-project.org/package=ggplot2) | Hadley Wickham 及包贡献者 | 4.0.3（运行环境） | `MIT + file LICENSE` |
| [`lmtest`](https://cran.r-project.org/package=lmtest) | Achim Zeileis、Torsten Hothorn 等 | 0.9-40（运行环境） | `GPL-2 | GPL-3` |
| [`tseries`](https://cran.r-project.org/package=tseries) | Adrian Trapletti、Kurt Hornik 等 | 0.10-63（运行环境） | `GPL-2 | GPL-3` |
| [`zoo`](https://cran.r-project.org/package=zoo) | Achim Zeileis、Gabor Grothendieck 等 | 1.9-1（运行环境） | `GPL-2 | GPL-3` |
| [`readr`](https://cran.r-project.org/package=readr) | Hadley Wickham、Jim Hester、Jennifer Bryan 等 | 2.2.0（CRAN镜像元数据） | `MIT + file LICENSE` |
| [`readxl`](https://cran.r-project.org/package=readxl) | Hadley Wickham、Jennifer Bryan 等 | 1.5.0.1（CRAN镜像元数据） | `MIT + file LICENSE` |
| [`dplyr`](https://cran.r-project.org/package=dplyr) | Hadley Wickham、Romain François、Lionel Henry、Kirill Müller、Davis Vaughan 等 | 1.2.1（运行环境） | `MIT + file LICENSE` |
| [`lubridate`](https://cran.r-project.org/package=lubridate) | Vitalie Spinu、Garrett Grolemund、Hadley Wickham 等 | 1.9.5（CRAN镜像元数据） | `MIT + file LICENSE` |
| [`tibble`](https://cran.r-project.org/package=tibble) | Kirill Müller、Hadley Wickham 等 | 3.3.1（运行环境） | `MIT + file LICENSE` |
| [`tsibble`](https://cran.r-project.org/package=tsibble) | Earo Wang、Di Cook、Rob J. Hyndman 等 | 1.2.0（CRAN镜像元数据） | `GPL-3` |

`GPL (>= 2)` 表示 GPL 第2版或以后版本；`GPL-2 | GPL-3` 表示包声明的可选许可；`MIT + file LICENSE` 还需要保留该包 `LICENSE` 中指定的版权人信息。许可证随版本可能变化，应按实际使用或改编的版本核对。**包的代码许可不自动概括其数据来源、论文出版版权或图像版权。**

按实际环境引用软件时，可以运行：

```r
citation("vars")
packageVersion("vars")
packageDescription("vars", fields = "License")
```

已安装软件的推荐引用摘自各包 `citation()`，可下载 [软件引用 BibTeX](software-citations.bib)。它保留软件作者推荐的文献；未安装的四个包应在使用者自己的环境中生成引用。

主要软件论文：

- Pfaff（2008），*VAR, SVAR and SVEC Models: Implementation Within R Package vars*，[DOI](https://doi.org/10.18637/jss.v027.i04)。
- Lange、Dalheimer、Herwartz 与 Maxand（2021），*svars: An R Package for Data-Driven Identification in Multivariate Time Series Analysis*，[DOI](https://doi.org/10.18637/jss.v097.i05)。
- Adämmer（2019），*lpirfs: An R Package to Estimate Impulse Response Functions by Local Projections*，[DOI](https://doi.org/10.32614/RJ-2019-052)。
- Hyndman 与 Khandakar（2008），*Automatic Time Series Forecasting: The forecast Package for R*，[DOI](https://doi.org/10.18637/jss.v027.i03)。
- Zeileis、Leisch、Hornik 与 Kleiber（2002），*strucchange: An R Package for Testing for Structural Change in Linear Regression Models*，[DOI](https://doi.org/10.18637/jss.v007.i02)。
- Zeileis（2004），*Econometric Computing with HC and HAC Covariance Matrix Estimators*，[DOI](https://doi.org/10.18637/jss.v011.i10)。
- Pfaff（2008），*Analysis of Integrated and Cointegrated Time Series with R*（第2版），Springer，[DOI](https://doi.org/10.1007/978-0-387-75967-8)。

基础 R 作者为 **R Core Team**，引用说明见 [R 官方页面](https://www.r-project.org/citing-r.html)。ARMA 绘图脚本还调用 NumPy、Pillow 的公开接口，其作者与许可见[NumPy](https://numpy.org/doc/stable/)和 [Pillow](https://pillow.readthedocs.io/en/stable/about.html)。

## 数据来源 {#datasets}

| 数据 | 来源与处理 |
|---|---|
| Lab 1 Brent CSV | 胡哲鹏提供的本人论文研究数据，用于本课程实验；不改标为其他外部机构数据 |
| Lab 2 `USA` | 从 `svars 1.3.12` 导出；原始来源 FRED，变换依据 Herwartz 与 Ploedt（2016）。[数据定义](https://search.r-project.org/CRAN/refmans/svars/html/USA.html)、[论文 DOI](https://doi.org/10.1111/obes.12098) |
| `Canada` | `vars` 所收录的加拿大宏观数据，原始来源 OECD，变换与样本以[包数据文档](https://search.r-project.org/CRAN/refmans/vars/html/Canada.html)为准 |
| `nporg` | `urca` 所收录的 Nelson–Plosser 宏观数据，用于重新绘制实际 GNP 图；原研究 [Nelson 与 Plosser（1982）](https://doi.org/10.1016/0304-3932(82)90012-5) |
| `denmark` | `urca` 所收录的丹麦货币需求数据；原研究 [Johansen 与 Juselius（1990）](https://doi.org/10.1111/j.1468-0084.1990.mp52002003.x) |
| ARMA、趋势/随机趋势、RPS 示例 | 课程脚本按注明过程生成的模拟数据，不是外部论文真实观测或原始估计结果 |

第三方数据的使用应同时核对原提供者条款。FRED 汇集不同来源的数据，不能把“可通过 FRED 下载”当作统一的再分发许可；参见 [FRED 法律与来源说明](https://fred.stlouisfed.org/legal/)。本页的软件许可表不为这些上游资料新增许可。

## 图像与图表来源 {#figures}

| 图像 | 来源说明 |
|---|---|
| 差分方程图2.1 | 依据 Enders（2015），*Applied Econometric Time Series*（第4版）第1章导言的模型，按课程模拟冲击重新绘制；不是原书图像或观测值的逐点复刻 |
| 平稳模型图2-1、图2-2 | 课程按所列 AR/MA/ARMA 参数模拟并绘制；仓库提供 R 与 Python 绘图脚本 |
| 滚动/扩展窗口图2-3 | 课程绘制的样本选择示意，SVG 为可检查的矢量源 |
| 差分平稳/趋势平稳示意图 | 课程按所列过程自行模拟，仓库提供生成脚本 |
| 实际 GNP 图 | 使用已注明的 `urca::nporg` 数据重新绘制；数据出处与方法出处分别引用 |
| RPS 图8-1 | 由本章脚本的模拟数据生成，非 Carter–Smith 或 Adjemian–Smith–He 的论文原图 |
| Lab 2 图表 | 由 `Lab 2.R` 对已注明来源的数据重新计算、绘制；不是论文或软件手册图片转载 |

模型来源、数据来源与图像来源是三个不同层次，应分别保留。依据通用方法重新计算图表，不应署名为原作者的实证结果；重画某幅图也不能作为对原图再发布权的替代判断。

## 第三方许可文本 {#licenses}

### Lab 3：Kilian（2009）复现材料

[Lab 3](../lab-3/index.md) 使用 Kilian（2009）原论文归档数据和复现材料的[固定版本镜像](https://github.com/richryan/jcre-oil/tree/d4e339300f8ee48f2ccb42051cb3a48f1fb9cfb0/kilianAER2009replication)，月度输入另与 [Hansen 配套数据](https://users.ssc.wisc.edu/~bhansen/econometrics/Kilian2009.txt)逐值核对。它不把今日修订版活动指数标为原文当时的数据。

复现包内 `references/author_mirror/LICENSE.txt` 保留镜像所附 AEA 许可文本：代码与软件采用 Modified BSD，数据库、表格及文本等采用 CC BY 4.0。新增 R 代码与整理说明另附 BSD-3-Clause 许可。论文引用为 Kilian（2009），*American Economic Review*, 99(3), 1053–1069，[DOI](https://doi.org/10.1257/aer.99.3.1053)。

R 代码调用 `vars` 与 `openxlsx` 的公开接口；下载包不分发已安装的软件库。图形由 R 按已注明数据重新计算并在绘图窗口显示，不转载论文图片。数据来源、数值核验记录和适用许可随复现包保留。

### 其他软件许可文本

- [GPL 第2版全文](许可证/GPL-2.0.txt)、[GNU 官方 GPL-2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)。
- [GPL 第3版全文](许可证/GPL-3.0.txt)、[GNU 官方 GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html)。
- [svars 1.3.12 的 MIT 版权与许可全文](许可证/svars-1.3.12-MIT.txt)。版权人按该版本 `LICENSE` 保留：Alexander Lange、Bernhard Dalheimer、Helmut Herwartz、Simone Maxand、Hannes Riebl，2018年。

这些文本只保留相应第三方许可，不给本站其他内容添加同名许可。后续引用或改编时应保留具体来源、作者、版本、改动说明与适用许可。

网站构建使用 [MkDocs](https://www.mkdocs.org/)、[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)与 [MathJax](https://www.mathjax.org/)；分别保留其项目的许可及原有署名，Material 页脚来源标识保留。
