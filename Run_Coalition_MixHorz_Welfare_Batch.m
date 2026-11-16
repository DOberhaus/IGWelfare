%% RUN_COALITION_MIXHORZ_WELFARE_BATCH.M
% Clean 5D MixHorz_PType VFI + 4x5 Endogenous Intergenerational Welfare Runner
% Calls Apply_Coalition_2024_Shocks directly with zero parameter-patching glue.

%% RUN_COALITION_MIXHORZ_WELFARE_BATCH.M (PHASE 2: launch_0980 SRTP AUDIT)
clear; clc;
Params.dt              = 3;
Params.Discount_Regime = 'launch_0980'; % Treasury Circular 2024/15 SRTP (beta_hh=0.980^dt, beta_firm=0.975^dt)
Params = Configure_TimeGrid_Params(Params);
NZ_4Region_Master;

N_reg    = length(Regions);
PopShare = Params.Pop_Weights_4(:)';
OutputDir = sprinft('Output_NZ_4Region_Intergen_%s', Params.Discount_Regime);
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end

LTFM_Offset     = -16.21;
% Core13Scale_Cal = 0.4108; % Locked from Phase 1 (historic_096) so Phase 2 isolates pure discount-rate effect!
Core13Scale_Cal = 0.3818; % Locked from Phase 1 (launch_0980) so Phase 2 isolates pure discount-rate effect!
Target_Full15_LTFM = -21.85;
Target_Full15_Raw  = Target_Full15_LTFM - LTFM_Offset; % -5.64%

%% 1. SOLVE CLEAN BASELINE ANCHOR (SS0_2023)
fprintf('\n=== PHASE 1: SOLVING 5D MIXHORZ BASELINE ANCHOR (SS0_2023) ===\n');
t0 = tic;
[Params_SS0_2023, pi_z_SS0_2023, Meta_SS0, z_grid_SS0_2023] = ...
    Apply_Coalition_2024_Shocks(Params, pi_z, 'reanchor_2023', struct(), z_grid);

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
fprintf('Solved SS0_2023 in %.1f s (IG iters: %d)\n', toc(t0), ig0_it);
print_ig_diag_block('0. SS0_2023 (HYEFU 2023 BASELINE)', IG_Diag_SS0_2023, Regions, PopShare, Params.dt, Params.J);

eta_c_val = 2.0;
if isfield(Params_SS0_2023, 'eta_c'), eta_c_val = Params_SS0_2023.eta_c; end
exp_ce = 1 / (Params_SS0_2023.phi_nd * (1 - eta_c_val));

%% 2. CALIBRATE Core13Scale SO Full15 ('all_but_ndc') = -21.85% LTFM (-5.64% Delta CE)
fprintf('\n=== PHASE 2A: CALIBRATING Core13Scale FOR Full15 (all_but_ndc) -> %.2f%% LTFM ===\n', Target_Full15_LTFM);
s_1  = 0.35;
ce_1 = eval_stage3_nat('all_but_ndc', struct('ShockScale', 1.0, 'Core13Scale', s_1), ...
    Params_SS0_2023, pi_z_SS0_2023, z_grid_SS0_2023, V_SS0_2023, jDist_SS0_2023, ...
    n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ReturnFn, DiscountFactorParamNames, ...
    AgeWeightsParamNames, PTypeDistParamNames, vfoptions, simoptions, Regions, PopShare, exp_ce);
fprintf('  [Probe 1] Core13Scale = %.4f -> Full15 Stage-3 Nat Delta CE = %+6.2f%% (LTFM: %+6.2f%%)\n', ...
    s_1, ce_1, ce_1 + LTFM_Offset);

ce_0 = -1.85; % Known Shock #14 + #15 intercept at Core13Scale = 0
s_2  = max(0.10, min(1.00, s_1 * (Target_Full15_Raw - ce_0) / (ce_1 - ce_0)));
if abs(ce_1 - Target_Full15_Raw) > 0.06
    ce_2 = eval_stage3_nat('all_but_ndc', struct('ShockScale', 1.0, 'Core13Scale', s_2), ...
        Params_SS0_2023, pi_z_SS0_2023, z_grid_SS0_2023, V_SS0_2023, jDist_SS0_2023, ...
        n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ReturnFn, DiscountFactorParamNames, ...
        AgeWeightsParamNames, PTypeDistParamNames, vfoptions, simoptions, Regions, PopShare, exp_ce);
    fprintf('  [Probe 2] Core13Scale = %.4f -> Full15 Stage-3 Nat Delta CE = %+6.2f%% (LTFM: %+6.2f%%)\n', ...
        s_2, ce_2, ce_2 + LTFM_Offset);
    Core13Scale_Cal = max(0.10, min(1.00, s_2 + (Target_Full15_Raw - ce_2) * (s_2 - s_1) / (ce_2 - ce_1)));
