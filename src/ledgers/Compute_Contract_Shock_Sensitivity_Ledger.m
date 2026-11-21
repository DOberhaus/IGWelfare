function Out = Compute_Contract_Shock_Sensitivity_Ledger(Params, Opts)
%% PURE COMONOTONIC SOE SHOCK-RANGE & ASSEMBLY CONTRACT BREAKING-POINT ENGINE (SUB-WAVE 7C)
% File: src/ledgers/Compute_Contract_Shock_Sensitivity_Ledger.m
% Exploits Small-Open-Economy (SOE) comonotonicity across New Zealand's 5 shock channels:
%   1) Global Demand / ToT Slumps co-move NEGATIVELY with global real interest rates r*
%      (monetary easing cushion) and trans-Tasman S4A poaching pressure (Australia slows too),
%      while floating NZD Real Exchange Rate (RER) depreciation cushions Sector 2 weightless exports!
%   2) Global Stagflation / Oil-Exergy Spikes co-move POSITIVELY with world interest rates r*,
%      but simultaneously lift global nominal protein/commodity prices (partial Sector 1 agflation hedge).
%   3) Joint Polycrisis evaluates the Cholesky mahalanobis-1.0x elliptical shock contour
%      (rather than an impossible unhedged sum of six independent 1-sigma tails!).

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end
if nargin < 2 || isempty(Opts), Opts = struct(); end
verbose_flag = isfield(Opts, 'Verbose') && logical(Opts.Verbose);

Compact = Load_Assembly_Compact(Params.Profile_ID);
CT      = Compact.Contract_Table;
nK      = Compact.N_Contracts; % 15 contracts

a_min         = double(CT.Assumed_Min(:));
a_max         = double(CT.Assumed_Max(:));
base_deliv_15 = double(CT.Deliv_Unified_Compact(:));

% Continuous shock amplitude grid [N_lam x 1] in [0.00, 2.50]:
Lambda_Grid = linspace(0.0, 2.50, 26)';
N_lam       = numel(Lambda_Grid);
lam_row     = Lambda_Grid(:)'; % [1 x N_lam]

% Comonotonic SOE Shock Correlation Matrix Sigma_SOE across [hc, staff, exergy, tot, rate]:
%   - Negative comovement: (tot, rate) = -0.45 (world rate cuts in global demand slump),
%                          (tot, staff)= -0.30 (slower trans-Tasman poaching in global slump)
%   - Positive comovement: (exergy, rate) = +0.50 (stagflationary oil/rate co-movement),
%                          (hc, staff)    = +0.40 (educator turnover slows cohort hc realization)
Sigma_SOE = [ ...
     1.00,  0.40,  0.15,  0.10,  0.05; ... % 1. Cohort hc lag
     0.40,  1.00,  0.20, -0.30,  0.10; ... % 2. S4A Kaiako/nurse poaching
     0.15,  0.20,  1.00, -0.25,  0.50; ... % 3. Dry-hydro + world oil exergy shock
     0.10, -0.30, -0.25,  1.00, -0.45; ... % 4. Export ToT / CBAM demand slump
     0.05,  0.10,  0.50, -0.45,  1.00];    % 5. World real interest rate shock (+180 bps unit)

