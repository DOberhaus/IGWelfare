# Document 4: Phase II Architecture for IGWelfare — Closing the Biophysical, External, and Unpaid-Care Loops
## Integrating Spatial Exergy Activation, Small-Open-Economy Structural Transformation, and Unpaid Whānau Care Without Expanding GPU State Dimensions

*Author:* Michael Tiemann (mdtiemann@gmail.com)  
*Date:* November 2026 | *Code & Replication Repository:* [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Strategy & Policy Answer Key), [Document 1C](Document%201C.md) (Executive Brief), [Document 2A](Document%202A.md) & [Document 2B](Document%202B.md) (Technical Specification Guides), [Document 2T](Document%202T.md) ("Thick" vs. "Thin" Numbers Tutorial), and [Document 3](Document%203.md) (Leaving Our Silos, Lifting All Boats)*

**Disclaimer:** No people nor organizations mentioned herein have endorsed this work unless stated otherwise.  This is the work of the author, and all errors and omissions are his alone.

---

## 1. Case Statement: Why `IGWelfare` Needs Physical and External Closure

`IGWelfare` currently solves a 60-year multiphase transition path (`SS0 -> SS1 -> SS2`) across four domestic regions (`Rural`, `Small`, `Large`, `Auckland`) plus an endogenous emigration outside option (`Abroad`) in 1–2 minutes ([Document 2A](Document%202A.md), [Document 2B](Document%202B.md)). That computational headroom creates an opportunity to confront the three structural blind spots that still separate domestic social-investment models from full macroeconomic closure:

1. **The Small Open Economy (SOE) & Tradable Composition Constraint:** As established in our coalition synthesis ([Document 3](Document%203.md)), domestic human-capital, housing, and enterprise reforms only overcome the Long-Term Fiscal Model (LTFM) sinkhole [Ref 31, 32] when coupled across the human lifecycle rather than pursued in single-lane silos. Yet a central-bank or Treasury reviewer can still ask how a land- and emissions-constrained commodity exporter funds an 18.8-year Phase-1 (`SS1`) incubation window—or absorbs external trade and security shocks—without triggering a current account blowout, real exchange rate crowding-out, or widening sovereign risk spreads [Ref 4, 10, 40].
2. **The Biophysical Energy Illusion:** New Zealand routinely conflates an ~85%–88.5% renewable *electricity* grid with clean energy independence, ignoring that roughly 60%–68% of total consumer and primary energy consists of fossil fuels—predominantly imported liquid petroleum products (~NZD 19.5B/yr) alongside depleting Taranaki gas and thermal coal firming [Ref 39, 46]. Simultaneously, 2024–2026 industrial curtailments (pulp, paper, and timber mill closures during wholesale power spikes) demonstrate that energy is not a minor, smoothly substitutable 4% cost share [Ref 9]; it is a physical capacity constraint governed by domestic hydro-firming bottlenecks and vertically integrated gentailer market power [Ref 39, 49].
3. **The National-Accounts Care Blind Spot:** Leaving non-market household production and *whānau* caregiving bundled inside an undifferentiated "leisure" residual creates a classic Marilyn Waring accounting distortion [Ref 47]. Shifting early childhood care between *kuia*/family networks and marketized provision alters measured GDP even when total child-rearing inputs are unchanged, while obscuring how incompressible regional energy and housing bills squeeze the unpaid caregiving time required for First-2,000-Days and adolescent skill formation [Ref 11, 23, 26, 46, 47].

