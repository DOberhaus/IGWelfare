function Out = Plot_Phase2_5Sector_Dashboard(Params)
%% PLOT_PHASE2_5SECTOR_DASHBOARD (DOCUMENT 4 PHASE II MULTISECTOR, EXERGY, WARING & ASSET SUITE)
% Cross-platform (MATLAB HG2 & GNU Octave) 4-Panel Dashboard rendering:
%   Panel A: 5-Sector Workforce Reallocation & Internal Sector 4A Reactive -> Capacitating Release
%   Panel B: Keen-Labrousse Fossil Import Compression Absorbing +3% GDP Defence & Stabilizing NFA/Y
%   Panel C: Three-Tier Scorecard (Conventional SNA GDP vs. Atkinson-Waring Output w/ 79k Volunteer FTEs)
%   Panel D: Public-Asset Stewardship (Fire-Sale Cash Mirage vs. 35-Yr Societal PV & Buyback Cliff)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end

OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag = Params.Calibration_Anchor;

L_3T  = Compute_ThreeTier_NationalAccounts_Ledger(Params);
L_AS  = Compute_Public_Asset_Stewardship_Ledger(Params);
L_NDC = Compute_NDC_Compliance_Ledger(Params);

Eq_SS0 = L_3T.Trajectories.SS0_LTFM;
Eq_Ref = L_3T.Trajectories.Phase2_Reform;
Eq_Def = L_3T.Trajectories.Phase2_Defence_3Pct;

vis_m = IGW_UI_Style('headless_vis');
fig   = figure('Name', sprintf('Document 4 Phase II: 5-Sector SOE, Exergy, Waring & Asset Stewardship (%s)', AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 1780, 1040], 'Visible', vis_m);

% --- PANEL A: 5-Sector Paid Workforce & Internal Sector 4A Reactive Release ---
ax1 = subplot('Position', [0.055, 0.545, 0.410, 0.375]);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');

idx_50  = find(Eq_Ref.Years == 2050, 1);
L_2026  = Eq_Ref.Paid_kFTE_Tx6(1, :);
L_SS050 = Eq_SS0.Paid_kFTE_Tx6(idx_50, :);
L_Ref50 = Eq_Ref.Paid_kFTE_Tx6(idx_50, :);
L_Def50 = Eq_Def.Paid_kFTE_Tx6(idx_50, :);

bA = bar(ax1, 1:6, [L_2026(:), L_SS050(:), L_Ref50(:), L_Def50(:)], 'grouped', 'BarWidth', 0.84);
cols_A  = {[0.35 0.45 0.58], [0.72 0.16 0.18], [0.06 0.56 0.40], [0.18 0.36 0.72]};
names_A = {'2026 Base (2,352k FTE)', '2050 SS0 Drift', '2050 Phase II Reform', '2050 Reform + 3% Defence'};
for k = 1:4
    set(bA(k), 'FaceColor', cols_A{k}, 'DisplayName', names_A{k});
end
set(ax1, 'XTick', 1:6, 'XTickLabel', {'S1 Primary', 'S2 Knowl z_h', 'S3 Market NT', 'S4A Civic/Care', 'S4B Pipes/Rds', 'S5 Defence'}, ...
    'FontSize', 8.5, 'FontWeight', 'bold');
ylabel(ax1, 'Paid Employment (Thousand FTEs)', 'FontSize', 10, 'FontWeight', 'bold');
title(ax1, sprintf('A. 5-Sector Workforce & Internal S4A Release (+%.0fk Reactive FTE Freed!)', Eq_Ref.L_S4A_Released_kFTE(idx_50)), ...
    'FontSize', 10.6, 'FontWeight', 'bold');
lgd1 = legend(ax1, 'Location', 'northeast', 'FontSize', 7.6);
IGW_UI_Style('legend_alpha', lgd1, 0.92);

