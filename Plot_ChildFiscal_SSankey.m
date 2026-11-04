%% PLOT_CHILDFISCAL_SSANKEY.M
% 6-Gate (28-Node) Pairwise N-Panel Lifecycle Fiscal Sankey Diagram (A3 Layout, 100% GPU-Vectorized)
% Units: Cohort-Weighted Annual NZD Thousands (kNZD/yr per child born in cohort)
%        + Explicit Population Share (% pop) on Gates 1-4 & Explicit 4-Lane Waring / Landlord Split:
%   - Gate 1 (J = 1, Birth, Age 0 — 4 Nodes: 1..4):
%       (1) Acute Hardship Tier 3 Support (DEP-17 9+), (2) Residual AHC Paper & Whanau Buffer,
%       (3) Universal Birth Benefit (PPL + BestStart), (4) Private Birth Out-of-Pocket
%   - Gate 2 (J = 2..3, First 2000 Days ECE Gate, Ages 0-5 — 4 Nodes: 5..8):
%       (5) ECE Corner + Benefit Need, (6) Public ECE Wraparound, (7) High-Intensity Public ECE,
%       (8) Private Parental ECE (Cash + Unpaid Whanau Time)
%   - Gate 3 (J = 5, Adolescent Gate, Ages 12-14 — 5 Nodes: 9..13):
%       (9) HH Unemp & Truancy Remediation, (10) Psychosocial Trauma CAMHS & ACC ISSC (38% Clinical Floor),
%       (11) Public Secondary Schooling (d_2), (12) Montessori / Tuakana Mentoring,
%       (13) Private Adolescent Commitment (Cash + Time)
%   - Gate 4 (J = 6..7, Adult Skill Launch, Age 20 — 3 Nodes: 14..16):
%       (14) Struggling Tier h1-h2, (15) Core Skill Tier h3-h5, (16) Thriving Tier h6-h7
%   - Gate 5 (J = 10, Age 30 — 6 Nodes: 17..22) & Gate 6 (J = 11..16, Career to Ret. — 6 Nodes: 23..28):
%       Exits 1,2,4 + Base Infra/Super Outlays at Bottom (BAD), GST/Cap/Estate + PAYE Tax in Middle (GOOD),
%       Exit 3 Foregone Tax + Emigrated Abroad Lost Tax at Top (BEYOND), with Net-Zero Breakeven & 50/50 Split.

%% 1. CONFIGURATION SWITCHES (N-PHASE COMPATIBLE: 1, 2, 3, OR MORE PANELS)
Target_Regions     = {'National', 'Auckland', 'Large', 'Small', 'Rural', 'Urban'};
if ischar(Target_Regions) || isstring(Target_Regions), Target_Regions = cellstr(Target_Regions); end

% Specify any 1, 2, 3, or N phases: e.g. {'SS0'}, {'SS0','SS1'}, or {'SS0','SS1','SS2'}
if ~exist('Active_Phases', 'var') || isempty(Active_Phases)
    Active_Phases = {'SS0', 'SS1', 'SS2'};
end
Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' or 'MetroSqueeze_GUiNZ'
Merge_Orientation  = 'Vertical';   % 'Vertical' (Stacked Top/Bottom for A3) or 'Horizontal'
NZD_Base_Scale     = 95.0;         % 1.0 model unit = NZD $95.0k/yr (mean prime household earnings)
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

%% 3. RENDER 1..N FISCAL PANELS, STITCH, AND EXPORT 28-NODE TABLE 14 & 2050 PROTOCOL LEDGERS
FiscalLedger = struct();

for r_loop = 1:length(Target_Regions)
    Target_Region = Target_Regions{r_loop};
    Out_PNG_Name  = sprintf('Fig_ChildFiscal_6Gate_%dPanel_%s_%s.png', ...
        N_phases, Target_Region, Calibration_Anchor);

    Panel_Imgs    = cell(1, N_phases);
    Phase_Ledgers = cell(1, N_phases);

    for p = 1:N_phases
        p_code = Phases(p).Code;
        figP   = figure('Name', sprintf('LIVE HOVER — %s (%s)', Phases(p).Label, Target_Region), ...
            'Color', 'w', 'Position', [20, 40, 1850, 820], 'Visible', 'on');
        axP    = axes('Parent', figP, 'Position', [0.02, 0.07, 0.95, 0.85]);

        [L_p, SK_p, links_p] = Build_And_Render_Fiscal_Panel(axP, Target_Region, ...
            Phases(p).Dist, Phases(p).Pol, Phases(p).Params, Phases(p).Diag, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, ...
            Phases(p).Label, Calibration_Anchor, NZD_Base_Scale, Phases(p).Intensity);
        drawnow;

        % 1. Capture high-res raster image BEFORE attaching interactive hover UI
        Panel_Imgs{p} = AutoCrop_White_Border(print(figP, '-RGBImage', '-r300'));

        % 2. If Interactive_Hover_Mode is enabled, wire up hover callbacks & keep figure open!
        if Interactive_Hover_Mode && strcmpi(Target_Region, 'National')
            fiscalNarrativeMap = getFiscalRibbonNarratives(p_code);
            attachSankeyHoverNarratives(axP, SK_p, links_p, fiscalNarrativeMap, 'NZD $%.2fk/yr per cohort birth');
            html_fname = fullfile(OutputDir, sprintf('Interactive_ChildFiscal_%s_%s.html', p_code, Target_Region));
            exportSankeyToHTML(axP, SK_p, links_p, fiscalNarrativeMap, 'NZD $%.2fk/yr per cohort birth', html_fname);
        else
            close(figP);
        end

        Phase_Ledgers{p}                        = L_p;
        FiscalLedger.(Target_Region).(p_code)   = L_p;
        FiscalLedger.(p_code)                   = L_p;
    end

    %% 3.1 STITCH 1..N PANELS CLEANLY
    [img_Merged, fig_pos] = Stitch_NPanels_Canvas(Panel_Imgs, Merge_Orientation);

    imwrite(img_Merged, fullfile(OutputDir, Out_PNG_Name));
    fprintf('\nSaved %d-panel 6-gate Fiscal Sankey image to: %s\n', N_phases, fullfile(OutputDir, Out_PNG_Name));

    %% 3.2 MULTIPHASE 2050 DEBT-SINKING FUND & PUBLIC REINVESTMENT PROTOCOL SUMMARY
    if N_phases >= 2
        FiscalLedger.(Target_Region).Protocol_2050_Summary = ...
            Build_Multiphase_2050_Protocol_Table(Phase_Ledgers, {Phases.Code}, Target_Region);
        FiscalLedger.Protocol_2050_Summary = FiscalLedger.(Target_Region).Protocol_2050_Summary;
    end

    %% 3.3 EXPORT CUSTOM 6-GATE (28-NODE) FISCAL LEDGER CSV (Table14_FiscalLedger_6Gate_Decomp_<Region>.csv)
    T_FiscalCSV = Build_Custom_Table14_Fiscal_CSV(Phase_Ledgers, {Phases.Code});
    FiscalLedger.(Target_Region).Table14_Decomp = T_FiscalCSV;

    fiscal_csv_fname = fullfile(OutputDir, sprintf('Table14_FiscalLedger_6Gate_Decomp_%s.csv', Target_Region));
    writetable(T_FiscalCSV, fiscal_csv_fname);
    fprintf('  -> Exported %d-Phase 6-Gate (28-Node) Fiscal CSV to: %s\n', N_phases, fiscal_csv_fname);

    fig_Merged = figure('Name', sprintf('%d-Panel 6-Gate Child Fiscal Sankey: %s', N_phases, Target_Region), ...
        'Color', 'w', 'Position', fig_pos);
    ax_M = axes('Parent', fig_Merged, 'Position', [0, 0, 1, 1]);
    imshow(img_Merged, 'Parent', ax_M, 'Border', 'tight');
    axis(ax_M, 'off');
end

%% ========================================================================
%  LOCAL HELPER: GPU-VECTORIZED 6-GATE FISCAL & PRIVATE LEDGER + SANKEY
%  ========================================================================
function [Ledger, SK, links] = Build_And_Render_Fiscal_Panel(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, z_grid, Panel_Tag, ...
    Calibration_Anchor, NZD_Scale, reform_intensity)

% 1. Inspect available HH_* regions inside Dist_Sim
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
z_vec    = z_grid.(ref_type);

n_l    = n_d.(ref_type)(1);
n_Ih   = n_d.(ref_type)(2);
n_ic   = n_d.(ref_type)(3);
l_vec  = d_grid.(ref_type)(1:n_l);
Ih_vec = d_grid.(ref_type)(n_l+1 : n_l+n_Ih);
ic_vec = d_grid.(ref_type)(n_l+n_Ih+1 : end);

fertile_j = [3, 4];
Jr        = round(getfield_def(P_Sim, 'Jr',          10));
J_tot     = getfield_def(P_Sim, 'J',           16);
rho_hc    = getfield_def(P_Sim, 'rho_hc_ig',   0.40);
gamma_ic  = getfield_def(P_Sim, 'gamma_ic',    0.35);
G_ece     = getfield_def(P_Sim, 'G_ece',       0.05);
sig_hc    = getfield_def(P_Sim, 'sigma_hc_ig', 0.18);
s_sub     = getfield_def(P_Sim, 's_sub',       0.10);
tau_l     = getfield_def(P_Sim, 'tau_l',       0.22);
tau_c     = getfield_def(P_Sim, 'tau_c',       0.15);
tau_k     = getfield_def(P_Sim, 'tau_k',       0.20);
tau_a     = getfield_def(P_Sim, 'tau_a',       0.005);
tau_b     = getfield_def(P_Sim, 'tau_b',       0.05);
r_ann     = (1 + getfield_def(P_Sim, 'r', 0.20))^(1/5) - 1;
p_super   = getfield_def(P_Sim, 'p_super',     0.18);
c_floor   = getfield_def(P_Sim, 'c_floor',     0.04);

% Define boolean flag for legacy if/else blocks below
is_reform_panel = (reform_intensity > 0);
% Clamp incoming scalar/boolean reform_intensity (0.0 = SS0, 1.0 = SS1, >1.0 = SS2+)
eta_ref         = min(1.18, max(0.0, double(reform_intensity)));


if is_reform_panel
    if G_ece <= 0.06, G_ece = G_ece + 0.14; end
    if tau_a <= 0.006, tau_a = tau_a + 0.010; end
    if tau_b <= 0.06,  tau_b = tau_b + 0.10;  end
    G_ece_eff       = G_ece * 1.15; % Montessori / Tuakana cross-age downward multiplier
    montessori_bank = +0.11;        % Montessori / Tuakana adolescent skill lock-in
else
    G_ece_eff       = G_ece;
    montessori_bank = +0.05;
end

