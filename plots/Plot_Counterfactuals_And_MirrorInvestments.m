function Out = Plot_Counterfactuals_And_MirrorInvestments(Params)
% PLOT_COUNTERFACTUALS_AND_MIRRORINVESTMENTS
% Renders the 2-Panel Constructive Supermodular Attribution Figure and the
% Split-Column Wave-Convolved Mirror-Investment Figure from pure ledger output
% Compute_Synergy_And_Mirror_Ledger (exporting Table 19, Table 19E, and Table 20).

if nargin < 1 || isempty(Params), Params = struct(); end
if ~isfield(Params, 'Kahui_ECE_13x5') || ~isfield(Params, 'Profile_ID')
    Params = Configure_TimeGrid_Params(Params);
end

T1_ws = [];
if evalin('base', 'exist(''T1'', ''var'')')
    T1_ws = evalin('base', 'T1');
end
rps_ws = [];
if evalin('base', 'exist(''Reform_Phase_Specs'', ''var'')')
    rps_ws = evalin('base', 'Reform_Phase_Specs');
end

% 1. Compute pure headless 11-layer + Arts/Civic Cap + Mirror ledger
L         = Compute_Synergy_And_Mirror_Ledger(Params, T1_ws, rps_ws);
AnchorTag = L.AnchorTag;
OutputDir = Resolve_IGW_OutputDir('', L.Profile_ID);
r_sel     = L.Target_Region;

if L.Col_Idx == 5
    Reg_File_Suffix = AnchorTag;
else
    Reg_File_Suffix = sprintf('%s_%s', r_sel, AnchorTag);
end

% 2. Export Table 19 (11-Layer Default), Table 19E (15-Layer Arts-Enabled), & Table 20
csv19 = fullfile(OutputDir, sprintf('Table19_Constructive_Synergy_Wedges_%s.csv', AnchorTag));
writetable(L.Table19, csv19);
fprintf('  -> Exported Table 19 (11-Layer Constructive Synergy Attribution) to: %s\n', csv19);

csv19E = fullfile(OutputDir, sprintf('Table19E_ArtsEnabled_Synergy_Wedges_%s.csv', AnchorTag));
writetable(L.Table19E, csv19E);
fprintf('  -> Exported Table 19E (Default + Document 1E Arts-Enabled Attribution) to: %s\n', csv19E);

csv20 = fullfile(OutputDir, sprintf('Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_%s.csv', Reg_File_Suffix));
writetable(L.Table20, csv20);

% Unpack pure ledger series for clean plotting
enable_arts          = L.enable_arts;
Is_Wedge             = L.Is_Wedge;
Wed_Idx              = L.Wed_Idx;
Layer_Legend_Labels  = L.Layer_Legend_Labels;
SS2_11x5             = L.SS2_11x5;
SS2_Nat_11           = L.SS2_Nat_11;
SS2_Sel_11           = L.SS2_Sel_11;
SS2_Sel_Total        = L.SS2_Sel_Total;
Arts_SS2_5           = L.Arts_SS2_5;
Arts_SS2_Sel_Total   = sum(L.Arts_SS2_Sel);
T1E_Sel_Total        = SS2_Sel_Total + Arts_SS2_Sel_Total;
Yr_Grid              = L.Yr_Grid;
Traj_11              = L.Traj_11;
Traj_Arts            = L.Traj_Arts;
YGr_Early_Share_Grid = L.YGr_Early_Share_Grid;
Total_Traj_CE        = L.Total_Traj_CE;
Total_Arts_Traj_CE   = L.Total_Arts_Traj_CE;
Iso_Only_Traj_CE     = L.Iso_Only_Traj_CE;
Total_1Shot_Grid     = L.Total_1Shot_Grid;
sh_ygr_base0         = L.sh_ygr_base0;
NZD_Per_CE           = L.NZD_Per_CE;
t_join               = L.t_join;

c_pale_purple_pos = [0.88, 0.76, 0.94];
c_pale_purple_neg = [0.84, 0.68, 0.90];

layer_colors = [ ...
    0.20, 0.48, 0.68; ...
    0.38, 0.65, 0.78; ...
    0.96, 0.76, 0.12; ...
    0.28, 0.54, 0.40; ...
    0.62, 0.24, 0.66; ...
    0.64, 0.80, 0.62; ...
    0.94, 0.50, 0.12; ...
    0.84, 0.18, 0.24; ...
    0.42, 0.46, 0.70; ...
    0.62, 0.62, 0.82; ...
    0.05, 0.56, 0.32];
wedge_colors_4 = layer_colors(Wed_Idx, :);

% =========================================================================
% 3. RENDER FIGURE A: 2-PANEL CONSTRUCTIVE SYNERGY ATTRIBUTION (DEFAULT + ARTS CAP)
% =========================================================================
vis_m  = IGW_UI_Style('headless_vis');
fig_cf = figure('Name', sprintf('Fig_Constructive_Synergy_Attribution_%s', Reg_File_Suffix), ...
    'Color', 'w', 'Position', [35, 45, 1680, 840], 'Visible', vis_m);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

