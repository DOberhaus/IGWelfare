# Document 2A: Intergenerational Welfare Technical Specification — Part A: Micro-Foundations, Core Agent Problems, & Sectoral Operators
*A GPU-Accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations Framework (Sections 1–4: The Theoretical Lanes)*

**Author:** Michael Tiemann ([mdtiemann@gmail.com](mailto:mdtiemann@gmail.com))  
**Date:** November 2026 | **Code & Replication Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Strategy & Policy Answer Key), [Document 1C](Document%201C.md) (Executive Brief), [Document 2B](Document%202B.md) (Part B: Coupled General-Equilibrium Synthesis, Calibration, Transition Dynamics, & Supermodular Attribution, Sections 5–10), [Document 2T](Document%202T.md) ("Thick" vs. "Thin" Numbers Tutorial), and [Document 3](Document%203.md) (Leaving Our Silos, Lifting All Boats)*

*Disclaimer:* No people nor organizations mentioned herein have endorsed this work unless stated otherwise. This is the work of the author, and all errors and omissions are his alone.

---

### 1. Model Overview, Spatial Taxonomy, & Flexible Period Resolution ($\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$)

#### 1.1 Mixed-Horizon 8-PType GPU Architecture
We formulate a quantitative general-equilibrium Spatial Overlapping Generations (OLG) model of Aotearoa New Zealand implemented on the GPU via the VFI Toolkit mixed finite/infinite-horizon permanent-type engines (`ValueFnIter_MixHorz_PType` and `StationaryDist_MixHorz_PType`). The domestic economy is partitioned into $N_{\mathrm{reg}} = 4$ geographic tiers indexed by $k \in \lbrace 1, 2, 3, 4 \rbrace \equiv \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$, augmented by a 5th endogenous outside option $k = 5 \equiv \mathrm{Abroad}$ (representing skilled youth emigration to Australia and the wider OECD):
1. **`HH_Rural` & `Firm_Rural` (16.0% Base Household Share, 15.0% Firm Share):** Agricultural, primary-sector, and remote districts characterized by responsive land supply ($`Q_{\mathrm{Rural},\mathrm{SS0}} = 1.05`$), elevated mandatory fuel/transport subsistence costs ($`\bar{e}_{\mathrm{Rural}} = 0.048`$), high household fossil-fuel dependency ($`\gamma_{h,\mathrm{Rural}} = 0.62`$), and primary-sector exposure to the Paris Agreement NDC and EU/OECD CBAM border regimes—where baseline wholesale monopsony and retail duopoly markups [Ref 49] and passive pine-ETS arbitrage are overcome in `SS1`/`SS2` via `1.60x–2.16x` regional food-hub procurement multipliers [Ref 56], MPI 4-channel transformation [Ref 29], and $`z_\ell \to z_h`$ job upgrading.
2. **`HH_Small` & `Firm_Small` (24.0% Base Household Share, 23.0% Firm Share):** Secondary provincial towns (population under 100,000) with moderate housing user costs ($`Q_{\mathrm{Small},\mathrm{SS0}} = 1.40`$) and compressed wage ceilings (upgraded in `SS1`/`SS2` as local food-hub and Clean-Green value chains shift jobs from $`z_\ell`$ to $`z_h`$ and retire 82%–85% of the `SS1` geographic transfer top-up [Ref 29, 49, 56]).
3. **`HH_Large` & `Firm_Large` (25.9% Base Household Share, 26.9% Firm Share):** Major regional metropolitan centers (population over 100,000: Wellington, Christchurch, Hamilton, Tauranga, and Dunedin) featuring tertiary university hubs, constrained urban land ($Q_{\mathrm{Large},\mathrm{SS0}} = 2.05$), and high outward youth turnover.
4. **`HH_Auckland` & `Firm_Auckland` (34.1% Base Household Share, 35.1% Firm Share):** The primate metropolitan agglomeration featuring the highest entrepreneurial productivity ceiling ($`z_{h,\mathrm{Akl}} = 1.75`$), the steepest land supply inelasticity ($`Q_{\mathrm{Auckland},\mathrm{SS0}} = 3.10`$), and severe young-renter crowd-out.

```text
+-----------------------------------------------------------------------------------+
|               8-PTYPE MIXED-HORIZON GPU ARCHITECTURE (Names_i)                    |
|                                                                                   |
|  FINITE-HORIZON HOUSEHOLDS (Ages 20-99, J = round(80/dt), Case 1 MixHorz)         |
|   * HH_Rural (16.0%)  |  HH_Small (24.0%)  |  HH_Large (25.9%)  |  HH_Auckland    |
|   * 4D Compact Grid: (a, h, z, j) + 5th Outside Option: Emigration Abroad (k = 5) |
|         |                                                       ^                 |
|         v (Supplies Effective Labor H_k, Rent/Owner Demand, & Estates)            |
|  INFINITE-HORIZON ENTREPRENEURIAL FIRMS (Guvenen et al. 2023, InfHorz)            |
|   * Firm_Rural (15.0%) | Firm_Small (23.0%) | Firm_Large (26.9%) | Firm_Auckland  |
|   * 2D Grid: (a_f, z_f) with Collateral Constraint k <= lambda_col * a_f          |
+-----------------------------------------------------------------------------------+
```

#### 1.2 Exact $\Delta t$-Scaling Laws (`Configure_TimeGrid_Params.m`)
Let $\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$ denote the model period length in years (with $\Delta t = 3$ as the high-resolution developmental default and $\Delta t = 5$ as the fast benchmark). `Configure_TimeGrid_Params(Params, dt)` maps all annual flow rates, stocks, and lifecycle age indices so steady-state and transition magnitudes remain invariant across $\Delta t$:
* **Lifecycle Horizon & Age Brackets:** Adult biological ages span 20 to 99 (80 years), yielding $J = \mathrm{round}\left(80 / \Delta t\right)$ model periods (`J = 16` at $\Delta t = 5$; `J = 27` at $\Delta t = 3$). Retirement begins at age 65: $J_r = \mathrm{round}\left(45 / \Delta t\right) + 1$ (`Jr = 10` at $\Delta t = 5$; `Jr = 16` at $\Delta t = 3$).
* **Childhood Developmental Sub-Stages ($`\mathcal{J}_{c,1}`$ and $`\mathcal{J}_{c,2}`$):** Children are born when parents are age 26 ($`j_{\mathrm{birth}} = \mathrm{round}\left(6 / \Delta t\right) + 1`$).
  * **Stage 1 (First 2000 Days, Child Ages 0–5):** Spans $`n_{s1} = \mathrm{round}\left(6 / \Delta t\right)`$ parental periods $`\mathcal{J}_{c,1} = \lbrace j_{s1,\mathrm{start}}, \dots, j_{s1,\mathrm{end}} \rbrace`$ ($`j_p = 3`$ at $\Delta t = 5$; $`j_p \in \lbrace 3, 4 \rbrace`$ at $\Delta t = 3$).
  * **Stage 2 (Primary/Secondary Schooling & Adolescent Gate, Child Ages 6–17):** Spans $`n_{s2} = \mathrm{round}\left(12 / \Delta t\right)`$ parental periods $`\mathcal{J}_{c,2} = \lbrace j_{s2,\mathrm{start}}, \dots, j_{s2,\mathrm{end}} \rbrace`$ ($`j_p \in \lbrace 4, 5 \rbrace`$ at $\Delta t = 5$; $`j_p \in \lbrace 5, 6, 7, 8 \rbrace`$ at $\Delta t = 3$).
