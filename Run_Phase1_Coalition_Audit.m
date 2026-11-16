%% RUN_PHASE1_COALITION_AUDIT.M (Phase 1: historic_096, dt = 3, J = 27)

if ~exist('Discount_Regime_Override', 'var') || isempty(Discount_Regime_Override)
    Discount_Regime_Override = 'launch_0980'; % 'historic_096' (Phase 1) | 'launch_0980' (Phase 2)
end
clearvars -except Discount_Regime_Override; clc;

Params.dt              = 3;
Params.Discount_Regime = Discount_Regime_Override;
Params = Configure_TimeGrid_Params(Params);
NZ_4Region_Master; % Inherits Params.Discount_Regime = 'launch_0980' (beta_hh = 0.980^dt, beta_firm = 0.975^dt)

% Step 1: Initialize Single Source of Truth at dt = 3 & Historic Discounting
Params = struct('dt', 3, 'Discount_Regime', 'historic_096');
Params = Configure_TimeGrid_Params(Params, 3);

% Initialize baseline grids, ReturnFn, jequaloneDist, and pi_z
% (Ensure NZ_4Region_Master respects Params.dt = 3 and doesn't clear Params!)
NZ_4Region_Master;
Params = Configure_TimeGrid_Params(Params, 3); % Re-assert SSOT fields if Master overwrote any

% Step 2: Re-Anchor to Pre-Coalition Late-2023 Baseline (SS0_2023)
[Params_SS0_2023, pi_z_SS0_2023, Meta_SS0_2023] = ...
    Apply_Coalition_2024_Shocks(Params, pi_z, 'reanchor_2023');

% Step 3: Generate All Phase-1 Shock Bundles from (Params_SS0_2023, pi_z_SS0_2023)
Modes = { ...
    'reanchor_2023',           'SS0_2023',   struct(); ...
    'austerity_landlord_only', 'AustOnly',   struct(); ...
    'pro_growth_only',         'GrowthOnly', struct(); ...
    'coalition_13_shocks',     'Full13',     struct(); ...
    'rates_cap_3_waters',      'Shock14',    struct(); ...
    'arts_and_civic_cuts',     'Shock15',    struct(); ...
    'all_but_ndc',             'All15',      struct(); ...
    'ndc',                     'NDC_Hybrid', struct('NDC_Settlement_Mode', 'hybrid'); ...
    'full_16_shocks',          'Full16_Pay', struct('NDC_Settlement_Mode', 'offshore_pay'); ...
    'full_16_shocks',          'Full16_Def', struct('NDC_Settlement_Mode', 'default_fta_penalty'); ...
    'full_16_shocks',          'Full16_Hyb', struct('NDC_Settlement_Mode', 'hybrid')};

nM = size(Modes, 1);
Bundle = struct();

% Pre-allocate summary vectors for fast CPU inspection BEFORE full VFI solves
Tag_Col      = Modes(:, 2);
Debt_Pct     = zeros(nM, 1);
Q_Akl        = zeros(nM, 1);
Ups_Lge_Pct  = zeros(nM, 1);
G1_Eff_Akl   = zeros(nM, 1);
Zh_Lge       = zeros(nM, 1);
Zh_Rur       = zeros(nM, 1);
Ebar_Rur     = zeros(nM, 1);
Strug_NatPct = zeros(nM, 1);
Emig_NatPct  = zeros(nM, 1);
Coh_St       = zeros(nM, 1);
Coh_Lge      = zeros(nM, 1);
TI_CPI       = zeros(nM, 1);

for m = 1:nM
    mode_str = Modes{m, 1};
    tag_str  = Modes{m, 2};
    opt_in   = Modes{m, 3};

    if m == 1
        Pm = Params_SS0_2023; pim = pi_z_SS0_2023; Mm = Meta_SS0_2023;
    else
        [Pm, pim, Mm] = Apply_Coalition_2024_Shocks(Params_SS0_2023, pi_z_SS0_2023, mode_str, opt_in);
    end

    Bundle.(tag_str).Params = Pm;
    Bundle.(tag_str).pi_z   = pim;
    Bundle.(tag_str).Meta   = Mm;

    Debt_Pct(m)     = 100 * Pm.Debt_to_GDP_Init;
    Q_Akl(m)        = Pm.Q_reg.HH_Auckland;
    Ups_Lge_Pct(m)  = 100 * Pm.upsilon_h_reg.HH_Large;
    G1_Eff_Akl(m)   = Pm.G_ECE_1_eff.HH_Auckland;
    Zh_Lge(m)       = Pm.z_f_grid.Firm_Large(2);
    Zh_Rur(m)       = Pm.z_f_grid.Firm_Rural(2);
    Ebar_Rur(m)     = Pm.ebar_energy.HH_Rural;
    Strug_NatPct(m) = 100 * Mm.Frac_Struggling_Imputed;
    Emig_NatPct(m)  = 100 * Mm.Emig_Nat_Imputed;
    Coh_St(m)       = Mm.Social_Cohesion_St;
    Coh_Lge(m)      = Mm.Cohesion_St_By_PType.HH_Large;
    TI_CPI(m)       = Mm.TI_Social_Credit_CPI;
end

% Export canonical workspace variables for VFI / 3-Way Decomposition solvers
Params_AustOnly = Bundle.AustOnly.Params; pi_z_AustOnly = Bundle.AustOnly.pi_z; Meta_AustOnly = Bundle.AustOnly.Meta;
Params_Full13   = Bundle.Full13.Params;   pi_z_Full13   = Bundle.Full13.pi_z;   Meta_Full13   = Bundle.Full13.Meta;
Params_Shock14  = Bundle.Shock14.Params;  pi_z_Shock14  = Bundle.Shock14.pi_z;  Meta_Shock14  = Bundle.Shock14.Meta;
Params_Shock15  = Bundle.Shock15.Params;  pi_z_Shock15  = Bundle.Shock15.pi_z;  Meta_Shock15  = Bundle.Shock15.Meta;
Params_All15    = Bundle.All15.Params;    pi_z_All15    = Bundle.All15.pi_z;    Meta_All15    = Bundle.All15.Meta;
Params_Full16   = Bundle.Full16_Hyb.Params; pi_z_Full16 = Bundle.Full16_Hyb.pi_z; Meta_Full16 = Bundle.Full16_Hyb.Meta;

T_Phase1_Params = table(Tag_Col, round(Debt_Pct,2), round(Q_Akl,3), round(Ups_Lge_Pct,2), ...
    round(G1_Eff_Akl,4), round(Zh_Lge,4), round(Zh_Rur,4), round(Ebar_Rur,4), ...
    round(Strug_NatPct,2), round(Emig_NatPct,2), round(Coh_St,2), round(Coh_Lge,2), round(TI_CPI,2), ...
    'VariableNames', {'Regime', 'Debt_GDP', 'Q_Akl', 'Ups_Lge_Pct', 'G1_Eff_Akl', ...
    'Zh_Lge', 'Zh_Rur', 'Ebar_Rur', 'Strug_Pct', 'Emig_Pct', 'Coh_Nat', 'Coh_WCC', 'TI_CPI'});
disp('=== PHASE 1 (historic_096): 11-REGIME PARAMETER & COHESION AUDIT ===');
disp(T_Phase1_Params);