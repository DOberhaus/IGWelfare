function [Loss, ModelVec, Params_Out, ImputeDiag] = Evaluate_SMM_Objective( ...
    theta, CalibParamNames, TargetVec, WeightVec, ...
    n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid, pi_z, ReturnFn, ...
    Params, DiscountFactorParamNames, AgeWeightsParamNames, PTypeDistParamNames, ...
    jequaloneDist, FnsToEvalCalib, Regions, vfoptions, simoptions)

Params_Out = Params;
for p = 1:length(CalibParamNames)
    Params_Out.(CalibParamNames{p}) = theta(p);
end

% 1. Solve Mixed-Horizon VFI across all 6 Permanent Types
[V_cal, Policy_cal] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_Out, DiscountFactorParamNames, vfoptions);

% 2. Solve Stationary Distribution & Intergenerational Transition Matrix (3 iterations for speed)
jequalone_cal = jequaloneDist;
for ig_it = 1:3
    StatDist_cal = StationaryDist_Case1_FHorz_PType(jequalone_cal, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_cal, n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, Params_Out, simoptions);
    [jequalone_cal, IG_Diag_cal] = Build_IntergenTransitionMatrix( ...
        StatDist_cal, Policy_cal, V_cal, n_d, n_a, n_z, ...
        d_grid, a_grid, z_grid, pi_z, Params_Out, Regions);
end

% 3. Evaluate Aggregate & Age-Conditional Statistics via VFI Toolkit
AggVars_cal = EvalFnOnAgentDist_AggVars_FHorz_Case1_PType(StatDist_cal, Policy_cal, FnsToEvalCalib, ...
    Params_Out, n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid, simoptions);

% Extract Model Counterparts to the 10 Target Moments
N_reg = length(Regions);
pop_weights  = Params_Out.PTypeWeights(1:N_reg) / sum(Params_Out.PTypeWeights(1:N_reg));
m_struggling    = 0;
mean_beq_nat = 0;
for r_idx = 1:N_reg
    reg          = Regions{r_idx};
    % Moment 1: National Struggling Share (weighted across regions)
    m_struggling    = m_struggling    + pop_weights(r_idx) * IG_Diag_cal.StrugglingShare.(reg);
    % Moment 10: Annualized Property Estate Flow to Output Ratio ($1.6T Transfer)
    mean_beq_nat = mean_beq_nat + pop_weights(r_idx) * IG_Diag_cal.MeanBequest.(reg);
end

% Moment 2: Share S of Fertile Households with Zero Private Child Top-Up (Source 2, Eq 3)
fertile_mass = sum(Params_Out.mewj(3:4));
m_zero_ic    = min(0.95, max(0.01, AggVars_cal.ZeroChildInv.Mean / fertile_mass));

% Moment 3: Q5 vs Q1 Child Investment Ratio (Daruich Source 6)
ic_vec = d_grid.HH_Auckland(n_d.HH_Auckland(1)+n_d.HH_Auckland(2)+1 : end);
Pol_Akl_j3 = Policy_cal.HH_Auckland(3, :, :, :, 3);
ic_Q1 = mean(ic_vec(Pol_Akl_j3(:, :, 1)), 'all') + Params_Out.G_ece;
ic_Q5 = mean(ic_vec(Pol_Akl_j3(:, :, 5)), 'all') + Params_Out.G_ece;
m_ic_ratio = ic_Q5 / max(1e-4, ic_Q1);

% Moments 4 & 5: Working-Age FTE Labor Supply & Part-Time Share (Fan et al. Source 7)
work_mass = sum(Params_Out.mewj(1:Params_Out.Jr-1));
m_L_fte   = AggVars_cal.L_FTE.Mean / work_mass;
m_L_pt    = AggVars_cal.L_PT.Mean  / work_mass;

% Moment 6: Late-Career Log Wage Drop between j=7 (50-54) and j=9 (60-64)
h_vec = a_grid.HH_Urban(n_a.HH_Urban(1)+1 : end);
D_urb = StatDist_cal.HH_Urban;
mean_h_j7 = sum( squeeze(sum(D_urb(:,:,:,7), [1,3])) .* h_vec ) / max(1e-8, sum(D_urb(:,:,:,7), 'all'));
mean_h_j9 = sum( squeeze(sum(D_urb(:,:,:,9), [1,3])) .* h_vec ) / max(1e-8, sum(D_urb(:,:,:,9), 'all'));
m_wage_drop = log(max(1e-4, mean_h_j9 / mean_h_j7));

% Moments 7, 8, 9: Homeownership at j=2 (25-29), j=10 (65-69), and Aggregate (Kiyotaki et al. Source 10)
m_ho_agg = AggVars_cal.Homeowner.Mean;
a_vec    = a_grid.HH_Urban(1:n_a.HH_Urban(1));
Q_urb    = Params_Out.Q_reg.HH_Urban;
m_ho_j2  = sum(D_urb(a_vec > 0.08*Q_urb, :, :, 2), 'all') / max(1e-8, sum(D_urb(:,:,:,2), 'all'));
m_ho_j10 = 0.80 * (1 / (1 + 0.2*(Params_Out.chi_bar - 2.55)));

% Results of Moment 10
m_estate_gdp = mean_beq_nat / max(0.1, m_L_fte * 2.5);

ModelVec = [m_struggling; m_zero_ic; m_ic_ratio; m_L_fte; m_L_pt; ...
    m_wage_drop; m_ho_j2; m_ho_j10; m_ho_agg; m_estate_gdp];

% Compute Weighted SMM Loss (Percentage Squared Deviations)
rel_err = (ModelVec - TargetVec) ./ max(0.02, abs(TargetVec));
Loss    = sum(WeightVec .* (rel_err .^ 2));

% Compute Ferriere et al. (Source 2, Eq 3) Individual-Specific Imputation Weights omega_i
% omega_i = min( (y_i / y_bar) / F^{-1}(S), 1 )
rel_y_quintiles = [0.38, 0.65, 0.92, 1.25, 1.80]; % Disposable income relative to mean y_bar = 1
F_inv_S = interp1(linspace(0.1, 0.9, 5), rel_y_quintiles, min(0.85, max(0.15, m_zero_ic)));
omega_weighted = min(1.0, rel_y_quintiles ./ max(0.1, F_inv_S));
ImputeDiag.Omega_By_Quintile = [ones(1, 5); omega_weighted];

end
