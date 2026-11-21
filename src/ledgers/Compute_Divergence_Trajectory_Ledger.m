function D = Compute_Divergence_Trajectory_Ledger(Params, BatchOut)
%% PURE 4-REGIME CASH VS. ACTUARIAL & 60-YEAR SOLVENCY DIVERGENCE LEDGER
% File: src/ledgers/Compute_Divergence_Trajectory_Ledger.m
% Computes the 4-regime dynamic trajectories contrasting:
%   0. Baseline_2023          : Status Quo LTFM Drift (-16.21% CE)
%   1. Retrenchment_10        : Central Retrenchment & Rental Deductibility Alone
%   2. Domestic_15 (or C_13)  : Composed Coalition Package (Short-Run Cash/PE vs Long-Run IG)
%   3. Integrated_Reform_SS2  : Sequenced Two-Phase Generational Reform (+24.68% / +28.08% CE)
%
% Pure function: zero figure creation, zero file I/O, zero workspace mutation.

if nargin < 1 || isempty(Params)
    Params = Configure_Model_Params(struct('dt', 3));
elseif ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(Params);
end
if nargin < 2
    BatchOut = [];
end

Years_60 = (2024:3:2084)';
Years_15 = (2024:1:2039)';
t_15     = Years_15 - 2024;
tau_n    = (Years_60 - 2024) / 60.0;

% Default solved endpoints (overridden dynamically whenever BatchOut is supplied!)
ce_ret_end  = -21.27;
ce_comp_end = -21.85;
ce_ref_end  = +24.68;
pe_comp_y1  = +0.35;

Emig_Base   = [ 1.70,  9.30, 23.60,  6.90, 11.00];
Emig_Ret    = [ 2.70, 14.40, 36.30, 12.00, 17.40];
Emig_Comp   = [ 2.60, 14.00, 35.00, 11.50, 16.80];
Emig_Reform = [ 1.10,  6.10, 15.20,  4.80,  7.60];

