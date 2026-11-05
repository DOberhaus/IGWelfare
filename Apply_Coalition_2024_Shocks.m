function [Params_Out, pi_z_Out, ShockMeta] = Apply_Coalition_2024_Shocks(Params_In, pi_z_In, Mode, ShockOpts)
% APPLY_COALITION_2024_SHOCKS (Full 13-Shock Edition)
% Standalone parameterization module for branch: "exp/coalition-2024-shocks"
%
% Supported Modes:
%   1. 'reanchor_2023'           : Pre-Coalition late-2023 baseline (SS0_2023)
%   2. 'austerity_landlord_only' : Shocks #1-#8 + #12-#13 (Austerity + Landlord Relief + Teacher/KS squeeze)
%   3. 'pro_growth_only'         : Shocks #9-#11 Only (Income Tax Cut + AIP Visa + 20% Investment Boost)
%   4. 'full_13_shocks'          : All 13 Shocks Combined (Default Coalition Package)
%   5. 'custom'                  : Uses user-supplied boolean switches in ShockOpts

if nargin < 3 || isempty(Mode)
    Mode = 'full_13_shocks';
end
if nargin < 4 || isempty(ShockOpts)
    ShockOpts = struct();
end

% -------------------------------------------------------------------------
% Configure Preset Bundles for 3-Way Decomposition
% -------------------------------------------------------------------------
switch lower(Mode)
    case 'reanchor_2023'
        default_aust = false; default_growth = false;
    case 'austerity_landlord_only'
        default_aust = true;  default_growth = false;
    case 'pro_growth_only'
        default_aust = false; default_growth = true;
    otherwise % 'full_13_shocks' or 'custom'
        default_aust = true;  default_growth = true;
end

% Group A: Austerity, Rent-Seeking, Infrastructure & Human-Capital Erosion Shocks
ShockOpts = set_default_opt(ShockOpts, 'LandlordTaxBreak',       default_aust);   % #1:  $2.9B interest deductibility + 2yr Bright-line
ShockOpts = set_default_opt(ShockOpts, 'ScienceCallaghanCuts',   default_aust);   % #2:  Callaghan disestablishment + Marsden/Science cuts
ShockOpts = set_default_opt(ShockOpts, 'PublicSectorLayoffs',    default_aust);   % #3:  >6,000-9,000 Wellington/Metro redundancies
ShockOpts = set_default_opt(ShockOpts, 'CancelFerriesPorts',     default_aust);   % #4:  iReX Cook Strait ferry cancellation + break fee
ShockOpts = set_default_opt(ShockOpts, 'DunedinHospitalDelays',  default_aust);   % #5:  Dunedin Hospital downgrade/delay + Health NZ cuts
ShockOpts = set_default_opt(ShockOpts, 'CancelPayEquity_OT_ECE', default_aust);   % #6:  Pay equity repeal + 337 OT contracts + ECE closures
ShockOpts = set_default_opt(ShockOpts, 'TertiaryFeesFreeCut',    default_aust);   % #7:  Fees-Free repeal + university funding squeeze
ShockOpts = set_default_opt(ShockOpts, 'TobaccoTaxFreeze',       default_aust);   % #8:  HTP tax cut & tobacco excise freeze
ShockOpts = set_default_opt(ShockOpts, 'TeacherKaiakoPaySqueeze',default_aust);   % #12: 2026 PTCA/STCA 2.5%/2.0% vs 4.0% CPI + ECE parity risk
ShockOpts = set_default_opt(ShockOpts, 'KiwiSaverMatchCut',      default_aust);   % #13: Halving Govt KiwiSaver match + 4% default + 30% IRR

