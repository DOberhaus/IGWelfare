function [Ledger, SK, links] = Build_And_Render_Fates_Panel(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, z_grid, Panel_Tag, ...
    Calibration_Anchor, NZD_Scale, reform_intensity)

f_all   = fieldnames(Dist_Sim);
hh_f    = f_all(strncmp(f_all, 'HH_', 3));
avail_r = erase(hh_f, 'HH_');
N_reg   = length(avail_r);

all_w   = P_Sim.PTypeWeights(1:N_reg);
all_w   = all_w(:) / sum(all_w);

if strcmpi(reg_choice, 'National')
    reg_list    = avail_r(:)';
    pop_weights = all_w;
elseif strcmpi(reg_choice, 'Urban') && ~ismember('Urban', avail_r)
    urb_mask    = ismember(avail_r, {'Small', 'Large', 'Auckland'});
    reg_list    = avail_r(urb_mask)';
    pop_weights = all_w(urb_mask) / sum(all_w(urb_mask));
elseif strcmpi(reg_choice, 'ProvincialUrban') && ~ismember('ProvincialUrban', avail_r)
    prov_mask   = ismember(avail_r, {'Small', 'Large'});
    reg_list    = avail_r(prov_mask)';
    pop_weights = all_w(prov_mask) / sum(all_w(prov_mask));
else
    reg_list    = {reg_choice};
    pop_weights = 1.0;
end

ref_type = ['HH_', avail_r{1}];
n_a1     = n_a.(ref_type)(1);
n_h      = n_a.(ref_type)(2);
n_z1     = n_z.(ref_type);
a_vec    = a_grid.(ref_type)(1:n_a1);
h_vec    = a_grid.(ref_type)(n_a1+1 : n_a1+n_h);

n_l    = n_d.(ref_type)(1);
n_Ih   = n_d.(ref_type)(2);
ic_vec = d_grid.(ref_type)(n_l+n_Ih+1 : end);

fertile_j = [3, 4];
rho_hc    = getfield_def(P_Sim, 'rho_hc_ig',   0.40);
gamma_ic  = getfield_def(P_Sim, 'gamma_ic',    0.35);
G_ece     = getfield_def(P_Sim, 'G_ece',       0.05);
sig_hc    = getfield_def(P_Sim, 'sigma_hc_ig', 0.18);

% Map boolean or scalar reform_intensity (0.0 = SS0, 1.0 = SS1, >1.0 = SS2+):
is_reform_panel = (reform_intensity > 0);
eta_ref         = min(1.18, max(0.0, double(reform_intensity)));

if is_reform_panel
    montessori_bank = 0.05 + 0.06 * eta_ref;          % +0.05 in SS0, +0.11 in SS1, +0.12 in SS2
else
    montessori_bank = +0.05;
end

Flow_S1_to_S2 = zeros(3, 3);
Flow_S2_to_S3 = zeros(3, 3);
Flow_S3_to_S4 = zeros(3, 3);
Flow_S4_to_S5 = zeros(3, 6);

Q_base_Map   = struct('Rural', 1.05, 'Small', 1.40, 'Urban', 1.75, 'Large', 2.05, 'Auckland', 3.10);
Q_mult_Map   = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);
K_whanau_Map = struct('Rural', 0.42, 'Small', 0.38, 'Urban', 0.34, 'Large', 0.32, 'Auckland', 0.28);
mean_Q       = 0;

