# 第3章 条件异方差模型（Conditional Heteroskedasticity Models）：ARCH 与 GARCH

在前面的平稳时间序列模型中，我们主要关心序列的条件均值（conditional mean）。例如，AR、MA 和 ARMA 模型解释的是 \(y_t\) 如何由自身过去值和过去冲击所决定。这类模型回答的问题是：给定过去信息，变量的平均变化方向是什么？

但是，在许多经济和金融时间序列中，仅仅描述条件均值是不够的。尤其是在金融市场中，收益率本身可能难以预测，但收益率的波动程度却呈现出明显的动态结构。股票收益率、汇率变化率、期货价格收益率等序列常常表现为：大波动之后容易跟随大波动，小波动之后容易跟随小波动。这种现象称为波动聚集（volatility clustering）。

ARCH 和 GARCH 模型正是为刻画这种波动聚集而发展出来的。它们的核心思想是：序列的条件均值可以比较简单，甚至接近不可预测；但序列的条件方差（conditional variance）并不是常数，而是会随着过去冲击和过去波动而变化。

本章讨论的重点不再是“变量的均值如何变化”，而是“变量的不确定性如何变化”。

**本节小结。** ARMA 模型主要刻画条件均值，ARCH/GARCH 模型主要刻画条件方差。许多经济金融序列的均值动态较弱，但波动动态很强，因此需要专门的条件异方差模型（conditional heteroskedasticity model）。

---

## 3.1 从同方差到条件异方差

在经典线性回归模型中，我们通常假设扰动项具有同方差性（homoskedasticity）。设模型为：

$$
y_t=x_t'\beta+u_t.
$$

同方差假设可以写为：

$$
Var(u_t\mid \mathcal{I}_{t-1})=\sigma^2.
$$

这里 \(\mathcal{I}_{t-1}\) 表示 t−1 期已经可以获得的信息集合（information set）。同方差假设意味着：无论过去发生了什么，当前扰动项的不确定性都保持为同一个常数 \(\sigma^2\)。

这个假设在很多低频宏观数据中有时可以作为近似，但在金融时间序列中往往并不合适。例如，金融危机、政策冲击、战争、极端天气或重大供需变化之后，价格收益率的波动通常会显著放大；而在市场平静时期，波动又会明显降低。

为了刻画这种现象，可以把扰动项写为：

$$
u_t=\sqrt{h_t}\varepsilon_t,
$$

其中：

$$
E(\varepsilon_t)=0,\quad Var(\varepsilon_t)=1.
$$

于是：

$$
Var(u_t\mid \mathcal{I}_{t-1})=h_t.
$$

这里 \(h_t\) 称为条件方差。它不是固定常数，而是可以随时间变化，并且通常由过去信息决定。

这一写法把扰动项分解为两个部分。第一部分是 \(\varepsilon_t\)，表示标准化的新冲击（standardized innovation）；第二部分是 \(\sqrt{h_t}\)，表示当前时期的波动尺度（volatility scale）。当 \(h_t\) 较大时，即使 \(\varepsilon_t\) 本身不大，扰动项 \(u_t\) 也可能表现出较大波动；当 \(h_t\) 较小时，同样大小的标准化冲击只会造成较小波动。

因此，条件异方差模型的基本目标，是为 \(h_t\) 建立一个动态方程。

**本节小结。** 同方差模型假定扰动项的条件方差为常数；条件异方差模型则允许方差随过去信息变化。ARCH/GARCH 模型的核心任务就是解释和预测 \(h_t\)。

---

## 3.2 金融收益率中的典型事实

ARCH/GARCH 模型最常用于金融收益率（financial returns）。设价格序列为 \(P_t\)，对数收益率（log return）通常定义为：

$$
r_t=100\left(\ln P_t-\ln P_{t-1}\right).
$$

乘以 100 之后，\(r_t\) 可以近似理解为百分比收益率。

大量金融数据具有几个典型特征。

