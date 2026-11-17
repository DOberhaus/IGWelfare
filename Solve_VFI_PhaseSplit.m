function [V, Policy] = Solve_VFI_PhaseSplit( ...
    n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions, Regions)
%% PHASE-SPLIT EXACT GPU VFI FOR 5D EXPERIENCE-ASSET LIFECYCLE HOUSEHOLDS + INFHORZ FIRMS
% Zero VFI Toolkit modifications required. Exploits exact lifecycle sub-manifolds:
%   - Phase 4 (Jr : J)              : Retirees      -> 4D Case1, n_d = 0         (756x smaller)
%   - Phase 3 (j_s2_end+1 : Jr-1)   : Post-Parent   -> 4D Case1, n_d = [4, 3]    ( 63x smaller)
%   - Phase 2 (j_s1_start : j_s2_end): Parenting     -> 5D ExpAsset, full grids   (  1x exact)
%   - Phase 1 (1 : j_s1_start-1)    : Pre-Parenting -> 5D ExpAsset, n_d=[4,3,1]  (  7x smaller)

N_reg = length(Regions);
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
j_p4   = Jr_int : J;                                       % Phase 4: Retirement (l=0, Ih=0, ic=0, no theta_c)
j_p3   = (Params.j_s2_end + 1) : (Jr_int - 1);             % Phase 3: Post-Parenting (ic=0, no theta_c)
j_p2   = Params.j_s1_start : Params.j_s2_end;              % Phase 2: Active Stages 1 & 2 Parenting
j_p1   = 1 : (Params.j_s1_start - 1);                      % Phase 1: Pre-Parenting Youth (ic=0, carries theta_c)

