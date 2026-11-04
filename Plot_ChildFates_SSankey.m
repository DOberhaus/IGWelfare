%% PLOT_CHILDFATES_2PANEL_SSANKEY.M
% 5-Stage (18-Node) Pairwise N-Panel Cohort Population Sankey Diagram (A3 Layout, 100% GPU-Vectorized)
% Synchronized with Plot_ChildFiscal_SSankey.m (Table 14) and exports Table 15 CSVs:
%   - Gate 1 (J = 1, Birth / Entry, Age 0):
%       (1) Severe Material Hardship DEP-17 9+ (~9.8% SS0 -> ~2.6% SS1) [Deep Crimson]
%       (2) Residual AHC Squeeze & Paper Support (~14.2% SS0 -> ~5.1% SS1) [Burnt Rust]
%       (3) Secure Parental Asset Buffer (~76.0% SS0 -> ~92.3% SS1) [Teal]
%   - Gate 2 (J = 2..3, First 2000 Days ECE Gate, Ages 0-5):
%       (4) Unmitigated Corner ic=0 (~24.0% -> ~5.7%), (5) Public ECE + Moderate Inv, (6) High Wraparound + Whanau Inv
%   - Gate 3 (J = 5, Adolescent Gate, Ages 12-14):
%       (7) Compounded HH & Psychosocial Stress (~18.9% -> ~4.9%), (8) Standard Schooling, (9) Montessori / Tuakana Mentoring (~17.3% -> ~57.3%)
%   - Gate 4 (J = 6..7, Adult Skill Launch, Age 20):
%       (10) Struggling Tier h1-h2 (~22.0% -> ~4.0%), (11) Core Skill Tier h3-h5 (~54.5% -> ~38.7%), (12) Thriving Tier h6-h7 (~23.5% -> ~57.3%)
%   - Gate 5 (J = 10, Adulthood Fates, Age 30+):
%       (13) Exit 1: State Care, (14) Exit 2: Avoidable Hospitalisation, (15) Exit 3: Lower Lifetime Income,
%       (16) Exit 4: Benefit & Justice Burden, (17) Retained NZ Secure/Thriving Adult, (18) Emigrated Abroad (20-35 Brain Drain)

%% 1. CONFIGURATION SWITCHES (N-PHASE COMPATIBLE: 1, 2, 3, OR MORE PANELS)
Target_Regions     = {'National', 'Auckland', 'Large', 'Small', 'Rural', 'Urban'};
if ischar(Target_Regions) || isstring(Target_Regions), Target_Regions = cellstr(Target_Regions); end

% Specify any 1, 2, 3, or N phases: e.g. {'SS0'}, {'SS0','SS1'}, or {'SS0','SS1','SS2'}
if ~exist('Active_Phases', 'var') || isempty(Active_Phases)
    Active_Phases = {'SS0', 'SS1', 'SS2'};
end

Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' or 'MetroSqueeze_GUiNZ'
Merge_Orientation  = 'Vertical';   % 'Vertical' (Stacked Top/Bottom for A3) or 'Horizontal'

NZD_Base_Scale         = 95.0;     % 1.0 model unit = 95.0 kNZD/yr (mean prime household earnings)
Interactive_Hover_Mode = true;     % TRUE = keep live vector SSankey figure open for mouse-hover narratives

if ~exist('OutputDir', 'var') || ~isfolder(OutputDir)
    if isfolder('Output_NZ_4Region_Intergen')
        OutputDir = 'Output_NZ_4Region_Intergen';
    else
        OutputDir = pwd;
    end
end

%% 2. ASSEMBLE N-PHASE REGISTRY (SUPPORTS 1, 2, 3, ... N PHASES)
Phases   = Build_Phase_Registry(Active_Phases);
N_phases = numel(Phases);

%% 3. RENDER 1..N PANELS ON A3 CANVASES, STITCH, AND EXPORT N-PHASE TABLE 15 CSVs
FatesLedger = struct();

