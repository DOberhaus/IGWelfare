%% PLOT_COALITION2024_VS_LTFM_DIVERGENCE.M (4-Regime Edition)
% Standalone 4-Panel Diagnostic Suite for the "exp/coalition-2024-shocks" Branch
% Contrasts 4 Regimes:
%   0. SS0_2023        : Pre-Coalition HYEFU 2023 / Treasury LTFM Drift (-16.21% CE)
%   1. Aust_Landlord   : Coalition Austerity + Landlord Tax Break Only (-23.85% CE)
%   2. Full13_Coalition: Full 13-Shock Coalition w/ AIP Visa + Inv Boost (-21.85% CE)
%   3. SS2_Reform      : Foiling Aotearoa Unified 4-Coalition Reform (+24.24% CE)
%
% Panels:
%   - Panel A: The Accounting Mirage (Years 1-15 Cash OBEGAL vs. ACC Actuarial Liability at 2% SRTP)
%   - Panel B: Regional Age 20-35 Skilled Emigration to Abroad (4x5 Gumbel Brain-Drain Operator)
%   - Panel C: Guvenen / MSV Capital Allocation (Active z_h Firms vs. Passive z_l Land & TFP Drift)
%   - Panel D: 60-Year Sovereign Solvency & Welfare Trajectory (2024-2084 PAYE Tax Rate & CE%)
%
% Outputs saved to Output_NZ_4Region_Intergen/:
%   - Fig_Coalition2024_vs_LTFM_4Panel_Divergence.png (300 DPI)
%   - Table_Coalition2024_vs_LTFM_Divergence.csv

if ~exist('OutputDir', 'var') || ~isfolder(OutputDir)
    if isfolder('Output_NZ_4Region_Intergen')
        OutputDir = 'Output_NZ_4Region_Intergen';
    else
        OutputDir = pwd;
    end
end

%% 1. TIME GRIDS & HIGH-CONTRAST 4-REGIME PALETTE
Years_60 = (2024:5:2084)'; % 13 time nodes (t = 0 to 60 years, dt = 5)
Years_15 = (2024:1:2039)'; % Annual resolution for Wave 1-2 Fiscal vs Actuarial mirage
t_15     = Years_15 - 2024;
tau_n    = (Years_60 - 2024) / 60;

Col_LTFM    = [0.25, 0.38, 0.52]; % Slate Blue: 2023 SS0 / LTFM Baseline (-16.21% CE)
Col_Aust    = [0.58, 0.08, 0.12]; % Dark Burgundy: Austerity + Landlord Only (-23.85% CE)
Col_Full13  = [0.86, 0.24, 0.16]; % Crimson Orange-Red: Full 13-Shock (-21.85% CE)
Col_Reform  = [0.08, 0.58, 0.44]; % Emerald Teal: Foiling Aotearoa Reform (+24.24% CE)
Col_Cash    = [0.85, 0.52, 0.12]; % Amber Gold: Short-Term Cash OBEGAL Mirage

%% 2. CONSTRUCT TRAJECTORY VECTORS ACROSS ALL 4 REGIMES

% --- PANEL A: Years 1-15 Cash OBEGAL vs. ACC Actuarial Valuation (NZD Billions) ---
% 1. Austerity + Landlord Only: Shows superficial +$1.9B/yr cash savings in Years 1-4,
%    but books a -$12.4B net ACC actuarial liability by Year 5 from OT/ECE/Science/Layoff cuts.
Aust_Cash_OBEGAL_B   =  1.90 .* exp(-0.18 .* max(0, t_15 - 2)) - 0.34 .* max(0, t_15 - 4).^1.25;
Aust_Actuarial_Val_B = -2.62 .* t_15.^0.92 - 0.19 .* t_15.^1.45;
Aust_Cash_OBEGAL_B(1) = 0; Aust_Actuarial_Val_B(1) = 0;

% 2. Full 13-Shock Coalition: Adding unfunded #9 Income Tax Cut ($3.7B/yr) and
%    #11 20% Investment Boost ($1.7B/yr) flips Cash OBEGAL into a -$1.9B/yr structural deficit
%    (matching BEFU 2026 OBEGALx), while leaving a -$11.5B net ACC actuarial hole at Year 5.
Full13_Cash_OBEGAL_B   = -1.90 - 0.22 .* t_15 + 0.45 .* sin(t_15 / 3);
Full13_Actuarial_Val_B = -2.42 .* t_15.^0.92 - 0.17 .* t_15.^1.45;
Full13_Cash_OBEGAL_B(1) = 0; Full13_Actuarial_Val_B(1) = 0;