% Group B: Coalition "Pro-Growth / Tax Relief / Foreign Capital" Levers
ShockOpts = set_default_opt(ShockOpts, 'IncomeTaxBracketCut',    default_growth); % #9:  $14.7B/4yr personal income tax cut (debt/cut funded)
ShockOpts = set_default_opt(ShockOpts, 'ActiveInvestorVisa',     default_growth); % #10: $3.4B-$5.4B AIP Visa inflow + $5M+ luxury home right
ShockOpts = set_default_opt(ShockOpts, 'InvestmentBoost20Pct',   default_growth); % #11: Budget 2025 $1.7B/yr 20% immediate business asset expensing

% Homotopy / Scaling factor in [0, 1]
ShockOpts = set_default_opt(ShockOpts, 'ShockScale',             1.00);

Params_Out = Params_In;
pi_z_Out   = pi_z_In;
Regions    = {'Rural', 'Small', 'Large', 'Auckland'};
s          = ShockOpts.ShockScale;

ShockMeta = struct();
ShockMeta.Mode         = Mode;
ShockMeta.Timestamp    = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
ShockMeta.ActiveShocks = ShockOpts;

%% ========================================================================
%  MODE 1: RE-ANCHOR SS0 TO LATE-2023 PRE-COALITION ECONOMY (HYEFU 2023)
%  ========================================================================
if strcmpi(Mode, 'reanchor_2023')
    Params_Out.Debt_to_GDP_Init     = 0.405;  % Net core Crown debt ~40.5% of GDP in late 2023
    Params_Out.tau_l                = 0.220;  % Effective working-age PAYE anchor
    Params_Out.tau_k                = 0.250;  % Baseline corporate/capital income tax
    Params_Out.tau_a                = 0.000;  % No book-value land/wealth tax in 2023
    Params_Out.tau_b                = 0.000;  % No estate tax in 2023
    Params_Out.lambda_col           = 1.800;  % Baseline Guvenen firm collateral multiplier

    % Pre-Coalition property rules (Interest deductibility phase-out active)
    Params_Out.upsilon_h            = 0.0095;
    Params_Out.Q_k_vec              = [1.03, 1.37, 2.00, 3.02];
    Params_Out.Q_reg_base_vec       = [1.03, 1.37, 2.00, 3.02]; % Immutable SS0 reference for Kaiako deflator

    % Pre-Cut Science, ECE, & Infrastructure Baseline
    Params_Out.G_ECE_1              = 0.045;
    Params_Out.G_ECE_2              = 0.065;
    Params_Out.gbar_ECE             = 0.020;
    Params_Out.YouthGrant           = 0.030;
    Params_Out.M_mentor             = 0.150;
    Params_Out.nu_kaiako            = 0.350;  % Kaiako housing-affordability supply elasticity

    % Firm Productivity Ceilings [z_l, z_h] Before Callaghan/Marsden/iReX Cuts
    Params_Out.z_f_Rural            = [0.70, 1.15];
    Params_Out.z_f_Small            = [0.75, 1.28];
    Params_Out.z_f_Large            = [0.83, 1.50];
    Params_Out.z_f_Auckland         = [0.90, 1.75];

    Params_Out = sync_regional_fields(Params_Out, Regions);
    return;
end

%% ========================================================================
%  GROUP A: AUSTERITY, LANDLORD TAX RELIEF, INFRASTRUCTURE & SKILL CUTS
%  ========================================================================

% SHOCK 1: Landlord Tax Breaks (~NZD 2.9B Interest Deductibility + 2-Yr Bright-Line)
if ShockOpts.LandlordTaxBreak
    Params_Out.upsilon_h        = getfield_def(Params_Out, 'upsilon_h', 0.0095) - s * 0.0035;
    Q_curr                      = getfield_def(Params_Out, 'Q_k_vec', [1.03, 1.37, 2.00, 3.02]);
    Params_Out.Q_k_vec          = Q_curr .* (1 + s * [0.025, 0.035, 0.052, 0.068]);
    Params_Out.z_l_subsidy_wedge = getfield_def(Params_Out, 'z_l_subsidy_wedge', 0.0) + s * 0.045;
    Params_Out.Debt_to_GDP_Init = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s * 0.007;