* **Compound Discounting & Flow Scaling ($\mathrm{dt\_scale} = \Delta t / 5$):**

$$
\beta_{hh}\left(\Delta t\right) = \beta_{\mathrm{ann}}^{\Delta t}, \qquad r\left(\Delta t\right) = \left(1 + r_{\mathrm{ann}}\right)^{\Delta t} - 1, \qquad s_j\left(\Delta t\right) = \left(s_{j,\mathrm{5yr}}\right)^{\Delta t / 5}
$$

$$
G_{\mathrm{ECE}}\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) G_{\mathrm{ECE,5yr}}, \qquad T_k\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) T_{k,\mathrm{5yr}}, \qquad \bar{e}_k\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) \bar{e}_{k,\mathrm{5yr}}
$$

while stock endowments (`YouthGrant` *E*) and proportional tax rates ($`\tau_l, \tau_c, \tau_k, \tau_b`$) are invariant to $\Delta t$, and the book-value wealth tax compounds as $`\left(1 - \tau_a\right)^{\Delta t}`$.

---

### 2. Infinite-Horizon Entrepreneurial Firms & Capital Reallocation (Lens 3)

Following Guvenen, Kambourov, Kuruscu, Ocampo, and Chen (2023), each region *k* contains a unit measure of infinite-horizon entrepreneurial firms (`Firm_Rural`, `Firm_Small`, `Firm_Large`, `Firm_Auckland`) with state vector $`\left(a_f, z_f\right) \in \mathcal{A}_f \times \mathcal{Z}_{f,k}`$, where $`a_f`$ is firm book equity and $`z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace`$ is idiosyncratic entrepreneurial productivity evolving via Markov matrix $`\Pi_{f,k}`$.

#### 2.1 Collateral-Constrained Profit Maximization, "Use-It-Or-Lose-It" Return, & NDC Carbon/Trade Channels

Firms rent capital `k_f <= lambda_col * a_f` (with collateral multiplier `lambda_col = 2.50`) and hire regional effective labor `l_f` at wage `w_reg` to produce output $`y_f = z_f \left(k_f^{\alpha_k} \ell_f^{1 - \alpha_k}\right)^{1 - \nu_{\mathrm{span}}}`$. In `ReturnFn_Firm.m` (11 arguments: `(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt)`), integrating out static factor and energy demands under the regional ETS carbon cost `tau_f_ets` (`omega_y_reg = [0.09, 0.07, 0.05, 0.02]`) and the Paris NDC "Clean-Green" vs. CBAM export terms-of-trade multiplier $`\Pi_{\mathrm{trade},k}`$ (`Pi_trade_reg`) yields marginal capital return `marg_prod_k` ($`\pi_k^{\star}`$) and gross-of-saving equity return `R_z`:

$$
R_k\left(z_f; \Delta t\right) = \left(1 - \tau_a\right)^{\Delta t} + \left(1 - \tau_k\right) \left\lbrack r\left(\Delta t\right) + \pi_{\mathrm{excess},k}\left(z_f, w_k, \tau_a\right) \right\rbrack
$$

$$
\pi_{\mathrm{excess},k}\left(z_f, w_k, \tau_a\right) =
\begin{cases}
\left(\pi_k^{\star}\left(z_f, w_k\right) - \left(r + \delta_k\right)\right) \lambda_{\mathrm{col}} & \mathrm{if\ } \pi_k^{\star}\left(z_f, w_k\right) > r + \delta_k \quad \left(\mathrm{active\ } z_{h,k}\right) \\
\rho_{\mathrm{pine/dairy},0} \left(1 - \frac{\tau_a}{0.015}\right) \Delta t & \mathrm{if\ } \pi_k^{\star}\left(z_f, w_k\right) \le r + \delta_k \quad \left(\mathrm{passive\ } z_{\ell,k}\right)
\end{cases}
$$

where $`\pi_k^{\star}\left(z_f, w_k\right) = \alpha_k \left(\left(1 - \alpha_k\right) / w_k\right)^{\left(1 - \alpha_k\right) / \alpha_k} \Pi_{\mathrm{trade},k} z_f`$. In `SS0` (`tau_a = 0`), passive rural land and exotic pine carbon-farming portfolios (`z_l`, the `else` branch in `ReturnFn_Firm.m`) capture an untaxed subsidy wedge `rho_pine_dairy > 0` while active exporters (`z_h`) suffer CBAM/NDC terms-of-trade drag (`Pi_trade_reg < 1`). In `SS1` and `SS2` (`tau_a = 0.015`), the passive pine/dairy subsidy vanishes, `(1 - tau_a)^dt` penalizes idle land banking, and credible domestic NDC compliance unlocks the Clean-Green export premium (`Pi_trade_reg > 1`) for active `z_h` enterprises.

#### 2.2 Firm Bellman Equation & Stationary Equity Distribution ($`\Gamma_k`$)

Each firm solves the infinite-horizon Bellman equation:

$$
V_{F,k}\left(a_f, z_f\right) = \max_{a_f^{\prime} \in \left\lbrack 0, R_k\left(z_f; \Delta t\right) a_f \right\rbrack} \left\lbrace \ln\left(R_k\left(z_f; \Delta t\right) a_f - a_f^{\prime} + \varepsilon_c\right) + \beta_{\mathrm{firm}}\left(\Delta t\right) \sum_{z_f^{\prime}} \Pi_{f,k}\left(z_f^{\prime} \vert z_f\right) V_{F,k}\left(a_f^{\prime}, z_f^{\prime}\right) \right\rbrace
$$

