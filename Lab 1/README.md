# Lab 1

Brent 价格序列：结构变化、ARMA 与 ARCH/GARCH。适合 R 语言初学者，代码逐段展开，无需编写循环或自定义函数。

- [R 代码：Lab 1.R](Lab%201.R)
- [数据：lab 1.csv](lab%201.csv)
- [课程网站：实验说明与下载](https://zhepenghucau.github.io/Time-seriese-analysis-China-Agricultural-University/lab-1/)

将代码和数据下载到同一个文件夹，用 RStudio 打开代码，选择 Session → Set Working Directory → To Source File Location。首次使用请运行代码开头的包安装命令，再从上往下分节执行。

数据为2006年1月至2022年2月的194个月度Brent价格。代码含结构变化检验、ACF/PACF识别、AIC/BIC选阶、ARCH-LM检验、ARCH/GARCH估计与诊断，以及36个月的样本外预测比较。