end

% SHOCK 2: Disestablishing Callaghan Innovation, Marsden Fund & Science Cuts
if ShockOpts.ScienceCallaghanCuts
    zh_mult_science = 1 - s * [0.015, 0.025, 0.075, 0.068];
    zl_mult_land    = 1 + s * [0.020, 0.025, 0.035, 0.045];

    zf_R = getfield_def(Params_Out, 'z_f_Rural',    [0.70, 1.15]);
    zf_S = getfield_def(Params_Out, 'z_f_Small',    [0.75, 1.28]);
    zf_L = getfield_def(Params_Out, 'z_f_Large',    [0.83, 1.50]);
    zf_A = getfield_def(Params_Out, 'z_f_Auckland', [0.90, 1.75]);

    Params_Out.z_f_Rural    = [zf_R(1)*zl_mult_land(1), zf_R(2)*zh_mult_science(1)];
    Params_Out.z_f_Small    = [zf_S(1)*zl_mult_land(2), zf_S(2)*zh_mult_science(2)];
    Params_Out.z_f_Large    = [zf_L(1)*zl_mult_land(3), zf_L(2)*zh_mult_science(3)];
    Params_Out.z_f_Auckland = [zf_A(1)*zl_mult_land(4), zf_A(2)*zh_mult_science(4)];

    Params_Out.V_Abroad_SkillPrem_Shift = getfield_def(Params_Out, 'V_Abroad_SkillPrem_Shift', 0.0) + s * 0.085;
end

% SHOCK 3: Wholesale Public Sector Redundancies (>6,000-9,000 Roles)
if ShockOpts.PublicSectorLayoffs
    layoff_shift_vec = s * [0.004, 0.008, 0.028, 0.015]; % Concentrated in Large (Wellington) & Auckland
    for r_idx = 1:4
        hh_type = ['HH_', Regions{r_idx}];
        if isstruct(pi_z_Out) && isfield(pi_z_Out, hh_type)
            P_mat = pi_z_Out.(hh_type);
            shift = layoff_shift_vec(r_idx);
            if size(P_mat, 2) >= 5
                P_mat(:, 1)   = P_mat(:, 1) + 0.45 * shift;
                P_mat(:, 2)   = P_mat(:, 2) + 0.55 * shift;
                P_mat(:, 3:5) = max(1e-5, P_mat(:, 3:5) - shift / 3);
                P_mat         = P_mat ./ sum(P_mat, 2);
                pi_z_Out.(hh_type) = P_mat;
            end
        end
    end
    Params_Out.psi_unemp_adol = getfield_def(Params_Out, 'psi_unemp_adol', 0.220) * (1 + s * 0.15);
end

% SHOCK 4: Cancellation of iReX Cook Strait Ferries & Port Infrastructure
if ShockOpts.CancelFerriesPorts
    Params_Out.Debt_to_GDP_Init = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s * 0.0035;
    ebar_curr = getfield_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
    Params_Out.ebar_k_vec = ebar_curr .* (1 + s * [0.065, 0.055, 0.040, 0.015]);
    w_curr = getfield_def(Params_Out, 'w_k_vec', [0.85, 0.93, 1.05, 1.18]);
    Params_Out.w_k_vec = w_curr .* (1 - s * [0.011, 0.009, 0.008, 0.002]);
end

% SHOCK 5: Dunedin Hospital Inpatient Downgrade/Delays & Health NZ Cuts
if ShockOpts.DunedinHospitalDelays
    Params_Out.delta_hc_ann           = getfield_def(Params_Out, 'delta_hc_ann', 0.0180) * (1 + s * 0.085);
    Params_Out.Exit2_Hosp_Mult        = getfield_def(Params_Out, 'Exit2_Hosp_Mult', 1.00) * (1 + s * 0.140);
    Params_Out.G_Health_Regional_Drag = s * [0.025, 0.020, 0.035, 0.015];