第一，收益率本身的线性自相关（linear autocorrelation）通常较弱。也就是说，\(r_t\) 与 \(r_{t-1},r_{t-2},...\) 的相关性可能不明显。这与有效市场思想（efficient market hypothesis）相一致：如果收益率很容易被过去收益率线性预测，那么市场参与者会利用这种规律交易，从而削弱这种可预测性。

第二，收益率平方或绝对值常常存在明显自相关。虽然 \(r_t\) 本身可能接近白噪声，但 \(r_t^2\) 或 \(|r_t|\) 往往呈现持续性。这说明收益率方向未必容易预测，但波动大小具有可预测性。

第三，波动具有聚集性。大幅上涨或下跌之后，市场往往进入高波动阶段；小幅波动之后，市场则可能继续保持平静。换言之，冲击的符号可能很难预测，但冲击的强度会在时间上持续。

第四，金融收益率常常具有厚尾特征（fat tails）。与正态分布相比，极端收益率出现的频率更高。因此，在实际估计 GARCH 模型时，除了正态分布假设，也常使用 t 分布误差。

ARCH/GARCH 模型主要针对第二和第三个事实：收益率平方存在相关性，波动具有聚集性。

**本节小结。** 金融收益率的均值可预测性通常较弱，但波动可预测性较强。ARCH/GARCH 模型不是为了预测收益率方向，而是为了预测收益率的条件方差。

---

## 3.3 ARCH 模型

ARCH 是 autoregressive conditional heteroskedasticity 的缩写，通常译为自回归条件异方差模型（autoregressive conditional heteroskedasticity model）。它由 Engle 提出，基本思想是：当前条件方差取决于过去扰动项的平方。

为了突出核心思想，先考虑一个均值为零的收益率序列：

$$
r_t=u_t.
$$

设：

$$
u_t=\sqrt{h_t}\varepsilon_t,
$$

其中 \(\varepsilon_t\) 是均值为 0、方差为 1 的白噪声。ARCH(q) 模型规定条件方差为：

$$
h_t=\alpha_0+\alpha_1u_{t-1}^2+\alpha_2u_{t-2}^2+\cdots+\alpha_qu_{t-q}^2.
$$

为了保证条件方差为正，通常要求：

$$
\alpha_0>0,\quad \alpha_i\ge 0,\quad i=1,2,\ldots,q.
$$

这个方程的含义非常直观。若上一期或更早时期的冲击平方较大，即 \(u_{t-i}^2\) 较大，那么当前条件方差 \(h_t\) 也会较大。由于平方项不区分正负，所以无论过去是大幅上涨还是大幅下跌，只要冲击幅度大，都会提高未来波动。

最简单的是 ARCH(1)：

$$
h_t=\alpha_0+\alpha_1u_{t-1}^2.
$$

若上一期冲击较小，则 \(u_{t-1}^2\) 较小，当前波动主要接近 \(\alpha_0\)；若上一期出现大冲击，则 \(u_{t-1}^2\) 增大，当前波动随之上升。

注意，ARCH 模型并不一定意味着 \(u_t\) 本身存在自相关。在设定正确时，\(u_t\) 可以是不相关的，但 \(u_t^2\) 却是相关的。这正是金融收益率常见的特征：收益率方向近似不可预测，但波动程度可预测。

**本节小结。** ARCH 模型用过去冲击平方解释当前条件方差。它把“过去是否发生大波动”转化为“当前波动是否升高”的动态方程。

---

## 3.4 ARCH(1) 的无条件方差（Unconditional Variance）

ARCH(1) 模型为：

$$
u_t=\sqrt{h_t}\varepsilon_t,
$$

$$
h_t=\alpha_0+\alpha_1u_{t-1}^2.
$$

由于：

$$
E(\varepsilon_t^2)=1,
$$

所以：

$$
E(u_t^2\mid \mathcal{I}_{t-1})=h_t.
$$

若 ARCH(1) 过程存在稳定的无条件方差（unconditional variance），记为：

$$
Var(u_t)=E(u_t^2)=\sigma_u^2.
$$

对条件方差方程两边取无条件期望：