SS2_15x5  = [SS2_11x5; Arts_SS2_5];
max_y_val = max([max(sum(SS2_15x5, 1)), max(Total_Arts_Traj_CE), 31.5]);
y_top_lim = ceil(max_y_val * 1.18);
min_y_val = min([0, min(sum(SS2_11x5, 1)), min(Total_Traj_CE)]);
y_bot_lim = floor(min_y_val * 1.15);

axA     = nexttile(1); hold(axA, 'on');
Traj_15 = [Traj_11, Traj_Arts];
h_area  = area(axA, Yr_Grid, Traj_15, 'LineWidth', 0.6, 'EdgeColor', [0.18 0.18 0.18]);
for k = 1:11
    pch_a = findobj(h_area(k), 'type', 'patch');
    set(pch_a, 'FaceColor', layer_colors(k, :));
    if Is_Wedge(k)
        set(pch_a, 'FaceAlpha', 0.92, 'EdgeColor', [0.10 0.10 0.10], 'LineWidth', 1.0);
    else
        set(pch_a, 'FaceAlpha', 0.78);
    end
    set(h_area(k), 'DisplayName', Layer_Legend_Labels{k});
end
for j = 1:4
    k15   = 11 + j;
    pch_c = findobj(h_area(k15), 'type', 'patch');
    set(pch_c, 'FaceColor', 0.68 * wedge_colors_4(j, :) + 0.32 * [1 1 1], ...
        'FaceAlpha', 0.88, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.75);
    set(h_area(k15), 'HandleVisibility', 'off');
end

if enable_arts
    local_hatch_band(axA, Yr_Grid, Total_Traj_CE, Total_Arts_Traj_CE, 2.2, 0.42, [0.14 0.14 0.14]);
end

y_bot_L5   = sum(Traj_11(:, 1:4), 2);
y_early_L5 = y_bot_L5 + Traj_11(:, 5) .* YGr_Early_Share_Grid;
h_pale = fill(axA, [Yr_Grid; flipud(Yr_Grid)], [y_bot_L5; flipud(y_early_L5)], c_pale_purple_pos, ...
    'FaceAlpha', 0.95, 'EdgeColor', [0.45 0.18 0.52], 'LineWidth', 0.5, ...
    'DisplayName', sprintf('5a. [Early Adopters] Youth Grants for Existing %.1f%% %s Tuakana Mentees (Active Yr 1!)', 100*sh_ygr_base0, r_sel));

h_tot = plot(axA, Yr_Grid, Total_Traj_CE, 'k-', 'LineWidth', 2.9, ...
    'DisplayName', sprintf('DEFAULT DIVIDER BAR (%s): Converges to %+.2f%% in SS2', r_sel, SS2_Sel_Total));
if enable_arts
    h_arts = plot(axA, Yr_Grid, Total_Arts_Traj_CE, '-', 'Color', [0.42 0.06 0.52], 'LineWidth', 2.5, ...
        'DisplayName', sprintf('ARTS & CIVIC ENABLED (Doc 1E Hatched Cap: %+.2f%% \rightarrow %+.2f%% SS2)', Arts_SS2_Sel_Total, T1E_Sel_Total));
end
h_1sh = plot(axA, Yr_Grid, Total_1Shot_Grid, ':', 'Color', [0.15 0.35 0.65], 'LineWidth', 2.0, ...
    'DisplayName', sprintf('Single-Phase Step Reference (Early Bottleneck Drag \rightarrow Same %+.2f%% Base SS2)', SS2_Sel_Total));