Replacing distortionary capital income taxation (`tau_k`) with a book-value wealth/land tax (`tau_a = 0.015`) penalizes low-productivity land-banking firms ($`z_{\ell,k}`$) while leaving high-productivity firms ($`z_{h,k}`$) with a higher marginal saving propensity, shifting the stationary equity distribution $`\Gamma_k\left(a_f, z_f\right)`$ toward $`z_{h,k}`$ and raising endogenous regional total factor productivity (reinforced in Rural and Small regions by breaking farm-gate wholesale monopsony and retail duopoly markups [Ref 49], rotating exotic pine carbon farms into MPI 4-channel high-value primary enterprises [Ref 29, 30], and anchoring `1.60x–2.16x` local food-hub procurement multipliers [Ref 56] that shift household labor draws from $`z_\ell`$ toward $`z_h`$, $`\Delta \mu_{z,\mathrm{SS2}} = [+0.040, +0.030, +0.015, +0.005]`$) $`Z_k\left(\Gamma_k\right)`$.

In `Firm_Rural` (`k = 1`) and `Firm_Small` (`k = 2`), baseline (`SS0`) asset pricing and operating returns are further shaped by two New Zealand climate-policy wedges (`LURNZ` land-use taxonomy; Hendy, Kerr, & Baisden, 2007 [Ref 30]): (i) **Unpriced Biogenic Dairy Emissions (`theta_ag = 0` in `SS0`) & Exotic Pine ETS Arbitrage (`kappa_pine_ets = 1` in `SS0`)**, which inflate passive rural land rents $`d_{\mathrm{land},1,t}`$ and Hirano and Toda (2025) land overvaluation ($`B_{\mathrm{land},1,t} > 0`$) while creating a post-Year-25 pine carbon-saturation cliff $`\mathcal{S}^{\mathrm{forest}}_t = \bar{\mathcal{S}}_0 \exp\left(-\delta_{\mathrm{sat}} \max\left(0, t - 25\right)\right)`$; and (ii) the **"Clean-Green" vs. CBAM Export Terms-of-Trade Multiplier** $`\Pi_{\mathrm{trade},k}`$:

$$
\Pi_{\mathrm{trade},k}\left(\Delta \mathcal{E}^{\mathrm{NDC}}_t , \theta_{\mathrm{ag}}\right) = 1 + \pi_{\mathrm{green},k} \theta_{\mathrm{ag}} - \chi_{\mathrm{CBAM},k} \max\left(0, \frac{\mathcal{E}^{\mathrm{dom}}_t - \overline{\mathcal{E}}^{\mathrm{NDC}}_t}{\overline{\mathcal{E}}^{\mathrm{NDC}}_t}\right)
$$

where `pi_green_reg = [0.045, 0.030, 0.010, 0.005]` is the verified low-emissions export premium and `chi_CBAM_reg = [0.080, 0.055, 0.020, 0.010]` is the Carbon Border Adjustment Mechanism (CBAM) tariff/market-access penalty when domestic emissions $`\mathcal{E}^{\mathrm{dom}}_t`$ exceed the Paris Agreement cap $`\overline{\mathcal{E}}^{\mathrm{NDC}}_t`$ (`E_NDC_schedule = [1.00, 0.65, 0.22]`). Phasing in circular biogenic pricing (`theta_ag: 0 -> 0.50 -> 1.00`), capping monoculture pine offsets (`kappa_pine_ets: 1.00 -> 0.25 -> 0.00`), and taxing passive land banking (`tau_a = 0.015`) eliminates the CBAM export penalty, unlocks the **+4.5%** Clean-Green export premium in `Rural`, and deflates speculative rural land bubbles ($`B_{\mathrm{land},1,t} \equiv 0`$).

* **Empirical Grounding of the Rural & Provincial `z_l -> z_h` Rotation (MPI 4-Channel Primary-Sector Transformation & Agglomeration Ceiling):** Crucially, the model does *not* assume that rural pastoral land converts into urban software startups or hyperscale datacenters. Consistent with the Ministry for Primary Industries' (MPI) primary-sector value-add assumptions (*Fit for a Better World: Background Analysis on Export Earnings in the Primary Sector*, MPI Technical Paper, 2020; *Situation and Outlook for Primary Industries [SOPI]*, Dec 2025 / June 2026 [Ref 29]) and DairyNZ / Beef + Lamb NZ farm-benchmark dispersions, the `z_l -> z_h` capital and talent rotation in `Rural` and `Small` operates through four empirically documented primary-sector channels, bounded by a conservative regional land-inelasticity and agglomeration ceiling (`Agglom_Map = [0.68, 0.80, 0.94, 1.00]` across `[Rural, Small, Large, Auckland]` in `Plot_ChildFiscal_SSankey.m` and a conservative `0.16` general-equilibrium wage pass-through exponent in `WelfareDecomposition_4Region.m`):
  1. *Intra-Sector Pastoral Productivity & Low-Emissions Operating Discipline (Closing the 80/20 ROA Gap):* In DairyNZ and Beef + Lamb NZ longitudinal benchmarks, the bottom 50% of farms operate as leveraged capital-gain vehicles (`z_l`, earning `1.5%–3.0%` operating ROA while relying on untaxed land appreciation), whereas top-quartile operators (`z_h`) on identical soil and climate achieve `7.0%–11.0%` operating ROA with `25%–35%` lower emissions intensity per kg of milksolids/meat via precision pasture management, high-genetic-merit herds, and low-emissions feed/inhibitor adoption.
  2. *High-Value Horticultural, Viticultural & Arable Land-Use Conversion:* As modeled in MPI's *Fit for a Better World* export assumptions and *SOPI 2025/2026* (where food and fibre exports reach `NZD 62B` in 2025/26 toward a `NZD 70B` 2030 target led by `+16%` to `+19%` horticultural growth), rotating flat and rolling land from low-margin commodity grazing (`z_l`, `~NZD 2,500/ha` gross revenue) into high-IP horticulture (`z_h`: Zespri SunGold/RubyRed kiwifruit, Envy/Rockit apples, viticulture, and specialty seed/arable crops at `NZD 60,000–120,000/ha`) multiplies value-added per hectare and skilled regional trade employment (`Node 18`: orchard managers, coolstore engineers, agronomists) without requiring urban agglomeration.
  3. *Permanent Indigenous Biodiversity Afforestation & Value-Added Wood Processing vs. Exotic Pine ETS Arbitrage:* Phasing out `kappa_pine_schedule = [1.00, 0.25, 0.00]` stops the hollowing-out of hill-country sheep and beef communities by unharvested *Pinus radiata* carbon farms (`z_l`)—which MPI and Budget 2026 (`NZD 109.2M` wilding conifer control) recognize as an ecological and post-2050 carbon-saturation liability—and redirects forestry capital into permanent native *totara/manuka/podocarp* sinks and engineered wood processing (`z_h`).
  4. *On-Farm & Regional Processing Electrification ("The Rural Powerhouse") & Iwi Collective Agribusiness:* Following Rewiring Aotearoa and MPI *Integrated Farm Planning* benchmarks, deploying the `~NZD 3.0B` Climate Emergency Response Fund (`-Inv 5` CERF Kick-Start) into on-farm solar/battery arrays, electric irrigation/vehicles, geothermal/electric dairy process-heat boilers, and long-horizon Iwi agribusiness collectives (e.g., *Tuaropaki*, *Wakatu*, *Miraka*) yields a fast `3.5-to-5-year` cash energy payback—pinning generational cash breakeven at `Year 20.0`—and secures tariff-free market access under EU/UK CBAM and high-value FTAs.

