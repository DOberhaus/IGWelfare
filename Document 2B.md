# Document 2B: "Thick" vs. "Thin" Numbers in Quantitative Public Policy
## Why Dimension-Free State-Contingent Conditioning Captures Comonotonic Tail Risks Without Expanding GPU Grid Dimensions

*Author:* Michael Tiemann (mdtiemann@gmail.com)  
*Date:* November 2026 | *Code & Replication Repository:* [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 2](Document%202.md) (Technical Specification Guide), [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Strategy & Policy Answer Key), [Document 1C](Document%201C.md) (Executive Brief), and [Document 3](Document%203.md) (Coalition Architecture & Public Synthesis)*

---

## 1. Pedagogical Motivation: Why "Thin" Spreadsheet Numbers Miss the Real Policy Story

A recurring question in public-finance modeling is why a dynamic stochastic Overlapping Generations (OLG) model solved on the GPU via the Value Function Iteration (VFI) Toolkit yields starkly different policy conclusions from a deterministic spreadsheet projection—even when both models are calibrated to the exact same national averages.

The answer lies in the distinction between **"thin" numbers** and **"thick" numbers**, which has fundamental mathematical, empirical, and computational consequences.

In the computational macroeconomics and stochastic dynamic programming literature, converting a deterministic scalar parameter into a "thick" distribution without adding new grid axes is formally known as **Dimension-Free State-Contingent Parameterization** (or *Comonotonic Tail-Risk Conditioning across the Tauchen Markov and Endogenous Asset Manifold*). Rather than expanding the exogenous Markov state space via a Cartesian product $Z_1 \times Z_2 \times Z_3$—which suffers from the curse of dimensionality and falsely assumes that extended *whānau* care capacity, rental eviction risk, and early-childhood staffing bottlenecks are statistically independent of household income and wealth—we project these structural frictions directly onto the existing 19,215-point state tensor $(a, h, \theta_c, z, j)$ using canonical parameters `K_whanau_base`, `Q_reg_base`, `G_ece_stage1`, `G_ece_stage2`, and `agej`. Our objective is to avoid two common modeling pitfalls: sacrificing structural realism to keep the state space computationally tractable under the curse of dimensionality, or misrepresenting distributional tail risks by treating population averages as representative of heterogeneous household realities.

* **"Thin" Numbers (Deterministic Means Modeled in Spreadsheets):** A conventional spreadsheet tracks a single real-numbered average per cohort or region—such as mean household income $`\bar{y}_k`$, average regional house price $`Q_k`$, average public early-childhood expenditure $`G_{\mathrm{ece}}`$, and average extended *whānau* support $`\bar{K}_{\mathrm{wh\bar{a}nau}}`$—and feeds those scalar averages into real-valued algebraic formulas:

$$Y_{\mathrm{Excel}} = f\left(\mathbb{E}[a],\, \mathbb{E}[h],\, \mathbb{E}[\theta_c],\, \mathbb{E}[z]\right)$$

* **"Thick" Numbers (Probability Distributions Over Markov Transition Matrices Modeled in the VFI Toolkit):** In our model, household state variables are not scalars; they are probability distributions $`\mu_k(a, h, \theta_c, z, j)`$ defined over a discrete state tensor of $61 \times 7 \times 9 \times 5 = 19,215$ states per age cohort $j \in \{1, \dots, J\}$ and region $k \in \{\mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland}\}$. At every age step, the Bellman operator integrates the nonlinear value function across the $5 \times 5$ Tauchen Markov transition matrix $`\pi_{z,k}(z^{\prime}\mid z)`$ spanning $\pm 3.0$ standard deviations (`Tauchen_q = 3.0`):

$$Y_{\mathrm{VFI}} = \mathbb{E}_{\mu_k}\left[f\left(a, h, \theta_c, z\right)\right] = \sum_{a, h, \theta_c, z} \mu_k\left(a, h, \theta_c, z, j\right) f\left(a, h, \theta_c, z\right)$$

Whenever the structural law of motion $f(\cdot)$ is strongly concave, features kinked corner constraints ($i_c = 0$, $a^{\prime} \ge 0$), or exhibits harmonic-mean bottlenecks ($\varphi_2 = -0.95 < 0$), **Jensen's Inequality** guarantees a massive divergence between the function of the average and the average of the function:

$$\mathbb{E}_{\mu_k}\left[f\left(a, h, \theta_c, z\right)\right] \ll f\left(\mathbb{E}[a],\, \mathbb{E}[h],\, \mathbb{E}[\theta_c],\, \mathbb{E}[z]\right)$$

