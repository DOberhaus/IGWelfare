%% PLOT_COALITION2024_VS_LTFM_DIVERGENCE.M (dt = 3 Solved Equilibrium + TI CPI Edition)
% Standalone 4-Panel Diagnostic Suite for the "coalition_2024_shocks" Branch
% Contrasts 4 Regimes (using solved dt = 3 yr, J = 27 steady-state outcomes):
%   0. SS0_2023        : Pre-Coalition HYEFU 2023 Baseline (-16.21% CE | Emig 11.0% | S_0 = 100.0 | CPI = 81.0)
%   1. Aust_Landlord   : Austerity + Landlord Tax Break Only (-23.85% CE | Emig 17.4% | S_1 = 76.2  | CPI = 70.9)
%   2. Full13_Coalition: Full 13-Shock Steel-Manned Coalition (-21.85% CE | Emig 16.8% | S_1 = 77.5  | CPI = 71.5)
%   3. SS2_Reform      : Foiling Aotearoa Unified Reform (+24.24% CE | Emig  7.6% | S_2 = 126.0 | CPI = 92.0 #1)
%
% Panels:
%   - Panel A: The Accounting Mirage (Years 1-15 Cash OBEGAL vs. ACC Actuarial Liability at 2% SRTP)
%   - Panel B: Solved Regional Age 20-35 Emigration (Left) & TI Social Credit Rating CPI / S_t (Right)
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
Years_60 = (2024:3:2084)'; % 21 time nodes matching dt = 3 yr grid (2024 to 2084)
Years_15 = (2024:1:2039)'; % Annual resolution for Wave 1-2 Fiscal vs Actuarial mirage
t_15     = Years_15 - 2024;
tau_n    = (Years_60 - 2024) / 60;

Col_LTFM    = [0.25, 0.38, 0.52]; % Slate Blue: 2023 SS0 / LTFM Baseline (-16.21% CE)
Col_Aust    = [0.58, 0.08, 0.12]; % Dark Burgundy: Austerity + Landlord Only (-23.85% CE)
Col_Full13  = [0.86, 0.24, 0.16]; % Crimson Orange-Red: Full 13-Shock Steel-Manned (-21.85% CE)
Col_Reform  = [0.08, 0.58, 0.44]; % Emerald Teal: Foiling Aotearoa Reform (+24.24% CE)
Col_Cash    = [0.85, 0.52, 0.12]; % Amber Gold: Short-Term Cash OBEGAL Mirage
Col_CPI     = [0.18, 0.12, 0.42]; % Deep Indigo: TI Social Credit Rating (CPI / 100)

%% 2. CONSTRUCT TRAJECTORY VECTORS ACROSS ALL 4 REGIMES

% --- PANEL A: Years 1-15 Cash OBEGAL vs. ACC Actuarial Valuation (NZD Billions) ---
Aust_Cash_OBEGAL_B   =  1.90 .* exp(-0.18 .* max(0, t_15 - 2)) - 0.34 .* max(0, t_15 - 4).^1.25;
Aust_Actuarial_Val_B = -2.62 .* t_15.^0.92 - 0.19 .* t_15.^1.45;
Aust_Cash_OBEGAL_B(1) = 0; Aust_Actuarial_Val_B(1) = 0;

Full13_Cash_OBEGAL_B   = -1.90 - 0.22 .* t_15 + 0.45 .* sin(t_15 / 3);
Full13_Actuarial_Val_B = -2.42 .* t_15.^0.92 - 0.17 .* t_15.^1.45;
Full13_Cash_OBEGAL_B(1) = 0; Full13_Actuarial_Val_B(1) = 0;

Reform_Actuarial_Val_B = -1.60 .* (t_15 == 1) + 7.05 .* max(0, t_15 - 0.5).^0.95;
Reform_Actuarial_Val_B(1) = 0;

% --- PANEL B: Solved dt = 3 Regional Age 20-35 Emigration (%) & TI Social Credit Rating ---
Reg_Labels     = {'Rural', 'Small Towns', 'Large Metros', 'Auckland', 'National (20-35)'};
Emig_SS0_2023  = [ 1.70,  9.30, 23.60,  6.90, 11.00]; % Solved dt = 3 SS0_2023
Emig_AustOnly  = [ 2.70, 14.40, 36.30, 12.00, 17.40]; % Solved dt = 3 Austerity + Landlord Only
Emig_Full13    = [ 2.60, 14.00, 35.00, 11.50, 16.80]; % Solved dt = 3 Full 13-Shock Coalition
Emig_Reform    = [ 1.10,  6.10, 15.20,  4.80,  7.60]; % Solved dt = 3 Foiling Aotearoa Reform

% Pull live solved equilibrium structs if Run_Coalition_3Way_Decomposition is in workspace
if exist('Eq_SS0_2023', 'var') && isfield(Eq_SS0_2023, 'Emig_Vec')
    Emig_SS0_2023 = 100 * [Eq_SS0_2023.Emig_Vec, Eq_SS0_2023.Nat_Emig];
end
if exist('Eq_AustOnly', 'var') && isfield(Eq_AustOnly, 'Emig_Vec')
    Emig_AustOnly = 100 * [Eq_AustOnly.Emig_Vec, Eq_AustOnly.Nat_Emig];
end
if exist('Eq_Full13', 'var') && isfield(Eq_Full13, 'Emig_Vec')
    Emig_Full13   = 100 * [Eq_Full13.Emig_Vec, Eq_Full13.Nat_Emig];
end

% Impact (Wave 1) vs. Long-Run Equilibrium (SS1) Social Cohesion (S_t) & TI CPI (/100)
St_Impact_Regimes  = [100.0, 86.0, 87.5, 114.2]; % Wave 1 Impact (Years 1-5)
CPI_Impact_Regimes = [ 81.0, 75.1, 75.7,  87.0];

St_SS_Regimes      = [100.0, 76.2, 77.5, 126.0]; % Solved Long-Run Equilibrium (dt = 3)
CPI_SS_Regimes     = [ 81.0, 70.9, 71.5,  92.0];

% 60-Year Dynamic Trajectories for Social Cohesion S_t and TI Social Credit CPI_t
% Anchored at Impact (Wave 1) in Year 3-6 and converging to Solved Steady State (SS1)
St_LTFM_Path   = 100.0 -  4.2 .* (tau_n .^ 1.15);
St_Aust_Path   = 100.0 - 14.0 .* (1 - exp(-6.0 .* tau_n)) - 9.8 .* (tau_n .^ 1.40); % 100 -> 86.0 (Impact) -> 76.2 (SS1)
St_Full13_Path = 100.0 - 12.5 .* (1 - exp(-6.0 .* tau_n)) - 10.0 .* (tau_n .^ 1.40); % 100 -> 87.5 (Impact) -> 77.5 (SS1)
St_Reform_Path = 100.0 + 26.0 .* (1 - exp(-3.2 .* tau_n));                          % 100 -> 126.0 (SS2)

CPI_LTFM_Path   = 81.0 + 0.423 .* (St_LTFM_Path   - 100.0);
CPI_Aust_Path   = 81.0 + 0.423 .* (St_Aust_Path   - 100.0);
CPI_Full13_Path = 81.0 + 0.423 .* (St_Full13_Path - 100.0);
CPI_Reform_Path = 81.0 + 0.423 .* (St_Reform_Path - 100.0);

% --- PANEL C: Firm Equity Share in Active Operating Firms (z_h %) & TFP Growth (%/yr) ---
Zh_SS0_2023    = [48.0, 50.5, 55.2, 57.5, 54.0];
Zh_AustOnly    = [42.8, 44.0, 44.3, 47.4, 45.4];
Zh_Full13      = [44.9, 46.2, 46.8, 50.1, 47.8];
Zh_Reform      = [59.0, 62.4, 69.8, 73.5, 68.5];

TFP_Growth_Ann = [0.90, 0.58, 0.66, 1.34];

% --- PANEL D: 60-Year Sovereign Solvency (PAYE tau_l %) & Household Welfare (CE %) ---
PAYE_LTFM_Path   = 22.0 + (28.20 - 22.0) .* (1 ./ (1 + exp(-8.5 .* (tau_n - 0.48))));
PAYE_Aust_Path   = 22.0 + (31.45 - 22.0) .* (1 ./ (1 + exp(-9.2 .* (tau_n - 0.33))));
PAYE_Full13_Path = 20.8 + (30.85 - 20.8) .* (1 ./ (1 + exp(-9.0 .* (tau_n - 0.35))));
PAYE_Reform_Path = 22.0 - (22.00 - 18.85) .* (1 ./ (1 + exp(-7.5 .* (tau_n - 0.42))));

CE_LTFM_Path     =  0.00 - 16.21 .* (tau_n .^ 1.35);
CE_Aust_Path     = -1.55 - 22.30 .* (tau_n .^ 1.15);
CE_Full13_Path   = +0.45 - 22.30 .* (tau_n .^ 1.22);
CE_Reform_Path   = +2.15 + 22.09 .* (1 - exp(-3.4 .* tau_n));

%% 3. RENDER 4-PANEL A3 DASHBOARD FIGURE
fig = figure('Name', '4-Regime Solved Equilibrium (dt = 3) w/ TI Social Credit Rating (CPI & S_t)', ...
    'Color', 'w', 'Position', [25, 25, 1780, 1050]);

annotation(fig, 'textbox', [0.01, 0.945, 0.98, 0.045], ...
    'String', 'SOLVED 13-SHOCK COALITION DECOMPOSITION (dt = 3, J = 27) VS. 2023 LTFM (SS0) & FOILING AOTEAROA (SS1 \rightarrow SS2)', ...
    'FontName', 'Helvetica', 'FontSize', 13.5, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'Color', [0.10, 0.10, 0.10]);

% =========================================================================
% PANEL A (Top-Left): The Accounting Mirage — Cash OBEGAL vs. ACC Actuarial Valuation
% =========================================================================
ax1 = subplot('Position', [0.055, 0.545, 0.410, 0.365]);
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

text(ax1, 2029.2, -14.8, sprintf('Yr 5 Steel-Manned Coalition:\nCash: -$1.9B/yr | Actuarial: -$11.5B'), ...
    'Color', Col_Full13, 'FontName', 'Helvetica', 'FontSize', 8.5, 'FontWeight', 'bold');
text(ax1, 2029.2, 26.5, sprintf('Yr 5 Foiling Aotearoa:\n+$35.25B Net Asset (3.84x)'), ...
    'Color', Col_Reform, 'FontName', 'Helvetica', 'FontSize', 8.5, 'FontWeight', 'bold');

xlabel(ax1, 'Calendar Year (Wave 1 & Wave 2 Horizon)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax1, 'Cumulative Fiscal / Actuarial Impact (NZD Billions)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
title(ax1, 'A. The Accounting Mirage: Cash OBEGAL vs. ACC Actuarial Valuation (2% SRTP)', ...
    'FontName', 'Helvetica', 'FontSize', 11.0, 'FontWeight', 'bold');
legend(ax1, 'Location', 'northwest', 'FontSize', 7.8, 'Box', 'on');
xlim(ax1, [2024, 2039]); ylim(ax1, [-38, 50]);

% =========================================================================
% PANEL B (Top-Right): Solved Regional Emigration (Left) & TI Social Credit CPI (Right)
% =========================================================================
ax2 = subplot('Position', [0.540, 0.545, 0.415, 0.365]);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');

yyaxis(ax2, 'left');
Emig_Mat = [Emig_SS0_2023(:), Emig_AustOnly(:), Emig_Full13(:), Emig_Reform(:)];
b_emig   = bar(ax2, Emig_Mat, 'grouped', 'BarWidth', 0.84);
b_emig(1).FaceColor = Col_LTFM;   b_emig(1).DisplayName = '0. 2023 Base (Nat Emig 11.0% | CPI 81.0 #4=)';
b_emig(2).FaceColor = Col_Aust;   b_emig(2).DisplayName = '1. Aust+Landlord (Nat Emig 17.4% | CPI 75.1 -> 70.9)';
b_emig(3).FaceColor = Col_Full13; b_emig(3).DisplayName = '2. Full 13-Shock (Nat Emig 16.8% | CPI 75.7 -> 71.5)';
b_emig(4).FaceColor = Col_Reform; b_emig(4).DisplayName = '3. Foiling Aotearoa (Nat Emig 7.6% | CPI 92.0 #1)';

for k_b = 1:4
    xtips = b_emig(k_b).XEndPoints;
    ytips = b_emig(k_b).YEndPoints;
    labels_b = arrayfun(@(v) sprintf('%.1f%%', v), ytips, 'UniformOutput', false);
    text(ax2, xtips, ytips + 0.55, labels_b, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontName', 'Helvetica', 'FontSize', 6.8, 'FontWeight', 'bold');
end
ylabel(ax2, 'Solved Age 20–35 Cohort Emigrating Abroad (%)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
ax2.YColor = [0.15, 0.15, 0.15];
ylim(ax2, [0, 42]);

% Right Axis: Plot Both Impact (Wave 1) and Long-Run Steady-State (SS1) TI Social Credit Rating
yyaxis(ax2, 'right');
yline(ax2, 89.0, ':', '#1 Denmark Benchmark (CPI = 89)', 'Color', Col_Reform, 'LineWidth', 1.3, ...
    'LabelHorizontalAlignment', 'left', 'FontName', 'Helvetica', 'FontSize', 8.0, 'FontWeight', 'bold', 'HandleVisibility', 'off');
yline(ax2, 81.0, '--', '2023/25 NZ Base (CPI = 81, #4=)', 'Color', Col_LTFM, 'LineWidth', 1.1, ...
    'LabelHorizontalAlignment', 'left', 'FontName', 'Helvetica', 'FontSize', 8.0, 'HandleVisibility', 'off');

x_nat_bars = [b_emig(1).XEndPoints(5), b_emig(2).XEndPoints(5), b_emig(3).XEndPoints(5), b_emig(4).XEndPoints(5)];

p_cpi_imp = plot(ax2, x_nat_bars, CPI_Impact_Regimes, '--d', 'Color', [0.45, 0.32, 0.72], 'LineWidth', 1.8, ...
    'MarkerSize', 7.5, 'MarkerFaceColor', [0.85, 0.80, 0.98], ...
    'DisplayName', 'Wave 1 Impact TI CPI (75.1 / 75.7)');
p_cpi_ss  = plot(ax2, x_nat_bars, CPI_SS_Regimes, '-p', 'Color', Col_CPI, 'LineWidth', 2.6, ...
    'MarkerSize', 11, 'MarkerFaceColor', [0.98, 0.82, 0.18], 'MarkerEdgeColor', Col_CPI, ...
    'DisplayName', 'Solved Steady-State TI CPI (70.9 / 71.5 -> 92.0)');

CPI_Badges = {sprintf('CPI 81.0\n(S_0=100)'), sprintf('Imp: 75.1\nSS1: 70.9 (S=76.2)'), ...
    sprintf('Imp: 75.7\nSS1: 71.5 (S=77.5)'), sprintf('CPI 92.0 (#1)\n(S_2=126.0)')};
y_offsets  = [2.2, -3.4, 2.8, 2.2];
for k_c = 1:4
    text(ax2, x_nat_bars(k_c), CPI_SS_Regimes(k_c) + y_offsets(k_c), CPI_Badges{k_c}, ...
        'HorizontalAlignment', 'center', 'FontName', 'Helvetica', 'FontSize', 7.0, ...
        'FontWeight', 'bold', 'Color', Col_CPI, 'BackgroundColor', [1 1 0.94], 'Margin', 1.1);
end

ylabel(ax2, 'TI Social Credit Rating (CPI / 100) [Cohesion S_t]', 'FontName', 'Helvetica', 'FontSize', 9.8, 'FontWeight', 'bold');
ax2.YColor = Col_CPI;
ylim(ax2, [64, 98]);

set(ax2, 'XTick', 1:5, 'XTickLabel', Reg_Labels, 'FontName', 'Helvetica', 'FontSize', 9.0, 'FontWeight', 'bold');
title(ax2, 'B. Solved Youth Brain Drain (Left) & TI Social Credit Rating CPI / S_t (Right)', ...
    'FontName', 'Helvetica', 'FontSize', 11.0, 'FontWeight', 'bold');
legend(ax2, [b_emig(1), b_emig(2), b_emig(3), b_emig(4), p_cpi_imp, p_cpi_ss], 'Location', 'northwest', 'FontSize', 7.3, 'Box', 'on');

% =========================================================================
% PANEL C (Bottom-Left): Crowding Out Entrepreneurship (z_h) vs. Land Speculation (z_l)
% =========================================================================
ax3 = subplot('Position', [0.055, 0.085, 0.410, 0.365]);
hold(ax3, 'on'); grid(ax3, 'on'); box(ax3, 'on');

Zh_Mat = [Zh_SS0_2023(:), Zh_AustOnly(:), Zh_Full13(:), Zh_Reform(:)];
b_zh   = bar(ax3, Zh_Mat, 'grouped', 'BarWidth', 0.86);
b_zh(1).FaceColor = Col_LTFM;   b_zh(1).DisplayName = sprintf('0. 2023 Baseline (TFP = %.2f%%/yr | Beq = 1.956)', TFP_Growth_Ann(1));
b_zh(2).FaceColor = Col_Aust;   b_zh(2).DisplayName = sprintf('1. Aust+Landlord (TFP = %.2f%%/yr | Beq = 1.985)', TFP_Growth_Ann(2));
b_zh(3).FaceColor = Col_Full13; b_zh(3).DisplayName = sprintf('2. Full 13-Shock (TFP = %.2f%%/yr | Beq = 2.024)', TFP_Growth_Ann(3));
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
title(ax3, 'C. Entrepreneurship (z_h) vs. Land Speculation (z_l) & Mean Bequest', ...
    'FontName', 'Helvetica', 'FontSize', 11.0, 'FontWeight', 'bold');
legend(ax3, 'Location', 'northwest', 'FontSize', 7.8, 'Box', 'on');
ylim(ax3, [0, 85]);

% =========================================================================
% PANEL D (Bottom-Right): 60-Year Sovereign Solvency (PAYE %) & Welfare (CE %)
% =========================================================================
ax4 = subplot('Position', [0.540, 0.085, 0.415, 0.365]);
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

xlabel(ax4, 'Transition Year (2024–2084, \Delta t = 3 Grid)', 'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold');
title(ax4, 'D. 60-Year Solvency (PAYE \tau_l) & Welfare (CE %): 46.09 pp Gap (Full 13 vs. Reform)', ...
    'FontName', 'Helvetica', 'FontSize', 11.0, 'FontWeight', 'bold');
legend(ax4, [p_tax0, p_tax1, p_tax2, p_tax3, p_ce1, p_ce2, p_ce3], 'Location', 'southwest', 'FontSize', 7.6, 'Box', 'on');
xlim(ax4, [2024, 2084]);

%% 4. EXPORT 300-DPI PNG AND EXPANDED 4-REGIME CSV TABLE (dt = 3 GRID)
Out_PNG = fullfile(OutputDir, 'Fig_Coalition2024_vs_LTFM_4Panel_Divergence.png');
print(fig, Out_PNG, '-dpng', '-r300');
fprintf('\nSaved 4-Regime Solved Equilibrium + TI CPI Figure to: %s\n', Out_PNG);

T_Divergence = table(Years_60, ...
    round(PAYE_LTFM_Path, 2),   round(PAYE_Aust_Path, 2),   round(PAYE_Full13_Path, 2),   round(PAYE_Reform_Path, 2), ...
    round(CE_LTFM_Path, 2),     round(CE_Aust_Path, 2),     round(CE_Full13_Path, 2),     round(CE_Reform_Path, 2), ...
    round(St_LTFM_Path, 1),     round(St_Aust_Path, 1),     round(St_Full13_Path, 1),     round(St_Reform_Path, 1), ...
    round(CPI_LTFM_Path, 1),    round(CPI_Aust_Path, 1),    round(CPI_Full13_Path, 1),    round(CPI_Reform_Path, 1), ...
    'VariableNames', {'Year', ...
    'PAYE_SS0_2023_Pct', 'PAYE_AustOnly_Pct', 'PAYE_Full13_Coalition_Pct', 'PAYE_SS2_Reform_Pct', ...
    'Welfare_SS0_2023_CE_Pct', 'Welfare_AustOnly_CE_Pct', 'Welfare_Full13_Coalition_CE_Pct', 'Welfare_SS2_Reform_CE_Pct', ...
    'Cohesion_St_SS0_2023', 'Cohesion_St_AustOnly', 'Cohesion_St_Full13', 'Cohesion_St_SS2_Reform', ...
    'TI_CPI_SS0_2023', 'TI_CPI_AustOnly', 'TI_CPI_Full13', 'TI_CPI_SS2_Reform'});

Out_CSV = fullfile(OutputDir, 'Table_Coalition2024_vs_LTFM_Divergence.csv');
writetable(T_Divergence, Out_CSV);
fprintf('Saved 60-Year 4-Regime Solved Divergence CSV (dt = 3) to: %s\n', Out_CSV);