---

### 3. Finite-Horizon Household Problem Across Lenses 1, 2, and 3

#### 3.1 State Vector, Decision Grids, & Return Function Signature

In the GPU experience-asset specification (`NZ_4Region_Master.m` and `ReturnFn_SpatialHH.m`, alongside the compact 4D solver `ReturnFn_SpatialHH_Compact4D.m`), a household in region $k$ at age bracket $j \in \{1, \dots, J\}$ has endogenous state vector $a = (a_1, h, \theta_c)$, exogenous productivity state $z$, and chooses decision vector $d = (\ell, I_h, i_c)$:

* **`d_grid` (`n_d = [4, 3, 7]`, 84 composite decision states):**
  * $\ell \in \{0, 0.5, 0.8, 1.0\}$ ($n_{d_1} = 4$, extensive and intensive margin market labor supply).
  * $I_h \in \text{linspace}(0, 0.30, 3)^{\top}$ ($n_{d_2} = 3$, adult Ben-Porath on-the-job training time).
  * $i_c \in [0, 0.50]$ ($n_{d_3} = 7$, private early/school child skill investment, placed last in `n_d` as the experience-asset control). To prevent working families in the residual after-housing-costs (AHC) squeeze (**Node 2**) from being artificially rounded down to the $i_c = 0$ corner—which occurs under linear spacing where the first positive rung sits at $`0.0833 \approx 7,917\text{ NZD/yr}`$—`d_grid_ic` uses a convex power grid:
    $$d_{\text{grid,ic}} = 0.50 \times (\text{linspace}(0, 1, 7))^{1.8} = [0, 0.0203, 0.0706, 0.1460, 0.2456, 0.3649, 0.5000]^{\top}$$
    providing accessible interior rungs at $i_{c,2} = 0.0203$ ($`\approx 1,929\text{ NZD/yr}`$) and $i_{c,3} = 0.0706$ ($`\approx 6,707\text{ NZD/yr}`$) while matching the 7-tier resolution of $h$ and $z$.
* **`a_grid` (`n_a = [61, 7, 9]`):**
  * $a_1 \in [0, 25]$ ($n_{a_1} = 61$, household liquid net worth spaced cubically via $25 \times (\text{linspace}(0, 1, 61))^3$, concentrating 17 grid nodes below $a = 0.48 \approx \text{NZD } 45\text{k}$ to resolve regional housing thresholds $Q_k$ via continuous sub-grid linear cell interpolation).
  * $h \in \{0.45, 0.65, 0.85, 1.00, 1.20, 1.45, 1.80\}$ ($n_{a_2} = 7$, canonical adult human capital tiers $h_1 \dots h_7$: $h_1\text{–}h_2$ Struggling, $h_3\text{–}h_5$ Core, $h_6\text{–}h_7$ Thriving).
  * $\theta_c \in \text{linspace}(0.45, 1.85, 9)^{\top}$ ($n_{a_3} = 9$, continuous-interpolation child skill experience asset governed by `HumanCapital_Lifecycle_aprimeFn.m`, placed last in `n_a`).
* **`z_grid` (`n_z = 7`):** $z \in Z_{hh}$ ($n_z = 7$, 7-point Rouwenhorst idiosyncratic earnings shock (Kopecky & Suen, 2010) with $\rho_z = 0.85$ and region-specific drift $\mu_k$ and volatility $\sigma_k \in [0.11, 0.24]$, where $i_z \in \{1, 2\}$ denotes unemployment or severe low-wage distress).

#### 3.2 Budget Constraint, Stone-Geary ETS Energy Subsistence, Spatial Carbon Rebate, & Housing Tenure Cutoff

In Section 4 of `ReturnFn_SpatialHH.m` (50 arguments) and `ReturnFn_SpatialHH_Compact4D.m` (40 arguments), gross labor earnings are `gross_earn = w_reg * h * z * l * senescence_fac`, and flow variables scale by `scale_dt = dt / 5`. Under household ETS carbon pricing `tau_h_ets` with regional fossil-fuel expenditure shares `gamma_h_reg = [0.62, 0.50, 0.34, 0.22]` (`Rural` households face 2.8x the mandatory transport/fuel share of `Auckland`) and clean-electricity substitution elasticity `eps_h_energy`, the regional energy subsistence parameter `ebar_energy` and `Income x Geography` transfer `Transfer_Geo` (augmented by recycled Carbon Tax Revenue `phi_rebate * CTR_k`) are evaluated on the `(a, z)` sub-manifold as:

$$
\bar{e}_k^{\mathrm{eff}}\left(a, \tau^h_t\right) = \bar{e}_{k,0} \left\lbrack \left(1 - \gamma_{h,k}\right) + \gamma_{h,k} \left(\frac{p_F + \tau^h_t}{p_{F,0}}\right)^{1 - \epsilon_h} \right\rbrack^{\frac{1}{1 - \epsilon_h}} \left(1 + 0.15 \mathbb{I}_{\left\lbrace a < 0.12 Q_k\right\rbrace}\right) , \qquad T_{\mathrm{geo},k}\left(y_{\mathrm{lab}}\right) = \left(T_{k,0} + \phi_{\mathrm{rebate}} \mathrm{CTR}_{k,t}\right) \exp\left(-\xi_{k} y_{\mathrm{lab}}\right)
$$

where `a < 0.12 * Q_reg` captures fossil-fuel lock-in among credit-constrained households unable to finance heat-pump or EV retrofits, and `xk_geo = 2.35 - 0.65 * K_whanau` implements the Labrousse and Perdereau (2025) spatial phase-out curvature without adding arguments to the GPU signature. Net consumption budget `c_budget` and tax-deflated effective composite expenditure `c_eff` are:

$$
c_{\mathrm{budget}} = \left(\left(1 - \tau_a\right)^{\Delta t} + r\left(1 - \tau_k\right)\right) a - a^{\prime} + \mathbb{I}_{\left\lbrace j = 1\right\rbrace} E + \left(\frac{\Delta t}{5}\right) \left\lbrack \left(1 - \tau_l\right) y_{\mathrm{lab}} + T_{\mathrm{geo},k}\left(y_{\mathrm{lab}}\right) + p_{\mathrm{inc},j} - \left(1 - s_{\mathrm{sub}}\right) i_c - \bar{e}_k^{\mathrm{eff}}\left(a, \tau^h_t\right) - \mathrm{drag}_{\mathrm{sandwich}}\right\rbrack
$$

$$
c_{\mathrm{eff}} = \frac{1}{\Delta t / 5} \max\left(\left(\frac{\Delta t}{5}\right) \underline{c} , \frac{c_{\mathrm{budget}}}{1 + \tau_c}\right)
$$

Following Kiyotaki, Michaelides, and Nikolov (2024), households with net worth below the regional down-payment threshold ($`a < \xi_k Q_k`$, where $`\xi_k = 0.20`$) are **Renters** facing rental user cost $`r_{h,k}^{\mathrm{rent}} = \left(1 + \mu_{\mathrm{maint}} - G_k / R\right) Q_k`$, while households with $`a \ge \xi_k Q_k`$ are **Homeowners** facing user cost $`r_{h,k}^{\mathrm{own}} = \left(1 + \mu_{\mathrm{maint}} - G_k / R - \psi_{\mathrm{own}}\right) Q_k`$. Optimal non-durable consumption $`c_{nd} = \phi_{nd} e_{\mathrm{tot}}`$ and housing services $`c_H = \left(1 - \phi_{nd}\right) e_{\mathrm{tot}} / r_{h,k}`$ combine in the Cobb-Douglas bundle (while the geographic transfer schedule $`T_k`$ surges in `SS1` to `[0.038, 0.031, 0.025, 0.028]` with spatial carbon rebates to bridge acute hardship and then retires by $`\psi_{\mathrm{retire},T} = 85\%`$ in `SS2` to `[0.018, 0.013, 0.008, 0.004]` as regional $`z_\ell \to z_h`$ jobs take over, expanding the working-age PAYE cut from `-3.15 pp` [`18.85%`] to **`-3.75 pp` [`18.25%`]** [Ref 49, 56]): $`c_{\mathrm{comp}} = c_{nd}^{\phi_{nd}} c_H^{1 - \phi_{nd}}`$.

##### 3.2.1 Discretization of Early Childhood Investment (`d_grid_ic`)
In the baseline VFI configuration (`NZ_4Region_Master.m`), household liquid assets $a \in [0, 25]$ use cubic spacing (`25 * linspace(0, 1, 61).^3`), providing high resolution across low-wealth states ($a_1 \dots a_{17}$ span $0 \text{ to } 0.4741$, or $0 \text{ to } 45,040$ NZD at the $95,000$ NZD base scale). However, when the early childhood investment decision grid `d_grid_ic` ($n_{ic} = 7$ points on $[0, 0.50]$) is spaced linearly (`linspace(0, 0.50, 7)'`), the first positive investment rung sits at $ic_2 = 0.0833$ ($\approx 7,917\text{ NZD/yr}$ of private out-of-pocket expenditure).

For households in **Node 2 (Residual AHC Squeeze & Paper Support)** whose optimal private cash investment lies between $1,500 \text{ to } 5,000 \text{ NZD/yr}$ ($ic \in [0.015, 0.055]$), a linear decision grid offers no interior point between $0$ and $0.0833$, artificially rounding their policy choice down to the $ic = 0$ corner. Replacing linear spacing with a convex power grid of identical dimension ($n_{ic} = 7$, incurring zero additional GPU memory or Bellman iteration cost):

$$d_{\text{grid,ic}} = 0.50 \times \left(\text{linspace}(0, 1, 7)\right)^{1.8} = [0, 0.0203, 0.0706, 0.1460, 0.2456, 0.3649, 0.5000]^{\top}$$

introduces an accessible first positive rung at $ic_2 = 0.0203$ ($\approx 1,929\text{ NZD/yr}$) and second rung at $ic_3 = 0.0706$ ($\approx 6,707\text{ NZD/yr}$). This allows squeezed working families in Node 2 to register modest positive investments rather than pooling synthetically at $ic = 0$.

##### 3.2.2 Continuous Sub-Grid Cell Interpolation for Regional Housing Thresholds
Because regional housing price multipliers $Q_{\text{reg}}(k)$ span a threefold range (`Rural` $= 1.05$ to `Auckland` $= 3.10$), hard boolean asset cutoffs such as $a < \tau_1 Q_{\text{reg}}$ can fall near a grid node boundary in one region while sitting mid-interval in another. To prevent step-function discretization jumps when housing supply reforms ($Q_{\text{mult}}$) shift $Q_{\text{reg}}$, the 18-node Sankey aggregation evaluates continuous linear cell-fraction weights over the cubic asset grid $a_1 < a_2 < \dots < a_{61}$:

$$w_{\text{cell}}(a_i; \tau Q_{\text{reg}}) = \min\left(1, \max\left(0, \frac{\tau Q_{\text{reg}} - a_{i-1}}{a_i - a_{i-1}}\right)\right)$$

with $a_0 \equiv a_1 - (a_2 - a_1)$. This ensures that marginal changes in regional housing costs ($Q_{\text{reg}}$) and alloparental buffering ($K_{\text{whānau}}$) map smoothly into cohort population shares across all four regions.

---

#### 3.3 Adolescent Family Unemployment Stress, Unbanked Skill Fade-Out, and Bidirectional Montessori / Tuakana–Teina Mentoring ($M_{\mathrm{mentor}}$), and the importance of Whānau

In the two-stage Cunha–Heckman–Schennach skill technology (`HumanCapital_Lifecycle_aprimeFn.m`), childhood skill $`\theta_c`$ evolves across Stage 1 (ages 0–5, where $`\varphi_1 = 0.35 > 0`$) and Stage 2 (ages 6–17, where $`\varphi_2 = -0.95 < 0`$):

$$
\theta_{c,\mathrm{ret}} = \theta_c - \delta_{\theta,\mathrm{fade}}(1 - M_{\mathrm{mentor}})\max(0, \theta_c - \theta_{\mathrm{base}})
$$

$$
\Theta_s(\tilde{\theta}_c) = \left[ \gamma_{s,\mathrm{self}}\tilde{\theta}_c^{\varphi_s} + \gamma_{s,\mathrm{inv}}\left(i_c + G_{\mathrm{ECE},s}^{\mathrm{eff}} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_s} + \gamma_{s,\mathrm{par}}\bar{h}_p^{\varphi_s} \right]^{1/\varphi_s}, \quad s \in \lbrace 1, 2 \rbrace
$$