% --- PANEL B: Exergy Fossil Import Savings Absorbing 3% GDP Defence & Stabilizing NFA/Y ---
ax2 = subplot('Position', [0.535, 0.545, 0.410, 0.375]);
yyaxis(ax2, 'left'); hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');

p_f0 = plot(ax2, Eq_SS0.Years, Eq_SS0.Fossil_Import_BNZD_t, '--', 'Color', [0.72 0.16 0.18], 'LineWidth', 2.2, ...
    'DisplayName', 'SS0 Fossil Fuel Imports (~NZD 20B/yr Drain)');
p_fR = plot(ax2, Eq_Ref.Years, Eq_Ref.Fossil_Import_BNZD_t, '-', 'Color', [0.06 0.56 0.40], 'LineWidth', 2.6, ...
    'DisplayName', 'Phase II Electrified Fossil Imports (e_N=0.88 vs e_F=0.30)');
p_dM = plot(ax2, Eq_Def.Years, Eq_Def.Def_Imports_BNZD_t, '-.', 'Color', [0.18 0.36 0.72], 'LineWidth', 2.2, ...
    'DisplayName', 'Sector 5 Defence FX Imports at 3.0% GDP (62% FX Share)');
ylabel(ax2, 'Annual FX Import Outflow (Real 2026 NZD B/yr)', 'FontSize', 9.8, 'FontWeight', 'bold');
ylim(ax2, [0, 26]);
set(vfi_active_ax(ax2), 'YColor', [0.15 0.15 0.15]);

yyaxis(ax2, 'right'); hold(ax2, 'on');
p_nfa0 = plot(ax2, Eq_SS0.Years, 100*Eq_SS0.NFA_to_GDP_t, ':', 'Color', [0.55 0.10 0.12], 'LineWidth', 2.1, ...
    'DisplayName', 'SS0 Net Foreign Assets (% of SNA GDP)');
p_nfaD = plot(ax2, Eq_Def.Years, 100*Eq_Def.NFA_to_GDP_t, '-', 'Color', [0.42 0.14 0.62], 'LineWidth', 2.5, ...
    'DisplayName', 'Reform + 3% GDP Defence NFA (% of SNA GDP)');
ylabel(ax2, 'Net Foreign Asset Position NFA_t / Y_t (%)', 'FontSize', 9.8, 'FontWeight', 'bold');
ylim(ax2, [-110, 25]);
set(vfi_active_ax(ax2), 'YColor', [0.42 0.14 0.62]);
yyaxis(ax2, 'left');

xlim(ax2, [2026, 2086]);
xlabel(ax2, 'Transition Year (2026-2086)', 'FontSize', 10, 'FontWeight', 'bold');
title(ax2, 'B. Keen-Labrousse Exergy Dividend Frees FX to Sustain 3% GDP Defence', 'FontSize', 10.6, 'FontWeight', 'bold');
lgd2 = legend(ax2, [p_f0, p_fR, p_dM, p_nfa0, p_nfaD], 'Location', 'southwest', 'FontSize', 7.2);
IGW_UI_Style('legend_alpha', lgd2, 0.92);

% --- PANEL C: Three-Tier National Accounts (SNA GDP vs. Atkinson-Waring Inclusive Output) ---
ax3 = subplot('Position', [0.055, 0.085, 0.410, 0.375]);
hold(ax3, 'on'); grid(ax3, 'on'); box(ax3, 'on');

ST3 = L_3T.SummaryTable;
bC  = bar(ax3, 1:height(ST3), [ST3.Y_SNA_2050_BNZD, ST3.Y_AtkinsonWaring_2050_BNZD], 'grouped', 'BarWidth', 0.80);
set(bC(1), 'FaceColor', [0.30 0.44 0.62], 'DisplayName', 'Tier 1: Conventional SNA GDP (Paid Inputs Only)');
set(bC(2), 'FaceColor', [0.05 0.58 0.38], 'DisplayName', 'Tier 2: Atkinson-Waring Inclusive Output (+Care/Vol - Y_{rem})');
set(ax3, 'XTick', 1:height(ST3), 'XTickLabel', {'SS0 LTFM', 'Dom 15 Cuts', 'SS0+3% Def', 'Phase II SS2', 'SS2+Doc 1E', 'SS2+3% Def'}, ...
    'FontSize', 8.4, 'FontWeight', 'bold');