% 6-Gate (28-Node) Accumulators (Cohort-Weighted kNZD/yr per birth + Exact Population Shares):
%   Gate 1 (J = 1 Birth, 4 nodes -> Nodes 1..4):
%     [1: Acute Hardship Tier 3 Support (DEP-17 9+, Deep Crimson);
%      2: Residual AHC Paper Support & Waring Whanau Buffer (AS Landlord Capture + Unpaid Care, Burnt Rust);
%      3: Universal Birth Benefit (PPL + BestStart + LMC, Public Steel Blue);
%      4: Private Birth Out-of-Pocket (Secure Buffer, Parental Warm Gold)]
%   Gate 2 (J = 2..3 First 2000 Days ECE Gate, 3 public/corner accumulators + Node 8 Private -> Nodes 5..8):
%     [5: ECE Corner + Benefit Need (Bad); 6: Public ECE Wraparound;
%      7: High-Intensity Public ECE;       8: Private Parental ECE (Cash + Whanau Time, Warm Gold)]
%   Gate 3 (J = 5 Adolescent Gate, Ages 12-14, 4 public/crisis accumulators + Node 13 Private -> Nodes 9..13):
%     [9:  HH Unemp & Truancy Remediation (Vote Social Dev / Alt-Ed / Youth Justice);
%      10: Psychosocial Trauma, CAMHS & ACC ISSC (38% Clinical Floor + LOPE Liability, Crimson-Plum);
%      11: Public Secondary Schooling (d_2);
%      12: Montessori / Tuakana-Teina Mentoring (Public Teal);
%      13: Private Adolescent Commitment (Cash + Whanau Time, Warm Gold)]
%   Gate 4 (J = 6..7 Adult Skill Launch, Age 20, 3 nodes -> Nodes 14..16):
%     [14: Struggling Tier h1-h2 (Exits 1,2,4 active); 15: Core Skill Tier h3-h5; 16: Thriving Tier h6-h7]
%   Gate 5 (J = 10 Age 30 Annual Fiscal Balance, 6 nodes -> Nodes 17..22):
%     [17: Exits 1,2,4 Care/Hosp/Just/Ben (Bad 1); 18: Infra, Roads & Base Health (Bad 2);
%      19: Age 30 GST & Cap Tax (Good 1);          20: Age 30 PAYE Income Tax (Good 2);
%      21: Exit 3 Lower-Skill Lost Tax (Foregone); 22: Age 30 Emigrated Abroad Lost Tax (Beyond)]
%   Gate 6 (J = 11..16 Career to Retirement Fiscal Destiny, 6 nodes -> Nodes 23..28):
%     [23: Exits 1,2,4 Ongoing Burden (Bad 1);     24: NZ Super, Infra & Health (Bad 2);
%      25: GST, Cap & Estate Tax Pool (Good 1);    26: Career PAYE Income Tax (Good 2);
%      27: Exit 3 Career Lost Tax (Foregone);      28: Permanent Abroad Lost Tax (Beyond)]
Flow_S1_to_S2 = zeros(4, 3); % 4 Gate-1 Birth Nodes -> 3 Gate-2 Public/Corner States
Flow_S2_to_S3 = zeros(3, 4); % 3 Gate-2 States      -> 4 Gate-3 Public/Crisis States
Flow_S3_to_S4 = zeros(4, 3); % 4 Gate-3 States      -> 3 Gate-4 Launch Skill Tiers
Pop_S1_Birth  = zeros(1, 4); % [1: Severe DEP-17 %, 2: Residual AHC Squeeze %, 3: Universal 100%, 4: Secure Buffer %]
Pop_S2_ECE    = zeros(1, 3); % [5: Corner ic=0 %, 6: Mod ECE %, 7: High ECE %] — matches 18-Node Fate Chart!
Pop_S3_Adol   = zeros(1, 4); % [9: HH Unemp Rem %, 10: Psychosocial CAMHS/ACC %, 11: Std School %, 12: Tuakana %]
Pop_S4_Skill  = zeros(1, 3); % [14: Struggling h1-h2 %, 15: Core h3-h5 %, 16: Thriving h6-h7 %]

ECE_Step_Dollars  = zeros(1, 3); % Cohort-weighted kNZD/yr at J=2-3 (Public/Remediation nodes 5, 6, 7)
Adol_Step_Dollars = zeros(1, 4); % Cohort-weighted kNZD/yr at J=5   (Public/Remediation nodes 9, 10, 11, 12)
Whanau_Care_G1_G2 = zeros(1, 2); % [Node 2 Waring Unpaid Whanau Care kNZD/yr, Node 2 AS Landlord Capture kNZD/yr]

Age30_Fiscal     = zeros(3, 6);  % 3 Skill Tiers x 6 Gate-5 Nodes (Nodes 17..22)
CareerRet_Fiscal = zeros(3, 6);  % 3 Skill Tiers x 6 Gate-6 Nodes (Nodes 23..28)