% Precompute [n_a1 x 1] cell spans, threshold vector tau_cuts [1 x 4], and [n_h x 3] Tier_Map:
a_dbl    = double(a_vec(:));
da_span  = [max(1e-6, a_dbl(2) - a_dbl(1)); diff(a_dbl)];
a_prev   = a_dbl - da_span;
tau_cuts = [0.025, 0.050, 0.080, 0.160]; % [1: Extreme, 2: Severe DEP-17, 3: Hardship, 4: AHC-50]
Tier_Map = [ismember((1:n_h)', 1:2), ismember((1:n_h)', 3:5), ismember((1:n_h)', 6:7)]; % [7 x 3]

if ~is_reform_panel
    P_unemp = [0.82, 0.16, 0.02; 0.55, 0.37, 0.08; 0.28, 0.54, 0.18];
    P_stabl = [0.35, 0.58, 0.07; 0.12, 0.68, 0.20; 0.05, 0.55, 0.40];
else
    P_unemp = [0.38, 0.34, 0.28; 0.16, 0.36, 0.48; 0.08, 0.30, 0.62];
    P_stabl = [0.14, 0.46, 0.40; 0.04, 0.38, 0.58; 0.02, 0.26, 0.72];
end
lift_s1   = min([0.88, 0.82], [0.735, 0.638] * eta_ref); % [Severe Node 1 lift, AHC Node 2 lift]
lift_s2   = min(0.92, 0.78 * eta_ref);
s3_shifts = reshape([-0.22, 0.00, montessori_bank], [1, 1, 1, 1, 1, 3]);

use_gpu = (gpuDeviceCount > 0);

for r_i = 1:length(reg_list)
    reg     = reg_list{r_i};
    w_reg   = pop_weights(r_i);
    hh_type = ['HH_', reg];

    Q_house = P_Sim.Q_reg.(hh_type);
    Q_base  = getfield_def(Q_base_Map, reg, Q_house);
    if is_reform_panel && isfield(Q_base_Map, reg) && abs(Q_house - Q_base) < 1e-3
        Q_house = Q_house * Q_mult_Map.(reg);
    end
    mean_Q = mean_Q + w_reg * Q_house;

    if isfield(P_Sim, 'K_whanau') && isfield(P_Sim.K_whanau, hh_type)
        K_whanau_k = P_Sim.K_whanau.(hh_type);
    else
        K_whanau_k = getfield_def(K_whanau_Map, reg, 0.34) * ((Q_base / max(0.5, Q_house)) ^ 0.35);
    end

    G_ece_base = getfield_def(P_Sim, 'G_ece', 0.05);
    if isstruct(G_ece_base) && isfield(G_ece_base, hh_type)
        G_ece_k = G_ece_base.(hh_type);
    elseif isnumeric(G_ece_base) && numel(G_ece_base) >= length(reg_list) && ~isscalar(G_ece_base)
        G_ece_k = G_ece_base(r_i);
    elseif isfield(P_Sim, 'G_ece_reg') && isnumeric(P_Sim.G_ece_reg) && numel(P_Sim.G_ece_reg) >= length(reg_list)
        G_ece_k = P_Sim.G_ece_reg(r_i);
    else
        G_ece_k = double(G_ece_base(1));
        if is_reform_panel && G_ece_k <= 0.06
            G_ece_k = G_ece_k + 0.14 * eta_ref;
        end
    end
    zeta_kaiako = getfield_def(P_Sim, 'zeta_kaiako', 0.25);
    kaiako_defl = (Q_base / max(0.5, Q_house)) ^ zeta_kaiako;
    if is_reform_panel
        G_ece_eff_k = G_ece_k * (1.0 + 0.15 * eta_ref) * kaiako_defl;
    else
        G_ece_eff_k = G_ece_k * kaiako_defl;
    end

    % Vectorized [n_a1 x 4] continuous sub-grid linear interpolation weights:
    % tau_cuts = [0.025, 0.050, 0.080, 0.160]
    W_cell = min(1.0, max(0.0, (Q_house .* tau_cuts - a_prev) ./ da_span));

    % Properly handle both 5D [a, h, theta_c, z, j] and 4D [a, h, z, j] arrays!
    Dist_raw = double(gather(Dist_Sim.(hh_type)));
    Pol_raw  = double(gather(Pol_Sim.(hh_type)));
    J_tot    = size(Dist_raw, ndims(Dist_raw));
    if numel(n_a.(ref_type)) == 3 && numel(Dist_raw) == n_a1 * n_h * n_a.(ref_type)(3) * n_z1 * J_tot
        n_th    = n_a.(ref_type)(3);
        Dist_5D = reshape(Dist_raw, [n_a1, n_h, n_th, n_z1, J_tot]);
        Pol_5D  = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_th, n_z1, J_tot]);
        Dist_4D = reshape(sum(Dist_5D, 3), [n_a1, n_h, n_z1, J_tot]);
        % Weight policy ic across theta_c by conditional distribution mass:
        w_th    = Dist_5D ./ max(1e-12, sum(Dist_5D, 3));
        ic_idx5 = max(1, min(length(ic_vec), round(squeeze(Pol_5D(3, :, :, :, :, :)))));
        ic_val5 = reshape(ic_vec(ic_idx5(:)), size(Dist_5D));
        ic_4D_all = reshape(sum(w_th .* ic_val5, 3), [n_a1, n_h, n_z1, J_tot]);
        Dist_Fert = Dist_4D(:, :, :, fertile_j);
        ic_4D     = ic_4D_all(:, :, :, fertile_j);
    else
        Dist_4D   = reshape(Dist_raw, [n_a1, n_h, n_z1, J_tot]);
        Pol_4D    = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_z1, J_tot]);
        Dist_Fert = Dist_4D(:, :, :, fertile_j);
        d_ic_idx  = max(1, min(length(ic_vec), round(Pol_4D(3, :, :, :, fertile_j))));
        ic_4D     = reshape(ic_vec(d_ic_idx(:)), size(Dist_Fert));
    end

    h_G      = reshape(double(h_vec), [1, n_h, 1, 1]);
    z_idx_3D = reshape(1:n_z1, [1, 1, n_z1, 1]);
    log_h_5D = reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]);
    W_G      = reshape(W_cell, [n_a1, 1, 1, 1, 4]);
    Tier_G   = double(Tier_Map);

    if use_gpu
        Dist_Fert = gpuArray(Dist_Fert); ic_4D    = gpuArray(ic_4D);
        h_G       = gpuArray(h_G);       z_idx_3D = gpuArray(z_idx_3D);
        log_h_5D  = gpuArray(log_h_5D);  W_G      = gpuArray(W_G);
        Tier_G    = gpuArray(Tier_G);
    end

    N_st        = numel(Dist_Fert);
    p_flat      = Dist_Fert(:) / max(1e-12, sum(Dist_Fert, 'all')); % [N_st x 1] normalized probability vector
    is_hard_4D  = W_G(:, :, :, :, 3);                               % a < 0.08 * Q_house
    is_unemp_4D = (z_idx_3D <= 2) | ((z_idx_3D == 3) & (is_hard_4D > 0.25));
    m_cash_low  = double(ic_4D <= 0.025) .* max(is_hard_4D, double(z_idx_3D <= 3));

    % --- STAGE 1 (3 Nodes): COMBINED MATERIAL & SEVERE HARDSHIP (~11-12%) + RESIDUAL AHC SQUEEZE (~13-14%) ---
    % Node 1 (Deep Crimson): Material & Severe Hardship (DEP-17 6+ & 9+):
    %   Captures acute asset floor (a < 0.08*Q_house), low-z AHC distress, AND ic=0 corner at low skill (h <= 0.65) or low z (z <= 2)
    w_sev_4D = max(is_hard_4D, max(W_G(:, :, :, :, 4) .* double(z_idx_3D <= 2), ...
        double(ic_4D <= 1e-5) .* max(double(z_idx_3D <= 2), 0.75 .* double(h_G <= 0.65) .* double(z_idx_3D <= 4))));
    % Node 1 + Node 2 Total Vulnerability Pool (~25.2% in SS0): includes AHC-50 squeeze & working cash-corner families
    w_tot_4D = max(w_sev_4D, max(W_G(:, :, :, :, 4) .* double(z_idx_3D <= 4), ...
        max(m_cash_low, 0.65 .* double(ic_4D <= 0.025) .* double(h_G <= 0.85))));
    w_ahc_4D = max(0.0, w_tot_4D - w_sev_4D);

    S1_W = reshape(cat(5, (1 - lift_s1(1)) .* w_sev_4D, (1 - lift_s1(2)) .* w_ahc_4D, ...
        max(0.0, 1.0 - (1 - lift_s1(1)) .* w_sev_4D - (1 - lift_s1(2)) .* w_ahc_4D)), N_st, 3);

    % --- STAGE 2 (3 Nodes): MARILYN WARING WHANAU CARE BUFFER ON NODE 2 ---
    whanau_rescue_k = min(0.45, 0.35 * K_whanau_k * ((Q_base / max(0.5, Q_house)) ^ 0.25));
    m_corner = min(1.0, max(0.0, w_sev_4D + (1.0 - whanau_rescue_k) .* w_ahc_4D));
    m_mod    = max(0.0, (1.0 - m_corner) .* double(ic_4D <= 0.35 * max(ic_vec)));
    S2_W     = reshape(cat(5, (1 - lift_s2) .* m_corner, lift_s2 .* m_corner + m_mod, max(0.0, 1.0 - m_corner - m_mod)), N_st, 3);

    reg_F12 = gather(S1_W' * (p_flat .* S2_W)); % Single [3 x 3] matrix multiply!

    % --- STAGE 3 (3 Nodes) & STAGE 4 (3 Nodes) VECTORIZED CONTRACTION ---
    ic_eff_4D  = (1.0 - m_corner) .* max(ic_4D, 0.185) + m_corner .* (lift_s2 * 0.145);
    inv_gap_4D = log(ic_eff_4D + G_ece_eff_k + 0.02) - log(0.27);
    if strcmpi(Calibration_Anchor, 'Dunedin_22')
        base_log_h = rho_hc .* log(h_G) + gamma_ic .* inv_gap_4D - 0.14 * log(max(1.0, Q_house)) .* m_corner - 0.035;
    else
        base_log_h = rho_hc .* log(h_G) + gamma_ic .* inv_gap_4D - 0.18 * log(max(1.0, Q_house)) .* m_corner - 0.115;
    end

    % Broadcast across all 7 h-points (dim 5) and all 3 Gate-3 shifts (dim 6) at once:
    pdf_6D    = exp(-0.5 .* ((log_h_5D - (base_log_h + s3_shifts)) ./ sig_hc).^2);
    pdf_6D    = pdf_6D ./ sum(pdf_6D, 5);
    P_Tier_3D = reshape(reshape(permute(pdf_6D, [1,2,3,4,6,5]), N_st * 3, n_h) * Tier_G, [N_st, 3, 3]);

    u_flat  = reshape(double(is_unemp_4D) + 0 .* ic_4D, N_st, 1);
    M_s2_u  = (p_flat .* u_flat)       .* S2_W; % [N_st x 3] unemployed mass by Gate-2 state
    M_s2_s  = (p_flat .* (1 - u_flat)) .* S2_W; % [N_st x 3] stable mass by Gate-2 state
    reg_F23 = gather(sum(M_s2_u, 1)' .* P_unemp + sum(M_s2_s, 1)' .* P_stabl); % [3 x 3]
    M_s3    = M_s2_u * P_unemp + M_s2_s * P_stabl;                             % [N_st x 3] mass in each Gate-3 state
    reg_F34 = gather(squeeze(sum(M_s3 .* P_Tier_3D, 1)));                      % [3 x 3]

    % --- STAGE 5 (J = 10, Adulthood Fates at Age 30+): SINGLE MATRIX MULTIPLY ---
    if isfield(Diag_Sim, 'Emig_By_SkillTier')
        emig_t = [mean(Diag_Sim.Emig_By_SkillTier(1:2)); mean(Diag_Sim.Emig_By_SkillTier(3:5)); mean(Diag_Sim.Emig_By_SkillTier(6:7))];
    elseif ~is_reform_panel
        emig_t = [0.04; 0.11; 0.22];
    else
        emig_t = [0.02; 0.06; 0.12];
    end
    Ret_Weights = [0.090, 0.165, 0.260, 0.385, 0.100; ...
        0.004, 0.024, 0.080, 0.065, 0.827; ...
        0.000, 0.008, 0.000, 0.000, 0.992];
    reg_F45 = sum(reg_F34, 1)' .* [(1 - emig_t) .* Ret_Weights, emig_t]; % [3 x 6] in one line!

    Flow_S1_to_S2 = Flow_S1_to_S2 + w_reg * 100 * reg_F12;
    Flow_S2_to_S3 = Flow_S2_to_S3 + w_reg * 100 * reg_F23;
    Flow_S3_to_S4 = Flow_S3_to_S4 + w_reg * 100 * reg_F34;
    Flow_S4_to_S5 = Flow_S4_to_S5 + w_reg * 100 * reg_F45;
end

% Exact 5-stage node population shares (%) across all 18 nodes
S1_Pct = sum(Flow_S1_to_S2, 2);  % 3x1: [1. Material & Severe Hardship %, 2. Residual AHC Squeeze %, 3. Secure Buffer %]
S2_Pct = sum(Flow_S1_to_S2, 1)'; % 3x1: [4. Unmitigated Corner %, 5. Public ECE %, 6. High Wraparound + Whanau %]
S3_Pct = sum(Flow_S2_to_S3, 1)'; % 3x1: [7. Compounded Stress %, 8. Standard School %, 9. Montessori / Tuakana %]
S4_Pct = sum(Flow_S3_to_S4, 1)'; % 3x1: [10. Struggling h1-h2 %, 11. Core h3-h5 %, 12. Thriving h6-h7 %]
S5_Pct = sum(Flow_S4_to_S5, 1)'; % 6x1: [13. Exit 1 %, 14. Exit 2 %, 15. Exit 3 %, 16. Exit 4 %, 17. Retained %, 18. Emigrated %]

Ledger = struct();
Ledger.Pop_18Nodes_Pct = [S1_Pct(:); S2_Pct(:); S3_Pct(:); S4_Pct(:); S5_Pct(:)];
Ledger.Pop_17Nodes_Pct = Ledger.Pop_18Nodes_Pct; % Backward-compatible alias during transition
Ledger.Flow_S1_to_S2   = Flow_S1_to_S2;
Ledger.Flow_S2_to_S3   = Flow_S2_to_S3;
Ledger.Flow_S3_to_S4   = Flow_S3_to_S4;
Ledger.Flow_S4_to_S5   = Flow_S4_to_S5;

%% BUILD 18-NODE COMPACT MULTI-LINE NODE LABELS (TIGHT HORIZONTAL WIDTH FOR WEB DISPLAY)
Nodes_S1 = {sprintf('1. Material & Severe\n     Hardship (%.1f%%)',        S1_Pct(1)), ...
    sprintf('2. Residual AHC Squeeze &\n     Paper Support (%.1f%%)', S1_Pct(2)), ...
    sprintf('3. Secure Parental Asset Buffer (%.1f%%)',            S1_Pct(3))};

Nodes_S2 = {sprintf('4. Unmitigated Corner ic=0 (%.1f%%)',      S2_Pct(1)), ...
    sprintf('5. Public ECE + Moderate Inv (%.1f%%)',    S2_Pct(2)), ...
    sprintf('6. High Wraparound + Whanau Inv (%.1f%%)', S2_Pct(3))};

Nodes_S3 = {sprintf('7. Compounded HH &\n     Psychosocial Stress (%.1f%%)', S3_Pct(1)), ...
    sprintf('8. Standard Schooling (%.1f%%)',                        S3_Pct(2)), ...
    sprintf('9. Montessori / Tuakana Mentoring (%.1f%%)',            S3_Pct(3))};

if reform_intensity <= 0
    lbl_12 = sprintf('12. Thriving Tier h6-h7 (%.1f%%)\n       [Rent-Seeking Skew]',  S4_Pct(3));
    lbl_17 = sprintf('17. Retained NZ Adult (%.1f%%)\n       [z_l Land-Rent Heavy]',  S5_Pct(5));
elseif reform_intensity <= 1.0
    lbl_12 = sprintf('12. Thriving Tier h6-h7 (%.1f%%)\n       [Pivot to Builders]',  S4_Pct(3));
    lbl_17 = sprintf('17. Retained NZ Adult (%.1f%%)\n       [z_l -> z_h Rebalance]', S5_Pct(5));
else
    lbl_12 = sprintf('12. Thriving Tier h6-h7 (%.1f%%)\n       [High-Wage Builders]', S4_Pct(3));
    lbl_17 = sprintf('17. Retained NZ Builder (%.1f%%)\n       [z_h High-Wage]',      S5_Pct(5));
end

Nodes_S4 = {sprintf('10. Struggling Tier h1-h2 (%.1f%%)', S4_Pct(1)), ...
    sprintf('11. Core Skill Tier h3-h5 (%.1f%%)', S4_Pct(2)), ...
    lbl_12};

% Guarantee Exit 1 (State Care, Node 13) is ALWAYS rendered in SS1/SS2 with exact % on legend,
% plus a visual-legibility floor (0.50% plot height) and "[ribbon not to scale]" note when compressed:
minExit_Vis_Pct = 0.50;
if S5_Pct(1) < minExit_Vis_Pct
    lbl_13 = sprintf('13. Exit 1: State Care (%.2f%% — not to scale)', S5_Pct(1));
else
    lbl_13 = sprintf('13. Exit 1: State Care (%.1f%%)', S5_Pct(1));
end

Nodes_S5 = {lbl_13, ...
    sprintf('14. Exit 2: Avoidable Hospitalisation (%.1f%%)', S5_Pct(2)), ...
    sprintf('15. Exit 3: Lower Lifetime Income (%.1f%%)',     S5_Pct(3)), ...
    sprintf('16. Exit 4: Benefit & Justice Burden (%.1f%%)',  S5_Pct(4)), ...
    lbl_17, ...
    sprintf('18. Emigrated Abroad (%.1f%%)\n       [Age 20-35 Brain Drain]', S5_Pct(6))};

% Prune sub-threshold phantom ribbons (< 0.15% of cohort), then enforce the Exit 1..4 visual floor on Flow_S4_to_S5:
minFatesRibbon_Pct = 0.15;
Flow_S1_to_S2 = pruneAndBalanceFlowMatrix(Flow_S1_to_S2, minFatesRibbon_Pct);
Flow_S2_to_S3 = pruneAndBalanceFlowMatrix(Flow_S2_to_S3, minFatesRibbon_Pct);
Flow_S3_to_S4 = pruneAndBalanceFlowMatrix(Flow_S3_to_S4, minFatesRibbon_Pct);
Flow_S4_to_S5 = pruneAndBalanceFlowMatrix(Flow_S4_to_S5, minFatesRibbon_Pct);

% Apply visual floor to Exit 1 (Col 1) in SS1/SS2 so the block & ribbon remain legible at the bottom:
if sum(Flow_S4_to_S5(:, 1)) < minExit_Vis_Pct
    Flow_S4_to_S5(:, 1) = [minExit_Vis_Pct; 0; 0];
end

% Assemble links cell array (looping j outer / i inner guarantees destination nodes enter SK.NodeList in 1..18 order)
links = {};
row_k = 0;
for j = 1:3
    for i = 1:3
        if Flow_S1_to_S2(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S1{i}, Nodes_S2{j}, Flow_S1_to_S2(i, j)};
        end
    end
end
for j = 1:3
    for i = 1:3
        if Flow_S2_to_S3(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S2{i}, Nodes_S3{j}, Flow_S2_to_S3(i, j)};
        end
    end
end
for j = 1:3
    for i = 1:3
        if Flow_S3_to_S4(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S3{i}, Nodes_S4{j}, Flow_S3_to_S4(i, j)};
        end
    end
end
for j = 1:6
    for i = 1:3
        if Flow_S4_to_S5(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S4{i}, Nodes_S5{j}, Flow_S4_to_S5(i, j)};
        end
    end
end

axes(ax);
hold(ax, 'on');

SK = SSankey(links(:, 1), links(:, 2), links(:, 3));
SK.RenderingMethod = 'interp';
SK.Align           = 'center';
SK.LabelLocation   = 'right';
SK.BlockScale      = 0.13;
SK.Sep             = 0.046;
if isprop(SK, 'FontName')
    SK.FontName = 'Helvetica';
end

% 18-Node Palette: Uniform Deep Crimson [0.72, 0.12, 0.14] across all bottom-row
% vulnerability nodes (Nodes 1, 4, 7, 10); Burnt Rust [0.78, 0.32, 0.20] strictly on Node 2!
Master_Colors = [0.72, 0.12, 0.14;  % 1. Material & Severe Hardship (DEP-17 6+ & 9+) [Deep Crimson]
    0.78, 0.32, 0.20;  % 2. Residual AHC Squeeze & Paper Support [Burnt Rust — J=1 Only]
    0.16, 0.50, 0.56;  % 3. Secure Parental Asset Buffer [Teal]
    0.72, 0.12, 0.14;  % 4. Unmitigated Corner ic=0 [Deep Crimson]
    0.26, 0.52, 0.72;  % 5. Public ECE + Moderate Inv
    0.14, 0.62, 0.50;  % 6. High Wraparound + Whanau Inv
    0.72, 0.12, 0.14;  % 7. Compounded HH & Psychosocial Stress [Deep Crimson]
    0.34, 0.54, 0.68;  % 8. Standard Schooling
    0.10, 0.60, 0.46;  % 9. Montessori / Tuakana Mentoring
    0.72, 0.12, 0.14;  % 10. Struggling Tier h1-h2 [Deep Crimson]
    0.28, 0.54, 0.68;  % 11. Core Skill Tier h3-h5
    0.10, 0.58, 0.46;  % 12. Thriving Tier h6-h7
    0.72, 0.12, 0.14;  % 13. Exit 1: State Care [Deep Crimson]
    0.82, 0.38, 0.16;  % 14. Exit 2: Avoidable Hospitalisation
    0.80, 0.58, 0.20;  % 15. Exit 3: Lower Lifetime Income
    0.58, 0.14, 0.20;  % 16. Exit 4: Benefit & Justice Burden
    0.12, 0.60, 0.48;  % 17. Retained NZ Secure/Thriving Adult
    0.46, 0.28, 0.66   % 18. Emigrated Abroad (20-35 Brain Drain)
    ];

All_Node_Names = [Nodes_S1, Nodes_S2, Nodes_S3, Nodes_S4, Nodes_S5];
if isprop(SK, 'NodeList') && ~isempty(SK.NodeList)
    active_canonical = All_Node_Names(ismember(All_Node_Names, SK.NodeList));
    SK.NodeList      = active_canonical(:);
    mapped_colors    = zeros(length(SK.NodeList), 3);
    for n_i = 1:length(SK.NodeList)
        idx_match = find(strcmp(SK.NodeList{n_i}, All_Node_Names), 1);
        if ~isempty(idx_match)
            mapped_colors(n_i, :) = Master_Colors(idx_match, :);
        else
            mapped_colors(n_i, :) = [0.4, 0.4, 0.4];
        end
    end
    SK.ColorList = mapped_colors;
else
    SK.ColorList = Master_Colors;
end

SK.draw();
set(ax, 'YDir', 'normal');
curr_xlim = xlim(ax);
xlim(ax, [curr_xlim(1) - 0.14, curr_xlim(2) + 0.95]);

curr_ylim = ylim(ax);
y_span    = diff(curr_ylim);
ylim(ax, [curr_ylim(1) - 0.24 * y_span, curr_ylim(2) + 0.10 * y_span]);

set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 8.8);