else
    Core13Scale_Cal = s_1;
end
fprintf('  ==> LOCKED Core13Scale_Cal = %.4f (Shocks #14-#16 at ShockScale = 1.0000)\n', Core13Scale_Cal);

%% 3. SOLVE ALL 8 BRANCHES DIRECTLY FROM Apply_Coalition_2024_Shocks
Branch_Specs = {
    'AustOnly',    'austerity_landlord_only', 'hybrid',              '1. Austerity + Landlord + Teacher/KS Squeeze (#1-#8, #12-#13)';
    'GrowthOnly',  'pro_growth_only',         'hybrid',              '2. Pro-Growth Levers Only (#9 Tax Cut, #10 AIP Visa, #11 Inv Boost)';
    'Coalition13', 'first_13_shocks',         'hybrid',              '3. First 13 Shocks Combined (#1-#13)';
    'Shock14_3W',  'rates_cap_3_waters',      'hybrid',              '4. Shock #14 Only: 3 Waters Repeal & Council Rates Wedge';
    'Shock15_Civ', 'arts_and_civic_cuts',     'hybrid',              '5. Shock #15 Only: Vote Arts/Sport & WCC Civic Squeeze';
    'Full15',      'all_but_ndc',             'hybrid',              '6. All 15 Domestic Shocks Combined (#1-#15)';
    'NDC_Hybrid',  'ndc',                     'hybrid',              '7. Shock #16 Only: Paris NDC1/2 + EV Rollback (Hybrid)';
    'Full16_Pay',  'full_16_shocks',          'offshore_pay',        '8. Full 16 Shocks: Offshore Article 6 Payment Mode';
    'Full16_Def',  'full_16_shocks',          'default_fta_penalty', '9. Full 16 Shocks: NDC Default & EU-FTA Penalty Mode';
    'Full16_Hyb',  'full_16_shocks',          'hybrid',              '10. Full 16 Shocks: Hybrid 50/50 Settlement Mode'
    };

N_branches        = size(Branch_Specs, 1);
Opts_Cal          = struct('ShockScale', 1.0, 'Core13Scale', Core13Scale_Cal);
CoalitionWelfare  = struct();
All_Rows_Raw      = zeros(3 * N_branches, N_reg + 1);
All_Row_Names     = cell(3 * N_branches, 1);
Summary_Stage3    = zeros(N_branches, N_reg + 1);