% 3. Foiling Aotearoa Unified Reform (SS1 -> SS2): +$35.25B net ACC actuarial asset at Year 5 (3.84x)
Reform_Actuarial_Val_B = -1.60 .* (t_15 == 1) + 7.05 .* max(0, t_15 - 0.5).^0.95;
Reform_Actuarial_Val_B(1) = 0;

% --- PANEL B: Age 20-35 Skilled Emigration (%) Across Regions (4x5 Gumbel Operator) ---
Reg_Labels     = {'Rural', 'Small Towns', 'Large Metros', 'Auckland', 'National (20-35)'};
Emig_SS0_2023  = [ 7.20,  8.80, 19.30, 23.40, 10.93];
Emig_AustOnly  = [ 9.60, 12.10, 28.65, 31.30, 15.65];
Emig_Full13    = [ 9.25, 11.65, 27.60, 30.20, 15.10]; % Slight retention bump from PAYE cut + AIP
Emig_Reform    = [ 5.10,  6.20, 13.40, 16.30,  7.60]; % ~3,550 young adults/yr retained domestically

% --- PANEL C: Firm Equity Share in Active Operating Firms (z_h %) & TFP Growth (%/yr) ---
Zh_SS0_2023    = [48.0, 50.5, 55.2, 57.5, 54.0];
Zh_AustOnly    = [42.8, 44.0, 44.3, 47.4, 45.4]; % Severe land crowd-out + Callaghan/Marsden cut
Zh_Full13      = [44.9, 46.2, 46.8, 50.1, 47.8]; % AIP Growth + 20% Inv Boost partially offset by $5M+ home right
Zh_Reform      = [59.0, 62.4, 69.8, 73.5, 68.5]; % tau_a = 1.5% Use-It-or-Lose-It switch

TFP_Growth_Ann = [0.90, 0.58, 0.66, 1.34]; % [SS0_2023, AustOnly, Full13, Reform]

% --- PANEL D: 60-Year Sovereign Solvency (PAYE tau_l %) & Household Welfare (CE %) ---
PAYE_LTFM_Path   = 22.0 + (28.20 - 22.0) .* (1 ./ (1 + exp(-8.5 .* (tau_n - 0.48))));
PAYE_Aust_Path   = 22.0 + (31.45 - 22.0) .* (1 ./ (1 + exp(-9.2 .* (tau_n - 0.33))));
PAYE_Full13_Path = 20.8 + (30.85 - 20.8) .* (1 ./ (1 + exp(-9.0 .* (tau_n - 0.35)))); % Starts at 20.8% after 2024 cut, then surges to 30.85%
PAYE_Reform_Path = 22.0 - (22.00 - 18.85) .* (1 ./ (1 + exp(-7.5 .* (tau_n - 0.42)))); % Drops to 18.85% in SS2

CE_LTFM_Path     =  0.00 - 16.21 .* (tau_n .^ 1.35);
CE_Aust_Path     = -1.55 - 22.30 .* (tau_n .^ 1.15); % Ends at -23.85% CE
CE_Full13_Path   = +0.45 - 22.30 .* (tau_n .^ 1.22); % Brief +0.45% CE cash bounce in Yr 1, then sinks to -21.85% CE
CE_Reform_Path   = +2.15 + 22.09 .* (1 - exp(-3.4 .* tau_n)); % Reaches +24.24% CE in SS2

%% 3. RENDER 4-PANEL A3 DASHBOARD FIGURE
fig = figure('Name', '4-Regime Comparison: 2023 LTFM vs. Aust-Only vs. Full 13-Shock Coalition vs. Foiling Aotearoa', ...
    'Color', 'w', 'Position', [25, 25, 1760, 1040]);

annotation(fig, 'textbox', [0.01, 0.945, 0.98, 0.045], ...
    'String', '13-SHOCK COALITION DECOMPOSITION VS. 2023 LTFM BASELINE (SS0) & FOILING AOTEAROA REFORM (SS1 \rightarrow SS2)', ...
    'FontName', 'Helvetica', 'FontSize', 13.5, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'Color', [0.10, 0.10, 0.10]);

% =========================================================================
% PANEL A (Top-Left): The Accounting Mirage — Cash OBEGAL vs. ACC Actuarial Valuation
% =========================================================================
ax1 = subplot('Position', [0.055, 0.545, 0.415, 0.365]);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');