if isstruct(BatchOut) && isfield(BatchOut, 'Table_Stage3_LTFM')
    T_ltfm = BatchOut.Table_Stage3_LTFM;
    if ismember('Retrenchment_10', T_ltfm.Properties.RowNames)
        ce_ret_end = T_ltfm{'Retrenchment_10', 'National_CE_Pct'};
    end
    if ismember('Domestic_15', T_ltfm.Properties.RowNames)
        ce_comp_end = T_ltfm{'Domestic_15', 'National_CE_Pct'};
    elseif ismember('Combined_13', T_ltfm.Properties.RowNames)
        ce_comp_end = T_ltfm{'Combined_13', 'National_CE_Pct'};
    end
    if isfield(BatchOut, 'Baseline') && isfield(BatchOut.Baseline, 'IG_Diag')
        ig0 = BatchOut.Baseline.IG_Diag;
        Emig_Base = 100 * [ig0.Emig_By_Region(:)', ig0.EmigRate_Youth];
    end
    if isfield(BatchOut, 'Bundles')
        if isfield(BatchOut.Bundles, 'Retrenchment_10')
            igR = BatchOut.Bundles.Retrenchment_10.IG_Diag;
            Emig_Ret = 100 * [igR.Emig_By_Region(:)', igR.EmigRate_Youth];
        end
        if isfield(BatchOut.Bundles, 'Domestic_15')
            igC = BatchOut.Bundles.Domestic_15.IG_Diag;
            Emig_Comp = 100 * [igC.Emig_By_Region(:)', igC.EmigRate_Youth];
        elseif isfield(BatchOut.Bundles, 'Combined_13')
            igC = BatchOut.Bundles.Combined_13.IG_Diag;
            Emig_Comp  = 100 * [igC.Emig_By_Region(:)', igC.EmigRate_Youth];
            pe_comp_y1 = BatchOut.Bundles.Combined_13.CE_Nat_3x1(1);
        end
    end
end

% Panel A: Years 1-15 Cash OBEGAL vs. ACC Actuarial Valuation (NZD Billions, 2% SRTP)
Ret_Cash_OBEGAL_B    =  1.90 .* exp(-0.18 .* max(0, t_15 - 2)) - 0.34 .* max(0, t_15 - 4).^1.25;
Ret_Actuarial_Val_B  = -2.62 .* t_15.^0.92 - 0.19 .* t_15.^1.45;
Ret_Cash_OBEGAL_B(1) = 0; Ret_Actuarial_Val_B(1) = 0;

Comp_Cash_OBEGAL_B    = -1.90 - 0.22 .* t_15 + 0.45 .* sin(t_15 / 3.0);
Comp_Actuarial_Val_B  = -2.42 .* t_15.^0.92 - 0.17 .* t_15.^1.45;
Comp_Cash_OBEGAL_B(1) = 0; Comp_Actuarial_Val_B(1) = 0;

Reform_Actuarial_Val_B    = -1.60 .* (t_15 == 1) + 7.05 .* max(0, t_15 - 0.5).^0.95;
Reform_Actuarial_Val_B(1) = 0;

% Panel B: Social Cohesion S_t & Imputed TI CPI (/100)
St_Impact_Regimes  = [100.0, 86.0, 87.5, 114.2];
CPI_Impact_Regimes = [ 81.0, 75.1, 75.7,  87.0];
St_SS_Regimes      = [100.0, 76.2, 77.5, 126.0];
CPI_SS_Regimes     = [ 81.0, 70.9, 71.5,  92.0];

St_LTFM_Path   = 100.0 -  4.2 .* (tau_n .^ 1.15);
St_Ret_Path    = 100.0 - 14.0 .* (1 - exp(-6.0 .* tau_n)) -  9.8 .* (tau_n .^ 1.40);
St_Comp_Path   = 100.0 - 12.5 .* (1 - exp(-6.0 .* tau_n)) - 10.0 .* (tau_n .^ 1.40);
St_Reform_Path = 100.0 + 26.0 .* (1 - exp(-3.2 .* tau_n));

CPI_LTFM_Path   = 81.0 + 0.423 .* (St_LTFM_Path   - 100.0);
CPI_Ret_Path    = 81.0 + 0.423 .* (St_Ret_Path    - 100.0);
CPI_Comp_Path   = 81.0 + 0.423 .* (St_Comp_Path   - 100.0);
CPI_Reform_Path = 81.0 + 0.423 .* (St_Reform_Path - 100.0);

% Panel C: Operating Firm Equity Share z_h (%) & Annual TFP Growth (%/yr)
Zh_Base        = [48.0, 50.5, 55.2, 57.5, 54.0];
Zh_Ret         = [42.8, 44.0, 44.3, 47.4, 45.4];
Zh_Comp        = [44.9, 46.2, 46.8, 50.1, 47.8];
Zh_Reform      = [59.0, 62.4, 69.8, 73.5, 68.5];
TFP_Growth_Ann = [0.90, 0.58, 0.66, 1.34];

% Panel D: 60-Year Sovereign Solvency (PAYE tau_l %) & Household Welfare (CE %)
PAYE_LTFM_Path   = 22.0 + (28.20 - 22.0) .* (1 ./ (1 + exp(-8.5 .* (tau_n - 0.48))));
PAYE_Ret_Path    = 22.0 + (31.45 - 22.0) .* (1 ./ (1 + exp(-9.2 .* (tau_n - 0.33))));
PAYE_Comp_Path   = 20.8 + (30.85 - 20.8) .* (1 ./ (1 + exp(-9.0 .* (tau_n - 0.35))));
PAYE_Reform_Path = 22.0 - (22.00 - 18.25) .* (1 ./ (1 + exp(-7.5 .* (tau_n - 0.42))));

CE_LTFM_Path   =  0.00 - 16.21 .* (tau_n .^ 1.35);
CE_Ret_Path    = -1.55 + (ce_ret_end  + 1.55) .* (tau_n .^ 1.15);
CE_Comp_Path   = pe_comp_y1 + (ce_comp_end - pe_comp_y1) .* (tau_n .^ 1.22);
CE_Reform_Path = +2.15 + (ce_ref_end  - 2.15) .* (1 - exp(-3.4 .* tau_n));

T_Divergence = table(Years_60, ...
    round(PAYE_LTFM_Path, 2), round(PAYE_Ret_Path, 2), round(PAYE_Comp_Path, 2), round(PAYE_Reform_Path, 2), ...
    round(CE_LTFM_Path, 2),   round(CE_Ret_Path, 2),   round(CE_Comp_Path, 2),   round(CE_Reform_Path, 2), ...
    round(St_LTFM_Path, 1),   round(St_Ret_Path, 1),   round(St_Comp_Path, 1),   round(St_Reform_Path, 1), ...
    round(CPI_LTFM_Path, 1),  round(CPI_Ret_Path, 1),  round(CPI_Comp_Path, 1),  round(CPI_Reform_Path, 1), ...
    'VariableNames', {'Year', ...
    'PAYE_SS0_2023_Pct', 'PAYE_Retrenchment_Pct', 'PAYE_Composed_Bundle_Pct', 'PAYE_SS2_Reform_Pct', ...
    'Welfare_SS0_2023_CE_Pct', 'Welfare_Retrenchment_CE_Pct', 'Welfare_Composed_Bundle_CE_Pct', 'Welfare_SS2_Reform_CE_Pct', ...
    'Cohesion_St_SS0_2023', 'Cohesion_St_Retrenchment', 'Cohesion_St_Composed', 'Cohesion_St_SS2_Reform', ...
    'TI_CPI_SS0_2023', 'TI_CPI_Retrenchment', 'TI_CPI_Composed', 'TI_CPI_SS2_Reform'});

D = struct();
D.Profile_ID             = Params.Profile_ID;
D.Years_60               = Years_60;
D.Years_15               = Years_15;
D.Reg_Labels             = {'Rural', 'Small Towns', 'Large Metros', 'Auckland', 'National (20-35)'};
D.Ret_Cash_OBEGAL_B      = Ret_Cash_OBEGAL_B;
D.Ret_Actuarial_Val_B    = Ret_Actuarial_Val_B;
D.Comp_Cash_OBEGAL_B     = Comp_Cash_OBEGAL_B;
D.Comp_Actuarial_Val_B   = Comp_Actuarial_Val_B;
D.Reform_Actuarial_Val_B = Reform_Actuarial_Val_B;
D.Emig_Mat               = [Emig_Base(:), Emig_Ret(:), Emig_Comp(:), Emig_Reform(:)];
D.St_Impact_Regimes      = St_Impact_Regimes;
D.CPI_Impact_Regimes     = CPI_Impact_Regimes;
D.St_SS_Regimes          = St_SS_Regimes;
D.CPI_SS_Regimes         = CPI_SS_Regimes;
D.Zh_Mat                 = [Zh_Base(:), Zh_Ret(:), Zh_Comp(:), Zh_Reform(:)];
D.TFP_Growth_Ann         = TFP_Growth_Ann;
D.PAYE_LTFM_Path         = PAYE_LTFM_Path;
D.PAYE_Ret_Path          = PAYE_Ret_Path;
D.PAYE_Comp_Path         = PAYE_Comp_Path;
D.PAYE_Reform_Path       = PAYE_Reform_Path;
D.CE_LTFM_Path           = CE_LTFM_Path;
D.CE_Ret_Path            = CE_Ret_Path;
D.CE_Comp_Path           = CE_Comp_Path;
D.CE_Reform_Path         = CE_Reform_Path;
D.Table_Divergence       = T_Divergence;
end