for b = 1:N_branches
    b_code   = Branch_Specs{b, 1};
    b_mode   = Branch_Specs{b, 2};
    ndc_mode = Branch_Specs{b, 3};
    b_label  = Branch_Specs{b, 4};

    Opts_Row                     = Opts_Cal;
    Opts_Row.NDC_Settlement_Mode = ndc_mode;

    [P_GE, piz_b, Meta_b, zg_b] = Apply_Coalition_2024_Shocks( ...
        Params_SS0_2023, pi_z_SS0_2023, b_mode, Opts_Row, z_grid_SS0_2023);

    fprintf('\n------------------------------------------------------------------------\n');
    fprintf(' Solving Branch %d/%d: %s\n', b, N_branches, b_label);
    fprintf('------------------------------------------------------------------------\n');
    tb = tic;

    % Stage 1: Short-Run PE (policy levers at SS0_2023 prices, z_grid, pi_z, & jDist)
    P_PE          = P_GE;
    P_PE.r        = Params_SS0_2023.r;
    P_PE.w_reg    = Params_SS0_2023.w_reg;
    P_PE.Q_reg    = Params_SS0_2023.Q_reg;
    P_PE.K_whanau = Params_SS0_2023.K_whanau;

    [V_PE_b, ~] = ValueFnIter_MixHorz_PType( ...
        n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid_SS0_2023, pi_z_SS0_2023, ...
        ReturnFn, P_PE, DiscountFactorParamNames, vfoptions);

    % Stage 2: Long-Run GE Prices, Firm z_grid & Layoff pi_z (at SS0_2023 jDist)
    [V_GE_b, Policy_GE_b] = ValueFnIter_MixHorz_PType( ...
        n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, zg_b, piz_b, ...
        ReturnFn, P_GE, DiscountFactorParamNames, vfoptions);

    % Stage 3: Endogenous 4x5 Intergenerational Steady State (reset from jDist_SS0_2023)
    jDist_b = jDist_SS0_2023;
    for ig_it = 1:12
        StatDist_b = StationaryDist_MixHorz_PType( ...
            jDist_b, AgeWeightsParamNames, PTypeDistParamNames, Policy_GE_b, ...
            n_d, n_a, n_z, N_j, Names_i, piz_b, P_GE, simoptions);
        [jDist_b_new, IG_Diag_b] = Build_IntergenTransitionMatrix( ...
            StatDist_b, Policy_GE_b, V_GE_b, ...
            n_d, n_a, n_z, d_grid, a_grid, zg_b, piz_b, P_GE, Regions);
        if max(abs(jDist_b_new.HH_Auckland(:) - jDist_b.HH_Auckland(:))) < 1e-5
            jDist_b = jDist_b_new;
            break;
        end
        jDist_b = jDist_b_new;
    end

    CE_Stage = compute_3stage_ce(V_SS0_2023, V_PE_b, V_GE_b, jDist_SS0_2023, jDist_b, Regions, exp_ce);
    Nat_Col  = CE_Stage * PopShare(:);

    rows_b = (3*(b-1)+1) : (3*b);
    All_Rows_Raw(rows_b, :)  = [CE_Stage, Nat_Col];
    Summary_Stage3(b, :)     = [CE_Stage(3, :), Nat_Col(3)];
    All_Row_Names{rows_b(1)} = sprintf('%s_1_ShortRun_PE', b_code);
    All_Row_Names{rows_b(2)} = sprintf('%s_2_LongRun_GE_ExoSkills', b_code);
    All_Row_Names{rows_b(3)} = sprintf('%s_3_LongRun_GE_EndoIntergen', b_code);

    print_ig_diag_block(b_label, IG_Diag_b, Regions, PopShare, Params.dt, Params.J);
    fprintf('Solved %s in %.1f s | Stage-3 Delta CE: %+6.2f%% (LTFM: %+6.2f%%) | Large (Wgtn) Delta CE: %+6.2f%%\n', ...
        b_code, toc(tb), Nat_Col(3), Nat_Col(3) + LTFM_Offset, CE_Stage(3, 3));

    CoalitionWelfare.(b_code) = struct('V_PE', V_PE_b, 'V_GE', V_GE_b, 'Policy_GE', Policy_GE_b, ...
        'StatDist', StatDist_b, 'jDist', jDist_b, 'IG_Diag', IG_Diag_b, 'Meta', Meta_b, 'CE_Pure', CE_Stage);
end