ylabel(ax3, '2050 Real Annual Output (2026 NZD Billions/yr)', 'FontSize', 10, 'FontWeight', 'bold');
title(ax3, 'C. Three-Tier Scorecard: SNA GDP vs. Atkinson-Waring Satellite Account', 'FontSize', 10.6, 'FontWeight', 'bold');
lgd3 = legend(ax3, 'Location', 'northwest', 'FontSize', 7.8);
IGW_UI_Style('legend_alpha', lgd3, 0.92);

% --- PANEL D: Public-Asset Privatization Mirage vs. Stewardship Governance Turnaround ---
ax4 = subplot('Position', [0.535, 0.085, 0.410, 0.375]);
hold(ax4, 'on'); grid(ax4, 'on'); box(ax4, 'on');

yline(ax4, 0, 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
yr_as = L_AS.Years;
Cum4  = L_AS.Cum_Societal_BNZD_Tx4;

plot(ax4, yr_as, Cum4(:, 1), '--', 'Color', [0.55 0.35 0.15], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('1. Mismanaged + Deferred Maint (2%% PV: %+.1fB)', L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(1)));
plot(ax4, yr_as, Cum4(:, 2), '-v', 'Color', [0.78 0.12 0.16], 'LineWidth', 2.5, 'MarkerIndices', 1:5:numel(yr_as), ...
    'DisplayName', sprintf('2. Fire-Sale Privatization (+$%.1fB Cash -> 2%% PV: %+.1fB!)', ...
    L_AS.SummaryTable.Crown_Cash_Yr0to3_BNZD(2), L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(2)));
plot(ax4, yr_as, Cum4(:, 3), '-.', 'Color', [0.22 0.48 0.72], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('3. Ring-Fenced Maint Only (2%% PV: %+.1fB)', L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(3)));
plot(ax4, yr_as, Cum4(:, 4), '-^', 'Color', [0.04 0.56 0.36], 'LineWidth', 2.8, 'MarkerIndices', 1:5:numel(yr_as), ...
    'DisplayName', sprintf('4. Public Stewardship Turnaround (2%% PV: %+.1fB)', L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(4)));

text(ax4, 2038, -28, sprintf('Irreversible Privatization Opportunity Loss:\n-NZD %.1fB (2%% SRTP) | Yr-10 Buyback: NZD %.1fB', ...
    L_AS.Opportunity_Loss_2pct_B, L_AS.Buyback_Cost_Yr10_BNZD), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.65 0.05 0.10], ...
    'BackgroundColor', [1.0 0.96 0.96], 'EdgeColor', [0.78 0.12 0.16], 'Margin', 3);

xlim(ax4, [2026, 2061]);
xlabel(ax4, 'Horizon Year (NZD 50B Network/Grid Asset Block)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax4, 'Cumulative Net Societal Value (NZD Billions)', 'FontSize', 10, 'FontWeight', 'bold');
title(ax4, 'D. Public Assets on the Block: Privatization Mirage vs. Governance Reform', 'FontSize', 10.6, 'FontWeight', 'bold');
lgd4 = legend(ax4, 'Location', 'northwest', 'FontSize', 7.3);
IGW_UI_Style('legend_alpha', lgd4, 0.92);

Out_PNG = fullfile(OutputDir, sprintf('Fig_Phase2_5Sector_Exergy_Waring_Dashboard_%s.png', AnchorTag));
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Phase II 5-Sector, Exergy, Waring & Asset Dashboard to: %s\n', Out_PNG);

Out = struct('ThreeTier', L_3T, 'AssetStewardship', L_AS, 'NDC', L_NDC, 'Fig_Path', Out_PNG);
end
