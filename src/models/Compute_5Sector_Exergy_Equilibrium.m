function Out = Compute_5Sector_Exergy_Equilibrium(Params, RegimeCode, Opts)
%% PURE 5-SECTOR SMALL OPEN ECONOMY, BIOPHYSICAL EXERGY & EXTERNAL BALANCE SOLVER
% File: src/models/Compute_5Sector_Exergy_Equilibrium.m
% Implements Document 4 Outer-Loop Macroeconomic Closure (100% CPU-vectorized, 0 time loops):
%   - Keen, Ayres & Standish (2019) Second-Law exergy activation (e_N = 0.88 vs e_F = 0.30, sigma_KL_X = 0.07)
%   - Labrousse & Perdereau (2026) 4-region dual-fuel substitution & fossil import bill
%   - 5-Sector output & labor allocation (S1 Primary, S2 Weightless z_h, S3 Market Non-Tradable & Grid,
%     S4A Capacitating vs Reactive Civic Co-Production, S4B Waters/Roads Capital, S5 Sovereign Defence)
%   - Balance of Payments, Real Exchange Rate (p_N_rel), & Schmitt-Grohe/Uribe debt-elastic spread r_t.

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end
if nargin < 2 || isempty(RegimeCode)
    RegimeCode = 'Phase2_Reform';
end
if nargin < 3 || isempty(Opts)
    Opts = struct();
end

SecSpec = Load_Sectoral_Exergy_Spec(Params.Profile_ID);
Ex      = SecSpec.Exergy;
NDC     = SecSpec.NDC;
SOE     = SecSpec.SOE;
MT      = SecSpec.MacroSector_Table;

% Column time vector [T x 1] (2026..2086, annual resolution for exact BoP/NFA integration):
Years   = (2026:1:2086)';
t_col   = Years - 2026;
tau_60  = t_col / 60.0;
T       = numel(Years);

% Resolve regime dials [ref_prog, clean_prog, civic_dial, def_dial, priv_dial, aust_drag]:
[ref_s, clean_s, civic_s, def_s, priv_s, aust_s] = resolve_regime_dials(RegimeCode, Params, Opts);

% Smooth transition S-curves [T x 1] (idiomatic column-vector masking/blending):
w_p1    = 1.0 - exp(-t_col / 11.0);
w_p2    = (t_col >= 20.0) .* (1.0 - exp(-max(0.0, t_col - 20.0) / 9.5));
w_ref   = ref_s   * (0.55 * w_p1 + 0.45 * w_p2);
w_clean = clean_s * (1.0 ./ (1.0 + exp(-(t_col - 7.5) / 4.2)));
w_def   = def_s   * (1.0 - exp(-t_col / 4.5));

% 1. Biophysical Exergy & Domestic Renewable Grid Capacity (K_N,t, M_olig,t, e_N vs e_F)
e_N     = Ex.e_N_elec;
e_F     = Ex.e_F_fossil;
K_N_t   = Ex.K_N_Grid_Init_BNZD * (1.0 + 1.15 * w_clean + 0.25 * w_ref - 0.18 * max(0, -priv_s) * w_p1);

m_grid0 = Ex.M_olig_grid_schedule(1);
m_grid2 = Ex.M_olig_grid_schedule(3);
M_olig_t = m_grid0 + w_ref * (m_grid2 - m_grid0) ...
         + max(0, -priv_s) * 0.24 * w_p1 - max(0, priv_s) * 0.12 * w_p1;

% Electrification shifts end-use fossil share down; Second-Law exergy ratio (e_N / e_F = 2.93x) lifts useful work!
fossil_mult_t  = max(0.14, 1.0 - 0.72 * w_clean + 0.12 * aust_s * w_p1);
elec_share_inc = 1.0 - fossil_mult_t;
exergy_gain_t  = 1.0 + 0.16 * ((e_N / e_F - 1.0) * elec_share_inc) ./ M_olig_t ...
               - 0.09 * aust_s * w_p1; % Curtailment drag under unexpanded/expensive grid

