# Lab 1

**Brent 价格序列：结构变化、ARMA 与 ARCH/GARCH**

本实验使用 Brent 价格序列，完成结构变化检验、ARMA 与 ARCH/GARCH 建模及预测比较。代码按步骤展开，每个模型单独估计，并附有操作和结果解释的注释。

## 下载数据和代码

- [下载数据：lab 1.csv](lab%201.csv){ download="lab 1.csv" }
- [下载 R 代码：Lab 1.R](Lab%201.R){ download="Lab 1.R" }
- [在 GitHub 查看 Lab 1](https://github.com/ZhepengHuCAU/Time-seriese-analysis-China-Agricultural-University/tree/main/Lab%201)

请将两个文件保存在同一个文件夹中。如果浏览器直接显示代码或数据，可右键下载链接，选择“链接另存为”，并保留原文件名。

## 如何运行

1. 使用 RStudio 打开 `Lab 1.R`，编码选择 UTF-8。
2. 将工作目录设置为这两个文件所在的文件夹：在 RStudio 中选择 **Session → Set Working Directory → To Source File Location**。
3. 第一次运行时，去掉代码开头 `install.packages(...)` 一行前的 `#`，运行该行安装所需包。
4. 从 `library(...)` 开始，按小节选中代码，按 **Ctrl+Enter** 逐段运行。先阅读注释、观察图表，再进入下一步。

也可在设置好工作目录后一次运行：

```r
source("Lab 1.R", encoding = "UTF-8")
```

图形显示在 RStudio 的 Plots 窗口；预测比较表保存在工作目录下的 `Lab1/results_beginner` 文件夹。

## 实验内容

1. 读取价格序列，计算对数收益率，划分训练集与测试集。
2. 分别对原始价格、对数价格和收益率进行 ADF、PP、KPSS 检验，再进行结构变化检验。
3. 观察 ACF/PACF，分别估计 AR、MA、ARMA 候选模型，用 AIC/BIC 比较阶数。
4. 检查均值模型残差，进行 ARCH-LM 检验。
5. 建立 ARCH(1) 与 GARCH(1,1)，解释参数并诊断标准化残差。
6. 进行多步波动预测和逐月一步样本外预测，比较点预测与波动预测表现。

## 数据说明

数据来源：课程作者胡哲鹏提供的本人论文研究数据。数据包含 `Date` 和 `Brent` 两列，共 194 个月度价格观测，时间为 2006 年 1 月至 2022 年 2 月。日期格式为“月/日/年”。原始文件未注明价格单位及月均价、月末价口径。

实验采用百分数形式的对数收益率。训练期为 2006 年 2 月至 2019 年 2 月，测试期为 2019 年 3 月至 2022 年 2 月，共 36 个月。选阶与结构变化检验只使用训练集。

## 实验报告问题

1. 结构变化检验是否拒绝原假设？结论能说明什么，不能说明什么？
2. ACF/PACF 与 AIC/BIC 如何支持均值模型的选择？为什么残差不相关仍可能需要 ARCH/GARCH？
3. 如何解释 GARCH 参数和标准化残差诊断？
4. 点预测与波动预测的排名是否相同？较小的预测误差是否具有统计显著性？

## ADF、PP 与 KPSS：如何正确解释？ {#stationarity-tests}

代码分别对原始价格、对数价格和收益率进行 ADF、PP 与 KPSS 检验。`adf_price`、`adf_logprice` 和 `adf_return` 分别对应三个对象的 ADF 结果，结论需限定到具体样本、设定和显著性水平。

### 训练样本的核验结果

价格与对数价格使用 2006 年 1 月至 2019 年 2 月的 158 期观测；收益率使用 2006 年 2 月至 2019 年 2 月的 157 期观测。ADF 含常数、不含时间趋势，最多 6 个差分滞后，以 BIC 选阶；PP 同样含常数、不含趋势，采用 Z-tau 和短带宽；KPSS 检验水平平稳，采用短带宽。以下均按 **5% 显著性水平**解释。

| 检验对象 | ADF tau2 | PP Z-tau | KPSS | 对应证据 |
|---|---:|---:|---:|---|
| 原始价格 | −2.432 | −2.169 | 0.578 | ADF/PP 不拒绝单位根；KPSS 拒绝水平平稳 |
| 对数价格 | −2.377 | −2.209 | 0.595 | ADF/PP 不拒绝单位根；KPSS 拒绝水平平稳 |
| 对数收益率 | −6.816 | −8.686 | 0.065 | ADF/PP 拒绝单位根；KPSS 不拒绝水平平稳 |

ADF 的 5% 临界值为 −2.88，PP 约为 −2.880，统计量更负才拒绝单位根。KPSS 的 5% 临界值为 0.463，统计量更大才拒绝平稳。

这些结果支持本实验采用收益率研究涨跌与波动，但**不拒绝单位根不等于证明非平稳，不拒绝平稳也不等于证明平稳**。不要用三个检验多数表决替代对样本和设定的判断。

### 容易误读的输出

- `ur.df()` 输出上方回归表中的 `Pr(>|t|)` 不是 ADF 单位根检验的 p 值。例如训练期对数价格的普通回归 p 值约为 0.0187，但其 ADF tau2 为 −2.377，没有越过 5% 临界值 −2.88。
- `phi1` 是联合限制的 F 型统计量，不能替代 `tau2` 进行同一种判断。
- 若使用 `tseries::adf.test()`，输出的 `alternative hypothesis: stationary` 仅写明备择假设，不是最终检验结论。该函数默认还包含时间趋势，与这里的 `ur.df(type="drift")` 设定不同。
- PP 以单位根为原假设；KPSS 以平稳为原假设。两者的拒绝方向相反。

### 为什么可能得到“价格也是平稳的”？

在 2006 年 1 月至 2022 年 2 月的**全样本**上，采用含常数、无趋势、最多 6 阶并由 BIC 选阶的 ADF：

- 原始价格 tau2 约 −2.714：在 5% 水平不拒绝单位根，在 10% 水平拒绝。
- 对数价格 tau2 约 −3.059：在 5% 水平拒绝单位根，支持该设定下的平稳备择。

因此，需要说明结论指的是原始价格还是对数价格、训练期还是全样本，以及显著性水平和检验设定。脚本末尾比较了全样本与训练样本的检验结果；全样本结果不用于前面的训练期模型选择。

检验使用 [urca 的 ADF 接口](https://search.r-project.org/CRAN/refmans/urca/html/ur.df.html)、[PP 接口](https://search.r-project.org/CRAN/refmans/urca/html/ur.pp.html)与 [KPSS 接口](https://search.r-project.org/CRAN/refmans/urca/html/ur.kpss.html)。更多讨论见[单位根检验比较](../第4章_非平稳时间序列模型/index.md#unit-root-test-comparison)。

## 方法与软件引用 {#references}

本实验代码为课程按 Brent 数据组织的逐步分析流程；调用所列软件接口，不复制包的估计实现源码，也不宣称复现外部论文。主要方法和软件来源：

- Engle, R. F. (1982). *Autoregressive Conditional Heteroscedasticity with Estimates of the Variance of United Kingdom Inflation*. *Econometrica*, 50(4), 987. [DOI](https://doi.org/10.2307/1912773).
- Bollerslev, T. (1986). *Generalized autoregressive conditional heteroskedasticity*. *Journal of Econometrics*, 31(3), 307–327. [DOI](https://doi.org/10.1016/0304-4076(86)90063-1).
- Bai, J.; Perron, P. (2003). *Computation and analysis of multiple structural change models*. *Journal of Applied Econometrics*, 18(1), 1–22. [DOI](https://doi.org/10.1002/jae.659).
- Hyndman, R. J.; Khandakar, Y. (2008). *Automatic Time Series Forecasting: The forecast Package for R*. *Journal of Statistical Software*, 27(3). [DOI](https://doi.org/10.18637/jss.v027.i03).
- Zeileis, A.; Leisch, F.; Hornik, K.; Kleiber, C. (2002). *strucchange : An R Package for Testing for Structural Change in Linear Regression Models*. *Journal of Statistical Software*, 7(2). [DOI](https://doi.org/10.18637/jss.v007.i02).
- Pfaff, B. (2008). *Analysis of Integrated and Cointegrated Time Series with R*. Springer New York. [DOI](https://doi.org/10.1007/978-0-387-75967-8).

具体接口依据：[forecast](https://pkg.robjhyndman.com/forecast/)、[rugarch 手册](https://cran.r-project.org/web/packages/rugarch/rugarch.pdf)、[FinTS::ArchTest](https://search.r-project.org/CRAN/refmans/FinTS/html/ArchTest.html)、[strucchange::breakpoints](https://search.r-project.org/CRAN/refmans/strucchange/html/breakpoints.html)、[urca](https://cran.r-project.org/package=urca)。软件作者、版本和许可见[版权与引用](../版权与引用/index.md#software)。
