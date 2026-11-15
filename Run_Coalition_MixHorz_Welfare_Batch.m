%% RUN_COALITION_MIXHORZ_WELFARE_BATCH.M
% Full 5D MixHorz_PType VFI + 4x5 Endogenous Intergenerational Welfare & Diagnostic Runner
% 1. Keeps reanchor_2023 Q_reg = [1.03, 1.37, 2.00, 3.02] so 0.08*Q_Rural stays below a(10)=0.084375
% 2. Calibrates ShockScale so Full15 ('all_but_ndc', Shocks #1-#15) lands on -21.85% LTFM (-5.64% Delta CE)
% 3. Compares Coalition13 ('first_13_shocks') vs Full15 ('all_but_ndc') vs Full16 ('full_16_shocks')

clear; clc;
Params.dt = 3;
Params = Configure_TimeGrid_Params(Params);
NZ_4Region_Master; % Initializes 5D grids, Params, pi_z, ReturnFn, vfoptions, simoptions

N_reg    = length(Regions);
PopShare = Params.Pop_Weights_4(:)';
if ~exist('OutputDir', 'var') || isempty(OutputDir)
    OutputDir = 'Output_NZ_4Region_Intergen';
end
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end

LTFM_Offset        = -16.21;
Target_Full15_LTFM = -21.85; % Canonical Table B.1 benchmark (-5.64% Delta CE vs SS0_2023)
Target_Full15_Raw  = Target_Full15_LTFM - LTFM_Offset; % -5.64%

%% ========================================================================
%  PHASE 1: SOLVE CLEAN BASELINE ANCHOR (SS0_2023) VIA 5D MixHorz_PType
%  ========================================================================
fprintf('\n========================================================================\n');
fprintf(' PHASE 1: SOLVING 5D MIXHORZ BASELINE ANCHOR (SS0_2023)\n');
fprintf('========================================================================\n');
t0 = tic;

[P_SS0_raw, pi_z_SS0_2023, Meta_SS0] = Apply_Coalition_2024_Shocks( ...
    Params, pi_z, 'reanchor_2023');
[Params_SS0_2023, z_grid_SS0_2023] = sync_shock_params_to_vfi(P_SS0_raw, Params, z_grid, Regions, true, 0.0);

[V_SS0_2023, Policy_SS0_2023] = ValueFnIter_MixHorz_PType( ...
    n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid_SS0_2023, pi_z_SS0_2023, ...
    ReturnFn, Params_SS0_2023, DiscountFactorParamNames, vfoptions);

jDist_SS0_2023 = jequaloneDist;
for ig0_it = 1:12
    StatDist_SS0_2023 = StationaryDist_MixHorz_PType( ...
        jDist_SS0_2023, AgeWeightsParamNames, PTypeDistParamNames, Policy_SS0_2023, ...
        n_d, n_a, n_z, N_j, Names_i, pi_z_SS0_2023, Params_SS0_2023, simoptions);
    [jDist_new, IG_Diag_SS0_2023] = Build_IntergenTransitionMatrix( ...
        StatDist_SS0_2023, Policy_SS0_2023, V_SS0_2023, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid_SS0_2023, pi_z_SS0_2023, Params_SS0_2023, Regions);
    diff0 = max(abs(jDist_new.HH_Auckland(:) - jDist_SS0_2023.HH_Auckland(:)));
    jDist_SS0_2023 = jDist_new;
    if diff0 < 1e-5, break; end
end
fprintf('Solved SS0_2023 baseline in %.1f s (IG iterations: %d)\n', toc(t0), ig0_it);
print_ig_diag_block('0. SS0_2023 (HYEFU 2023 BASELINE)', IG_Diag_SS0_2023, Regions, PopShare, Params.dt, Params.J);

eta_c_val = 2.0;
if isfield(Params_SS0_2023, 'eta_c'), eta_c_val = Params_SS0_2023.eta_c; end
exp_ce = 1 / (Params_SS0_2023.phi_nd * (1 - eta_c_val));

%% ========================================================================
%  PHASE 2A: CALIBRATE ShockScale SO Full15 ('all_but_ndc') = -5.64% (-21.85% LTFM)
%  ========================================================================
fprintf('\n========================================================================\n');
fprintf(' PHASE 2A: CALIBRATING ShockScale FOR Full15 (all_but_ndc) -> %.2f%% LTFM\n', Target_Full15_LTFM);
fprintf('========================================================================\n');

s_a = 0.25;
[ce_a, ~] = eval_full15_stage3(s_a, P_SS0_raw, pi_z_SS0_2023, Params_SS0_2023, z_grid_SS0_2023, ...
    V_SS0_2023, jDist_SS0_2023, n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ...
    ReturnFn, DiscountFactorParamNames, AgeWeightsParamNames, PTypeDistParamNames, ...
    vfoptions, simoptions, Regions, PopShare, exp_ce);
fprintf('  [Probe 1] ShockScale = %.4f -> Full15 Stage-3 Nat Delta CE = %+6.2f%% (LTFM: %+6.2f%%)\n', ...
    s_a, ce_a, ce_a + LTFM_Offset);

% Anchor against s = 0.00 where Shocks #14+#15 alone produce ~ -1.85% Nat Delta CE:
ce_0 = -1.85;
s_b  = max(0.10, min(0.85, s_a * (Target_Full15_Raw - ce_0) / (ce_a - ce_0)));
if abs(ce_a - Target_Full15_Raw) > 0.08
    [ce_b, ~] = eval_full15_stage3(s_b, P_SS0_raw, pi_z_SS0_2023, Params_SS0_2023, z_grid_SS0_2023, ...
        V_SS0_2023, jDist_SS0_2023, n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ...
        ReturnFn, DiscountFactorParamNames, AgeWeightsParamNames, PTypeDistParamNames, ...
        vfoptions, simoptions, Regions, PopShare, exp_ce);
    fprintf('  [Probe 2] ShockScale = %.4f -> Full15 Stage-3 Nat Delta CE = %+6.2f%% (LTFM: %+6.2f%%)\n', ...
        s_b, ce_b, ce_b + LTFM_Offset);
    if abs(ce_b - ce_a) > 1e-4
        ShockScale_Cal = max(0.10, min(0.85, s_b + (Target_Full15_Raw - ce_b) * (s_b - s_a) / (ce_b - ce_a)));
    else
        ShockScale_Cal = s_b;
    end
else
    ShockScale_Cal = s_a;
end
fprintf('  ==> LOCKED CALIBRATED ShockScale_Cal = %.4f (Anchors Full15 = %.2f%% LTFM)\n', ...
    ShockScale_Cal, Target_Full15_LTFM);

%% ========================================================================
%  PHASE 2B: SOLVE ALL 8 BRANCHES AT CALIBRATED ShockScale_Cal
%  ========================================================================
Branch_Specs = {
    'AustOnly',      'austerity_landlord_only', '1. Austerity + Landlord + Teacher/KS Squeeze (#1-#8, #12-#13)';
    'GrowthOnly',    'pro_growth_only',         '2. Pro-Growth Levers Only (#9 Tax Cut, #10 AIP Visa, #11 Inv Boost)';
    'Coalition13',   'coalition_13_shocks',     '3. First 13 Shocks Combined (first_13_shocks, #1-#13)';
    'Shock14_3W',    'rates_cap_3_waters',      '4. Shock #14 Only: 3 Waters Repeal & Council Rates Wedge';
    'Shock15_Civic', 'arts_and_civic_cuts',     '5. Shock #15 Only: Vote Arts/Sport & WCC Civic Squeeze';
    'Full15',        'all_but_ndc',             '6. All 15 Domestic Shocks Combined (all_but_ndc, #1-#15)';
    'Shock16_NDC',   'ndc',                     '7. Shock #16 Only: Off-Book Paris NDC1/2 + EV Rollback';
    'Full16',        'full_16_shocks',          '8. Full 16-Shock Coalition Package (full_16_shocks, #1-#16)'
    };

N_branches          = size(Branch_Specs, 1);
CoalitionWelfare    = struct();
All_Rows_Raw        = zeros(3 * N_branches, N_reg + 1);
All_Row_Names       = cell(3 * N_branches, 1);
Summary_Stage3_Pure = zeros(N_branches, N_reg + 1);

for b = 1:N_branches
    b_code  = Branch_Specs{b, 1};
    b_mode  = Branch_Specs{b, 2};
    b_label = Branch_Specs{b, 3};

    [P_vfi_b, zg_b, piz_b, Meta_b] = build_calibrated_branch( ...
        b_mode, ShockScale_Cal, P_SS0_raw, pi_z_SS0_2023, Params_SS0_2023, z_grid_SS0_2023, Regions);

    fprintf('\n------------------------------------------------------------------------\n');
    fprintf(' Solving Branch %d/%d: %s\n', b, N_branches, b_label);
    fprintf('------------------------------------------------------------------------\n');
    tb = tic;

    % --- STAGE 1: Short-Run PE ---
    P_PE          = P_vfi_b;
    P_PE.r        = Params_SS0_2023.r;
    P_PE.w_reg    = Params_SS0_2023.w_reg;
    P_PE.Q_reg    = Params_SS0_2023.Q_reg;
    P_PE.K_whanau = Params_SS0_2023.K_whanau;

    [V_PE_b, Policy_PE_b] = ValueFnIter_MixHorz_PType( ...
        n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid_SS0_2023, pi_z_SS0_2023, ...
        ReturnFn, P_PE, DiscountFactorParamNames, vfoptions);

    % --- STAGE 2: Long-Run GE Prices, Firm z_grid & Layoff pi_z ---
    P_GE = P_vfi_b;
    [V_GE_b, Policy_GE_b] = ValueFnIter_MixHorz_PType( ...
        n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, zg_b, piz_b, ...
        ReturnFn, P_GE, DiscountFactorParamNames, vfoptions);

    % --- STAGE 3: Endogenous 4x5 Intergenerational Distribution (Reset from jDist_SS0_2023) ---
    jDist_b = jDist_SS0_2023;
    for ig_it = 1:12
        StatDist_b = StationaryDist_MixHorz_PType( ...
            jDist_b, AgeWeightsParamNames, PTypeDistParamNames, Policy_GE_b, ...
            n_d, n_a, n_z, N_j, Names_i, piz_b, P_GE, simoptions);
        [jDist_b_new, IG_Diag_b] = Build_IntergenTransitionMatrix( ...
            StatDist_b, Policy_GE_b, V_GE_b, ...
            n_d, n_a, n_z, d_grid, a_grid, zg_b, piz_b, P_GE, Regions);
        diff_b = max(abs(jDist_b_new.HH_Auckland(:) - jDist_b.HH_Auckland(:)));
        jDist_b = jDist_b_new;
        if diff_b < 1e-5, break; end
    end

    CE_Stage_Pure = compute_3stage_ce(V_SS0_2023, V_PE_b, V_GE_b, jDist_SS0_2023, jDist_b, Regions, exp_ce);
    Nat_Pure      = CE_Stage_Pure * PopShare(:);

    rows_b = (3*(b-1)+1) : (3*b);
    All_Rows_Raw(rows_b, :)   = [CE_Stage_Pure, Nat_Pure];
    Summary_Stage3_Pure(b, :) = [CE_Stage_Pure(3, :), Nat_Pure(3)];
    All_Row_Names{rows_b(1)}  = sprintf('%s_1_ShortRun_PE', b_code);
    All_Row_Names{rows_b(2)}  = sprintf('%s_2_LongRun_GE_ExoSkills', b_code);
    All_Row_Names{rows_b(3)}  = sprintf('%s_3_LongRun_GE_EndoIntergen', b_code);

    print_ig_diag_block(b_label, IG_Diag_b, Regions, PopShare, Params.dt, Params.J);
    fprintf('Solved %s in %.1f s | Stage-3 Delta CE: %+6.2f%% (LTFM: %+6.2f%%) | Large (Wgtn) Delta CE: %+6.2f%%\n', ...
        b_code, toc(tb), Nat_Pure(3), Nat_Pure(3) + LTFM_Offset, CE_Stage_Pure(3, 3));

    CoalitionWelfare.(b_code).V_PE      = V_PE_b;
    CoalitionWelfare.(b_code).V_GE      = V_GE_b;
    CoalitionWelfare.(b_code).Policy_GE = Policy_GE_b;
    CoalitionWelfare.(b_code).StatDist  = StatDist_b;
    CoalitionWelfare.(b_code).jDist     = jDist_b;
    CoalitionWelfare.(b_code).IG_Diag   = IG_Diag_b;
    CoalitionWelfare.(b_code).Meta      = Meta_b;
    CoalitionWelfare.(b_code).CE_Pure   = CE_Stage_Pure;
end

%% ========================================================================
%  PHASE 2C: PRINT & SAVE FINAL TABLES + WELLINGTON (LARGE) INCIDENCE AUDIT
%  ========================================================================
VarNames = {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct', 'National_CE_Pct'};

T_Coalition_AllStages = array2table(All_Rows_Raw,                      'RowNames', All_Row_Names,      'VariableNames', VarNames);
T_Stage3_Pure_Delta   = array2table(Summary_Stage3_Pure,               'RowNames', Branch_Specs(:, 1), 'VariableNames', VarNames);
T_Stage3_Pure_LTFM    = array2table(Summary_Stage3_Pure + LTFM_Offset, 'RowNames', Branch_Specs(:, 1), 'VariableNames', VarNames);

fprintf('\n=== FULL 3-STAGE DECOMPOSITION (CALIBRATED TO Full15 = -21.85%% LTFM): RAW DELTA CE%% VS. SS0_2023 ===\n');
disp(T_Coalition_AllStages);

fprintf('\n=== STAGE-3 SUMMARY: RAW DELTA CE%% VS. SS0_2023 ===\n');
disp(T_Stage3_Pure_Delta);

fprintf('\n=== STAGE-3 SUMMARY: LTFM-ANCHORED CE%% (-16.21%% OFFSET) ===\n');
disp(T_Stage3_Pure_LTFM);

ce13_row = [CoalitionWelfare.Coalition13.CE_Pure(3, :), CoalitionWelfare.Coalition13.CE_Pure(3, :) * PopShare(:)];
ce15_row = [CoalitionWelfare.Full15.CE_Pure(3, :),      CoalitionWelfare.Full15.CE_Pure(3, :)      * PopShare(:)];
ce16_row = [CoalitionWelfare.Full16.CE_Pure(3, :),      CoalitionWelfare.Full16.CE_Pure(3, :)      * PopShare(:)];
wedge_14_15 = ce15_row - ce13_row;

fprintf('\n=========================================================================================\n');
fprintf(' HEAD-TO-HEAD AUDIT: first_13_shocks (Coalition13) vs. all_but_ndc (Full15)\n');
fprintf('=========================================================================================\n');
fprintf('Metric / Regime                         |  Rural  |  Small  |  Large (Wgtn) | Auckland | National\n');
fprintf('----------------------------------------+---------+---------+---------------+----------+---------\n');
fprintf('Coalition13 (first_13_shocks) Delta CE%% | %+6.2f%% | %+6.2f%% |    %+6.2f%%    | %+6.2f%%  | %+6.2f%%\n', ce13_row);
fprintf('Full15      (all_but_ndc)     Delta CE%% | %+6.2f%% | %+6.2f%% |    %+6.2f%%    | %+6.2f%%  | %+6.2f%%\n', ce15_row);
fprintf('Incremental Wedge (#14 + #15) Delta CE%% | %+6.2f%% | %+6.2f%% |    %+6.2f%%    | %+6.2f%%  | %+6.2f%%\n', wedge_14_15);
fprintf('Full16      (full_16_shocks)  Delta CE%% | %+6.2f%% | %+6.2f%% |    %+6.2f%%    | %+6.2f%%  | %+6.2f%%\n', ce16_row);
fprintf('----------------------------------------+---------+---------+---------------+----------+---------\n');
fprintf('Large / National Disproportionality Ratio: %.2fx in Coalition13 | %.2fx in (#14+#15) | %.2fx in Full15\n', ...
    ce13_row(3)/ce13_row(5), wedge_14_15(3)/wedge_14_15(5), ce15_row(3)/ce15_row(5));
fprintf('Large Emigration Rate (Abroad)           : %.1f%% (SS0_2023) -> %.1f%% (Coalition13) -> %.1f%% (Full15) -> %.1f%% (Full16)\n', ...
    100*IG_Diag_SS0_2023.EmigRate.Large, 100*CoalitionWelfare.Coalition13.IG_Diag.EmigRate.Large, ...
    100*CoalitionWelfare.Full15.IG_Diag.EmigRate.Large, 100*CoalitionWelfare.Full16.IG_Diag.EmigRate.Large);

writetable(T_Coalition_AllStages, fullfile(OutputDir, 'Table_Coalition_AllStages_Calibrated_SS0_2023.csv'), 'WriteRowNames', true);
writetable(T_Stage3_Pure_Delta,   fullfile(OutputDir, 'Table_Coalition_Stage3_Calibrated_Delta.csv'),       'WriteRowNames', true);
writetable(T_Stage3_Pure_LTFM,    fullfile(OutputDir, 'Table_Coalition_Stage3_Calibrated_LTFM.csv'),        'WriteRowNames', true);
save(fullfile(OutputDir, 'Coalition_MixHorz_Welfare_Calibrated.mat'), ...
    'CoalitionWelfare', 'ShockScale_Cal', 'T_Coalition_AllStages', 'T_Stage3_Pure_Delta', 'T_Stage3_Pure_LTFM', 'IG_Diag_SS0_2023');

%% ========================================================================
%  LOCAL HELPER FUNCTIONS
%  ========================================================================
function [nat_ce3, CE_Stage] = eval_full15_stage3(s_core, P_SS0_raw, pi_z_SS0_2023, Params_SS0_2023, z_grid_SS0_2023, ...
    V_SS0_2023, jDist_SS0_2023, n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ...
    ReturnFn, DiscountFactorParamNames, AgeWeightsParamNames, PTypeDistParamNames, ...
    vfoptions, simoptions, Regions, PopShare, exp_ce)

[P_GE, zg_b, piz_b, ~] = build_calibrated_branch( ...
    'all_but_ndc', s_core, P_SS0_raw, pi_z_SS0_2023, Params_SS0_2023, z_grid_SS0_2023, Regions);

[V_GE_b, Policy_GE_b] = ValueFnIter_MixHorz_PType( ...
    n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, zg_b, piz_b, ...
    ReturnFn, P_GE, DiscountFactorParamNames, vfoptions);

jDist_b = jDist_SS0_2023;
for ig_it = 1:12
    StatDist_b = StationaryDist_MixHorz_PType( ...
        jDist_b, AgeWeightsParamNames, PTypeDistParamNames, Policy_GE_b, ...
        n_d, n_a, n_z, N_j, Names_i, piz_b, P_GE, simoptions);
    [jDist_b_new, ~] = Build_IntergenTransitionMatrix( ...
        StatDist_b, Policy_GE_b, V_GE_b, ...
        n_d, n_a, n_z, d_grid, a_grid, zg_b, piz_b, P_GE, Regions);
    if max(abs(jDist_b_new.HH_Auckland(:) - jDist_b.HH_Auckland(:))) < 1e-5
        jDist_b = jDist_b_new;
        break;
    end
    jDist_b = jDist_b_new;
end
CE_Stage = compute_3stage_ce(V_SS0_2023, V_GE_b, V_GE_b, jDist_SS0_2023, jDist_b, Regions, exp_ce);
nat_ce3  = CE_Stage(3, :) * PopShare(:);
end

function [P_vfi, zg_out, piz_out, Meta_out] = build_calibrated_branch( ...
    b_mode, s_core, P_SS0_raw, pi_z_SS0_2023, Params_SS0_2023, z_grid_SS0_2023, Regions)

switch lower(b_mode)
    case {'rates_cap_3_waters', 'arts_and_civic_cuts', 'ndc'}
        opts = struct('ShockScale', 1.0);
        [P_raw, piz_out, Meta_out] = Apply_Coalition_2024_Shocks(P_SS0_raw, pi_z_SS0_2023, b_mode, opts);
        [P_vfi, zg_out] = sync_shock_params_to_vfi(P_raw, Params_SS0_2023, z_grid_SS0_2023, Regions, false, 0.0);
    case {'austerity_landlord_only', 'pro_growth_only', 'coalition_13_shocks'}
        opts = struct('ShockScale', s_core);
        [P_raw, piz_out, Meta_out] = Apply_Coalition_2024_Shocks(P_SS0_raw, pi_z_SS0_2023, b_mode, opts);
        s_landlord = s_core * double(~strcmpi(b_mode, 'pro_growth_only'));
        [P_vfi, zg_out] = sync_shock_params_to_vfi(P_raw, Params_SS0_2023, z_grid_SS0_2023, Regions, false, s_landlord);
    case {'all_but_ndc', 'full_16_shocks'}
        opts13 = struct('ShockScale', s_core);
        [P_13, piz_out, ~] = Apply_Coalition_2024_Shocks(P_SS0_raw, pi_z_SS0_2023, 'coalition_13_shocks', opts13);
        opts_add = struct('ShockScale', 1.0, 'LandlordTaxBreak', false, 'ScienceCallaghanCuts', false, ...
            'PublicSectorLayoffs', false, 'CancelFerriesPorts', false, 'DunedinHospitalDelays', false, ...
            'CancelPayEquity_OT_ECE', false, 'TertiaryFeesFreeCut', false, 'TobaccoTaxFreeze', false, ...
            'TeacherKaiakoPaySqueeze', false, 'KiwiSaverMatchCut', false, ...
            'IncomeTaxBracketCut', false, 'ActiveInvestorVisa', false, 'InvestmentBoost20Pct', false, ...
            'ThreeWatersRatesWedge', true, 'ArtsCivicWCCSqueeze', true, ...
            'ParisNDCLiabilityAndEVRollback', strcmpi(b_mode, 'full_16_shocks'));
        [P_raw, piz_out, Meta_out] = Apply_Coalition_2024_Shocks(P_13, piz_out, 'custom', opts_add);
        [P_vfi, zg_out] = sync_shock_params_to_vfi(P_raw, Params_SS0_2023, z_grid_SS0_2023, Regions, false, s_core);
end
end

function CE_Stage = compute_3stage_ce(V0, Vpe, Vge, jDist0, jDistB, Regions, exp_ce)
N_reg    = numel(Regions);
CE_Stage = zeros(3, N_reg);
for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    d0_j1   = double(gather(jDist0.(hh_type)(:)));
    db_j1   = double(gather(jDistB.(hh_type)(:)));
    N_st    = numel(d0_j1);

    V0_mat  = reshape(double(gather(V0.(hh_type))),  N_st, []);
    Vpe_mat = reshape(double(gather(Vpe.(hh_type))), N_st, []);
    Vge_mat = reshape(double(gather(Vge.(hh_type))), N_st, []);

    V0_j1   = V0_mat(:, 1);
    Vpe_j1  = Vpe_mat(:, 1);
    Vge_j1  = Vge_mat(:, 1);

    m_v = isfinite(V0_j1) & isfinite(Vpe_j1) & isfinite(Vge_j1);
    m0  = m_v & (d0_j1 > 0);
    mb  = m_v & (db_j1 > 0);

    ev0   = sum(V0_j1(m0)  .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_pe = sum(Vpe_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_ge = sum(Vge_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_ig = sum(Vge_j1(mb) .* db_j1(mb)) / sum(db_j1(mb));

    CE_Stage(1, r_idx) = 100 * (((ev_pe / ev0) ^ exp_ce) - 1);
    CE_Stage(2, r_idx) = 100 * (((ev_ge / ev0) ^ exp_ce) - 1);
    CE_Stage(3, r_idx) = 100 * (((ev_ig / ev0) ^ exp_ce) - 1);
end
end

function [P_vfi, z_grid_out] = sync_shock_params_to_vfi(P_raw, P_ref, z_grid_in, Regions, is_baseline, s_landlord)
P_vfi      = P_raw;
z_grid_out = z_grid_in;
dt_val     = P_vfi.dt;
scale_dt   = dt_val / 5;

% 1. Keep G_ece_stage1, G_ece_stage2, G_ece SCALAR:
if isfield(P_raw, 'G_ECE_1') && isscalar(P_raw.G_ECE_1)
    P_vfi.G_ece_stage1 = P_raw.G_ECE_1;
    P_vfi.G_ece        = P_raw.G_ECE_1;
elseif isstruct(P_vfi.G_ece_stage1)
    P_vfi.G_ece_stage1 = P_vfi.G_ece_stage1.HH_Rural;
    P_vfi.G_ece        = P_vfi.G_ece_stage1;
end
if isfield(P_raw, 'G_ECE_2') && isscalar(P_raw.G_ECE_2)
    P_vfi.G_ece_stage2 = P_raw.G_ECE_2;
elseif isstruct(P_vfi.G_ece_stage2)
    P_vfi.G_ece_stage2 = P_vfi.G_ece_stage2.HH_Rural;
end

% 2. Preserve Shock #1 scalar upsilon_h shift (0.0095 - 0.0035 * s_landlord) and Shock #14 mu_maint hike:
P_vfi.upsilon_h = 0.0095 - s_landlord * 0.0035;
rates_14_add    = [0, 0, 0, 0];
if ~is_baseline && isfield(P_raw, 'upsilon_h_vec')
    rates_14_add = max(0, P_raw.upsilon_h_vec - [0.012, 0.014, 0.016, 0.015]);
end
for k = 1:numel(Regions)
    P_vfi.mu_maint.(['HH_', Regions{k}]) = 0.040 + rates_14_add(k);
end

% 3. Keep Apply_Coalition_2024_Shocks's own Q_reg_base = [1.03, 1.37, 2.00, 3.02] & Q_reg = Q_k_vec!
%    (At Q_base_Rural = 1.03, 0.08 * Q_Rural = 0.0824, which never crosses a(10) = 0.084375!)
if isfield(P_raw, 'gbar_ECE')
    P_vfi.gbar_ece = P_raw.gbar_ECE;
end

hc_mult    = 1.0;
morbid_5yr = 0.0;
if ~is_baseline && isfield(P_raw, 'delta_hc_ann'),          hc_mult    = P_raw.delta_hc_ann / 0.0180; end
if ~is_baseline && isfield(P_raw, 'Senescence_Morbid_Add'), morbid_5yr = P_raw.Senescence_Morbid_Add; end
P_vfi.delta_hc = 1 - (1 - min(0.45, 0.087 * hc_mult + morbid_5yr)) ^ scale_dt;

P_vfi.r      = P_ref.r;
r_spread_ann = 0.0;
if ~is_baseline && isfield(P_raw, 'r_sov_spread'), r_spread_ann = P_raw.r_sov_spread; end
ndc_drain_b  = 0.0;
if ~is_baseline && isfield(P_raw, 'Offshore_NDC_Drain_BNZD'), ndc_drain_b = P_raw.Offshore_NDC_Drain_BNZD; end
if ~is_baseline && (r_spread_ann > 0 || ndc_drain_b > 0)
    P_vfi.tau_l = P_vfi.tau_l + 0.0025 * (ndc_drain_b / 0.725) + 0.80 * r_spread_ann;
end

super_age_eff   = 20 + (P_vfi.Jr - 1) * dt_val;
elder_time_mult = exp(-P_vfi.eta_elder_whanau * max(0, super_age_eff - 65));
zh_ref_vec      = [1.15, 1.28, 1.50, 1.75];
tau_k_delta     = P_vfi.tau_k - 0.250;
lam_col_delta   = P_vfi.lambda_col - 1.80;

for k = 1:numel(Regions)
    reg     = Regions{k};
    hh_tp   = ['HH_', reg];
    firm_tp = ['Firm_', reg];

    if isfield(P_raw, 'z_f_grid') && isfield(P_raw.z_f_grid, firm_tp)
        zf_pair = P_raw.z_f_grid.(firm_tp)(:);
        z_grid_out.(firm_tp) = zf_pair;
        if ~is_baseline
            d_ln_zh     = (zf_pair(2) - zh_ref_vec(k)) / zh_ref_vec(k);
            ge_cap_lift = -0.28 * tau_k_delta + 0.08 * lam_col_delta - 1.20 * r_spread_ann;
            ge_tfp_lift = 0.45 * d_ln_zh;
            w_ge        = P_raw.w_reg.(hh_tp) * (1.0 + ge_cap_lift + ge_tfp_lift);
            P_vfi.w_reg.(hh_tp)   = w_ge;
            P_vfi.w_reg.(firm_tp) = w_ge;
        end
    end

    q_base = P_vfi.Q_reg_base.(hh_tp);
    q_now  = P_vfi.Q_reg.(hh_tp);
    elder_home_mult = min(1.15, max(0.50, (P_vfi.p_super / 0.18) * ((q_base / q_now) ^ 0.35)));
    club_mult = 1.0;
    if ~is_baseline && isfield(P_raw, 'psi_club_buffer') && isfield(P_raw.psi_club_buffer, hh_tp)
        club_mult = P_raw.psi_club_buffer.(hh_tp);
    end
    P_vfi.K_whanau.(hh_tp) = P_vfi.K_whanau_base.(hh_tp) * elder_time_mult * elder_home_mult * club_mult;
end
end

function print_ig_diag_block(TitleStr, IG_D, Regions, PopShares, dt, J)
fprintf('\n=== 4-REGION + ABROAD STEADY-STATE DIAGNOSTICS: %s (dt = %d yr, J = %d) ===\n', TitleStr, dt, J);
for k = 1:numel(Regions)
    reg = Regions{k};
    fprintf('Region: %-9s (Pop %4.1f%%) | Stage-1 Skill: %.3f | Completed Skill: %.3f | Struggling: %4.1f%% | Mean Bequest: %.3f | Emig: %4.1f%%\n', ...
        reg, 100*PopShares(k), IG_D.MeanTheta2.(reg), IG_D.MeanTheta3.(reg), ...
        100*IG_D.StrugglingShare.(reg), IG_D.MeanBequest.(reg), 100*IG_D.EmigRate.(reg));
end
end