Q_base_Map   = struct('Rural', 1.05, 'Small', 1.40, 'Urban', 1.75, 'Large', 2.05, 'Auckland', 3.10);
Q_mult_Map   = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);
K_whanau_Map = struct('Rural', 0.42, 'Small', 0.38, 'Urban', 0.34, 'Large', 0.32, 'Auckland', 0.28);

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

    % Extract effective regional alloparental whanau care capacity K_whanau(k) (Marilyn Waring buffer)
    if isfield(P_Sim, 'K_whanau') && isfield(P_Sim.K_whanau, hh_type)
        K_whanau_k = P_Sim.K_whanau.(hh_type);
    elseif isfield(K_whanau_Map, reg)
        K_whanau_k = K_whanau_Map.(reg) * ((Q_base / max(0.5, Q_house)) ^ 0.35);
    else
        K_whanau_k = 0.34;
    end

    w_mkt = getfield_def(P_Sim, 'w', 1.0);
    if isfield(P_Sim, 'w_reg') && isfield(P_Sim.w_reg, hh_type)
        w_mkt = P_Sim.w_reg.(hh_type);
    end
    if is_reform_panel, w_mkt = w_mkt * 1.042; end

    if use_gpu
        Dist_G     = gpuArray(double(Dist_k));
        Pol_G      = gpuArray(double(Pol_k));
        a_G        = gpuArray(reshape(a_dbl,      [n_a1, 1, 1, 1]));
        a_prev_G   = gpuArray(reshape(a_prev_dbl, [n_a1, 1, 1, 1]));
        da_G       = gpuArray(reshape(da_span,    [n_a1, 1, 1, 1]));
        h_G        = gpuArray(reshape(double(h_vec), [1, n_h, 1, 1]));
        z_G        = gpuArray(reshape(double(z_vec), [1, 1, n_z1, 1]));
        l_G        = gpuArray(double(l_vec(:)));
        Ih_G       = gpuArray(double(Ih_vec(:)));
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
        z_G        = reshape(double(z_vec), [1, 1, n_z1, 1]);
        l_G        = double(l_vec(:));
        Ih_G       = double(Ih_vec(:));
        ic_G       = double(ic_vec(:));
        z_idx_3D   = reshape(1:n_z1, [1, 1, n_z1, 1]);
        log_h_dst5 = reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]);
    end

    %% PART A (GPU): GATES 1 TO 4 — SYNCHRONIZED WITH 18-NODE PLOT_CHILDFATES_SSANKEY.M
    Dist_Fert = Dist_G(:, :, :, fertile_j);
    tot_p     = max(1e-12, gather(sum(Dist_Fert, 'all')));
    d_ic_idx  = max(1, min(length(ic_vec), Pol_G(3, :, :, :, fertile_j)));
    ic_4D     = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));
    pwage_4D  = w_mkt .* z_G .* h_G;

    % Continuous sub-grid linear cell interpolation weights on cubic asset grid:
    w_cell_025 = min(1.0, max(0.0, (0.025 * Q_house - a_prev_G) ./ da_G));
    w_cell_050 = min(1.0, max(0.0, (0.050 * Q_house - a_prev_G) ./ da_G));
    w_cell_080 = min(1.0, max(0.0, (0.080 * Q_house - a_prev_G) ./ da_G));
    w_cell_160 = min(1.0, max(0.0, (0.160 * Q_house - a_prev_G) ./ da_G));

    is_hard_4D  = w_cell_080;
    is_unemp_4D = (z_idx_3D == 1) | (n_z1 >= 5 & (z_idx_3D == 2) & (w_cell_080 > 0.5));
    m_cash_zero = double(ic_4D <= 1e-5) .* max(w_cell_080, double(z_idx_3D <= 2));

    % Gate 1 Population Weights (Matching Fates Nodes 1, 2, 3):
    w_sev_raw_4D  = max(w_cell_050 .* double(z_idx_3D <= 2), w_cell_025 .* double(z_idx_3D <= 3)) .* ones(size(ic_4D));
    w_tot_vuln_4D = max(w_sev_raw_4D, max(w_cell_160 .* double(z_idx_3D <= 2), ...
        max(w_cell_080 .* double(z_idx_3D <= 3), m_cash_zero)));
    w_ahc_raw_4D  = max(0.0, w_tot_vuln_4D - w_sev_raw_4D);

    lift_s1_sev = min(0.88, 0.735 * eta_ref);
    lift_s1_ahc = min(0.82, 0.638 * eta_ref);
    s1_W1_sev   = (1.00 - lift_s1_sev) .* w_sev_raw_4D;         % Node 1: Severe Material Hardship (DEP-17 9+)
    s1_W2_ahc   = (1.00 - lift_s1_ahc) .* w_ahc_raw_4D;         % Node 2: Residual AHC Squeeze & Paper Support
    s1_W4_sec   = max(0.0, 1.00 - s1_W1_sev - s1_W2_ahc);       % Node 4: Secure Parental Asset Buffer

    % Gate 2 Population Weights (with Marilyn Waring K_whanau(k) rescue out of ic=0 corner):
    whanau_rescue_k = min(0.45, 0.32 * K_whanau_k * ((Q_base / max(0.5, Q_house)) ^ 0.25));
    m_corner = max(0.0, w_sev_raw_4D .* m_cash_zero + (1.0 - whanau_rescue_k) .* w_ahc_raw_4D .* m_cash_zero);
    m_mod    = max(0.0, (1.0 - m_corner) .* double((ic_4D <= 1e-5) | (ic_4D <= 0.35 * max(ic_vec))));
    m_high   = max(0.0, 1.0 - m_corner - m_mod);

    lift_s2 = min(0.92, 0.78 * eta_ref);
    s2_W1   = (1.00 - lift_s2) .* m_corner;
    s2_W2   = lift_s2 .* m_corner + 1.00 .* m_mod;
    s2_W3   = 1.00 .* m_high;
    s2_W_5D = cat(5, s2_W1, s2_W2, s2_W3);

    % --- GATE 1 (J = 1, Birth, Age 0): FOUR BIRTH FISCAL FLOWS (kNZD/yr per cohort birth) ---
    %   (1) Node 1: Acute Hardship Tier 3 Support (Deep Crimson — Special Needs, Emergency Housing, OT crisis)
    %   (2) Node 2: Residual AHC Paper Support & Landlord Capture (Burnt Rust — AS rent capture + abated WfF)
    %   (3) Node 3: Universal Birth Benefit (Steel Blue — PPL + BestStart + LMC, 100% of births)
    %   (4) Node 4: Private Birth Out-of-Pocket (Warm Gold — Secure parental setup & time)
    Acute_Birth_4D = NZD_Scale .* (0.195 .* s1_W1_sev + 0.045 .* double(z_idx_3D == 1) .* s1_W1_sev);
    AHC_Paper_4D   = NZD_Scale .* ((0.095 + 0.028 * max(0, Q_house - 1.0)) .* s1_W2_ahc);
    if is_reform_panel
        Univ_Birth_4D = NZD_Scale .* (0.142 + 0.045 * eta_ref + 0 .* Dist_Fert);
    else
        Univ_Birth_4D = NZD_Scale .* (0.142 + 0 .* Dist_Fert);
    end
    Priv_Birth_4D = NZD_Scale .* (0.045 * Q_house + 0.120 .* pwage_4D .* (0.25 + 0.75 .* (1.0 - m_corner)) + 0.55 .* (1 - s_sub) .* ic_4D);

    % Track Marilyn Waring unpaid whanau care valuation (Lane B) vs AS Landlord Capture (Lane D) in Node 2:
    waring_whanau_kNZD = NZD_Scale * gather(sum(Dist_Fert .* s1_W2_ahc .* (0.085 * K_whanau_k .* pwage_4D), 'all')) / tot_p;
    as_landlord_kNZD   = NZD_Scale * gather(sum(Dist_Fert .* AHC_Paper_4D, 'all')) / tot_p;
    Whanau_Care_G1_G2  = Whanau_Care_G1_G2 + w_reg * [waring_whanau_kNZD, as_landlord_kNZD];

    reg_Pop_S1 = [gather(sum(Dist_Fert .* s1_W1_sev, 'all')) / tot_p, ...
        gather(sum(Dist_Fert .* s1_W2_ahc, 'all')) / tot_p, ...
        1.00, ...
        gather(sum(Dist_Fert .* s1_W4_sec, 'all')) / tot_p];

    reg_F12    = zeros(4, 3);
    reg_Pop_S2 = zeros(1, 3);
    for s2_i = 1:3
        ws = s2_W_5D(:, :, :, :, s2_i);
        reg_Pop_S2(s2_i) = gather(sum(Dist_Fert .* ws, 'all')) / tot_p;
        reg_F12(1, s2_i) = gather(sum(Dist_Fert .* Acute_Birth_4D .* ws, 'all')) / tot_p;
        reg_F12(2, s2_i) = gather(sum(Dist_Fert .* AHC_Paper_4D   .* ws, 'all')) / tot_p;
        reg_F12(3, s2_i) = gather(sum(Dist_Fert .* Univ_Birth_4D  .* ws, 'all')) / tot_p;
        reg_F12(4, s2_i) = gather(sum(Dist_Fert .* Priv_Birth_4D  .* ws, 'all')) / tot_p;
    end

    % --- GATE 2 (J = 2..3, First 2000 Days ECE Gate) ANNUAL COST FLOWS (kNZD/yr per cohort child) ---
    ECE_Corner_Need_4D = NZD_Scale .* (0.135 + 0.085 .* is_hard_4D + 0.065 .* double(is_unemp_4D));
    ECE_PubMod_Cost_4D = NZD_Scale .* (G_ece_eff + 0.045 + s_sub .* ic_4D);
    ECE_High_Cost_4D   = NZD_Scale .* (G_ece_eff + 0.065 + s_sub .* ic_4D);

    reg_ECE_Step = [gather(sum(Dist_Fert .* ECE_Corner_Need_4D .* s2_W1, 'all')) / tot_p, ...
        gather(sum(Dist_Fert .* ECE_PubMod_Cost_4D .* s2_W2, 'all')) / tot_p, ...
        gather(sum(Dist_Fert .* ECE_High_Cost_4D   .* s2_W3, 'all')) / tot_p];

    % --- GATE 3 (J = 5, Ages 12-14 Adolescent Gate): OPTION 2 SPLIT OF NODE 9 (HH UNEMP) VS NODE 10 (CAMHS/ACC ISSC) ---
    if ~is_reform_panel
        P_unemp = [0.82, 0.16, 0.02; 0.55, 0.37, 0.08; 0.28, 0.54, 0.18];
        P_stabl = [0.35, 0.58, 0.07; 0.12, 0.68, 0.20; 0.05, 0.55, 0.40];
        psy_share_of_stress = 0.346; % In SS0: ~8.90 kNZD HH Unemp/Truancy vs ~4.70 kNZD CAMHS/ACC ISSC (out of 13.60 kNZD)
    else
        P_unemp = [0.38, 0.34, 0.28; 0.16, 0.36, 0.48; 0.08, 0.30, 0.62];
        P_stabl = [0.14, 0.46, 0.40; 0.04, 0.38, 0.58; 0.02, 0.26, 0.72];
        psy_share_of_stress = 0.560; % In SS1: ~1.10 kNZD HH Unemp vs ~1.40 kNZD CAMHS/ACC 38% Clinical Floor (out of 2.50 kNZD)
    end

    Adol_Cost_TotStress_4D = NZD_Scale .* (0.100 + 0.120 + 0.126 + 0.068 + 0.045 .* is_hard_4D);
    Adol_Cost_Node9_HH_4D  = (1.0 - psy_share_of_stress) .* Adol_Cost_TotStress_4D; % Node 9: HH Unemp & Truancy Remediation
    Adol_Cost_Node10_Psy4D = psy_share_of_stress         .* Adol_Cost_TotStress_4D; % Node 10: Psychosocial CAMHS & ACC ISSC
    Adol_Cost_Node11_Sch4D = NZD_Scale .* (0.105 + s_sub .* ic_4D + 0 .* Dist_Fert);         % Node 11: Public Schooling (d_2)
    Adol_Cost_Node12_Tua4D = NZD_Scale .* (0.105 + 0.038 + s_sub .* ic_4D + 0 .* Dist_Fert); % Node 12: Montessori / Tuakana

    % Gate 3 -> Gate 4 (J = 6..7 Adult Skill Launch) Gaussian Transitions
    ic_eff_4D  = max(ic_4D, 0.185 .* (1.0 - m_corner));
    inv_gap_4D = log(ic_eff_4D + G_ece_eff + 0.02) - log(0.20 + 0.05 + 0.02);
    if strcmpi(Calibration_Anchor, 'Dunedin_22')
        crowd_pen_4D = 0.14 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.265;
    else
        crowd_pen_4D = 0.18 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.105;
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

    reg_F23_raw   = zeros(3, 4); % Columns: [9_HH_Unemp, 10_Psychosocial_CAMHS_ACC, 11_Public_School, 12_Tuakana]
    reg_F34_raw   = zeros(4, 3);
    reg_Pop_S3    = zeros(1, 4);
    reg_Pop_S4    = zeros(1, 3);
    reg_Adol_Step = zeros(1, 4);

    for s2_i = 1:3
        ws2     = s2_W_5D(:, :, :, :, s2_i);
        mass_s2 = Dist_Fert .* ws2;
        for s3_i = 1:3
            p_s3_4D = P_unemp(s2_i, s3_i) .* double(is_unemp_4D) + P_stabl(s2_i, s3_i) .* (1.0 - double(is_unemp_4D));
            mass_s3 = mass_s2 .* p_s3_4D;
            m_share = gather(sum(mass_s3, 'all')) / tot_p;

            m_st = gather(sum(mass_s3 .* p_st_cell{s3_i}, 'all')) / tot_p;
            m_co = gather(sum(mass_s3 .* p_co_cell{s3_i}, 'all')) / tot_p;
            m_th = gather(sum(mass_s3 .* p_th_cell{s3_i}, 'all')) / tot_p;

            if s3_i == 1
                % Split Gate 3 stress state into Node 9 (HH Unemp/Truancy) and Node 10 (Psychosocial CAMHS/ACC ISSC)
                sh_hh  = (1.0 - psy_share_of_stress) * m_share;
                sh_psy = psy_share_of_stress         * m_share;
                reg_Pop_S3(1)    = reg_Pop_S3(1)    + sh_hh;
                reg_Pop_S3(2)    = reg_Pop_S3(2)    + sh_psy;
                reg_Adol_Step(1) = reg_Adol_Step(1) + gather(sum(mass_s3 .* Adol_Cost_Node9_HH_4D,  'all')) / tot_p;
                reg_Adol_Step(2) = reg_Adol_Step(2) + gather(sum(mass_s3 .* Adol_Cost_Node10_Psy4D, 'all')) / tot_p;
                reg_F23_raw(s2_i, 1) = sh_hh;
                reg_F23_raw(s2_i, 2) = sh_psy;

                reg_F34_raw(1, :) = reg_F34_raw(1, :) + (1.0 - psy_share_of_stress) * [m_st, m_co, m_th];
                reg_F34_raw(2, :) = reg_F34_raw(2, :) + psy_share_of_stress         * [m_st, m_co, m_th];
            elseif s3_i == 2
                reg_Pop_S3(3)    = reg_Pop_S3(3)    + m_share;
                reg_Adol_Step(3) = reg_Adol_Step(3) + gather(sum(mass_s3 .* Adol_Cost_Node11_Sch4D, 'all')) / tot_p;
                reg_F23_raw(s2_i, 3) = m_share;
                reg_F34_raw(3, :)    = reg_F34_raw(3, :) + [m_st, m_co, m_th];
            else
                reg_Pop_S3(4)    = reg_Pop_S3(4)    + m_share;
                reg_Adol_Step(4) = reg_Adol_Step(4) + gather(sum(mass_s3 .* Adol_Cost_Node12_Tua4D, 'all')) / tot_p;
                reg_F23_raw(s2_i, 4) = m_share;
                reg_F34_raw(4, :)    = reg_F34_raw(4, :) + [m_st, m_co, m_th];
            end

            reg_Pop_S4(1) = reg_Pop_S4(1) + m_st;
            reg_Pop_S4(2) = reg_Pop_S4(2) + m_co;
            reg_Pop_S4(3) = reg_Pop_S4(3) + m_th;
        end
    end

    Flow_S1_to_S2     = Flow_S1_to_S2     + w_reg * reg_F12;
    Flow_S2_to_S3     = Flow_S2_to_S3     + w_reg * reg_F23_raw;
    Flow_S3_to_S4     = Flow_S3_to_S4     + w_reg * reg_F34_raw;
    Pop_S1_Birth      = Pop_S1_Birth      + w_reg * reg_Pop_S1;
    Pop_S2_ECE        = Pop_S2_ECE        + w_reg * reg_Pop_S2;
    Pop_S3_Adol       = Pop_S3_Adol       + w_reg * reg_Pop_S3;
    Pop_S4_Skill      = Pop_S4_Skill      + w_reg * (reg_Pop_S4 / max(1e-12, sum(reg_Pop_S4)));
    ECE_Step_Dollars  = ECE_Step_Dollars  + w_reg * reg_ECE_Step;
    Adol_Step_Dollars = Adol_Step_Dollars + w_reg * reg_Adol_Step;

    %% PART B (GPU): GATES 5 & 6 — ALL 4 BARNARDOS EXITS VS. TAX REVENUES BY CATEGORY
    d_l_all  = max(1, min(n_l,  Pol_G(1, :, :, :, :)));
    d_Ih_all = max(1, min(n_Ih, Pol_G(2, :, :, :, :)));
    l_4D     = reshape(l_G(d_l_all(:)),   size(Dist_G));
    Ih_4D    = reshape(Ih_G(d_Ih_all(:)), size(Dist_G));

    earn_4D  = w_mkt .* z_G .* h_G .* max(0, l_4D - Ih_4D);
    paye_4D  = tau_l .* earn_4D;
    cap_4D   = (tau_k * r_ann + tau_a) .* a_G + 0 .* Dist_G;
    cons_w4D = max(c_floor, (1 - tau_l) .* earn_4D + (1 - tau_k) * r_ann .* a_G);
    gst_w4D  = (tau_c / (1 + tau_c)) .* cons_w4D;

    beq_r4D  = (tau_b * 0.045) .* a_G + 0 .* Dist_G;
    cons_r4D = max(c_floor, p_super + (1 - tau_k) * r_ann .* a_G) + 0 .* Dist_G;
    gst_r4D  = (tau_c / (1 + tau_c)) .* cons_r4D;

    tier_bins = {1:2, 3:5, 6:7};
    if isfield(Diag_Sim, 'Emig_By_SkillTier')
        emig_t = [mean(Diag_Sim.Emig_By_SkillTier(1:2)), ...
            mean(Diag_Sim.Emig_By_SkillTier(3:5)), ...
            mean(Diag_Sim.Emig_By_SkillTier(6:7))];
    else
        if ~is_reform_panel, emig_t = [0.04, 0.11, 0.22];
        else,                emig_t = [0.02, 0.06, 0.12];
        end
    end

    exits_124_y     = [0.420, 0.038, 0.006];
    pub_infra_y     = [0.072, 0.072, 0.072];
    exit3_taxloss_y = [0.068, 0.012, 0.000];

    exits_124_w     = [0.380, 0.035, 0.005];
    pub_infra_w     = [0.076, 0.076, 0.076];
    exit3_taxloss_w = [0.078, 0.014, 0.000];

    exits_124_r     = [0.145, 0.022, 0.004];
    pub_infra_r     = [0.085, 0.085, 0.085];

    for t_idx = 1:3
        ih_set = tier_bins{t_idx};

        % --- GATE 5 (J = 10, Age 30, VFI j = 1..3) ---
        D_y    = Dist_G(:, ih_set, :, 1:3);
        mass_y = max(1e-12, gather(sum(D_y, 'all')));
        P_y    = paye_4D(:, ih_set, :, 1:3);
        GC_y   = gst_w4D(:, ih_set, :, 1:3) + cap_4D(:, ih_set, :, 1:3);
        E_y    = earn_4D(:, ih_set, :, 1:3);
        BN_124 = 0.075 .* (E_y < 0.35) + 0.045 .* (a_G < 0.05 * Q_house) + exits_124_y(t_idx);

        paye_y      = NZD_Scale * gather(sum(D_y .* P_y,    'all')) / mass_y;
        gst_cap_y   = NZD_Scale * gather(sum(D_y .* GC_y,   'all')) / mass_y;
        cost_124_y  = NZD_Scale * gather(sum(D_y .* BN_124, 'all')) / mass_y;
        infra_gp_y  = NZD_Scale * pub_infra_y(t_idx);
        ex3_loss_y  = NZD_Scale * exit3_taxloss_y(t_idx);

        sh_t  = Pop_S4_Skill(t_idx);
        ret_t = 1 - emig_t(t_idx);
        Age30_Fiscal(t_idx, :) = Age30_Fiscal(t_idx, :) + w_reg * sh_t * ...
            [ret_t * cost_124_y, ...
            ret_t * infra_gp_y, ...
            ret_t * gst_cap_y, ...
            ret_t * paye_y, ...
            ret_t * ex3_loss_y, ...
            emig_t(t_idx) * (paye_y + gst_cap_y)];

        % --- GATE 6 (J = 11..16, Career to Retirement, VFI j = 4..16) ---
        D_w    = Dist_G(:, ih_set, :, 4:(Jr-1));
        mass_w = max(1e-12, gather(sum(D_w, 'all')));
        P_w    = paye_4D(:, ih_set, :, 4:(Jr-1));
        GC_w   = gst_w4D(:, ih_set, :, 4:(Jr-1)) + cap_4D(:, ih_set, :, 4:(Jr-1));
        E_w    = earn_4D(:, ih_set, :, 4:(Jr-1));
        BN_w   = 0.075 .* (E_w < 0.35) + exits_124_w(t_idx);

        paye_w     = NZD_Scale * gather(sum(D_w .* P_w,  'all')) / mass_w;
        gst_cap_w  = NZD_Scale * gather(sum(D_w .* GC_w, 'all')) / mass_w;
        cost_124_w = NZD_Scale * gather(sum(D_w .* BN_w, 'all')) / mass_w;
        infra_gp_w = NZD_Scale * pub_infra_w(t_idx);
        ex3_loss_w = NZD_Scale * exit3_taxloss_w(t_idx);

        D_r    = Dist_G(:, ih_set, :, Jr:J_tot);
        mass_r = max(1e-12, gather(sum(D_r, 'all')));
        RT_r   = cap_4D(:, ih_set, :, Jr:J_tot) + beq_r4D(:, ih_set, :, Jr:J_tot) + gst_r4D(:, ih_set, :, Jr:J_tot);
        SD_124 = exits_124_r(t_idx) + 0 .* D_r;
        SD_sup = (p_super + pub_infra_r(t_idx)) + 0 .* D_r;

        ret_tax_r  = NZD_Scale * gather(sum(D_r .* RT_r,   'all')) / mass_r;
        cost_124_r = NZD_Scale * gather(sum(D_r .* SD_124, 'all')) / mass_r;
        sup_inf_r  = NZD_Scale * gather(sum(D_r .* SD_sup, 'all')) / mass_r;

        ann_exits_124    = 0.67 * cost_124_w + 0.33 * cost_124_r;
        ann_super_infra  = 0.67 * infra_gp_w + 0.33 * sup_inf_r;
        ann_super_estate = 0.67 * gst_cap_w  + 0.33 * ret_tax_r;
        ann_career_paye  = 0.67 * paye_w;
        ann_exit3_loss   = ret_t * (0.67 * ex3_loss_w);
        ann_abroad_loss  = emig_t(t_idx) * (0.67 * (paye_w + gst_cap_w) + 0.33 * ret_tax_r);

        CareerRet_Fiscal(t_idx, :) = CareerRet_Fiscal(t_idx, :) + w_reg * sh_t * ...
            [ret_t * ann_exits_124, ...
            ret_t * ann_super_infra, ...
            ret_t * ann_super_estate, ...
            ret_t * ann_career_paye, ...
            ann_exit3_loss, ...
            ann_abroad_loss];
    end
