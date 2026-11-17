%% CALIBRATE_NZ_MOMENTS.M: SMM CALIBRATION FOR MULTI-REGION MIXED-HORIZON MODEL
% Uses VFI Toolkit's PType statistical evaluation and calibration architecture
% to discipline structural parameters against New Zealand & OECD moments:
%   1. Cunha, Heckman & Schennach (2010) / Daruich (2018): Early skill & Q5/Q1 investment
%   2. Ferriere et al. (Source 2): Zero private top-up share S and weighted imputation omega_i
%   3. Fan, Seshadri & Taber (Source 7): Late-career FTE labor supply & 55-65 wage profile
%   4. Kiyotaki, Michaelides & Nikolov (2024, Source 10): Homeownership age profile
%   5. De Nardi (2004, Source 5) & Labrousse/Perdereau (Source 1): Bequests & Spatial Rural/Auckland gaps

% Prerequisite: Run NZ_MultiRegion_Master.m to initialize grids (n_d, n_a, n_z, N_j, Names_i)
% and baseline structures (ReturnFn, Params, DiscountFactorParamNames, jequaloneDist).

%% 1. DEFINE MOMENT EVALUATION FUNCTIONS (FnsToEvaluate FOR CALIBRATION)
FnsToEvalCalib = struct();

for r_idx = 1:length(Regions)
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    firm_tp = ['Firm_', reg];

    % 1. Full-Time Equivalent Labor Supply: FT = 1.0, PT = 0.5 (Fan et al. Source 7, Table 6 note d)
    FnsToEvalCalib.L_FTE.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, agej, Jr) ...
        (agej < Jr) * l;
    FnsToEvalCalib.L_FTE.(firm_tp) = @(aprime, a, z) 0;

    % 2. Part-Time Work Indicator (l == 0.5, Fan et al. Source 7, Table 6 note e)
    FnsToEvalCalib.L_PT.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, agej, Jr) ...
        (agej < Jr) * (abs(l - 0.5) < 1e-4);
    FnsToEvalCalib.L_PT.(firm_tp) = @(aprime, a, z) 0;

    % 3. Log Measured Wage for Working Individuals (Fan et al. Source 7 & Lee/Seshadri Source 4 Eq 18)
    FnsToEvalCalib.LogWage.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, w_reg, agej, Jr) ...
        (agej < Jr && l > 0) * log(max(1e-4, w_reg * z * h * max(0.05, l - Ih)));
    FnsToEvalCalib.LogWage.(firm_tp) = @(aprime, a, z) 0;

    % 4. Zero Private Child Top-Up Indicator S = Pr(ic == 0 | fertile age j=3,4) (Source 2, Eq 3)
    FnsToEvalCalib.ZeroChildInv.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, agej) ...
        ((agej == 3) || (agej == 4)) * (ic < 1e-4);
    FnsToEvalCalib.ZeroChildInv.(firm_tp) = @(aprime, a, z) 0;

    % 5. Positive Parental Child Investment ic (Daruich Source 6: Q5 vs Q1 ratio)
    FnsToEvalCalib.ChildInv.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, agej) ...
        ((agej == 3) || (agej == 4)) * ic;
    FnsToEvalCalib.ChildInv.(firm_tp) = @(aprime, a, z) 0;

    % 6. Homeownership Rate by Age & Region (Kiyotaki et al. Source 10, Fig 2 & Table 2)
    FnsToEvalCalib.Homeowner.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, ...
        r, Q_reg, G_reg, mu_maint, upsilon_h, chi_bar, agej, Jr) ...
        (agej < Jr) * min(1.0, (1/chi_bar) * ((1 + mu_maint - G_reg/((1+r)^(1/5))) / ...
        max(0.005, 1 + mu_maint - upsilon_h - G_reg/((1+r)^(1/5))))) * (a > 0.08 * Q_reg) ...
        + (agej >= Jr) * 1.0;
    FnsToEvalCalib.Homeowner.(firm_tp) = @(aprime, a, z) 0;

    % 7. Net Worth / Property Estate Holdings at Age 70+ (De Nardi Source 5: j >= 11)
    FnsToEvalCalib.Assets70Plus.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, agej) ...
        (agej >= 11) * a;
    FnsToEvalCalib.Assets70Plus.(firm_tp) = @(aprime, a, z) 0;
end

