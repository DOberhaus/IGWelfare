function Out = Plot_SOE_Shock_Sensitivity_Dashboard(Params)
%% PLOT_SOE_SHOCK_SENSITIVITY_DASHBOARD (SUB-WAVE 7C: SOE SHOCK FRONTIERS & ASSEMBLY TELEMETRY)
% Cross-platform (MATLAB HG2 & GNU Octave) 4-Panel Dashboard rendering:
%   Panel A: Breaking-Point Shock Amplitude (lambda*) Across All 15 Assembly Contracts (Rigid vs Contingent)
%   Panel B: Contract Survival Decay Curves Across Shock Severity lambda in [0, 2.5] + Governance Zones
%   Panel C: 2D External SOE Polycrisis Heatmap (Exergy/Oil Spike x Sovereign Rate/ToT Hit -> Contracts Intact)
%   Panel D: Five-Assembly Own Deliverable vs. Upstream Dependency Shock Ceilings (A1..A5)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end

OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag = Params.Calibration_Anchor;

S7C = Compute_Contract_Shock_Sensitivity_Ledger(Params);
CST = S7C.ContractSecurityTable;
ART = S7C.AssemblyRoadmapTable;

vis_m = IGW_UI_Style('headless_vis');
fig   = figure('Name', sprintf('SOE Exogenous Shock Frontiers & 5-Assembly Contract Security (%s)', AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 1780, 1040], 'Visible', vis_m);

% --- PANEL A: 15-Contract Breaking-Point Frontier (Dumbbell Range Plot) ---
ax1 = subplot('Position', [0.085, 0.545, 0.385, 0.375]);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');

y_k  = (1:15)';
lamR = CST.Break_Lambda_Rigid;
lamC = CST.Break_Lambda_Cont;

% Vectorized horizontal connector segments [2 x 15]:
plot(ax1, [lamR(:)'; lamC(:)'], [y_k(:)'; y_k(:)'], '-', 'Color', [0.20 0.55 0.42], ...
    'LineWidth', 2.6, 'HandleVisibility', 'off');
p_r = plot(ax1, lamR, y_k, 'o', 'Color', [0.80 0.14 0.18], 'MarkerFaceColor', [0.85 0.20 0.24], ...
    'MarkerSize', 6.8, 'DisplayName', 'Rigid Calendar Breaking Point (\lambda^*_{Rigid})');
p_c = plot(ax1, lamC, y_k, 's', 'Color', [0.04 0.54 0.34], 'MarkerFaceColor', [0.08 0.66 0.42], ...
    'MarkerSize', 7.2, 'DisplayName', 'Two-Key + Auto-Remedy Ceiling (\lambda^*_{Cont})');

xline(ax1, 1.0, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xline(ax1, 1.5, 'r:',  'LineWidth', 1.5, 'HandleVisibility', 'off');

short_k = cellfun(@(s) regexprep(s, '_.*', ''), CST.Contract_ID, 'UniformOutput', false);
set(ax1, 'YDir', 'reverse', 'YTick', 1:15, 'YTickLabel', short_k, 'FontSize', 7.8, 'FontWeight', 'bold');
xlim(ax1, [0, 2.75]); ylim(ax1, [0.4, 15.6]);
xlabel(ax1, 'Exogenous SOE Shock Amplitude \lambda (1.0 = Severe Benchmark, 2.0 = Extreme Tail)', 'FontSize', 9.5, 'FontWeight', 'bold');
title(ax1, 'A. Contract Security Frontier: How Contingent Remedies Expand \lambda^*', 'FontSize', 10.5, 'FontWeight', 'bold');
lgd1 = legend(ax1, [p_r, p_c], 'Location', 'southeast', 'FontSize', 7.6);
IGW_UI_Style('legend_alpha', lgd1, 0.92);

% --- PANEL B: Contract Survival Curves Over Shock Severity lambda in [0, 2.5] ---
ax2 = subplot('Position', [0.535, 0.545, 0.410, 0.375]);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');

lam_vec = S7C.Lambda_Grid;
% Worst-case single shock envelope vs Compound Polycrisis:
min_single_R = min(S7C.Surv_Rigid_LamxF(:, 1:5), [], 2);
min_single_C = min(S7C.Surv_Cont_LamxF(:, 1:5),  [], 2);
poly_R       = S7C.Surv_Rigid_LamxF(:, 6);
poly_C       = S7C.Surv_Cont_LamxF(:, 6);

fill(ax2, [lam_vec; flipud(lam_vec)], [min_single_R; flipud(min_single_C)], ...
    [0.10 0.62 0.42], 'FaceAlpha', 0.14, 'EdgeColor', 'none', ...
    'DisplayName', 'Amber Zone: Contracts Saved by Pre-Agreed Remedies');

plot(ax2, lam_vec, min_single_C, '-o', 'Color', [0.06 0.56 0.36], 'LineWidth', 2.7, 'MarkerIndices', 1:3:numel(lam_vec), ...
    'DisplayName', 'Single SOE Shock: Two-Key Contingent Compact');
plot(ax2, lam_vec, min_single_R, '--v', 'Color', [0.78 0.22 0.18], 'LineWidth', 2.2, 'MarkerIndices', 1:3:numel(lam_vec), ...
    'DisplayName', 'Single SOE Shock: Rigid Unhedged Calendar');
plot(ax2, lam_vec, poly_C, '-s', 'Color', [0.16 0.36 0.74], 'LineWidth', 2.6, 'MarkerIndices', 1:3:numel(lam_vec), ...
    'DisplayName', '5-Channel Polycrisis: Two-Key Contingent Compact');
plot(ax2, lam_vec, poly_R, ':d', 'Color', [0.58 0.10 0.22], 'LineWidth', 2.2, 'MarkerIndices', 1:3:numel(lam_vec), ...
    'DisplayName', '5-Channel Polycrisis: Rigid Unhedged Calendar');

yline(ax2, 12.0, 'k:', 'LineWidth', 1.3, 'HandleVisibility', 'off');
text(ax2, 1.52, 12.4, 'Below 12/15 -> Reconvene 30-Delegate Citizen Plenary', ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.55 0.08 0.14]);