end

%% HARMONIZE 6-GATE (28-NODE) FLOW SCALES & SPLIT PRIVATE PARENTAL COMMITMENT INTO NODE 8 (GATE 2) & NODE 13 (GATE 3)
Pop_Priv_G1_G2  = 1.0 - Pop_S2_ECE(1);                 % ~76.0% in SS0 -> ~94.3% in SS1
Pop_Priv_G3     = 1.0 - sum(Pop_S3_Adol(1:2));         % ~81.1% in SS0 -> ~95.1% in SS1
Pop_S1_Birth(4) = max(0.0, 1.0 - Pop_S1_Birth(1) - Pop_S1_Birth(2));

Pop_S2_ECE_4Node  = [Pop_S2_ECE(1), Pop_S2_ECE(2), Pop_S2_ECE(3), Pop_Priv_G1_G2];
Pop_S3_Adol_5Node = [Pop_S3_Adol(1), Pop_S3_Adol(2), Pop_S3_Adol(3), Pop_S3_Adol(4), Pop_Priv_G3];

if ~is_reform_panel
    cond_priv_G2 = 18.50;
    cond_priv_G3 = 19.00;
else
    cond_priv_G2 = 18.70;
    cond_priv_G3 = 19.80;
end
Priv_Cohort_G2 = Pop_Priv_G1_G2 * cond_priv_G2;
Priv_Cohort_G3 = Pop_Priv_G3    * cond_priv_G3;

S2_ECE_4Node_kNZD  = [ECE_Step_Dollars(1),  ECE_Step_Dollars(2),  ECE_Step_Dollars(3),  Priv_Cohort_G2];
S3_Adol_5Node_kNZD = [Adol_Step_Dollars(1), Adol_Step_Dollars(2), Adol_Step_Dollars(3), Adol_Step_Dollars(4), Priv_Cohort_G3];

% Build 4x4 Flow_S1_to_S2_4N (4 Gate-1 Birth Nodes -> 4 Gate-2 ECE Nodes):
Flow_S1_to_S2(4, 1) = 0;
Flow_S1_to_S2_4N = zeros(4, 4);
for c2 = 1:3
    pub_in = sum(Flow_S1_to_S2(1:3, c2));
    if pub_in > 1e-8
        Flow_S1_to_S2_4N(1:3, c2) = S2_ECE_4Node_kNZD(c2) * (Flow_S1_to_S2(1:3, c2) / pub_in);
    else
        Flow_S1_to_S2_4N(3, c2) = S2_ECE_4Node_kNZD(c2);
    end
end
% Also show Marilyn Waring unpaid whanau rescue flow from Node 2 (Residual AHC Squeeze) into Node 6 (Public ECE + Mod Inv)
Flow_S1_to_S2_4N(4, 4) = S2_ECE_4Node_kNZD(4);
S1_Totals = sum(Flow_S1_to_S2_4N, 2);

% Build 4x5 Flow_S2_to_S3_5N (4 Gate-2 ECE Nodes -> 5 Gate-3 Adolescent Nodes):
P_23 = zeros(3, 4);
for r2 = 1:3
    rs = sum(Flow_S2_to_S3(r2, :));
    if rs > 1e-8, P_23(r2, :) = Flow_S2_to_S3(r2, :) / rs; else, P_23(r2, min(4, r2)) = 1; end
end
Flow_S2_to_S3_5N = zeros(4, 5);
for r2 = 1:3
    for c3 = 1:4
        Flow_S2_to_S3_5N(r2, c3) = S2_ECE_4Node_kNZD(r2) * P_23(r2, c3) * 0.82;
        Flow_S2_to_S3_5N(r2, 5)  = Flow_S2_to_S3_5N(r2, 5) + S2_ECE_4Node_kNZD(r2) * P_23(r2, c3) * 0.18;
    end
end
w_priv_r2    = [0, ECE_Step_Dollars(2), ECE_Step_Dollars(3)];
w_priv_r2    = w_priv_r2 / max(1e-8, sum(w_priv_r2));
P_priv_to_G3 = w_priv_r2 * P_23;
for c3 = 1:4
    Flow_S2_to_S3_5N(4, c3) = S2_ECE_4Node_kNZD(4) * P_priv_to_G3(c3) * (1 - 0.78 * (c3 >= 3));
    Flow_S2_to_S3_5N(4, 5)  = Flow_S2_to_S3_5N(4, 5) + S2_ECE_4Node_kNZD(4) * P_priv_to_G3(c3) * (0.78 * (c3 >= 3));
end
target_G3_widths = sum(S2_ECE_4Node_kNZD) * (S3_Adol_5Node_kNZD / max(1e-8, sum(S3_Adol_5Node_kNZD)));
for iter_ras = 1:4
    for c3 = 1:5
        cs = sum(Flow_S2_to_S3_5N(:, c3));
        if cs > 1e-8, Flow_S2_to_S3_5N(:, c3) = Flow_S2_to_S3_5N(:, c3) * (target_G3_widths(c3) / cs); end
    end
    for r2 = 1:4
        rs = sum(Flow_S2_to_S3_5N(r2, :));
        if rs > 1e-8, Flow_S2_to_S3_5N(r2, :) = Flow_S2_to_S3_5N(r2, :) * (S2_ECE_4Node_kNZD(r2) / rs); end
    end
end

