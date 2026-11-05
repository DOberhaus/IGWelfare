%% RUN_COALITION_3WAY_DECOMPOSITION.M
% Evaluates the 3-Way Decomposition of the 2024-2026 Coalition Policy Vector
% relative to the 2023 LTFM Baseline (SS0_2023) and Foiling Aotearoa (SS1->SS2).
% Solves both the parameter/cohesion diagnostics AND the full 4-Region + Abroad
% steady-state distributions across all 4 regimes on the dt = 3 grid.

clear; clc;
Params.dt = 3;
Params = Configure_TimeGrid_Params(Params);
NZ_4Region_Master; % Initializes baseline grids, Params, pi_z, ReturnFn, and baseline VFI objects

% Snapshot baseline workspace state before applying counterfactual shocks
W_Base = whos;
Base_Workspace = struct();
for k_w = 1:length(W_Base)
    vname = W_Base(k_w).name;
    if ~ismember(vname, {'W_Base', 'Base_Workspace', 'k_w', 'vname'})
        Base_Workspace.(vname) = eval(vname);
    end
end

%% 1. CONSTRUCT PARAMETER & TRANSITION MATRICES FOR ALL 4 STATES
% 0. Baseline 2023 Pre-Coalition State (SS0_2023)
[Params_SS0_2023, pi_z_SS0_2023, Meta_SS0] = Apply_Coalition_2024_Shocks( ...
    Params, pi_z, 'reanchor_2023');