% Dry-year thermal peaking F_N,t shrinks as renewable overbuild & hydro-firming K_N,t scale:
dry_share_t    = Ex.DryYear_Thermal_Share_SS0 * (1.0 - w_clean) + Ex.DryYear_Thermal_Share_SS2 * w_clean;
Fossil_Bill_t  = Ex.Fossil_Import_Bill_SS0_BNZD * fossil_mult_t .* (1.0 + 0.45 * dry_share_t);

% 2. Paris NDC Net Emissions, Pine Saturation Cliff (Yr 25), & Clean-Green vs CBAM Terms-of-Trade
E_NDC_cap_t = 1.00 - 0.35 * (1.0 - exp(-t_col / 8.0)) - 0.43 * (t_col >= 10.0) .* (1.0 - exp(-max(0, t_col - 10.0) / 12.0));
kappa_pine  = max(0.0, 1.0 - 0.75 * w_clean - 0.25 * w_p2);
S_pine_t    = 0.18 * kappa_pine .* exp(-0.085 * max(0.0, t_col - 25.0)); % Saturates & decays post-2050!
S_native_t  = (0.14 * w_clean + 0.06 * max(0, civic_s) * w_p1) .* min(1.0, t_col / 22.0);
E_gross_t   = 1.00 * (0.35 + 0.65 * fossil_mult_t) .* (1.0 - 0.22 * w_clean);
E_net_t     = max(0.10, E_gross_t - S_pine_t - S_native_t);
ndc_gap_t   = max(0.0, E_net_t - E_NDC_cap_t);

% Regional [T x 4] terms-of-trade multiplier Pi_trade_Tx4 (Clean-Green lift vs CBAM penalty):
theta_ag_t   = min(1.0, w_clean);
Pi_trade_Tx4 = 1.0 + theta_ag_t * NDC.pi_green_reg - ndc_gap_t * NDC.chi_CBAM_reg;
Pi_trade_S1  = Pi_trade_Tx4 * [0.46; 0.30; 0.14; 0.10]; % Rural/Small weighted primary export index [T x 1]

NDC_Outflow_BNZD_t = 67.5 * ndc_gap_t .* (NDC.p_NDC_intl_BNZD_per_Mt * (1.012 .^ t_col));

% 3. Five-Sector Labor Reallocation (Internal Sector 4A Reactive -> Capacitating Release!) & Output [T x 6]
% Base 2026 paid workforce [1 x 6] in kFTE & value-added/spend [1 x 6] in BNZD:
L0_row = MT.Paid_kFTE(:)';          % [S1, S2, S3, S4A, S4B, S5]
Y0_row = MT.Annual_Spend_BNZD(:)';  % Consolidated non-transfer spend/output anchor

% Derive baseline reactive anti-bads FTE & spend directly from SubSector_Table (Justice/OT + Health_Reactive_Share):
ST        = SecSpec.SubSector_Table;
idx_hlth  = find(strcmp(ST.SubSector_ID, 'S4A1_Health_SocialCare'), 1);
idx_just  = find(strcmp(ST.SubSector_ID, 'S4A4_Justice_OT_Remed'),  1);
L_rem_0   = ST.Paid_Workforce_kFTE(idx_just) + SOE.Health_Reactive_Share_SS0 * ST.Paid_Workforce_kFTE(idx_hlth);
Y_rem_0   = ST.Annual_Spend_BNZD(idx_just)   + SOE.Health_Reactive_Share_SS0 * ST.Annual_Spend_BNZD(idx_hlth);

rem_compress_t  = max(0.22, 1.0 - 0.76 * w_ref + 0.28 * aust_s * tau_60); % Shrinks >75% by SS2 maturity!
L_S4A_rem_t     = L_rem_0 * rem_compress_t;                               % Reactive paid kFTE
L_released_t    = max(0.0, L_rem_0 - L_S4A_rem_t);                        % Internally freed nurses/social/public staff!