$$
E(h_t)=\alpha_0+\alpha_1E(u_{t-1}^2).
$$

又因为：

$$
E(h_t)=E(u_t^2)=\sigma_u^2,
$$

且平稳时：

$$
E(u_{t-1}^2)=E(u_t^2)=\sigma_u^2.
$$

因此：

$$
\sigma_u^2=\alpha_0+\alpha_1\sigma_u^2.
$$

整理得：

$$
\sigma_u^2=\frac{\alpha_0}{1-\alpha_1}.
$$

为了使无条件方差为正且有限，需要：

$$
0\le \alpha_1<1.
$$

如果 \(\alpha_1\) 越接近 1，过去冲击平方对未来波动的影响越持久；如果 \(\alpha_1\) 较小，波动冲击衰减较快。

**本节小结。** ARCH(1) 的稳定性要求 \(\alpha_1<1\)。在这一条件下，无条件方差为 \(\alpha_0/(1-\alpha_1)\)。参数 \(\alpha_1\) 衡量波动对过去冲击的敏感程度和持续性。

---

## 3.5 GARCH 模型

ARCH 模型虽然直观，但在实际金融数据中常常需要较高阶数才能刻画波动持续性。例如，若波动冲击持续很久，ARCH(q) 可能需要很大的 q。这样会导致参数过多，估计不稳定。

GARCH 模型在 ARCH 的基础上加入过去条件方差。GARCH 是 generalized ARCH 的缩写，通常译为广义 ARCH 模型（generalized autoregressive conditional heteroskedasticity model）。

最常用的是 GARCH(1,1)：

$$
u_t=\sqrt{h_t}\varepsilon_t,
$$

$$
h_t=\omega+\alpha u_{t-1}^2+\beta h_{t-1}.
$$

其中：

$$
\omega>0,\quad \alpha\ge 0,\quad \beta\ge 0.
$$

这个方程有三部分。

第一，\(\omega\) 是长期基础波动水平。若过去冲击和过去方差都很小，条件方差仍然有一个正的基础水平。

第二，\(\alpha u_{t-1}^2\) 是 ARCH 项（ARCH term），表示上一期冲击平方对当前波动的影响。若上一期发生大冲击，当前条件方差会上升。

第三，\(\beta h_{t-1}\) 是 GARCH 项（GARCH term），表示上一期条件方差对当前条件方差的持续影响。如果上一期处于高波动状态，即使上一期冲击本身已经过去，当前波动也可能继续较高。

因此，GARCH(1,1) 用一个非常简洁的方程同时刻画两种力量：冲击效应和波动惯性。

**本节小结。** GARCH 模型在 ARCH 模型中加入滞后条件方差。GARCH(1,1) 只用少量参数就能刻画持久的波动聚集，因此是应用中最常用的波动率模型。

---

## 3.6 GARCH(1,1) 的长期方差与波动持续性（Volatility Persistence）

对 GARCH(1,1) 方程：

$$
h_t=\omega+\alpha u_{t-1}^2+\beta h_{t-1}
$$

两边取无条件期望。若过程平稳，则：

$$
E(h_t)=E(h_{t-1})=E(u_t^2)=\sigma_u^2.
$$

于是：

$$
\sigma_u^2=\omega+\alpha\sigma_u^2+\beta\sigma_u^2.
$$

整理得：

$$
\sigma_u^2=\frac{\omega}{1-\alpha-\beta}.
$$

为了使长期方差为正且有限，通常要求：

$$
\alpha+\beta<1.
$$

\(\alpha+\beta\) 是 GARCH 模型中最重要的参数组合之一，它衡量波动的持续性（volatility persistence）。若 \(\alpha+\beta\) 较小，波动冲击衰减较快；若 \(\alpha+\beta\) 接近 1，波动冲击会非常持久。

例如，在金融市场中，估计得到的 \(\alpha+\beta\) 经常接近 1。这意味着一次重大市场冲击之后，波动率可能需要较长时间才能回到正常水平。

