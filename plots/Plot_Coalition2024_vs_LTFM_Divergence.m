function Out = Plot_Coalition2024_vs_LTFM_Divergence(Params, BatchOut)
%% PLOT_COALITION2024_VS_LTFM_DIVERGENCE
% Cross-platform (MATLAB HG2 & GNU Octave Qt/FLTK) 4-Panel Divergence Dashboard
% powered by pure ledger Compute_Divergence_Trajectory_Ledger.m.

if nargin < 1 || isempty(Params)
    Params = Configure_Model_Params(struct('dt', 3));
elseif ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(Params);
end
if nargin < 2
    BatchOut = [];
end

D         = Compute_Divergence_Trajectory_Ledger(Params, BatchOut);
OutputDir = Resolve_IGW_OutputDir('', D.Profile_ID);

Col_LTFM   = [0.25, 0.38, 0.52];
Col_Ret    = [0.58, 0.08, 0.12];
Col_Comp   = [0.86, 0.24, 0.16];
Col_Reform = [0.08, 0.58, 0.44];
Col_Cash   = [0.85, 0.52, 0.12];
Col_CPI    = [0.18, 0.12, 0.42];

vis_m = IGW_UI_Style('headless_vis');
fig   = figure('Name', '4-Regime Policy Composition vs. LTFM & Sequenced Reform', ...
    'Color', 'w', 'Position', [25, 25, 1780, 1050], 'Visible', vis_m);

% --- PANEL A: Cash OBEGAL vs. ACC Actuarial Valuation (2% SRTP) ---
ax1 = subplot('Position', [0.055, 0.545, 0.410, 0.375]);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');

