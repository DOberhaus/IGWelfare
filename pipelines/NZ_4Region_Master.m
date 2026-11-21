%% NEW ZEALAND 4-REGION + ABROAD MASTER SCRIPT (EXPERIENCE-ASSET LIFECYCLE PIPELINE)
% File: NZ_4Region_Master.m
% Regions (k = 1, 2, 3, 4):
%   1. 'Rural'    : Rural & Primary Districts (16.0% HH, 15.0% Firm)
%   2. 'Small'    : Small/Medium Provincial Towns & Cities (24.0% HH, 23.0% Firm)
%   3. 'Large'    : Major Regional Metros - Wgtn, Chch, Hamilton, Tauranga, Dunedin (25.9% HH, 26.9% Firm)
%   4. 'Auckland' : Primate Metropolitan Agglomeration / "Paris" Analog (34.1% HH, 35.1% Firm)
% Horizons:
%   - Households ('HH_Rural', 'HH_Small', 'HH_Large', 'HH_Auckland'): Finite Horizon (J = 80/dt)
%   - Firms ('Firm_Rural', 'Firm_Small', 'Firm_Large', 'Firm_Auckland'): Infinite Horizon (N_j = Inf)

%% 0. TOOLKIT & GNU OCTAVE / UFHORZ ENVIRONMENT BOOTSTRAP
if exist('Ensure_Workbench_Initialized', 'file') == 0
    this_dir = fileparts(mfilename('fullpath'));
    cand_setup = fullfile(this_dir, '..', 'setup_igw_paths.m');
    if exist(cand_setup, 'file') == 2, run(cand_setup);
    elseif exist('setup_igw_paths.m', 'file') == 2, setup_igw_paths(true); end
end
if ~exist('Params', 'var'), Params = struct(); end
[Params, Regions, Reg_HH_Shares] = Ensure_Workbench_Initialized(Params, ...
    struct('RequireToolkit', true, 'RequireWorkerPool', true, 'ForceConfigure', true));

%% 1. DEFINE PERMANENT TYPES (N_reg REGIONS x 2 SECTORS FROM DATASPEC)
Regions = Params.Regions;
N_reg   = Params.N_reg;
Names_i = [cellfun(@(r) ['HH_',   r], Regions, 'UniformOutput', false), ...
           cellfun(@(r) ['Firm_', r], Regions, 'UniformOutput', false)];
PTypeDistParamNames = {'PTypeWeights'};

% Subnational Population & Business Demography Shares (from Layer 1 DataSpec)
Reg_HH_Shares   = Params.Pop_Weights_4(:);
Reg_Firm_Shares = Params.Firm_Weights_4(:);
Reg_Pop_Shares  = Reg_HH_Shares;
Params.PTypeWeights = [0.90 * Reg_HH_Shares; ...
    0.10 * Reg_Firm_Shares];

for r_idx = 1:N_reg
    reg = Regions{r_idx};
    N_j.(['HH_', reg])   = Params.J; % Finite horizon: Ages 20-99 (dt-yr periods, Jr at Age 65)
    N_j.(['Firm_', reg]) = Inf;      % Infinite horizon collateral-constrained firms
end

%% 2. TREASURY OLG DEMOGRAPHIC TRANSITION MATRIX (SCALED TO Params.J)
T_demo = zeros(Params.J, Params.J);
T_demo(1, :) = Params.fj * 0.5;
for jj = 1:(Params.J - 1)
    T_demo(jj+1, jj) = Params.sj(jj);
end
N_pop = ones(Params.J, 1) / Params.J;
for iter = 1:200
    N_pop = T_demo * N_pop + Params.mig_rate_j' .* N_pop;
    N_pop = max(0, N_pop) / sum(max(0, N_pop));
end
AgeWeightsParamNames = {'mewj'};
Params.mewj = N_pop';