Fate_Gates = { ...
    'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
    'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
    'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'; ...
    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'};

Fate_Node_Names = { ...
    '1_Severe_Material_Hardship_DEP17';    '2_Residual_AHC_Squeeze_Paper_Support'; '3_Secure_Parental_Asset_Buffer'; ...
    '4_Unmitigated_Corner_ic0';            '5_Public_ECE_Moderate_Inv';            '6_High_Wraparound_Whanau_Inv'; ...
    '7_Compounded_HH_Psychosocial_Stress'; '8_Standard_Public_Schooling';          '9_Montessori_Tuakana_Mentoring'; ...
    '10_Struggling_Tier_h1_h2';            '11_Core_Skill_Tier_h3_h5';             '12_Thriving_Tier_h6_h7'; ...
    '13_Exit1_State_Care';                 '14_Exit2_Avoidable_Hospitalisation';   '15_Exit3_Lower_Lifetime_Income'; ...
    '16_Exit4_Benefit_Justice_Burden';     '17_Retained_NZ_Secure_Thriving';       '18_Emigrated_Abroad_BrainDrain'};

for r_loop = 1:length(Target_Regions)
    Target_Region = Target_Regions{r_loop};
    Out_PNG_Name  = sprintf('Fig_ChildFates_5Stage_%dPanel_%s_%s.png', ...
        N_phases, Target_Region, Calibration_Anchor);

    %% 3.1 RENDER EACH PHASE p = 1..N_phases
    Panel_Imgs    = cell(1, N_phases);
    Phase_Ledgers = cell(1, N_phases);
    Pop_Mat       = zeros(18, N_phases);

    for p = 1:N_phases
        p_code = Phases(p).Code;
        figP   = figure('Name', sprintf('LIVE HOVER — %s (%s)', Phases(p).Label, Target_Region), ...
            'Color', 'w', 'Position', [20, 40, 1850, 820], 'Visible', 'on');
        axP    = axes('Parent', figP, 'Position', [0.02, 0.07, 0.95, 0.85]);

        [F_p, SK_p, links_p] = Build_And_Render_Fates_Panel(axP, Target_Region, ...
            Phases(p).Dist, Phases(p).Pol, Phases(p).Params, Phases(p).Diag, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, ...
            Phases(p).Label, Calibration_Anchor, NZD_Base_Scale, Phases(p).Intensity);
        drawnow;

        % 1. Capture high-res raster image BEFORE attaching interactive hover UI
        Panel_Imgs{p} = AutoCrop_White_Border(print(figP, '-RGBImage', '-r300'));

        % 2. If Interactive_Hover_Mode is enabled, wire up hover callbacks & keep figure open!
        if Interactive_Hover_Mode && strcmpi(Target_Region, 'National')
            fatesNarrativeMap = getFatesRibbonNarratives(p_code);
            attachSankeyHoverNarratives(axP, SK_p, links_p, fatesNarrativeMap, '%.1f%% of cohort');
            html_fname = fullfile(OutputDir, sprintf('Interactive_ChildFates_%s_%s.html', p_code, Target_Region));
            exportSankeyToHTML(axP, SK_p, links_p, fatesNarrativeMap, '%.1f%% of cohort', html_fname);
        else
            close(figP);
        end

        Phase_Ledgers{p}                        = F_p;
        FatesLedger.(Target_Region).(p_code)    = F_p;
        FatesLedger.(p_code)                    = F_p;
        Pop_Mat(:, p) = reshape(F_p.Pop_18Nodes_Pct, 18, 1);
    end

    %% 3.2 STITCH 1..N PANELS CLEANLY
    [img_Merged, fig_pos] = Stitch_NPanels_Canvas(Panel_Imgs, Merge_Orientation);

    imwrite(img_Merged, fullfile(OutputDir, Out_PNG_Name));
    fprintf('\nSaved %d-panel 5-stage Child Fates Sankey image to: %s\n', N_phases, fullfile(OutputDir, Out_PNG_Name));

    %% 3.3 BUILD CUSTOM 18-NODE TABLE 15 CSV FOR 1, 2, 3, ... N PHASES
    T_FatesCSV = table(Fate_Gates, Fate_Node_Names, 'VariableNames', {'Gate', 'Node_Name'});
    for p = 1:N_phases
        T_FatesCSV.([Phases(p).Code, '_Pop_Pct']) = round(Pop_Mat(:, p), 2);
    end
    if N_phases == 2
        T_FatesCSV.Reform_Delta_PctPt = round(Pop_Mat(:, 2) - Pop_Mat(:, 1), 2);
    elseif N_phases >= 3
        for p = 2:N_phases
            col_d = sprintf('Delta_%s_vs_%s_PctPt', Phases(p).Code, Phases(p-1).Code);
            T_FatesCSV.(col_d) = round(Pop_Mat(:, p) - Pop_Mat(:, p-1), 2);
        end
        col_cum = sprintf('Cumul_%s_vs_%s_PctPt', Phases(N_phases).Code, Phases(1).Code);
        T_FatesCSV.(col_cum) = round(Pop_Mat(:, N_phases) - Pop_Mat(:, 1), 2);
    end

    fates_csv_fname = fullfile(OutputDir, sprintf('Table15_ChildFates_5Stage_Decomp_%s.csv', Target_Region));
    writetable(T_FatesCSV, fates_csv_fname);
    FatesLedger.(Target_Region).Table15_Decomp = T_FatesCSV;
    fprintf('  -> Exported %d-Phase (18-Node) Child Fates CSV to: %s\n', N_phases, fates_csv_fname);

    fig_Merged = figure('Name', sprintf('%d-Panel 5-Stage Child Fates Sankey: %s', N_phases, Target_Region), ...
        'Color', 'w', 'Position', fig_pos);
    ax_M = axes('Parent', fig_Merged, 'Position', [0, 0, 1, 1]);
    imshow(img_Merged, 'Parent', ax_M, 'Border', 'tight');
    axis(ax_M, 'off');
end

%% ========================================================================
%  LOCAL HELPER: GPU-VECTORIZED 5-STAGE (18-NODE) CHILD FATES SANKEY
%  ========================================================================
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
    if G_ece <= 0.06, G_ece = G_ece + 0.14 * eta_ref; end
    G_ece_eff       = G_ece * (1.0 + 0.15 * eta_ref); % Montessori / Tuakana downward multiplier
    montessori_bank = 0.05 + 0.06 * eta_ref;          % +0.05 in SS0, +0.11 in SS1, +0.12 in SS2
else
    G_ece_eff       = G_ece;
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

% Precompute lower cell boundaries a_{i-1} for continuous sub-grid linear interpolation on a_vec:
a_dbl      = double(a_vec(:));
da_first   = max(1e-6, a_dbl(2) - a_dbl(1));
a_prev_dbl = [a_dbl(1) - da_first; a_dbl(1:end-1)];
da_span    = max(1e-8, a_dbl - a_prev_dbl);

use_gpu = (gpuDeviceCount > 0);

for r_i = 1:length(reg_list)
    reg     = reg_list{r_i};
    w_reg   = pop_weights(r_i);
    hh_type = ['HH_', reg];
    Dist_k  = Dist_Sim.(hh_type);
    Pol_k   = Pol_Sim.(hh_type);

    Q_house = P_Sim.Q_reg.(hh_type);
    Q_base  = Q_house;
    if isfield(Q_base_Map, reg), Q_base = Q_base_Map.(reg); end
    if is_reform_panel && isfield(Q_base_Map, reg) && abs(Q_house - Q_base_Map.(reg)) < 1e-3
        Q_house = Q_house * Q_mult_Map.(reg);
    end
    mean_Q = mean_Q + w_reg * Q_house;

    % Extract effective regional alloparental whanau care capacity K_whanau(k) (Marilyn Waring buffer)
    if isfield(P_Sim, 'K_whanau') && isfield(P_Sim.K_whanau, hh_type)
        K_whanau_k = P_Sim.K_whanau.(hh_type);
    elseif isfield(K_whanau_Map, reg)
        K_whanau_k = K_whanau_Map.(reg) * ((Q_base / max(0.5, Q_house)) ^ 0.35);
    else
        K_whanau_k = 0.34;
    end

    if use_gpu
        Dist_G     = gpuArray(double(Dist_k));
        Pol_G      = gpuArray(double(Pol_k));
        a_G        = gpuArray(reshape(a_dbl,      [n_a1, 1, 1, 1]));
        a_prev_G   = gpuArray(reshape(a_prev_dbl, [n_a1, 1, 1, 1]));
        da_G       = gpuArray(reshape(da_span,    [n_a1, 1, 1, 1]));
        h_G        = gpuArray(reshape(double(h_vec), [1, n_h, 1, 1]));
        ic_G       = gpuArray(double(ic_vec(:)));
        z_idx_3D   = gpuArray(reshape(1:n_z1, [1, 1, n_z1, 1]));
        log_h_dst5 = gpuArray(reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]));
    else
        Dist_G     = double(Dist_k);
        Pol_G      = double(Pol_k);
        a_G        = reshape(a_dbl,      [n_a1, 1, 1, 1]);
        a_prev_G   = reshape(a_prev_dbl, [n_a1, 1, 1, 1]);
        da_G       = reshape(da_span,    [n_a1, 1, 1, 1]);
        h_G        = reshape(double(h_vec), [1, n_h, 1, 1]);
        ic_G       = double(ic_vec(:));
        z_idx_3D   = reshape(1:n_z1, [1, 1, n_z1, 1]);
        log_h_dst5 = reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]);
    end

    Dist_Fert = Dist_G(:, :, :, fertile_j);
    tot_p     = max(1e-12, gather(sum(Dist_Fert, 'all')));
    d_ic_idx  = max(1, min(length(ic_vec), Pol_G(3, :, :, :, fertile_j)));
    ic_4D     = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));

    % --- CONTINUOUS SUB-GRID LINEAR CELL INTERPOLATION WEIGHTS ON CUBIC ASSET GRID ---
    % 1. Acute Destitution Floor (tau_sev = 0.050 * Q_house) & Extreme Floor (0.025 * Q_house)
    % 2. Standard Hardship / Crowding Threshold (tau_hard = 0.080 * Q_house)
    % 3. Residual AHC-50 & Paper-Support Abatement Trap (tau_ahc = 0.160 * Q_house)
    w_cell_025 = min(1.0, max(0.0, (0.025 * Q_house - a_prev_G) ./ da_G));
    w_cell_050 = min(1.0, max(0.0, (0.050 * Q_house - a_prev_G) ./ da_G));
    w_cell_080 = min(1.0, max(0.0, (0.080 * Q_house - a_prev_G) ./ da_G));
    w_cell_160 = min(1.0, max(0.0, (0.160 * Q_house - a_prev_G) ./ da_G));

    is_hard_4D  = w_cell_080; % Continuous cell weight in [0, 1] replacing boolean (a_G < 0.08 * Q_house)
    is_unemp_4D = (z_idx_3D == 1) | (n_z1 >= 5 & (z_idx_3D == 2) & (w_cell_080 > 0.5));

    % Raw corner indicator on private cash investment ic_4D:
    m_cash_zero = double(ic_4D <= 1e-5) .* max(w_cell_080, double(z_idx_3D <= 2));

    % --- STAGE 1 (J = 1, Birth, Age 0): 3-NODE SPLIT (SEVERE DEP-17 vs RESIDUAL AHC SQUEEZE vs SECURE) ---
    % Node 1 (Deep Crimson): Severe Material Hardship (DEP-17 9+ / MSD Tier 3 High Needs, ~9.8% Nat SS0)
    w_sev_raw_4D = max(w_cell_050 .* double(z_idx_3D <= 2), w_cell_025 .* double(z_idx_3D <= 3)) .* ones(size(ic_4D));
    % Node 1 + Node 2 Total Vulnerability Pool (~24.0% Nat SS0): includes AHC-50 squeeze & cash-corner families
    w_tot_vuln_4D = max(w_sev_raw_4D, max(w_cell_160 .* double(z_idx_3D <= 2), ...
        max(w_cell_080 .* double(z_idx_3D <= 3), m_cash_zero)));
    w_ahc_raw_4D  = max(0.0, w_tot_vuln_4D - w_sev_raw_4D);

    % Reform lifts: High-intensity Tier 3 wraparound lifts Severe Node 1; Universal ECE + Q_mult lifts Node 2
    lift_s1_sev = min(0.88, 0.735 * eta_ref); % 0.00 in SS0, 0.735 in SS1 (~9.8% -> ~2.6%), 0.867 in SS2 (~1.2%)
    lift_s1_ahc = min(0.82, 0.638 * eta_ref); % 0.00 in SS0, 0.638 in SS1 (~14.2% -> ~5.1%), 0.753 in SS2 (~3.2%)

    s1_W1   = (1.00 - lift_s1_sev) .* w_sev_raw_4D;               % Node 1: Severe Material Hardship (DEP-17 9+)
    s1_W2   = (1.00 - lift_s1_ahc) .* w_ahc_raw_4D;               % Node 2: Residual AHC Squeeze & Paper Support
    s1_W3   = max(0.0, 1.00 - s1_W1 - s1_W2);                     % Node 3: Secure Parental Asset Buffer
    s1_W_5D = cat(5, s1_W1, s1_W2, s1_W3);

    % --- STAGE 2 (J = 2..3, First 2000 Days, Ages 0-5): MARILYN WARING WHANAU CARE BUFFER ---
    % In Node 2 (Residual AHC Squeeze), unpaid extended whanau care K_whanau(k) rescues a fraction of
    % cash-constrained infants out of the ic=0 corner into Moderate Investment (Node 5) in Rural/Small regions,
    % whereas high metropolitan rents Q_house and nuclear isolation in Auckland erode this unpaid care buffer:
    whanau_rescue_k = min(0.45, 0.32 * K_whanau_k * ((Q_base / max(0.5, Q_house)) ^ 0.25));
    m_corner = max(0.0, w_sev_raw_4D .* m_cash_zero + (1.0 - whanau_rescue_k) .* w_ahc_raw_4D .* m_cash_zero);
    m_mod    = max(0.0, (1.0 - m_corner) .* double((ic_4D <= 1e-5) | (ic_4D <= 0.35 * max(ic_vec))));
    m_high   = max(0.0, 1.0 - m_corner - m_mod);

    lift_s2 = min(0.92, 0.78 * eta_ref);          % 0.00 in SS0, 0.78 in SS1, 0.92 in SS2
    s2_W1   = (1.00 - lift_s2) .* m_corner;       % Node 4: Unmitigated Corner ic=0
    s2_W2   = lift_s2 .* m_corner + 1.00 .* m_mod;% Node 5: Public ECE + Moderate Inv
    s2_W3   = 1.00 .* m_high;                     % Node 6: High Wraparound + Whanau Inv
    s2_W_5D = cat(5, s2_W1, s2_W2, s2_W3);

    reg_F12 = zeros(3, 3);
    for s1_i = 1:3
        w1 = s1_W_5D(:, :, :, :, s1_i);
        for s2_i = 1:3
            w2 = s2_W_5D(:, :, :, :, s2_i);
            reg_F12(s1_i, s2_i) = gather(sum(Dist_Fert .* w1 .* w2, 'all')) / tot_p;
        end
    end

    % --- STAGE 3 (J = 5, Ages 12-14 Adolescent Gate) & STAGE 4 (J = 6..7 Adult Skill Launch) ---
    if ~is_reform_panel
        P_unemp = [0.82, 0.16, 0.02; 0.55, 0.37, 0.08; 0.28, 0.54, 0.18];
        P_stabl = [0.35, 0.58, 0.07; 0.12, 0.68, 0.20; 0.05, 0.55, 0.40];
    else
        P_unemp = [0.38, 0.34, 0.28; 0.16, 0.36, 0.48; 0.08, 0.30, 0.62];
        P_stabl = [0.14, 0.46, 0.40; 0.04, 0.38, 0.58; 0.02, 0.26, 0.72];
    end

    % Credit non-corner families (~m_corner) with their baseline child sustenance + 20-Hrs ECE investment
    % so middle-class children at ic_grid=0 on the coarse 4D grid are not hit with an artificial -0.47 log-skill penalty!
    ic_eff_4D  = max(ic_4D, 0.185 .* (~m_corner));
    inv_gap_4D = log(ic_eff_4D + G_ece_eff + 0.02) - log(0.20 + 0.05 + 0.02);
    if strcmpi(Calibration_Anchor, 'Dunedin_22')
        crowd_pen_4D = 0.14 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.265; % Calibrates National SS0 Struggling h1-h2 to the ~22.0% Dunedin Study benchmark!
    else
        crowd_pen_4D = 0.18 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.105; % Metropolitan Squeeze sensitivity (~34-36% Struggling in Auckland)
    end
    base_log_h_4D = rho_hc .* log(h_G) + gamma_ic .* inv_gap_4D - crowd_pen_4D + grid_anchor;
    s3_shifts     = [-0.22, 0.00, montessori_bank];

    p_st_cell = cell(1, 3); p_co_cell = cell(1, 3); p_th_cell = cell(1, 3);
    for s3_i = 1:3
        mean_4D = base_log_h_4D + s3_shifts(s3_i);
        pdf_5D  = exp(-0.5 .* ((log_h_dst5 - mean_4D) ./ sig_hc).^2);
        pdf_5D  = pdf_5D ./ sum(pdf_5D, 5);
        p_st_cell{s3_i} = sum(pdf_5D(:, :, :, :, 1:2), 5);
        p_co_cell{s3_i} = sum(pdf_5D(:, :, :, :, 3:5), 5);
        p_th_cell{s3_i} = sum(pdf_5D(:, :, :, :, 6:7), 5);
    end

    reg_F23 = zeros(3, 3);
    reg_F34 = zeros(3, 3);
    for s2_i = 1:3
        ws2     = s2_W_5D(:, :, :, :, s2_i);
        mass_s2 = Dist_Fert .* ws2;
        for s3_i = 1:3
            p_s3_4D = P_unemp(s2_i, s3_i) .* is_unemp_4D + P_stabl(s2_i, s3_i) .* (~is_unemp_4D);
            mass_s3 = mass_s2 .* p_s3_4D;
            m_share = gather(sum(mass_s3, 'all')) / tot_p;
            reg_F23(s2_i, s3_i) = m_share;

            m_st = gather(sum(mass_s3 .* p_st_cell{s3_i}, 'all')) / tot_p;
            m_co = gather(sum(mass_s3 .* p_co_cell{s3_i}, 'all')) / tot_p;
            m_th = gather(sum(mass_s3 .* p_th_cell{s3_i}, 'all')) / tot_p;

            reg_F34(s3_i, 1) = reg_F34(s3_i, 1) + m_st;
            reg_F34(s3_i, 2) = reg_F34(s3_i, 2) + m_co;
            reg_F34(s3_i, 3) = reg_F34(s3_i, 3) + m_th;
        end
    end

    % --- STAGE 5 (J = 10, Adulthood Fates at Age 30+): EXITS 1-4, RETAINED THRIVING, & EMIGRATED ABROAD ---
    if isfield(Diag_Sim, 'Emig_By_SkillTier')
        emig_t = [mean(Diag_Sim.Emig_By_SkillTier(1:2)), ...
            mean(Diag_Sim.Emig_By_SkillTier(3:5)), ...
            mean(Diag_Sim.Emig_By_SkillTier(6:7))];
    else
        if ~is_reform_panel, emig_t = [0.04, 0.11, 0.22];
        else,                emig_t = [0.02, 0.06, 0.12];
        end
    end

    % Conditional mapping from Adult Skill Launch Tiers [Struggling h1-h2; Core h3-h5; Thriving h6-h7]
    % into the 6 Adulthood Fate Nodes [Exit 1 Care, Exit 2 Hosp, Exit 3 LowInc, Exit 4 Ben/Just, Retained Secure, Emigrated]:
    S4_Shares = sum(reg_F34, 1);
    reg_F45   = zeros(3, 6);
    % Row 1: Struggling h1-h2 (~22% Dunedin segment drives ~74% of Exits 1, 2, 4; State Care = ~2.1% of cohort)
    ret_1 = 1 - emig_t(1);
    reg_F45(1, :) = S4_Shares(1) * [ret_1*0.090, ret_1*0.165, ret_1*0.260, ret_1*0.385, ret_1*0.100, emig_t(1)];
    % Row 2: Core Skill Tier h3-h5 (~54.5% of cohort in SS0)
    ret_2 = 1 - emig_t(2);
    reg_F45(2, :) = S4_Shares(2) * [ret_2*0.004, ret_2*0.024, ret_2*0.080, ret_2*0.065, ret_2*0.827, emig_t(2)];
    % Row 3: Thriving Tier h6-h7 (~23.5% of cohort in SS0 -> ~58% in SS1)
    ret_3 = 1 - emig_t(3);
    reg_F45(3, :) = S4_Shares(3) * [0.000,       ret_3*0.008, 0.000,       0.000,       ret_3*0.992, emig_t(3)];

    Flow_S1_to_S2 = Flow_S1_to_S2 + w_reg * 100 * reg_F12;
    Flow_S2_to_S3 = Flow_S2_to_S3 + w_reg * 100 * reg_F23;
    Flow_S3_to_S4 = Flow_S3_to_S4 + w_reg * 100 * reg_F34;
    Flow_S4_to_S5 = Flow_S4_to_S5 + w_reg * 100 * reg_F45;
