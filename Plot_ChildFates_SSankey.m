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

%% 0. OPTIONAL DEPENDENCY CHECK (MATLAB FILE EXCHANGE 'SSankey')
if exist('SSankey', 'file') == 0 && exist('SSankey', 'class') == 0
    if exist('IGW_Log', 'file') ~= 0
        IGW_Log('IGW:MissingSSankey', 'Plot_ChildFates_SSankey.m: SSankey library not found in environment; skipping Sankey figure rendering.');
    else
        warning('IGW:MissingSSankey', 'Plot_ChildFates_SSankey.m: SSankey library not found in environment; skipping Sankey figure rendering.');
    end
    return;
end

%% 1. CONFIGURATION SWITCHES (N-PHASE COMPATIBLE: 1, 2, 3, OR MORE PANELS)
if ~exist('Target_Regions', 'var') || isempty(Target_Regions)
    Target_Regions     = {'National', 'Auckland', 'Large', 'Small', 'Rural', 'Urban'};
else
    if ischar(Target_Regions) || isstring(Target_Regions), Target_Regions = cellstr(Target_Regions); end
end
% Specify any 1, 2, 3, or N phases: e.g. {'SS0'}, {'SS0','SS1'}, or {'SS0','SS1','SS2'}
if ~exist('Active_Phases', 'var') || isempty(Active_Phases)
    Active_Phases = {'SS0', 'SS1', 'SS2'};
else
    if ischar(Active_Phases) || isstring(Active_Phases), Active_Phases = cellstr(Active_Phases); end
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