%% 3. CONFIGURE GRIDS & ENABLE VFI TOOLKIT EXPERIENCE ASSET ACROSS 4 REGIONS
for r_idx = 1:N_reg
    hh_type   = ['HH_', Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];

    vfoptions.experienceasset.(hh_type)    = 1;
    Backend_NZ = Resolve_Compute_Backend();
    if Backend_NZ.IsOctave && (~isfield(vfoptions, 'lowmemory') || ~isfield(vfoptions.lowmemory, hh_type))
        vfoptions.lowmemory.(hh_type)      = 1;
    end
    simoptions.experienceasset.(hh_type)   = 1;
    vfoptions.experienceasset.(firm_type)  = 0;
    simoptions.experienceasset.(firm_type) = 0;

    % Decisions d: [d1 = l (Labor), d2 = Ih (Ben-Porath Training), d3 = ic (Experience Asset Decision LAST)]
    n_d.(hh_type)    = [4, 3, 7];
    d_grid_l         = [0; 0.5; 0.8; 1.0];
    d_grid_Ih        = linspace(0, 0.30, 3)';
    d_grid_ic        = 0.50 * (linspace(0, 1, 7).^1.8)'; % Convex power grid: [0, 0.0203, 0.0706, 0.1460, 0.2456, 0.3649, 0.5000]'
    d_grid.(hh_type) = [d_grid_l; d_grid_Ih; d_grid_ic];

    % Endogenous States a: [a1 = Net Worth (a), a2 = Adult HC (h), a3 = Skill Experience Asset (theta_c LAST)]
    n_a.(hh_type)    = [61, 7, 9];
    a_grid_assets    = 25 * (linspace(0, 1, n_a.(hh_type)(1)).^3)';
    a_grid_hc        = [0.45; 0.65; 0.85; 1.00; 1.20; 1.45; 1.80];
    a_grid_thetac    = linspace(0.45, 1.85, n_a.(hh_type)(3))';
    a_grid.(hh_type) = [a_grid_assets; a_grid_hc; a_grid_thetac];

    %% N-POINT ROUWENHORST REGIONAL LABOR PRODUCTIVITY GRIDS (Kopecky & Suen, 2010)
    n_z.(hh_type) = Params.n_z_pts;

    % VFI Toolkit experienceasset=1 requires: @(d_exp, a_exp, Params...)
    % 1st arg = ic (last decision), 2nd arg = theta_c (last endogenous state), 3rd+ args = Params fields
    vfoptions.aprimeFn.(hh_type) = @(ic, theta_c, agej, ...
        phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
        phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
        gbar_ece, h_par_mean, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg, Q_reg_base, K_whanau, Jr, dt) ...
        HumanCapital_Lifecycle_aprimeFn(ic, theta_c, agej, ...
        phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
        phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
        gbar_ece, h_par_mean, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg, Q_reg_base, K_whanau, Jr, dt);
    simoptions.aprimeFn.(hh_type) = vfoptions.aprimeFn.(hh_type);

    % Infinite-Horizon Firm Grids (with endogenous z_l -> z_h upgrading as local procurement breaks monopsony rents)
    n_d.(firm_type) = 0;
    d_grid.(firm_type) = [];
    n_a.(firm_type) = 81;
    a_grid.(firm_type) = 30 * (linspace(0.001, 1, 81).^2.5)';
    n_z.(firm_type) = 2; 
    p_up = Params.p_zh_upgrade_vec(r_idx);
    p_dn = Params.p_zl_downgrade_v(r_idx);
    pi_z.(firm_type) = [1.0 - p_up, p_up; p_dn, 1.0 - p_dn];
end

% Discretize regional log-productivity AR(1) via Rouwenhorst (mew, rho, sigma, znum)
% Note: In VFI Toolkit, mew = mu * (1 - rho) so unconditional mean of log(z) is Params.mu_z_reg_vec(r_idx)
rho_z = Params.rho_z;
for r_idx = 1:length(Regions)
    hh_type = ['HH_', Regions{r_idx}];
    [z_grid_log.(hh_type), pi_z.(hh_type)] = discretizeAR1_Rouwenhorst( ...
        Params.mu_z_reg_vec(r_idx) * (1 - rho_z), rho_z, Params.sigma_z_vec(r_idx), Params.n_z_pts);
    z_grid.(hh_type) = exp(z_grid_log.(hh_type));
end

% Regional Firm Productivity Ceilings (z_l vs z_h from Tier B Apply_Empirical_Data)
for r_idx = 1:N_reg
    firm_type = ['Firm_', Regions{r_idx}];
    z_grid.(firm_type) = [Params.z_firm_low_vec(r_idx); Params.z_firm_high_vec(r_idx)];
end

%% 4. SPATIAL HOUSING, ENERGY, & INTERGENERATIONAL PARAMETERS (FROM LAYER 1 DATASPEC)
% Note: Configure_TimeGrid_Params already populated G_reg, Q_reg, Q_reg_base, delta_H,
% w_reg, w_reg_base, ebar_energy, Transfer_Geo, and K_whanau_base from Params.DataSpec
% (respecting any caller-supplied overrides in Params prior to script invocation).
for r_idx = 1:N_reg
    DiscountFactorParamNames.(['HH_', Regions{r_idx}])   = {'beta_hh', 'sj'};
    DiscountFactorParamNames.(['Firm_', Regions{r_idx}]) = {'beta_firm'};
end

% Note: Tiers A, B, C, and D (Configure_Grid_And_Prefs, Apply_Empirical_Data,
% Apply_Calibrated_Params, Apply_Policy_Regime) already populated all deep preferences,
% statutory taxes, Cunha-Heckman/Ben-Porath elasticities, and SS0 ECE baselines while
% respecting any caller-supplied overrides on Params!