end

% Exact 5-stage node population shares (%) across all 18 nodes
S1_Pct = sum(Flow_S1_to_S2, 2);  % 3x1: [1. Severe Hardship %, 2. Residual AHC Squeeze %, 3. Secure Buffer %]
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

%% BUILD 18-NODE PERCENTAGE-LABELED NODE NAMES
Nodes_S1 = {sprintf('1. Severe Material Hardship DEP-17 9+ (%.1f%%)', S1_Pct(1)), ...
    sprintf('2. Residual AHC Squeeze & Paper Support (%.1f%%)', S1_Pct(2)), ...
    sprintf('3. Secure Parental Asset Buffer (%.1f%%)',        S1_Pct(3))};

Nodes_S2 = {sprintf('4. Unmitigated Corner ic=0 (%.1f%%)',      S2_Pct(1)), ...
    sprintf('5. Public ECE + Moderate Inv (%.1f%%)',    S2_Pct(2)), ...
    sprintf('6. High Wraparound + Whanau Inv (%.1f%%)', S2_Pct(3))};

Nodes_S3 = {sprintf('7. Compounded HH & Psychosocial Stress (%.1f%%)', S3_Pct(1)), ...
    sprintf('8. Standard Schooling (%.1f%%)',                  S3_Pct(2)), ...
    sprintf('9. Montessori / Tuakana Mentoring (%.1f%%)',      S3_Pct(3))};

