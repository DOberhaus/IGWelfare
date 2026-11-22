%% MODULAR POLICY COMPOSITION & ADDITIONALITY SUITE (CONVENTION-2 COMMITMENT ALGEBRA)
% File: pipelines/Run_Policy_Composition_Suite.m
% Orchestrates full 5D Phase-Split VFI + 4x5 Endogenous Intergenerational solving
% across standalone and composed domestic/civic commitment bundles on the canonical
% 4-tier parameter pipeline (dt = 3, beta_hh = 0.980^dt, beta_firm = 0.9815^dt).

if ~exist('Params', 'var') || ~isstruct(Params)
    Params = struct();
end
if ~isfield(Params, 'dt') || isempty(Params.dt)
    Params.dt = 3;
end
[Params, Regions] = Ensure_Workbench_Initialized(Params, struct('RequireWorkerPool', true));
OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
Skip_Baseline_Solve = true;
run(which('NZ_4Region_Master.m'));

BaseState = struct( ...
    'Params', Params, 'Regions', {Regions}, ...
    'n_d', n_d, 'n_a', n_a, 'n_z', n_z, 'N_j', N_j, ...
    'd_grid', d_grid, 'a_grid', a_grid, 'z_grid', z_grid, 'pi_z', pi_z, ...
    'ReturnFn', ReturnFn, 'DiscountFactorParamNames', {DiscountFactorParamNames}, ...
    'jequaloneDist', jequaloneDist, 'vfoptions', vfoptions, 'simoptions', simoptions);

% 2. Calibrate Core13Scale so Domestic_15 matches -5.64% raw Delta CE (-21.85% LTFM) & solve all 7 bundles
CompOpts = struct('Verbose', true, 'Calibrate_Domestic15_Target_CE', -5.6412);
CompositionOut = Compute_Policy_Composition_Batch(BaseState, [], CompOpts);

fprintf('\n=== STAGE-3 ENDOGENOUS INTERGENERATIONAL DELTA CE%% VS. BASELINE_2023 ===\n');
disp(CompositionOut.Table_Stage3_Delta);

fprintf('\n=== COMPOSITIONAL INTERACTION WEDGES (ADDITIVE SUM VS. SOLVED EQUILIBRIUM) ===\n');
if isfield(CompositionOut.Additionality, 'WedgeTable')
    disp(CompositionOut.Additionality.WedgeTable);
end

% 3. Export CSVs & 4-Panel Divergence Dashboard into OutputDir
writetable(CompositionOut.Table_AllStages,    fullfile(OutputDir, 'Table_Coalition_AllStages_Calibrated_SS0_2023.csv'), 'WriteRowNames', true);
writetable(CompositionOut.Table_Stage3_Delta, fullfile(OutputDir, 'Table_Coalition_Stage3_Calibrated_Delta.csv'),       'WriteRowNames', true);
writetable(CompositionOut.Table_Stage3_LTFM,  fullfile(OutputDir, 'Table_Coalition_Stage3_Calibrated_LTFM.csv'),        'WriteRowNames', true);

DivOut = Plot_Coalition2024_vs_LTFM_Divergence(Params, CompositionOut);