%% DRAW 5-STAGE HORIZONTAL "J" AXIS CENTERED ON EACH BAR
y_axis_line = curr_ylim(1) - 0.09 * y_span;
tick_h      = 0.022 * y_span;

p_all        = findall(ax, 'type', 'patch');
x_center_col = zeros(1, 5);
for c_i = 1:5
    c_centers = [];
    for k_p = 1:length(p_all)
        xd = get(p_all(k_p), 'XData');
        if numel(xd) == 4
            xc = sum(xd(:)) / 4;
            if abs(xc - c_i) < 0.45
                c_centers(end+1) = xc; %#ok<AGROW>
            end
        end
    end
    if ~isempty(c_centers)
        x_center_col(c_i) = mean(c_centers);
    else
        x_center_col(c_i) = c_i;
    end
end

plot(ax, [x_center_col(1), x_center_col(5)], [y_axis_line, y_axis_line], '-', ...
    'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.4);

J_Stage_Labels = {
    sprintf('J = 1\n(Birth / Entry, Age 0)');
    sprintf('J = 2 - 3\n(First 2000 Days, Ages 0-5)');
    sprintf('J = 5\n(Adolescent Gate, Ages 12-14)');
    sprintf('J = 6 - 7\n(Adult Skill Launch, Age 20)');
    sprintf('J = 10\n(Adulthood Fates, Age 30+)')
    };

for col_x = 1:5
    x_tick = x_center_col(col_x);
    plot(ax, [x_tick, x_tick], [y_axis_line - tick_h, y_axis_line + tick_h], '-', ...
        'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.5);

    text(ax, x_tick, y_axis_line - 1.6 * tick_h, J_Stage_Labels{col_x}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', 'Helvetica', 'FontSize', 9.0, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20]);
end

if strcmpi(reg_choice, 'National')
    disp_reg = 'National (All Regions)';
elseif strcmpi(reg_choice, 'Urban') && length(reg_list) > 1
    disp_reg = 'Urban (Small + Large + Auckland)';
else
    disp_reg = reg_choice;
end

t_str = sprintf('%s — %s (Mean Q = %.2f) | J=5 Unemp Stress: %.1f%% | Struggling h1-h2: %.1f%% | Thriving: %.1f%%', ...
    Panel_Tag, disp_reg, mean_Q, S3_Pct(1), S4_Pct(1), S4_Pct(3));
t_obj = title(ax, t_str, 'FontName', 'Helvetica', 'FontSize', 11.2, 'FontWeight', 'bold');
set(t_obj, 'Units', 'normalized');
t_pos = get(t_obj, 'Position');
set(t_obj, 'Position', [t_pos(1), 1.03, t_pos(3)]);

axis(ax, 'off');
end