%% 2. SPECIFY EMPIRICAL TARGET MOMENTS & WEIGHTS (NZ DATA + LITERATURE BENCHMARKS)
TargetMoments = struct();

% Lens 1 Targets: Child Hardship, Zero Private Top-Up Share S, & Q5/Q1 Investment Ratio
TargetMoments.StrugglingShare_NZ     = 0.180; % 14.3% NZ Material Hardship to 22% Dunedin Study benchmark
TargetMoments.ZeroChildTopUp_S    = 0.250; % Share S with ic = 0 (Source 2 weighted imputation benchmark)
TargetMoments.ChildInv_Q5_Q1_Ratio= 1.385; % Daruich (Source 6): 21.6 / 15.6 = 1.385 investment ratio

% Lens 2 Targets: Labor Supply (FTE & Part-Time) & Late-Career Log Wage Drop (Ages 50-54 to 60-64)
TargetMoments.Labor_FTE_Mean      = 0.658; % Fan, Seshadri & Taber (Source 7, Table 6 Panel A: 0.658)
TargetMoments.Labor_PT_Share      = 0.032; % Fan, Seshadri & Taber (Source 7, Table 6 Panel A: 0.032)
TargetMoments.LateCareer_WageDrop = -0.140;% 10-year log measured wage decline from j=7 (50-54) to j=9 (60-64)

% Lens 3 & Spatial Housing Targets: Homeownership Profile, Auckland/Rural Price Ratio, & Bequest Share
TargetMoments.Homeown_Young_j2    = 0.380; % Ages 25-29 ownership rate (Kiyotaki et al. Source 10 Fig 2)
TargetMoments.Homeown_Old_j10     = 0.800; % Ages 65-69 ownership rate (Kiyotaki et al. Source 10 Fig 2)
TargetMoments.Homeown_Aggregate   = 0.648; % National homeownership rate (NZ Census 64.5% / US 65.2% Source 10)
TargetMoments.EstateToGDP_Share   = 0.165; % Annualized $1.6T 40-yr property bequest flow to output ratio

% Diagonal SMM Weighting Matrix (higher weight on primary policy targets)
MomentNames = fieldnames(TargetMoments);
N_moments   = length(MomentNames);
TargetVec   = zeros(N_moments, 1);
for m = 1:N_moments
    TargetVec(m) = TargetMoments.(MomentNames{m});
end
WeightVec = [2.5; 2.0; 1.5; 1.5; 1.0; 1.5; 2.0; 2.0; 2.5; 2.0];

%% 3. DEFINE PARAMETERS TO CALIBRATE (CalibParamNames) & BOUNDS
% Vector of 8 core parameters spanning Lenses 1, 2, and 3
CalibParamNames = {'omega_ic', 'gbar_ece', 'gamma_ic', ... % Lens 1: Child skill & luxury shifter
    'delta_hc', 'alpha_I',  ...             % Lens 2: Ben-Porath depreciation & training
    'chi_bar',  'b1_beq',   'b2_beq'};      % Lens 3: Housing tenure & luxury bequests

theta_init = [Params.omega_ic; Params.gbar_ece; Params.gamma_ic; ...
    Params.delta_hc; Params.alpha_I;  ...
    Params.chi_bar;  Params.b1_beq;   Params.b2_beq];

lb = [0.15; 0.005; 0.18;  0.040; 0.040;  1.50; 1.50; 0.15];
ub = [0.75; 0.080; 0.55;  0.150; 0.180;  4.00; 8.00; 1.20];

%% 4. STAGE 1: SOBOL QUASI-RANDOM GLOBAL PRE-SCREENING (Daruich Source 6, Fig C1)
% Draw quasi-random Sobol points across parameter hypercube to avoid local minima
N_sobol = 16; % Set to 500-2000 on GPU cluster for full global sweep
fprintf('\n=== STAGE 1: RUNNING SOBOL QUASI-RANDOM HYPERCUBE PRE-SCREENING (%d draws) ===\n', N_sobol);

sobol_seq = net(sobolset(length(theta_init), 'Skip', 100), N_sobol);
best_loss = Inf;
best_theta = theta_init;