%% 3. SOLVE EACH HOUSEHOLD REGION BY BACKWARD PHASE HANDOFF (V_Jplus1)
for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    Params_reg = unpack_ptype_params(Params, hh_type, J);

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
    a_4d   = a_all(1 : (n_a1 + n_h));                      % [a; h] -> [68 x 1]
    z_g    = z_grid.(hh_type);
    pi_g   = pi_z.(hh_type);
    disc   = DiscountFactorParamNames.(hh_type);

    % Preallocate full 5D V [61, 7, 9, n_z, J] and Policy [5, 61, 7, 9, n_z, J] on GPU
    use_gpu = (gpuDeviceCount > 0);
    if use_gpu
        V_full   = zeros(n_a1, n_h, n_th, N_z, J, 'gpuArray');
        Pol_full = ones(5, n_a1, n_h, n_th, N_z, J, 'gpuArray');
    else
        V_full   = zeros(n_a1, n_h, n_th, N_z, J);
        Pol_full = ones(5, n_a1, n_h, n_th, N_z, J);
    end

    %4D wrappers: fix dummy theta_c = 1.0 (unused outside Stages 1-2) and ic = 0 (and l=0, Ih=0 in Phase 4)
    RetFn_5D = ReturnFn.(hh_type);
    RetFn_P4 = @(aprime, hprime, a, h, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau) ...
        ReturnFn_SpatialHH(0, 0, 0, aprime, hprime, a, h, 1.0, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau);

    RetFn_P3 = @(l, Ih, aprime, hprime, a, h, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau) ...
        ReturnFn_SpatialHH(l, Ih, 0, aprime, hprime, a, h, 1.0, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau);

    % ---- PHASE 4: RETIREMENT (Jr_int : J) — 4D Standard Case1, n_d = 0 ----
    vfo_4 = struct('verbose', 0, 'experienceasset', 0);
    P_p4  = slice_age_params(Params_reg, j_p4, J);
    [V_p4, Pol_p4] = ValueFnIter_Case1_FHorz(0, [n_a1, n_h], n_z_reg, length(j_p4), ...
        [], a_4d, z_g, pi_g, RetFn_P4, P_p4, disc, vfo_4);
    % Pol_p4 has 2 rows: [aprime_idx; hprime_idx]. Broadcast across n_th = 9:
    V_full(:, :, :, :, j_p4)      = repmat(reshape(V_p4, [n_a1, n_h, 1, N_z, length(j_p4)]), [1, 1, n_th, 1, 1]);
    Pol_full(4:5, :, :, :, :, j_p4) = repmat(reshape(Pol_p4, [2, n_a1, n_h, 1, N_z, length(j_p4)]), [1, 1, 1, n_th, 1, 1]);
    V_next_4d = reshape(V_p4(:, :, :, 1), [n_a1, n_h, N_z]);

    % ---- PHASE 3: POST-PARENTING (j_s2_end+1 : Jr_int-1) — 4D Standard Case1, n_d = [4, 3] ----
    if ~isempty(j_p3)
        vfo_3 = struct('verbose', 0, 'experienceasset', 0, 'V_Jplus1', V_next_4d);
        P_p3  = slice_age_params(Params_reg, j_p3, J);
        [V_p3, Pol_p3] = ValueFnIter_Case1_FHorz(n_d_full(1:2), [n_a1, n_h], n_z_reg, length(j_p3), ...
            d_l_Ih, a_4d, z_g, pi_g, RetFn_P3, P_p3, disc, vfo_3);
        % Pol_p3 has 4 rows: [l_idx; Ih_idx; aprime_idx; hprime_idx]; row 3 in full Policy is ic_idx = 1:
        V_full(:, :, :, :, j_p3)          = repmat(reshape(V_p3, [n_a1, n_h, 1, N_z, length(j_p3)]), [1, 1, n_th, 1, 1]);
        Pol_p3_5d                         = repmat(reshape(Pol_p3, [4, n_a1, n_h, 1, N_z, length(j_p3)]), [1, 1, 1, n_th, 1, 1]);
        Pol_full([1,2,4,5], :, :, :, :, j_p3) = Pol_p3_5d;
        V_next_4d = reshape(V_p3(:, :, :, 1), [n_a1, n_h, N_z]);
    end

    % Broadcast 4D continuation value at j_s2_end + 1 across 9 theta_c points -> [61, 7, 9, n_z]
    V_next_5d = repmat(reshape(V_next_4d, [n_a1, n_h, 1, N_z]), [1, 1, n_th, 1]);

    % ---- PHASE 2: ACTIVE PARENTING (j_s1_start : j_s2_end) — Full 5D Experience Asset ----
    vfo_2 = struct('verbose', 0, 'experienceasset', 1, ...
                   'aprimeFn', vfoptions.aprimeFn.(hh_type), 'V_Jplus1', V_next_5d);
    P_p2  = slice_age_params(Params_reg, j_p2, J);
    [V_p2, Pol_p2] = ValueFnIter_Case1_FHorz(n_d_full, n_a_full, n_z_reg, length(j_p2), ...
        d_all, a_all, z_g, pi_g, RetFn_5D, P_p2, disc, vfo_2);
    V_full(:, :, :, :, j_p2)   = reshape(V_p2,   [n_a1, n_h, n_th, N_z, length(j_p2)]);
    Pol_full(:, :, :, :, :, j_p2) = reshape(Pol_p2, [5, n_a1, n_h, n_th, N_z, length(j_p2)]);
    V_next_5d = reshape(V_full(:, :, :, :, j_p2(1)), [n_a1, n_h, n_th, N_z]);

    % ---- PHASE 1: PRE-PARENTING YOUTH (1 : j_s1_start-1) — 5D Experience Asset, n_d = [4, 3, 1] ----
    % Must stay 5D because V_next_5d at j_s1_start depends on inherited theta_c!
    if ~isempty(j_p1)
        vfo_1 = struct('verbose', 0, 'experienceasset', 1, ...
                       'aprimeFn', vfoptions.aprimeFn.(hh_type), 'V_Jplus1', V_next_5d);
        P_p1  = slice_age_params(Params_reg, j_p1, J);
        [V_p1, Pol_p1] = ValueFnIter_Case1_FHorz([n_d_full(1:2), 1], n_a_full, n_z_reg, length(j_p1), ...
            d_pre, a_all, z_g, pi_g, RetFn_5D, P_p1, disc, vfo_1);
        V_full(:, :, :, :, j_p1)   = reshape(V_p1,   [n_a1, n_h, n_th, N_z, length(j_p1)]);
        Pol_full(:, :, :, :, :, j_p1) = reshape(Pol_p1, [5, n_a1, n_h, n_th, N_z, length(j_p1)]);
    end

    V.(hh_type)      = V_full;
    Policy.(hh_type) = Pol_full;
end
end

%% ---- LOCAL HELPERS ----
function P_reg = unpack_ptype_params(Params, hh_type, ~)
P_reg  = Params;
fnames = fieldnames(Params);
for k = 1:length(fnames)
    val = Params.(fnames{k});
    if isstruct(val) && isfield(val, hh_type)
        P_reg.(fnames{k}) = val.(hh_type);
    end
end
end

function P_sub = slice_age_params(P_reg, j_range, J)
% Slices only true age-indexed vectors (agej, sj, fj, mig_rate_j, mewj) so accidental length-J vectors stay intact
P_sub    = P_reg;
age_flds = {'agej', 'sj', 'fj', 'mig_rate_j', 'mewj'};
for k = 1:length(age_flds)
    fn = age_flds{k};
    if isfield(P_sub, fn) && numel(P_sub.(fn)) == J
        P_sub.(fn) = P_sub.(fn)(j_range);
    end
end


end