GARCH(1,1) 的条件方差还可以写成向长期方差回归的形式。设长期方差为：

$$
\bar h=\frac{\omega}{1-\alpha-\beta}.
$$

由于：

$$
\omega=(1-\alpha-\beta)\bar h,
$$

所以：

$$
h_t=(1-\alpha-\beta)\bar h+\alpha u_{t-1}^2+\beta h_{t-1}.
$$

这个表达式说明，当前条件方差由长期均值、上一期冲击平方和上一期条件方差共同决定。若当前波动高于长期水平，只要 \(\alpha+\beta<1\)，它最终会向长期方差回归。

**本节小结。** GARCH(1,1) 的长期方差为 \(\omega/(1-\alpha-\beta)\)。参数和 \(\alpha+\beta\) 衡量波动持续性，是判断波动冲击衰减速度的关键。

---

## 3.7 GARCH 与 ARMA 的关系

GARCH 模型虽然是条件方差模型，但它与 ARMA 模型有密切联系。这个关系有助于理解为什么 GARCH 能刻画平方收益率的自相关。

以 GARCH(1,1) 为例：

$$
h_t=\omega+\alpha u_{t-1}^2+\beta h_{t-1}.
$$

定义：

$$
v_t=u_t^2-h_t.
$$

由于：

$$
E(u_t^2\mid \mathcal{I}_{t-1})=h_t,
$$

所以：

$$
E(v_t\mid \mathcal{I}_{t-1})=0.
$$

也就是说，\(v_t\) 是平方冲击中无法由过去信息预测的部分。由定义可得：

$$
h_t=u_t^2-v_t.
$$

将 \(h_t\) 和 \(h_{t-1}=u_{t-1}^2-v_{t-1}\) 代入 GARCH 方程：

$$
u_t^2-v_t
=\omega+\alpha u_{t-1}^2+\beta(u_{t-1}^2-v_{t-1}).
$$

整理得：

$$
u_t^2
=\omega+(\alpha+\beta)u_{t-1}^2+v_t-\beta v_{t-1}.
$$

这说明 \(u_t^2\) 可以表示为一个 ARMA(1,1) 形式。也就是说，GARCH(1,1) 隐含了平方扰动项的动态相关结构。收益率本身可以近似没有自相关，但收益率平方却可以表现出类似 ARMA 过程的持续性。

这个结果也解释了模型诊断中的一个重要步骤：如果均值方程残差没有明显自相关，但残差平方仍然存在自相关，就说明可能存在 ARCH/GARCH 效应。

**本节小结。** GARCH 模型可以看作是对平方扰动项动态结构的建模。GARCH(1,1) 隐含 \(u_t^2\) 具有 ARMA(1,1) 形式，因此能够解释收益率平方的持续相关。

---

## 3.8 ARCH 效应检验（ARCH Effects Test）

在建立 GARCH 模型之前，通常需要先判断数据中是否存在条件异方差。常见方法是 ARCH-LM 检验（ARCH Lagrange Multiplier test）。

设已经估计了某个均值方程，并得到残差 \(\hat u_t\)。ARCH-LM 检验的基本思想是：如果不存在 ARCH 效应，那么过去残差平方不应显著解释当前残差平方。

具体做法是估计辅助回归（auxiliary regression）：

$$
\hat u_t^2
=\delta_0+\delta_1\hat u_{t-1}^2+\delta_2\hat u_{t-2}^2+\cdots+\delta_q\hat u_{t-q}^2+e_t.
$$

原假设为：

$$
H_0:\delta_1=\delta_2=\cdots=\delta_q=0.
$$

如果拒绝原假设，说明残差平方存在显著自相关，即存在 ARCH 效应。此时使用普通同方差模型可能低估或误判风险，进一步建立 ARCH/GARCH 模型就是合理的。

常见检验统计量（test statistic）为：

$$
TR^2,
$$

其中 T 是辅助回归的样本量，\(R^2\) 是辅助回归的决定系数。在原假设成立且样本较大时：

