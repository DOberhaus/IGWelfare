%% RUN_COALITION_3WAY_DECOMPOSITION.M
% Evaluates the 3-Way Decomposition of the 2024-2026 Coalition Policy Vector
% relative to the 2023 LTFM Baseline (SS0_2023) and Foiling Aotearoa (SS1->SS2).

clear; clc;
Params.dt = 3;
Params = Configure_TimeGrid_Params(Params);
NZ_4Region_Master; % Initializes baseline grids, Params, pi_z, ReturnFn

% 1. Baseline 2023 Pre-Coalition State (SS0_2023)
[Params_SS0_2023, pi_z_SS0_2023, Meta_SS0] = Apply_Coalition_2024_Shocks( ...
    Params, pi_z, 'reanchor_2023');

% 2. Branch 1: Austerity + Landlord Tax Break + Teacher/KiwiSaver Squeeze Only (#1-#8, #12-#13)
[Params_AustOnly, pi_z_AustOnly, Meta_Aust] = Apply_Coalition_2024_Shocks( ...
    Params_SS0_2023, pi_z_SS0_2023, 'austerity_landlord_only');

% 3. Branch 2: Coalition "Pro-Growth" Levers Only (#9 Income Tax Cut, #10 AIP Visa, #11 20% Inv Boost)
[Params_GrowthOnly, pi_z_GrowthOnly, Meta_Growth] = Apply_Coalition_2024_Shocks( ...
    Params_SS0_2023, pi_z_SS0_2023, 'pro_growth_only');

% 4. Branch 3: Full 13-Shock Coalition Package (#1-#13 Combined)
[Params_Full13, pi_z_Full13, Meta_Full13] = Apply_Coalition_2024_Shocks( ...
    Params_SS0_2023, pi_z_SS0_2023, 'full_13_shocks');

fprintf('\n=== 13-SHOCK PARAMETER VERIFICATION (AUCKLAND & NATIONAL) ===\n');
fprintf('State                    | tau_l  | tau_k  | Q_Akl | G_ECE1_eff(Akl) | z_h(Akl) | YouthGrant\n');
fprintf('-------------------------+--------+--------+-------+-----------------+----------+-----------\n');
fprintf('0. SS0_2023 (Baseline)   | %.3f  | %.3f  | %.2f  |     %.4f      |  %.3f   |   %.4f\n', ...
    Params_SS0_2023.tau_l, Params_SS0_2023.tau_k, Params_SS0_2023.Q_reg.HH_Auckland, ...
    Params_SS0_2023.G_ECE_1_eff.HH_Auckland, Params_SS0_2023.z_f_Auckland(2), Params_SS0_2023.YouthGrant);
fprintf('1. Austerity+Landlord    | %.3f  | %.3f  | %.2f  |     %.4f      |  %.3f   |   %.4f\n', ...
    Params_AustOnly.tau_l, Params_AustOnly.tau_k, Params_AustOnly.Q_reg.HH_Auckland, ...
    Params_AustOnly.G_ECE_1_eff.HH_Auckland, Params_AustOnly.z_f_Auckland(2), Params_AustOnly.YouthGrant);
fprintf('2. Pro-Growth Levers Only| %.3f  | %.3f  | %.2f  |     %.4f      |  %.3f   |   %.4f\n', ...
    Params_GrowthOnly.tau_l, Params_GrowthOnly.tau_k, Params_GrowthOnly.Q_reg.HH_Auckland, ...
    Params_GrowthOnly.G_ECE_1_eff.HH_Auckland, Params_GrowthOnly.z_f_Auckland(2), Params_GrowthOnly.YouthGrant);
fprintf('3. Full 13-Shock Package | %.3f  | %.3f  | %.2f  |     %.4f      |  %.3f   |   %.4f\n', ...
    Params_Full13.tau_l, Params_Full13.tau_k, Params_Full13.Q_reg.HH_Auckland, ...
    Params_Full13.G_ECE_1_eff.HH_Auckland, Params_Full13.z_f_Auckland(2), Params_Full13.YouthGrant);