% Six Structural & Comonotonic Eigen-Scenarios:
% Each row specifies raw shock loadings [s_hc, s_staff, s_exergy, s_tot, s_rate] AND
% endogenous comonotonic offsets [rer_s2_cushion, rate_ease_offset, agflation_tot_hedge, poach_cool_offset]:
% Notice how C3 (Stagflation) carries partial agflation hedge, C4 (ToT Slump) carries monetary-easing + RER S2 cushion,
% and C6 (Joint Elliptical Polycrisis) is normalized to unit Mahalanobis norm (s' * inv(Sigma_SOE) * s == 1.0)!
% Normalize joint polycrisis basket w so portfolio shock volatility sqrt(w * Sigma_SOE * w') == 1.0 (1-sigma joint tail):
raw_poly = [0.38, 0.42, 0.52, 0.36, 0.48];
port_sd  = sqrt(raw_poly * Sigma_SOE * raw_poly');
p_unit   = raw_poly / port_sd;

Families = { ...
    'C1_Cohort_Skill_Pipeline', '1. Cohort Skill & Mentoring Lag (Comonotonic S4A)', [1.00, 0.35, 0.00, 0.00, 0.00], [0.00, 0.00, 0.00, 0.00]; ...
    'C2_S4A_Staffing_Poach',    '2. Sector 4A Kaiako & Nurse Poaching Wave',         [0.30, 1.00, 0.00, 0.00, 0.00], [0.00, 0.00, 0.00, 0.00]; ...
    'C3_Stagflation_Exergy',    '3. Stagflation: Dry-Hydro/Oil + Rate Co-Spike',     [0.00, 0.15, 1.00, 0.00, 0.45], [0.22, 0.00, 0.25, 0.00]; ...
    'C4_Global_Slump_ToT',      '4. Global Slump: ToT/CBAM Hit (w/ RER & r* Relief)',[0.00, 0.00, 0.00, 1.00, 0.00], [0.38, 0.42, 0.00, 0.30]; ...
    'C5_Sovereign_Rate_Spike',  '5. Sovereign Credit / Term-Premium Spike (+180bp)', [0.00, 0.00, 0.20, 0.00, 1.00], [0.18, 0.00, 0.00, 0.00]; ...
    'C6_Comonotonic_Polycrisis','6. Comonotonic Elliptical Polycrisis (||s||_Sigma=1)', p_unit,                      [0.30, 0.15, 0.15, 0.15]};
nF = size(Families, 1);

% Anchor exact 5-Sector SOE derivatives at lambda = 0 and lambda = 1 across the channels (only 13 SOE calls total -> 10x faster!):
Eq0 = Compute_5Sector_Exergy_Equilibrium(Params, 'Phase2_Civic_Doc1E', struct('Enable_Contingent_Stabilizers', true));

Deliv_Rigid      = zeros(nK, N_lam, nF);
Deliv_Cont       = zeros(nK, N_lam, nF);
Pass_Rigid       = false(nK, N_lam, nF);
Pass_Cont        = false(nK, N_lam, nF);
Surv_Rigid_LamxF = zeros(N_lam, nF);
Surv_Cont_LamxF  = zeros(N_lam, nF);

for f = 1:nF
    s_vec = Families{f, 3};
    c_vec = Families{f, 4};
    shk_1 = vec_to_shock_struct(s_vec, 1.0);

    Eq1_R = Compute_5Sector_Exergy_Equilibrium(Params, 'Phase2_Civic_Doc1E', ...
        struct('ExogShocks', shk_1, 'Enable_Contingent_Stabilizers', false));
    Eq1_C = Compute_5Sector_Exergy_Equilibrium(Params, 'Phase2_Civic_Doc1E', ...
        struct('ExogShocks', shk_1, 'Enable_Contingent_Stabilizers', true));

    % Vectorized [15 x N_lam] evaluation exploiting monotone SOE response + convex tail curvature:
    D_R = eval_comonotonic_contracts_vec(base_deliv_15, Eq0, Eq1_R, s_vec, c_vec, lam_row, false);
    D_C = eval_comonotonic_contracts_vec(base_deliv_15, Eq0, Eq1_C, s_vec, c_vec, lam_row, true);

    P_R = (D_R >= (a_min - 1e-9)) & (D_R <= (a_max + 1e-9));
    P_C = (D_C >= (a_min - 1e-9)) & (D_C <= (a_max + 1e-9));

    Deliv_Rigid(:, :, f)   = D_R;
    Deliv_Cont(:, :, f)    = D_C;
    Pass_Rigid(:, :, f)    = P_R;
    Pass_Cont(:, :, f)     = P_C;
    Surv_Rigid_LamxF(:, f) = sum(P_R, 1)';
    Surv_Cont_LamxF(:, f)  = sum(P_C, 1)';
end

% 1. Breaking-Point Shock Amplitudes lambda* across K01..K15:
Break_Rigid_15 = zeros(nK, 1);
Break_Cont_15  = zeros(nK, 1);
Vuln_Chan_15   = cell(nK, 1);
Zone_At_1p0    = cell(nK, 1);
Zone_At_1p5    = cell(nK, 1);

idx_1p0 = find(abs(Lambda_Grid - 1.00) < 1e-6, 1);
idx_1p5 = find(abs(Lambda_Grid - 1.50) < 1e-6, 1);
idx_2p0 = find(abs(Lambda_Grid - 2.00) < 1e-6, 1);

for k = 1:nK
    min_lam_r = 2.60;
    min_f_r   = 6;
    for f = 1:nF
        fail_r = find(~Pass_Rigid(k, :, f), 1, 'first');
        if ~isempty(fail_r) && Lambda_Grid(fail_r) < min_lam_r
            min_lam_r = Lambda_Grid(fail_r);
            min_f_r   = f;
        end
    end
    fail_c = find(~Pass_Cont(k, :, min_f_r), 1, 'first');
    lam_c  = ifelse_num(~isempty(fail_c), Lambda_Grid(fail_c), 2.60);

    Break_Rigid_15(k) = min_lam_r;
    Break_Cont_15(k)  = lam_c;
    Vuln_Chan_15{k}   = Families{min_f_r, 1};
    Zone_At_1p0{k}    = classify_zone(Pass_Rigid(k, idx_1p0, min_f_r), Pass_Cont(k, idx_1p0, min_f_r));
    Zone_At_1p5{k}    = classify_zone(Pass_Rigid(k, idx_1p5, min_f_r), Pass_Cont(k, idx_1p5, min_f_r));
end

Margin_Gain_15 = Break_Cont_15 - Break_Rigid_15;

ContractSecurityTable = table(CT.Contract_ID, CT.Provider_Assembly, CT.Consumer_Assembly, ...
    a_min, a_max, base_deliv_15, Vuln_Chan_15, ...
    round(Break_Rigid_15, 2), round(Break_Cont_15, 2), round(Margin_Gain_15, 2), ...
    Zone_At_1p0, Zone_At_1p5, ...
    'VariableNames', {'Contract_ID', 'Provider', 'Consumer', 'Assumed_Min', 'Assumed_Max', ...
    'Baseline_Deliv', 'Primary_Risk_Channel', 'Break_Lambda_Rigid', 'Break_Lambda_Cont', ...
    'Buffer_Expansion_dLambda', 'Status_At_1x_Shock', 'Status_At_1p5x_Shock'});

% 2. 6-Row Comonotonic Shock-Channel Frontier Table:
Safe_All15_Rigid = zeros(nF, 1);
Safe_All15_Cont  = zeros(nF, 1);
for f = 1:nF
    ok_r = find(Surv_Rigid_LamxF(:, f) == nK, 1, 'last');
    ok_c = find(Surv_Cont_LamxF(:, f)  == nK, 1, 'last');
    Safe_All15_Rigid(f) = ifelse_num(~isempty(ok_r), Lambda_Grid(ok_r), 0.0);
    Safe_All15_Cont(f)  = ifelse_num(~isempty(ok_c), Lambda_Grid(ok_c), 0.0);
end

ShockFrontierTable = table(Families(:, 2), ...
    round(Safe_All15_Rigid, 2), round(Safe_All15_Cont, 2), ...
    Surv_Rigid_LamxF(idx_1p0, :)', Surv_Cont_LamxF(idx_1p0, :)', ...
    Surv_Rigid_LamxF(idx_1p5, :)', Surv_Cont_LamxF(idx_1p5, :)', ...
    Surv_Rigid_LamxF(idx_2p0, :)', Surv_Cont_LamxF(idx_2p0, :)', ...
    'VariableNames', {'SOE_Shock_Channel', 'Max_All15_Safe_Rigid', 'Max_All15_Safe_Cont', ...
    'Intact_1x_Rigid', 'Intact_1x_Cont', 'Intact_1p5x_Rigid', 'Intact_1p5x_Cont', ...
    'Intact_2x_Rigid', 'Intact_2x_Cont'});

% 3. 5-Assembly Own vs. Upstream-Dependency Resilience Ceiling Table (A1..A5):
Assem_List = Compact.Assemblies;
nA         = numel(Assem_List);
Own_Rigid  = zeros(nA, 1); Own_Cont  = zeros(nA, 1);
Dep_Rigid  = zeros(nA, 1); Dep_Cont  = zeros(nA, 1);
Key_Telemetry = { ...
    'IDI Age-5/14 Struggling Exit %, S4A2 Kaiako Retention, S4A Reactive Release kFTE'; ...
    'Metro Price-to-Income Q_k, 17.3%->100% YouthGrant Gate, Kuia Care Hours & T_k Step-Down'; ...
    'Joiner Passport Active Uptake %, Vacant-Space Peppercorn Leases, Taiao Sink MtCO2e'; ...
    'S2 Weightless Export Share (RER Cushion), K_N Grid Firming & M_olig, LVT-CorpTax Lockstep'; ...
    'Yr-5 CBAx 2% ROI (>=3.0x), Yr-3 Drawdown (<=1.6% GDP), NFA/Y & 70/30 Debt-Shield Trigger'};

for a = 1:nA
    m_own = strcmp(CT.Provider_Assembly, Assem_List{a});
    m_dep = strcmp(CT.Consumer_Assembly, Assem_List{a});
    Own_Rigid(a) = min(Break_Rigid_15(m_own));
    Own_Cont(a)  = min(Break_Cont_15(m_own));
    Dep_Rigid(a) = min(Break_Rigid_15(m_dep));
    Dep_Cont(a)  = min(Break_Cont_15(m_dep));
end

AssemblyRoadmapTable = table(Assem_List, ...
    round(Own_Rigid, 2), round(Own_Cont, 2), round(Dep_Rigid, 2), round(Dep_Cont, 2), Key_Telemetry, ...
    'VariableNames', {'Assembly', 'Own_Break_Rigid', 'Own_Break_Cont', ...
    'Upstream_Dep_Break_Rigid', 'Upstream_Dep_Break_Cont', 'Live_Dashboard_Telemetry_KPIs'});

% 4. Fast Vectorized 2D Comonotonic External SOE Surface (Exergy lambda_E x Finance/ToT lambda_F):
Grid_2D_Axis      = linspace(0.0, 2.0, 9)';
nG                = numel(Grid_2D_Axis);
Surf_Intact_Cont  = zeros(nG, nG);
Surf_Intact_Rigid = zeros(nG, nG);
Eq_E1_C = Compute_5Sector_Exergy_Equilibrium(Params, 'Phase2_Civic_Doc1E', ...
    struct('ExogShocks', vec_to_shock_struct([0, 0.15, 1, 0, 0.45], 1.0), 'Enable_Contingent_Stabilizers', true));
Eq_F1_C = Compute_5Sector_Exergy_Equilibrium(Params, 'Phase2_Civic_Doc1E', ...
    struct('ExogShocks', vec_to_shock_struct([0, 0, 0, 0.7, 0.7], 1.0), 'Enable_Contingent_Stabilizers', true));

for r_e = 1:nG
    le   = Grid_2D_Axis(r_e);
    lf_r = Grid_2D_Axis(:)'; % [1 x nG] vectorized across columns!
    % Comonotonic dampening when simultaneous exergy + demand/rate shocks hit (monetary/RER stabilizer):
    como_damp = 1.0 ./ (1.0 + 0.18 * min(le, lf_r));
    s_mix     = [0.10*(le+lf_r); 0.20*(le+0.5*lf_r); le*ones(1,nG); 0.65*lf_r; 0.35*le + 0.65*lf_r] .* como_damp;
    c_mix     = [0.28, 0.20, 0.18, 0.15];
    D2_R = eval_comonotonic_surface_cols(base_deliv_15, Eq0, Eq_E1_C, Eq_F1_C, s_mix, c_mix, false);
    D2_C = eval_comonotonic_surface_cols(base_deliv_15, Eq0, Eq_E1_C, Eq_F1_C, s_mix, c_mix, true);
    Surf_Intact_Rigid(r_e, :) = sum((D2_R >= a_min - 1e-9) & (D2_R <= a_max + 1e-9), 1);
    Surf_Intact_Cont(r_e, :)  = sum((D2_C >= a_min - 1e-9) & (D2_C <= a_max + 1e-9), 1);
end

Out = struct();
Out.Sigma_SOE             = Sigma_SOE;
Out.Lambda_Grid           = Lambda_Grid;
Out.Families              = Families;
Out.Surv_Rigid_LamxF      = Surv_Rigid_LamxF;
Out.Surv_Cont_LamxF       = Surv_Cont_LamxF;
Out.Grid_2D_Axis          = Grid_2D_Axis;
Out.Surf_Intact_Rigid     = Surf_Intact_Rigid;
Out.Surf_Intact_Cont      = Surf_Intact_Cont;
Out.ContractSecurityTable = ContractSecurityTable;
Out.ShockFrontierTable    = ShockFrontierTable;
Out.AssemblyRoadmapTable  = AssemblyRoadmapTable;

if verbose_flag
    fprintf('\n=== 1. COMONOTONIC SOE SHOCK FRONTIER ACROSS 6 CHANNELS (CONTRACTS INTACT / 15) ===\n');
    disp(ShockFrontierTable);
    fprintf('\n=== 2. PER-CONTRACT BREAKING-POINT AMPLITUDE (LAMBDA*) & GOVERNANCE ZONES ===\n');
    disp(ContractSecurityTable);
    fprintf('\n=== 3. FIVE-ASSEMBLY OWN VS. UPSTREAM-DEPENDENCY SHOCK CEILINGS & LIVE KPIs ===\n');
    disp(AssemblyRoadmapTable);
end
end

%% --- VECTORIZED COMONOTONIC SOE -> K01..K15 CONTRACT MAPPING [15 x N_lam] ---
function D = eval_comonotonic_contracts_vec(d0, Eq0, Eq1, s_vec, c_vec, lam_row, stab_on)
idx50 = find(Eq0.Years == 2050, 1);

% Nonlinear amplitude envelope: mild convex tail escalation above lambda > 1.0 under unhedged rules:
tail_scale = lam_row .* (1.0 + (0.22 * (~stab_on) + 0.08 * stab_on) * max(0.0, lam_row - 1.0));

% Comonotonic endogenous SOE cushions [rer_s2_cushion, rate_ease_offset, agflation_tot_hedge, poach_cool_offset]:
c_rer   = c_vec(1);
c_rease = c_vec(2);
c_agf   = c_vec(3);
c_pcool = c_vec(4);

s_hc    = s_vec(1) * (1.0 - 0.50 * stab_on);
s_staff = max(0.0, s_vec(2) - 0.35 * c_pcool) * (1.0 - 0.62 * stab_on);
s_en    = s_vec(3) * (1.0 - 0.56 * stab_on);
s_tot   = max(0.0, s_vec(4) * (1.0 - 0.45 * c_agf)) * (1.0 - 0.50 * stab_on);
s_rate  = max(0.0, s_vec(5) - 0.55 * c_rease * s_vec(4)) * (1.0 - 0.52 * stab_on);

% Exact solved SOE slopes at lambda = 1.0:
rel_S2_1  = max(0.0, (Eq0.Y_Sector_SNA_Tx6(idx50, 2) - Eq1.Y_Sector_SNA_Tx6(idx50, 2)) / Eq0.Y_Sector_SNA_Tx6(idx50, 2)) * (1.0 - 0.55 * c_rer);
rel_rem_1 = max(0.0, Eq0.Reactive_Compress_Pct(end) - Eq1.Reactive_Compress_Pct(end)) * (1.0 - 0.35 * stab_on);
rel_vol_1 = max(0.0, (Eq0.Vol_Civic_kFTE_t(idx50) - Eq1.Vol_Civic_kFTE_t(idx50)) / Eq0.Vol_Civic_kFTE_t(idx50));
spr_loss_1= max(0.0, Eq0.Spread_Cut_bps_t(end) - Eq1.Spread_Cut_bps_t(end)) * (1.0 - 0.45 * stab_on - 0.35 * c_rease);

slope_15 = zeros(15, 1);
slope_15(1)  = +0.62 * s_hc + 0.48 * s_staff + 0.22 * s_en;                                   % K01 <= 4.5 (base 4.0, buf 0.50)
slope_15(2)  = -5.80 * s_hc - 4.60 * s_staff - 1.50 * s_en;                                   % K02 >= 57.0 (base 63.5, buf 6.50)
slope_15(3)  = -0.65 * rel_rem_1 - 1.60 * s_hc - 1.10 * s_staff;                              % K03 >= 70.0 (base 76.5, buf 6.50)
slope_15(4)  = -2.50 * s_rate - 1.60 * s_staff - 0.65 * s_tot * (1.0 - 0.50 * c_rease);       % K04 >= 7.5 (base 10.2, buf 2.70)
slope_15(5)  = +(1.0 - 0.68 * stab_on) * (0.95 * s_rate + 0.55 * s_hc + 0.40 * s_tot);        % K05 <= 65.0 (base 64.0, buf 1.00)
slope_15(6)  = -4.60 * s_tot - 3.20 * s_en;                                                   % K06 >= 80.0 (base 85.0, buf 5.00)
slope_15(7)  = -22.0 * rel_vol_1 - 2.60 * s_en - 2.40 * s_staff;                              % K07 >= 57.0 (base 64.0, buf 7.00)
slope_15(8)  = -35.0 * rel_vol_1 - 5.20 * s_en - 4.20 * s_tot - 3.60 * s_staff;               % K08 >= 122.0 (base 134.5, buf 12.5)
slope_15(9)  = -0.32 * s_en - 0.33 * s_rate - 0.30 * s_hc;                                    % K09 >= 1.0 (base 1.4, buf 0.40)
slope_15(10) = +(1.0 - 0.78 * stab_on) * (1.85 * s_rate + 1.15 * s_tot);                      % K10 in [8, 12] (base 10.0, buf 2.00)
slope_15(11) = -(1.0 - 0.72 * stab_on) * (12.5 * s_rate + 8.0 * s_tot);                       % K11 >= 75.0 (base 90.0, buf 15.0)
slope_15(12) = -18.0 * rel_S2_1 - 4.80 * s_en - 4.60 * s_tot * (1.0 - 0.45 * c_rer) - 3.60 * s_rate; % K12 >= 40.0 (base 52.9, buf 12.9)
slope_15(13) = -0.64 * s_rate - 0.52 * s_hc - 0.38 * s_en - 0.28 * s_tot;                     % K13 >= 3.0 (base 3.84, buf 0.84)
slope_15(14) = +0.34 * s_en + 0.30 * s_rate + 0.20 * s_tot;                                   % K14 <= 1.60 (base 1.15, buf 0.45)
slope_15(15) = -0.45 * spr_loss_1 - 5.20 * s_rate - 4.20 * s_tot - 3.60 * s_en;               % K15 >= 45.0 (base 60.0, buf 15.0)

D = d0(:) + slope_15 * tail_scale; % Outer product [15 x 1] * [1 x N_lam] -> [15 x N_lam]!
end

function D2 = eval_comonotonic_surface_cols(d0, Eq0, EqE, EqF, s_mix_5xn, c_vec, stab_on)
nG = size(s_mix_5xn, 2);
D2 = zeros(15, nG);
for c = 1:nG
    sv = s_mix_5xn(:, c)';
    Eq_blend = EqE;
    Eq_blend.Spread_Cut_bps_t = 0.5 * (EqE.Spread_Cut_bps_t + EqF.Spread_Cut_bps_t);
    D2(:, c) = eval_comonotonic_contracts_vec(d0, Eq0, Eq_blend, sv, c_vec, 1.0, stab_on);
end
end

function S = vec_to_shock_struct(s_vec, lam)
S = struct( ...
    'HC_Realization_Lag',   lam * s_vec(1), ...
    'S4A_Poaching_Shock',   lam * s_vec(2), ...
    'World_Fossil_Spike',   lam * s_vec(3), ...
    'Dry_Hydro_Shock',      lam * s_vec(3), ...
    'Export_ToT_Hit',       lam * s_vec(4), ...
    'World_Rate_Shock_bps', lam * 180.0 * s_vec(5));
end

function z = classify_zone(pass_r, pass_c)
if pass_r && pass_c
    z = 'GREEN_SELF_CLEARING';
elseif (~pass_r) && pass_c
    z = 'AMBER_AUTO_REMEDY';
else
    z = 'RED_RECONVENE_PLENARY';
end
end

function v = ifelse_num(c, a, b)
if c, v = a; else, v = b; end
end
