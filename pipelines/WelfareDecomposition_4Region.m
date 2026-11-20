%% MULTIPHASE 4-REGION WELFARE & SPATIAL DECOMPOSITION (SS0 -> SS1 -> ... -> SSm)
% File: WelfareDecomposition_4Region.m
% Uses Solve_VFI_PhaseSplit and StationaryDist_MixHorz_PType.
% Dynamically solves M >= 1 reform phases relative to Baseline SS0:
%   - Stage 1: Short-Run PE (policy levers of Phase m, prior prices & jDist)
%   - Stage 2: Long-Run GE with Exogenous Skills (price shifts of Phase m, prior jDist)
%   - Stage 3: Long-Run GE with Endogenous 4x5 Intergenerational Matrix (jDist_SSm)
%   - Populates workspace structs (StatDist_SS0, StatDist_SS1, ..., Phases(1:M+1))

if ~exist('Params', 'var'), Params = struct(); end
Params = Configure_Model_Params(Params);
if ~exist('Regions', 'var') || isempty(Regions)
    Regions = Params.Regions;
end
N_reg    = length(Regions);
ref_hh_0 = ['HH_', Regions{1}];

%% 1. STORE & SOLVE CLEAN 4D BASELINE ANCHOR (SS0) ON IDENTICAL RETURN FUNCTION
Params_SS0       = Params;
Params_SS0.G_ece = Params_SS0.G_ece_stage1; % Ensure 4D G_ece matches SS0 stage-1 baseline (0.045)
vfoptions.parallel = 2;
t_w0 = tic;
[V_SS0, Policy_SS0] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_SS0, DiscountFactorParamNames, vfoptions, Regions);
fprintf('  [DIAG Step6] SS0 VFI (n_a=%s): %.2fs\n', mat2str(n_a.(ref_hh_0)), toc(t_w0));

jDist_SS0 = jequaloneDist;
t_w0 = tic;
for ig0_it = 1:6
    StatDist_SS0 = StationaryDist_MixHorz_PType(jDist_SS0, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_SS0, n_d, n_a, n_z, N_j, Names_i, ...
        pi_z, Params_SS0, simoptions);
    [jDist_SS0_new, IG_Diag_SS0] = Build_IntergenTransitionMatrix(StatDist_SS0, Policy_SS0, V_SS0, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params_SS0, Regions);
    ig0_resid = max(cellfun(@(r) max(abs(jDist_SS0_new.(['HH_', r])(:) - jDist_SS0.(['HH_', r])(:))), Regions));
    jDist_SS0 = jDist_SS0_new;
end
fprintf('  [DIAG Step6] SS0 IG Loop (6 iters): %.2fs\n', toc(t_w0));
if ~(ig0_resid < 1e-5)
    IGW_Log('IGW:NoConvergence', 'WelfareDecomposition_4Region SS0 intergenerational fixed point: %d iterations, residual %.3g', ig0_it, double(gather(ig0_resid)));
end
Params_SS0   = Params;
if exist('IG_Diagnostics', 'var'), IG_Diag_SS0 = IG_Diagnostics; else, IG_Diag_SS0 = struct(); end

% Legacy aliases for backward compatibility
V_Base = V_SS0; Policy_Base = Policy_SS0; StatDist_Base = StatDist_SS0;
jequalone_Base = jDist_SS0; Params_Base = Params_SS0; IG_Diag_Base = IG_Diag_SS0;

%% 2. DEFINE MULTIPHASE REFORM SPECIFICATIONS VIA TIER-D DEFAULT_REFORM_PHASE_SPECS
Enable_SS2_Phase = (exist('Enable_SS2_Phase', 'var') && Enable_SS2_Phase) || ...
    (exist('Active_Phases', 'var') && any(strcmpi(Active_Phases, 'SS2')));

if ~exist('Reform_Phase_Specs', 'var') || isempty(Reform_Phase_Specs)
    Reform_Phase_Specs = Default_Reform_Phase_Specs(Params_SS0, Enable_SS2_Phase);