for s_idx = 1:N_sobol
    theta_cand = lb + sobol_seq(s_idx, :)' .* (ub - lb);
    [loss_s, ~] = Evaluate_SMM_Objective(theta_cand, CalibParamNames, TargetVec, WeightVec, ...
        n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid, pi_z, ReturnFn, ...
        Params, DiscountFactorParamNames, AgeWeightsParamNames, PTypeDistParamNames, ...
        jequaloneDist, FnsToEvalCalib, Regions, vfoptions, simoptions);

    if loss_s < best_loss
        best_loss  = loss_s;
        best_theta = theta_cand;
        fprintf('  New Best Sobol Draw #%2d | Weighted SMM Loss = %.5f\n', s_idx, best_loss);
    end
end

%% 5. STAGE 2: LOCAL NELDER-MEAD / QUASI-NEWTON SMM OPTIMIZATION
fprintf('\n=== STAGE 2: REFINING CALIBRATION VIA LOCAL SMM OPTIMIZER ===\n');
calib_options = optimset('Display', 'iter', 'MaxIter', 40, 'TolX', 1e-3, 'TolFun', 1e-4);

obj_fn = @(theta) Evaluate_SMM_Objective(theta, CalibParamNames, TargetVec, WeightVec, ...
    n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid, pi_z, ReturnFn, ...
    Params, DiscountFactorParamNames, AgeWeightsParamNames, PTypeDistParamNames, ...
    jequaloneDist, FnsToEvalCalib, Regions, vfoptions, simoptions);

% Bound-constrained transformation via logistic sigmoid mapping
inv_logit = @(p) log((p - lb) ./ max(1e-6, ub - p));
fwd_logit = @(x) lb + (ub - lb) ./ (1 + exp(-x));

x0 = inv_logit(max(lb + 1e-4, min(ub - 1e-4, best_theta)));
[x_opt, fval_opt, exitflag_opt, output_opt] = fminsearch(@(x) obj_fn(fwd_logit(x)), x0, calib_options);
if exitflag_opt ~= 1
    IGW_Log('IGW:NoConvergence', 'Calibrate_NZ_Moments Stage-2 fminsearch (MaxIter %d, TolX 1e-3, TolFun 1e-4): %d iterations, residual %.3g (final weighted SMM loss; exitflag %d)', ...
        calib_options.MaxIter, output_opt.iterations, fval_opt, exitflag_opt);
end
theta_calibrated  = fwd_logit(x_opt);

% Evaluate final calibrated moments and update Params
[~, ModelMomentsVec, Params_Calibrated, ImputationDiag] = Evaluate_SMM_Objective( ...
    theta_calibrated, CalibParamNames, TargetVec, WeightVec, ...
    n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid, pi_z, ReturnFn, ...
    Params, DiscountFactorParamNames, AgeWeightsParamNames, PTypeDistParamNames, ...
    jequaloneDist, FnsToEvalCalib, Regions, vfoptions, simoptions);

%% 6. DISPLAY CALIBRATED PARAMETERS, MOMENT FIT, & FERRIERE ET AL. IMPUTATION WEIGHTS
fprintf('\n=========================================================================\n');
fprintf('TABLE A: CALIBRATED STRUCTURAL PARAMETERS (MULTI-REGION NZ OLG MODEL)\n');
fprintf('=========================================================================\n');
T_Params = table(CalibParamNames', theta_init, theta_calibrated, lb, ub, ...
    'VariableNames', {'Parameter', 'Initial_Guess', 'Calibrated_Value', 'Lower_Bound', 'Upper_Bound'});
disp(T_Params);

fprintf('\n=========================================================================\n');
fprintf('TABLE B: MODEL FIT VS. EMPIRICAL TARGET MOMENTS\n');
fprintf('=========================================================================\n');
Pct_Dev = 100 * (ModelMomentsVec - TargetVec) ./ max(1e-4, abs(TargetVec));
T_Moments = table(MomentNames, TargetVec, ModelMomentsVec, Pct_Dev, ...
    'VariableNames', {'Moment_Name', 'Data_Target', 'Model_Moment', 'Pct_Deviation'});
disp(T_Moments);

fprintf('\n=========================================================================\n');
fprintf('TABLE C: FERRIERE ET AL. (SOURCE 2, EQ 3) WEIGHTED IN-KIND ECE IMPUTATION\n');
fprintf('=========================================================================\n');
T_Impute = array2table(ImputationDiag.Omega_By_Quintile, ...
    'VariableNames', {'Q1_Poor', 'Q2', 'Q3', 'Q4', 'Q5_Rich'}, ...
    'RowNames', {'Standard Monetary Imputation Weight', 'Welfare-Based Weight omega_i (Eq 3)'});
disp(T_Impute);


%% ========================================================================