$$
\theta'_c = \begin{cases}
(1 - \omega_{s1})\theta_c + \omega_{s1}\Theta_1(\theta_c) & \text{if } j \in \mathcal{J}_{c,1} \\
(1 - \omega_{s2})\theta_{c,\mathrm{ret}} + \omega_{s2}\Theta_2(\theta_{c,\mathrm{ret}})\exp\left(\Psi_{J=5}(z_p, a_p, M_{\mathrm{mentor}})\right) & \text{if } j \in \mathcal{J}_{c,2} \\
\theta_c & \text{otherwise}
\end{cases}
$$

Because Stage 2 exhibits strong dynamic complementarity ($`\sigma_2 = \frac{1}{1 - \varphi_2} = 0.51 < 1`$) and unbanked gain depreciation $`\delta_{\theta,\mathrm{fade}} > 0`$ (Bailey et al., 2017; Rea & Burton, 2019; Lillard, 2005), early skill gains erode during middle childhood and early adolescence (`J = 5`, child ages 12–14) if children transition into passive factory-model schooling or if Stage-2 socio-emotional stability collapses. We formalize two countervailing mechanisms operating at this gate:

*1. Compounded Family Unemployment & Adolescent Psychosocial Morbidity Shock ($\psi_{\text{unemp}}, \lambda_{\text{psy}}$):* Following the empirical job-displacement and *Family Stress Model* literature (Conger et al., 1992; Coelli, 2011) alongside contemporary Aotearoa longitudinal evidence on early-adolescent peer victimization, algorithmic compulsion, sexual harm, and depressive escalation (*Growing Up in New Zealand* "Now We Are Twelve", Morton et al., 2023/2024; *Youth19*, Fleming et al., 2020; ACC ISSC actuarial valuations), disengagement at the ages 12–14 gate ($J = 5$, **Node 7**) is driven by two interacting channels: (i) household unemployment or severe AHC distress $z_p \in Z_{\text{distress}}$, and (ii) a cross-income psychosocial relational hazard $\lambda_{\text{psy}}(M_{\text{mentor}}, K_{\text{whānau}})$ that erodes executive function across all socioeconomic tiers while compounding multiplicatively when household buffers are depleted. In the adolescent net skill shift $\Psi_{J=5}$, active *Tuakana–Teina* / *Erdkinder* mentoring ($M_{\text{mentor}}$) and extended *whānau* connection ($K_{\text{whānau}}^{\text{eff}}(k)$) operate both to lower primary incidence $\lambda_{\text{psy}}$ (via critical-thinking cognitive inoculation and *KiVa*/*Planet Youth* peer-norm restructuring) and to insulate exposed adolescents against permanent detachment (retaining a conservative 38% clinical persistence residual for acute trauma requiring specialized CAMHS/ACC care):

$$\Psi_{J=5}(z_p, a_p, M_{\text{mentor}}, K_{\text{whānau}}) = -ψ_{\text{unemp}} \left[ I(z_p \in Z_{\text{distress}}) + λ_{\text{psy}}(M_{\text{mentor}}) \right] (1 - \zeta_{\text{buf}} M_{\text{mentor}})(1 - 0.55 K_{\text{whānau}}^{\text{eff}}(k)) + \kappa_{\text{up}} M_{\text{mentor}}$$

**2. Bidirectional Montessori / *Tuakana–Teina* Cross-Age Mentoring ($`M_{\mathrm{mentor}} \in [0, 1]`$):** While Stage 2 cognitive investment productivity is low ($`\gamma_{2,C,3} = 0.044`$), non-cognitive malleability remains more than twice as high ($`\gamma_{2,N,3} = 0.104`$, Cunha et al., 2010). Synthesizing indigenous *Tuakana–Teina* and *Ako* reciprocal whānau in *Kura Kaupapa Māori* and bilingual units, the Graeme Dingle Foundation's *Stars / Te Kāhui Whetū* and *Project K* peer-mentoring programs, CEFS *Food Youth Initiative (FYI)* and *GrowingChange* youth-led agricultural enterprises (92% non-recidivism [Ref 56]), high-agency vertical-*whānau* state schools, and Montessori's multi-age *Erdkinder* pedagogy (Lillard, 2005; Lillard & Else-Quest, 2006; Agostinelli, Saharkhiz, & Wiswall, 2024; Resnjanskij et al., 2024), structured cross-age mentoring where adolescents at `J = 5` mentor younger children at $J = 2\text{--}3$ generates a **two-way intra-generational spillover** without adding an endogenous state variable:
- *Downward Scaffolding Multiplier on Stage 1 ($`\kappa_{\mathrm{down}} > 0`$):* Near-peer tutoring and role-modeling by the *tuakana* adolescent cohort (with mean skill $`\bar{\theta}_{J=5}`$) augment the effective productivity of public early childhood and primary investments (including fresh *Ka Ora, Ka Ako* and NC State CEFS *Farm-to-ECE* nutrition: +24%–33% vegetable intake, $`d = 1.20`$, +26.6 pp parent nutrition crowding-in, and 46% take-home garden produce [Ref 56]) for younger *teina*:

$$
G_{\mathrm{ECE},1}^{\mathrm{eff}} = G_{\mathrm{ECE},1} \left(1 + \kappa_{\mathrm{down}} M_{\mathrm{mentor}} \bar{\theta}_{J=5}\right)
$$

- *Upward "Protégé Effect", Zero Fade-Out, & Stress Buffer on Stage 2 ($`\kappa_{\mathrm{up}} > 0`$):* Serving as a high-agency *tuakana* mentor builds adolescent executive function, self-regulation, and *mana*, eliminating unbanked Stage-1 skill fade-out ($`(1 - M_{\mathrm{mentor}})\delta_{\theta,\mathrm{fade}} \to 0`$) and directly buffering the family unemployment shock via the adolescent net shift $`\Psi_{J=5}`$:

See definition of $\Psi_{J=5}$ above.

- *Compact 4D Log-Skill Projection & Vectorized Sub-Grid Crowding Operator:* Defining the threshold vector $\tau_{\text{cuts}} = [0.025, 0.050, 0.080, 0.160]$ and the $[n_{a1} \times 4]$ sub-grid weight matrix $W_{\text{cell}}(a_i; \tau_{\text{cuts}} Q_k) = \min(1, \max(0, (Q_k \tau_{\text{cuts}} - a_{i-1}) / \Delta a_i))$, `Build_IntergenTransitionMatrix.m` and `Plot_ChildFates_SSankey.m` evaluate the two-tier Waring-buffered housing crowding vector $`\text{crowd}_{1D}(a_p; k) = W_{\text{cell},3} \psi_{\text{crowd,sev}} + (W_{\text{cell},4} - W_{\text{cell},3})(0.35 \psi_{\text{crowd,ahc}})`$ and induce the anchored log-skill transition mean across the 7-point adult human capital grid $h_{\text{child}} \in H$:

$$\mu_{\ln h}(h_p, i_c, z_p, a_p; k) = \rho_{hc} \ln(h_p^{\text{eff}}) + \gamma_{ic} \ln\left(\frac{i_c^{\text{eff}} + G_{\text{ECE},1}^{\text{eff}} + \bar{g}_{\text{ECE}}}{\bar{i}_c + G_{\text{ECE,base}} + \bar{g}_{\text{ECE}}}\right) - \text{crowd}_{1D}(a_p; k) + \Psi_{J=5}(z_p, i_c, M_{\text{mentor}}, K_{\text{whānau}}) + \alpha_{\text{grid}}$$

**3. The Endogenous Pension–*Whānau* Coupling Operator ($`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{eff}}(k)`$):** To make New Zealand Superannuation parameters ($`A_{\mathrm{super}}, p_{\mathrm{super}}`$) and regional housing user costs (*Q_k*) endogenously legible to the younger parenting generation without expanding the 4D GPU state vector $(a, h, z, j)$, `HumanCapital_Lifecycle_aprimeFn.m`, `ReturnFn_SpatialHH_Compact4D.m`, and `Build_IntergenTransitionMatrix.m` evaluate effective regional *whānau* capacity $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{eff}}(k) = K_{\mathrm{wh\bar{a}nau},0}(k) \cdot \Phi_{\mathrm{super}}(k)`$ from baseline proximity $`K_{\mathrm{wh\bar{a}nau},0} = [0.42, 0.38, 0.32, 0.28]`$ (`[Rural, Small, Large, Auckland]`) and the **Elder Time & Housing Stability Factor** $`\Phi_{\mathrm{super}}(k) \in [0.45, 1.25]`$:

$$
\Phi_{\mathrm{super}}(k) = \underbrace{\Phi_{\mathrm{time}}(A_{\mathrm{super}})}_{\text{Kuia / Aunty time availability}} \times \underbrace{\min\left(1.15, \max\left(0.50, \frac{p_{\mathrm{super}}}{0.18} \cdot \left(\frac{Q_{k,0}}{Q_k}\right)^{0.35}\right)\right)}_{\text{Ability of aunties / kaumātua to stay in their own homes}}
$$

- *Downstream Channels:* Where $`\Phi_{\mathrm{time}}(A_{\mathrm{super}}) = \exp(-\eta_{\mathrm{elder}}(A_{\mathrm{super}} - 65))`$ for $`A_{\mathrm{super}} \ge 65`$ ($`\eta_{\mathrm{elder}} = 0.09\text{ yr}^{-1}`$, yielding a -36.2% loss at Age 70: $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{eff}} \to [0.27, 0.24, 0.20, 0.18]`$) and $`\Phi_{\mathrm{time}}(A_{\mathrm{super}}) = 1 + 0.16 \tanh((65 - A_{\mathrm{super}})/1.80)`$ for $`A_{\mathrm{super}} < 65`$ (+8.1% boost at Age 64). In turn, $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{eff}}(k)`$ feeds directly into (i) Stage-1 informal *whānau* care and pooled *whānau* human capital $`\bar{h}_p`$, (ii) Stage-2 fade-out retention (`fade_residual`) and adolescent crisis buffering $`\Psi_{J=5}`$ (`psi_unemp_step`), and (iii) domestic youth retention (`whanau_stay_pull`) in $`\Pi_{\mathrm{mig}}`$.

**4. De Nardi (2004) Luxury Warm-Glow Bequest Motive:**

$$
u_{\mathrm{beq}}(a'; \tau_b) = b_1 \frac{\left(1 + \frac{(1 - \tau_b)a'}{b_2}\right)^{1 - \eta_c} - 1}{1 - \eta_c}
$$

**5. Relational Altruism, Social Cohesion Utility ($`u_{\mathrm{rel}}`$), & Transparency International CPI Calibration:** Captures the utility gain experienced by citizens and aging parents when the struggling launch share ($`\mathrm{Frac}_{\mathrm{struggling}}`$) is compressed and domestic social cohesion ($`S_t`$, `S_cohesion`) rises as educated youth remain in New Zealand:

$$
u_{\mathrm{rel}}(\mathrm{Frac}_{\mathrm{struggling}}, S_t) = \chi_{\mathrm{rel}} \left[ (0.285 - \mathrm{Frac}_{\mathrm{struggling}}) + 0.015 (S_t - 100) \right]
$$

- *Macro Social Cohesion Law of Motion:* Along the transition path, the macro **Social Cohesion Index** $S_t$ evolves endogenously as a linear functional of struggling-launch compression, youth brain-drain closure (`Nat_Emig_Abroad_Pct`), and moderated replacement-migration turnover (`Churn_Rate`):

$$
S_t = 100.0 + \zeta_{\mathrm{hardship}} (0.220 - \mathrm{Frac}_{\mathrm{struggling},t}) + \zeta_{\mathrm{ret}} (0.1093 - \mathrm{Emig}_{\mathrm{Nat},t}) - \zeta_{\mathrm{churn}} \max(0, \mathrm{Churn}_t - \overline{\mathrm{Churn}})
$$

- *Empirical CPI Anchor:* Empirically, $`S_t`$ is anchored to New Zealand's sovereign **Transparency International Corruption Perceptions Index (CPI)** ("Social Credit Rating"), which declined from **96/100** (2004 peak) and **88/100** (#1 equal globally in 2021) to a 30-year low of **81/100** (#4 equal in the 2025/2026 release, behind **#1 Denmark at 89, #2 Finland at 88, and #3 Singapore at 84**; Office of the Controller and Auditor-General, *New Zealand's Integrity Inheritance*, 2026; TI-NZ *National Integrity System Gap Analysis*, 2026). Compressing $`\mathrm{Frac}_{\mathrm{struggling}}`$ from 0.220 to 0.015 and cutting $`\mathrm{Emig}_{\mathrm{Nat}}`$ from 10.93% to 7.60% lifts $`S_t`$ from 100.0 (*SS0*) to 118.4 (*SS1*) and 126.0 (*SS2*).

---

### 4. 100% GPU-Vectorized Intergenerational & 4 × 5 Spatial Migration Operators (`Build_IntergenTransitionMatrix.m`)

To eliminate CPU nested loops, `Build_IntergenTransitionMatrix.m` executes all three intergenerational operators via 4D/5D GPU tensor broadcasting and `accumarray` projection, mapping the stationary distribution $`\mu_k\left(a, h, z, j\right)`$ and policy arrays `Policy` into the newborn adult distribution `jequaloneDist` ($`\mu_{1,k}\left(a_1, h_1, z_1\right)`$).

#### 4.1 Stage 1 Operator ($Q_h$): Two-Stage Childhood Skill & Montessori / Tuakana–Teina Gate

For fertile parental cohorts in Stage 1 ($`\mathcal{J}_{c,1}`$) and Stage 2 ($`\mathcal{J}_{c,2}`$), expected log pre-labor-market skill $`\ln(\hat{h}_{\mathrm{child}})`$ integrates Stage-1 private and public investment $`(i_{c,1}, G_{\mathrm{ECE},1})`$, housing crowding penalties, and the **Gate 3 (`J = 5`, Ages 12–14) Montessori / *Tuakana–Teina* & Graeme Dingle Foundation Mentoring Operator**:

$$
\ln(\hat{h}_{\mathrm{child}}) = \rho_{hc} \ln(h_p) + \gamma_{ic} \ln\left(1 + i_{c,\mathrm{eff}} + G_{\mathrm{ECE,eff}}\right) - \psi_{\mathrm{crowd}} \ln(Q_k) \mathbb{I}_{\mathrm{hard}} + \Delta_{\mathrm{Adol}}(z_p, M_{\mathrm{Tuakana}}) + \eta_h
$$

where the Adolescent Gate (`J = 5`) transition term $\Delta_{\mathrm{Adol}}(z_p, M_{\mathrm{Tuakana}})$ captures both family unemployment vulnerability (`iz == 1`) and the reciprocal *Tuakana–Teina* / *Ako* / Montessori *Erdkinder* mentoring dividend:

$$
\Delta_{\mathrm{Adol}}(z_p, M_{\mathrm{Tuakana}}) = \begin{cases}
-0.22 & \text{if } z_p = z_1 \text{ and unbuffered by mentoring } (M_{\mathrm{Tuakana}} = 0) \\
0.00 & \text{if standard schooling } (z_p > z_1, M_{\mathrm{Tuakana}} = 0) \\
+0.05 \text{ in } SS0 \ (+0.11 \text{ in } SS1, +0.14 \text{ in } SS2) & \text{if enrolled in Montessori / Tuakana--Teina mentoring } (M_{\mathrm{Tuakana}} = 1)
\end{cases}
$$

#### 4.2 Stage 2 Operator ($\mathbf{Q}_a$): The NZD 1.6T Property Estate Wave & Youth Capital Grant *E*
Dying retirees ($`j \ge J_r`$, weighted by mortality $`1 - s_j`$) in region *k* leave net-of-tax estates $`\left(1 - \tau_b\right) a^{\prime *}\left(a, h, z, j; k\right)`$. Adding the universal age-20 Youth Capital Grant *E* (`YouthGrant`) induces the initial young-adult asset distribution $`P_{a,k}\left(a_1\right)`$ over `a_grid`.

#### 4.3 Stage 3 Operator ($\Pi_{\mathrm{mig}}$): The 4 × 5 Domestic & International (`Abroad`) Gumbel Youth Sorting Matrix
Upon launching at `j = 1` (age 20) in origin region $k \in \lbrace 1, 2, 3, 4 \rbrace$ with state $`\left(a_1, h_1, z_1\right)`$, young adults evaluate the 4 domestic regions $m \in \lbrace 1, 2, 3, 4 \rbrace$ (incurring moving/entry cost $`\kappa_{k \to m}`$) against the **5th outside option: emigrating to `Abroad` (Australia/OECD)** with continuation value $`V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right)`$ and Gumbel scale parameter $`\varrho_{\mathrm{mig}} > 0`$:

$$
P_t\left(k \to m \middle| a_1, h_1, z_1\right) = \frac{\exp\left(V_{m,t}\left(\max\left(a_{\min}, a_1 - \kappa_{k \to m}\right), h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right)}{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right) + \sum_{r=1}^{4} \exp\left(V_{r,t}\left(\max\left(a_{\min}, a_1 - \kappa_{k \to r}\right), h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right)}
$$

$$
P_{\mathrm{emig},t}\left(k \to \mathrm{Abroad} \middle| a_1, h_1, z_1\right) = 1 - \sum_{m=1}^{4} P_t\left(k \to m \middle| a_1, h_1, z_1\right)
$$

**Calibration of the Gumbel Scale Parameter ($`\rho_G = 0.10`$ in Labrousse & Perdereau, 2025, Table 8 → $`\varrho_{\mathrm{mig}} = 0.180`$ in `Calibrate_NZ_Moments.m`):** In Table 8 (p. 54) of Labrousse and Perdereau (2025), their baseline Gumbel shock scale parameter is calibrated to $`\rho_G = 0.10`$ to match France's 5-year inter-regional stay rate of 85% (3% annual mobility). In our New Zealand model (`Calibrate_NZ_Moments.m`), $`\varrho_{\mathrm{mig}} = 0.180`$ is higher than France's 0.10 because under the 1973 Trans-Tasman Travel Arrangement (TTTA), New Zealand citizens have visa-free labor-market access to Australia and exhibit the highest cross-border skilled mobility rate in the OECD. Calibrating $`\varrho_{\mathrm{mig}}`$ in SMM (Table 6.1, Row 13) to match New Zealand's observed 10.93% national (and 19.29%–23.41% Auckland/Large-city) age 20–35 trans-Tasman/OECD departure rate uniquely pins down $`\varrho_{\mathrm{mig}} = 0.180`$.

---

---

## Navigation to Part B & Companion Tutorial
* **Continue to [Document 2B (Sections 5–10)](Document%202B.md):** *Part B — Coupled General-Equilibrium Synthesis, 6-Gate Fiscal Sankey, 2050 Debt-Sinking Protocol, Fertility & Super-Age U-Curve, SMM Calibration, Actuarial Continuation Valuation, 12-Layer Supermodular Attribution (7 Isolated Factors + 5 Synergy Wedges), Code Manifest, & Master Reference Library.*
* **Companion Tutorial [Document 2T](Document%202T.md):** *"Thick" vs. "Thin" Numbers in Quantitative Public Policy — Why Dimension-Free State-Contingent Conditioning Captures Comonotonic Tail Risks Without Expanding GPU Grid Dimensions.*
