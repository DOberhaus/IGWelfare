function [V, Policy] = Solve_VFI_PhaseSplit( ...
    n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions, Regions)
%% PHASE-SPLIT EXACT MULTI-REGION VFI FOR 5D EXPERIENCE-ASSET LIFECYCLE HOUSEHOLDS + INFHORZ FIRMS
% Zero VFI Toolkit modifications required. Exploits exact lifecycle sub-manifolds AND fuses all N_reg
% regions x N_z shocks into a single batch per phase (saturating all CPU workers & using compiled .oct/.ptx kernels):
%   - Phase 4 (Jr : J)              : Retirees      -> 4D Case1, n_d = [1,1,1]     (756x smaller, compiled ReturnFn_SpatialHH)
%   - Phase 3 (j_s2_end+1 : Jr-1)   : Post-Parent   -> 4D Case1, n_d = [4,3,1]     ( 63x smaller, compiled ReturnFn_SpatialHH)
%   - Phase 2 (j_s1_start : j_s2_end): Parenting     -> 5D ExpAsset, full grids     (  1x exact)
%   - Phase 1 (1 : j_s1_start-1)    : Pre-Parenting -> 5D ExpAsset, n_d = [4,3,1]   (  7x smaller)

N_reg  = length(Regions);
V      = struct();
Policy = struct();

%% 1. SOLVE 4 INFINITE-HORIZON FIRMS VIA EXISTING TOOLKIT DISPATCH
Names_Firm = cell(1, N_reg);
for r_idx = 1:N_reg
    Names_Firm{r_idx} = ['Firm_', Regions{r_idx}];
end
[V_firm, Pol_firm] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_Firm, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
for r_idx = 1:N_reg
    ft = Names_Firm{r_idx};
    V.(ft)      = V_firm.(ft);
    Policy.(ft) = Pol_firm.(ft);
end

%% 2. LIFECYCLE WINDOW BOUNDARIES (FROM Configure_TimeGrid_Params)
J      = Params.J;
Jr_int = max(Params.j_s2_end + 1, ceil(Params.Jr - 1e-9)); % Safe even if fractional Jr is tested
j_p4   = Jr_int : J;                                       % Phase 4: Retirement (l=0, Ih=0, ic=0, dummy theta_c=1)
j_p3   = (Params.j_s2_end + 1) : (Jr_int - 1);             % Phase 3: Post-Parenting (ic=0, dummy theta_c=1)
j_p2   = Params.j_s1_start : Params.j_s2_end;              % Phase 2: Active Stages 1 & 2 Parenting
j_p1   = 1 : (Params.j_s1_start - 1);                      % Phase 1: Pre-Parenting Youth (ic=0, carries theta_c)

Names_HH = cell(1, N_reg);
for r_idx = 1:N_reg
    Names_HH{r_idx} = ['HH_', Regions{r_idx}];
end

use_gpu = (exist('OCTAVE_VERSION', 'builtin') == 0) && (gpuDeviceCount > 0);

%% 3. BUILD PER-PHASE MULTI-REGION INPUT STRUCTS (ALL REGIONS FUSED PER PHASE)
nd_p4 = struct(); nd_p3 = struct(); nd_p1 = struct();
na_4d = struct();
dg_p4 = struct(); dg_p3 = struct(); dg_p1 = struct();
ag_4d = struct();
nj_p4 = struct(); nj_p3 = struct(); nj_p2 = struct(); nj_p1 = struct();

for r_idx = 1:N_reg
    hh_type  = Names_HH{r_idx};
    n_d_full = n_d.(hh_type);     % [4, 3, 7]
    n_a_full = n_a.(hh_type);     % [61, 7, 9]
    n_z_reg  = n_z.(hh_type);     % [7]
    N_z      = prod(n_z_reg);
    n_a1     = n_a_full(1);       % 61
    n_h      = n_a_full(2);       % 7
    n_th     = n_a_full(3);       % 9

    d_all  = d_grid.(hh_type);
    d_l_Ih = d_all(1 : sum(n_d_full(1:2)));                % [4 + 3 = 7 x 1]
    d_pre  = [d_l_Ih; d_all(sum(n_d_full(1:2)) + 1)];      % [l; Ih; ic=0] -> [8 x 1]

    a_all  = a_grid.(hh_type);
    % Singleton theta_c = 1.0 grid keeps exact 9-arg ReturnFn_SpatialHH signature so compiled .oct/.ptx runs natively!
    a_4d_reg = [a_all(1 : (n_a1 + n_h)); 1.0];             % [a; h; theta_c=1.0] -> [69 x 1]

    nd_p4.(hh_type) = [1, 1, 1];
    nd_p3.(hh_type) = [n_d_full(1:2), 1];
    nd_p1.(hh_type) = [n_d_full(1:2), 1];
    na_4d.(hh_type) = [n_a1, n_h, 1];

    dg_p4.(hh_type) = [0; 0; 0];
    dg_p3.(hh_type) = d_pre;
    dg_p1.(hh_type) = d_pre;
    ag_4d.(hh_type) = a_4d_reg;

    nj_p4.(hh_type) = length(j_p4);
    nj_p3.(hh_type) = length(j_p3);
    nj_p2.(hh_type) = length(j_p2);
    nj_p1.(hh_type) = length(j_p1);

    if use_gpu
        V.(hh_type)      = zeros(n_a1, n_h, n_th, N_z, J, 'gpuArray');
        Policy.(hh_type) = ones(5, n_a1, n_h, n_th, N_z, J, 'gpuArray');
    else
        V.(hh_type)      = zeros(n_a1, n_h, n_th, N_z, J);
        Policy.(hh_type) = ones(5, n_a1, n_h, n_th, N_z, J);
    end