% Skill-supply expansion (retained thriving h_6..h_7 youth) vs. austerity brain drain:
skill_pool_mult = 1.0 + 0.24 * w_ref + 0.04 * max(0, civic_s) * w_p1 - 0.14 * aust_s * tau_60;

L_S5_t   = L0_row(6) * (1.0 + 0.95 * w_def);                              % ~15.8k -> ~30.8k FTE at 3% GDP Defence
def_pull = max(0.0, L_S5_t - L0_row(6));                                  % Technical labor pulled by Defence
unbuf_def_crowd = max(0.0, def_pull - 0.35 * L_released_t) .* (1.0 - 0.75 * w_ref);

L_S1_t   = L0_row(1) * (1.0 - 0.06 * tau_60 + 0.04 * w_ref);
L_S2_t   = L0_row(2) * (1.0 + 0.62 * w_ref + 0.08 * max(0, civic_s) * w_p1 - 0.22 * aust_s * tau_60) ...
         + 0.45 * L_released_t - 0.55 * unbuf_def_crowd;
L_S3_t   = L0_row(3) * (1.0 + 0.08 * tau_60 - 0.04 * w_ref);
L_S4A_cap_t = (L0_row(4) - L_rem_0) * (1.0 + 0.22 * w_ref - 0.12 * aust_s * w_p1) + 0.45 * L_released_t;
L_S4A_t  = L_S4A_cap_t + L_S4A_rem_t;
L_S4B_t  = L0_row(5) * (1.0 + 0.18 * w_ref + 0.10 * max(0, priv_s) * w_p1 - 0.10 * aust_s * w_p1) - 0.20 * unbuf_def_crowd;

Paid_kFTE_Tx6 = [L_S1_t, L_S2_t, L_S3_t, L_S4A_t, L_S4B_t, L_S5_t];

% Ostrom Polycentric Volunteer Co-Production (79k FTE base; boosted by Super-64 & Doc 1E, eroded by Super-70/cuts):
Vol_Civic_kFTE_t = SecSpec.Civic_Volunteer_kFTE * (1.0 + 0.18 * w_ref + 0.28 * civic_s * w_p1 - 0.24 * aust_s * tau_60);
Care_Home_kFTE_t = SOE.Household_Unpaid_Care_kFTE_SS0 * (1.0 + 0.11 * w_ref + 0.06 * w_clean - 0.15 * aust_s * tau_60);

% Sectoral Real Output / Value-Added [T x 6] in 2026 BNZD:
%   - S1 Primary: land-bound concave scale * Clean-Green Pi_trade_S1 * exergy_gain_t
%   - S2 Knowledge: high-skill z_h + Arrow learning-by-doing spillover (L_S2 / L0_2)^eta * exergy_gain_t
Y_S1_t  = Y0_row(1) * ((L_S1_t / L0_row(1)) .^ 0.68) .* Pi_trade_S1 .* exergy_gain_t .* (1.0 + 0.14 * w_ref);
Y_S2_t  = Y0_row(2) * ((L_S2_t / L0_row(2)) .^ (1.0 + SOE.Arrow_S2_Spillover_Eta)) .* skill_pool_mult .* exergy_gain_t;
Y_S3_t  = Y0_row(3) * (L_S3_t / L0_row(3)) .* exergy_gain_t .* (1.0 + 0.08 * w_ref - 0.06 * aust_s * tau_60);

% Standard SNA books S4A, S4B, S5 strictly at paid input + depreciation cost (blind to quality & anti-bads!):
wage_idx_t    = 1.0 + 0.14 * w_ref + 0.04 * (exergy_gain_t - 1.0) - 0.08 * aust_s * tau_60;
Y_S4A_cap_SNA = (Y0_row(4) - Y_rem_0) * (L_S4A_cap_t / (L0_row(4) - L_rem_0)) .* wage_idx_t;
Y_S4A_rem_SNA = Y_rem_0 * (L_S4A_rem_t / L_rem_0) .* wage_idx_t;
Y_S4A_SNA_t   = Y_S4A_cap_SNA + Y_S4A_rem_SNA;
Y_S4B_SNA_t   = Y0_row(5) * (L_S4B_t / L0_row(5)) .* wage_idx_t .* (1.0 + 0.15 * w_ref);
Y_S5_SNA_t    = Y0_row(6) * (1.0 + 1.50 * w_def) .* (1.0 + 0.12 * w_ref);