xlim(ax2, [0, 2.5]); ylim(ax2, [0, 15.8]);
xlabel(ax2, 'Exogenous Shock Amplitude \lambda', 'FontSize', 9.8, 'FontWeight', 'bold');
ylabel(ax2, 'Bilateral Assembly Contracts Intact (out of 15)', 'FontSize', 9.8, 'FontWeight', 'bold');
title(ax2, 'B. Contract Survival Across Continuous SOE Shock Ranges', 'FontSize', 10.5, 'FontWeight', 'bold');
lgd2 = legend(ax2, 'Location', 'southwest', 'FontSize', 7.4);
IGW_UI_Style('legend_alpha', lgd2, 0.92);

% --- PANEL C: 2D External SOE Polycrisis Heatmap (Exergy/Oil x Sovereign Rate/ToT) ---
ax3 = subplot('Position', [0.075, 0.085, 0.395, 0.375]);
hold(ax3, 'on'); box(ax3, 'on');

g_ax = S7C.Grid_2D_Axis;
imagesc(ax3, g_ax, g_ax, S7C.Surf_Intact_Cont);
colormap(ax3, [0.78 0.16 0.20; 0.88 0.45 0.15; 0.94 0.76 0.18; 0.42 0.74 0.38; 0.08 0.58 0.38]);
caxis(ax3, [5, 15]);
set(ax3, 'YDir', 'normal');

[GX, GY] = meshgrid(g_ax, g_ax);
cnt_lbls = arrayfun(@(v) sprintf('%d', round(v)), S7C.Surf_Intact_Cont(:), 'UniformOutput', false);
text(ax3, GX(:), GY(:), cnt_lbls, 'HorizontalAlignment', 'center', 'FontSize', 7.4, 'FontWeight', 'bold', 'Color', 'w');

xlim(ax3, [-0.12, 2.12]); ylim(ax3, [-0.12, 2.12]);
xlabel(ax3, 'External Finance & ToT Shock \lambda_F (Rate +180bp, ToT -12%)', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax3, 'Biophysical Exergy Shock \lambda_E (Oil +60%, Dry Hydro)', 'FontSize', 9.5, 'FontWeight', 'bold');
title(ax3, 'C. Joint External SOE Surface: Contracts Intact (/15) Under Remedies', 'FontSize', 10.5, 'FontWeight', 'bold');

% --- PANEL D: Per-Assembly Own vs. Upstream Dependency Shock Ceilings (A1..A5) ---
ax4 = subplot('Position', [0.535, 0.085, 0.410, 0.375]);
hold(ax4, 'on'); grid(ax4, 'on'); box(ax4, 'on');

bD = bar(ax4, 1:5, [ART.Own_Break_Rigid, ART.Own_Break_Cont, ART.Upstream_Dep_Break_Rigid, ART.Upstream_Dep_Break_Cont], ...
    'grouped', 'BarWidth', 0.84);
set(bD(1), 'FaceColor', [0.80 0.24 0.22], 'DisplayName', 'Own Deliverables (Rigid)');
set(bD(2), 'FaceColor', [0.06 0.58 0.38], 'DisplayName', 'Own Deliverables (Contingent)');
set(bD(3), 'FaceColor', [0.88 0.56 0.18], 'DisplayName', 'Upstream Dependencies (Rigid)');
set(bD(4), 'FaceColor', [0.16 0.42 0.76], 'DisplayName', 'Upstream Dependencies (Contingent)');

yline(ax4, 1.0, 'k--', 'LineWidth', 1.3, 'HandleVisibility', 'off');
set(ax4, 'XTick', 1:5, 'XTickLabel', {'A1 Child/Youth', 'A2 Housing/Super', 'A3 Civic/Arts', 'A4 Firm/Exergy', 'A5 Debt/Infra'}, ...
    'FontSize', 8.5, 'FontWeight', 'bold');
ylabel(ax4, 'Safe Shock Amplitude Ceiling \lambda^* Before First Breach', 'FontSize', 9.8, 'FontWeight', 'bold');
ylim(ax4, [0, 2.65]);
title(ax4, 'D. Assembly Telemetry: Own Mandate vs. Neighbor Dependency Ceilings', 'FontSize', 10.5, 'FontWeight', 'bold');
lgd4 = legend(ax4, 'Location', 'northwest', 'NumColumns', 2, 'FontSize', 7.3);
IGW_UI_Style('legend_alpha', lgd4, 0.92);

Out_PNG = fullfile(OutputDir, sprintf('Fig_Doc1F_SOE_Shock_Contract_Frontiers_%s.png', AnchorTag));
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved SOE Shock-Frontier & Assembly Telemetry Dashboard to: %s\n', Out_PNG);

Out = struct('Sensitivity', S7C, 'Fig_Path', Out_PNG);
end
