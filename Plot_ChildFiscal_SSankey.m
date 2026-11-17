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

%% 0. OPTIONAL DEPENDENCY CHECK (MATLAB FILE EXCHANGE 'SSankey')
if exist('SSankey', 'file') == 0 && exist('SSankey', 'class') == 0
    if exist('IGW_Log', 'file') ~= 0
        IGW_Log('IGW:MissingSSankey', 'Plot_ChildFiscal_SSankey.m: SSankey library not found in environment; skipping Sankey figure rendering.');
    else
        warning('IGW:MissingSSankey', 'Plot_ChildFiscal_SSankey.m: SSankey library not found in environment; skipping Sankey figure rendering.');
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
NZD_Base_Scale     = 95.0;         % 1.0 model unit = $95.0 kNZD/yr (mean prime household earnings)
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
            attachSankeyHoverNarratives(axP, SK_p, links_p, fiscalNarrativeMap, '%.2f kNZD/yr per cohort birth');
            html_fname = fullfile(OutputDir, sprintf('Interactive_ChildFiscal_%s_%s.html', p_code, Target_Region));
            exportSankeyToHTML(axP, SK_p, links_p, fiscalNarrativeMap, '%.2f kNZD/yr per cohort birth', html_fname);
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
