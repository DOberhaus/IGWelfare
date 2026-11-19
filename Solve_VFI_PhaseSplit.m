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

Names_HH = cell(1, N_reg);
for r_idx = 1:N_reg
    Names_HH{r_idx} = ['HH_', Regions{r_idx}];
end

use_gpu = (exist('OCTAVE_VERSION', 'builtin') == 0) && (gpuDeviceCount > 0);

% Detect Compact 4D ([n_a1, n_h], experienceasset == 0) vs Canonical 5D ([n_a1, n_h, n_th])
is_5d = (numel(n_a.(Names_HH{1})) >= 3);

if ~is_5d
    %% COMPACT 4D EXACT PHASE-SPLIT FAST PATH (HANDLES ANY CONTINUOUS Jr / super_age)
    J             = Params.J;
    dt            = Params.dt;
    super_age_yrs = 20 + (Params.Jr - 1) * dt;
    % Exact first age index where is_full_ret == true in ReturnFn_SpatialHH_Compact4D:
    % requires BOTH age_start_yrs >= 65 AND age_end_yrs - super_age_yrs >= 0.999 * dt
    j_ret4d = J + 1;
    for jj = (Params.j_s2_end + 1) : J
        age_s = 20 + (jj - 1) * dt;
        age_e = age_s + dt;
        if (age_s >= 65.0 - 1e-4) && ((age_e - super_age_yrs) / dt >= 0.999)
            j_ret4d = jj;
            break;
        end
    end
    vfo_base4d = vfoptions;
    vfo_base4d.verbose = 0;
    vfo_base4d.experienceasset = 0;
    vfo_base4d.vectorized = 1;
    for stale_f = {'V_Jplus1', 'aprimeFn', 'n_d1', 'n_d2', 'n_a1', 'n_a2', 'd1_grid', 'd2_grid', 'a1_grid', 'a2_grid'}
        if isfield(vfo_base4d, stale_f{1})
            vfo_base4d = rmfield(vfo_base4d, stale_f{1});
        end
    end

    j_c4 = j_ret4d : J;
    j_c3 = (Params.j_s2_end + 1) : (j_ret4d - 1);
    j_c2 = Params.j_s1_start : Params.j_s2_end;
    j_c1 = 1 : (Params.j_s1_start - 1);

    nd_c4 = struct(); nd_c31 = struct();
    dg_c4 = struct(); dg_c31 = struct();
    nj_c4 = struct(); nj_c3  = struct(); nj_c2 = struct(); nj_c1 = struct();

    for r_idx = 1:N_reg
        ht       = Names_HH{r_idx};
        n_d_full = n_d.(ht);
        n_a_reg  = n_a.(ht);
        N_z_reg  = prod(n_z.(ht));
        d_all    = d_grid.(ht);
        d_l_Ih   = d_all(1 : sum(n_d_full(1:2)));
        d_pre    = [d_l_Ih; d_all(sum(n_d_full(1:2)) + 1)];

        nd_c4.(ht)  = [1, 1, 1];
        nd_c31.(ht) = [n_d_full(1:2), 1];
        dg_c4.(ht)  = [0; 0; 0];
        dg_c31.(ht) = d_pre;

        nj_c4.(ht) = length(j_c4);
        nj_c3.(ht) = length(j_c3);
        nj_c2.(ht) = length(j_c2);
        nj_c1.(ht) = length(j_c1);

        if use_gpu
            V.(ht)      = zeros(n_a_reg(1), n_a_reg(2), N_z_reg, J, 'gpuArray');
            Policy.(ht) = ones(5, n_a_reg(1), n_a_reg(2), N_z_reg, J, 'gpuArray');
        else
            V.(ht)      = zeros(n_a_reg(1), n_a_reg(2), N_z_reg, J);
            Policy.(ht) = ones(5, n_a_reg(1), n_a_reg(2), N_z_reg, J);
        end
    end

    V_next_c = struct();
    % Phase 4 (Full Retirement: l=0, Ih=0, ic=0 -> 84x smaller)
    if ~isempty(j_c4)
        vfo_c4 = vfo_base4d; vfo_c4.verbose = 0; vfo_c4.experienceasset = 0;
        P_c4   = slice_age_params_ptype(Params, Names_HH, j_c4, J);
        [V_c4, Pol_c4] = ValueFnIter_MixHorz_PType(nd_c4, n_a, n_z, nj_c4, Names_HH, ...
            dg_c4, a_grid, z_grid, pi_z, ReturnFn, P_c4, DiscountFactorParamNames, vfo_c4);
        for r_idx = 1:N_reg
            ht = Names_HH{r_idx}; na = n_a.(ht); Nz = prod(n_z.(ht)); l4 = length(j_c4);
            V.(ht)(:, :, :, j_c4)           = reshape(V_c4.(ht), [na(1), na(2), Nz, l4]);
            Policy.(ht)(4:5, :, :, :, j_c4) = reshape(Pol_c4.(ht)(4:5, :, :, :, :), [2, na(1), na(2), Nz, l4]);
            V_next_c.(ht)                   = reshape(V_c4.(ht)(:, :, :, 1), [na(1), na(2), Nz]);
        end
    end

    % Phase 3 (Post-Parenting: ic=0 -> 7x smaller)
    if ~isempty(j_c3)
        vfo_c3 = vfo_base4d; vfo_c3.verbose = 0; vfo_c3.experienceasset = 0;
        if ~isempty(fieldnames(V_next_c)); vfo_c3.V_Jplus1 = V_next_c; end
        P_c3 = slice_age_params_ptype(Params, Names_HH, j_c3, J);
        [V_c3, Pol_c3] = ValueFnIter_MixHorz_PType(nd_c31, n_a, n_z, nj_c3, Names_HH, ...
            dg_c31, a_grid, z_grid, pi_z, ReturnFn, P_c3, DiscountFactorParamNames, vfo_c3);
        for r_idx = 1:N_reg
            ht = Names_HH{r_idx}; na = n_a.(ht); Nz = prod(n_z.(ht)); l3 = length(j_c3);
            V.(ht)(:, :, :, j_c3)                   = reshape(V_c3.(ht), [na(1), na(2), Nz, l3]);
            Policy.(ht)([1, 2, 4, 5], :, :, :, j_c3) = reshape(Pol_c3.(ht)([1, 2, 4, 5], :, :, :, :), [4, na(1), na(2), Nz, l3]);
            V_next_c.(ht)                           = reshape(V_c3.(ht)(:, :, :, 1), [na(1), na(2), Nz]);
        end
    end

    % Phase 2 (Active Parenting: full [4, 3, 7])
    vfo_c2 = vfo_base4d; vfo_c2.verbose = 0; vfo_c2.experienceasset = 0;
    if ~isempty(fieldnames(V_next_c)); vfo_c2.V_Jplus1 = V_next_c; end
    P_c2 = slice_age_params_ptype(Params, Names_HH, j_c2, J);
    [V_c2, Pol_c2] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, nj_c2, Names_HH, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, P_c2, DiscountFactorParamNames, vfo_c2);
    for r_idx = 1:N_reg
        ht = Names_HH{r_idx}; na = n_a.(ht); Nz = prod(n_z.(ht)); l2 = length(j_c2);
        V.(ht)(:, :, :, j_c2)         = reshape(V_c2.(ht), [na(1), na(2), Nz, l2]);
        Policy.(ht)(:, :, :, :, j_c2) = reshape(Pol_c2.(ht), [5, na(1), na(2), Nz, l2]);
        V_next_c.(ht)                 = reshape(V_c2.(ht)(:, :, :, 1), [na(1), na(2), Nz]);
    end

    % Phase 1 (Pre-Parenting Youth: ic=0 -> 7x smaller)
    if ~isempty(j_c1)
        vfo_c1 = vfo_base4d; vfo_c1.verbose = 0; vfo_c1.experienceasset = 0;
        vfo_c1.V_Jplus1 = V_next_c;
        P_c1 = slice_age_params_ptype(Params, Names_HH, j_c1, J);
        [V_c1, Pol_c1] = ValueFnIter_MixHorz_PType(nd_c31, n_a, n_z, nj_c1, Names_HH, ...
            dg_c31, a_grid, z_grid, pi_z, ReturnFn, P_c1, DiscountFactorParamNames, vfo_c1);
        for r_idx = 1:N_reg
            ht = Names_HH{r_idx}; na = n_a.(ht); Nz = prod(n_z.(ht)); l1 = length(j_c1);
            V.(ht)(:, :, :, j_c1)                   = reshape(V_c1.(ht), [na(1), na(2), Nz, l1]);
            Policy.(ht)([1, 2, 4, 5], :, :, :, j_c1) = reshape(Pol_c1.(ht)([1, 2, 4, 5], :, :, :, :), [4, na(1), na(2), Nz, l1]);
        end
    end
    return;
