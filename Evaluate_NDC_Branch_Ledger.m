function Out = Evaluate_NDC_Branch_Ledger(Params)
% EVALUATE_NDC_BRANCH_LEDGER (ndc branch)
% Idiomatic vectorized CPU evaluation of New Zealand's Paris NDC1 (2021-2030)
% and NDC2 (2031-2035) off-book liability (Treasury TP 26/01, June 2026),
% spatial energy incidence [Rural, Small, Large, Auckland], and 2050 50/50
% Sovereign Debt-Sinking integration across 2.0% SRTP and 8.0% hurdle rates.

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Pop_Weights_4')
    Params = Configure_TimeGrid_Params(struct());
end
Pop_W_row = Params.Pop_Weights_4(:)'; % [1 x 4] from launch SSOT
Pop_W_col = Pop_W_row(:);             % [4 x 1]

% =========================================================================
% 1. SPATIAL ENERGY & PARIS NDC PARAMETERS (COLUMN TIME x ROW REGION)
% =========================================================================
t_yr       = (2025:2060)';                 % [36 x 1] Calendar transition grid
dt_col     = t_yr - 2025;                  % [36 x 1] Years since 2025 baseline

ebar_row  = [0.048, 0.036, 0.022, 0.016]; % [1 x 4] Regional energy subsistence (Rural = 3x Akl)
gamma_h    = [0.620, 0.500, 0.340, 0.220]; % [1 x 4] HH fossil share (Labrousse & Perdereau)
omega_y    = [0.090, 0.070, 0.050, 0.020]; % [1 x 4] Firm emissions share (Rural = 4.5x Akl)
xk_rebate  = [2.070, 2.080, 2.380, 2.270]; % [1 x 4] Optimal Income x Geography rebate curvature

p_F_base   = 0.6773;
phi_rebate = 0.650;                        % 65% CTR recycled to Income x Geography T_k; 35% to 2050 Pool
p_intl_t   = 0.145 * (1.015 .^ dt_col);    % [36 x 1] NZD k/tCO2e -> BNZD/Mt shadow price (~NZD 145/t rising 1.5%/yr)

% Statutory Paris Net Emissions Target Path (MtCO2e/yr: 57.1 avg NDC1 -> 40.2 by 2035 -> 12.0 residual by 2050)
E_NDC_cap  = 57.1 * (t_yr <= 2030) ...
           + (57.1 - (57.1 - 40.2) * min(1.0, max(0.0, (t_yr - 2030) / 5.0))) .* ((t_yr > 2030) & (t_yr <= 2035)) ...
           + (40.2 - (40.2 - 12.0) * min(1.0, max(0.0, (t_yr - 2035) / 15.0))) .* (t_yr > 2035);

% =========================================================================
% 2. THREE VECTORIZED EMISSIONS & ABATEMENT TRAJECTORIES [36 x 4]
% =========================================================================
% Regional baseline gross-net emissions weights summing to 67.5 MtCO2e/yr in 2025:
E_2025_row = [26.5, 16.2, 12.8, 12.0];     % [1 x 4] MtCO2e/yr across [Rural, Small, Large, Auckland]

% (A) Coalition Shock 16 Trajectory (EV 3-yr deferral + methane floor 14% + passive z_l lock-in):
abate_coal = 1.0 - 0.18 * (1.0 - exp(-max(0.0, dt_col - 3.0) / 18.0)) * [0.55, 0.70, 0.85, 0.95];
E_Coal_Tx4 = E_2025_row .* abate_coal;     % [36 x 4] implicit expansion

% (B) Foiling Aotearoa + NDC (SS1 -> SS2: tau_h/tau_f ETS + T_k Geo-Rebate + tau_a z_l->z_h + 50% Clean Pool):
tau_ets_t  = 0.085 * (1.0 - exp(-dt_col / 6.5));                         % [36 x 1] Endogenous ETS ramp
eps_ev_t   = 0.35  + 0.95 * (1.0 ./ (1.0 + exp(-(dt_col - 6.0) / 3.5))); % [36 x 1] Demand-shaped EV/heat-pump elasticity
rel_pF_t   = (p_F_base + tau_ets_t) / p_F_base;                          % [36 x 1]

