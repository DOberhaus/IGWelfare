function Out = Plot_Contingency_And_Assembly_Dashboard(Params)
%% PLOT_CONTINGENCY_AND_ASSEMBLY_DASHBOARD (DOCUMENT 1F CLEARINGHOUSE & 5-RISK STRESS TEST)
% Cross-platform (MATLAB HG2 & GNU Octave) 4-Panel Dashboard rendering:
%   Panel A: Joint Plenary Clearinghouse Audit (15 Ranged Contracts x 4 Governance Regimes)
%   Panel B: State-Contingent Two-Key SS2 Unlock Year vs. Rigid Year-25 Calendar
%   Panel C: 60-Year Sovereign Debt Shield Under Polycrisis & Stock-Formation Lag
%   Panel D: Year-60 Household Welfare (CE%) & Contingent Resilience Dividend (+pp CE)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end

OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag = Params.Calibration_Anchor;

L7 = Compute_Assembly_Clearinghouse_Ledger(Params);
CT = L7.Compact.Contract_Table;
ST = L7.StressTestTable;

vis_m = IGW_UI_Style('headless_vis');
fig   = figure('Name', sprintf('Document 1F: Five-Assembly Clearinghouse & 5-Risk Contingency Stress-Test (%s)', AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 1780, 1040], 'Visible', vis_m);

% --- PANEL A: 15x4 Clearinghouse Contract Satisfaction Matrix ---
ax1 = subplot('Position', [0.075, 0.545, 0.390, 0.375]);
hold(ax1, 'on'); box(ax1, 'on');

% Encode pass=1 (emerald) vs breach=0 (crimson) on [15 x 4] grid:
Z_mat = double(L7.Pass_Mat_15x4);
imagesc(ax1, 1:4, 1:15, Z_mat);
colormap(ax1, [0.82, 0.16, 0.20; 0.08, 0.62, 0.40]);
caxis(ax1, [0, 1]);
set(ax1, 'YDir', 'reverse');

% Vectorized cell annotations ('OK' vs 'BREACH'):
[C_grid, R_grid] = meshgrid(1:4, 1:15);
lbl_cells = arrayfun(@(p) ifelse_str(p > 0.5, 'PASS', 'VOID'), Z_mat(:), 'UniformOutput', false);
text(ax1, C_grid(:), R_grid(:), lbl_cells, 'HorizontalAlignment', 'center', ...
    'FontSize', 7.2, 'FontWeight', 'bold', 'Color', 'w');

short_k = cellfun(@(s) regexprep(s, '_.*', ''), CT.Contract_ID, 'UniformOutput', false);
set(ax1, 'XTick', 1:4, 'XTickLabel', {'1. Unified (15/15)', '2. Day-1 Grant', '3. Cherry-Pick', '4. Split 50%'}, ...
    'FontSize', 8.3, 'FontWeight', 'bold');
set(ax1, 'YTick', 1:15, 'YTickLabel', short_k, 'FontSize', 7.6, 'FontWeight', 'bold');
xlim(ax1, [0.5, 4.5]); ylim(ax1, [0.5, 15.5]);
title(ax1, 'A. Economic Clearinghouse: 15 Assembly Contracts Across 4 Regimes', 'FontSize', 10.5, 'FontWeight', 'bold');

% --- PANEL B: State-Contingent Two-Key SS2 Unlock Year Across All 7 Scenarios ---
ax2 = subplot('Position', [0.535, 0.545, 0.410, 0.375]);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');

nS = height(ST);
bB = barh(ax2, 1:nS, [ST.SS2_Yr_Fixed, ST.SS2_Yr_Cont], 'grouped', 'BarWidth', 0.82);
set(bB(1), 'FaceColor', [0.52, 0.56, 0.62], 'DisplayName', 'Rigid Calendar Rule (Blind Yr 25 PAYE Cut)');
set(bB(2), 'FaceColor', [0.12, 0.44, 0.74], 'DisplayName', 'Two-Key Contingent Rule (Early Reward / Shock Deferral)');
xline(ax2, 25, 'r--', 'LineWidth', 1.6, 'HandleVisibility', 'off');
set(ax2, 'YDir', 'reverse', 'YTick', 1:nS, ...
    'YTickLabel', {'S0 Baseline', 'S1 Skill Lag', 'S2 S4A Staff', 'S3 Exergy Spike', 'S4 Trade/CBAM', 'S5 Bond +180bp', 'S6 Polycrisis'}, ...
    'FontSize', 8.5, 'FontWeight', 'bold');
xlabel(ax2, 'Phase-2 (SS2) Dividend Harvest Unlock Year (Years Post-Launch)', 'FontSize', 9.8, 'FontWeight', 'bold');
xlim(ax2, [0, 42]);
title(ax2, 'B. Dynamic Two-Key Pacing: Unlocks Early On-Track, Defers Under Shock', 'FontSize', 10.5, 'FontWeight', 'bold');
lgd2 = legend(ax2, 'Location', 'southeast', 'FontSize', 7.6);
IGW_UI_Style('legend_alpha', lgd2, 0.92);