h_iso = plot(axA, Yr_Grid, Iso_Only_Traj_CE, '--', 'Color', [0.15 0.15 0.15], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Additive Sum of 7 Isolated Factors Without Synergy (%+.2f%% in SS2)', sum(SS2_Sel_11(~Is_Wedge))));

xline(axA, 0,    'k--', 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(axA, 7.0,  ':',   'Color', [0.58 0.20 0.62], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axA, 16.8, ':',   'Color', [0.40 0.15 0.60], 'LineWidth', 1.6, 'HandleVisibility', 'off');
xline(axA, 25.0, '--',  'Color', [0.05 0.50 0.20], 'LineWidth', 1.6, 'HandleVisibility', 'off');

y_iso_52  = interp1(Yr_Grid, Iso_Only_Traj_CE,   52);
y_tot_52  = interp1(Yr_Grid, Total_Traj_CE,      52);
y_arts_52 = interp1(Yr_Grid, Total_Arts_Traj_CE, 52);
syn_pct_share = 100 * (sum(SS2_Sel_11(Is_Wedge)) + Arts_SS2_Sel_Total) / max(1e-6, T1E_Sel_Total);
plot(axA, [52, 52], [y_iso_52, y_arts_52], 'r-', 'LineWidth', 2.2, 'HandleVisibility', 'off');
text(axA, 50.5, 0.5*(y_iso_52 + y_tot_52), ...
    sprintf('Default Wedges (%s): %+.2f%%\n+ Arts Cap: %+.2f%%\n= %.1f%% Total Synergy!', ...
    r_sel, sum(SS2_Sel_11(Is_Wedge)), Arts_SS2_Sel_Total, syn_pct_share), ...
    'HorizontalAlignment', 'right', 'FontSize', 8.0, 'FontWeight', 'bold', ...
    'Color', [0.65 0.05 0.10], 'BackgroundColor', [1.0 0.96 0.94], 'EdgeColor', [0.75 0.15 0.20], 'Margin', 3.5);

text(axA, 0.6, 5.2, sprintf('Yrs 1-6: %.1f%% Early-Adopter\nGrants (Pale Purple) \rightarrow\nTe Kāhui Waka Expansion @ Yr 7+', 100*sh_ygr_base0), ...
    'FontSize', 7.5, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', [0.45 0.18 0.52], 'Margin', 2.5);
text(axA, 25.6, 16.0, sprintf('%s\n(Wave-Convolved SS2 Echo)', L.box25_label), 'FontSize', 7.8, 'FontWeight', 'bold', ...
    'Color', [0.00 0.42 0.18], 'BackgroundColor', 'w', 'EdgeColor', [0.00 0.45 0.20], 'Margin', 2.5);

title(axA, sprintf('A. Constructive Attribution (%s): Default Stack + Hatched Arts & Civic Cap (Doc 1E)', r_sel), ...
    'FontSize', 10.6, 'FontWeight', 'bold');
xlabel(axA, 'Cohort Entry Year Relative to 2026 Reform Introduction (13-Wave Te Kāhui Waka S-Curve)', 'FontSize', 10.2, 'FontWeight', 'bold');
ylabel(axA, 'Lifetime Consumption-Equivalent Welfare Gain (CE %)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlim(axA, [-3, 63]); xticks(axA, 0:10:60); ylim(axA, [y_bot_lim, y_top_lim]);
grid(axA, 'on'); box(axA, 'on');
if enable_arts
    legend(axA, [h_area(1:5), h_pale, h_area(6:11), h_tot, h_arts, h_1sh, h_iso], 'Location', 'northwest', 'FontSize', 6.0);
else
    legend(axA, [h_area(1:5), h_pale, h_area(6:11), h_tot, h_1sh, h_iso], 'Location', 'northwest', 'FontSize', 6.2);
end

% --- PANEL B: REGIONAL & NATIONAL SS2 STACKED BUILD-UP WITH DIVIDER BAR & ARTS CAP ---
axB   = nexttile(2); hold(axB, 'on');
x_5   = 1:5;
bar_w = 0.58;
b_reg = bar(axB, x_5, SS2_15x5', 'stacked', 'BarWidth', bar_w, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.6);
for k = 1:11
    set(b_reg(k), 'FaceColor', layer_colors(k, :));
    if Is_Wedge(k)
        set(b_reg(k), 'LineWidth', 1.1);
        set(findobj(b_reg(k), 'type', 'patch'), 'FaceAlpha', 0.94);
    else
        set(findobj(b_reg(k), 'type', 'patch'), 'FaceAlpha', 0.80);
    end
end
for j = 1:4
    k15 = 11 + j;
    set(b_reg(k15), 'FaceColor', 0.68 * wedge_colors_4(j, :) + 0.32 * [1 1 1], 'LineWidth', 0.9);
    set(findobj(b_reg(k15), 'type', 'patch'), 'FaceAlpha', 0.90);
end

Reg_Default_5 = sum(SS2_11x5, 1);
Reg_ArtsCap_5 = sum(Arts_SS2_5, 1);
Reg_Totals_5  = Reg_Default_5 + Reg_ArtsCap_5;

if enable_arts
    local_hatch_stacked_caps(axB, x_5, bar_w, Reg_Default_5, Arts_SS2_5, 0.22, 0.55, [0.14 0.14 0.14]);
    for c = 1:5
        y_div = Reg_Default_5(c);
        plot(axB, [c - 0.54*bar_w, c + 0.54*bar_w], [y_div, y_div], '-', ...
            'Color', [0.08 0.08 0.08], 'LineWidth', 3.2, 'HandleVisibility', 'off');
        plot(axB, [c - 0.54*bar_w, c + 0.54*bar_w], [y_div, y_div], '--', ...
            'Color', [1.00 0.96 0.70], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    end
end

for c = 1:5
    cum_bot = 0;
    for k = 1:11
        val_kc = SS2_11x5(k, c);
        if val_kc >= 0.95
            y_mid  = cum_bot + 0.5 * val_kc;
            pct_sh = round(100 * val_kc / max(1e-6, Reg_Default_5(c)));
            if Is_Wedge(k)
                lbl_str = sprintf('★%+.2f%%\n(%d%%)', val_kc, pct_sh);
                txt_col = [0.10 0.05 0.00];
                if k == 8 || k == 11, txt_col = [1 1 1]; end
            else
                lbl_str = sprintf('%+.2f%%\n(%d%%)', val_kc, pct_sh);
                txt_col = [1 1 1];
                if k == 6 || k == 10, txt_col = [0.12 0.12 0.12]; end
            end
            text(axB, c, y_mid, lbl_str, 'HorizontalAlignment', 'center', ...
                'FontSize', 6.5, 'FontWeight', 'bold', 'Color', txt_col);
        end
        cum_bot = cum_bot + val_kc;
    end
    if enable_arts
        y_cap_mid = Reg_Default_5(c) + 0.5 * Reg_ArtsCap_5(c);
        text(axB, c, y_cap_mid, sprintf('+%0.2f%% Arts', Reg_ArtsCap_5(c)), ...
            'HorizontalAlignment', 'center', 'FontSize', 6.3, 'FontWeight', 'bold', ...
            'Color', [0.12 0.04 0.18], 'BackgroundColor', [1 1 1], 'Margin', 1.0);
        text(axB, c, Reg_Totals_5(c) + 0.95, ...
            sprintf('Arts Total: %+.2f%%\n(Base %+.2f%% | +%0.2f%%)', Reg_Totals_5(c), Reg_Default_5(c), Reg_ArtsCap_5(c)), ...
            'HorizontalAlignment', 'center', 'FontSize', 7.2, 'FontWeight', 'bold', 'Color', [0.18 0.04 0.28]);
    else
        iso_sum_c = sum(SS2_11x5(~Is_Wedge, c));
        wed_sum_c = sum(SS2_11x5(Is_Wedge, c));
        text(axB, c, Reg_Totals_5(c) + 0.85, ...
            sprintf('Total: %+.2f%%\n(Iso %+.1f%% | ★Syn %+.1f%%)', Reg_Totals_5(c), iso_sum_c, wed_sum_c), ...
            'HorizontalAlignment', 'center', 'FontSize', 7.5, 'FontWeight', 'bold', 'Color', [0.05 0.15 0.05]);
    end
end

c_nat_cum = cumsum(SS2_Nat_11);
tier_tops = [c_nat_cum(3), c_nat_cum(7), c_nat_cum(8), c_nat_cum(11)];
tier_bots = [0,            c_nat_cum(3), c_nat_cum(7), c_nat_cum(8)];
tier_lbls = { ...
    sprintf('Tier 1: Dual-Gate HC\n(%+.2f%%: %+.1f%% Iso, ★%+.1f%% Wedge)', tier_tops(1) - tier_bots(1), SS2_Nat_11(1)+SS2_Nat_11(2), SS2_Nat_11(3)), ...
    sprintf('Tier 2: Spatial/LVR Stack\n(%+.2f%%: %+.1f%% Iso, ★%+.1f%% Wedge)', tier_tops(2) - tier_bots(2), sum(SS2_Nat_11(4:6)), SS2_Nat_11(7)), ...
    sprintf('★ Wedge 3: Stack 1 \\times Stack 2\n(%+.2f%% Cross-Stack Synergy)', tier_tops(3) - tier_bots(3)), ...
    sprintf('%s\n(%+.2f%%: %+.1f%% Iso, ★%+.1f%% Wedge)', L.tier4_hdr, tier_tops(4) - tier_bots(4), SS2_Nat_11(9)+SS2_Nat_11(10), SS2_Nat_11(11))};
for t_i = 1:4
    ym = 0.5 * (tier_bots(t_i) + tier_tops(t_i));
    plot(axB, [5.32, 5.38, 5.38, 5.32], [tier_bots(t_i)+0.15, tier_bots(t_i)+0.15, tier_tops(t_i)-0.15, tier_tops(t_i)-0.15], ...
        'k-', 'LineWidth', 1.1, 'HandleVisibility', 'off');
    text(axB, 5.42, ym, tier_lbls{t_i}, 'FontSize', 7.0, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15]);
end
if enable_arts
    y_div_nat = c_nat_cum(11);
    y_top_nat = y_div_nat + Reg_ArtsCap_5(5);
    plot(axB, [5.32, 5.40], [y_div_nat, y_div_nat], '-', 'Color', [0.08 0.08 0.08], 'LineWidth', 2.4, 'HandleVisibility', 'off');
    plot(axB, [5.32, 5.38, 5.38, 5.32], [y_div_nat+0.12, y_div_nat+0.12, y_top_nat-0.12, y_top_nat-0.12], ...
        '-', 'Color', [0.42 0.06 0.52], 'LineWidth', 1.3, 'HandleVisibility', 'off');
    text(axB, 5.42, 0.5*(y_div_nat + y_top_nat) + 0.25, ...
        sprintf('ARTS & CIVIC CAP (Doc 1E)\n★%+.2f%% (+\DeltaW1..W4 Hatched)\n── Default Bar: %+.2f%% ──', ...
        Reg_ArtsCap_5(5), y_div_nat), ...
        'FontSize', 7.0, 'FontWeight', 'bold', 'Color', [0.35 0.05 0.45]);
end

x_lbls_5 = arrayfun(@(c) sprintf('%s (%+.2f%%)', L.Params.Reg_Names_5{c}, Reg_Totals_5(c)), 1:5, 'UniformOutput', false);
set(axB, 'XTick', x_5, 'XTickLabel', x_lbls_5, 'XTickLabelRotation', 20, 'FontSize', 9.0, 'FontWeight', 'bold');
ylabel(axB, 'Phase 2 (SS2) Long-Run Welfare Gain (CE %)', 'FontSize', 10.2, 'FontWeight', 'bold');
title(axB, 'B. Regional SS2 Build-Up: Default Bar (──) + Hatched Arts & Civic Wedge Caps', ...
    'FontSize', 10.6, 'FontWeight', 'bold');
xlim(axB, [0.4, 6.55]); ylim(axB, [y_bot_lim, y_top_lim]);
grid(axB, 'on'); box(axB, 'on');

f_cf_out = fullfile(OutputDir, sprintf('Fig_Counterfactual_8Scenarios_SS1_SS2_%s.png', Reg_File_Suffix));
exportgraphics(fig_cf, f_cf_out, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved 2-Panel Constructive Synergy Attribution Figure (%s) to: %s\n', r_sel, f_cf_out);

% =========================================================================
% 4. RENDER FIGURE B: SPLIT-COLUMN TE KĀHUI WAKA MIRROR LEDGER + ARTS CAP
% =========================================================================
Yr_Mir      = L.Yr_Mir;
Pos_12_Mir  = L.Pos_12_Mir;
Pos_16_Kh   = [L.Pos_12_Kahui, L.Pos_Arts_Mir];
Neg_5_Mir   = L.Neg_5_Mir;
Neg_6_Kh    = [L.Neg_5_Kahui, L.Neg_JoinerPassport_CE];

fig_mir = figure('Name', sprintf('Fig_11Layer_Welfare_And_MirrorInvestments_%s', Reg_File_Suffix), ...
    'Color', 'w', 'Position', [40, 35, 1640, 880], 'Visible', vis_m);
axM = axes(fig_mir); hold(axM, 'on');

m_split = Yr_Mir <  t_join;
m_join  = Yr_Mir >= t_join;
dx_half = 0.42;
bw_half = 0.38;
bw_join = 0.72;

pos12_colors = [layer_colors(1:4, :); c_pale_purple_pos; layer_colors(5:11, :)];
arts4_colors = 0.68 * wedge_colors_4 + 0.32 * ones(4, 3);
pos16_colors = [pos12_colors; arts4_colors];
neg5_colors  = [0.78, 0.12, 0.18; 0.92, 0.38, 0.22; c_pale_purple_neg; 0.58, 0.20, 0.62; 0.32, 0.32, 0.48];
neg6_colors  = [neg5_colors; 0.65 * neg5_colors(2, :) + 0.35 * [1 1 1]];

% Years 0..14 Left Half-Columns: Single-Phase Launch
b_pos_1s = bar(axM, Yr_Mir(m_split) - dx_half, Pos_12_Mir(m_split, :), 'stacked', 'BarWidth', bw_half, ...
    'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.35, 'HandleVisibility', 'off');
for k = 1:12
    set(b_pos_1s(k), 'FaceColor', pos12_colors(k, :));
    set(findobj(b_pos_1s(k), 'type', 'patch'), 'FaceAlpha', 0.60);
end

b_neg_1s = bar(axM, Yr_Mir(m_split) - dx_half, Neg_5_Mir(m_split, :), 'stacked', 'BarWidth', bw_half, ...
    'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.35, 'HandleVisibility', 'off');
for k = 1:5
    set(b_neg_1s(k), 'FaceColor', neg5_colors(k, :));
    set(findobj(b_neg_1s(k), 'type', 'patch'), 'FaceAlpha', 0.60);
end

% Years 0..14 Right Half-Columns: 13-Wave Te Kāhui Waka + Arts Cap
b_pos_sp = bar(axM, Yr_Mir(m_split) + dx_half, Pos_16_Kh(m_split, :), 'stacked', 'BarWidth', bw_half, ...
    'EdgeColor', [0.10 0.10 0.10], 'LineWidth', 0.55, 'HandleVisibility', 'off');
for k = 1:16
    set(b_pos_sp(k), 'FaceColor', pos16_colors(k, :));
    set(findobj(b_pos_sp(k), 'type', 'patch'), 'FaceAlpha', 0.92);
end

b_neg_sp = bar(axM, Yr_Mir(m_split) + dx_half, Neg_6_Kh(m_split, :), 'stacked', 'BarWidth', bw_half, ...
    'EdgeColor', [0.10 0.10 0.10], 'LineWidth', 0.55, 'HandleVisibility', 'off');
for k = 1:6
    set(b_neg_sp(k), 'FaceColor', neg6_colors(k, :));
    set(findobj(b_neg_sp(k), 'type', 'patch'), 'FaceAlpha', 0.92);
end

% Years 16..60 Unified Full-Width Columns
b_pos16 = bar(axM, Yr_Mir(m_join), Pos_16_Kh(m_join, :), 'stacked', 'BarWidth', bw_join, ...
    'EdgeColor', [0.10 0.10 0.10], 'LineWidth', 0.55);
pos12_labels = [Layer_Legend_Labels(1:4), ...
    {sprintf('5a. [Early-Adopter Bridge] Youth Grants for %.1f%% %s Tuakana Base (Yrs 1-12 \rightarrow Folds In by Yr 14!)', 100*sh_ygr_base0, r_sel)}, ...
    {'5b. [Universal Te Kāhui Waka] Youth Grants Across Mentored Waves (100% Universal Yr 13+!)'}, ...
    Layer_Legend_Labels(6:11)];
for k = 1:12
    set(b_pos16(k), 'FaceColor', pos16_colors(k, :), 'DisplayName', pos12_labels{k});
    set(findobj(b_pos16(k), 'type', 'patch'), 'FaceAlpha', 0.94);
end
for k = 13:16
    set(b_pos16(k), 'FaceColor', pos16_colors(k, :), 'HandleVisibility', 'off');
    set(findobj(b_pos16(k), 'type', 'patch'), 'FaceAlpha', 0.90);
end
set(b_pos_sp(5), 'HandleVisibility', 'on', 'DisplayName', pos12_labels{5});
set(b_pos16(5),  'HandleVisibility', 'off');

b_neg6 = bar(axM, Yr_Mir(m_join), Neg_6_Kh(m_join, :), 'stacked', 'BarWidth', bw_join, ...
    'EdgeColor', [0.10 0.10 0.10], 'LineWidth', 0.55);
inv6_names = { ...
    '-Inv 1: Universal First-2000-Days Wraparound (\DeltaG_{ECE,1})', ...
    '-Inv 2: Tuakana-Teina / Montessori Mentoring (\DeltaG_{ECE,2})', ...
    sprintf('-Inv 3a: Early-Adopter Bridge Grants (%.1f%% %s Tuakana Base in Yrs 1-6 \rightarrow Folds In Yr 13)', 100*sh_ygr_base0, r_sel), ...
    '-Inv 3b: Universal Te Kāhui Waka Youth Grants (Waves 7-13 \rightarrow 100% Universal Yr 13+, Vivid Orchid)', ...
    '-Inv 4: Geographic & Electrification Grants (\DeltaT_k: Retires 82% in SS2!)', ...
    '-\DeltaInv 2E: Universal NZD 500/yr Joiner Passport & Residencies (-0.33B/yr \rightarrow 24.3x Marginal!)'};
for k = 1:6
    set(b_neg6(k), 'FaceColor', neg6_colors(k, :), 'DisplayName', inv6_names{k});
    set(findobj(b_neg6(k), 'type', 'patch'), 'FaceAlpha', 0.94);
end
set(b_neg_sp(3), 'HandleVisibility', 'on', 'DisplayName', inv6_names{3});
set(b_neg6(3),   'HandleVisibility', 'off');
if ~enable_arts
    set(b_neg6(6), 'HandleVisibility', 'off');
end

if enable_arts
    % Hatch Arts-Enabled caps & draw Default Divider Bar across joined bars:
    idx_j = find(m_join);
    local_hatch_stacked_caps(axM, Yr_Mir(idx_j)', bw_join*2.0, L.Total_Kahui_CE(idx_j)', L.Pos_Arts_Mir(idx_j, :)', 1.15, 0.62, [0.15 0.15 0.15]);
    for ii = idx_j'
        xc = Yr_Mir(ii);
        yd = L.Total_Kahui_CE(ii);
        plot(axM, [xc - 0.52*bw_join*2, xc + 0.52*bw_join*2], [yd, yd], '-', ...
            'Color', [0.08 0.08 0.08], 'LineWidth', 2.2, 'HandleVisibility', 'off');
    end
end

m_sp_inc = Yr_Mir <= t_join;
x_1s_env = Yr_Mir(m_sp_inc) - dx_half * (Yr_Mir(m_sp_inc) < t_join);
x_kh_env = Yr_Mir + dx_half * m_split;

h_ov1 = plot(axM, x_1s_env, L.Total_Mir_CE(m_sp_inc), '--', 'Color', [0.18 0.38 0.58], 'LineWidth', 2.2, ...
    'DisplayName', 'Yrs 0-14 Left Half-Bar: Single-Phase Step (4-Yr System Learning \rightarrow Joins Unified Path at Yr 16!)');
h_ov2 = plot(axM, x_kh_env, L.Total_Kahui_CE, '-o', 'Color', [0.08 0.08 0.08], 'MarkerFaceColor', [0.24 0.24 0.24], ...
    'LineWidth', 2.5, 'MarkerSize', 4.2, ...
    'DisplayName', sprintf('DEFAULT DIVIDER BAR (Te Kāhui Waka): %+.2f%% Base SS2', L.Total_Kahui_CE(end)));

if enable_arts
    h_ov2E = plot(axM, x_kh_env, L.Total_Arts_Kahui_CE, '-^', 'Color', [0.00 0.36 0.14], 'MarkerFaceColor', [0.00 0.64 0.26], ...
        'LineWidth', 2.6, 'MarkerSize', 4.8, ...
        'DisplayName', sprintf('ARTS & CIVIC ENABLED (Doc 1E Hatched Cap): %+.2f%% Total SS2', L.Total_Arts_Kahui_CE(end)));
    act_kh  = L.Actuarial_CBAx_Arts_Kahui_CE;
    cash_kh = L.Net_Fiscal_Outlay_Arts_Kahui_CE;
else
    act_kh  = L.Actuarial_CBAx_Kahui_CE;
    cash_kh = L.Net_Fiscal_Outlay_Kahui_CE;
end

cbax_yr5 = interp1(Yr_Mir, act_kh, 5.0, 'linear');
h_ov3 = plot(axM, x_kh_env, act_kh, '-.s', 'Color', [0.00 0.72 0.78], 'MarkerFaceColor', [0.15 0.92 0.95], ...
    'MarkerEdgeColor', [0.00 0.38 0.44], 'LineWidth', 2.4, 'MarkerSize', 4.8, ...
    'DisplayName', sprintf('Te Kāhui Waka ACC / CBAx Actuarial Valuation (0%% Yr 0 \rightarrow %+.2f%% CE [%+.1fB/yr] at Yr 5)', cbax_yr5, cbax_yr5*NZD_Per_CE));

trough_1s = min(L.Net_Fiscal_Outlay_Mirror_CE);
trough_kh = min(cash_kh);
m_c1s     = Yr_Mir <= 20.0;
x_1s_cash = Yr_Mir(m_c1s) - dx_half * (Yr_Mir(m_c1s) < t_join);
h_ov4 = plot(axM, x_1s_cash, L.Net_Fiscal_Outlay_Mirror_CE(m_c1s), ':v', 'Color', [0.85 0.48 0.05], 'MarkerFaceColor', [0.95 0.60 0.10], ...
    'LineWidth', 2.0, 'MarkerSize', 4.0, ...
    'DisplayName', sprintf('Single-Phase Annual Net Unrecovered Cost (%.2f%% CE [%.1fB/yr] Trough \rightarrow Breakeven Yr 18.8)', trough_1s, trough_1s*NZD_Per_CE));
h_ov5 = plot(axM, x_kh_env, cash_kh, '--d', 'Color', [0.95 0.82 0.15], 'MarkerFaceColor', [0.95 0.82 0.15], ...
    'MarkerEdgeColor', [0.25 0.20 0.00], 'LineWidth', 2.4, 'MarkerSize', 4.6, ...
    'DisplayName', sprintf('Te Kāhui Waka Annual Net Unrecovered Cost (%.2f%% CE [%.1fB/yr] Trough)', trough_kh, trough_kh*NZD_Per_CE));

y_mir_top = max(39.0, ceil(max([L.Total_Mir_CE(:); L.Total_Arts_Kahui_CE(:); T1E_Sel_Total]) * 1.44));
y_mir_bot = -8.8;

m_pos_f = L.Yr_Fine >= 0;
h_ov6 = plot(axM, L.Yr_Fine(m_pos_f), L.LTFM_Ann_Deficit_CE(m_pos_f), '-', 'Color', [0.76 0.04 0.12], 'LineWidth', 3.4, ...
    'DisplayName', sprintf('Status Quo LTFM Annual Incremental Debt Sinking (-dDebt/dt: -4.57%% CE [%.1fB/yr] @ Yr 30 \rightarrow -6.24%% CE [%.1fB/yr] @ Yr 60!)', ...
    -4.57*NZD_Per_CE, -6.24*NZD_Per_CE));

yline(axM, 0, 'k-', 'LineWidth', 1.8, 'HandleVisibility', 'off');
xline(axM, 0,    'k:',  'LineWidth', 1.4, 'HandleVisibility', 'off');
xline(axM, 5.0,  ':',   'Color', [0.00 0.55 0.62], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axM, 7.0,  ':',   'Color', [0.58 0.20 0.62], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axM, 15.0, ':',   'Color', [0.25 0.25 0.25], 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(axM, 16.8, '--',  'Color', [0.00 0.52 0.22], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axM, 25.0, 'b-.', 'LineWidth', 1.7, 'HandleVisibility', 'off');

ylabel(axM, 'Annual Welfare Flow (+CE %/yr) Above 0  |  Annual Public Outlay & LTFM Deficit (-CE %/yr) Below 0', 'FontSize', 10.0, 'FontWeight', 'bold');
ylim(axM, [y_mir_bot, y_mir_top]);

yyaxis(axM, 'right');
ylim(axM, [y_mir_bot * NZD_Per_CE, y_mir_top * NZD_Per_CE]);
ylabel(axM, sprintf('%s Annual Gain (+%s B/yr) vs. Outlay & LTFM Deficit (-%s B/yr)', r_sel, L.Params.Currency_ISO, L.Params.Currency_ISO), 'FontSize', 10.0, 'FontWeight', 'bold');
set(vfi_active_ax(axM), 'YColor', [0.15 0.15 0.15]);
yyaxis(axM, 'left');

title(axM, sprintf('Apples-to-Apples Annual Flows (%s): Default 11-Layer + Hatched Arts Cap vs. Mirror Outlays & LTFM Deficit', r_sel), ...
    'FontSize', 10.6, 'FontWeight', 'bold');
xlabel(axM, 'Years Relative to Reform Launch (Yrs 0-14 Split: Single-Phase Left vs. Te Kāhui Waka Right | Yr 16+ Unified Trajectory)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlim(axM, [-3, 63]); xticks(axM, 0:5:60); grid(axM, 'on'); box(axM, 'on');

bp16_r = b_pos16(:)'; bpsp_r = b_pos_sp(:)'; bn6_r = b_neg6(:)'; bnsp_r = b_neg_sp(:)';
if enable_arts
    leg_handles = [bp16_r(1:4), bpsp_r(5), bp16_r(6:12), bn6_r(1:2), bnsp_r(3), bn6_r(4:6), h_ov1, h_ov2, h_ov2E, h_ov3, h_ov4, h_ov5, h_ov6];
else
    leg_handles = [bp16_r(1:4), bpsp_r(5), bp16_r(6:12), bn6_r(1:2), bnsp_r(3), bn6_r(4:5), h_ov1, h_ov2, h_ov3, h_ov4, h_ov5, h_ov6];
end
legend(axM, leg_handles, 'Location', 'northwest', 'FontSize', 5.6, 'NumColumns', 2);

f_mir_out = fullfile(OutputDir, sprintf('Fig_11Layer_Welfare_And_MirrorInvestments_%s.png', Reg_File_Suffix));
exportgraphics(fig_mir, f_mir_out, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Split-Column + Hatched Arts Cap Mirror-Image Figure (%s) to: %s\n', r_sel, f_mir_out);

Out = struct();
Out.Table19_Counterfactuals   = L.Table19;
Out.Table19E_ArtsEnabled      = L.Table19E;
Out.Table20_MirrorInvestments = L.Table20;
Out.Fig_Counterfactuals       = f_cf_out;
Out.Fig_MirrorInvestments     = f_mir_out;
end

function local_hatch_stacked_caps(ax, x_centers, bar_w, y_base_vec, cap_mat_4xN, dx_step, slope_yx, line_col)
n_bars = numel(x_centers);
half_w = 0.5 * bar_w;
xs_all = [];
ys_all = [];
for b = 1:n_bars
    yb = y_base_vec(b);
    yt = yb + sum(cap_mat_4xN(:, b));
    if yt - yb <= 0.05, continue; end
    xl = x_centers(b) - half_w;
    xr = x_centers(b) + half_w;
    c_min = yb - slope_yx * bar_w;
    c_max = yt;
    for c0 = c_min : (dx_step * slope_yx) : c_max
        x0 = xl; y0 = c0;
        x1 = xr; y1 = c0 + slope_yx * bar_w;
        if y0 < yb
            x0 = xl + (yb - c0) / slope_yx;
            y0 = yb;
        end
        if y1 > yt
            x1 = xl + (yt - c0) / slope_yx;
            y1 = yt;
        end
        if x1 > x0 && y1 >= yb && y0 <= yt
            xs_all = [xs_all, x0, x1, NaN]; %#ok<AGROW>
            ys_all = [ys_all, y0, y1, NaN]; %#ok<AGROW>
        end
    end
end
if ~isempty(xs_all)
    plot(ax, xs_all, ys_all, '-', 'Color', line_col, 'LineWidth', 0.65, 'HandleVisibility', 'off');
end
end

function local_hatch_band(ax, x_grid, y_low, y_high, x_spacing, slope_yx, line_col)
x_min  = min(x_grid);
x_max  = max(x_grid);
c_min  = min(y_low) - slope_yx * (x_max - x_min);
c_max  = max(y_high);
x_fine = linspace(x_min, x_max, 280)';
yl_f   = interp1(x_grid, y_low,  x_fine, 'linear');
yh_f   = interp1(x_grid, y_high, x_fine, 'linear');
xs_all = [];
ys_all = [];
for c0 = c_min : (x_spacing * slope_yx) : c_max
    y_line = c0 + slope_yx * (x_fine - x_min);
    in_msk = (y_line >= yl_f) & (y_line <= yh_f) & ((yh_f - yl_f) > 0.08);
    if any(in_msk)
        x_seg = x_fine; y_seg = y_line;
        x_seg(~in_msk) = NaN; y_seg(~in_msk) = NaN;
        xs_all = [xs_all; x_seg; NaN]; %#ok<AGROW>
        ys_all = [ys_all; y_seg; NaN]; %#ok<AGROW>
    end
end
if ~isempty(xs_all)
    plot(ax, xs_all, ys_all, '-', 'Color', line_col, 'LineWidth', 0.55, 'HandleVisibility', 'off');
end
end