Y_Sector_SNA_Tx6 = [Y_S1_t, Y_S2_t, Y_S3_t, Y_S4A_SNA_t, Y_S4B_SNA_t, Y_S5_SNA_t];
% Scale total economy-wide SNA GDP to match canonical 430.0 BNZD 2026 anchor at t = 0:
sna_scale        = Params.GDP_2026_BNZD / sum(Y_Sector_SNA_Tx6(1, :));
Y_Sector_SNA_Tx6 = Y_Sector_SNA_Tx6 * sna_scale;
Y_SNA_t          = sum(Y_Sector_SNA_Tx6, 2);

% Ostrom Outcome-Adjusted S4A Capacitating Output (incorporating volunteer co-production):
ostrom_mult_t = (SOE.Ostrom_Omega_Paid + (1.0 - SOE.Ostrom_Omega_Paid) * ...
    ((Vol_Civic_kFTE_t / SecSpec.Civic_Volunteer_kFTE) .^ SOE.Ostrom_CoProd_Rho)) .^ (1.0 / SOE.Ostrom_CoProd_Rho);
Y_S4A_Cap_Outcome_t = (Y_S4A_cap_SNA * sna_scale) .* ostrom_mult_t .* (1.0 + 0.22 * w_ref + 0.12 * max(0, civic_s) * w_p1);
Y_S4A_Rem_Regret_t  = (Y_S4A_rem_SNA * sna_scale);

% 4. External Balance of Payments, Real Exchange Rate (p_N_rel), & Schmitt-Grohe/Uribe Spread r_t
Exports_BNZD_t     = 0.72 * Y_Sector_SNA_Tx6(:, 1) + 0.78 * Y_Sector_SNA_Tx6(:, 2);
Def_Imports_BNZD_t = SOE.Defence_Import_Share * Y_Sector_SNA_Tx6(:, 6);
NonEnergy_Imp_t    = 0.175 * Y_SNA_t;
Trade_Bal_BNZD_t   = Exports_BNZD_t - (Fossil_Bill_t + Def_Imports_BNZD_t + NDC_Outflow_BNZD_t + NonEnergy_Imp_t);

% Integrate NFA_t / Y_t ratio cleanly via cumulative trade-balance improvement relative to SS0 path:
tb_gdp_delta_t = (Trade_Bal_BNZD_t ./ Y_SNA_t) - (Trade_Bal_BNZD_t(1) / Y_SNA_t(1));
NFA_to_GDP_t   = max(-1.35, min(0.35, SOE.NFA_to_GDP_Init + cumtrapz(t_col, 0.38 * tb_gdp_delta_t) - 0.42 * aust_s * (tau_60 .^ 1.3)));

% Schmitt-Grohe & Uribe (2003) debt-elastic external borrowing rate r_t & Real Exchange Rate p_N_t:
r_dom_t   = SOE.r_dom_SS0 + SOE.psi_sov_spread * (exp(max(-0.45, SOE.NFA_to_GDP_Bar - NFA_to_GDP_t)) - 1.0) ...
          - 0.0060 * w_ref .* w_p2;
RER_pN_t  = 1.0 + 0.18 * tb_gdp_delta_t - 0.06 * (M_olig_t - m_grid0);