% Build 5x3 Flow_S3_to_S4_5N (5 Gate-3 Adolescent Nodes -> 3 Gate-4 Skill Launch Nodes):
S3_In_Widths = sum(Flow_S2_to_S3_5N, 1);
P_34 = zeros(4, 3);
for r3 = 1:4
    rs = sum(Flow_S3_to_S4(r3, :));
    if rs > 1e-8, P_34(r3, :) = Flow_S3_to_S4(r3, :) / rs; else, P_34(r3, min(3, r3)) = 1; end
end
Flow_S3_to_S4_5N = zeros(5, 3);
for r3 = 1:4
    Flow_S3_to_S4_5N(r3, :) = S3_In_Widths(r3) * P_34(r3, :);
end
w_priv_r3 = [0, 0, Adol_Step_Dollars(3), Adol_Step_Dollars(4)];
w_priv_r3 = w_priv_r3 / max(1e-8, sum(w_priv_r3));
Flow_S3_to_S4_5N(5, :) = S3_In_Widths(5) * (w_priv_r3 * P_34);
S4_Totals = sum(Flow_S3_to_S4_5N, 1);

% Exact adult dollar totals (kNZD/yr per cohort child) for Gate 5 (Age 30) and Gate 6 (Career to J=16)
A30_Col_Dollars = sum(Age30_Fiscal, 1);
CR_Col_Dollars  = sum(CareerRet_Fiscal, 1);

S5_Widths = sum(S4_Totals) * (A30_Col_Dollars / max(1e-8, sum(A30_Col_Dollars)));
S6_Widths = sum(S4_Totals) * (CR_Col_Dollars  / max(1e-8, sum(CR_Col_Dollars)));

Flow_S4_to_S5 = max(Age30_Fiscal, 0);
Flow_S4_to_S5(3, 5) = 0;
for iter_ras = 1:15
    for c5 = 1:6
        cs = sum(Flow_S4_to_S5(:, c5));
        if cs > 1e-8, Flow_S4_to_S5(:, c5) = Flow_S4_to_S5(:, c5) * (S5_Widths(c5) / cs); end
    end
    for r4 = 1:3
        rs = sum(Flow_S4_to_S5(r4, :));
        if rs > 1e-8, Flow_S4_to_S5(r4, :) = Flow_S4_to_S5(r4, :) * (S4_Totals(r4) / rs); end
    end
end

Flow_S5_to_S6 = zeros(6, 6);
Flow_S5_to_S6(1, :) = S5_Widths(1) * [0.74, 0.16, 0.05, 0.03, 0.01, 0.01];
Flow_S5_to_S6(2, :) = S5_Widths(2) * [0.12, 0.66, 0.12, 0.08, 0.01, 0.01];
Flow_S5_to_S6(3, :) = S5_Widths(3) * [0.04, 0.18, 0.54, 0.22, 0.01, 0.01];
Flow_S5_to_S6(4, :) = S5_Widths(4) * [0.03, 0.16, 0.30, 0.49, 0.01, 0.01];
Flow_S5_to_S6(5, :) = S5_Widths(5) * [0.04, 0.04, 0.02, 0.00, 0.90, 0.00];
Flow_S5_to_S6(6, :) = S5_Widths(6) * [0.00, 0.02, 0.04, 0.04, 0.00, 0.90];
for iter_ras = 1:15
    for c_j = 1:6
        cs = sum(Flow_S5_to_S6(:, c_j));
        if cs > 1e-8, Flow_S5_to_S6(:, c_j) = Flow_S5_to_S6(:, c_j) * (S6_Widths(c_j) / cs); end
    end
    for r_i = 1:6
        rs = sum(Flow_S5_to_S6(r_i, :));
        if rs > 1e-8, Flow_S5_to_S6(r_i, :) = Flow_S5_to_S6(r_i, :) * (S5_Widths(r_i) / rs); end
    end
end

%% COMPUTE MACRO PUBLIC RESIDUAL (OMEGA) & 2050 50/50 SURPLUS SPLIT
Bad_30      = A30_Col_Dollars(1) + A30_Col_Dollars(2);
Good_30     = A30_Col_Dollars(3) + A30_Col_Dollars(4);
net_fisc_30 = Good_30 - Bad_30;

Bad_CR      = CR_Col_Dollars(1) + CR_Col_Dollars(2);
Good_CR     = CR_Col_Dollars(3) + CR_Col_Dollars(4);
net_fisc_CR = Good_CR - Bad_CR;

Bad_Final2  = [Bad_30,  Bad_CR];
Good_Final2 = [Good_30, Good_CR];

Surplus_30  = max(0, net_fisc_30);
Surplus_CR  = max(0, net_fisc_CR);

DebtSink_50_30 = 0.50 * Surplus_30;  Reinvest_50_30 = 0.50 * Surplus_30;
DebtSink_50_CR = 0.50 * Surplus_CR;  Reinvest_50_CR = 0.50 * Surplus_CR;

r_gov_bond   = 0.042;
mu_infra_div = 1.65;
Cohort_N     = 60.0;

% Save exact 28-node population & monetary vectors into output Ledger struct
Ledger.Pop_S1_Birth                     = Pop_S1_Birth(:);
Ledger.Pop_S2_ECE                       = Pop_S2_ECE(:);
Ledger.Pop_S2_ECE_4Node                 = Pop_S2_ECE_4Node(:);
Ledger.Pop_S3_Adol                      = Pop_S3_Adol(:);
Ledger.Pop_S3_Adol_5Node                = Pop_S3_Adol_5Node(:);
Ledger.Pop_S4_Skill                     = Pop_S4_Skill(:);
Ledger.S1_Birth_kNZD                    = S1_Totals(:);
Ledger.S2_ECE_3Node_kNZD                = ECE_Step_Dollars(:);
Ledger.S2_ECE_4Node_kNZD                = S2_ECE_4Node_kNZD(:);
Ledger.S3_Adol_4Node_kNZD               = Adol_Step_Dollars(:);
Ledger.S3_Adol_5Node_kNZD               = S3_Adol_5Node_kNZD(:);
Ledger.S4_Skill_kNZD                    = S4_Totals(:);
Ledger.S5_Age30_kNZD                    = A30_Col_Dollars(:);
Ledger.S6_Career_kNZD                   = CR_Col_Dollars(:);
Ledger.Whanau_And_Landlord_G1_kNZD      = Whanau_Care_G1_G2(:);
Ledger.Net_Fiscal_Balance_kNZD          = [net_fisc_30, net_fisc_CR];
Ledger.SinkingFund_50Pct_kNZD           = [DebtSink_50_30, DebtSink_50_CR];
Ledger.ReinvestmentPool_50Pct_kNZD      = [Reinvest_50_30, Reinvest_50_CR];
Ledger.Annual_DebtService_Saving_kNZD   = r_gov_bond * [DebtSink_50_30, DebtSink_50_CR];
Ledger.Public_Infra_Yield_Dividend_kNZD = mu_infra_div * [Reinvest_50_30, Reinvest_50_CR];
Ledger.Cum_2050_DebtReduction_MNZD      = 25 * Cohort_N * (0.4 * DebtSink_50_30 + 0.6 * DebtSink_50_CR) * (1 + 0.5 * 25 * r_gov_bond);
Ledger.Cum_2050_ReinvestPool_MNZD       = 25 * Cohort_N * (0.4 * Reinvest_50_30 + 0.6 * Reinvest_50_CR);

%% BUILD 28-NODE DOLLAR-LABELED NODE NAMES (OPTION 2: 4 NODES AT GATE 1, 5 NODES AT GATE 3)
Nodes_S1 = {sprintf('1. Acute Hardship Tier 3 Support\n     (%.1f%% pop | %.1f kNZD/yr)', 100*Pop_S1_Birth(1), S1_Totals(1)), ...
    sprintf('2. Residual AHC Paper & Whanau\n     (%.1f%% pop | %.1f kNZD/yr)',   100*Pop_S1_Birth(2), S1_Totals(2)), ...
    sprintf('3. Universal Birth Benefit\n     (100%% pop | %.1f kNZD/yr)',        S1_Totals(3)), ...
    sprintf('4. Private Birth Out-of-Pocket\n     (%.1f%% pop | %.1f kNZD/yr)',   100*Pop_S1_Birth(4), S1_Totals(4))};

Nodes_S2 = {sprintf('5. ECE Corner + Benefit Need\n     (%.1f%% pop | %.1f kNZD/yr)',          100*Pop_S2_ECE_4Node(1), S2_ECE_4Node_kNZD(1)), ...
    sprintf('6. Public ECE Wraparound\n     (%.1f%% pop | %.1f kNZD/yr)',              100*Pop_S2_ECE_4Node(2), S2_ECE_4Node_kNZD(2)), ...
    sprintf('7. High-Intensity Public ECE\n     (%.1f%% pop | %.1f kNZD/yr)',          100*Pop_S2_ECE_4Node(3), S2_ECE_4Node_kNZD(3)), ...
    sprintf('8. Private Parental ECE (Cash+Time)\n     (%.1f%% pop | %.1f kNZD/yr)',   100*Pop_S2_ECE_4Node(4), S2_ECE_4Node_kNZD(4))};

Nodes_S3 = {sprintf('9. HH Unemp & Truancy Remed.\n     (%.1f%% pop | %.1f kNZD/yr)',          100*Pop_S3_Adol_5Node(1), S3_Adol_5Node_kNZD(1)), ...
    sprintf('10. Psychosocial CAMHS & ACC ISSC\n       (%.1f%% pop | %.1f kNZD/yr)',   100*Pop_S3_Adol_5Node(2), S3_Adol_5Node_kNZD(2)), ...
    sprintf('11. Public Schooling (d_2)\n       (%.1f%% pop | %.1f kNZD/yr)',          100*Pop_S3_Adol_5Node(3), S3_Adol_5Node_kNZD(3)), ...
    sprintf('12. Montessori / Tuakana Mentoring\n       (%.1f%% pop | %.1f kNZD/yr)',  100*Pop_S3_Adol_5Node(4), S3_Adol_5Node_kNZD(4)), ...
    sprintf('13. Private Adol. Commit (Cash+Time)\n       (%.1f%% pop | %.1f kNZD/yr)',100*Pop_S3_Adol_5Node(5), S3_Adol_5Node_kNZD(5))};

if reform_intensity <= 0
    lbl_16 = sprintf('16. Thriving Tier h6-h7\n        [Rent-Seeking Skew]\n        (%.1f%% pop | %.1f kNZD/yr)', 100*Pop_S4_Skill(3), S4_Totals(3));
elseif reform_intensity <= 1.0
    lbl_16 = sprintf('16. Thriving Tier h6-h7\n        [Pivot to Builders]\n        (%.1f%% pop | %.1f kNZD/yr)', 100*Pop_S4_Skill(3), S4_Totals(3));
else
    lbl_16 = sprintf('16. Thriving Tier h6-h7\n        [z_h Builders]\n        (%.1f%% pop | %.1f kNZD/yr)',      100*Pop_S4_Skill(3), S4_Totals(3));
end

Nodes_S4 = {sprintf('14. Struggling Tier h1-h2 [Exits 1,2,4]\n       (%.1f%% pop | %.1f kNZD/yr)', 100*Pop_S4_Skill(1), S4_Totals(1)), ...
    sprintf('15. Core Skill Tier h3-h5\n       (%.1f%% pop | %.1f kNZD/yr)',               100*Pop_S4_Skill(2), S4_Totals(2)), ...
    lbl_16};

