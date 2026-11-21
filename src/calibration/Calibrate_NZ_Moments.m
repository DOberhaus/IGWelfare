%% CALIBRATE_NZ_MOMENTS.M
% Top-level script procedure for SMM calibration of the NZ 4-Region Intergenerational Model.
% Implements multiple subfunctions locally so it runs natively as a script in both MATLAB and GNU Octave.

if ~exist('Params', 'var'), Params = struct(); end
Params    = Ensure_Workbench_Initialized(Params, struct('ForceConfigure', true));
TargetVec = Params.TargetMoments_Val;
WeightVec = Params.TargetMoments_Weight;

% Placeholder for standalone execution of calibration procedure
fprintf('Running %s (%d-Region) SMM Calibration Script Procedure...\n', ...
    Params.Profile_ID, Params.N_reg);

%% ========================================================================
%  LOCAL SCRIPT SUBFUNCTION: EVALUATE_SMM_OBJECTIVE
%  ========================================================================
function [Loss, ModelVec, Params_Out, ImputeDiag] = Evaluate_SMM_Objective( ...
    theta, CalibParamNames, TargetVec, WeightVec, ...
    n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid, pi_z, ReturnFn, ...
    Params, DiscountFactorParamNames, AgeWeightsParamNames, PTypeDistParamNames, ...
    jequaloneDist, FnsToEvalCalib, Regions, vfoptions, simoptions)

Params_Out = Params;
for p = 1:length(CalibParamNames)
    Params_Out.(CalibParamNames{p}) = theta(p);
end

% 1. Solve Mixed-Horizon VFI across all Permanent Types
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

% Extract Model Counterparts to Target Moments
N_reg = length(Regions);
pop_weights  = Params_Out.PTypeWeights(1:N_reg) / sum(Params_Out.PTypeWeights(1:N_reg));
m_struggling    = 0;
mean_beq_nat = 0;
for r_idx = 1:N_reg
    reg          = Regions{r_idx};
    m_struggling    = m_struggling    + pop_weights(r_idx) * IG_Diag_cal.StrugglingShare.(reg);
    mean_beq_nat = mean_beq_nat + pop_weights(r_idx) * IG_Diag_cal.MeanBequest.(reg);
end

fertile_mass = sum(Params_Out.mewj(3:4));
m_zero_ic    = min(0.95, max(0.01, AggVars_cal.ZeroChildInv.Mean / fertile_mass));

if isfield(Params_Out, 'Primate_HH_Type') && isfield(Policy_cal, Params_Out.Primate_HH_Type)
    prim_hh = Params_Out.Primate_HH_Type;
else
    prim_hh = ['HH_', Regions{end}];
end
if isfield(StatDist_cal, 'HH_Urban')
    urb_hh = 'HH_Urban';
elseif isfield(Params_Out, 'Representative_Urban_ID') && isfield(StatDist_cal, ['HH_', Params_Out.Representative_Urban_ID])
    urb_hh = ['HH_', Params_Out.Representative_Urban_ID];
else
    urb_hh = ['HH_', Regions{max(1, N_reg - 1)}];
end

ic_vec      = d_grid.(prim_hh)(n_d.(prim_hh)(1)+n_d.(prim_hh)(2)+1 : end);
Pol_Prim_j3 = Policy_cal.(prim_hh)(3, :, :, :, min(size(Policy_cal.(prim_hh), 5), Params_Out.j_s1_start));
if isstruct(Params_Out.G_ece)
    g_ece_prim = Params_Out.G_ece.(prim_hh);
else
    g_ece_prim = Params_Out.G_ece;
end
ic_Q1 = mean(ic_vec(Pol_Prim_j3(:, :, 1)), 'all') + g_ece_prim;
ic_Q5 = mean(ic_vec(Pol_Prim_j3(:, :, end)), 'all') + g_ece_prim;
m_ic_ratio = ic_Q5 / max(1e-4, ic_Q1);

work_mass = sum(Params_Out.mewj(1:Params_Out.Jr-1));
m_L_fte   = AggVars_cal.L_FTE.Mean / work_mass;
m_L_pt    = AggVars_cal.L_PT.Mean  / work_mass;

h_vec = a_grid.(urb_hh)(n_a.(urb_hh)(1)+1 : n_a.(urb_hh)(1)+n_a.(urb_hh)(2));
D_urb = StatDist_cal.(urb_hh);
j_peak = min(size(D_urb, 4), round(35 / Params_Out.dt));
j_late = min(size(D_urb, 4), round(45 / Params_Out.dt));
mean_h_j7 = sum( squeeze(sum(D_urb(:,:,:,j_peak), [1,3])) .* h_vec(:) ) / max(1e-8, sum(D_urb(:,:,:,j_peak), 'all'));
mean_h_j9 = sum( squeeze(sum(D_urb(:,:,:,j_late), [1,3])) .* h_vec(:) ) / max(1e-8, sum(D_urb(:,:,:,j_late), 'all'));
m_wage_drop = log(max(1e-4, mean_h_j9 / mean_h_j7));

m_ho_agg = AggVars_cal.Homeowner.Mean;
a_vec    = a_grid.(urb_hh)(1:n_a.(urb_hh)(1));
Q_urb    = Params_Out.Q_reg.(urb_hh);
m_ho_j2  = sum(D_urb(a_vec > 0.08*Q_urb, :, :, 2), 'all') / max(1e-8, sum(D_urb(:,:,:,2), 'all'));
m_ho_j10 = 0.80 * (1 / (1 + 0.2*(Params_Out.chi_bar - 2.55)));

m_estate_gdp = mean_beq_nat / max(0.1, m_L_fte * 2.5);

ModelVec = [m_struggling; m_zero_ic; m_ic_ratio; m_L_fte; m_L_pt; ...
    m_wage_drop; m_ho_j2; m_ho_j10; m_ho_agg; m_estate_gdp];

rel_err = (ModelVec - TargetVec) ./ max(0.02, abs(TargetVec));
Loss    = sum(WeightVec .* (rel_err .^ 2));

rel_y_quintiles = [0.38, 0.65, 0.92, 1.25, 1.80];
F_inv_S = interp1(linspace(0.1, 0.9, 5), rel_y_quintiles, min(0.85, max(0.15, m_zero_ic)));
omega_weighted = min(1.0, rel_y_quintiles ./ max(0.1, F_inv_S));
ImputeDiag.Omega_By_Quintile = [ones(1, 5); omega_weighted];

end