%% 4. PRINT & EXPORT SUMMARY TABLES + HEAD-TO-HEAD WELLINGTON INCIDENCE AUDIT
VarNames = {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct', 'National_CE_Pct'};
T_Coalition_AllStages = array2table(All_Rows_Raw,                   'RowNames', All_Row_Names,      'VariableNames', VarNames);
T_Stage3_Delta        = array2table(Summary_Stage3,                 'RowNames', Branch_Specs(:, 1), 'VariableNames', VarNames);
T_Stage3_LTFM         = array2table(Summary_Stage3 + LTFM_Offset,   'RowNames', Branch_Specs(:, 1), 'VariableNames', VarNames);

fprintf('\n=== FULL 3-STAGE DECOMPOSITION: RAW DELTA CE%% VS. SS0_2023 ===\n'); disp(T_Coalition_AllStages);
fprintf('\n=== STAGE-3 SUMMARY: RAW DELTA CE%% VS. SS0_2023 ===\n');            disp(T_Stage3_Delta);
fprintf('\n=== STAGE-3 SUMMARY: LTFM-ANCHORED CE%% (-16.21%% OFFSET) ===\n');   disp(T_Stage3_LTFM);

ce13_row    = Summary_Stage3(3, :);
ce15_row    = Summary_Stage3(6, :);
ce16_row    = Summary_Stage3(10, :);
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

writetable(T_Coalition_AllStages, fullfile(OutputDir, 'Table_Coalition_AllStages_Calibrated_SS0_2023.csv'), 'WriteRowNames', true);
writetable(T_Stage3_Delta,        fullfile(OutputDir, 'Table_Coalition_Stage3_Calibrated_Delta.csv'),       'WriteRowNames', true);
writetable(T_Stage3_LTFM,         fullfile(OutputDir, 'Table_Coalition_Stage3_Calibrated_LTFM.csv'),        'WriteRowNames', true);
save(fullfile(OutputDir, 'Coalition_MixHorz_Welfare_Calibrated.mat'), ...
    'CoalitionWelfare', 'Core13Scale_Cal', 'T_Coalition_AllStages', 'T_Stage3_Delta', 'T_Stage3_LTFM', 'IG_Diag_SS0_2023');

%% LOCAL HELPERS (EVALUATION & PRINTING ONLY — ZERO PARAMETER PATCHING)
function nat_ce3 = eval_stage3_nat(b_mode, opts, P0, piz0, zg0, V0, jDist0, ...
    n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ReturnFn, DiscNames, AgeNames, PTypeNames, vfopt, simopt, Regions, PopShare, exp_ce)
[P_GE, piz_b, ~, zg_b] = Apply_Coalition_2024_Shocks(P0, piz0, b_mode, opts, zg0);
[V_GE_b, Pol_GE_b]     = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, zg_b, piz_b, ReturnFn, P_GE, DiscNames, vfopt);
jDist_b = jDist0;
for ig_it = 1:12
    StatDist_b = StationaryDist_MixHorz_PType(jDist_b, AgeNames, PTypeNames, Pol_GE_b, n_d, n_a, n_z, N_j, Names_i, piz_b, P_GE, simopt);
    [jDist_new, ~] = Build_IntergenTransitionMatrix(StatDist_b, Pol_GE_b, V_GE_b, n_d, n_a, n_z, d_grid, a_grid, zg_b, piz_b, P_GE, Regions);
    if max(abs(jDist_new.HH_Auckland(:) - jDist_b.HH_Auckland(:))) < 1e-5, jDist_b = jDist_new; break; end
    jDist_b = jDist_new;
end
CE_Stage = compute_3stage_ce(V0, V_GE_b, V_GE_b, jDist0, jDist_b, Regions, exp_ce);
nat_ce3  = CE_Stage(3, :) * PopShare(:);
end

function CE_Stage = compute_3stage_ce(V0, Vpe, Vge, jDist0, jDistB, Regions, exp_ce)
CE_Stage = zeros(3, numel(Regions));
for r_idx = 1:numel(Regions)
    hh_type = ['HH_', Regions{r_idx}];
    d0_j1   = double(gather(jDist0.(hh_type)(:)));
    db_j1   = double(gather(jDistB.(hh_type)(:)));
    N_st    = numel(d0_j1);
    V0_j1   = reshape(double(gather(V0.(hh_type))),  N_st, []); V0_j1  = V0_j1(:, 1);
    Vpe_j1  = reshape(double(gather(Vpe.(hh_type))), N_st, []); Vpe_j1 = Vpe_j1(:, 1);
    Vge_j1  = reshape(double(gather(Vge.(hh_type))), N_st, []); Vge_j1 = Vge_j1(:, 1);
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

function print_ig_diag_block(TitleStr, IG_D, Regions, PopShares, dt, J)
fprintf('\n=== 4-REGION + ABROAD STEADY-STATE DIAGNOSTICS: %s (dt = %d yr, J = %d) ===\n', TitleStr, dt, J);
for k = 1:numel(Regions)
    reg = Regions{k};
    fprintf('Region: %-9s (Pop %4.1f%%) | Stage-1 Skill: %.3f | Completed Skill: %.3f | Struggling: %4.1f%% | Mean Bequest: %.3f | Emig: %4.1f%%\n', ...
        reg, 100*PopShares(k), IG_D.MeanTheta2.(reg), IG_D.MeanTheta3.(reg), ...
        100*IG_D.StrugglingShare.(reg), IG_D.MeanBequest.(reg), 100*IG_D.EmigRate.(reg));
end
end