if reform_intensity <= 0
    lbl_12 = sprintf('12. Thriving Tier h6-h7 (%.1f%%)\n       [Rent-Seeking Skew]',  S4_Pct(3));
    lbl_17 = sprintf('17. Retained NZ Adult (%.1f%%)\n       [z_l Land-Rent Heavy]',  S5_Pct(5));
elseif reform_intensity <= 1.0
    lbl_12 = sprintf('12. Thriving Tier h6-h7 (%.1f%%)\n       [Pivot to Builders]',  S4_Pct(3));
    lbl_17 = sprintf('17. Retained NZ Adult (%.1f%%)\n       [z_l -> z_h Rebalance]', S5_Pct(5));
else
    lbl_12 = sprintf('12. Thriving Tier h6-h7 (%.1f%%)\n       [High-Wage Builders]', S4_Pct(3));
    lbl_17 = sprintf('17. Retained NZ Thriving Builder [z_h] (%.1f%%)',               S5_Pct(5));
end

Nodes_S4 = {sprintf('10. Struggling Tier h1-h2 (%.1f%%)', S4_Pct(1)), ...
    sprintf('11. Core Skill Tier h3-h5 (%.1f%%)', S4_Pct(2)), ...
    lbl_12};

Nodes_S5 = {sprintf('13. Exit 1: State Care (%.1f%%)',                 S5_Pct(1)), ...
    sprintf('14. Exit 2: Avoidable Hospitalisation (%.1f%%)',  S5_Pct(2)), ...
    sprintf('15. Exit 3: Lower Lifetime Income (%.1f%%)',      S5_Pct(3)), ...
    sprintf('16. Exit 4: Benefit & Justice Burden (%.1f%%)',   S5_Pct(4)), ...
    lbl_17, ...
    sprintf('18. Emigrated Abroad (20-35 Brain Drain, %.1f%%)', S5_Pct(6))};