end

%% 2. LIFECYCLE WINDOW BOUNDARIES (FROM Configure_TimeGrid_Params)
J      = Params.J;
Jr_int = max(Params.j_s2_end + 1, ceil(Params.Jr - 1e-9)); % Safe even if fractional Jr is tested
j_p4   = Jr_int : J;                                       % Phase 4: Retirement (l=0, Ih=0, ic=0, dummy theta_c=1)
j_p3   = (Params.j_s2_end + 1) : (Jr_int - 1);             % Phase 3: Post-Parenting (ic=0, dummy theta_c=1)
j_p2   = Params.j_s1_start : Params.j_s2_end;              % Phase 2: Active Stages 1 & 2 Parenting
j_p1   = 1 : (Params.j_s1_start - 1);                      % Phase 1: Pre-Parenting Youth (ic=0, carries theta_c)

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
vfo_4 = struct('verbose', 0, 'experienceasset', 0, 'vectorized', 1);
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
    vfo_3 = struct('verbose', 0, 'experienceasset', 0, 'vectorized', 1, 'V_Jplus1', V_next_4d);
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
vfo_2.verbose    = 0;
vfo_2.vectorized = 1;
vfo_2.V_Jplus1   = V_next_5d;
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
    vfo_1.verbose    = 0;
    vfo_1.vectorized = 1;
    vfo_1.V_Jplus1   = V_next_5d;
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
% Slices all age-indexed vectors of length J globally and per HH_Region, wrapping
% shared age vectors into per-HH structs so ValueFnIter_MixHorz_PType never mistakes
% a sub-horizon of length N_reg (e.g. length(j_p2) == 4 == N_i) for a PType vector!
P_sub    = Params;
all_flds = fieldnames(P_sub);
for k = 1:length(all_flds)
    fn  = all_flds{k};
    val = P_sub.(fn);
    if isstruct(val)
        changed = false;
        for r = 1:length(Names_HH)
            ht = Names_HH{r};
            if isfield(val, ht) && isnumeric(val.(ht)) && isvector(val.(ht)) && numel(val.(ht)) == J
                val.(ht) = val.(ht)(j_range);
                changed  = true;
            end
        end
        if changed
            P_sub.(fn) = val;
        end
    elseif isnumeric(val) && isvector(val) && numel(val) == J
        s_sliced = struct();
        for r = 1:length(Names_HH)
            s_sliced.(Names_HH{r}) = val(j_range);
        end
        P_sub.(fn) = s_sliced;
    end
end


end