if Surplus_30 > 0.05
    lbl_19 = sprintf('19. Age 30 GST & z_h Cap Tax\n       (%.1f kNZD/yr | Reinvest: +%.1fk)', A30_Col_Dollars(3), Reinvest_50_30);
    lbl_20 = sprintf('20. Age 30 Builder PAYE Tax\n       (%.1f kNZD/yr | Debt Sink: +%.1fk)', A30_Col_Dollars(4), DebtSink_50_30);
else
    lbl_19 = sprintf('19. Age 30 GST & Cap Tax [z_l Skew]\n        (%.1f kNZD/yr)', A30_Col_Dollars(3));
    lbl_20 = sprintf('20. Age 30 PAYE Income Tax\n        (%.1f kNZD/yr)',          A30_Col_Dollars(4));
end

Nodes_S5 = {sprintf('17. Exits 1,2,4: Care/Hosp/Just\n       (%.1f kNZD/yr | @32k/struggling)', A30_Col_Dollars(1)), ...
    sprintf('18. Infra, Roads & Base Health\n       (%.1f kNZD/yr per adult)',          A30_Col_Dollars(2)), ...
    lbl_19, ...
    lbl_20, ...
    sprintf('21. Exit 3: Lower-Skill Lost Tax\n       (%.1f kNZD/yr foregone)',         A30_Col_Dollars(5)), ...
    sprintf('22. Age 30 Emig Tax Loss\n       (%.1f kNZD/yr to Abroad)',                A30_Col_Dollars(6))};

if Surplus_CR > 0.05
    lbl_25 = sprintf('25. GST, z_h Cap & Estate Tax\n       (%.1f kNZD/yr | 50%% Reinvest: +%.1fk)', CR_Col_Dollars(3), Reinvest_50_CR);
    lbl_26 = sprintf('26. Career Builder PAYE Tax\n       (%.1f kNZD/yr | 50%% Debt Sink: +%.1fk)',  CR_Col_Dollars(4), DebtSink_50_CR);
else
    lbl_25 = sprintf('25. GST, Cap & Estate Pool [z_l Skew]\n       (%.1f kNZD/yr)', CR_Col_Dollars(3));
    lbl_26 = sprintf('26. Career PAYE Income Tax\n       (%.1f kNZD/yr)',            CR_Col_Dollars(4));
end

Nodes_S6 = {sprintf('23. Exits 1,2,4: Ongoing Burden\n       (%.1f kNZD/yr)',  CR_Col_Dollars(1)), ...
    sprintf('24. NZ Super, Infra & Health\n       (%.1f kNZD/yr)',     CR_Col_Dollars(2)), ...
    lbl_25, ...
    lbl_26, ...
    sprintf('27. Exit 3: Career Lost Tax\n       (%.1f kNZD/yr foregone)', CR_Col_Dollars(5)), ...
    sprintf('28. Perm. Abroad Tax Loss\n       (%.1f kNZD/yr in Abroad)',  CR_Col_Dollars(6))};

% Prune sub-threshold phantom ribbons (< 0.10 kNZD/yr) and redistribute pro-rata
minFiscalRibbon_k = 0.10;
Flow_S1_to_S2_4N = pruneAndBalanceFlowMatrix(Flow_S1_to_S2_4N, minFiscalRibbon_k);
Flow_S2_to_S3_5N = pruneAndBalanceFlowMatrix(Flow_S2_to_S3_5N, minFiscalRibbon_k);
Flow_S3_to_S4_5N = pruneAndBalanceFlowMatrix(Flow_S3_to_S4_5N, minFiscalRibbon_k);
Flow_S4_to_S5    = pruneAndBalanceFlowMatrix(Flow_S4_to_S5,    minFiscalRibbon_k);
Flow_S5_to_S6    = pruneAndBalanceFlowMatrix(Flow_S5_to_S6,    minFiscalRibbon_k);

% Assemble links cell array
links = {};
row_k = 0;
for i = 1:4
    for j = 1:4
        if Flow_S1_to_S2_4N(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S1{i}, Nodes_S2{j}, Flow_S1_to_S2_4N(i, j)};
        end
    end
end
for i = 1:4
    for j = 1:5
        if Flow_S2_to_S3_5N(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S2{i}, Nodes_S3{j}, Flow_S2_to_S3_5N(i, j)};
        end
    end
end
for i = 1:5
    for j = 1:3
        if Flow_S3_to_S4_5N(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S3{i}, Nodes_S4{j}, Flow_S3_to_S4_5N(i, j)};
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
for i = 1:6
    for j = 1:6
        if Flow_S5_to_S6(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S5{i}, Nodes_S6{j}, Flow_S5_to_S6(i, j)};
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
SK.Sep             = 0.044;
if isprop(SK, 'FontName')
    SK.FontName = 'Helvetica';
end

% 28-Node Palette (Deep Crimson for Node 1, Burnt Rust for Node 2, Warm Gold reserved for Private Parental Nodes 4, 8, 13):
Master_Colors = [0.72, 0.12, 0.14;  % 1. Acute Hardship Tier 3 Support [Deep Crimson]
    0.78, 0.32, 0.20;  % 2. Residual AHC Paper & Whanau [Burnt Rust / Terracotta]
    0.24, 0.50, 0.70;  % 3. Universal Birth Benefit [Public Steel Blue]
    0.82, 0.54, 0.14;  % 4. Private Birth Out-of-Pocket [Parental Warm Gold]
    0.78, 0.20, 0.16;  % 5. ECE Corner + Benefit Need
    0.24, 0.50, 0.70;  % 6. Public ECE Wraparound
    0.14, 0.62, 0.50;  % 7. High-Intensity Public ECE
    0.84, 0.56, 0.14;  % 8. Private Parental ECE (Cash+Time) [Parental Warm Gold]
    0.82, 0.24, 0.16;  % 9. HH Unemp & Truancy Remediation
    0.64, 0.16, 0.36;  % 10. Psychosocial CAMHS & ACC ISSC [38% Clinical Floor Crimson-Plum]
    0.26, 0.52, 0.70;  % 11. Public Schooling (d_2)
    0.14, 0.62, 0.50;  % 12. Montessori / Tuakana Mentoring
    0.84, 0.56, 0.14;  % 13. Private Adol. Commit (Cash+Time) [Parental Warm Gold]
    0.74, 0.18, 0.18;  % 14. Struggling Tier h1-h2
    0.30, 0.56, 0.68;  % 15. Core Skill Tier h3-h5
    0.12, 0.58, 0.46;  % 16. Thriving Tier h6-h7
    0.80, 0.22, 0.18;  % 17. Age 30 Exits 1,2,4 Remediation
    0.76, 0.46, 0.18;  % 18. Age 30 Infra, Roads & Base Health
    0.22, 0.48, 0.70;  % 19. Age 30 GST & Cap Tax
    0.14, 0.60, 0.48;  % 20. Age 30 PAYE Income Tax
    0.68, 0.30, 0.48;  % 21. Age 30 Exit 3: Lower-Skill Lost Tax
    0.50, 0.32, 0.68;  % 22. Age 30 Emig Tax Loss
    0.76, 0.20, 0.18;  % 23. Career Exits 1,2,4 Ongoing Burden
    0.74, 0.44, 0.16;  % 24. Career NZ Super, Infra & Health
    0.20, 0.46, 0.68;  % 25. Career GST, Cap & Estate Tax Pool
    0.12, 0.58, 0.46;  % 26. Career PAYE Income Tax
    0.64, 0.28, 0.46;  % 27. Career Exit 3: Lower-Skill Lost Tax
    0.46, 0.28, 0.66   % 28. Career Permanent Abroad Tax Loss
    ];

All_Node_Names = [Nodes_S1, Nodes_S2, Nodes_S3, Nodes_S4, Nodes_S5, Nodes_S6];
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
xlim(ax, [curr_xlim(1) - 0.18, curr_xlim(2) + 1.38]);

curr_ylim = ylim(ax);
y_span    = diff(curr_ylim);
ylim(ax, [curr_ylim(1) - 0.24 * y_span, curr_ylim(2) + 0.12 * y_span]);

set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 8.5);

%% DRAW 6-GATE HORIZONTAL "J" AXIS CENTERED ON EACH BAR VIA sum(xd(:))/4
y_axis_line = curr_ylim(1) - 0.09 * y_span;
tick_h      = 0.022 * y_span;

p_all        = findall(ax, 'Type', 'Patch');
x_center_col = zeros(1, 6);
for c_i = 1:6
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