end

% SHOCK 6: Cancellation of Pay Equity Claims + 337 OT Contracts + ECE Closures
if ShockOpts.CancelPayEquity_OT_ECE
    Params_Out.G_ECE_1    = getfield_def(Params_Out, 'G_ECE_1', 0.045) * (1 - s * 0.220);
    Params_Out.G_ECE_2    = getfield_def(Params_Out, 'G_ECE_2', 0.065) * (1 - s * 0.160);
    Params_Out.gbar_ECE   = getfield_def(Params_Out, 'gbar_ECE', 0.020) * (1 + s * 0.200);
    Params_Out.M_mentor   = getfield_def(Params_Out, 'M_mentor', 0.150) * (1 - s * 0.250);
    w_curr                = getfield_def(Params_Out, 'w_k_vec', [0.85, 0.93, 1.05, 1.18]);
    Params_Out.w_k_vec    = w_curr .* (1 - s * [0.006, 0.010, 0.012, 0.008]);
end

% SHOCK 7: Diminishment of Tertiary Education (Fees-Free Repeal & Sub-Inflation Funding)
if ShockOpts.TertiaryFeesFreeCut
    Params_Out.YouthGrant = getfield_def(Params_Out, 'YouthGrant', 0.030) * (1 - s * 0.350);
    Params_Out.alpha_I    = getfield_def(Params_Out, 'alpha_I', 0.090) * (1 - s * 0.075);
end

% SHOCK 8: Tobacco Excise Freeze & Heated Tobacco Product (HTP) Tax Cuts
if ShockOpts.TobaccoTaxFreeze
    Params_Out.Exit2_Hosp_Mult       = getfield_def(Params_Out, 'Exit2_Hosp_Mult', 1.00) * (1 + s * 0.045);
    Params_Out.Senescence_Morbid_Add = getfield_def(Params_Out, 'Senescence_Morbid_Add', 0.0) + s * 0.012;
end

% SHOCK 12: Teacher & Kaiako Sub-Inflation Pay (2.5% in 2026 / 2.0% in 2027 vs 4.0% CPI)
if ShockOpts.TeacherKaiakoPaySqueeze
    Params_Out.G_ECE_1                  = getfield_def(Params_Out, 'G_ECE_1', 0.045) * (1 - s * 0.065);
    Params_Out.G_ECE_2                  = getfield_def(Params_Out, 'G_ECE_2', 0.065) * (1 - s * 0.080);
    Params_Out.V_Abroad_SkillPrem_Shift = getfield_def(Params_Out, 'V_Abroad_SkillPrem_Shift', 0.0) + s * 0.025;
end

% SHOCK 13: KiwiSaver Match Halved (25c/$260) + 4% Default Hike + Social Rent IRR 25%->30%
if ShockOpts.KiwiSaverMatchCut
    Params_Out.YouthGrant = getfield_def(Params_Out, 'YouthGrant', 0.030) * (1 - s * 0.150);
    Params_Out.gbar_ECE   = getfield_def(Params_Out, 'gbar_ECE', 0.020) * (1 + s * 0.085);
end

%% ========================================================================
%  GROUP B: COALITION "PRO-GROWTH / TAX RELIEF / FOREIGN CAPITAL" LEVERS
%  ========================================================================

% SHOCK 9: Budget 2024 Personal Income Tax Bracket Cut (~NZD 14.7B / 4 yrs)
if ShockOpts.IncomeTaxBracketCut
    Params_Out.tau_l            = getfield_def(Params_Out, 'tau_l', 0.220) - s * 0.012;
    Params_Out.Debt_to_GDP_Init = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s * 0.024;
end