$$
TR^2\sim \chi^2(q).
$$

**本节小结。** ARCH-LM 检验通过检验残差平方是否能被自身滞后项解释，判断序列中是否存在条件异方差。它是建立 GARCH 模型前的重要诊断步骤。

---

## 3.9 GARCH 模型的估计与诊断（Estimation and Diagnostics）

GARCH 模型通常使用最大似然法（maximum likelihood）估计。设标准化误差（standardized error）\(\varepsilon_t\) 服从标准正态分布，则：

$$
u_t\mid \mathcal{I}_{t-1}\sim N(0,h_t).
$$

在给定参数的情况下，可以递推计算每一期的 \(h_t\)，进而写出对数似然函数（log-likelihood function）。单期对数似然为：

$$
\ell_t
=-\frac{1}{2}\left[\ln(2\pi)+\ln h_t+\frac{u_t^2}{h_t}\right].
$$

样本对数似然为：

$$
L=\sum_{t=1}^{T}\ell_t.
$$

最大似然估计就是选择参数，使得 L 最大。

估计完成后，需要进行模型诊断。一个好的 GARCH 模型应当满足两个基本要求。

第一，标准化残差（standardized residuals）：

$$
\hat\varepsilon_t=\frac{\hat u_t}{\sqrt{\hat h_t}}
$$

不应存在明显自相关。否则说明均值方程可能仍然遗漏了动态结构。

第二，标准化残差平方（squared standardized residuals）：

$$
\hat\varepsilon_t^2
$$

不应存在明显自相关。否则说明方差方程仍然没有充分解释波动聚集。

因此，实际诊断中通常会分别检查 \(\hat\varepsilon_t\) 和 \(\hat\varepsilon_t^2\) 的 ACF，并对二者进行 Ljung-Box 检验。

此外，还要关注参数是否满足正值约束和平稳性约束。例如，在 GARCH(1,1) 中，一般希望：

$$
\omega>0,\quad \alpha\ge 0,\quad \beta\ge 0,\quad \alpha+\beta<1.
$$

如果 \(\alpha+\beta\) 非常接近 1，说明波动持续性极强。此时模型虽然可能拟合良好，但也提示市场波动具有高度持久性。

**本节小结。** GARCH 模型通常用最大似然法估计。估计后不仅要看参数显著性，还要检查标准化残差和标准化残差平方是否仍有相关性。

---

## 3.10 条件方差预测（Conditional Variance Forecasting）

GARCH 模型最重要的用途之一是预测未来波动率（volatility forecasting）。

以 GARCH(1,1) 为例：

$$
h_{t+1}=\omega+\alpha u_t^2+\beta h_t.
$$

在 t 期，\(u_t^2\) 和 \(h_t\) 都已经可以得到，因此一步条件方差预测（one-step-ahead conditional variance forecast）为：

$$
\hat h_{t+1|t}=\omega+\alpha u_t^2+\beta h_t.
$$

二步预测为：

$$
\hat h_{t+2|t}
=\omega+\alpha E_t(u_{t+1}^2)+\beta \hat h_{t+1|t}.
$$

由于：

$$
E_t(u_{t+1}^2)=\hat h_{t+1|t},
$$

所以：

$$
\hat h_{t+2|t}
=\omega+(\alpha+\beta)\hat h_{t+1|t}.
$$

类似地，h 步条件方差预测满足递推关系：

$$
\hat h_{t+h|t}
=\omega+(\alpha+\beta)\hat h_{t+h-1|t},
\quad h\ge 2.
$$

设长期方差为：

$$
\bar h=\frac{\omega}{1-\alpha-\beta}.
$$

则 h 步条件方差预测可以写为：

$$
\hat h_{t+h|t}
=\bar h+(\alpha+\beta)^{h-1}(\hat h_{t+1|t}-\bar h).
$$

这个公式说明，未来波动率预测会逐步回到长期方差。若 \(\alpha+\beta\) 越接近 1，回归速度越慢；若 \(\alpha+\beta\) 较小，波动率预测更快接近长期水平。

