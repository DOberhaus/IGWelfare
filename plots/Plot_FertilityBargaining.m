function figFert = Plot_FertilityBargaining(FertOut, Params, Opts)
%% RENDER 4-REGION FERTILITY BARGAINING, WHANAU NETWORKS & NZ SUPER U-CURVE (2x2 FIGURE + CSVs)
% File: plots/Plot_FertilityBargaining.m
% Pure presentation/export driver consuming the FertOut struct returned by
% Compute_FiscalSolvency_And_Fertility.m without mutating model state.
% Outputs (when Opts.Export_Tables_Figures == true):
%   - FigFert_4Region_Bargaining_Solvency.png (2x2 figure with continuous Age 60-75 U-Curve in Panel D)
%   - Table7_4Region_Fertility_Bargaining_TFR.csv
%   - Table8_4Region_Fertility_Struggling_NZSuperTax.csv
%   - Table8B_SuperAge_UCurve_60to75.csv

if nargin < 3 || isempty(Opts)
    Opts = struct();
end

Regions              = FertOut.Regions;
super_age_ss2_target = FertOut.super_age_ss2_target;
TFR_mat              = FertOut.TFR_mat;
DiffFert_mat         = FertOut.DiffFert_mat;
Struggling_mat       = FertOut.Struggling_mat;
SuperAge_Grid        = FertOut.SuperAge_Grid;
Tax_UCurve_SS0       = FertOut.Tax_UCurve_SS0;
Tax_UCurve_SS2       = FertOut.Tax_UCurve_SS2;
CE_UCurve_SS2        = FertOut.CE_UCurve_SS2;

% Log typed-anchor notice if plotting an unanchored U-curve (e.g. standalone run prior to Step 6)
log_unanchored = ~isfield(Opts, 'LogTypedAnchorWarning') || logical(Opts.LogTypedAnchorWarning);
if log_unanchored && isfield(FertOut, 'ce_anchor_fallback') && ~isempty(FertOut.ce_anchor_fallback)
    IGW_Log('IGW:TypedAnchor', 'Super-age U-curve anchored to typed ce_anchor_64 = %.6f (%s)', ...
        FertOut.ce_anchor_64, FertOut.ce_anchor_fallback);
end

figFert = figure('Name', '4-Region Fertility Bargaining, Whanau Networks & NZ Super U-Curve', ...
    'Color', 'w', 'Position', [60, 35, 1520, 940]);
tiledlayout(2, 2, 'TileSpacing', 'loose', 'Padding', 'loose');

scen_labels = {'1. Baseline (65)', '2. Hyperbolic', '3. ECE Relief', '4. SS1 Pkg (65)', ...
    '5. Austerity (70)', sprintf('6. SS2 (Age %.0f)', super_age_ss2_target)};
scen_cats   = categorical(scen_labels, scen_labels);