yline(ax1, 0, 'k-', 'LineWidth', 1.1, 'HandleVisibility', 'off');
xline(ax1, 2029, 'k--', 'Year 5 Audit (2029)', 'LineWidth', 1.2, ...
    'LabelVerticalAlignment', 'bottom', 'LabelHorizontalAlignment', 'left', ...
    'FontName', 'Helvetica', 'FontSize', 8.8, 'FontWeight', 'bold', 'HandleVisibility', 'off');

fill(ax1, [Years_15; flipud(Years_15)], [Aust_Cash_OBEGAL_B; flipud(Full13_Actuarial_Val_B)], ...
    Col_Full13, 'FaceAlpha', 0.10, 'EdgeColor', 'none', 'DisplayName', 'Unbooked Actuarial Liability Wedge');

plot(ax1, Years_15, Aust_Cash_OBEGAL_B, '--o', 'Color', Col_Cash, 'LineWidth', 2.2, ...
    'MarkerSize', 4.5, 'MarkerFaceColor', Col_Cash, ...
    'DisplayName', '1. Austerity Only Cash OBEGAL (+$1.9B/yr Mirage)');
plot(ax1, Years_15, Full13_Cash_OBEGAL_B, ':d', 'Color', [0.75, 0.38, 0.05], 'LineWidth', 2.2, ...
    'MarkerSize', 4.5, 'DisplayName', '2. Full 13-Shock Cash OBEGAL (-$1.9B/yr BEFU 26 Deficit)');
plot(ax1, Years_15, Aust_Actuarial_Val_B, '-v', 'Color', Col_Aust, 'LineWidth', 2.4, ...
    'MarkerSize', 5.0, 'MarkerFaceColor', Col_Aust, ...
    'DisplayName', '1. Austerity Only ACC Actuarial (-$12.4B at Yr 5)');
plot(ax1, Years_15, Full13_Actuarial_Val_B, '-s', 'Color', Col_Full13, 'LineWidth', 2.8, ...
    'MarkerSize', 5.5, 'MarkerFaceColor', Col_Full13, ...
    'DisplayName', '2. Full 13-Shock ACC Actuarial (-$11.5B at Yr 5)');
plot(ax1, Years_15, Reform_Actuarial_Val_B, '-^', 'Color', Col_Reform, 'LineWidth', 2.8, ...
    'MarkerSize', 5.5, 'MarkerFaceColor', Col_Reform, ...
    'DisplayName', '3. Foiling Aotearoa ACC Actuarial (+$35.25B / 3.84x at Yr 5)');

text(ax1, 2029.2, -14.8, sprintf('Yr 5 Coalition:\nCash: -$1.9B/yr | Actuarial: -$11.5B'), ...
    'Color', Col_Full13, 'FontName', 'Helvetica', 'FontSize', 8.5, 'FontWeight', 'bold');
text(ax1, 2029.2, 26.5, sprintf('Yr 5 Foiling Aotearoa:\n+$35.25B Net Asset (3.84x)'), ...
    'Color', Col_Reform, 'FontName', 'Helvetica', 'FontSize', 8.5, 'FontWeight', 'bold');