plot(ax, [x_center_col(1), x_center_col(6)], [y_axis_line, y_axis_line], '-', ...
    'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.4);

J_Stage_Labels = {
    sprintf('J = 1 (Birth, Age 0)\n(Out-of-Pocket vs Public $)');
    sprintf('J = 2..3 (Ages 0-5)\n(First 2000 Days ECE Gate)');
    sprintf('J = 5 (Ages 12-14)\n(Adol. Gate + Exits 1,2,4)');
    sprintf('J = 6..7 (Age 20)\n(Adult Skill Launch)');
    sprintf('J = 10 (Age 30)\n(Exits 1-4 vs Annual Tax $)');
    sprintf('J = 11..16 (To Ret.)\n(Exits 1-4 & Super vs Tax $)')
    };

for col_x = 1:6
    x_tick = x_center_col(col_x);
    plot(ax, [x_tick, x_tick], [y_axis_line - tick_h, y_axis_line + tick_h], '-', ...
        'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.5);

    text(ax, x_tick, y_axis_line - 1.6 * tick_h, J_Stage_Labels{col_x}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', 'Helvetica', 'FontSize', 8.8, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20]);
end

%% DRAW WIGGLY REGIME-BREAK LINE DOWN THE MIDDLE OF GATE 4 (J = 6..7, ADULT SKILL LAUNCH)
% Separates the Childhood Investment Regime (Gates 1-3, true 1:1 scale) from the
% Adult Fiscal & Tax Regime (Gates 5-6, true 1:1 scale).
col4_boxes = [];
for k_p = 1:length(p_all)
    xd = get(p_all(k_p), 'XData');
    yd = get(p_all(k_p), 'YData');
    if numel(xd) == 4 && abs((sum(xd(:)) / 4) - 4) < 0.45
        col4_boxes(end+1, :) = [min(xd(:)), max(xd(:)), min(yd(:)), max(yd(:))]; %#ok<AGROW>
    end
end
if ~isempty(col4_boxes)
    x_c4     = mean(col4_boxes(:, 1:2), 'all');
    w_c4     = mean(col4_boxes(:, 2) - col4_boxes(:, 1));
    y_bot_c4 = min(col4_boxes(:, 3)) - 0.025 * y_span;
    y_top_c4 = max(col4_boxes(:, 4)) + 0.025 * y_span;

    % Construct smooth sinusoidal wiggly break line down the center of Gate 4
    y_wig    = linspace(y_bot_c4, y_top_c4, 180);
    n_waves  = 9.5;
    amp_x    = 0.16 * w_c4;
    dx_gap   = 0.11 * w_c4;
    x_wig_C  = x_c4 + amp_x * sin(2 * pi * n_waves * (y_wig - y_bot_c4) / max(1e-8, y_top_c4 - y_bot_c4));

    % White inner ribbon + twin dark charcoal wave edges (classic engineering scale-break symbol)
    plot(ax, x_wig_C,          y_wig, '-', 'Color', [1.00, 1.00, 1.00], 'LineWidth', 3.6);
    plot(ax, x_wig_C - dx_gap, y_wig, '-', 'Color', [0.15, 0.15, 0.15], 'LineWidth', 1.4);
    plot(ax, x_wig_C + dx_gap, y_wig, '-', 'Color', [0.15, 0.15, 0.15], 'LineWidth', 1.4);

    % Small top badge above Gate 4 marking the Childhood -> Adult scale break
    text(ax, x_c4, y_top_c4 + 0.012 * y_span, ...
        sprintf('%s Childhood Scale  |  Adult Fiscal Scale %s', char(9668), char(9658)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontName', 'Helvetica', 'FontSize', 7.8, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20], 'BackgroundColor', [0.98, 0.98, 0.94], ...
        'EdgeColor', [0.55, 0.55, 0.55], 'Margin', 1.8);
end

%% DOCUMENT 2 PROTOCOL: NET-ZERO BREAKEVEN LINE & 50/50 DEBT-SINKING VS. REINVESTMENT VISUALIZATION
cols_target = [5, 6];
y_zero_f2   = nan(1, 2);
y_topG_f2   = nan(1, 2); % Top of the Good Tax blocks (100% of Tax Revenue collected)
y_split_50  = nan(1, 2); % 50/50 split line inside the Net Tax Surplus zone (when Good > Bad)
x_cent_f2   = nan(1, 2);
x_left_f2   = nan(1, 2);
x_rght_f2   = nan(1, 2);

for idx_f = 1:2
    c_i = cols_target(idx_f);
    col_boxes = [];
    for k_p = 1:length(p_all)
        xd = get(p_all(k_p), 'XData');
        yd = get(p_all(k_p), 'YData');
        if numel(xd) == 4 && abs((sum(xd(:)) / 4) - c_i) < 0.45
            col_boxes(end+1, :) = [min(xd(:)), max(xd(:)), min(yd(:)), max(yd(:))]; %#ok<AGROW>
        end
    end
    if size(col_boxes, 1) >= 4
        [~, s_ord] = sort(col_boxes(:, 3), 'ascend');
        col_boxes  = col_boxes(s_ord, :);

        x_left_f2(idx_f) = col_boxes(1, 1);
        x_rght_f2(idx_f) = col_boxes(1, 2);
        x_cent_f2(idx_f) = sum(col_boxes(1, 1:2)) / 2;

        bad_boxes  = col_boxes(1:2, :);
        good_boxes = col_boxes(3:min(4, size(col_boxes, 1)), :);
        y_topG_f2(idx_f) = good_boxes(end, 4);

        B_val = Bad_Final2(idx_f);
        G_val = Good_Final2(idx_f);
        net_v = G_val - B_val;

        y_top_bad  = bad_boxes(end, 4);
        y_bot_good = good_boxes(1, 3);
        y_origin   = 0.5 * (y_top_bad + y_bot_good);

        if abs(net_v) < 1e-6
            y_zero_f2(idx_f) = y_origin;
        elseif net_v > 0
            % Net Surplus (Omega > 0): Breakeven sits inside Good where Taxes cover 100% of Bad Outlays;
            % the remaining Good block height ABOVE y_zero_f2 is the Net Fiscal Surplus (Omega)!
            % Wait: to make the zone ABOVE y_zero_f2 equal the Net Surplus (Omega = G_val - B_val),
            % the height from the bottom of Good up to y_zero_f2 covers B_val (fraction f_cover = B_val / G_val),
            % and the height ABOVE y_zero_f2 up to the top of Good is f_surplus = (G_val - B_val) / G_val!
            f_surplus = net_v / max(1e-8, G_val);
            g_heights = good_boxes(:, 4) - good_boxes(:, 3);
            tot_g_h   = sum(g_heights);
            target_h  = f_surplus * tot_g_h;
            cum_h     = 0;
            for g_k = 1:size(good_boxes, 1)
                if cum_h + g_heights(g_k) >= target_h || g_k == size(good_boxes, 1)
                    y_zero_f2(idx_f) = good_boxes(g_k, 3) + max(0, target_h - cum_h);
                    break;
                end
                cum_h = cum_h + g_heights(g_k);
            end

            % Compute exact 50/50 Split Height inside the Surplus Zone (half of net_v):
            target_h_50 = 0.50 * target_h;
            cum_h50     = 0;
            for g_k = 1:size(good_boxes, 1)
                if cum_h50 + g_heights(g_k) >= target_h_50 || g_k == size(good_boxes, 1)
                    y_split_50(idx_f) = good_boxes(g_k, 3) + max(0, target_h_50 - cum_h50);
                    break;
                end
                cum_h50 = cum_h50 + g_heights(g_k);
            end
        else
            % Net Deficit (Omega < 0): descend DOWNWARD from the top of Bad by (Bad - Good) / Bad
            f_deficit = (B_val - G_val) / max(1e-8, B_val);
            b_heights = bad_boxes(:, 4) - bad_boxes(:, 3);
            target_d  = f_deficit * sum(b_heights);
            cum_d     = 0;
            for b_k = size(bad_boxes, 1):-1:1
                if cum_d + b_heights(b_k) >= target_d || b_k == 1
                    y_zero_f2(idx_f) = bad_boxes(b_k, 4) - max(0, target_d - cum_d);
                    break;
                end
                cum_d = cum_d + b_heights(b_k);
            end
        end

        % Subtle gray dotted reference tick at the Good/Bad interface ($0 origin)
        plot(ax, [x_left_f2(idx_f) - 0.025, x_rght_f2(idx_f) + 0.025], ...
            [y_origin, y_origin], ':', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.3);

        % Solid dark bar at Net Balance height (y_zero_f2)
        plot(ax, [x_left_f2(idx_f) - 0.035, x_rght_f2(idx_f) + 0.035], ...
            [y_zero_f2(idx_f), y_zero_f2(idx_f)], '-', ...
            'Color', [0.10, 0.10, 0.10], 'LineWidth', 2.8);

        % If Surplus > 0, draw the 50/50 Debt-Sinking vs. Reinvestment divider bar at y_split_50
        if ~isnan(y_split_50(idx_f)) && net_v > 0.5
            plot(ax, [x_left_f2(idx_f) - 0.030, x_rght_f2(idx_f) + 0.030], ...
                [y_split_50(idx_f), y_split_50(idx_f)], '-', ...
                'Color', [0.05, 0.42, 0.35], 'LineWidth', 2.2);
        end
    end
end

if all(~isnan(y_zero_f2))
    plot(ax, x_cent_f2, y_zero_f2, '--o', ...
        'Color', [0.12, 0.12, 0.12], 'LineWidth', 2.0, ...
        'MarkerSize', 6.0, 'MarkerFaceColor', [0.98, 0.82, 0.18], 'MarkerEdgeColor', [0.10, 0.10, 0.10]);

    % If both Gate 5 & Gate 6 have positive surplus (or in Reform Panel B), connect the 50/50 split line
    if all(~isnan(y_split_50)) && is_reform_panel
        plot(ax, x_cent_f2, y_split_50, ':s', ...
            'Color', [0.05, 0.42, 0.35], 'LineWidth', 1.8, ...
            'MarkerSize', 5.2, 'MarkerFaceColor', [0.20, 0.80, 0.65], 'MarkerEdgeColor', [0.05, 0.35, 0.28]);

        % Callout badge showing the 2050 50/50 Surplus Split at Gate 6
        text(ax, x_rght_f2(2) + 0.04, y_zero_f2(2), ...
            sprintf('Net Fiscal Surplus: +$%.1fk/yr\n  • 50%% 2050 Debt Sinking: +$%.1fk/yr\n  • 50%% Reinvest (Infra/NZSF): +$%.1fk/yr', ...
            net_fisc_CR, DebtSink_50_CR, Reinvest_50_CR), ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
            'FontName', 'Helvetica', 'FontSize', 8.0, 'FontWeight', 'bold', ...
            'Color', [0.10, 0.10, 0.10], 'BackgroundColor', [0.96, 1.00, 0.96], ...
            'EdgeColor', [0.15, 0.55, 0.45], 'Margin', 2.5);
    else
        text(ax, x_rght_f2(2) + 0.04, y_zero_f2(2), ...
            sprintf('Net Fiscal Balance\n(Good Taxes - Crown Outlays)'), ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
            'FontName', 'Helvetica', 'FontSize', 8.3, 'FontWeight', 'bold', ...
            'Color', [0.12, 0.12, 0.12], 'BackgroundColor', [1.0, 0.98, 0.90], ...
            'EdgeColor', [0.4, 0.4, 0.4], 'Margin', 2);
    end
end

if strcmpi(reg_choice, 'Urban') && length(reg_list) > 1
    disp_reg = 'Urban';
elseif strcmpi(reg_choice, 'National')
    disp_reg = 'National';
else
    disp_reg = reg_choice;
end

n_sign_30 = char('+' * (net_fisc_30 >= 0) + '-' * (net_fisc_30 < 0));
n_sign_CR = char('+' * (net_fisc_CR >= 0) + '-' * (net_fisc_CR < 0));
if is_reform_panel && net_fisc_CR > 0
    t_str = sprintf('%s — %s | Net Surplus: %s$%.1fk (Age 30) | %s$%.1fk (To Ret: $%.1fk Debt Sink + $%.1fk Reinvest)', ...
        Panel_Tag, disp_reg, n_sign_30, abs(net_fisc_30), n_sign_CR, abs(net_fisc_CR), DebtSink_50_CR, Reinvest_50_CR);
else
    t_str = sprintf('%s — %s (Cohort-Weighted $k/yr per Birth) | Net Balance: %s$%.1fk/yr (Age 30) | %s$%.1fk/yr (To Ret.)', ...
        Panel_Tag, disp_reg, n_sign_30, abs(net_fisc_30), n_sign_CR, abs(net_fisc_CR));
end
t_obj = title(ax, t_str, 'FontName', 'Helvetica', 'FontSize', 11.2, 'FontWeight', 'bold');
set(t_obj, 'Units', 'normalized');
t_pos = get(t_obj, 'Position');
set(t_obj, 'Position', [t_pos(1), 1.03, t_pos(3)]);

axis(ax, 'off');
end

function out_4D = is_mt_4D_helper(mask_in, ref_4D)
out_4D = double(mask_in) + 0 .* ref_4D;
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

function T_Prot = Build_Multiphase_2050_Protocol_Table(Phase_Ledgers, Phase_Codes, Target_Region)
%% BUILD_MULTIPHASE_2050_PROTOCOL_TABLE
% Builds the 2050 Sovereign Debt-Sinking & Public Reinvestment Table across N >= 2 phases.
N_p   = numel(Phase_Ledgers);
L_ref = Phase_Ledgers{1};
T_Prot = table([L_ref.Net_Fiscal_Balance_kNZD(1); L_ref.Net_Fiscal_Balance_kNZD(2)], ...
    'RowNames', {'Gate5_Age30_J10', 'Gate6_CareerToRet_J11_16'}, ...
    'VariableNames', {sprintf('Baseline_%s_kNZD', Phase_Codes{1})});

for p = 2:N_p
    Lp   = Phase_Ledgers{p};
    code = Phase_Codes{p};
    Omega_30 = max(0, Lp.Net_Fiscal_Balance_kNZD(1) - L_ref.Net_Fiscal_Balance_kNZD(1));
    Omega_CR = max(0, Lp.Net_Fiscal_Balance_kNZD(2) - L_ref.Net_Fiscal_Balance_kNZD(2));

    T_Prot.(sprintf('Reform_%s_kNZD', code))              = [Lp.Net_Fiscal_Balance_kNZD(1); Lp.Net_Fiscal_Balance_kNZD(2)];
    T_Prot.(sprintf('Gain_Omega_%s_kNZD', code))          = [Omega_30; Omega_CR];
    T_Prot.(sprintf('DebtSinking_50Pct_%s_kNZD', code))   = [Lp.SinkingFund_50Pct_kNZD(1); Lp.SinkingFund_50Pct_kNZD(2)];
    T_Prot.(sprintf('ReinvestPool_50Pct_%s_kNZD', code))  = [Lp.ReinvestmentPool_50Pct_kNZD(1); Lp.ReinvestmentPool_50Pct_kNZD(2)];
    T_Prot.(sprintf('DebtIntSaved_2050_%s_kNZD', code))   = [Lp.Annual_DebtService_Saving_kNZD(1); Lp.Annual_DebtService_Saving_kNZD(2)];
    T_Prot.(sprintf('InfraYieldDiv_2050_%s_kNZD', code))  = [Lp.Public_Infra_Yield_Dividend_kNZD(1); Lp.Public_Infra_Yield_Dividend_kNZD(2)];
end

fprintf('\n=========================================================================================================\n');
fprintf('SECTION 5 PROTOCOL: MULTIPHASE 2050 SOVEREIGN DEBT-SINKING & REINVESTMENT LEDGER (%s)\n', Target_Region);
fprintf('=========================================================================================================\n');
disp(T_Prot);
for p = 2:N_p
    fprintf('  [%s] Cumulative 2050 Sovereign Debt Reduction (per 60k cohort): NZD $%.1fM | Reinvest Pool: NZD $%.1fM\n', ...
        Phase_Codes{p}, Phase_Ledgers{p}.Cum_2050_DebtReduction_MNZD, Phase_Ledgers{p}.Cum_2050_ReinvestPool_MNZD);
end
end

function T_Fiscal = Build_Custom_Table14_Fiscal_CSV(Phase_Ledgers, Phase_Codes)
%% BUILD_CUSTOM_TABLE14_FISCAL_CSV
% Builds the 28-Node, 6-Gate Monetary & 4-Lane Fiscal Decomposition Table (Option 2)
% making Marilyn Waring's Unpaid Whanau Time (Lane B) and AS Landlord Capture (Lane D) explicit.
N_p = numel(Phase_Ledgers);

Gate_Labels = { ...
    'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
    'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
    'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
    'Gate5_J10_Age30_Fiscal';        'Gate5_J10_Age30_Fiscal';        'Gate5_J10_Age30_Fiscal'; ...
    'Gate5_J10_Age30_Fiscal';        'Gate5_J10_Age30_Fiscal';        'Gate5_J10_Age30_Fiscal'; ...
    'Gate6_J11_16_CareerToRet';      'Gate6_J11_16_CareerToRet';      'Gate6_J11_16_CareerToRet'; ...
    'Gate6_J11_16_CareerToRet';      'Gate6_J11_16_CareerToRet';      'Gate6_J11_16_CareerToRet'};

Node_Names = { ...
    '1_Acute_Hardship_Tier3_Support';     '2_Residual_AHC_Paper_And_Whanau';    '3_Universal_Birth_Benefit';          '4_Private_Birth_OutOfPocket'; ...
    '5_ECE_Corner_Benefit_Need';          '6_Public_ECE_Wraparound';            '7_High_Intensity_Public_ECE';        '8_Private_Parental_ECE_CashTime'; ...
    '9_HH_Unemp_And_Truancy_Remed';       '10_Psychosocial_CAMHS_ACC_ISSC';     '11_Public_Secondary_Schooling';      '12_Montessori_Tuakana_Public';       '13_Private_Adol_Commit_CashTime'; ...
    '14_Struggling_Tier_h1_h2_Launch';    '15_Core_Skill_Tier_h3_h5_Launch';    '16_Thriving_Tier_h6_h7_Launch'; ...
    '17_Age30_Exits124_CareHospJust';     '18_Age30_Infra_Roads_BaseHealth';    '19_Age30_GST_Cap_Tax'; ...
    '20_Age30_PAYE_Income_Tax';           '21_Age30_Exit3_LowerSkill_LostTax';  '22_Age30_Emigrated_Abroad_LostTax'; ...
    '23_Career_Ongoing_Exits124';         '24_Career_NZSuper_Health_Infra';     '25_Career_GST_Cap_Estate_Tax'; ...
    '26_Career_PAYE_Income_Tax';          '27_Career_Exit3_LowerSkill_LostTax'; '28_Career_Perm_Abroad_LostTax'};

T_Fiscal = table(Gate_Labels, Node_Names, 'VariableNames', {'Gate', 'Node_Name'});
Flow_Mat = zeros(28, N_p);

for p = 1:N_p
    L = Phase_Ledgers{p};
    c = Phase_Codes{p};

    Pop_28 = 100 * [ ...
        L.Pop_S1_Birth(:); ...
        L.Pop_S2_ECE_4Node(:); ...
        L.Pop_S3_Adol_5Node(:); ...
        L.Pop_S4_Skill(:); ...
        ones(12, 1)];

    Flow_28 = [ ...
        L.S1_Birth_kNZD(:); ...
        L.S2_ECE_4Node_kNZD(:); ...
        L.S3_Adol_5Node_kNZD(:); ...
        L.S4_Skill_kNZD(:); ...
        L.S5_Age30_kNZD(:); ...
        L.S6_Career_kNZD(:)];

    Cond_28 = Flow_28 ./ max(0.01, Pop_28 / 100);
    Flow_Mat(:, p) = Flow_28;

    % Construct 4-Lane Decomposition (Lane A: Priv Cash, Lane B: Priv/Whanau Time, Lane C: Pub Dev, Lane D: Pub Remed / Landlord Capture)
    LaneA = zeros(28, 1); LaneB = zeros(28, 1); LaneC = zeros(28, 1); LaneD = zeros(28, 1);
    % Gate 1: Node 1 = Tier 3 Remed (Lane D); Node 2 = AS Landlord Capture (Lane D) + Waring Whanau Time (Lane B); Node 3 = Pub Dev (Lane C); Node 4 = Priv Cash (63%) + Time (37%)
    LaneD(1) = Flow_28(1);
    LaneD(2) = Flow_28(2);
    if isfield(L, 'Whanau_And_Landlord_G1_kNZD'), LaneB(2) = L.Whanau_And_Landlord_G1_kNZD(1); end
    LaneC(3) = Flow_28(3);
    LaneA(4) = 0.63 * Flow_28(4); LaneB(4) = 0.37 * Flow_28(4);
    % Gate 2: Node 5 = Remed (Lane D); Nodes 6,7 = Pub Dev (Lane C); Node 8 = Priv Cash (60%) + Whanau/Parental Time (40%)
    LaneD(5) = Flow_28(5); LaneC(6:7) = Flow_28(6:7);
    LaneA(8) = 0.60 * Flow_28(8); LaneB(8) = 0.40 * Flow_28(8);
    % Gate 3: Node 9 (HH Unemp) & Node 10 (Psychosocial CAMHS/ACC ISSC) = Remed (Lane D); Nodes 11,12 = Pub Dev (Lane C); Node 13 = Priv Cash (62%) + Time (38%)
    LaneD(9:10) = Flow_28(9:10); LaneC(11:12) = Flow_28(11:12);
    LaneA(13) = 0.62 * Flow_28(13); LaneB(13) = 0.38 * Flow_28(13);
    % Gate 4: Launch Skill Tiers (14..16)
    LaneD(14) = 0.82 * Flow_28(14); LaneC(14) = 0.18 * Flow_28(14);
    LaneA(15) = 0.29 * Flow_28(15); LaneB(15) = 0.12 * Flow_28(15); LaneC(15) = 0.53 * Flow_28(15); LaneD(15) = 0.06 * Flow_28(15);
    LaneA(16) = 0.37 * Flow_28(16); LaneB(16) = 0.13 * Flow_28(16); LaneC(16) = 0.50 * Flow_28(16);
    % Gates 5 & 6: Adult Fiscal Flows (17..28)
    LaneD([17, 21, 22, 23, 27, 28]) = Flow_28([17, 21, 22, 23, 27, 28]);
    LaneC([18, 19, 20, 24, 25, 26]) = Flow_28([18, 19, 20, 24, 25, 26]);

    T_Fiscal.(sprintf('%s_Pop_Pct', c))             = round(Pop_28, 2);
    T_Fiscal.(sprintf('%s_CohortFlow_kNZD', c))     = round(Flow_28, 2);
    T_Fiscal.(sprintf('%s_CondPerChild_kNZD', c))   = round(Cond_28, 2);
    T_Fiscal.(sprintf('%s_LaneA_PrivCash_kNZD', c)) = round(LaneA, 2);
    T_Fiscal.(sprintf('%s_LaneB_WhanauTime_kNZD', c)) = round(LaneB, 2);
    T_Fiscal.(sprintf('%s_LaneC_PubDev_kNZD', c))   = round(LaneC, 2);
    T_Fiscal.(sprintf('%s_LaneD_RemedRent_kNZD', c))= round(LaneD, 2);
end

if N_p == 2
    T_Fiscal.Reform_Delta_Flow_kNZD = round(Flow_Mat(:, 2) - Flow_Mat(:, 1), 2);
elseif N_p >= 3
    for p = 2:N_p
        d_col = sprintf('Delta_%s_vs_%s_kNZD', Phase_Codes{p}, Phase_Codes{p-1});
        T_Fiscal.(d_col) = round(Flow_Mat(:, p) - Flow_Mat(:, p-1), 2);
    end
    cum_col = sprintf('Cumul_%s_vs_%s_kNZD', Phase_Codes{N_p}, Phase_Codes{1});
    T_Fiscal.(cum_col) = round(Flow_Mat(:, N_p) - Flow_Mat(:, 1), 2);
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
        'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
        'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
        'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
        'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
        'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'; ...
        'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'};
    Names = { ...
        '1_Material_Hardship_Housing_Squeeze'; '2_Secure_Parental_Asset_Buffer'; ...
        '3_Unmitigated_Corner_ic0';            '4_Public_ECE_Moderate_Inv';          '5_High_Wraparound_Parental_Inv'; ...
        '6_Family_Unemp_Stress_z1';            '7_Standard_Public_Schooling';        '8_Montessori_Peer_Mentoring'; ...
        '9_Struggling_Tier_h1_h2';                '10_Core_Skill_Tier_h3_h5';           '11_Thriving_Tier_h6_h7'; ...
        '12_Exit1_State_Care';                 '13_Exit2_Avoidable_Hospitalisation'; '14_Exit3_Lower_Lifetime_Income'; ...
        '15_Exit4_Benefit_Justice_Burden';     '16_Retained_NZ_Secure_Thriving';     '17_Emigrated_Abroad_BrainDrain'};
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