end

%% 4. BACKWARD PHASE HANDOFF ACROSS ALL 4 REGIONS CONCURRENTLY
% ---- PHASE 4: RETIREMENT (Jr_int : J) — 4D Standard Case1, n_d = [1,1,1] ----
vfo_4 = struct('verbose', 0, 'experienceasset', 0);
P_p4  = slice_age_params_ptype(Params, Names_HH, j_p4, J);
[V_p4, Pol_p4] = ValueFnIter_MixHorz_PType(nd_p4, na_4d, n_z, nj_p4, Names_HH, ...
    dg_p4, ag_4d, z_grid, pi_z, ReturnFn, P_p4, DiscountFactorParamNames, vfo_4);

V_next_4d = struct();
for r_idx = 1:N_reg
    hh_type  = Names_HH{r_idx};
    n_a_full = n_a.(hh_type);
    n_a1 = n_a_full(1); n_h = n_a_full(2); n_th = n_a_full(3);
    N_z  = prod(n_z.(hh_type));
    len4 = length(j_p4);

    V.(hh_type)(:, :, :, :, j_p4) = repmat(reshape(V_p4.(hh_type), [n_a1, n_h, 1, N_z, len4]), [1, 1, n_th, 1, 1]);
    % Pol_p4 has 6 rows: [d1=1; d2=1; d3=1; aprime_idx; hprime_idx; thetaprime=1]. Extract [4,5] -> rows 4:5:
    Pol_p4_ah = Pol_p4.(hh_type)(4:5, :, :, :, :, :);
    Policy.(hh_type)(4:5, :, :, :, :, j_p4) = repmat(reshape(Pol_p4_ah, [2, n_a1, n_h, 1, N_z, len4]), [1, 1, 1, n_th, 1, 1]);
    V_next_4d.(hh_type) = reshape(V_p4.(hh_type)(:, :, 1, :, 1), [n_a1, n_h, 1, N_z]);
end

% ---- PHASE 3: POST-PARENTING (j_s2_end+1 : Jr_int-1) — 4D Standard Case1, n_d = [4, 3, 1] ----
if ~isempty(j_p3)
    vfo_3 = struct('verbose', 0, 'experienceasset', 0, 'V_Jplus1', V_next_4d);
    P_p3  = slice_age_params_ptype(Params, Names_HH, j_p3, J);
    [V_p3, Pol_p3] = ValueFnIter_MixHorz_PType(nd_p3, na_4d, n_z, nj_p3, Names_HH, ...
        dg_p3, ag_4d, z_grid, pi_z, ReturnFn, P_p3, DiscountFactorParamNames, vfo_3);

    for r_idx = 1:N_reg
        hh_type  = Names_HH{r_idx};
        n_a_full = n_a.(hh_type);
        n_a1 = n_a_full(1); n_h = n_a_full(2); n_th = n_a_full(3);
        N_z  = prod(n_z.(hh_type));
        len3 = length(j_p3);

        V.(hh_type)(:, :, :, :, j_p3) = repmat(reshape(V_p3.(hh_type), [n_a1, n_h, 1, N_z, len3]), [1, 1, n_th, 1, 1]);
        % Pol_p3 has 6 rows: [l_idx; Ih_idx; ic_idx=1; aprime_idx; hprime_idx; thetaprime=1]. Extract [1,2,4,5]:
        Pol_p3_sub = Pol_p3.(hh_type)([1, 2, 4, 5], :, :, :, :, :);
        Policy.(hh_type)([1, 2, 4, 5], :, :, :, :, j_p3) = repmat(reshape(Pol_p3_sub, [4, n_a1, n_h, 1, N_z, len3]), [1, 1, 1, n_th, 1, 1]);
        V_next_4d.(hh_type) = reshape(V_p3.(hh_type)(:, :, 1, :, 1), [n_a1, n_h, 1, N_z]);
    end