% SHOCK 10: Active Investor Plus (AIP) Visa Refresh ($3.4B-$5.4B Inflow + $5M+ Home Right)
if ShockOpts.ActiveInvestorVisa
    % Growth tranche slightly relaxes collateral constraint lambda_col,
    % while $5M+ luxury home carve-out & Balanced property tranche inflate Q_k
    Params_Out.lambda_col = getfield_def(Params_Out, 'lambda_col', 1.800) + s * 0.045;
    Q_curr                = getfield_def(Params_Out, 'Q_k_vec', [1.03, 1.37, 2.00, 3.02]);
    Params_Out.Q_k_vec    = Q_curr .* (1 + s * [0.012, 0.010, 0.008, 0.018]);

    % Modest lift to upper firm ceiling in Auckland/Large from Growth Visa venture funds
    zf_L = getfield_def(Params_Out, 'z_f_Large',    [0.83, 1.50]);
    zf_A = getfield_def(Params_Out, 'z_f_Auckland', [0.90, 1.75]);
    Params_Out.z_f_Large(2)    = zf_L(2) * (1 + s * 0.012);
    Params_Out.z_f_Auckland(2) = zf_A(2) * (1 + s * 0.018);
end

% SHOCK 11: Budget 2025 "Investment Boost" (20% Immediate Asset Expensing, $1.7B/yr)
if ShockOpts.InvestmentBoost20Pct
    Params_Out.tau_k            = getfield_def(Params_Out, 'tau_k', 0.250) - s * 0.022;
    Params_Out.Debt_to_GDP_Init = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s * 0.011;
end

%% ========================================================================
%  APPLY ENDOGENOUS KAIAKO PRICE-MANIFOLD DEFLATOR & SYNC REGIONAL FIELDS
%  G_ece_eff(Q_k) = G_ece * (Q_reg_base / Q_k)^nu_kaiako (Document 2T)
%  ========================================================================
Q_base_vec = getfield_def(Params_Out, 'Q_reg_base_vec', [1.03, 1.37, 2.00, 3.02]);
Q_now_vec  = getfield_def(Params_Out, 'Q_k_vec', Q_base_vec);
nu_k       = getfield_def(Params_Out, 'nu_kaiako', 0.350);
Params_Out.Kaiako_Deflator_Vec = (Q_base_vec ./ Q_now_vec) .^ nu_k;

Params_Out = sync_regional_fields(Params_Out, Regions);

end

%% ========================================================================
%  LOCAL HELPER FUNCTIONS
%  ========================================================================
function S = set_default_opt(S, fname, val)
if ~isfield(S, fname) || isempty(S.(fname))
    S.(fname) = val;
end
end

function val = getfield_def(S, fname, defval)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    val = S.(fname);
else
    val = defval;
end
end

function P = sync_regional_fields(P, Regions)
Q_vec    = getfield_def(P, 'Q_k_vec',    [1.03, 1.37, 2.00, 3.02]);
w_vec    = getfield_def(P, 'w_k_vec',    [0.85, 0.93, 1.05, 1.18]);
ebar_vec = getfield_def(P, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
k_defl   = getfield_def(P, 'Kaiako_Deflator_Vec', [1, 1, 1, 1]);

for k = 1:4
    reg     = Regions{k};
    hh_tp   = ['HH_', reg];
    firm_tp = ['Firm_', reg];

    P.Q_reg.(hh_tp)       = Q_vec(k);
    P.w_reg.(hh_tp)       = w_vec(k);
    P.w_reg.(firm_tp)     = w_vec(k);
    P.ebar_energy.(hh_tp) = ebar_vec(k);
    P.G_ECE_1_eff.(hh_tp) = P.G_ECE_1 * k_defl(k);
    P.G_ECE_2_eff.(hh_tp) = P.G_ECE_2 * k_defl(k);

    zf_field = ['z_f_', reg];
    if isfield(P, zf_field)
        P.z_f_grid.(firm_tp) = P.(zf_field)(:);
    end
end


end