% --- PANEL A: 4-REGION TOTAL FERTILITY RATE ---
ax1 = nexttile; hold(ax1, 'on');
bar(ax1, scen_cats, TFR_mat, 'grouped');
yline(ax1, 2.10, 'k--', 'LineWidth', 1.3, 'HandleVisibility', 'off');
% Place Replacement (2.1) callout cleanly above the low Group 2 (Hyperbolic) bars:
text(ax1, scen_cats(2), 2.18, 'Replacement TFR (2.10)', 'HorizontalAlignment', 'center', ...
    'FontSize', 8.2, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', [0.3 0.3 0.3], 'Margin', 1.5);
ylim(ax1, [0, 2.85]);
xtickangle(ax1, 20);
ylabel(ax1, 'Total Fertility Rate (TFR)', 'FontWeight', 'bold');
if super_age_ss2_target < 65
    title(ax1, sprintf('A. 4-Region Total Fertility Rate (TFR: SS2 Age %.0f Reaches Replacement)', super_age_ss2_target), 'FontWeight', 'bold');
else
    title(ax1, 'A. 4-Region Total Fertility Rate (TFR)', 'FontWeight', 'bold');
end
legend(ax1, Regions, 'Location', 'northwest', 'Orientation', 'horizontal', 'FontSize', 8.5);
grid(ax1, 'on'); box(ax1, 'on');

% --- PANEL B: METROPOLITAN DIFFERENTIAL FERTILITY GAP ---
ax2 = nexttile;
metro_idx = unique([Params.Representative_Urban_Idx, Params.Primate_Region_Idx], 'stable');
bar(ax2, scen_cats, DiffFert_mat(:, metro_idx), 'grouped');
ylim(ax2, [0, max(0.46, max(DiffFert_mat(:)) * 1.32)]);
xtickangle(ax2, 20);
ylabel(ax2, 'Low-Skill minus High-Skill Births', 'FontWeight', 'bold');
title(ax2, sprintf('B. Metropolitan Differential Fertility Gap (%s)', strjoin(Regions(metro_idx), ' vs ')), 'FontWeight', 'bold');
legend(ax2, Regions(metro_idx), 'Location', 'northeast', 'FontSize', 8.5);
grid(ax2, 'on'); box(ax2, 'on');

% --- PANEL C: 4-REGION LOW-SKILL COHORT HARDSHIP SHARE ---
ax3 = nexttile;
bar(ax3, scen_cats, Struggling_mat, 'grouped');
ylim(ax3, [0, max(30, max(Struggling_mat(:)) * 1.25)]);
xtickangle(ax3, 20);
ylabel(ax3, 'Struggling Launch Share (%)', 'FontWeight', 'bold');
title(ax3, sprintf('C. 4-Region Struggling Launch Cohort Share (Age 70 Spike vs Age %.0f Compression)', super_age_ss2_target), 'FontWeight', 'bold');
legend(ax3, Regions, 'Location', 'northeast', 'FontSize', 8.5);
grid(ax3, 'on'); box(ax3, 'on');

% --- PANEL D: CONTINUOUS NZ SUPER RETIREMENT-AGE U-CURVE (AGES 60 TO 75) ---
ax4 = nexttile; hold(ax4, 'on');

% Highlight the Age 64-65 Sweet-Spot Band
yyaxis(ax4, 'left');
fill(ax4, [63.5, 65.5, 65.5, 63.5], [16.0, 16.0, 33.0, 33.0], [0.88 0.97 0.90], ...
    'FaceAlpha', 0.55, 'EdgeColor', [0.15 0.60 0.25], 'LineStyle', ':', ...
    'DisplayName', 'Age 64-65 Sweet Spot (Lowest Tax & Peak Welfare)');

yline(ax4, 100*Params.tau_l, 'k:', sprintf('2026 Current PAYE (%.1f%%)', 100*Params.tau_l), ...
    'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'bottom', ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'LineWidth', 1.3, 'HandleVisibility', 'off');

p_u_ss0 = plot(ax4, SuperAge_Grid, Tax_UCurve_SS0, '--o', 'Color', [0.55 0.15 0.15], ...
    'MarkerFaceColor', [0.75 0.25 0.25], 'MarkerIndices', [1, 6, 11, 16], 'LineWidth', 2.0, 'MarkerSize', 5.5, ...
    'DisplayName', sprintf('Status Quo (SS0) Required PAYE Tax U-Curve (%.1f%% at 65, %.1f%% at 70)', Tax_UCurve_SS0(6), Tax_UCurve_SS0(11)));

p_u_ss2 = plot(ax4, SuperAge_Grid, Tax_UCurve_SS2, '-s', 'Color', [0.82 0.12 0.12], ...
    'MarkerFaceColor', [0.95 0.28 0.18], 'MarkerIndices', [1, 4, 5, 6, 8, 11, 16], 'LineWidth', 2.8, 'MarkerSize', 7.0, ...
    'DisplayName', sprintf('Phase 2 (SS2) Required PAYE Tax U-Curve (Min %.2f%% at 65, %.2f%% at 64)', Tax_UCurve_SS2(6), Tax_UCurve_SS2(5)));

% Annotate key points along the SS2 Tax U-Curve with collision-free offsets:
% [Age, x_pos, y_offset]
tax_callouts = [ ...
    60, 60.35, -1.25; ... % Below marker so it never touches the 22.0% line
    64, 63.45, -1.25; ... % Shifted slightly left of 64
    65, 65.55, -1.25; ... % Shifted slightly right of 65
    70, 69.85, +1.35; ... % Above marker at Age 70
    75, 74.15, -1.35];    % Left/below marker at Age 75 so it stays well below title!

for row_c = 1:size(tax_callouts, 1)
    k_a   = tax_callouts(row_c, 1);
    x_pos = tax_callouts(row_c, 2);
    y_off = tax_callouts(row_c, 3);
    idx_a = find(SuperAge_Grid == k_a, 1);
    t_val = Tax_UCurve_SS2(idx_a);
    text(ax4, x_pos, t_val + y_off, sprintf('Age %d:\n%.2f%%', k_a, t_val), ...
        'HorizontalAlignment', 'center', 'FontSize', 7.4, 'FontWeight', 'bold', ...
        'Color', [0.65 0.05 0.05], 'BackgroundColor', [1.0 0.98 0.98], 'EdgeColor', [0.85 0.25 0.25], 'Margin', 1.5);
end

ylim(ax4, [16.0, 33.0]);
ylabel(ax4, 'Required Working-Age PAYE Tax \tau_l (%) [U-Curve]', 'FontWeight', 'bold');
set(vfi_active_ax(ax4), 'YColor', [0.75 0.10 0.10]);

yyaxis(ax4, 'right');
p_w_ss2 = plot(ax4, SuperAge_Grid, CE_UCurve_SS2, '-p', 'Color', [0.00 0.50 0.22], ...
    'MarkerFaceColor', [0.10 0.80 0.35], 'MarkerIndices', [1, 4, 5, 6, 8, 11, 16], 'LineWidth', 2.6, 'MarkerSize', 8.0, ...
    'DisplayName', 'Phase 2 (SS2) National Welfare Gain CE% [Inverted-U Peak at Age 64]');

idx_64 = find(SuperAge_Grid == 64, 1);
idx_65 = find(SuperAge_Grid == 65, 1);
% Place Welfare Peak callout just to the right of Age 65 (x = 68.3) in open space below the legend:
text(ax4, 68.3, CE_UCurve_SS2(idx_64) + 0.4, ...
    sprintf('★ Welfare Peak (Age 64): %+.2f%% CE (%.2f%% Tax)\n   Age 65 Tax Min: %+.2f%% CE (%.2f%% Tax)', ...
    CE_UCurve_SS2(idx_64), Tax_UCurve_SS2(idx_64), CE_UCurve_SS2(idx_65), Tax_UCurve_SS2(idx_65)), ...
    'HorizontalAlignment', 'center', 'FontSize', 7.5, 'FontWeight', 'bold', ...
    'Color', [0.00 0.38 0.15], 'BackgroundColor', [0.94 1.00 0.95], 'EdgeColor', [0.00 0.45 0.20], 'Margin', 2);

ylim(ax4, [0.0, 34.0]); % Gives generous headroom at the top for the northwest legend box!
ylabel(ax4, 'National Long-Run Welfare Gain (CE %) [Inverted-U]', 'FontWeight', 'bold');
set(vfi_active_ax(ax4), 'YColor', [0.00 0.42 0.18]);

xlim(ax4, [59.5, 75.5]);
xticks(ax4, 60:1:75);
xlabel(ax4, 'Statutory NZ Superannuation Eligibility Age (Years)', 'FontWeight', 'bold');
title(ax4, 'D. The Retirement-Age U-Curve (Ages 60-75): Required Tax vs. National Welfare', 'FontWeight', 'bold');
legend(ax4, [p_u_ss2, p_w_ss2, p_u_ss0], 'Location', 'northwest', 'FontSize', 7.0);
grid(ax4, 'on'); box(ax4, 'on');

do_export = isfield(Opts, 'Export_Tables_Figures') && logical(Opts.Export_Tables_Figures);
if do_export
    explicit_dir = '';
    if isfield(Opts, 'OutputDir') && ~isempty(Opts.OutputDir)
        explicit_dir = Opts.OutputDir;
    end
    out_dir = Resolve_IGW_OutputDir(explicit_dir, Params.Profile_ID);
    exportgraphics(figFert, fullfile(out_dir, 'FigFert_4Region_Bargaining_Solvency.png'), 'Resolution', 300, 'BackgroundColor', 'white');
    writetable(FertOut.T_Fert1,  fullfile(out_dir, 'Table7_4Region_Fertility_Bargaining_TFR.csv'), 'WriteRowNames', true);
    writetable(FertOut.T_Fert2,  fullfile(out_dir, 'Table8_4Region_Fertility_Struggling_NZSuperTax.csv'), 'WriteRowNames', true);
    writetable(FertOut.T_UCurve, fullfile(out_dir, 'Table8B_SuperAge_UCurve_60to75.csv'));
end

end
