# Lab 1

**Brent 价格序列：结构变化、ARMA 与 ARCH/GARCH**

本实验安排在 ARCH/GARCH 课程之后，面向 R 语言初学者。代码按步骤展开，每个模型单独估计，不需要编写循环或自定义函数。

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
2. 检查平稳性前提，进行结构变化检验。
3. 观察 ACF/PACF，分别估计 AR、MA、ARMA 候选模型，用 AIC/BIC 比较阶数。
4. 检查均值模型残差，进行 ARCH-LM 检验。
5. 建立 ARCH(1) 与 GARCH(1,1)，解释参数并诊断标准化残差。
6. 进行多步波动预测和逐月一步样本外预测，比较点预测与波动预测表现。

## 数据说明

数据包含 `Date` 和 `Brent` 两列，共 194 个月度价格观测，时间为 2006 年 1 月至 2022 年 2 月。日期格式为“月/日/年”。原始文件未注明价格单位及月均价、月末价口径。

实验采用百分数形式的对数收益率。训练期为 2006 年 2 月至 2019 年 2 月，测试期为 2019 年 3 月至 2022 年 2 月，共 36 个月。选阶与结构变化检验只使用训练集。

## 实验报告问题

1. 结构变化检验是否拒绝原假设？结论能说明什么，不能说明什么？
2. ACF/PACF 与 AIC/BIC 如何支持均值模型的选择？为什么残差不相关仍可能需要 ARCH/GARCH？
3. 如何解释 GARCH 参数和标准化残差诊断？
4. 点预测与波动预测的排名是否相同？较小的预测误差是否具有统计显著性？