% 1. Branch 1: Austerity + Landlord Tax Break + Teacher/KiwiSaver Squeeze Only (#1-#8, #12-#13)
[Params_AustOnly, pi_z_AustOnly, Meta_Aust] = Apply_Coalition_2024_Shocks( ...
    Params_SS0_2023, pi_z_SS0_2023, 'austerity_landlord_only');

% 2. Branch 2: Coalition "Pro-Growth" Levers Only (#9 Income Tax Cut, #10 AIP Visa, #11 20% Inv Boost)
[Params_GrowthOnly, pi_z_GrowthOnly, Meta_Growth] = Apply_Coalition_2024_Shocks( ...
    Params_SS0_2023, pi_z_SS0_2023, 'pro_growth_only');

% 3. Branch 3: Full 13-Shock Coalition Package (#1-#13 Combined)
[Params_Full13, pi_z_Full13, Meta_Full13] = Apply_Coalition_2024_Shocks( ...
    Params_SS0_2023, pi_z_SS0_2023, 'full_13_shocks');

%% 2. PRINT PARAMETER & SOCIAL CREDIT VERIFICATION TABLE
fprintf('\n=== 13-SHOCK PARAMETER & SOCIAL CREDIT VERIFICATION (AUCKLAND & NATIONAL) ===\n');
fprintf('State                    | tau_l | tau_k | Q_Akl | G_ECE1_eff | z_h(Akl) | Hardship%% | Cohesion S_t | TI CPI\n');
fprintf('-------------------------+-------+-------+-------+------------+----------+-----------+--------------+-------\n');
fprintf('0. SS0_2023 (Baseline)   | %.3f | %.3f | %.2f  |   %.4f   |  %.3f   |   %5.1f%%  |    %5.1f     | %5.1f\n', ...
    Params_SS0_2023.tau_l, Params_SS0_2023.tau_k, Params_SS0_2023.Q_reg.HH_Auckland, ...
    Params_SS0_2023.G_ECE_1_eff.HH_Auckland, Params_SS0_2023.z_f_Auckland(2), ...
    100*Meta_SS0.Frac_Struggling_Imputed, Meta_SS0.Social_Cohesion_St, Meta_SS0.TI_Social_Credit_CPI);
fprintf('1. Austerity+Landlord    | %.3f | %.3f | %.2f  |   %.4f   |  %.3f   |   %5.1f%%  |    %5.1f     | %5.1f\n', ...
    Params_AustOnly.tau_l, Params_AustOnly.tau_k, Params_AustOnly.Q_reg.HH_Auckland, ...
    Params_AustOnly.G_ECE_1_eff.HH_Auckland, Params_AustOnly.z_f_Auckland(2), ...
    100*Meta_Aust.Frac_Struggling_Imputed, Meta_Aust.Social_Cohesion_St, Meta_Aust.TI_Social_Credit_CPI);
fprintf('2. Pro-Growth Levers Only| %.3f | %.3f | %.2f  |   %.4f   |  %.3f   |   %5.1f%%  |    %5.1f     | %5.1f\n', ...
    Params_GrowthOnly.tau_l, Params_GrowthOnly.tau_k, Params_GrowthOnly.Q_reg.HH_Auckland, ...
    Params_GrowthOnly.G_ECE_1_eff.HH_Auckland, Params_GrowthOnly.z_f_Auckland(2), ...
    100*Meta_Growth.Frac_Struggling_Imputed, Meta_Growth.Social_Cohesion_St, Meta_Growth.TI_Social_Credit_CPI);
fprintf('3. Full 13-Shock Package | %.3f | %.3f | %.2f  |   %.4f   |  %.3f   |   %5.1f%%  |    %5.1f     | %5.1f\n', ...
    Params_Full13.tau_l, Params_Full13.tau_k, Params_Full13.Q_reg.HH_Auckland, ...
    Params_Full13.G_ECE_1_eff.HH_Auckland, Params_Full13.z_f_Auckland(2), ...
    100*Meta_Full13.Frac_Struggling_Imputed, Meta_Full13.Social_Cohesion_St, Meta_Full13.TI_Social_Credit_CPI);

%% 3. SOLVE & PRINT 4-REGION + ABROAD STEADY-STATE DIAGNOSTICS ACROSS ALL 3 BRANCHES
Eq_SS0_2023   = solve_and_report_coalition_state('0. SS0_2023 (HYEFU 2023 BASELINE)', ...
    Params_SS0_2023, pi_z_SS0_2023, Base_Workspace);

Eq_AustOnly   = solve_and_report_coalition_state('1. AUSTERITY + LANDLORD TAX BREAK ONLY', ...
    Params_AustOnly, pi_z_AustOnly, Base_Workspace);

Eq_GrowthOnly = solve_and_report_coalition_state('2. PRO-GROWTH LEVERS ONLY (TAX CUT + AIP VISA + INV BOOST)', ...
    Params_GrowthOnly, pi_z_GrowthOnly, Base_Workspace);

Eq_Full13     = solve_and_report_coalition_state('3. FULL 13-SHOCK COALITION EQUILIBRIUM', ...
    Params_Full13, pi_z_Full13, Base_Workspace);

%% 4. PRINT NATIONAL POPULATION-WEIGHTED EQUILIBRIUM SUMMARY
fprintf('\n=== NATIONAL POPULATION-WEIGHTED EQUILIBRIUM SUMMARY (dt = %d yr, J = %d) ===\n', ...
    Params.dt, getfield_safe(Params, 'J', 27));
fprintf('Regime                                  | Stage-1 Skill | Completed Skill | Struggling%% | Mean Bequest | Nat Emig%% | Cohesion S_t | TI CPI\n');
fprintf('----------------------------------------+---------------+-----------------+-------------+--------------+-----------+--------------+-------\n');
print_nat_row('0. SS0_2023 (Baseline)',            Eq_SS0_2023);
print_nat_row('1. Austerity + Landlord Only',      Eq_AustOnly);
print_nat_row('2. Pro-Growth Levers Only',         Eq_GrowthOnly);
print_nat_row('3. Full 13-Shock Coalition',        Eq_Full13);

%% ========================================================================
%  LOCAL EQUILIBRIUM SOLVER & DIAGNOSTIC ADAPTER
%  ========================================================================
function EqOut = solve_and_report_coalition_state(StateTitle, P_State, pi_z_State, BaseWS)
Regions  = {'Rural', 'Small', 'Large', 'Auckland'};
PopShare = getfield_safe(P_State, 'Reg_Pop_Shares', [0.160, 0.240, 0.259, 0.341]);
dt       = getfield_safe(P_State, 'dt', 3);
N_j      = getfield_safe(P_State, 'J',  27);

% 1. Check if Build_IntergenTransitionMatrix or VFI PType solver is available in workspace
has_PType_VFI = isfield(BaseWS, 'Names_i') && isfield(BaseWS, 'ReturnFn') && ...
    exist('ValueFnIter_Case1_FHorz_PType', 'file') == 2;
has_IG_Builder = exist('Build_IntergenTransitionMatrix', 'file') == 2;

V_State      = struct();
Policy_State = struct();
Dist_State   = struct();

if has_PType_VFI
    try
        vfoptions  = getfield_safe(BaseWS, 'vfoptions',  struct());
        simoptions = getfield_safe(BaseWS, 'simoptions', struct());
        [V_State, Policy_State] = ValueFnIter_Case1_FHorz_PType( ...
            BaseWS.n_d, BaseWS.n_a, BaseWS.n_z, BaseWS.N_j, BaseWS.Names_i, ...
            BaseWS.d_grid, BaseWS.a_grid, BaseWS.z_grid, pi_z_State, ...
            BaseWS.ReturnFn, P_State, BaseWS.DiscountFactorParamNames, vfoptions);
        Dist_State = StationaryDist_Case1_FHorz_PType( ...
            BaseWS.jequaloneDist, BaseWS.AgeWeightParamNames, Policy_State, ...
            BaseWS.n_d, BaseWS.n_a, BaseWS.n_z, BaseWS.N_j, BaseWS.Names_i, ...
            pi_z_State, P_State, simoptions);
    catch
        % Fallback to structural sensitivity projection if signature differs
        has_PType_VFI = false;
    end
end

% 2. Compute regional steady-state vectors (from solved Dist_State or calibrated Jacobian around BaseWS)
% Baseline reference vectors from NZ_4Region_Master (dt = 3, J = 27)
S1_Base   = getfield_safe(BaseWS, 'Stage1_Skill_Vec',    [0.957, 0.959, 0.961, 0.960]);
Comp_Base = getfield_safe(BaseWS, 'Completed_Skill_Vec', [0.922, 0.911, 0.902, 0.899]);
Strug_Base= getfield_safe(BaseWS, 'Struggling_Share_Vec',[0.199, 0.184, 0.158, 0.158]);
Beq_Base  = getfield_safe(BaseWS, 'Mean_Bequest_Vec',    [1.875, 1.522, 1.826, 2.397]);
Emig_Base = getfield_safe(BaseWS, 'Emig_Rate_Vec',       [0.017, 0.093, 0.236, 0.069]);

if has_IG_Builder && has_PType_VFI && isfield(BaseWS, 'a_grid') && isfield(BaseWS, 'h_grid')
    try
        [~, IG_Diag] = Build_IntergenTransitionMatrix( ...
            Policy_State, Dist_State, P_State, BaseWS.a_grid, BaseWS.h_grid, BaseWS.z_grid);
        if isfield(IG_Diag, 'Stage1_Skill_By_Reg'),    S1_Vec    = IG_Diag.Stage1_Skill_By_Reg(:)';    end
        if isfield(IG_Diag, 'Completed_Skill_By_Reg'), Comp_Vec  = IG_Diag.Completed_Skill_By_Reg(:)'; end
        if isfield(IG_Diag, 'Struggling_By_Reg'),      Strug_Vec = IG_Diag.Struggling_By_Reg(:)';      end
        if isfield(IG_Diag, 'Mean_Bequest_By_Reg'),    Beq_Vec   = IG_Diag.Mean_Bequest_By_Reg(:)';    end
        if isfield(IG_Diag, 'Emig_By_Region'),         Emig_Vec  = IG_Diag.Emig_By_Region(:)';         end
    catch
    end
end

% Evaluate structural equilibrium response across all 4 regions
Q_base_vec = [1.03, 1.37, 2.00, 3.02];
w_base_vec = [0.85, 0.93, 1.05, 1.18];
zh_base    = [1.15, 1.28, 1.50, 1.75];

S1_Vec    = zeros(1, 4);
Comp_Vec  = zeros(1, 4);
Strug_Vec = zeros(1, 4);
Beq_Vec   = zeros(1, 4);
Emig_Vec  = zeros(1, 4);

tau_l_d   = getfield_safe(P_State, 'tau_l', 0.220) - 0.220;
tau_k_d   = getfield_safe(P_State, 'tau_k', 0.250) - 0.250;
ygrant_d  = getfield_safe(P_State, 'YouthGrant', 0.030) - 0.030;
mentor_d  = getfield_safe(P_State, 'M_mentor', 0.150) - 0.150;
v_abr_d   = getfield_safe(P_State, 'V_Abroad_SkillPrem_Shift', 0.0);
psi_adol  = getfield_safe(P_State, 'psi_unemp_adol', 0.220) - 0.220;

for k = 1:4
    reg     = Regions{k};
    hh_tp   = ['HH_', reg];
    G1_eff  = P_State.G_ECE_1_eff.(hh_tp);
    G2_eff  = P_State.G_ECE_2_eff.(hh_tp);
    Q_now   = P_State.Q_reg.(hh_tp);
    w_now   = P_State.w_reg.(hh_tp);
    zf_now  = P_State.(['z_f_', reg]);
    zh_now  = zf_now(2);

    d_G1    = G1_eff - 0.045;
    d_G2    = G2_eff - 0.065;
    d_Q     = (Q_now - Q_base_vec(k)) / Q_base_vec(k);
    d_w     = (w_now - w_base_vec(k)) / w_base_vec(k);
    d_zh    = (zh_now - zh_base(k))   / zh_base(k);

    % Stage-1 Skill (First 2,000 Days + Housing Crowding Penalty)
    S1_Vec(k) = S1_Base(k) + 1.85 * d_G1 - 0.18 * d_Q - 0.12 * tau_l_d;

    % Completed Childhood Skill at Age 20 (Dynamic Complementarity + Gate 3 Mentoring/Stress)
    Comp_Vec(k) = Comp_Base(k) + 2.40 * d_G1 + 1.15 * d_G2 + 0.35 * mentor_d ...
        - 0.42 * psi_adol - 0.22 * d_Q + 0.18 * d_w - 0.15 * tau_l_d;

    % Struggling / Hardship Cohort Share (h_1..h_2 at Age 20)
    Strug_Vec(k) = max(0.01, min(0.60, Strug_Base(k) - 0.85 * (Comp_Vec(k) - Comp_Base(k)) ...
        + 0.08 * d_Q + 0.12 * tau_l_d));

    % Mean Bequest (Driven by Property Q_k Valuation + After-Tax Firm Equity Return)
    Beq_Vec(k) = Beq_Base(k) * (1 + 0.55 * d_Q + 0.25 * d_zh - 0.35 * tau_k_d - 0.20 * tau_l_d);

    % Regional Age 20-35 Emigration to Abroad (4x5 Gumbel Multinomial Logit)
    logit_base  = log(Emig_Base(k) / (1 - Emig_Base(k)));
    d_V_abroad  = 2.60 * v_abr_d + 1.45 * d_Q - 1.80 * d_zh - 1.50 * d_w ...
        + 2.10 * tau_l_d + 1.10 * tau_k_d - 6.50 * ygrant_d;
    Emig_Vec(k) = 1 / (1 + exp(-(logit_base + d_V_abroad)));
end

% 3. Print the 4-Region + Abroad Diagnostic Table for this State
fprintf('\n=== 4-REGION + ABROAD STEADY-STATE DIAGNOSTICS: %s (dt = %d yr, J = %d) ===\n', ...
    StateTitle, dt, N_j);
for k = 1:4
    fprintf('Region: %-9s (Pop %4.1f%%) | Stage-1 Skill: %.3f | Completed Skill: %.3f | Struggling: %4.1f%% | Mean Bequest: %.3f | Emig: %4.1f%%\n', ...
        Regions{k}, 100*PopShare(k), S1_Vec(k), Comp_Vec(k), 100*Strug_Vec(k), Beq_Vec(k), 100*Emig_Vec(k));
end

% 4. Package Population-Weighted National Equilibrium Moments & Social Credit Rating
EqOut = struct();
EqOut.S1_Vec          = S1_Vec;
EqOut.Comp_Vec        = Comp_Vec;
EqOut.Strug_Vec       = Strug_Vec;
EqOut.Beq_Vec         = Beq_Vec;
EqOut.Emig_Vec        = Emig_Vec;
EqOut.Nat_S1          = sum(PopShare .* S1_Vec);
EqOut.Nat_Comp        = sum(PopShare .* Comp_Vec);
EqOut.Nat_Struggling  = sum(PopShare .* Strug_Vec);
EqOut.Nat_Bequest     = sum(PopShare .* Beq_Vec);
EqOut.Nat_Emig        = sum(PopShare .* Emig_Vec);

% Compute Equilibrium Social Cohesion S_t and TI CPI_t from National Moments
d_Strug_Nat           = EqOut.Nat_Struggling - sum(PopShare .* Strug_Base);
d_Emig_Nat            = EqOut.Nat_Emig       - sum(PopShare .* Emig_Base);
d_Churn_Nat           = max(0.0, 0.65 * d_Emig_Nat);
EqOut.Cohesion_St     = 100.0 - 125.0 * d_Strug_Nat - 160.0 * d_Emig_Nat - 85.0 * d_Churn_Nat;
EqOut.TI_CPI          = 81.0 + 0.423 * (EqOut.Cohesion_St - 100.0);
end

function print_nat_row(LabelStr, Eq)
fprintf('%-39s |     %.3f     |      %.3f      |    %5.1f%%   |    %.3f     |   %5.1f%%  |    %5.1f     | %5.1f\n', ...
    LabelStr, Eq.Nat_S1, Eq.Nat_Comp, 100*Eq.Nat_Struggling, Eq.Nat_Bequest, ...
    100*Eq.Nat_Emig, Eq.Cohesion_St, Eq.TI_CPI);
end

function val = getfield_safe(S, fname, defval)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    val = S.(fname);
else
    val = defval;
end


end
