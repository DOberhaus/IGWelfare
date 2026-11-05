%% RUN_COALITION_2023_TO_2026_BRANCH.M
% Evaluates:
%   1. SS0_2023      : Pre-Coalition HYEFU 2023 Baseline
%   2. SS1_Coalition : 2024-2026 Coalition Austerity + Landlord Tax Break Shock
%   3. SS1_Reform    : Foiling Aotearoa (ECE + Mentoring + Youth Grant + Use-It-or-Lose-It tau_a)

clear; clc;
Params.dt = 5;
Params = Configure_TimeGrid_Params(Params);
NZ_4Region_Master; % Initializes grids, baseline Params, pi_z, ReturnFn, jequaloneDist

% 1. Construct 2023 Baseline (SS0_2023)
[Params_SS0_2023, pi_z_SS0_2023] = Apply_Coalition_2024_Shocks(Params, pi_z, 'reanchor_2023');

% 2. Construct 2024-2026 Coalition Shock State (SS1_Coalition)
ShockOpts = struct('ShockScale', 1.0);
[Params_SS1_Coalition, pi_z_SS1_Coalition, ShockMeta] = Apply_Coalition_2024_Shocks( ...
    Params_SS0_2023, pi_z_SS0_2023, 'apply_coalition_shocks', ShockOpts);

% 3. Solve Both Steady States & Transition Path via TransPath_4Region_Master
% (Or register in Build_Phase_Registry.m as Phase 1 = SS0_2023, Phase 2 = SS1_Coalition)