Out = struct();
Out.RegimeCode           = RegimeCode;
Out.Years                = Years;
Out.Macro_Sector_Names   = MT.Macro_Sector';
Out.Paid_kFTE_Tx6        = Paid_kFTE_Tx6;
Out.Vol_Civic_kFTE_t     = Vol_Civic_kFTE_t;
Out.Care_Home_kFTE_t     = Care_Home_kFTE_t;
Out.L_S4A_Released_kFTE  = L_released_t;
Out.Y_Sector_SNA_Tx6     = Y_Sector_SNA_Tx6;
Out.Y_SNA_BNZD_t         = Y_SNA_t;
Out.Y_S4A_Cap_Outcome_t  = Y_S4A_Cap_Outcome_t;
Out.Y_S4A_Rem_Regret_t   = Y_S4A_Rem_Regret_t;
Out.K_N_Grid_BNZD_t      = K_N_t;
Out.M_Olig_Grid_t        = M_olig_t;
Out.Exergy_Gain_Mult_t   = exergy_gain_t;
Out.Fossil_Import_BNZD_t = Fossil_Bill_t;
Out.Def_Imports_BNZD_t   = Def_Imports_BNZD_t;
Out.NDC_Outflow_BNZD_t   = NDC_Outflow_BNZD_t;
Out.Exports_BNZD_t       = Exports_BNZD_t;
Out.Trade_Balance_BNZD_t = Trade_Bal_BNZD_t;
Out.NFA_to_GDP_t         = NFA_to_GDP_t;
Out.r_Sovereign_t        = r_dom_t;
Out.RER_NonTradable_t    = RER_pN_t;
Out.Pi_Trade_Tx4         = Pi_trade_Tx4;
Out.E_Net_Norm_t         = E_net_t;
Out.E_NDC_Cap_Norm_t     = E_NDC_cap_t;
Out.Wage_Index_t         = wage_idx_t;
Out.SecSpec              = SecSpec;
end

function [ref_s, clean_s, civic_s, def_s, priv_s, aust_s] = resolve_regime_dials(RegimeCode, Params, Opts)
ref_s = 0.0; clean_s = 0.0; civic_s = 0.0; def_s = 0.0; priv_s = 0.0; aust_s = 0.0;
switch lower(strtrim(char(RegimeCode)))
    case {'ss0', 'ss0_ltfm', 'baseline_2023'}
        aust_s = 0.45;
    case {'domestic_15', 'coalition_2024', 'full_16_commitments'}
        aust_s = 1.00; civic_s = -0.50; priv_s = -0.35;
    case {'ss0_defence_3pct', 'unfunded_defence_3pct'}
        aust_s = 0.55; def_s = 1.00;
    case {'phase2_reform', 'ss2_reform', 'foiling_aotearoa'}
        ref_s = 1.00; clean_s = 1.00; priv_s = 0.50;
    case {'phase2_civic_doc1e', 'arts_enabled_ss2'}
        ref_s = 1.00; clean_s = 1.00; civic_s = 1.00; priv_s = 0.65;
    case {'phase2_defence_3pct', 'reform_plus_defence_3pct'}
        ref_s = 1.00; clean_s = 1.00; civic_s = 0.50; def_s = 1.00; priv_s = 0.50;
    otherwise
        % Custom dial overrides from Params or Opts:
        ref_s   = get_val(Opts, 'Ref_Scale',   get_val(Params, 'Reform_Intensity', 0.0));
        clean_s = get_val(Opts, 'Clean_Scale', get_val(Params, 'Clean_Exergy_Scale', ref_s));
        civic_s = get_val(Opts, 'Civic_Scale', get_val(Params, 'Civic_Commitment_Scale', 0.0));
        def_s   = get_val(Opts, 'Def_Scale',   get_val(Params, 'Defence_Posture_Dial', 0.0));
        priv_s  = get_val(Opts, 'Asset_Scale', get_val(Params, 'Asset_Stewardship_Dial', 0.0));
        aust_s  = get_val(Opts, 'Aust_Scale',  0.0);
end
end

function v = get_val(S, fn, defv)
if isstruct(S) && isfield(S, fn) && ~isempty(S.(fn))
    v = double(S.(fn));
else
    v = defv;
end
end