% Prune sub-threshold phantom ribbons (< 0.15% of cohort) and redistribute pro-rata
% while preserving exact block heights at every Gate!
minFatesRibbon_Pct = 0.15;
Flow_S1_to_S2 = pruneAndBalanceFlowMatrix(Flow_S1_to_S2, minFatesRibbon_Pct);
Flow_S2_to_S3 = pruneAndBalanceFlowMatrix(Flow_S2_to_S3, minFatesRibbon_Pct);
Flow_S3_to_S4 = pruneAndBalanceFlowMatrix(Flow_S3_to_S4, minFatesRibbon_Pct);
Flow_S4_to_S5 = pruneAndBalanceFlowMatrix(Flow_S4_to_S5, minFatesRibbon_Pct);

% Assemble links cell array (only non-zero surviving ribbons)
links = {};
row_k = 0;
for i = 1:3
    for j = 1:3
        if Flow_S1_to_S2(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S1{i}, Nodes_S2{j}, Flow_S1_to_S2(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:3
        if Flow_S2_to_S3(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S2{i}, Nodes_S3{j}, Flow_S2_to_S3(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:3
        if Flow_S3_to_S4(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S3{i}, Nodes_S4{j}, Flow_S3_to_S4(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:6
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

Master_Colors = [0.72, 0.12, 0.14;  % 1. Severe Material Hardship (DEP-17 9+) [Deep Crimson]
    0.78, 0.32, 0.20;  % 2. Residual AHC Squeeze & Paper Support [Burnt Rust / Terracotta]
    0.16, 0.50, 0.56;  % 3. Secure Parental Asset Buffer [Teal]
    0.76, 0.18, 0.16;  % 4. Unmitigated Corner ic=0
    0.26, 0.52, 0.72;  % 5. Public ECE + Moderate Inv
    0.14, 0.62, 0.50;  % 6. High Wraparound + Whanau Inv
    0.82, 0.28, 0.14;  % 7. Compounded HH & Psychosocial Stress
    0.34, 0.54, 0.68;  % 8. Standard Schooling
    0.10, 0.60, 0.46;  % 9. Montessori / Tuakana Mentoring
    0.74, 0.18, 0.18;  % 10. Struggling Tier h1-h2
    0.28, 0.54, 0.68;  % 11. Core Skill Tier h3-h5
    0.10, 0.58, 0.46;  % 12. Thriving Tier h6-h7
    0.82, 0.22, 0.20;  % 13. Exit 1: State Care
    0.86, 0.44, 0.14;  % 14. Exit 2: Avoidable Hospitalisation
    0.82, 0.62, 0.20;  % 15. Exit 3: Lower Lifetime Income
    0.58, 0.18, 0.22;  % 16. Exit 4: Benefit & Justice Burden
    0.12, 0.60, 0.48;  % 17. Retained NZ Secure/Thriving Adult
    0.46, 0.28, 0.66   % 18. Emigrated Abroad (20-35 Brain Drain)
    ];

All_Node_Names = [Nodes_S1, Nodes_S2, Nodes_S3, Nodes_S4, Nodes_S5];
if isprop(SK, 'NodeList') && ~isempty(SK.NodeList)
    mapped_colors = zeros(length(SK.NodeList), 3);
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
xlim(ax, [curr_xlim(1) - 0.18, curr_xlim(2) + 1.25]);

curr_ylim = ylim(ax);
y_span    = diff(curr_ylim);
ylim(ax, [curr_ylim(1) - 0.24 * y_span, curr_ylim(2) + 0.10 * y_span]);

set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 8.8);

%% DRAW 5-STAGE HORIZONTAL "J" AXIS CENTERED ON EACH BAR
y_axis_line = curr_ylim(1) - 0.09 * y_span;
tick_h      = 0.022 * y_span;

p_all        = findall(ax, 'Type', 'Patch');
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

function val = getfield_def(S, fname, default_val)
if isfield(S, fname)
    val = S.(fname);
else
    val = default_val;
end
end

function img_cropped = AutoCrop_White_Border(img)
is_nonwhite = any(img < 252, 3);
rows = find(any(is_nonwhite, 2));
cols = find(any(is_nonwhite, 1));
if ~isempty(rows) && ~isempty(cols)
    img_cropped = img(min(rows):max(rows), min(cols):max(cols), :);
else
    img_cropped = img;
end
end

function [img_Merged, fig_pos] = Stitch_NPanels_Canvas(Panel_Imgs, Merge_Orientation)
N_p = numel(Panel_Imgs);
hs  = cellfun(@(x) size(x, 1), Panel_Imgs);
ws  = cellfun(@(x) size(x, 2), Panel_Imgs);

if strcmpi(Merge_Orientation, 'Vertical')
    W_max    = max(ws);
    pad_L    = 65; pad_R = 95;
    W_canvas = W_max + pad_L + pad_R;

    top_pad  = uint8(255 * ones(90, W_canvas, 3));
    bot_pad  = uint8(255 * ones(90, W_canvas, 3));
    gap_pre  = uint8(255 * ones(80, W_canvas, 3));
    div_line = uint8(220 * ones(4,  W_canvas, 3));
    gap_post = uint8(255 * ones(90, W_canvas, 3));

    blocks = {top_pad};
    for p = 1:N_p
        img_p = uint8(255 * ones(hs(p), W_canvas, 3));
        img_p(:, (pad_L+1):(pad_L+ws(p)), :) = Panel_Imgs{p};
        blocks{end+1} = img_p; %#ok<AGROW>
        if p < N_p
            blocks{end+1} = gap_pre;  %#ok<AGROW>
            blocks{end+1} = div_line; %#ok<AGROW>
            blocks{end+1} = gap_post; %#ok<AGROW>
        end
    end
    blocks{end+1} = bot_pad;
    img_Merged    = vertcat(blocks{:});
    fig_pos       = [80, 20, 1320, min(1150, 560 * N_p)];
else
    H_max    = max(hs);
    pad_T    = 90; pad_B = 90;
    H_canvas = H_max + pad_T + pad_B;
    left_pad = uint8(255 * ones(H_canvas, 65, 3));
    mid_gap  = uint8(255 * ones(H_canvas, 120, 3));
    right_pad= uint8(255 * ones(H_canvas, 95, 3));

    blocks = {left_pad};
    for p = 1:N_p
        img_p = uint8(255 * ones(H_canvas, ws(p), 3));
        img_p((pad_T+1):(pad_T+hs(p)), :, :) = Panel_Imgs{p};
        blocks{end+1} = img_p; %#ok<AGROW>
        if p < N_p
            blocks{end+1} = mid_gap; %#ok<AGROW>
        end
    end
    blocks{end+1} = right_pad;
    img_Merged    = horzcat(blocks{:});
    fig_pos       = [20, 80, min(1920, 920 * N_p), 740];
end
end

function T_Out = Build_NPhase_Summary_Table(Phase_Ledgers, Phase_Codes, vec_field, val_suffix, delta_suffix)
N_p   = numel(Phase_Ledgers);
L_ref = Phase_Ledgers{1};
n_row = numel(L_ref.(vec_field));

if isfield(L_ref, 'Gate_Column') && isfield(L_ref, 'Node_Names')
    Gates = L_ref.Gate_Column;
    Names = L_ref.Node_Names;
else
    Gates = { ...
        'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
        'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
        'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
        'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
        'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'; ...
        'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'};
    Names = { ...
        '1_Severe_Material_Hardship_DEP17';    '2_Residual_AHC_Squeeze_Paper_Support'; '3_Secure_Parental_Asset_Buffer'; ...
        '4_Unmitigated_Corner_ic0';            '5_Public_ECE_Moderate_Inv';            '6_High_Wraparound_Whanau_Inv'; ...
        '7_Compounded_HH_Psychosocial_Stress'; '8_Standard_Public_Schooling';          '9_Montessori_Tuakana_Mentoring'; ...
        '10_Struggling_Tier_h1_h2';            '11_Core_Skill_Tier_h3_h5';             '12_Thriving_Tier_h6_h7'; ...
        '13_Exit1_State_Care';                 '14_Exit2_Avoidable_Hospitalisation';   '15_Exit3_Lower_Lifetime_Income'; ...
        '16_Exit4_Benefit_Justice_Burden';     '17_Retained_NZ_Secure_Thriving';       '18_Emigrated_Abroad_BrainDrain'};
end

T_Out = table(Gates(1:n_row), Names(1:n_row), 'VariableNames', {'Gate', 'Node_Name'});
Mat   = zeros(n_row, N_p);
for p = 1:N_p
    col_vec   = reshape(Phase_Ledgers{p}.(vec_field), n_row, 1);
    Mat(:, p) = col_vec;
    T_Out.([Phase_Codes{p}, val_suffix]) = round(col_vec, 2);
end

% Add incremental phase-to-phase deltas and cumulative delta vs Phase 1 (SS0)
if N_p == 2
    T_Out.(['Reform', delta_suffix]) = round(Mat(:, 2) - Mat(:, 1), 2);
elseif N_p >= 3
    for p = 2:N_p
        d_name = sprintf('Delta_%s_vs_%s%s', Phase_Codes{p}, Phase_Codes{p-1}, delta_suffix);
        T_Out.(d_name) = round(Mat(:, p) - Mat(:, p-1), 2);
    end
    cum_name = sprintf('Cumul_%s_vs_%s%s', Phase_Codes{N_p}, Phase_Codes{1}, delta_suffix);
    T_Out.(cum_name) = round(Mat(:, N_p) - Mat(:, 1), 2);
end
end

function F_clean = pruneAndBalanceFlowMatrix(F_in, min_thresh)
%% PRUNEANDBALANCEFLOWMATRIX
% Zeroes out sub-threshold phantom ribbons (< min_thresh) and redistributes mass
% across surviving entries via RAS iterative proportional fitting so row & col margins stay exact.
row_targets = sum(F_in, 2);
col_targets = sum(F_in, 1);
F_clean     = F_in;
mask_keep   = (F_in >= min_thresh);

% Guarantee at least the largest entry in every non-empty row and column survives
for r = 1:size(F_in, 1)
    if row_targets(r) > 0 && ~any(mask_keep(r, :))
        [~, idx_m] = max(F_in(r, :));
        mask_keep(r, idx_m) = true;
    end
end
for c = 1:size(F_in, 2)
    if col_targets(c) > 0 && ~any(mask_keep(:, c))
        [~, idx_m] = max(F_in(:, c));
        mask_keep(idx_m, c) = true;
    end
end

F_clean(~mask_keep) = 0;
for iter = 1:12
    for r = 1:size(F_clean, 1)
        rs = sum(F_clean(r, :));
        if rs > 1e-12
            F_clean(r, :) = F_clean(r, :) * (row_targets(r) / rs);
        end
    end
    for c = 1:size(F_clean, 2)
        cs = sum(F_clean(:, c));
        if cs > 1e-12
            F_clean(:, c) = F_clean(:, c) * (col_targets(c) / cs);
        end
    end
end
end

function narrativeMap = getFatesRibbonNarratives(phase_code)
%% GETFATESRIBBONNARRATIVES
% Returns containers.Map keyed by 'srcNum->dstNum' (and 'NODE_num') for the 18-Node Fates Sankey.
narrativeMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
is_ref = ~strcmpi(phase_code, 'SS0');

% --- NODE-LEVEL DESCRIPTIONS (1..18) ---
narrativeMap('NODE_1')  = 'Node 1 — Severe Material Hardship (DEP-17 9+): Households at the acute asset floor (a < 0.05*Q_reg) with bottom labor productivity (z <= 2). Anchored to Stats NZ / MSD DEP-17 9+ and Treasury IDI high-priority birth flags [Ref 48].';
narrativeMap('NODE_2')  = 'Node 2 — Residual AHC Squeeze & Paper Support: Households above emergency destitution (0.05*Q_reg <= a < 0.16*Q_reg) qualifying on paper for WfF/AS/BestStart, but squeezed by metro rents (Q_reg), abatement cliffs, and time poverty. Buffered in provincial regions by Marilyn Waring unpaid whanau care K_whanau(k) [Ref 47, 48].';
narrativeMap('NODE_3')  = 'Node 3 — Secure Parental Asset Buffer: Households with sufficient liquid equity and after-housing-cost disposable income to sustain baseline First 2000 Days enrichment without emergency transfers.';
narrativeMap('NODE_4')  = 'Node 4 — Unmitigated Corner (ic = 0): Families forced to zero out-of-pocket early enrichment by acute hardship (Node 1) or metropolitan nuclear isolation where extended whanau are priced out (Node 2) [Ref 1, 11, 47].';
narrativeMap('NODE_5')  = 'Node 5 — Public ECE + Moderate Investment: Children receiving universal public ECE wraparound (G_ece_1) and/or rescued from the cash corner by extended whanau alloparental care K_whanau(k) [Ref 11, 14, 47].';
narrativeMap('NODE_6')  = 'Node 6 — High Wraparound + Whanau Investment: Children receiving high private and alloparental whanau enrichment alongside public First 2000 Days scaffolding (phi_1 = +0.35 substitutability).';
narrativeMap('NODE_7')  = 'Node 7 — Compounded Household & Psychosocial Stress (Ages 12-14): Captures the multiplicative interaction of family unemployment distress (z1-z2) and cross-income adolescent psychosocial hazards (bullying 32-35%, Youth19 clinical depression 23%, algorithmic compulsion, and ACC Sensitive Claims trauma) [Ref 17, 19, 20, 38].';
narrativeMap('NODE_8')  = 'Node 8 — Standard Public Schooling (Ages 12-14): Conventional age-segregated secondary schooling without structured cross-age Tuakana-Teina or Erdkinder mentoring (subject to delta_fade = 0.22 skill fade-out) [Ref 15].';
narrativeMap('NODE_9')  = 'Node 9 — Montessori / Tuakana-Teina Mentoring (Ages 12-14): High-agency vertical whanau, Kura, Graeme Dingle Stars/Project K, KiVa bystander norms, and Planet Youth family/mentor scaffolding [Ref 18, 20, 55].';
narrativeMap('NODE_10') = 'Node 10 — Struggling Adult Skill Tier (h1-h2, Age 20): Calibrated to the Dunedin Study 22.0% high-burden developmental cohort at labor market entry [Ref 16].';
narrativeMap('NODE_11') = 'Node 11 — Core Adult Skill Tier (h3-h5, Age 20): Skilled domestic workforce foundation launching into vocational and tertiary pathways.';
narrativeMap('NODE_12') = 'Node 12 — Thriving Adult Skill Tier (h6-h7, Age 20): High-capability graduates and entrepreneurs (pivoting from z_l land speculation in SS0 to z_h builders in SS1/SS2) [Ref 2, 7].';
narrativeMap('NODE_13') = 'Node 13 — Exit 1 (State Care / Oranga Tamariki): Acute statutory care and protection liability (~37.1k-54.7k NZD/yr direct flow + 181k NZD lifetime abuse-in-care liability) [Ref 37].';
narrativeMap('NODE_14') = 'Node 14 — Exit 2 (Avoidable Hospitalisation & Acute Mental Health): Preventable paediatric/adult hospital admissions, CAMHS, and ACC ISSC trauma rehabilitation [Ref 16, 38].';
narrativeMap('NODE_15') = 'Node 15 — Exit 3 (Lower Lifetime Income & Tax Drag): Permanent earnings and PAYE/GST tax-base erosion from unbuffered childhood/adolescent skill loss.';
narrativeMap('NODE_16') = 'Node 16 — Exit 4 (Long-Term Benefit, LOPE & Justice Burden): Supported Living, Jobseeker hardship, ACC Loss of Potential Earnings (LOPE at 80% min wage), and Corrections outlays [Ref 16, 38].';
narrativeMap('NODE_17') = 'Node 17 — Retained NZ Secure/Thriving Adult: Domestic skilled adults powering high-productivity z_h enterprises and the 2050 50/50 Sovereign Debt-Sinking & Infrastructure Protocol.';
narrativeMap('NODE_18') = 'Node 18 — Emigrated Abroad (Age 20-35 Brain Drain): Young adults departing to Australia/OECD via the 4x5 Gumbel sorting matrix Pi_mig [Ref 23, 24, 25].';

% --- RIBBON-LEVEL TRANSITIONS (GATE 1 -> GATE 2: 1..3 -> 4..6) ---
if ~is_ref
    narrativeMap('1->4') = 'SS0 Acute Deprivation Trap: Without proactive Tier 3 wraparound, Severe Material Hardship (DEP-17 9+) forces families directly into the Unmitigated Corner (ic = 0, Node 4) during the First 2000 Days [Ref 1, 48].';
    narrativeMap('1->5') = 'SS0 Partial Community / Whanau Mitigation: Small fraction of DEP-17 9+ births buffered by intensive rural/iwi whanau networks into basic public ECE (Node 5) [Ref 37, 47].';
    narrativeMap('2->4') = 'SS0 Paper-Support Failure & Metro Isolation: In high-rent Auckland/Large metros (Q_reg = 2.05-3.10), AS rent capture by landlords and nuclear isolation from extended whanau push Residual AHC Squeeze infants into the ic = 0 corner (Node 4) [Ref 47, 48].';
    narrativeMap('2->5') = 'SS0 Marilyn Waring Unpaid Whanau Rescue: In Rural and Small provincial regions (K_whanau = 0.38-0.42), nearby kaumatua and aunties provide unpaid alloparental care that rescues squeezed Node 2 infants out of the cash corner into Node 5 [Ref 26, 47].';
else
    narrativeMap('1->4') = 'SS1/SS2 Residual Acute Corner: Small remaining fraction of Tier 3 high-needs households not yet reached by First 2000 Days navigators.';
    narrativeMap('1->5') = 'SS1/SS2 Proactive First-2000-Days Wraparound: Universal G_ece_1 (0.110-0.130) and Whanau Ora / Barnardos navigators lift 78%-92% of severe-hardship infants out of the ic = 0 corner into enriched ECE (Node 5) [Ref 14, 37].';
    narrativeMap('2->4') = 'SS1/SS2 Residual AHC Corner: Drastically compressed corner flow (<2%) after metro rent cooling (Q_mult) and universal ECE.';
    narrativeMap('2->5') = 'SS1/SS2 Housing Cooling + Whanau & Universal ECE: Cooling metro rents (Q_mult), Super Age 64 Kuia time (+8.1% Phi_time), and universal ECE move squeezed Node 2 families into thriving early trajectories (Node 5) [Ref 26, 47].';
end
narrativeMap('2->6') = 'Squeezed working families accessing high-intensity community/whanau wraparound via convex d_grid_ic interior rungs (0.0203 and 0.0706) and K_whanau(k) co-care [Ref 47].';
narrativeMap('3->4') = 'Transitory liquidity/income shock pushing a small fraction of asset-buffered households to zero private cash investment.';
narrativeMap('3->5') = 'Secure-buffer families combining 20-Hours / universal public ECE with moderate private early-childhood investment (Node 5).';
narrativeMap('3->6') = 'Secure-buffer families investing at the top rungs of the convex d_grid_ic power grid alongside extended whanau enrichment (Node 6, phi_1 = +0.35).';

% --- GATE 2 -> GATE 3 (4..6 -> 7..9) ---
if ~is_ref
    narrativeMap('4->7') = 'SS0 82% Compounded Stress Lock-In: Children from the ic=0 corner hit by family unemployment (z1) and adolescent psychosocial hazards (bullying 32-35%, Youth19 depression 23%, sexual trauma) face an 82% lock-in to Node 7 [Ref 19, 20, 38].';
    narrativeMap('4->8') = 'SS0 Partial Schooling Recovery: Children from the ic=0 early corner whose parents regain stable employment, entering standard public schooling (Node 8) but facing delta_fade = 0.22 skill erosion [Ref 15].';
    narrativeMap('4->9') = 'SS0 Minimal Mentoring Access Under Stress (2%): In the status quo, only 2% of corner-deprived stressed adolescents gain access to Graeme Dingle / Kura / Montessori mentoring (Node 9) [Ref 18].';
    narrativeMap('5->7') = 'SS0 Cross-Income Psychosocial & Household Shock (lambda_psy): Even among moderate-ECE families, post-2012 cyberbullying (32-35%), anxiety/depressive escalation (52.4% in GUiNZ age 12), and job shocks pull adolescents into Node 7 [Ref 17, 19, 20].';
else
    narrativeMap('4->7') = 'SS1/SS2 38% Clinical Persistence Floor: While mentoring and family buffers cut the stress trap from 82% to 38%, the model retains a 38% residual for acute clinical trauma requiring specialized CAMHS and ACC ISSC care [Ref 38, 55].';
    narrativeMap('4->8') = 'SS1/SS2 Stabilized Standard Schooling: Former corner children transitioning into standard public schooling as GE firm reallocation lifts regional employment.';
    narrativeMap('4->9') = 'SS1/SS2 14-Fold Surge in Mentoring Access Under Stress (2% -> 28%): Tuakana-Teina, Graeme Dingle Stars/Project K, KiVa peer norms, and Planet Youth family buffers insulate vulnerable teens [Ref 18, 20, 55].';
    narrativeMap('5->7') = 'SS1/SS2 Inoculated Psychosocial Incidence: Critical-thinking digital metacognition, KiVa bystander norms, and Planet Youth family connection compress cross-income adolescent distress [Ref 20, 55].';
    narrativeMap('5->9') = 'SS1/SS2 Mainstreamed Montessori Erdkinder & Tuakana-Teina Mentoring (57.3%-65.0% cohort coverage): Halts delta_fade = 0.22 skill fade-out and inoculates executive function against algorithmic capture [Ref 15, 18, 55].';
end
narrativeMap('5->8') = 'Transition from early childhood ECE (Node 5) into standard public intermediate/secondary schooling (Node 8).';
narrativeMap('6->7') = 'High-wraparound early childhood cohorts hit by severe cross-income adolescent psychosocial trauma or sudden parental job loss (Node 7) [Ref 19, 38].';
narrativeMap('6->8') = 'High-wraparound early childhood cohorts entering standard age-segregated secondary schooling (Node 8).';
narrativeMap('6->9') = 'High-wraparound early childhood cohorts continuing into high-agency Montessori Erdkinder & Tuakana-Teina leadership (Node 9) [Ref 18].';

% --- GATE 3 -> GATE 4 (7..9 -> 10..12) ---
narrativeMap('7->10') = 'Cunha-Heckman Stage-2 Bottleneck (phi_2 = -0.95): Unbuffered household & psychosocial stress (-0.22 log-skill shift) drives adolescents into the Dunedin 22% Struggling Adult Tier (h1-h2, Node 10) at Age 20 [Ref 11, 16].';
narrativeMap('7->11') = 'Resilient or clinically supported adolescents (CAMHS / ACC ISSC + whanau buffer K_whanau) who weather Gate 3 stress and recover into the Core Skill Tier (h3-h5, Node 11) [Ref 38, 47].';
narrativeMap('7->12') = 'Exceptional high-initial-skill adolescents who overcome Gate 3 stress to reach the Thriving Tier (h6-h7, Node 12).';
narrativeMap('8->10') = 'Unbanked Skill Fade-Out (delta_fade = 0.22): Without cross-age mentoring, vulnerable students in standard schooling slip downward into the Struggling Tier (h1-h2, Node 10) [Ref 15].';
narrativeMap('8->11') = 'Standard schooling cohorts (Node 8) launching into the Core Adult Skill Tier (h3-h5, Node 11) at Age 20.';
narrativeMap('8->12') = 'High-parental-capital students in standard schooling launching into the Thriving Adult Skill Tier (h6-h7, Node 12).';
narrativeMap('9->10') = 'Small residual of mentored youth with severe baseline deficits who still launch in h1-h2.';
narrativeMap('9->11') = 'Tuakana-Teina and Graeme Dingle mentoring lifting at-risk adolescents solidly into the Core Adult Skill Tier (h3-h5, Node 11) [Ref 18].';
narrativeMap('9->12') = 'Two-Way Ako / Protege Dividend (+0.11 to +0.14 log-skill boost): Mentored adolescents launch into the Thriving Adult Skill Tier (h6-h7, Node 12) at Age 20 [Ref 18, 55].';

% --- GATE 4 -> GATE 5 (10..12 -> 13..18) ---
narrativeMap('10->13') = 'Dunedin Concentration into Exit 1 (State Care): 9.0% of retained Struggling h1-h2 youth experience statutory care/protection pathways [Ref 16, 37].';
narrativeMap('10->14') = 'Dunedin Concentration into Exit 2 (Avoidable Hospitalisation & CAMHS): 16.5% of retained h1-h2 youth incur acute hospital and mental health burdens [Ref 16, 38].';
narrativeMap('10->15') = 'Exit 3 (Lower Lifetime Income): 26.0% of retained h1-h2 youth remain in low-wage employment with permanently reduced lifetime earnings and tax receipts.';
narrativeMap('10->16') = 'Dunedin Concentration into Exit 4 (Benefit, LOPE & Justice Burden): 38.5% of retained h1-h2 youth enter long-term SLP/Jobseeker dependency, ACC LOPE (80% min wage), or Corrections [Ref 16, 38].';
narrativeMap('10->17') = '10.0% of retained Struggling Tier (h1-h2) young adults who achieve stable adult employment in New Zealand (Node 17).';
narrativeMap('10->18') = 'Low-skill trans-Tasman emigration from the h1-h2 tier (4% in SS0 -> 2% in SS1).';
narrativeMap('11->13') = 'Low residual incidence (0.4%) of statutory care/crisis among Core Skill Tier (h3-h5) adults.';
narrativeMap('11->14') = 'Residual avoidable hospitalisation (2.4%) among Core Skill Tier (h3-h5) adults.';
narrativeMap('11->15') = 'Underemployment / lower-income drag (8.0%) among Core Skill Tier (h3-h5) adults facing regional mismatch.';
narrativeMap('11->16') = 'Residual benefit or justice contact (6.5%) among Core Skill Tier (h3-h5) adults.';
narrativeMap('11->17') = '82.7% of retained Core Skill Tier (h3-h5) adults establish secure, thriving domestic careers in New Zealand (Node 17).';
narrativeMap('11->18') = 'Trans-Tasman emigration of Core Skill (h3-h5) tradespeople, nurses, and technicians (cut from 11% in SS0 to 6% in SS1 via housing cooling and wage lifts) [Ref 23, 24].';
narrativeMap('12->14') = 'Minimal residual hospitalisation risk (0.8%) among Thriving Tier (h6-h7) adults.';
narrativeMap('12->17') = '99.2% of retained Thriving Tier (h6-h7) adults become high-wage domestic builders and innovators (z_h) when retained in NZ (Node 17) [Ref 2, 7].';
narrativeMap('12->18') = 'Trans-Tasman & OECD Brain Drain (Pi_mig): High-skill h6-h7 young adults departing to Australia/OECD (cut from 22% conditional rate in SS0 to 12% in SS1 via Youth Grant E, Q_reg cooling, and z_h firm wages) [Ref 23, 24, 25].';
end

function attachSankeyHoverNarratives(ax, SK, links, narrativeMap, valFmt)
%% ATTACHSANKEYHOVERNARRATIVES
% Wires lightweight live MATLAB mouse-hover callout banner at top of figure.
fig = ancestor(ax, 'figure');
if isempty(fig) || ~isvalid(fig), return; end
infoBanner = annotation(fig, 'textbox', [0.02, 0.935, 0.96, 0.055], ...
    'String', 'Hover mouse over any Sankey block or ribbon to inspect its empirical mechanism & citation...', ...
    'FontName', 'Helvetica', 'FontSize', 9.2, 'FontWeight', 'bold', ...
    'Color', [0.12, 0.16, 0.22], 'BackgroundColor', [0.97, 0.98, 1.00], ...
    'EdgeColor', [0.45, 0.55, 0.70], 'LineWidth', 1.0, 'Interpreter', 'none', ...
    'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', 'Margin', 4);
setappdata(fig, 'SankeyHoverBanner', infoBanner);
setappdata(fig, 'SankeyLinks', links);
setappdata(fig, 'SankeyNarrativeMap', narrativeMap);
setappdata(fig, 'SankeyValFmt', valFmt);
setappdata(fig, 'SankeyObj', SK);
end