end

% Broadcast 4D continuation value at j_s2_end + 1 across 9 theta_c points -> [61, 7, 9, n_z]
V_next_5d = struct();
for r_idx = 1:N_reg
    hh_type  = Names_HH{r_idx};
    n_a_full = n_a.(hh_type);
    n_th     = n_a_full(3);
    V_next_5d.(hh_type) = repmat(V_next_4d.(hh_type), [1, 1, n_th, 1]);
end

% ---- PHASE 2: ACTIVE PARENTING (j_s1_start : j_s2_end) — Full 5D Experience Asset ----
vfo_2 = vfoptions;
vfo_2.verbose  = 0;
vfo_2.V_Jplus1 = V_next_5d;
P_p2 = slice_age_params_ptype(Params, Names_HH, j_p2, J);
[V_p2, Pol_p2] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, nj_p2, Names_HH, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, P_p2, DiscountFactorParamNames, vfo_2);

for r_idx = 1:N_reg
    hh_type  = Names_HH{r_idx};
    n_a_full = n_a.(hh_type);
    n_a1 = n_a_full(1); n_h = n_a_full(2); n_th = n_a_full(3);
    N_z  = prod(n_z.(hh_type));
    len2 = length(j_p2);

    V.(hh_type)(:, :, :, :, j_p2)      = reshape(V_p2.(hh_type),   [n_a1, n_h, n_th, N_z, len2]);
    Policy.(hh_type)(:, :, :, :, :, j_p2) = reshape(Pol_p2.(hh_type), [5, n_a1, n_h, n_th, N_z, len2]);
    V_next_5d.(hh_type) = reshape(V.(hh_type)(:, :, :, :, j_p2(1)), [n_a1, n_h, n_th, N_z]);
end

% ---- PHASE 1: PRE-PARENTING YOUTH (1 : j_s1_start-1) — 5D Experience Asset, n_d = [4, 3, 1] ----
% Must stay 5D because V_next_5d at j_s1_start depends on inherited theta_c!
if ~isempty(j_p1)
    vfo_1 = vfoptions;
    vfo_1.verbose  = 0;
    vfo_1.V_Jplus1 = V_next_5d;
    P_p1 = slice_age_params_ptype(Params, Names_HH, j_p1, J);
    [V_p1, Pol_p1] = ValueFnIter_MixHorz_PType(nd_p1, n_a, n_z, nj_p1, Names_HH, ...
        dg_p1, a_grid, z_grid, pi_z, ReturnFn, P_p1, DiscountFactorParamNames, vfo_1);

    for r_idx = 1:N_reg
        hh_type  = Names_HH{r_idx};
        n_a_full = n_a.(hh_type);
        n_a1 = n_a_full(1); n_h = n_a_full(2); n_th = n_a_full(3);
        N_z  = prod(n_z.(hh_type));
        len1 = length(j_p1);

        V.(hh_type)(:, :, :, :, j_p1) = reshape(V_p1.(hh_type), [n_a1, n_h, n_th, N_z, len1]);
        if size(Pol_p1.(hh_type), 1) == 5
            Policy.(hh_type)(:, :, :, :, :, j_p1) = reshape(Pol_p1.(hh_type), [5, n_a1, n_h, n_th, N_z, len1]);
        else
            Policy.(hh_type)([1, 2, 4, 5], :, :, :, :, j_p1) = reshape(Pol_p1.(hh_type), [4, n_a1, n_h, n_th, N_z, len1]);
        end
    end
end
end

%% ---- LOCAL HELPERS ----
function P_sub = slice_age_params_ptype(Params, Names_HH, j_range, J)
% Slices only true age-indexed vectors (agej, sj, fj, mig_rate_j, mewj) globally and per HH_Region
P_sub    = Params;
age_flds = {'agej', 'sj', 'fj', 'mig_rate_j', 'mewj'};
for k = 1:length(age_flds)
    fn = age_flds{k};
    if isfield(P_sub, fn)
        val = P_sub.(fn);
        if isstruct(val)
            for r = 1:length(Names_HH)
                ht = Names_HH{r};
                if isfield(val, ht) && numel(val.(ht)) == J
                    val.(ht) = val.(ht)(j_range);
                end
            end
            P_sub.(fn) = val;
        elseif numel(val) == J
            P_sub.(fn) = val(j_range);
        end
    end
end
end