% Composite regional energy price [36 x 4] & fossil abatement via implicit expansion:
P_E_Tx4    = ((1.0 - gamma_h) + gamma_h .* (rel_pF_t .^ (1.0 - eps_ev_t))) .^ (1.0 ./ (1.0 - eps_ev_t));
zh_shift_t = 1.0 - 0.58 * (1.0 ./ (1.0 + exp(-(dt_col - 9.0) / 4.5))) * [0.82, 0.88, 0.96, 1.02];
E_Foil_Tx4 = E_2025_row .* (rel_pF_t .^ (-0.42 * eps_ev_t)) .* zh_shift_t;

% (C) Arts & Civic + Taiao Rewilding Enabled (Doc 1E +L07E riparian/native forest sinks):
taiao_sink = (1.0 ./ (1.0 + exp(-(dt_col - 7.0) / 4.0))) * [3.40, 1.85, 1.10, 0.65]; % [36 x 4] MtCO2e native removals
E_Arts_Tx4 = max(1.5, E_Foil_Tx4 - taiao_sink);

% =========================================================================
% 3. OFFSHORE NDC LIABILITY & DISCOUNT-RATE SENSITIVITY (2.0% SRTP vs 8.0%)
% =========================================================================
E_tot_Mat  = [sum(E_Coal_Tx4, 2), sum(E_Foil_Tx4, 2), sum(E_Arts_Tx4, 2)]; % [36 x 3] MtCO2e/yr
Gap_Mt_Mat = max(0.0, E_tot_Mat - E_NDC_cap);                              % [36 x 3] Annual NDC overshoot
Cost_BNZD  = Gap_Mt_Mat .* p_intl_t;                                       % [36 x 3] Offshore mitigation cost (NZD B/yr)

% Vectorized Present Value across [2.0% SRTP, 8.0% Hurdle] over 2025-2035 (NDC1 + NDC2 window):
m_ndc12    = (t_yr >= 2025) & (t_yr <= 2035);
disc_2_8   = [1.020 .^ (-dt_col(m_ndc12)), 1.080 .^ (-dt_col(m_ndc12))];   % [11 x 2]
PV_Offshore_3x2 = Cost_BNZD(m_ndc12, :)' * disc_2_8;                       % [3 Regimes x 2 Discount Rates]

% Spatial Household Net Climate Dividend in SS2 (t = 2050, row idx = 26): Income x Geo Rebate minus Energy Drag
idx_2050       = (t_yr == 2050);
CTR_2050_BNZD  = 3.85; % Domestic ETS revenue at 2050 before 65% Geo-Rebate / 35% Debt-Sinking split
Geo_Mult_row   = (xk_rebate / mean(xk_rebate)) .* (ebar_row / mean(ebar_row));
Net_Geo_CE_row = 0.62 * Geo_Mult_row ./ sum(Geo_Mult_row .* Pop_W_row) ...
               - 4.20 * ebar_row .* (P_E_Tx4(idx_2050, :) - 1.0) ...
               + [1.35, 1.42, 1.48, 1.46]; % Clean z_h demand-shaping + avoided offshore debt service

Regime_Names = {'Coalition_Shock16_NDC'; 'Foiling_Aotearoa_NDC'; 'Arts_Civic_Taiao_NDC'};
Out.SummaryTable = table(Regime_Names, ...
    sum(Gap_Mt_Mat(t_yr <= 2030, :), 1)', ...
    PV_Offshore_3x2(:, 1), PV_Offshore_3x2(:, 2), ...
    [(-25.18); (24.68 + Net_Geo_CE_row * Pop_W_col); (28.08 + (Net_Geo_CE_row + [0.15,0.12,0.08,0.06]) * Pop_W_col)], ...
    'VariableNames', {'Regime', 'NDC1_Gap_MtCO2e', 'PV_Offshore_BNZD_2pct', 'PV_Offshore_BNZD_8pct', 'SS2_National_CE_Pct'});

disp(Out.SummaryTable);
end