Rather than treating sectoral trade (Australia's *OLGA* [Ref 57]), biophysical energy transition (*Keen, Ayres, & Standish* [Ref 9] and *Labrousse & Perdereau* [Ref 23]), and unpaid care (*Waring* [Ref 47] and *Gronau* [Ref 28]) as competing model expansions, they form **two orthogonal, non-compounding upgrades**: an outer general-equilibrium production and external-balance block, paired with an intratemporal household time-and-subsistence block. Consistent with the dimension-free conditioning principles in [Document 2T](Document%202T.md), both upgrades leave the household endogenous state tensor untouched (`1.0x` state-space memory multiplier) and preserve sub-5-minute 60-year transition solves.

---

## 2. Economic Theory and Justification

### 2.1 Biophysical Exergy Activation vs. the Neoclassical KLE Fallacy (Keen & Ayres)

Standard CGE and OLG climate models append energy via a nested Capital-Labor-Energy (`KLE`) function governed by Solow's cost-share theorem. Because energy expenditure represents ~3%–5% of GDP, conventional models assign energy an output elasticity near $`\gamma \approx 0.04`$, implying that a 10% physical energy shortfall reduces aggregate output by a trivial ~0.4% to 0.7% [Ref 9].

Following Robert Ayres and Steve Keen (Keen, Ayres, & Standish, 2019; Ayres & Warr, 2009 [Ref 9]), physical capital and labor cannot perform work without energy throughput converted into useful physical work (**exergy**). Energy activates capital rather than substituting for it. Once regional plant and machinery are installed, short-run substitutability between capital-labor bundles and useful exergy approaches zero ($`\sigma_{KL,X} \to 0`$, consistent with Hassler, Krusell, & Olovsson, 2021 [Ref 10]). Distinguishing raw primary energy from useful exergy exposes the physical macroeconomic engine of electrification:

* **Imported Fossil Fuels ($`F`$):** Internal combustion vehicles and industrial fossil boilers suffer severe Second-Law conversion losses ($`e_F \in \lbrack 0.25, 0.35 \rbrack`$), bleeding foreign exchange out of the current account and compounding Paris Agreement NDC liabilities to deliver low useful mechanical or thermal work [Ref 9, 40, 46].
* **Domestic Renewable Electricity ($`N`$):** Electric drive motors, EVs, and industrial/residential heat pumps achieve $`e_N \ge 0.85`$ (or thermal coefficients of performance exceeding unity) [Ref 9, 46]. Electrification is therefore not an abatement drag on total factor productivity; it is a **three-fold step-change in end-use exergy efficiency**—provided domestic renewable generation and dry-year firming capacity ($`K_N`$) expand ahead of machine demand and are not throttled by wholesale gentailer oligopoly markups ($`M_{\mathrm{olig}}`$) [Ref 39, 49].

---

### 2.2 Spatial Dual-Fuel Heterogeneity and External Balance (Labrousse & Perdereau)

Labrousse and Perdereau (2026 [Ref 23]) demonstrate in a dynamic spatial heterogeneous-agent framework for France—whose ~93% low-carbon nuclear/hydro electricity baseload paired with imported rural and industrial fossil dependence closely mirrors New Zealand's hydro-plus-imported-oil structure [Ref 39]—that **geography dominates income** in determining fossil-fuel exposure. Total energy behaves as a household necessity, while fossil-fuel intensity varies sharply across urban-to-rural space due to commuting distances, building stock, and regional industrial composition [Ref 23, 50].

Embedding Labrousse and Perdereau's dual-fuel structure—sharpened by Keen and Ayres's exergy conversion weights $`(e_N, e_F)`$ [Ref 9]—directly into `IGWelfare`'s 4-region spine (`Rural`, `Small`, `Large`, `Auckland`) accomplishes two theoretical objectives simultaneously:

1. **Spatial Non-Homotheticity & Dual-Fuel Exergy Bundles:** Each region *k* carries an incompressible subsistence exergy requirement $`\bar{e}(k)`$ in household utility alongside region-specific CES weights $`\gamma_h(k)`$ and $`\gamma_y(k)`$ governing the split between domestic electricity ($`N`$) and imported fossil fuel ($`F`$, subject to ETS/carbon pricing $`\tau_F`$) [Ref 23, 39, 50]. On the regional production side, useful exergy $`X_{Y,k}`$ aggregates electric and fossil throughput as:

$$
X_{Y,k} = \left\lbrack \left(1 - \gamma_y(k)\right)\left(e_N N_{Y,k}\right)^{\frac{\epsilon_y - 1}{\epsilon_y}} + \gamma_y(k)\left(e_F F_{Y,k}\right)^{\frac{\epsilon_y - 1}{\epsilon_y}} \right\rbrack^{\frac{\epsilon_y}{\epsilon_y - 1}}
$$

2. **Macro External Closure:** Aggregate fossil fuel demand $`F_t = \sum_{k=1}^{4} \left(F_{h,k,t} + F_{Y,k,t}\right) + F_{N,t}`$—where $`F_{N,t}`$ captures marginal Huntly coal and gas thermal peaking required during dry hydro years [Ref 39]—must be imported from the Rest of the World at world price $`p_F^{\ast}`$ (plus shadow NDC carbon liability when domestic abatement falls short [Ref 40]). Financing $`p_F^{\ast} F_t`$ alongside Net Foreign Asset ($`\mathrm{NFA}_t`$) service requires tradable export earnings [Ref 10, 23].

---

### 2.3 Structural Transformation in a 3-Sector Small Open Economy

To capture how generational human-capital and enterprise investments resolve external balance-of-payments constraints without the dimensionality of a 19-sector ANZSIC input-output table, outer-loop production partitions into three structural sectors (adapting Australia's *OLGA* small-open-economy logic [Ref 57] to New Zealand's factor endowments):

1. **Land-Bound Primary Tradables:** Dairy, meat, and forestry exports subject to fixed agricultural land, diminishing marginal returns, farm-gate value-chain upgrading [Ref 49, 56], and agricultural/NDC emissions pricing wedges [Ref 40].
2. **Weightless / Knowledge Tradables:** High-skill intensive ($`z_h`$), unbound by land, exhibiting substantially higher value-added per joule of exergy and endogenous Arrow (1962) learning-by-doing spillovers [Ref 2, 7, 10].
3. **Domestic Non-Tradables & Grid Infrastructure:** Housing, local services, retail distribution, and domestic electricity generation ($`K_N`$), where domestic oligopoly markups reside [Ref 39, 49] and whose relative price $`p_t^N`$ pins down the **Real Exchange Rate (RER)**.

Closing the international capital account with a Schmitt-Grohé and Uribe (2003 [Ref 10]) debt-elastic sovereign risk premium,

$$
r_t = r_t^{\ast} + \psi \left(\exp\left(\frac{\mathrm{NFA}_t}{Y_t} - \bar{b}\right) - 1\right)
$$

links domestic social, fiscal, and energy transitions directly to external borrowing costs [Ref 1, 4, 10]. As First-2,000-Days wraparound and *Tuakana–Teina* mentoring shift future cohorts into thriving skill tiers ($`h_6\text{–}h_7`$) [Ref 11, 15, 18] and Guvenen et al. (2023) tax rebalancing rotates domestic talent from passive land speculation ($`z_{\ell}`$) into operating enterprises ($`z_h`$) [Ref 2, 3, 7], labor migrates endogenously into weightless exports while electrification permanently compresses structural fossil imports $`p_F^{\ast} F_t`$ [Ref 23, 46]—stabilizing the real exchange rate and compressing sovereign spreads $`r_t`$ over the 60-year horizon.

---

### 2.4 Paid vs. Unpaid Care and the Time-Energy Squeeze (Marilyn Waring)

In *Counting for Nothing / If Women Counted*, Marilyn Waring (1988 [Ref 47]) demonstrated that treating unpaid household and community work as zero-value leisure systematically biases public policy against caregivers and children. In `IGWelfare`, extended-*whānau* care capacity ($`K_{\mathrm{wh\bar{a}nau}}`$) already operates as an off-balance-sheet quality-assurance asset buffering adolescent skill formation ([Document 2A](Document%202A.md), [Document 2T](Document%202T.md), [Document 3](Document%203.md)). Formalizing Waring [Ref 47] via a Becker–Gronau household time trichotomy [Ref 28] splits the normalized period time endowment ($`T = 1`$) into **market labor ($`\ell_m`$)**, **unpaid household/*whānau* production ($`\ell_u`$)**, and **pure leisure ($`1 - \ell_m - \ell_u`$)** [Ref 21, 28, 50]:

* Market non-energy goods and services ($`c_m`$, notably domestic non-tradable services priced at $`p_t^N`$) combine with unpaid home production ($`c_u = A_u \ell_u^{\theta_u}`$) via a high-substitutability CES aggregator ($`\sigma_c > 1`$), while unpaid hours $`\ell_u`$ feed directly into intergenerational child skill transitions and regional $`K_{\mathrm{wh\bar{a}nau}}`$ capacity [Ref 11, 26, 47].
* Crucially, the spatial exergy block and the Waring care block interact directly inside household budgets: when `Rural` and low-income families face high incompressible fossil/electricity bills $`\bar{e}(k)`$ and elevated housing user costs $`r_{h,k}`$, parents and *kuia* are forced to supply extra survival market hours $`\ell_m`$, crowding out unpaid caregiving $`\ell_u`$ and triggering Stage-2 dynamic-complementarity losses ($`\varphi_2 = -0.95`$) in child development ([Document 2T](Document%202T.md) [Ref 11, 23, 46, 47]). Distributed household electrification (slashing $`\bar{e}(k)`$ bills via high-$`e_N`$ heat pumps, rooftop solar, and EVs [Ref 9, 46]) and universal public ECE relieve both budget poverty and time poverty simultaneously.

---

## 3. High-Level Implementation Plan for `IGWelfare`

The cardinal architectural rule in VFI Toolkit is strict separation between the **inner backward-induction household state space** ($`N_a \times N_z`$) and **outer general-equilibrium transition paths** (`TransPath_4Region_Master.m` Anderson acceleration and shooting solvers) ([Document 2A](Document%202A.md), [Document 2B](Document%202B.md)). Every module in Table 3.1 preserves **zero additional endogenous household state variables**.

#### Table 3.1: Zero-State-Expansion Implementation Matrix Across VFI Toolkit Modules

| Architectural Module | Target Code / Solver Location | Mathematical Formulation & Calibration Hook | Grid / Compute Impact |
| :--- | :--- | :--- | :--- |
| **Phase 1: Spatial Exergy & Electricity Sector (Keen + Labrousse Firm Side)** | Outer GE Firm & Grid Block (`Solve_Spatial_GE_Loop.m` + `TransPath_4Region_Master.m`) | Partition aggregate capital into regional productive capital ($`K_{Y,k,t}`$) and renewable grid/firming capacity ($`K_{N,t}`$). Activate regional $`(K_{Y,k}, L_{Y,k})`$ with exergy bundle $`X_{Y,k}(e_N N_{Y,k}, e_F F_{Y,k})`$ under smooth near-Leontief complementarity $`\sigma_{KL,X} \in \lbrack 0.05, 0.10 \rbrack`$ (avoiding non-differentiable kinks in Anderson acceleration) [Ref 9, 10, 23]. Include dry-year fossil firming $`F_{N,t}`$ and gentailer markup $`M_{\mathrm{olig}}`$ on $`p_{N,t}`$. Calibrate to MBIE & EECA EEUD regional fuel shares [Ref 39]. | **1.0x** VFI states & `d`-grid; +1–2 outer GE price paths ($`p_{N,t}, K_{N,t}`$). |
| **Phase 2: 3-Sector SOE, RER & Debt-Elastic $`r_t`$ Closure** | Outer GE Sectoral & BoP Clearing (`TransPath_4Region_Master.m`) | Partition firm FOCs across Primary Tradables (land-fixed + NDC carbon wedge [Ref 40]), Knowledge Tradables ($`z_h`$-intensive + Arrow learning spillover [Ref 10]), and Non-Tradables ($`p_t^N`$). Clear external balance $`\mathrm{Exports}_t - p_F^{\ast} F_t = \Delta \mathrm{NFA}_t - r_t \mathrm{NFA}_{t-1}`$ via the real exchange rate and update sovereign risk spread $`r_t(\mathrm{NFA}_t / Y_t)`$ [Ref 10, 23, 57]. | **1.0x** VFI states; +20%–40% outer Anderson/shooting iterations. |
| **Phase 3: Analytical Dual-Fuel Household Demand** | Intra-period expenditure block inside `ReturnFn_SpatialHH.m` & `ReturnFn_SpatialHH_Compact4D.m` | Replace scalar regional subsistence with dual-fuel Stone-Geary incompressible exergy $`\bar{e}(k)`$ and CES utility over $`(e_N N_h, e_F F_h)`$ [Ref 9, 23, 46]. Solve exact household expenditure shares on $`(c_m, N_h, F_h)`$ analytically in closed form given period composite expenditure $`e_{\mathrm{tot}}`$ and regional prices $`(p_t^N, p_{N,t}, p_F^{\ast} + \tau_{F,t})`$. Calibrate to Stats NZ HES by region [Ref 50]. | **1.0x** VFI states; **1.0x** `d`-grid (~1.1x arithmetic ops in `ReturnFn`). |
| **Phase 4: Waring Paid vs. Unpaid Care Allocation** | Intra-period FOC in `ReturnFn_SpatialHH_Compact4D.m` + `K_whanau` & `WelfareDecomposition_4Region.m` | Split household time into $`(\ell_m, \ell_u, 1 - \ell_m - \ell_u)`$ [Ref 28, 47]. Solve the intratemporal marginal rate of substitution between $`\ell_m`$ (at net regional skill wage) and $`\ell_u`$ (substituting against non-tradable $`p_t^N`$ services) analytically inside `ReturnFn` (or via a compact `d`-grid), passing aggregate regional $`L_{u,k,t}`$ to update $`K_{\mathrm{wh\bar{a}nau}}(k, t)`$ and `HumanCapital_Lifecycle_aprimeFn.m`. Calibrate to Stats NZ Time Use Survey [Ref 47, 50]. | **1.0x** VFI states; ~1.5x–2.5x on `ReturnFn` evaluation; total 60-yr solve stays **< 4–5 mins**. |

### Sequencing & Verification Guardrails

1. **Outer-Loop First (Phases 1 & 2):** Implement the 3-sector SOE and Keen–Labrousse firm/grid block while keeping `ReturnFn_SpatialHH_Compact4D.m` unchanged. Verify steady-state (`SS0`, `SS1`, `SS2`) and 60-year Anderson/shooting `TransPath_4Region_Master.m` convergence across all three continuous-integration test configurations (MATLAB with GPU, MATLAB without GPU, and GNU Octave without GPU) before modifying household preferences.
2. **Closed-Form Household Enrichment & Waring Satellite Account Second (Phases 3 & 4):** Layer the analytical Stone-Geary dual-fuel split first, verify regional distributional incidence from `Rural` through `Auckland` in `Calibrate_NZ_Moments.m`, and then activate the Waring $`(\ell_m, \ell_u)`$ split alongside a formal **Household Production Satellite Account** in `WelfareDecomposition_4Region.m` and Lane B of `Plot_ChildFiscal_SSankey.m` (`LaneB_WhanauTime_kNZD`) [Ref 47, 50]—reporting conventional market GDP alongside Waring-inclusive output and exact Consumption-Equivalent (`CE%`) welfare.

---

## 4. Statement of Unique Contribution to the Economic Literature

Existing quantitative macroeconomic policy models partition human capability, biophysical energy, and small-open-economy dynamics into three disconnected literatures:

* **Multi-sector OLG trade and fiscal models** (such as Australia's *OLGA* or *OG-Core* [Ref 57]) capture small-open-economy capital flows, sovereign debt, and industry taxation, but treat early human capital as exogenous or adult-only, omit unpaid household care, and represent energy via high-elasticity neoclassical cost shares that cannot generate physical capacity bottlenecks [Ref 9].
* **Spatial heterogeneous-agent climate and resource models** (Hassler, Krusell, & Olovsson, 2021 [Ref 10]; Labrousse & Perdereau, 2026 [Ref 23]) capture geographic fossil-fuel lock-in and short-run putty-clay energy complementarities, but operate in infinitely lived Bewley–Huggett–Aiyagari environments without lifecycle skill formation, intergenerational *whānau* transfers, or endogenous structural transformation across tradable export sectors.
* **Lifecycle skill-formation and home-production OLG models** (Cunha, Heckman, & Schennach, 2010 [Ref 11]; Lee & Seshadri, 2019 [Ref 12]; Gronau, 1977 [Ref 28]; Waring, 1988 [Ref 47]) formalize early childhood dynamic complementarities and non-market caregiving time, but model the macroeconomy as a closed, single-good aggregate detached from balance-of-payments constraints, real exchange rates, and physical exergy conversion.

By integrating these three mechanisms within a computationally tractable 4-region + `Abroad`, 60-year transition framework, `IGWelfare` establishes a novel result in computational public economics: **it demonstrates quantitatively how biophysical exergy transition and intergenerational human-capital formation operate as joint macroeconomic complements in a small open economy**. Formally, the model links micro-level household time and subsistence-energy constraints—where distributed electrification [Ref 9, 46] and universal care infrastructure [Ref 11, 37] jointly relieve the rural and low-income squeeze on unpaid *whānau* caregiving time [Ref 23, 47]—to macro-level external solvency, showing how shifting from low-exergy imported fossil fuels to high-exergy domestic renewables, coupled with cohort skill-upgrading out of land-bound primary commodities into weightless tradables, endogenously stabilizes the current account, real exchange rate, and sovereign borrowing spread over a multi-decade generational transition [Ref 10, 23, 31, 40].

---

## 5. Companion Codebase & Suite Navigation

* **For the Full 8-PType Mixed-Horizon Bellman Specification, SMM Identification Matrix, 22-File Codebase Manifest, & Master Reference Library (`[Ref 1]`–`[Ref 60]`):** See **[Document 2A](Document%202A.md)** and **[Document 2B](Document%202B.md) (*Technical Documentation & Model Specification Guides*)**.
* **For the State-Contingent Operator Methodology Preserving Compact GPU Grids:** See **[Document 2T: "Thick" vs. "Thin" Numbers in Quantitative Public Policy](Document%202T.md)**.
* **For the 2D Coalition Complementarity Matrix, LTFM Sinkhole Trajectories, & Public Synthesis:** See **[Document 3: Leaving Our Silos, Lifting All Boats](Document%203.md)**.
* **For the Strategic Monograph, Line-Item Answer Key, & Executive Brief:** See **[Document 1A](Document%201A.md)**, **[Document 1B](Document%201B.md)**, and **[Document 1C](Document%201C.md)**.