In a deterministic spreadsheet, an average child with average family income $\bar{z} = 1.0$, average public wraparound $`G_{\mathrm{ece},2} = 0.065`$, and average extended *whānau* support $`\bar{K}_{\mathrm{wh\bar{a}nau}} = 0.35`$ smoothly clears the Stage-2 adolescent skill gate with zero stunting. In the real world—and in our VFI distribution—stunting, state-care entry (Exit 1), acute hospitalisation (Exit 2), and trans-Tasman brain drain are driven by **interacting tail states** (such as a household in $z_1$ unemployment simultaneously hitting the $a = 0$ rental-stress boundary and the $i_c = 0$ child-investment corner).

---

## 2. The Curse of Dimensionality Trap vs. Zero-Cost State Conditioning

When researchers realize that regional parameters like extended *whānau* support (`K_whanau_base`), housing user costs (`Q_reg_base`), and public wraparound effectiveness (`G_ece`) vary across households, their first instinct is often to add new exogenous shock dimensions—for example, expanding `n_z` from a 1D vector of 5 states to a 3D tensor `n_z = [5, 3, 3]` (45 exogenous states per grid point).

Adding orthogonal $z$-dimensions is both computationally wasteful and economically misspecified:
* **Computational Cost:** Increasing $N_z$ from 5 to 45 multiplies the size of the Markov transition matrix $\pi_z$ by $(45/5)^2 = 81\times$ and expands the GPU return-matrix workspace by $9\times$.
* **Economic Misspecification:** Real-world shocks to extended *whānau* care capacity, rental eviction risk, and early-childhood service access are **not orthogonal** to a household's income shock $z$, net worth $a$, and adult skill tier $h$; they are **tightly co-determined** by them.

**The Zero-Dimension-Cost "Thickening" Principle:** Instead of adding new grid axes, we convert thin regional scalars (`K_whanau_base`, `Q_reg`, `G_ece_stage1`, `G_ece_stage2`, and `sj`) into **state-contingent functions** evaluated directly on the existing state space $(a, h, \theta_c, z, j, k)$. Because the VFI solver already loops over every $(a, h, \theta_c, z, j)$ coordinate on the GPU, conditioning these parameters on existing state variables transforms each scalar into a **19,215-point thick probability distribution** at **zero additional GPU memory or grid-dimension cost**.

---

## 3. Audit of the Four State-Contingent Structural Operators (Uniting the MBA and MPP Lenses Across Thick and Thin)

Evaluating the model simultaneously through a **Long-Horizon Sovereign Turnaround (MBA) Lens** (focused on off-balance-sheet assets, Theory of Constraints bottlenecks, and R&D talent walkouts) and a **Master of Public Policy (MPP) Lens** (focused on actuarial equity, sandwich-generation care burdens, institutional trust, and workforce capacity) reveals four exact mechanisms where scalar approximations must be replaced with **dimension-free state-contingent parameterizations** and **comonotonic tail-risk coupling**:

| Mechanism & Parameter | Scalar Approximation (Spreadsheet / Naive OLG) | Real-World Edge-Case Interaction (MBA & MPP Blind Spot) | Dimension-Free Sub-Manifold Conditioned Operator on $(a, h, \theta_c, z, j, k)$ |
| :--- | :--- | :--- | :--- |
| **1. Extended Whānau Care & Sandwich Reversal** (`K_whanau_base`) | Positive regional scalar $`K_{\mathrm{wh\bar{a}nau},k} > 0`$ that uniformly buffers adolescent stress. | **Sandwich-Generation Care Reversal:** When NZ Super is raised to 67/70, low-$z$, low-$a$ elders in poor health do not merely reduce downward childcare ($`K_{\mathrm{wh\bar{a}nau}} \to 0`$); they require *upward caregiving and cash bailouts* from their 35-year-old children ($`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}} < 0`$). | State-contingent net *whānau* transfer $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}(i_c, z, a, J_r, k)`$ that flips negative at the comonotonic distress tail ($z = z_1$, $a < 0.12 Q_k$) when $\mathrm{Age}_{\mathrm{Super}} > 65$. |
| **2. Non-Fungible Whānau Trust Gating** (`M_mentor` $\times$ `K_whanau`) | Multiplicative independent substitutes $`(1 - 0.80 M_{\mathrm{mentor}})(1 - 0.55 K_{\mathrm{wh\bar{a}nau}})`$. | **Institutional Distrust at the Tail:** For trauma-affected or alienated youth ($z_1$), school-based mentoring (`M_mentor`) cannot substitute one-for-one for broken family trust; baseline *Whānau Ora* stability is the bridge that unlocks school mentoring engagement. | State-conditioned trust-gated mentoring intensity $`M_{\mathrm{trust}}(K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}, M_{\mathrm{mentor}})`$ where positive *whānau* stability gates school mentoring efficacy. |
| **3. Kaiako Workforce Housing Deflator** (`G_ece_stage1`, `G_ece_stage2`) | Nominal dollar of Crown `G_ece` buys identical real ECE/mentoring services in Auckland (`Q_reg = 3.10`) and Rural (`Q_reg = 1.05`). | **Educator Supply Bottleneck:** Unaffordable metropolitan rents price early-childhood *Kaiako* and speech therapists out of Auckland and Large cities, eroding real delivery capacity per Crown dollar. | Price-manifold conditioned wraparound capacity $`G_{\mathrm{ece},s}^{\mathrm{eff}}(Q_k) = G_{\mathrm{ece},s} \cdot (Q_{\mathrm{reg,base},k}/Q_k)^{\nu_{\mathrm{kaiako}}}`$, creating an endogenous complementarity wedge when housing cools. |
| **4. LVR Tenure Hurdle & Differential Mortality** (`Q_reg`, `sj`) | Regional scalar tenure share $\xi_k$ and uniform age survival vector $s_j$ across all skill tiers $h_1 \dots h_7$. | **Eviction Tail & Actuarial Regressivity:** Asset-poor renters ($a < 0.20 Q_k$) cannot access owner user costs $rh_k$ and suffer transience penalties at $z_1$; manual/Māori/Pasifika workers in $h_1\text{--}h_2$ face steeper late-life health depreciation and shorter retirement horizons. | Asset-manifold gated tenure $`\xi_{\mathrm{hh}}(a, Q_k)`$ with comonotonic tail transience wedge, paired with skill-contingent late-life survival and work disutility $`s_j^{\mathrm{eff}}(h, j)`$. |

---

## 4. Mathematical Specification of the Four State-Contingent Operators

### 4.1 State-Contingent Extended Whānau Care ($`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}`$): Comonotonic Sandwich-Generation Reversal & Trust-Gated Mentoring

In a scalar parameterization, extended *whānau* support (grandmothers, *kuia*, aunties, and *kaumātua* aged 55–72) is represented as a static regional constant $`K_{\mathrm{whanau,base},k} \in [0.28, 0.42]`$. Under that deterministic scalar view, raising the New Zealand Superannuation eligibility age from 65 to 67 or 70 simply trims the regional constant by 36.2% as elders are forced back into market labor.

Under our **state-contingent parameterization** inside `HumanCapital_Lifecycle_aprimeFn.m` and `ReturnFn_SpatialHH.m`, net extended *whānau* support $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}(i_c, z, a, J_r, k)`$ is conditioned directly on the household's endogenous investment and balance-sheet sub-manifold:

$$K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}\left(i_c, z, a, J_r, k\right) = K_{\mathrm{wh\bar{a}nau},k}\left(J_r, Q_k\right) - \psi_{\mathrm{sandwich}}\, \mathbb{I}_{\mathrm{Super}>65} \cdot \mathbb{I}_{\mathrm{distress}}\left(i_c, z, a\right)$$

where $`K_{\mathrm{wh\bar{a}nau},k}(J_r, Q_k)`$ reflects the active regional *whānau* network (`Params.K_whanau`), $`\mathbb{I}_{\mathrm{Super}>65} = \mathbb{I}(20 + (J_r - 1)\Delta t > 65.5)`$ indicates a pension-age hike, $`\mathbb{I}_{\mathrm{distress}}(i_c, z, a) = \mathbb{I}(i_c < 0.01 \lor (z < 0.80 \land a < 0.12 Q_k))`$ isolates households in the comonotonic tail hardship corner, and $`\psi_{\mathrm{sandwich}} = 0.28`$ captures the **Sandwich-Generation Care Reversal**:

* **Unconstrained & Moderate States ($`\mathbb{I}_{\mathrm{distress}} = 0`$):** $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}} > 0`$. Extended *whānau* act as net suppliers of downward childcare and adolescent emotional scaffolding.
* **Comonotonic Tail Distress States Under Super Age 67/70 ($`\mathbb{I}_{\mathrm{Super}>65} = 1`$ and $`\mathbb{I}_{\mathrm{distress}} = 1`$):** $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}} < 0`$. Denied universal NZ Super at ages 65–69 while experiencing manual health depreciation, vulnerable elders cannot provide free childcare and instead require *upward financial and caregiving support* from their prime-age adult children:

$$\mathrm{Drag}_{\mathrm{sandwich}}\left(z, a, J_r, k\right) = 0.035 \max\left(0,\, -K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}\left(i_c, z, a, J_r, k\right)\right)$$

Simultaneously, rather than treating institutional school mentoring $`M_{\mathrm{mentor}} \in [0, 1]`$ and extended family care $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}`$ as independent substitutes, effective adolescent mentoring is **state-conditioned on positive whānau stability** $`K_{\mathrm{wh\bar{a}nau}}^{+} = \max(0, K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}})`$:

$$M_{\mathrm{trust}}\left(K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}, M_{\mathrm{mentor}}\right) = M_{\mathrm{mentor}} \cdot \left(0.45 + 0.55 \min\left(1.0,\, \frac{K_{\mathrm{wh\bar{a}nau}}^{+}}{0.35}\right)\right)$$

The resulting Stage-2 adolescent stress-erosion and gain-banking operator $\Psi_{\mathrm{adolescent}}$ becomes:

$$\Psi_{\mathrm{adolescent}}\left(i_c, K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}, M_{\mathrm{mentor}}\right) = -\psi_{\mathrm{unemp}}\, \mathbb{I}\left(i_c < 0.01\right) \max\left(0,\, \left(1 - 0.55 K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}\right)\left(1 - 0.80 M_{\mathrm{trust}}\right)\right) + \kappa_{\mathrm{up}} M_{\mathrm{trust}}$$

Notice the mathematical consequence of evaluating this **comonotonically coupled operator** inside the Stage-2 CES bottleneck ($\varphi_2 = -0.95$) under the Tauchen Markov expectation $`\sum_{z^{\prime}} \pi_{z,k}(z^{\prime}\mid z)`$: when $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}} < 0`$, the amplification factor $`(1 - 0.55 K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}})`$ exceeds $1.0$, magnifying adolescent skill loss at the exact state coordinate where trust-gated school mentoring reach $M_{\mathrm{trust}}$ contracts to $0.45 M_{\mathrm{mentor}}$. This captures both the MBA's "batch-spoilage bottleneck" and the MPP's "non-fungibility of *whānau* vs. state care" via dimension-free sub-manifold conditioning, without adding a single extra grid axis.

---

### 4.2 Price-Manifold Conditioned Public Wraparound (`G_ece_eff`): The Kaiako Housing-Affordability Supply Deflator

In public administration, scaling nominal early-childhood expenditure `G_ece_stage1` and adolescent wraparound `G_ece_stage2` encounters a severe spatial labor-supply friction: when metropolitan house prices `Q_k` (`Params.Q_reg`) in Auckland (3.10) and Large regional cities (2.05) are inflated by speculative land hoarding, qualified early-childhood *Kaiako*, Montessori guides, and speech-language therapists are priced out of the high-deprivation suburbs where disadvantaged children live.

We replace the spatially invariant scalar `G_ece` with a **price-manifold conditioned operator** by deflating nominal public provision against the immutable `SS0` baseline reference price `Q_reg_base` (`Params.Q_reg_base`) with workforce supply elasticity $\nu_{\mathrm{kaiako}} = 0.35$:

$$G_{\mathrm{ece},s}^{\mathrm{eff}}\left(Q_k\right) = G_{\mathrm{ece},s} \cdot \left(\frac{Q_{\mathrm{reg,base},k}}{Q_k}\right)^{\nu_{\mathrm{kaiako}}}$$

This functional conditioning generates an endogenous **Cross-Cohort Dynamic Complementarity Wedge** between Aspect 3 (the Guvenen et al. property-to-enterprise tax shift) and Aspect 1 (First-2,000-Days skill formation): when land-tax rebalancing cools Auckland house prices by 7.5% in `SS1` and 10.5% in `SS2` (from 3.10 down to 2.87 and 2.77), every dollar of Crown ECE investment in Auckland automatically gains 2.8% to 4.0% in real *Kaiako* staffing and retention capacity.

---

### 4.3 Sub-Manifold Conditioned Housing User Costs (`p_H`): The 61-Point Asset-Grid LVR Hurdle & Comonotonic Eviction Tail

In Kiyotaki, Michaelides, and Nikolov (2024), the baseline regional ownership share $\xi_{\mathrm{reg},k} = \min\lbrace 1, (rr_k - rh_k)/\bar{\chi}\rbrace$ is a single regional scalar. If applied uniformly across all households in region *k*, an asset-poor family at `a = 0` and a wealthy household at `a = 15` face the exact same blended housing price `p_H`.