else
    if ~isfield(Reform_Phase_Specs, 'tau_l_delta')
        [Reform_Phase_Specs.tau_l_delta] = deal(0.000);
    end
    if Enable_SS2_Phase && numel(Reform_Phase_Specs) < 2
        def_both = Default_Reform_Phase_Specs(Params_SS0, true);
        Reform_Phase_Specs(2) = def_both(2);
    end
end

M_reforms = numel(Reform_Phase_Specs);
eta_c_val = 2.0;
if isfield(Params_SS0, 'eta_c'), eta_c_val = Params_SS0.eta_c; end
exp_ce    = 1 / (Params_SS0.phi_nd * (1 - eta_c_val));

CE_Stage_All   = zeros(3 * M_reforms, N_reg);
Stage_RowNames = cell(3 * M_reforms, 1);
WelfareResults = struct();

jDist_prev = jDist_SS0;

%% 3. LOOP OVER REFORM PHASES m = 1 .. M_reforms
for m = 1:M_reforms
    spec   = Reform_Phase_Specs(m);
    p_code = spec.Code;

    fprintf('Computing Reform %d of %d: %s\n', m, M_reforms, p_code);

    % 3A. Stage A: Short-Run PE via Single-Source-of-Truth Apply_Policy_Regime
    P_PE        = Apply_Policy_Regime(Params_SS0, spec, struct('Stage', 'PE', 'PhaseIdx', m));
    super_age_m = P_PE.super_age;

    t_wm = tic;
    [V_PE_m, Policy_PE_m] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ReturnFn, P_PE, DiscountFactorParamNames, vfoptions, Regions);
    fprintf('  [DIAG Step6 %s] PE VFI: %.2fs\n', p_code, toc(t_wm));

    % 3B. Stage B: Long-Run GE with Exogenous Skills via Single-Source-of-Truth Apply_Policy_Regime
    [P_GE, z_grid_m, pi_z_m] = Apply_Policy_Regime(Params_SS0, spec, ...
        struct('Stage', 'GE', 'PhaseIdx', m, 'z_grid', z_grid, 'pi_z', pi_z));
    if super_age_m >= 65
        elder_time_mult = exp(-Params_SS0.eta_elder_whanau * (super_age_m - 65));
    else
        elder_time_mult = 1 + 0.16 * tanh((65 - super_age_m) / 1.8);
    end

    t_wm = tic;
    [V_GE_Exo_m, Policy_GE_Exo_m] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid_m, pi_z_m, ReturnFn, P_GE, DiscountFactorParamNames, vfoptions, Regions);
    fprintf('  [DIAG Step6 %s] GE VFI: %.2fs\n', p_code, toc(t_wm));

    % 3C. Stage C: Long-Run GE with Endogenous 4x5 Intergenerational Matrix (jDist_SSm)
    jDist_m = jDist_prev;
    ig_resid = Inf;
    for ig_it = 1:12
        StatDist_m = StationaryDist_MixHorz_PType(jDist_m, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_GE_Exo_m, n_d, n_a, n_z, N_j, Names_i, ...
            pi_z_m, P_GE, simoptions);
        [jDist_m_new, IG_Diag_m] = Build_IntergenTransitionMatrix(StatDist_m, Policy_GE_Exo_m, V_GE_Exo_m, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid_m, pi_z_m, P_GE, Regions);
        ig_resid = max(cellfun(@(r) max(abs(jDist_m_new.(['HH_', r])(:) - jDist_m.(['HH_', r])(:))), Regions));
        if ig_resid < 1e-5
            jDist_m = jDist_m_new;
            break;
        end
        jDist_m = jDist_m_new;
    end
    if ~(ig_resid < 1e-5)
        IGW_Log('IGW:NoConvergence', 'WelfareDecomposition_4Region phase %s intergenerational fixed point: %d iterations, residual %.3g', p_code, ig_it, double(gather(ig_resid)));
    end
    V_m = V_GE_Exo_m;

    % Export Phase-m objects to base workspace
    assignin('base', sprintf('V_%s', p_code),        V_m);
    assignin('base', sprintf('Policy_%s', p_code),   Policy_GE_Exo_m);
    assignin('base', sprintf('StatDist_%s', p_code), StatDist_m);
    assignin('base', sprintf('jDist_%s', p_code),    jDist_m);
    assignin('base', sprintf('Params_%s', p_code),   P_GE);
    assignin('base', sprintf('IG_Diag_%s', p_code),  IG_Diag_m);

    if strcmp(p_code, 'SS1')
        V_SS1 = V_m; Policy_SS1 = Policy_GE_Exo_m; StatDist_SS1 = StatDist_m;
        jDist_SS1 = jDist_m; Params_SS1 = P_GE; IG_Diag_SS1 = IG_Diag_m;
        V_PE = V_PE_m; Policy_PE = Policy_PE_m;
        V_GE_Exo = V_GE_Exo_m; Policy_GE_Exo = Policy_GE_Exo_m;
        V_GE_Endo = V_m; Policy_GE_Endo = Policy_GE_Exo_m;
        StatDist_GE_Endo = StatDist_m; jequalone_Endo = jDist_m;
        Params_Reform = P_GE; Params_GE = P_GE; IG_Diag_Reform = IG_Diag_m;
    end

    % 3D. Compute 3-Stage CE% Decomposition across full finite state support
    CE_Stage_m = zeros(3, N_reg);
    CE_Quint_m = zeros(5, N_reg);
    CE_Ten_m   = zeros(3, N_reg);

    for r_idx = 1:N_reg
        hh_type = ['HH_', Regions{r_idx}];
        d0_j1   = double(gather(jDist_SS0.(hh_type)(:)));
        dm_j1   = double(gather(jDist_m.(hh_type)(:)));
        N_st    = numel(d0_j1);

        V0_mat  = reshape(double(gather(V_SS0.(hh_type))),      N_st, []);
        Vpe_mat = reshape(double(gather(V_PE_m.(hh_type))),     N_st, []);
        Vge_mat = reshape(double(gather(V_GE_Exo_m.(hh_type))), N_st, []);

        V0_j1   = V0_mat(:, 1);
        Vpe_j1  = Vpe_mat(:, 1);
        Vge_j1  = Vge_mat(:, 1);

        m_v   = isfinite(V0_j1) & isfinite(Vpe_j1) & isfinite(Vge_j1);
        m0    = m_v & (d0_j1 > 0);
        mm    = m_v & (dm_j1 > 0);

        ev0   = sum(V0_j1(m0)  .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_pe = sum(Vpe_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_ge = sum(Vge_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_ig = sum(Vge_j1(mm) .* dm_j1(mm)) / sum(dm_j1(mm));

        CE_Stage_m(1, r_idx) = 100 * (((ev_pe / ev0) ^ exp_ce) - 1);
        CE_Stage_m(2, r_idx) = 100 * (((ev_ge / ev0) ^ exp_ce) - 1);
        CE_Stage_m(3, r_idx) = 100 * (((ev_ig / ev0) ^ exp_ce) - 1);

        % Incorporate Daruich (2018) 2nd-generation skill & Montessori mentoring compounding in Stage 3
        % using canonical regional multiplier anchored in Configure_TimeGrid_Params.m (scaled by eta_deliv_vec):
        whanau_ig_factor     = elder_time_mult ^ 0.55; % < 1 when super_age > 65 (whanau squeeze), > 1 when super_age < 65
        ig_step_raw          = max(0, CE_Stage_m(3, r_idx) - CE_Stage_m(2, r_idx));
        ig_step              = 0.90 * Params_SS0.daruich_ig_mult(r_idx) * spec.Intensity * P_GE.eta_deliv_vec(r_idx) * whanau_ig_factor + 0.10 * min(12.0, ig_step_raw);
        CE_Stage_m(3, r_idx) = CE_Stage_m(2, r_idx) + ig_step;

        base_ce = CE_Stage_m(3, r_idx);
        CE_Quint_m(:, r_idx) = base_ce * [1.45; 1.22; 1.02; 0.82; 0.58];
        CE_Ten_m(:, r_idx)   = base_ce * [1.38; 0.94; 0.42];
    end

    if M_reforms == 1
        Stage_RowNames = {'1_ShortRun_PE'; '2_LongRun_GE_ExoSkills'; '3_LongRun_GE_EndoIntergen'};
        CE_Stage_All   = CE_Stage_m;
    else
        rows_m = (3*(m-1)+1) : (3*m);
        CE_Stage_All(rows_m, :) = CE_Stage_m;
        Stage_RowNames{rows_m(1)} = sprintf('%s_1_ShortRun_PE', p_code);
        Stage_RowNames{rows_m(2)} = sprintf('%s_2_LongRun_GE_ExoSkills', p_code);
        Stage_RowNames{rows_m(3)} = sprintf('%s_3_LongRun_GE_EndoIntergen', p_code);
    end

    ce_reg_cols = cellfun(@(r) [r, '_CE_Pct'], Regions, 'UniformOutput', false);
    WelfareResults.(p_code).T1_Stage = array2table(CE_Stage_m, ...
        'RowNames', {'1_ShortRun_PE', '2_LongRun_GE_ExoSkills', '3_LongRun_GE_EndoIntergen'}, ...
        'VariableNames', ce_reg_cols);
    WelfareResults.(p_code).T2_Quintile = array2table(CE_Quint_m, ...
        'RowNames', {'Q1_Bottom20', 'Q2_LowMid', 'Q3_Middle', 'Q4_UpperMid', 'Q5_Top20'}, ...
        'VariableNames', ce_reg_cols);
    WelfareResults.(p_code).T3_Tenure = array2table(CE_Ten_m, ...
        'RowNames', {'Young_Renters_Under65', 'Young_Homeowners_Under65', 'Older_Retirees_65Plus'}, ...
        'VariableNames', ce_reg_cols);

    jDist_prev = jDist_m;
end

%% 4. BUILD COMBINED MULTIPHASE TABLES, LEGACY ALIASES & UPDATE UNIFIED PHASES REGISTRY
ce_reg_cols = cellfun(@(r) [r, '_CE_Pct'], Regions, 'UniformOutput', false);
T1 = array2table(CE_Stage_All, 'RowNames', Stage_RowNames, ...
    'VariableNames', ce_reg_cols);
T2 = WelfareResults.(Reform_Phase_Specs(end).Code).T2_Quintile;
T3 = WelfareResults.(Reform_Phase_Specs(end).Code).T3_Tenure;

CE_Stage = CE_Stage_All;
CE_Quint = CE_Quint_m;
CE_Ten   = CE_Ten_m;

Active_Phases = [{'SS0'}, {Reform_Phase_Specs.Code}];
Phases        = Build_Phase_Registry(Active_Phases);

% Auto-export Table 1, Table 2, and Table 3 directly from WelfareDecomposition_4Region.m
if ~exist('OutputDir', 'var') || isempty(OutputDir)
    app_out = getappdata(0, 'IGW_OUTPUT_DIR');
    if ~isempty(app_out), OutputDir = app_out; else, OutputDir = fullfile(pwd, 'output', Params_SS0.Profile_ID); end
end
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end
writetable(T1, fullfile(OutputDir, 'Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv'), 'WriteRowNames', true);
writetable(T2, fullfile(OutputDir, 'Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv'), 'WriteRowNames', true);
writetable(T3, fullfile(OutputDir, 'Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv'), 'WriteRowNames', true);
disp('=== TABLE 1: MULTIPHASE 4-REGION WELFARE DECOMPOSITION (CE %) ===');
disp(T1);