% Update active regional whanau capacity Params.K_whanau(k) from fixed Params.K_whanau_base(k)
% as a function of current NZ Super age (Jr), pension rate (p_super), and current house prices (Params.Q_reg):
super_age_eff   = 20 + (Params.Jr - 1) * Params.dt;
elder_time_mult = exp(-Params.eta_elder_whanau * max(0, super_age_eff - 65));
for r_idx = 1:length(Regions)
    hh_type = ['HH_', Regions{r_idx}];
    elder_home_mult = min(1.15, max(0.50, (Params.p_super / 0.18) * ((Params.Q_reg_base.(hh_type) / Params.Q_reg.(hh_type)) ^ 0.35)));
    Params.K_whanau.(hh_type) = Params.K_whanau_base.(hh_type) * elder_time_mult * elder_home_mult;
end
Params = Apply_Policy_Regime(Params, '');

%% 5. SOLVE VFI & 4-REGION + ABROAD INTERGENERATIONAL TRANSITION LOOP
for r_idx = 1:N_reg
    hh_type   = ['HH_', Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];
    ReturnFn.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau) ...
        ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau);

    ReturnFn.(firm_type) = @(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt) ...
        ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt);
end

vfoptions.verbose = 0; simoptions.verbose = 0;
simoptions.d_grid = d_grid; simoptions.a_grid = a_grid;

% 1. Solve Policy via Phase-Split VFI (optional Benchmark_PhaseSplit check against full 5D VFI)
if isfield(Params, 'Benchmark_PhaseSplit') && Params.Benchmark_PhaseSplit
    tic;
    [V_ref, ~] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
    t_orig = toc;
    tic;
    [V, Policy] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions, Regions);
    t_split = toc;
    max_V_diff = max(cellfun(@(fn) max(abs(V.(fn)(:) - V_ref.(fn)(:))), Names_i));
    fprintf('VFI Speedup: %.2fs -> %.2fs (%.2fx) | Max |V - V_ref| = %.3e\n', ...
        t_orig, t_split, t_orig / t_split, double(gather(max_V_diff)));
else
    [V, Policy] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions, Regions);
end

for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    jequaloneDist.(hh_type) = ones([n_a.(hh_type), n_z.(hh_type)]) / prod([n_a.(hh_type), n_z.(hh_type)]);
end

% 2. Solve Infinite-Horizon Firms ONCE (jequaloneDist never affects firms)
Names_Firm = cellfun(@(r) ['Firm_', r], Regions, 'UniformOutput', false);
Params_Firm = Params;
Params_Firm.PTypeWeights = Reg_Firm_Shares / sum(Reg_Firm_Shares);
StationaryDist = StationaryDist_MixHorz_PType(struct(), AgeWeightsParamNames, ...
    PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_Firm, pi_z, Params_Firm, simoptions);

% 3. Precompute HH Tan transition operators ONCE across all 4 regions
HH_TransCache = Precompute_HH_StationaryCache( ...
    Policy, n_d, n_a, n_z, N_j, d_grid, a_grid, pi_z, Params, simoptions, Regions);

% 4. Fast Intergenerational Fixed-Point across all 4 regions (pure SpMV + tiny GEMM)
for ig_iter = 1:12
    StationaryDist = PushForward_HH_Dist(StationaryDist, jequaloneDist, HH_TransCache, Regions);

    [jequaloneDist_new, IG_Diagnostics] = Build_IntergenTransitionMatrix( ...
        StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions);

    diff_ig = 0;
    for r_idx = 1:N_reg
        hh_type = ['HH_', Regions{r_idx}];
        diff_ig = max(diff_ig, max(abs(jequaloneDist_new.(hh_type)(:) - jequaloneDist.(hh_type)(:))));
    end
    jequaloneDist = jequaloneDist_new;
    if diff_ig < 1e-5; break; end
end
StationaryDist.ptweights = reshape(Params.PTypeWeights, [], 1);
if ~(diff_ig < 1e-5)
    IGW_Log('IGW:NoConvergence', 'NZ_4Region_Master intergenerational newborn-distribution fixed point: %d iterations, residual %.3g', ig_iter, double(gather(diff_ig)));
end

fprintf('\n=== 4-REGION + ABROAD STEADY-STATE DIAGNOSTICS (dt = %d yr, J = %d) ===\n', Params.dt, Params.J);
for r_idx = 1:N_reg
    reg = Regions{r_idx};
    fprintf('Region: %-9s (Pop %4.1f%%) | Stage-1 Skill: %.3f | Completed Skill: %.3f | Struggling: %4.1f%% | Mean Bequest: %.3f | Emig: %4.1f%%\n', ...
        reg, 100*Reg_HH_Shares(r_idx), IG_Diagnostics.MeanTheta2.(reg), ...
        IG_Diagnostics.MeanTheta3.(reg), 100*IG_Diagnostics.StrugglingShare.(reg), ...
        IG_Diagnostics.MeanBequest.(reg), 100*IG_Diagnostics.EmigRate.(reg));
end