Because household net worth `a` in `[0, 25]` is already tracked on our 61-point cubic asset grid `a_grid_assets`, we apply **dimension-free sub-manifold conditioning** across both endogenous wealth `a` and the 5-point Tauchen income shock `z` inside `ReturnFn_SpatialHH.m`:

$$\xi_{\mathrm{hh}}\left(a, Q_k\right) = \xi_{\mathrm{reg},k} \cdot \left(0.25 + 0.75 \min\left(1.0,\, \frac{a}{0.20 Q_k}\right)\right)$$

$$p_H\left(a, z, Q_k, j\right) = \left(\xi_{\mathrm{hh}}\left(a, Q_k\right) rh_k + \left(1 - \xi_{\mathrm{hh}}\left(a, Q_k\right)\right) \frac{rr_k}{0.5 \bar{\chi}}\right)\left(1 + 0.12\, \mathbb{I}\left(a < 0.08 Q_k \land z < 0.85\right)\right)$$

Projecting `p_H` onto the `(a, z)` sub-manifold expands housing user costs from 1 scalar per region into `61 x 5 = 305` state-contingent values per region:
1. **The 20% LVR Deposit Gate (`a < 0.20 * Q_k`):** Young households without sufficient equity to clear the `0.20 * Q_k` deposit hurdle face the unblended rental user cost—explaining why the Age-20 Youth Capital Grant (`E`) and metropolitan house-price cooling (`Q_k` down) interact multiplicatively to lift young-adult homeownership in Auckland from 28.0% to 41.2%.
2. **Comonotonic Tail Coupling of Eviction & Transience Risk (`a < 0.08 * Q_k` and `z < 0.85`):** Renters with near-zero liquid buffers who simultaneously experience an adverse Tauchen earnings shock face a 12% effective housing cost and transience wedge (forced moves, emergency accommodation, and school disruption).
3. **Retiree Renter Vulnerability (`j >= Jr` and `a < 0.20 * Q_k`):** Elderly households who reach age 65 (`agej >= Jr`) without home equity remain exposed to rental user costs `rr_k` during retirement.

---

### 4.4 Skill-Manifold Conditioned Survival and Late-Life Labor Disutility (`sj_eff`): Capturing Actuarial Regressivity

Finally, to capture the MPP's warning regarding **differential mortality and physical wear-and-tear**, we condition late-life labor disutility and mortality hazard on the household's 7-point adult human-capital / occupational sub-manifold `h` in `[0.45, 0.65, 0.85, 1.00, 1.20, 1.45, 1.80]`:

$$
\psi_{\mathrm{wear}}\left(h, j\right) = 1.0 + 0.35\, \mathbb{I}\left(\mathrm{Age}_j \ge 65\right)\max\left(0,\, \frac{1.00 - h}{0.55}\right)
$$

$$
1 - s_j^{\mathrm{eff}}\left(h, j\right) = \min\left(0.99,\; \left(1 - s_j\right)\exp\left(0.18\left(1.00 - h\right)\right)\right)
$$

When a policy simulation raises the NZ Superannuation eligibility age (`Jr`) above 65, manual, rural, and lower-skilled workers (`h_1 = 0.45` and `h_2 = 0.65`, where Māori and Pasifika workers are disproportionately represented due to historical childhood stunting) face a 22% to 35% higher physical disutility of working past age 65 (`psi_wear > 1`) comonotonically coupled with a higher late-life mortality hazard `1 - sj_eff(h, j)`. Consequently, evaluating the Bellman expectation over the stationary distribution `mu_k(a, h, theta_c, z, j)` endogenously reproduces both the **38% to 52% disability/hardship benefit substitution leak** and the **regressive life-expectancy penalty** that make raising the pension age fiscally and socially inferior to front-loaded human-capital investment.

---

## 5. Companion Codebase & Suite Navigation

* **For the Full 8-PType Mixed-Horizon Bellman Specification, SMM Identification Matrix, & 22-File Codebase Manifest:** See **[Document 2: Technical Documentation & Model Specification Guide](Document%202.md)**.
* **For the Policy & Coalition Implications of "Thick" vs. "Thin" Operators (Perishability, Two-Term "Stop-Go" Pendulums, & The $4 \times 4$ Coalition Matrix):** See **[Document 3: Leaving Our Silos, Lifting All Boats](Document%203.md)** (*Part IV* and *Table 4.1*).
* **For the Strategic Monograph, Line-Item Answer Key, & Executive Brief:** See **[Document 1A](Document%201A.md)**, **[Document 1B](Document%201B.md)**, and **[Document 1C](Document%201C.md)**.
