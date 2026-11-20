function test_phasesplit_and_stationary_pushforward()
%TEST_PHASESPLIT_AND_STATIONARY_PUSHFORWARD Test Precompute_HH_StationaryCache and
%   PushForward_HH_Dist on a compact 5D Experience-Asset fixture across GPU/CPU/Octave.

if exist('ValueFnIter_Case1_FHorz', 'file') == 0
    mode = strtrim(getenv('IGWELFARE_TEST_MODE'));
    if isempty(mode)
        error('tests:skip', 'VFIToolkit not on path (interactive run)');
    else
        error('tests:fail', 'VFIToolkit required in CI mode %s', mode);
    end
end

Regions = {'Rural', 'Auckland'};
J = 6;
n_d_hh = [2, 2, 3];          % [l, Ih, ic]
n_a_hh = [4, 3, 3];          % [a, h, theta_c] (theta_c is experienceasset)
n_z_hh = 2;
N_a    = prod(n_a_hh);

d_grid_hh = [0.0; 0.8;   0.0; 0.05;   0.0; 0.0203; 0.08];
a_grid_hh = [0.1; 0.8; 2.0; 4.5;   0.65; 1.00; 1.45;   0.60; 1.00; 1.40];
pi_z_mat  = [0.85, 0.15; 0.20, 0.80];

% Age weights summing strictly to 1.0
mewj = (0.985 .^ (0:(J - 1))');
mewj = mewj / sum(mewj);

Params = struct();
Params.Jr             = 5;
Params.dt             = 5.0;
Params.agej           = 1:J;
Params.mewj           = mewj;
Params.j_s1_start     = 2;
Params.j_s1_end       = 2;
Params.j_s2_start     = 3;
Params.j_s2_end       = 4;
Params.n_stage1_steps = 1;
Params.n_stage2_steps = 2;
Params.phi1_ces       = -0.25; Params.gamma1_self = 0.45; Params.gamma1_inv = 0.35; Params.gamma1_par = 0.20;
Params.phi2_ces       = -0.50; Params.gamma2_self = 0.55; Params.gamma2_inv = 0.28; Params.gamma2_par = 0.17;
Params.gbar_ece       = 0.040;
Params.h_par_mean     = 1.00;
Params.G_ece_stage1   = struct('HH_Rural', 0.05, 'HH_Auckland', 0.06);
Params.G_ece_stage2   = struct('HH_Rural', 0.06, 'HH_Auckland', 0.07);
Params.Q_reg          = struct('HH_Rural', 1.05, 'HH_Auckland', 1.65);
Params.Q_reg_base     = struct('HH_Rural', 1.05, 'HH_Auckland', 1.65);
Params.K_whanau       = struct('HH_Rural', 0.14, 'HH_Auckland', 0.09);

n_d = struct(); n_a = struct(); n_z = struct(); N_j = struct();
d_grid = struct(); a_grid = struct(); pi_z = struct();
Policy = struct(); jequaloneDist = struct(); StationaryDist = struct();

simoptions = struct();
simoptions.experienceasset = struct();
simoptions.aprimeFn = struct();
simoptions.d_grid = d_grid;
simoptions.a_grid = a_grid;

% Deterministic valid policy indices [5 x n_a1 x n_h x n_th x n_z x J]:
% Rows 1..3 = d indices (l, Ih, ic); Rows 4..5 = aprime1, hprime indices (for experienceasset=1)
idx_grid = reshape(1:(N_a * n_z_hh * J), [1, n_a_hh, n_z_hh, J]);
pol_5d = zeros([5, n_a_hh, n_z_hh, J]);
pol_5d(1, :, :, :, :, :) = 1 + mod(idx_grid, n_d_hh(1));
pol_5d(2, :, :, :, :, :) = 1 + mod(idx_grid + 1, n_d_hh(2));
pol_5d(3, :, :, :, :, :) = 1 + mod(idx_grid + 2, n_d_hh(3));
pol_5d(4, :, :, :, :, :) = 1 + mod(idx_grid, n_a_hh(1));
pol_5d(5, :, :, :, :, :) = 1 + mod(idx_grid + 1, n_a_hh(2));
% Retirees (age >= Jr) choose zero ic (index 1) and stay at interior assets
pol_5d(3, :, :, :, :, Params.Jr:J) = 1;

aprimeFn_hdl = @(i_c, thetac, agej, ...
    phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
    phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
    gbar_ece, h_par_mean, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_reg, Q_reg_base, K_whanau, Jr, dt) ...
    HumanCapital_Lifecycle_aprimeFn(i_c, thetac, agej, ...
    phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
    phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
    gbar_ece, h_par_mean, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_reg, Q_reg_base, K_whanau, Jr, dt);

for r_idx = 1:numel(Regions)
    hh = ['HH_', Regions{r_idx}];
    n_d.(hh)    = n_d_hh;
    n_a.(hh)    = n_a_hh;
    n_z.(hh)    = n_z_hh;
    N_j.(hh)    = J;
    d_grid.(hh) = d_grid_hh;
    a_grid.(hh) = a_grid_hh;
    pi_z.(hh)   = pi_z_mat;
    Policy.(hh) = pol_5d;

    simoptions.experienceasset.(hh) = 1;
    simoptions.aprimeFn.(hh)        = aprimeFn_hdl;

    % Non-uniform initial newborn distribution summing to 1.0
    j1_raw = reshape(linspace(0.5, 1.5, N_a * n_z_hh), [n_a_hh, n_z_hh]);
    jequaloneDist.(hh)  = j1_raw / sum(j1_raw(:));
    StationaryDist.(hh) = [];
end

% 1. Precompute Tan sparse operators & push forward across all ages
Cache = Precompute_HH_StationaryCache( ...
    Policy, n_d, n_a, n_z, N_j, d_grid, a_grid, pi_z, Params, simoptions, Regions);
StationaryDist = PushForward_HH_Dist(StationaryDist, jequaloneDist, Cache, Regions);

% 2. Validate probability axioms & regional distinction
for r_idx = 1:numel(Regions)
    hh = ['HH_', Regions{r_idx}];
    D  = double(gather(StationaryDist.(hh)));
    check(isequal(size(D), [n_a_hh, n_z_hh, J]), ...
        sprintf('StationaryDist.%s wrong shape', hh));
    check(all(isfinite(D(:)) & (D(:) >= -1e-15)), ...
        sprintf('StationaryDist.%s contains negative or NaN mass', hh));
    check(abs(sum(D(:)) - 1.0) < 1e-12, ...
        sprintf('StationaryDist.%s total mass = %.15f (expected 1.0)', hh, sum(D(:))));

    % Cohort marginal sum across (a, h, th, z) must equal mewj
    cohort_mass = reshape(sum(reshape(D, [], J), 1), [J, 1]);
    check(max(abs(cohort_mass - mewj)) < 1e-12, ...
        sprintf('StationaryDist.%s cohort marginals deviate from mewj', hh));
end

% Auckland vs Rural housing/ECE wedges must produce distinct theta_c distributions
D_rur = double(gather(StationaryDist.HH_Rural));
D_akl = double(gather(StationaryDist.HH_Auckland));
check(max(abs(D_rur(:) - D_akl(:))) > 1e-6, ...
    'Expected distinct stationary distributions between Rural and Auckland price/ECE manifolds');
end

function check(cond, msg)
if ~cond
    error('tests:fail', '%s', msg);
end


end
