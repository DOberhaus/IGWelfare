%% MULTI-STAGE CHILDHOOD COUNTERFACTUALS ACROSS 4 REGIONS (INTEGRATED WITH Params.dt)
% File: pipelines/PolicyExperiment_LeeSeshadri_4Region.m
% Pipeline orchestration & rendering script delegating counterfactual VFI/IGE math to
% Compute_LeeSeshadri_Counterfactuals.m and rendering Figure E8 + Tables 4/5/6 & 12A/12B/12C.

wb_opts = struct('RequireToolkit', true);
if exist('Regions', 'var') && ~isempty(Regions), wb_opts.Regions = Regions; end
if ~exist('Params', 'var'), Params = struct(); end
[Params, Regions] = Ensure_Workbench_Initialized(Params, wb_opts);

Grids5D = struct( ...
    'n_d_5D',                   n_d_5D, ...
    'n_a_5D',                   n_a_5D, ...
    'n_z',                      n_z, ...
    'N_j',                      N_j, ...
    'd_grid_5D',                d_grid_5D, ...
    'a_grid_5D',                a_grid_5D, ...
    'z_grid',                   z_grid, ...
    'pi_z',                     pi_z, ...
    'ReturnFn_5D',              ReturnFn_5D, ...
    'DiscountFactorParamNames', {DiscountFactorParamNames}, ...
    'vfoptions_5D',             vfoptions_5D, ...
    'simoptions_5D',            simoptions_5D);

Baseline5D = struct('jequaloneDist_5D_BM', jequaloneDist_5D_BM);
if exist('V_5D_BM', 'var'),      Baseline5D.V_5D_BM      = V_5D_BM;      end
if exist('Policy_5D_BM', 'var'), Baseline5D.Policy_5D_BM = Policy_5D_BM; end

%% 1. COMPUTE PURE COUNTERFACTUAL TABLES & MATRICES
LSOut = Compute_LeeSeshadri_Counterfactuals(Params, Grids5D, Baseline5D, struct('Regions', {Regions}));

PolicyNames = LSOut.PolicyNames;
N_pol       = numel(PolicyNames);
IGE_SR      = LSOut.IGE_SR;
IGE_LR      = LSOut.IGE_LR;
VarExpl_h1  = LSOut.VarExpl_h1;
VarExpl_LFE = LSOut.VarExpl_LFE;
VarLogE     = LSOut.VarLogE;
Ebar_SR     = LSOut.Ebar_SR;
Ebar_LR     = LSOut.Ebar_LR;
CE_LR       = LSOut.CE_LR;
T_IGE       = LSOut.T_IGE;
T_VarExpl   = LSOut.T_VarExpl;
T_Out       = LSOut.T_Out;

%% 2. PLOT 4-PANEL FIGURE E8 & EXPORT CSV TABLES
figE8 = figure('Name', 'Lee & Seshadri 4-Region Counterfactuals', 'Color', 'w', 'Position', [100, 80, 1240, 820]);
t_e8  = tiledlayout(2, 2, 'TileSpacing', 'loose', 'Padding', 'compact');

CleanLabels = {'BM Baseline'; 'P0 Early (0-5)'; 'P1/P2 Late (6-17)'; 'BN Front-Load'; 'P0 + Grant E'};
is_oct = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
if is_oct
    x_all = (1:N_pol)';
    x_sub = (1:(N_pol-1))';
else
    x_all = categorical(CleanLabels(1:N_pol), CleanLabels(1:N_pol));
    x_sub = x_all(2:end);
end

% Panel A: Long-Run IGE
ax1 = nexttile;
b_ige = bar(x_all, IGE_LR, 'grouped');
ylim([0, max(0.62, max(IGE_LR(:)) * 1.25)]);
ylabel('Long-Run IGE');
title('A. Intergenerational Elasticity of Earnings (IGE\_LR)');
if is_oct
    set(ax1, 'XTick', 1:N_pol, 'XTickLabel', CleanLabels(1:N_pol));
else
    set(ax1, 'TickLabelInterpreter', 'none');
end
grid on;
lgd = legend(b_ige, Regions, 'Orientation', 'horizontal', 'Location', 'northoutside');
if ~is_oct
    lgd.Layout.Tile = 'north';
end

% Panel B: Variance Explained
ax2 = nexttile;
bar(x_all, VarExpl_LFE, 'grouped');
ylim([0, max(88, max(VarExpl_LFE(:)) * 1.20)]);
ylabel('Variance Explained (%)');
title('B. Lifetime Earnings Variance Explained by Parents at Age 30-35');
if is_oct
    set(ax2, 'XTick', 1:N_pol, 'XTickLabel', CleanLabels(1:N_pol));
else
    set(ax2, 'TickLabelInterpreter', 'none');
end
grid on;

% Panel C: Lifetime Earnings Gain
ax3 = nexttile;
bar(x_sub, Ebar_LR(2:end, :), 'grouped');
ylim([min(0, min(Ebar_LR(:)) * 1.2), max(9.0, max(Ebar_LR(:)) * 1.22)]);
ylabel('\Delta Lifetime Earnings (%)');
title('C. Long-Run Average Lifetime Earnings Gain (Ebar\_LR %)');
if is_oct
    set(ax3, 'XTick', 1:(N_pol-1), 'XTickLabel', CleanLabels(2:N_pol));
else
    set(ax3, 'TickLabelInterpreter', 'none');
end
grid on;

% Panel D: Newborn Welfare Gain
ax4 = nexttile;
bar(x_sub, CE_LR(2:end, :), 'grouped');
ylim([min(0, min(CE_LR(:)) * 1.2), max(8.0, max(CE_LR(:)) * 1.22)]);
ylabel('Consumption Equivalent CE\_LR (%)');
title('D. Long-Run Newborn Welfare Gain (CE\_LR %)');
if is_oct
    set(ax4, 'XTick', 1:(N_pol-1), 'XTickLabel', CleanLabels(2:N_pol));
else
    set(ax4, 'TickLabelInterpreter', 'none');
end
grid on;

if ~exist('Export_Tables_Figures', 'var') || logical(Export_Tables_Figures)
    explicit_out = '';
    if exist('OutputDir', 'var') && ~isempty(OutputDir), explicit_out = OutputDir; end
    OutputDir = Resolve_IGW_OutputDir(explicit_out, Params.Profile_ID);
    exportgraphics(figE8, fullfile(OutputDir, 'FigE8_LeeSeshadri_4Region_Counterfactuals.png'), 'Resolution', 300, 'BackgroundColor', 'white');
    writetable(T_IGE,     fullfile(OutputDir, 'Table4_4Region_LeeSeshadri_IGE.csv'), 'WriteRowNames', true);
    writetable(T_Out,     fullfile(OutputDir, 'Table5_4Region_LeeSeshadri_Output_Welfare.csv'), 'WriteRowNames', true);
    writetable(T_VarExpl, fullfile(OutputDir, 'Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv'), 'WriteRowNames', true);
    writetable(T_IGE,     fullfile(OutputDir, 'Table12A_LeeSeshadri_4Region_IGE.csv'), 'WriteRowNames', true);
    writetable(T_VarExpl, fullfile(OutputDir, 'Table12B_LeeSeshadri_4Region_VarExpl.csv'), 'WriteRowNames', true);
    writetable(T_Out,     fullfile(OutputDir, 'Table12C_LeeSeshadri_4Region_Welfare.csv'), 'WriteRowNames', true);
end