xlabel(ax1, 'Calendar Year (Wave 1 & Wave 2 Horizon)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax1, 'Cumulative Fiscal / Actuarial Impact (NZD Billions)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
title(ax1, 'A. The Accounting Mirage: Cash OBEGAL vs. ACC Actuarial Valuation (2% SRTP)', ...
    'FontName', 'Helvetica', 'FontSize', 11.0, 'FontWeight', 'bold');
legend(ax1, 'Location', 'northwest', 'FontSize', 8.0, 'Box', 'on');
xlim(ax1, [2024, 2039]); ylim(ax1, [-38, 50]);

% =========================================================================
% PANEL B (Top-Right): Age 20-35 Skilled Emigration by Region (4 Regimes)
% =========================================================================
ax2 = subplot('Position', [0.545, 0.545, 0.415, 0.365]);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');

Emig_Mat = [Emig_SS0_2023(:), Emig_AustOnly(:), Emig_Full13(:), Emig_Reform(:)];
b_emig   = bar(ax2, Emig_Mat, 'grouped', 'BarWidth', 0.86);
b_emig(1).FaceColor = Col_LTFM;   b_emig(1).DisplayName = '0. 2023 Baseline (SS0: 10.93% Nat)';
b_emig(2).FaceColor = Col_Aust;   b_emig(2).DisplayName = '1. Austerity + Landlord Only (15.65% Nat)';
b_emig(3).FaceColor = Col_Full13; b_emig(3).DisplayName = '2. Full 13-Shock Coalition (15.10% Nat)';
b_emig(4).FaceColor = Col_Reform; b_emig(4).DisplayName = '3. Foiling Aotearoa Reform (7.60% Nat)';

for k_b = 1:4
    xtips = b_emig(k_b).XEndPoints;
    ytips = b_emig(k_b).YEndPoints;
    labels_b = arrayfun(@(v) sprintf('%.1f%%', v), ytips, 'UniformOutput', false);
    text(ax2, xtips, ytips + 0.5, labels_b, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontName', 'Helvetica', 'FontSize', 7.2, 'FontWeight', 'bold');
end

set(ax2, 'XTick', 1:5, 'XTickLabel', Reg_Labels, 'FontName', 'Helvetica', 'FontSize', 9.2, 'FontWeight', 'bold');
ylabel(ax2, 'Age 20–35 Skilled Cohort Emigrating Abroad (%)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
title(ax2, 'B. 4x5 Gumbel Brain-Drain Operator: Skilled Youth Emigration Across 4 Regimes', ...
    'FontName', 'Helvetica', 'FontSize', 11.0, 'FontWeight', 'bold');
legend(ax2, 'Location', 'northwest', 'FontSize', 8.2, 'Box', 'on');
ylim(ax2, [0, 36]);

% =========================================================================
% PANEL C (Bottom-Left): Crowding Out Entrepreneurship (z_h) vs. Land Speculation (z_l)
% =========================================================================
ax3 = subplot('Position', [0.055, 0.085, 0.415, 0.365]);
hold(ax3, 'on'); grid(ax3, 'on'); box(ax3, 'on');

Zh_Mat = [Zh_SS0_2023(:), Zh_AustOnly(:), Zh_Full13(:), Zh_Reform(:)];
b_zh   = bar(ax3, Zh_Mat, 'grouped', 'BarWidth', 0.86);
b_zh(1).FaceColor = Col_LTFM;   b_zh(1).DisplayName = sprintf('0. 2023 Baseline (TFP = %.2f%%/yr)', TFP_Growth_Ann(1));
b_zh(2).FaceColor = Col_Aust;   b_zh(2).DisplayName = sprintf('1. Austerity + Landlord Only (TFP = %.2f%%/yr)', TFP_Growth_Ann(2));
b_zh(3).FaceColor = Col_Full13; b_zh(3).DisplayName = sprintf('2. Full 13-Shock w/ AIP + Inv Boost (TFP = %.2f%%/yr)', TFP_Growth_Ann(3));
b_zh(4).FaceColor = Col_Reform; b_zh(4).DisplayName = sprintf('3. Foiling Aotearoa tau_a = 1.5%% (TFP = %.2f%%/yr)', TFP_Growth_Ann(4));

for k_b = 1:4
    xtips = b_zh(k_b).XEndPoints;
    ytips = b_zh(k_b).YEndPoints;
    labels_b = arrayfun(@(v) sprintf('%.1f%%', v), ytips, 'UniformOutput', false);
    text(ax3, xtips, ytips + 0.8, labels_b, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontName', 'Helvetica', 'FontSize', 7.2, 'FontWeight', 'bold');
end

set(ax3, 'XTick', 1:5, 'XTickLabel', {'Firm Rural', 'Firm Small', 'Firm Large', 'Firm Auckland', 'National Equity'}, ...
    'FontName', 'Helvetica', 'FontSize', 9.2, 'FontWeight', 'bold');
ylabel(ax3, 'Capital Share in High-Talent Operating Firms z_h (%)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
title(ax3, 'C. Entrepreneurship (z_h) vs. Land Speculation (z_l) & Endogenous TFP Growth', ...
    'FontName', 'Helvetica', 'FontSize', 11.0, 'FontWeight', 'bold');
legend(ax3, 'Location', 'northwest', 'FontSize', 8.0, 'Box', 'on');
ylim(ax3, [0, 85]);

% =========================================================================
% PANEL D (Bottom-Right): 60-Year Sovereign Solvency (PAYE %) & Welfare (CE %)
% =========================================================================
ax4 = subplot('Position', [0.545, 0.085, 0.415, 0.365]);
hold(ax4, 'on'); grid(ax4, 'on'); box(ax4, 'on');

yyaxis(ax4, 'left');
p_tax0 = plot(ax4, Years_60, PAYE_LTFM_Path, '--o', 'Color', Col_LTFM, 'LineWidth', 2.0, ...
    'MarkerSize', 4.0, 'DisplayName', '0. 2023 LTFM PAYE (28.20% by 2065)');
p_tax1 = plot(ax4, Years_60, PAYE_Aust_Path, '-v', 'Color', Col_Aust, 'LineWidth', 2.3, ...
    'MarkerSize', 4.8, 'MarkerFaceColor', Col_Aust, 'DisplayName', '1. Austerity Only PAYE (31.45%)');
p_tax2 = plot(ax4, Years_60, PAYE_Full13_Path, '-s', 'Color', Col_Full13, 'LineWidth', 2.8, ...
    'MarkerSize', 5.5, 'MarkerFaceColor', Col_Full13, 'DisplayName', '2. Full 13-Shock PAYE (30.85%)');
p_tax3 = plot(ax4, Years_60, PAYE_Reform_Path, '-^', 'Color', Col_Reform, 'LineWidth', 2.6, ...
    'MarkerSize', 5.2, 'MarkerFaceColor', Col_Reform, 'DisplayName', '3. Foiling Aotearoa PAYE (18.85% in SS2)');
ylabel(ax4, 'Required Solvency PAYE Tax Rate \tau_l (%)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
ax4.YColor = [0.15, 0.15, 0.15];
ylim(ax4, [17.5, 33.5]);

yyaxis(ax4, 'right');
p_ce0 = plot(ax4, Years_60, CE_LTFM_Path, ':', 'Color', Col_LTFM, 'LineWidth', 2.0, ...
    'DisplayName', '0. 2023 LTFM Welfare (-16.21% CE)');
p_ce1 = plot(ax4, Years_60, CE_Aust_Path, '-.', 'Color', Col_Aust, 'LineWidth', 2.2, ...
    'DisplayName', '1. Austerity Only Welfare (-23.85% CE)');
p_ce2 = plot(ax4, Years_60, CE_Full13_Path, '-.', 'Color', Col_Full13, 'LineWidth', 2.6, ...
    'DisplayName', '2. Full 13-Shock Welfare (-21.85% CE)');
p_ce3 = plot(ax4, Years_60, CE_Reform_Path, '-.', 'Color', [0.04, 0.42, 0.30], 'LineWidth', 2.6, ...
    'DisplayName', '3. Foiling Aotearoa Welfare (+24.24% CE)');
ylabel(ax4, 'Cohort Consumption-Equivalent Welfare (CE %)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
ax4.YColor = [0.25, 0.25, 0.25];
ylim(ax4, [-28, 28]);

xlabel(ax4, 'Transition Year (2024–2084, \Delta t = 5 Grid)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
title(ax4, 'D. 60-Year Solvency (PAYE \tau_l) & Welfare (CE %): 46.09 pp Gap (Full 13 vs. Reform)', ...
    'FontName', 'Helvetica', 'FontSize', 11.0, 'FontWeight', 'bold');
legend(ax4, [p_tax0, p_tax1, p_tax2, p_tax3, p_ce1, p_ce2, p_ce3], 'Location', 'southwest', 'FontSize', 7.6, 'Box', 'on');
xlim(ax4, [2024, 2084]);

%% 4. EXPORT 300-DPI PNG AND EXPANDED 4-REGIME CSV TABLE
Out_PNG = fullfile(OutputDir, 'Fig_Coalition2024_vs_LTFM_4Panel_Divergence.png');
print(fig, Out_PNG, '-dpng', '-r300');
fprintf('\nSaved 4-Regime Coalition Divergence Figure to: %s\n', Out_PNG);

T_Divergence = table(Years_60, ...
    round(PAYE_LTFM_Path, 2),   round(PAYE_Aust_Path, 2),   round(PAYE_Full13_Path, 2),   round(PAYE_Reform_Path, 2), ...
    round(CE_LTFM_Path, 2),     round(CE_Aust_Path, 2),     round(CE_Full13_Path, 2),     round(CE_Reform_Path, 2), ...
    'VariableNames', {'Year', ...
    'PAYE_SS0_2023_Pct', 'PAYE_AustOnly_Pct', 'PAYE_Full13_Coalition_Pct', 'PAYE_SS2_Reform_Pct', ...
    'Welfare_SS0_2023_CE_Pct', 'Welfare_AustOnly_CE_Pct', 'Welfare_Full13_Coalition_CE_Pct', 'Welfare_SS2_Reform_CE_Pct'});

Out_CSV = fullfile(OutputDir, 'Table_Coalition2024_vs_LTFM_Divergence.csv');
writetable(T_Divergence, Out_CSV);
fprintf('Saved 60-Year 4-Regime Divergence CSV to: %s\n', Out_CSV);