**本节小结。** GARCH 的预测对象是未来条件方差。GARCH(1,1) 的多步方差预测会向长期方差回归，回归速度由 \(\alpha+\beta\) 决定。

---

## 3.11 应用含义：风险、波动率与预测

ARCH/GARCH 模型在应用经济和金融研究中有多种用途。

第一，它可以用于估计和预测波动率。对股票、汇率、利率、商品期货等序列而言，波动率本身就是重要研究对象。市场平静与市场动荡往往对应不同的投资决策和政策含义。

第二，它可以用于风险度量（risk measurement）。例如，在金融风险管理中，条件方差预测可以用于计算风险价值 VaR（Value at Risk）。若假设：

$$
r_{t+1}\mid \mathcal{I}_t\sim N(\mu_{t+1|t},h_{t+1|t}),
$$

则 5% 分位数可以近似写为：

$$
VaR_{0.05,t+1}
=\mu_{t+1|t}-1.645\sqrt{h_{t+1|t}}.
$$

这说明，当预测波动率上升时，即使预测均值不变，潜在损失也会扩大。

第三，它可以改善均值方程的推断。若扰动项存在条件异方差而模型没有处理，参数估计的标准误可能不准确，从而影响显著性判断。

第四，它可以用于比较不同市场或不同时期的风险特征。例如，可以研究某一政策实施前后波动持续性是否变化，也可以比较不同农产品期货市场的波动聚集程度。

不过，GARCH 模型也有局限。标准 GARCH 模型假设正负冲击对波动的影响是对称的，即同样大小的正冲击和负冲击对 \(h_t\) 的影响相同。但在股票市场中，负收益往往比正收益更容易引发未来波动上升，这称为杠杆效应（leverage effect）。为了刻画这种不对称性（asymmetry），可以进一步使用 EGARCH、GJR-GARCH 等扩展模型。

**本节小结。** ARCH/GARCH 模型不仅是统计工具，也是理解金融市场风险动态的重要框架。它能够刻画波动聚集、预测未来风险，并为风险管理和政策分析提供量化依据。

---

## 本章阶段性小结

ARCH 和 GARCH 模型把时间序列分析的重点从条件均值扩展到条件方差。它们适用于那些均值难以预测但波动可以预测的经济金融序列。

ARCH 模型用过去冲击平方解释当前条件方差，GARCH 模型进一步加入过去条件方差，从而用更少参数刻画更持久的波动动态。GARCH(1,1) 是最常用的基本模型，其条件方差方程为：

$$
h_t=\omega+\alpha u_{t-1}^2+\beta h_{t-1}.
$$

其中 \(\alpha\) 反映新冲击对波动的影响，\(\beta\) 反映波动本身的惯性，\(\alpha+\beta\) 衡量波动持续性。若 \(\alpha+\beta<1\)，模型具有有限长期方差；若 \(\alpha+\beta\) 接近 1，说明波动冲击衰减很慢。

从应用角度看，ARCH/GARCH 模型特别适合金融收益率、汇率、利率和商品期货价格变化率等数据。它们不是为了预测价格上涨还是下跌，而是为了预测未来不确定性的大小。

## 思考题

1. 为什么金融收益率本身可能接近白噪声，但收益率平方却存在明显自相关？
2. ARCH 模型为什么使用过去扰动项的平方，而不是扰动项本身？
3. 在 ARCH(1) 模型中，为什么要求 \(\alpha_1<1\)？
4. GARCH(1,1) 中 \(\alpha\)、\(\beta\) 和 \(\alpha+\beta\) 分别有什么含义？
5. 为什么说 GARCH(1,1) 能够用较少参数刻画持久波动？
6. ARCH-LM 检验的原假设是什么？如果拒绝原假设，说明什么？
7. 估计 GARCH 模型后，为什么要检查标准化残差平方的自相关？
8. 为什么 GARCH 模型的多步方差预测会向长期方差回归？
9. 标准 GARCH 模型为什么不能刻画正负冲击的不对称影响？