yline(ax1, 0, 'k-', 'LineWidth', 1.1, 'HandleVisibility', 'off');
xline(ax1, 2029, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');

fill(ax1, [D.Years_15; flipud(D.Years_15)], [D.Ret_Cash_OBEGAL_B; flipud(D.Comp_Actuarial_Val_B)], ...
    Col_Comp, 'FaceAlpha', 0.12, 'EdgeColor', 'none', 'DisplayName', 'Unbooked Actuarial Liability Wedge');

plot(ax1, D.Years_15, D.Ret_Cash_OBEGAL_B, '--o', 'Color', Col_Cash, 'LineWidth', 2.2, ...
    'MarkerSize', 4.5, 'MarkerFaceColor', Col_Cash, ...
    'DisplayName', '1. Retrenchment Only Cash OBEGAL (+$1.9B/yr Short-Term)');
plot(ax1, D.Years_15, D.Comp_Cash_OBEGAL_B, ':d', 'Color', [0.75, 0.38, 0.05], 'LineWidth', 2.2, ...
    'MarkerSize', 4.5, 'DisplayName', '2. Composed Bundle Cash OBEGAL (-$1.9B/yr Deficit)');
plot(ax1, D.Years_15, D.Ret_Actuarial_Val_B, '-v', 'Color', Col_Ret, 'LineWidth', 2.4, ...
    'MarkerSize', 5.0, 'MarkerFaceColor', Col_Ret, ...
    'DisplayName', '1. Retrenchment Only ACC Actuarial (-$12.4B at Yr 5)');
plot(ax1, D.Years_15, D.Comp_Actuarial_Val_B, '-s', 'Color', Col_Comp, 'LineWidth', 2.8, ...
    'MarkerSize', 5.5, 'MarkerFaceColor', Col_Comp, ...
    'DisplayName', '2. Composed Bundle ACC Actuarial (-$11.5B at Yr 5)');
plot(ax1, D.Years_15, D.Reform_Actuarial_Val_B, '-^', 'Color', Col_Reform, 'LineWidth', 2.8, ...
    'MarkerSize', 5.5, 'MarkerFaceColor', Col_Reform, ...
    'DisplayName', '3. Sequenced Two-Phase Reform (+$35.25B / 3.84x at Yr 5)');

text(ax1, 2029.2, -14.8, sprintf('Yr 5 Composed Bundle:\nCash: -$1.9B/yr | Actuarial: -$11.5B'), ...
    'Color', Col_Comp, 'FontSize', 8.3, 'FontWeight', 'bold');
text(ax1, 2029.2, 26.5, sprintf('Yr 5 Sequenced Reform:\n+$35.25B Net Asset (3.84x)'), ...
    'Color', Col_Reform, 'FontSize', 8.3, 'FontWeight', 'bold');

xlabel(ax1, 'Calendar Year (Wave 1 & Wave 2 Horizon)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax1, 'Cumulative Fiscal / Actuarial Impact (NZD Billions)', 'FontSize', 10, 'FontWeight', 'bold');
title(ax1, 'A. Short-Term Cash OBEGAL vs. 25-Yr ACC Actuarial Valuation (2% SRTP)', 'FontSize', 10.8, 'FontWeight', 'bold');
lgd1 = legend(ax1, 'Location', 'northwest', 'FontSize', 7.6);
IGW_UI_Style('legend_alpha', lgd1, 0.92);
xlim(ax1, [2024, 2039]); ylim(ax1, [-38, 50]);

% --- PANEL B: Solved Regional Emigration (Left) & Imputed Social Cohesion / TI CPI (Right) ---
ax2 = subplot('Position', [0.535, 0.545, 0.410, 0.375]);
yyaxis(ax2, 'left'); hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');

b_emig = bar(ax2, 1:5, D.Emig_Mat, 'grouped', 'BarWidth', 0.82);
emig_cols  = {Col_LTFM, Col_Ret, Col_Comp, Col_Reform};
emig_names = { ...
    sprintf('0. 2023 Base (Nat Emig %.1f%% | CPI 81.0)', D.Emig_Mat(5,1)), ...
    sprintf('1. Retrenchment 10 (Nat Emig %.1f%% | CPI 70.9)', D.Emig_Mat(5,2)), ...
    sprintf('2. Composed Bundle (Nat Emig %.1f%% | CPI 71.5)', D.Emig_Mat(5,3)), ...
    sprintf('3. Sequenced Reform (Nat Emig %.1f%% | CPI 92.0)', D.Emig_Mat(5,4))};
for k_b = 1:4
    set(b_emig(k_b), 'FaceColor', emig_cols{k_b}, 'DisplayName', emig_names{k_b});
end
ylabel(ax2, 'Solved Age 20-35 Cohort Emigrating Abroad (%)', 'FontSize', 10, 'FontWeight', 'bold');
ylim(ax2, [0, 44]);
set(vfi_active_ax(ax2), 'YColor', [0.15, 0.15, 0.15]);

yyaxis(ax2, 'right'); hold(ax2, 'on');
ylim(ax2, [64, 98]);
set(vfi_active_ax(ax2), 'YColor', Col_CPI);
yline(ax2, 89.0, ':', 'Color', Col_Reform, 'LineWidth', 1.4, 'HandleVisibility', 'off');
yline(ax2, 81.0, '--', 'Color', Col_LTFM,  'LineWidth', 1.2, 'HandleVisibility', 'off');

x_nat_bars = 5.0 + [-0.27, -0.09, 0.09, 0.27];
p_cpi_imp = plot(ax2, x_nat_bars, D.CPI_Impact_Regimes, '--d', 'Color', [0.45, 0.32, 0.72], ...
    'LineWidth', 2.0, 'MarkerSize', 7.5, 'MarkerFaceColor', [0.85, 0.80, 0.98], ...
    'DisplayName', 'Wave 1 Impact TI CPI (81.0 -> 75.1 / 75.7)');
p_cpi_ss  = plot(ax2, x_nat_bars, D.CPI_SS_Regimes, '-p', 'Color', Col_CPI, ...
    'LineWidth', 2.6, 'MarkerSize', 10.0, 'MarkerFaceColor', [0.98, 0.82, 0.18], ...
    'DisplayName', 'Steady-State TI CPI (70.9 / 71.5 -> 92.0)');
ylabel(ax2, 'Imputed TI Social Credit (CPI / 100) [Cohesion S_t]', 'FontSize', 9.8, 'FontWeight', 'bold');
yyaxis(ax2, 'left');

xlim(ax2, [0.45, 5.65]);
set(ax2, 'XTick', 1:5, 'XTickLabel', D.Reg_Labels, 'FontSize', 8.8, 'FontWeight', 'bold');
title(ax2, 'B. Solved Youth Emigration (Left) & Social Cohesion / TI CPI (Right)', 'FontSize', 10.8, 'FontWeight', 'bold');
lgd2 = legend(ax2, [b_emig(1), b_emig(2), b_emig(3), b_emig(4), p_cpi_imp, p_cpi_ss], 'Location', 'northwest', 'FontSize', 7.1);
IGW_UI_Style('legend_alpha', lgd2, 0.92);

% --- PANEL C: Productive Enterprise (z_h) vs. Passive Land Speculation (z_l) ---
ax3 = subplot('Position', [0.055, 0.085, 0.410, 0.375]);
hold(ax3, 'on'); grid(ax3, 'on'); box(ax3, 'on');

b_zh = bar(ax3, 1:5, D.Zh_Mat, 'grouped', 'BarWidth', 0.84);
zh_names = { ...
    sprintf('0. 2023 Baseline (TFP = %.2f%%/yr)', D.TFP_Growth_Ann(1)), ...
    sprintf('1. Retrenchment + Deductibility (TFP = %.2f%%/yr)', D.TFP_Growth_Ann(2)), ...
    sprintf('2. Composed Bundle (TFP = %.2f%%/yr)', D.TFP_Growth_Ann(3)), ...
    sprintf('3. Sequenced Reform \\tau_a = 1.5%% (TFP = %.2f%%/yr)', D.TFP_Growth_Ann(4))};
for k_b = 1:4
    set(b_zh(k_b), 'FaceColor', emig_cols{k_b}, 'DisplayName', zh_names{k_b});
end
set(ax3, 'XTick', 1:5, 'XTickLabel', {'Firm Rural', 'Firm Small', 'Firm Large', 'Firm Auckland', 'National Equity'}, ...
    'FontSize', 9.0, 'FontWeight', 'bold');
ylabel(ax3, 'Capital Share in High-Complexity Operating Firms z_h (%)', 'FontSize', 10, 'FontWeight', 'bold');
title(ax3, 'C. Productive Enterprise (z_h) vs. Passive Property Allocation (z_l)', 'FontSize', 10.8, 'FontWeight', 'bold');
lgd3 = legend(ax3, 'Location', 'northwest', 'FontSize', 7.6);
IGW_UI_Style('legend_alpha', lgd3, 0.92);
ylim(ax3, [0, 85]);

% --- PANEL D: 60-Year Sovereign Solvency (PAYE tau_l %) & Household Welfare (CE %) ---
ax4 = subplot('Position', [0.535, 0.085, 0.410, 0.375]);
yyaxis(ax4, 'left'); hold(ax4, 'on'); grid(ax4, 'on'); box(ax4, 'on');
ylim(ax4, [8.5, 34.5]);
set(vfi_active_ax(ax4), 'YDir', 'reverse', 'YColor', [0.22, 0.22, 0.22]);
ylabel(ax4, 'Required Solvency PAYE Tax Rate \tau_l (%) [Inverted: Down = Hike]', 'FontSize', 9.5, 'FontWeight', 'bold');

p_tax0 = plot(ax4, D.Years_60, D.PAYE_LTFM_Path,   '--o', 'Color', Col_LTFM,   'LineWidth', 1.7, 'MarkerSize', 3.8, 'DisplayName', sprintf('0. LTFM PAYE (%.2f%%)', D.PAYE_LTFM_Path(end)));
p_tax1 = plot(ax4, D.Years_60, D.PAYE_Ret_Path,    '--v', 'Color', Col_Ret,    'LineWidth', 1.7, 'MarkerSize', 4.0, 'DisplayName', sprintf('1. Retrenchment PAYE (%.2f%%)', D.PAYE_Ret_Path(end)));
p_tax2 = plot(ax4, D.Years_60, D.PAYE_Comp_Path,   '--s', 'Color', Col_Comp,   'LineWidth', 1.9, 'MarkerSize', 4.2, 'DisplayName', sprintf('2. Composed PAYE (%.2f%%)', D.PAYE_Comp_Path(end)));
p_tax3 = plot(ax4, D.Years_60, D.PAYE_Reform_Path, '--^', 'Color', Col_Reform, 'LineWidth', 1.9, 'MarkerSize', 4.2, 'DisplayName', sprintf('3. Reform PAYE (%.2f%%)', D.PAYE_Reform_Path(end)));

yyaxis(ax4, 'right'); hold(ax4, 'on');
ylim(ax4, [-62, 56]);
set(vfi_active_ax(ax4), 'YColor', [0.10, 0.10, 0.10]);
ylabel(ax4, 'Cohort Consumption-Equivalent Welfare (CE %)', 'FontSize', 9.8, 'FontWeight', 'bold');
yline(ax4, 0, 'k:', 'LineWidth', 1.1, 'HandleVisibility', 'off');

p_ce0 = plot(ax4, D.Years_60, D.CE_LTFM_Path,   '-o', 'Color', Col_LTFM,   'LineWidth', 2.4, 'MarkerSize', 4.6, 'MarkerFaceColor', 'w',        'DisplayName', sprintf('0. LTFM Welfare (%+.2f%% CE)', D.CE_LTFM_Path(end)));
p_ce1 = plot(ax4, D.Years_60, D.CE_Ret_Path,    '-v', 'Color', Col_Ret,    'LineWidth', 2.5, 'MarkerSize', 5.0, 'MarkerFaceColor', Col_Ret,    'DisplayName', sprintf('1. Retrenchment (%+.2f%% CE)', D.CE_Ret_Path(end)));
p_ce2 = plot(ax4, D.Years_60, D.CE_Comp_Path,   '-s', 'Color', Col_Comp,   'LineWidth', 2.8, 'MarkerSize', 5.4, 'MarkerFaceColor', Col_Comp,   'DisplayName', sprintf('2. Composed Bundle (%+.2f%% CE)', D.CE_Comp_Path(end)));
p_ce3 = plot(ax4, D.Years_60, D.CE_Reform_Path, '-^', 'Color', Col_Reform, 'LineWidth', 2.8, 'MarkerSize', 5.4, 'MarkerFaceColor', Col_Reform, 'DisplayName', sprintf('3. Sequenced Reform (%+.2f%% CE)', D.CE_Reform_Path(end)));
yyaxis(ax4, 'left');

xlim(ax4, [2024, 2084]);
set(ax4, 'XTick', 2024:10:2084, 'FontSize', 9.0, 'FontWeight', 'bold');
xlabel(ax4, 'Transition Year (2024-2084, \Delta t = 3 Grid)', 'FontSize', 10, 'FontWeight', 'bold');
gap_pp = D.CE_Reform_Path(end) - D.CE_Comp_Path(end);
title(ax4, sprintf('D. 60-Year Solvency & Welfare: %.2f pp Gap (Composed Bundle vs. Reform)', gap_pp), 'FontSize', 10.8, 'FontWeight', 'bold');
lgd4 = legend(ax4, [p_ce3, p_tax3, p_ce0, p_tax0, p_ce2, p_tax2, p_ce1, p_tax1], 'Location', 'northwest', 'NumColumns', 2, 'FontSize', 6.8);
IGW_UI_Style('legend_alpha', lgd4, 0.92);

Out_PNG = fullfile(OutputDir, 'Fig_Coalition2024_vs_LTFM_4Panel_Divergence.png');
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
Out_CSV = fullfile(OutputDir, 'Table_Coalition2024_vs_LTFM_Divergence.csv');
writetable(D.Table_Divergence, Out_CSV);
fprintf('  -> Saved 4-Panel Policy Divergence Figure & CSV to: %s\n', OutputDir);

Out = struct('Ledger', D, 'Fig_Path', Out_PNG, 'CSV_Path', Out_CSV);
end