% --- PANEL C: 60-Year Sovereign Debt Shield (Rigid Calendar vs. Two-Key Stabilizers) ---
ax3 = subplot('Position', [0.055, 0.085, 0.410, 0.375]);
hold(ax3, 'on'); grid(ax3, 'on'); box(ax3, 'on');

P_S0 = L7.Paths.S0_Baseline_OnTrack;
P_S1 = L7.Paths.S1_Stock_Formation_Lag;
P_S6 = L7.Paths.S6_Compound_Polycrisis;
yrs  = P_S0.Years;

plot(ax3, yrs, P_S6.Macro_Fixed.Debt_PctGDP_t, '--', 'Color', [0.80 0.14 0.18], 'LineWidth', 2.4, ...
    'DisplayName', 'S6 Polycrisis: Rigid Calendar (Premature Yr-25 Tax Cut)');
plot(ax3, yrs, P_S6.Macro_Cont.Debt_PctGDP_t,  '-',  'Color', [0.80 0.14 0.18], 'LineWidth', 2.8, ...
    'DisplayName', 'S6 Polycrisis: Two-Key + 70/30 Debt-Sinking Stabilizer');
plot(ax3, yrs, P_S1.Macro_Fixed.Debt_PctGDP_t, '--', 'Color', [0.85 0.48 0.10], 'LineWidth', 2.0, ...
    'DisplayName', 'S1 Stock Lag: Rigid Calendar');
plot(ax3, yrs, P_S1.Macro_Cont.Debt_PctGDP_t,  '-',  'Color', [0.85 0.48 0.10], 'LineWidth', 2.4, ...
    'DisplayName', 'S1 Stock Lag: Two-Key Contingent');
plot(ax3, yrs, P_S0.Macro_Cont.Debt_PctGDP_t,  '-',  'Color', [0.06 0.56 0.38], 'LineWidth', 2.5, ...
    'DisplayName', sprintf('S0 Baseline On-Track (Unlocks SS2 at Yr %d -> 22%% Debt)', P_S0.Gate_Cont.SS2_Unlock_Year));

xlim(ax3, [0, 60]); ylim(ax3, [18, 68]);
xlabel(ax3, 'Years Relative to 2026 Compact Launch', 'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax3, 'Net Core Crown Debt (% of SNA GDP)', 'FontSize', 10, 'FontWeight', 'bold');
title(ax3, 'C. Sovereign Debt Shield: Preventing Unfunded Tax Cuts Under Shocks', 'FontSize', 10.5, 'FontWeight', 'bold');
lgd3 = legend(ax3, 'Location', 'northeast', 'FontSize', 7.3);
IGW_UI_Style('legend_alpha', lgd3, 0.92);

% --- PANEL D: Year-60 Welfare (CE%) & Contingent Resilience Dividend ---
ax4 = subplot('Position', [0.535, 0.085, 0.410, 0.375]);
hold(ax4, 'on'); grid(ax4, 'on'); box(ax4, 'on');

bD = bar(ax4, 1:nS, [ST.Welfare_Fixed_CE_Pct, ST.Welfare_Cont_CE_Pct], 'grouped', 'BarWidth', 0.82);
set(bD(1), 'FaceColor', [0.76, 0.28, 0.24], 'DisplayName', 'Rigid Calendar Rule (Unhedged)');
set(bD(2), 'FaceColor', [0.06, 0.58, 0.38], 'DisplayName', 'Two-Key Contingent Compact (+Stabilizers)');

% Vectorized resilience gain callouts above each pair:
gain_vec = ST.Contingent_Resilience_Gain_pp;
y_top_d  = max(ST.Welfare_Fixed_CE_Pct, ST.Welfare_Cont_CE_Pct) + 1.1;
gain_lbl = arrayfun(@(g) sprintf('%+.1f pp', g), gain_vec, 'UniformOutput', false);
text(ax4, (1:nS)', y_top_d, gain_lbl, 'HorizontalAlignment', 'center', ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.04, 0.42, 0.26]);

set(ax4, 'XTick', 1:nS, 'XTickLabel', {'S0 Base', 'S1 hc Lag', 'S2 S4A Staff', 'S3 Exergy', 'S4 Trade', 'S5 Credit', 'S6 Polycrisis'}, ...
    'FontSize', 8.3, 'FontWeight', 'bold');
ylabel(ax4, 'Realized Year-60 Household Welfare (CE %)', 'FontSize', 10, 'FontWeight', 'bold');
ylim(ax4, [0, 34]);
title(ax4, 'D. State-Contingent Resilience Dividend (+pp CE Over Rigid Calendar)', 'FontSize', 10.5, 'FontWeight', 'bold');
lgd4 = legend(ax4, 'Location', 'northeast', 'FontSize', 7.8);
IGW_UI_Style('legend_alpha', lgd4, 0.92);

Out_PNG = fullfile(OutputDir, sprintf('Fig_Doc1F_Contingency_And_Clearinghouse_%s.png', AnchorTag));
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Document 1F Contingency & Clearinghouse Dashboard to: %s\n', Out_PNG);

Out = struct('Ledger', L7, 'Fig_Path', Out_PNG);
end

function s = ifelse_str(cond, s_true, s_false)
if cond, s = s_true; else, s = s_false; end
end
