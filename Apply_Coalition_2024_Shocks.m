function [Params_Out, pi_z_Out, ShockMeta, z_grid_Out] = Apply_Coalition_2024_Shocks(Params_In, pi_z_In, Mode, ShockOpts, z_grid_In)
% APPLY_COALITION_2024_SHOCKS (Full 16-Shock Edition)
% Standalone parameterization module for branch: "coalition_2024_shocks"
% Directly outputs VFI-ready Params_Out, pi_z_Out, ShockMeta, and optional z_grid_Out
% aligned with Configure_TimeGrid_Params.m, ReturnFn_SpatialHH.m, and Build_IntergenTransitionMatrix.m.
%
% Supported Modes:
%   1. 'reanchor_2023'           : Pre-Coalition late-2023 baseline (SS0_2023)
%   2. 'austerity_landlord_only' : Shocks #1-#8 + #12-#13 (Austerity + Landlord Relief + Teacher/KS squeeze)
%   3. 'pro_growth_only'         : Shocks #9-#11 Only (Income Tax Cut + AIP Visa + 20% Investment Boost)
%   4. 'first_13_shocks'         : Shocks #1-#13 (aliases: 'coalition_13_shocks', 'full_13_shocks')
%   5. 'rates_cap_3_waters'      : Shock #14 (Council Rates Cap and 3 Waters repeal)
%   6. 'arts_and_civic_cuts'     : Shock #15 (Vote Arts/Sport + Creatives in Schools + WCC Civic Cuts)
%   7. 'all_but_ndc'             : All domestic shocks #1-#15 ('full_15_shocks')
%   8. 'ndc'                     : Shock #16 (Off-Book Paris NDC1/NDC2 Liability + Clean Car Discount Repeal)
%   9. 'full_16_shocks'          : All 16 Shocks Combined (Default Coalition Package)
%  10. 'custom'                  : Uses user-supplied boolean switches in ShockOpts

if nargin < 3 || isempty(Mode)
    Mode = 'full_16_shocks';
end
if nargin < 4 || isempty(ShockOpts)
    ShockOpts = struct();
end
if nargin < 5
    z_grid_In = struct();
end

% -------------------------------------------------------------------------
% Configure Preset Bundles for 3-Way & 16-Shock Decomposition
% -------------------------------------------------------------------------
default_14 = false; default_15 = false; default_ndc = false;
switch lower(strtrim(Mode))
    case {'reanchor_2023', 'custom'}
        default_aust = false; default_growth = false;
    case 'austerity_landlord_only'                                         % Original 10-shock Group A (Table B.1 Col 1)
        default_aust = true;  default_growth = false;
    case 'pro_growth_only'                                                 % 3-shock Group B (Table B.1 Col 2)
        default_aust = false; default_growth = true;
    case {'first_13_shocks', 'coalition_13_shocks', 'full_13_shocks'}      % 13-shock bundle (#1-#13, Table B.1 Col 3)
        default_aust = true;  default_growth = true;
    case 'rates_cap_3_waters'                                              % Isolate Shock #14 (Appendix B.3)
        default_aust = false; default_growth = false; default_14 = true;
    case 'arts_and_civic_cuts'                                             % Isolate Shock #15 (Appendix B.4)
        default_aust = false; default_growth = false; default_15 = true;
    case {'all_but_ndc', 'full_15_shocks'}                                 % All domestic shocks #1-#15 (excludes off-book NDC)
        default_aust = true;  default_growth = true;  default_14 = true;  default_15 = true;
    case 'ndc'                                                             % Isolate Shock #16 (Appendix B.5)
        default_aust = false; default_growth = false; default_14 = false; default_15 = false;
        default_ndc = true;
    case 'full_16_shocks'                                                  % Full 16-Shock Coalition Package (#1-#16)
        default_aust = true;  default_growth = true;
        default_14   = true;  default_15     = true;  default_ndc = true;
    otherwise
        error('Apply_Coalition_2024_Shocks:UnknownMode', 'Unrecognized Mode: ''%s''.', Mode);
end

% Group A: Austerity, Rent-Seeking, Infrastructure & Skill-Formation Erosion Shocks
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
ShockOpts = set_default_opt(ShockOpts, 'ThreeWatersRatesWedge',  default_14);     % #14: NZD 7B-10B council water debt shift + 12%-20%/yr rates & IRR 30%
ShockOpts = set_default_opt(ShockOpts, 'ArtsCivicWCCSqueeze',    default_15);     % #15: Vote Arts/Sport + Creatives in Schools axed + delegated WCC squeeze
ShockOpts = set_default_opt(ShockOpts, 'ParisNDCLiabilityAndEVRollback', ...      % #16: Off-book TP 26/01 NDC1/2 gap + Clean Car repeal + methane/oil-gas rollback
    default_ndc);
ShockOpts = set_default_opt(ShockOpts, 'NDC_Settlement_Mode',    'hybrid');       % 'offshore_pay' | 'default_fta_penalty' | 'hybrid' (50/50 split)

% Group B: Coalition "Pro-Growth / Tax Relief / Foreign Capital" Levers
ShockOpts = set_default_opt(ShockOpts, 'IncomeTaxBracketCut',    default_growth); % #9:  $14.7B/4yr personal income tax cut (debt/cut funded)
ShockOpts = set_default_opt(ShockOpts, 'ActiveInvestorVisa',     default_growth); % #10: $3.4B-$5.4B AIP Visa inflow + $5M+ luxury home right
ShockOpts = set_default_opt(ShockOpts, 'InvestmentBoost20Pct',   default_growth); % #11: Budget 2025 $1.7B/yr 20% immediate business asset expensing

% Homotopy / Scaling Factors in [0, 1]:
%   - ShockScale  : Master homotopy scale applied to Shocks #14-#16 (default 1.00 = full documented empirical effect)
%   - Core13Scale : Separate homotopy scale on Shocks #1-#13 (defaults to ShockScale; allows calibrating #1-#13
%                   so 'all_but_ndc' hits the -21.85% LTFM / -5.64% Delta CE benchmark while keeping #14-#15 at 1.00)
ShockOpts = set_default_opt(ShockOpts, 'ShockScale',  1.0000);
ShockOpts = set_default_opt(ShockOpts, 'Core13Scale', 0.4108 * ShockOpts.ShockScale);

% Ensure Single Source of Truth (Configure_TimeGrid_Params) is present on Params_In
if ~isfield(Params_In, 'Pop_Weights_4') || ~isfield(Params_In, 'Reg_Names_4')
    Params_In = Configure_TimeGrid_Params(Params_In);
end
Params_Out = Params_In;
pi_z_Out   = pi_z_In;
z_grid_Out = z_grid_In;
Regions    = Params_Out.Reg_Names_4; % {'Rural', 'Small', 'Large', 'Auckland'} from SSOT
dt_val     = Params_Out.dt;
scale_dt   = dt_val / 5;             % Period scaling relative to 5-year calibration benchmark

s13 = ShockOpts.Core13Scale;         % Scale applied to Shocks #1-#13
s   = ShockOpts.ShockScale;          % Scale applied to Shocks #14-#16

ShockMeta = struct();
ShockMeta.Mode         = strtrim(Mode);
ShockMeta.Timestamp    = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
ShockMeta.ActiveShocks = ShockOpts;

%% ========================================================================
%  MODE 1: RE-ANCHOR SS0 TO LATE-2023 PRE-COALITION ECONOMY (HYEFU 2023)
%  ========================================================================
if strcmpi(strtrim(Mode), 'reanchor_2023')
    Params_Out.Debt_to_GDP_Init          = 0.405;  % Net core Crown debt ~40.5% of GDP in late 2023 (HYEFU 2023)
    Params_Out.tau_l                     = 0.220;  % Effective working-age PAYE anchor
    Params_Out.tau_k                     = 0.250;  % Baseline corporate/capital income tax
    Params_Out.tau_a                     = 0.000;  % No book-value land/wealth tax in 2023
    Params_Out.tau_b                     = 0.000;  % No estate tax in 2023
    Params_Out.lambda_col                = 1.800;  % Baseline Guvenen firm collateral multiplier
    Params_Out.V_Abroad_SkillPrem_Shift  = 0.000;  % Baseline Abroad skill-premium wedge

    % Pre-Coalition property & carrying-cost rules (Interest deductibility phase-out active in late 2023)
    Params_Out.upsilon_h                 = 0.0095; % Owner-occupier tax user-cost advantage relative to leveraged landlords
    Params_Out.mu_maint_base             = 0.0400; % Baseline property maintenance, insurance & council rates carrying cost (4.0%)
    Params_Out.mu_rates_wedge_vec        = [0.0, 0.0, 0.0, 0.0]; % Zero post-2024 council water/rates surcharge in SS0_2023
    Params_Out.Q_k_vec                   = [1.03, 1.37, 2.00, 3.02];
    Params_Out.Q_reg_base_vec            = [1.03, 1.37, 2.00, 3.02]; % Immutable SS0 reference for Kaiako deflator
    Params_Out.w_k_vec                   = [0.85, 0.93, 1.05, 1.18]; % Pre-Coalition regional wage profile [Rural, Small, Large, Auckland]
    Params_Out.ebar_k_vec                = [0.048, 0.036, 0.022, 0.016]; % Mandatory regional fuel/energy subsistence floor
    Params_Out.sj_base                   = Params_Out.sj; % Immutable SS0 survival curve prior to Shock #8 tobacco/HTP morbidity

    % Pre-Cut Science, ECE, & Infrastructure Baseline
    Params_Out.G_ECE_1                   = 0.045;  % Stage-1 (First 2,000 Days) public investment anchor
    Params_Out.G_ECE_2                   = 0.065;  % Stage-2 (Ages 6-17 school/mentoring) public investment anchor
    Params_Out.gbar_ece                  = 0.020;  % Baseline parental ECE fee/time co-payment threshold
    Params_Out.YouthGrant                = 0.030;  % Pre-repeal age-20 Fees-Free / KiwiSaver launch endowment
    Params_Out.M_mentor                  = 0.150;  % Baseline youth mentoring / pastoral support intensity
    Params_Out.nu_kaiako                 = 0.350;  % Kaiako housing-affordability supply elasticity
    Params_Out.alpha_I                   = 0.090;  % Baseline Ben-Porath adult tertiary/training elasticity
    Params_Out.delta_hc_mult             = 1.000;  % Unity multiplier on SSOT adult HC depreciation (0.087 per 5 yrs)

    % Firm Productivity Ceilings [z_l, z_h] Before Callaghan/Marsden/iReX Cuts
    Params_Out.z_f_Rural                 = [0.70, 1.15];
    Params_Out.z_f_Small                 = [0.75, 1.28];
    Params_Out.z_f_Large                 = [0.83, 1.50];
    Params_Out.z_f_Auckland              = [0.90, 1.75];

    % Sync regional PType fields first, then populate ShockMeta cohesion/CPI diagnostics
    [Params_Out, ShockMeta, z_grid_Out] = compute_cohesion_and_sync(Params_Out, Regions, ShockMeta, z_grid_Out, true);
    return;
end

%% ========================================================================
%  GROUP A: AUSTERITY, LANDLORD TAX RELIEF, INFRASTRUCTURE & SKILL CUTS
%  ========================================================================

% SHOCK 1: Landlord Tax Breaks (~NZD 2.9B Interest Deductibility + 2-Yr Bright-Line)
% Mechanism: Restoring 100% mortgage interest deductibility for leveraged investors & cutting
% the Bright-line test from 10 yrs to 2 yrs erodes owner-occupiers' relative user-cost edge
% (-0.35 pp on upsilon_h, raising rh_reg in ReturnFn_SpatialHH), bids up urban house prices Q_k
% (+2.5% Rural to +6.8% Auckland), and adds +0.7% GDP to net Crown debt over the 4-yr forecast.
if ShockOpts.LandlordTaxBreak
    Params_Out.upsilon_h         = getfield_def(Params_Out, 'upsilon_h', 0.0095) - s13 * 0.0035;
    Q_curr                       = getfield_def(Params_Out, 'Q_k_vec', [1.03, 1.37, 2.00, 3.02]);
    Params_Out.Q_k_vec           = Q_curr .* (1 + s13 * [0.025, 0.035, 0.052, 0.068]);
    Params_Out.z_l_subsidy_wedge = getfield_def(Params_Out, 'z_l_subsidy_wedge', 0.0) + s13 * 0.045;
    Params_Out.Debt_to_GDP_Init  = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s13 * 0.007;
end

% SHOCK 2: Disestablishing Callaghan Innovation, Marsden Fund & Science Cuts
% Mechanism: Disestablishing Callaghan Innovation, stripping humanities/social-science panels
% from the Marsden Fund, & ending Endeavour/National Science Challenges lowers high-complexity
% firm TFP ceilings z_h (-7.5% in Wellington/Large CRI-university hub, -6.8% in Auckland),
% shifts capital toward low-TFP land/property extraction z_l, and widens the trans-Tasman/OECD
% STEM/researcher emigration push (+0.085 Gumbel utility shift toward Abroad).
if ShockOpts.ScienceCallaghanCuts
    zh_mult_science = 1 - s13 * [0.015, 0.025, 0.075, 0.068];
    zl_mult_land    = 1 + s13 * [0.020, 0.025, 0.035, 0.045];

    zf_R = getfield_def(Params_Out, 'z_f_Rural',    [0.70, 1.15]);
    zf_S = getfield_def(Params_Out, 'z_f_Small',    [0.75, 1.28]);
    zf_L = getfield_def(Params_Out, 'z_f_Large',    [0.83, 1.50]);
    zf_A = getfield_def(Params_Out, 'z_f_Auckland', [0.90, 1.75]);

    Params_Out.z_f_Rural    = [zf_R(1)*zl_mult_land(1), zf_R(2)*zh_mult_science(1)];
    Params_Out.z_f_Small    = [zf_S(1)*zl_mult_land(2), zf_S(2)*zh_mult_science(2)];
    Params_Out.z_f_Large    = [zf_L(1)*zl_mult_land(3), zf_L(2)*zh_mult_science(3)];
    Params_Out.z_f_Auckland = [zf_A(1)*zl_mult_land(4), zf_A(2)*zh_mult_science(4)];

    Params_Out.V_Abroad_SkillPrem_Shift = getfield_def(Params_Out, 'V_Abroad_SkillPrem_Shift', 0.0) + s13 * 0.085;
end

% SHOCK 3: Wholesale Public Sector Redundancies (>6,000-9,000 Roles)
% Mechanism: Baseline 6.5%-7.5% ministry expenditure cuts & >6,000-9,000 public-service job
% losses concentrated in Wellington (Large k=3, +2.8 pp downward transition hazard into bottom
% two Rouwenhorst z states) and Auckland (k=4, +1.5 pp), raising household earnings precarity.
if ShockOpts.PublicSectorLayoffs
    layoff_shift_vec = s13 * [0.004, 0.008, 0.028, 0.015]; % Concentrated in Large (Wellington) & Auckland
    for r_idx = 1:4
        hh_type = ['HH_', Regions{r_idx}];
        if isstruct(pi_z_Out) && isfield(pi_z_Out, hh_type)
            P_mat = pi_z_Out.(hh_type);
            shift = layoff_shift_vec(r_idx);
            nz_r  = size(P_mat, 2);
            if nz_r >= 4
                P_mat(:, 1)      = P_mat(:, 1) + 0.45 * shift;
                P_mat(:, 2)      = P_mat(:, 2) + 0.55 * shift;
                P_mat(:, 3:nz_r) = max(1e-5, P_mat(:, 3:nz_r) - shift / (nz_r - 2));
                P_mat            = P_mat ./ sum(P_mat, 2);
                pi_z_Out.(hh_type) = P_mat;
            end
        end
    end
    Params_Out.psi_unemp_adol = getfield_def(Params_Out, 'psi_unemp_adol', 0.220) * (1 + s13 * 0.15);
end

% SHOCK 4: Cancellation of iReX Cook Strait Ferries & Port Infrastructure
% Mechanism: Cancelling rail-enabled Interislander iReX ferries & Picton/Wellington port upgrades
% books ~NZD 0.5B-0.8B sunk break/re-procurement costs (+0.35% GDP debt), raises inter-island
% freight & household transport subsistence ebar_k (+6.5% Rural, +5.5% Small, +4.0% Large), and
% trims regional tradable wages (-1.1% Rural, -0.9% Small, -0.8% Large).
if ShockOpts.CancelFerriesPorts
    Params_Out.Debt_to_GDP_Init = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s13 * 0.0035;
    ebar_curr                   = getfield_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
    Params_Out.ebar_k_vec       = ebar_curr .* (1 + s13 * [0.065, 0.055, 0.040, 0.015]);
    w_curr                      = getfield_def(Params_Out, 'w_k_vec', [0.85, 0.93, 1.05, 1.18]);
    Params_Out.w_k_vec          = w_curr .* (1 - s13 * [0.011, 0.009, 0.008, 0.002]);
end

% SHOCK 5: Dunedin Hospital Inpatient Downgrade/Delays & Health NZ Cuts
% Mechanism: Delaying/downgrading the New Dunedin Hospital (Large k=3 Southern teaching hub &
% Otago/Southland Rural k=1 catchment) alongside Health NZ clinical hiring freezes accelerates
% untreated working-age skill depreciation (+8.5% on delta_hc via delta_hc_mult) and shifts
% rationed acute/outpatient care onto household out-of-pocket subsistence ebar_k
% (+0.0018 in Large/Dunedin, +0.0012 in Rural, +0.0010 in Small, +0.0008 in Auckland, ~NZD 250-550/yr).
if ShockOpts.DunedinHospitalDelays
    Params_Out.delta_hc_mult          = getfield_def(Params_Out, 'delta_hc_mult', 1.000) * (1 + s13 * 0.085);
    Params_Out.Exit2_Hosp_Mult        = getfield_def(Params_Out, 'Exit2_Hosp_Mult', 1.00) * (1 + s13 * 0.140);
    Params_Out.G_Health_Regional_Drag = s13 * [0.0012, 0.0010, 0.0018, 0.0008];
    ebar_curr                         = getfield_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
    Params_Out.ebar_k_vec             = ebar_curr + Params_Out.G_Health_Regional_Drag;
end

% SHOCK 6: Cancellation of Pay Equity Claims + 337 OT Contracts + ECE Closures
% Mechanism: Repealing 33 active care/education pay-equity claims under urgency, cancelling
% 337 Oranga Tamariki community early-intervention contracts, and loosening ECE regulatory/ratio
% protections reduces effective First-2000-Days wraparound (-22% G_ECE_1) and school-age support
% (-16% G_ECE_2), raises out-of-pocket ECE friction (+20% gbar_ece), cuts community mentoring
% (-25% M_mentor), and depresses female-intensive care/education wages (-0.6% to -1.2% w_k).
if ShockOpts.CancelPayEquity_OT_ECE
    Params_Out.G_ECE_1  = getfield_def(Params_Out, 'G_ECE_1', 0.045)  * (1 - s13 * 0.220);
    Params_Out.G_ECE_2  = getfield_def(Params_Out, 'G_ECE_2', 0.065)  * (1 - s13 * 0.160);
    Params_Out.gbar_ece = getfield_def(Params_Out, 'gbar_ece', 0.020) * (1 + s13 * 0.200);
    Params_Out.M_mentor = getfield_def(Params_Out, 'M_mentor', 0.150) * (1 - s13 * 0.250);
    w_curr              = getfield_def(Params_Out, 'w_k_vec', [0.85, 0.93, 1.05, 1.18]);
    Params_Out.w_k_vec  = w_curr .* (1 - s13 * [0.006, 0.010, 0.012, 0.008]);
end

% SHOCK 7: Diminishment of Tertiary Education (Fees-Free Repeal & Sub-Inflation Funding)
% Mechanism: Replacing first-year Fees-Free with final-year-only rebate & sub-CPI university
% tuition subsidies cuts the age-20 launch endowment (-35% YouthGrant) and lowers adult
% Ben-Porath tertiary/retraining productivity elasticity (-7.5% alpha_I).
if ShockOpts.TertiaryFeesFreeCut
    Params_Out.YouthGrant = getfield_def(Params_Out, 'YouthGrant', 0.030) * (1 - s13 * 0.350);
    Params_Out.alpha_I    = getfield_def(Params_Out, 'alpha_I', 0.090)    * (1 - s13 * 0.075);
end

% SHOCK 8: Tobacco Excise Freeze & Heated Tobacco Product (HTP) Tax Cuts
% Mechanism: Repealing the Smokefree Environments generational endgame, freezing tobacco excise,
% and halving HTP excise raises late-life smoking-attributable cardiopulmonary/cancer mortality:
% lowers retiree 5-yr survival probabilities sj(Jr:J-1) by -0.8% compounded by scale_dt (entering
% both Bellman discounting beta_hh*sj and ReturnFn_SpatialHH mortality-weighted bequest timing).
if ShockOpts.TobaccoTaxFreeze
    Params_Out.Exit2_Hosp_Mult       = getfield_def(Params_Out, 'Exit2_Hosp_Mult', 1.00) * (1 + s13 * 0.045);
    Params_Out.Senescence_Morbid_Add = getfield_def(Params_Out, 'Senescence_Morbid_Add', 0.0) + s13 * 0.008;
    sj_ref           = getfield_def(Params_Out, 'sj_base', Params_Out.sj);
    sj_new           = sj_ref;
    ret_span         = max(1, round(Params_Out.Jr)) : (Params_Out.J - 1);
    sj_new(ret_span) = max(0.05, sj_ref(ret_span) .* ((1 - s13 * 0.008) ^ scale_dt));
    Params_Out.sj    = sj_new;
end

% SHOCK 12: Teacher & Kaiako Sub-Inflation Pay (2.5% in 2026 / 2.0% in 2027 vs 4.0% CPI)
% Mechanism: Sub-CPI collective settlements & ECE pay-parity funding erosion trigger kaiako/teacher
% attrition (-6.5% real G_ECE_1 quality, -8.0% real G_ECE_2 quality) and trans-Tasman teacher
% recruitment outflow (+0.025 Abroad Gumbel push).
if ShockOpts.TeacherKaiakoPaySqueeze
    Params_Out.G_ECE_1                  = getfield_def(Params_Out, 'G_ECE_1', 0.045) * (1 - s13 * 0.065);
    Params_Out.G_ECE_2                  = getfield_def(Params_Out, 'G_ECE_2', 0.065) * (1 - s13 * 0.080);
    Params_Out.V_Abroad_SkillPrem_Shift = getfield_def(Params_Out, 'V_Abroad_SkillPrem_Shift', 0.0) + s13 * 0.025;
end

% SHOCK 13: KiwiSaver Match Halved (25c/$260) + 4% Default Hike + Social Rent IRR 25%->30%
% Mechanism: Budget 2025 halving of the Government KiwiSaver member tax credit (50c -> 25c, max
% $260.72/yr) & removing 16-17yo match eligibility cuts youth launch wealth (-15% YouthGrant),
% while raising income-related social housing rent thresholds increases low-income family fixed
% housing/childcare squeeze (+8.5% gbar_ece).
if ShockOpts.KiwiSaverMatchCut
    Params_Out.YouthGrant = getfield_def(Params_Out, 'YouthGrant', 0.030) * (1 - s13 * 0.150);
    Params_Out.gbar_ece   = getfield_def(Params_Out, 'gbar_ece', 0.020)   * (1 + s13 * 0.085);
end

% SHOCK 14: Three Waters Repeal + Council Rates-Capping Wedge (NZD 7B-10B Shift)
% Mechanism: Repealing Three Waters moves NZD 7B-10B of water balance-sheet debt back onto local
% councils (forcing 14.2% -> 9.2%/yr median rates hikes) while capping non-water "non-core" council
% spend. IMPORTANT SIGN NOTE: In ReturnFn_SpatialHH (lines 49-50), upsilon_h enters rh_reg with a
% MINUS sign (owner-occupied tax advantage), whereas mu_maint enters BOTH rr_reg and rh_reg with a
% PLUS sign (property carrying/rates/maintenance cost). Council rates & water charges therefore map
% onto mu_rates_wedge_vec (+[0.22, 0.30, 0.42, 0.26] pp/yr, peaking in Large k=3 WCC +68M & Small k=2).
if ShockOpts.ThreeWatersRatesWedge
    wedge_curr = getfield_def(Params_Out, 'mu_rates_wedge_vec', [0.0, 0.0, 0.0, 0.0]);
    Params_Out.mu_rates_wedge_vec = wedge_curr + s * [0.0022, 0.0030, 0.0042, 0.0026];
end

% SHOCK 15: Vote Arts/Culture/Sport Cuts + Delegated WCC Civic Squeeze (~NZD 0.16B/yr)
% Claimed Cash Saving: +0.067% CE (+NZD 0.16B/yr across Vote Arts -101.7M/4yr,
%   Creatives in Schools & Arts Coordinators axed, Tu Manawa youth sport cut,
%   Fale Malae NZD 7M halt, Better Off freeze, and WCC Creative/Civic Square/CAB cuts).
% Four-Wedge Transmission Channels (Vectorized 1x4 Regional Incidence):
%   (i)   Wedge 1 (L03): Axing Creatives in Schools & Tu Manawa cuts Gate-2 non-cognitive
%         retention (-3.8% G_ECE_2) and raises adolescent psychosocial hazard lambda_psy (+8.5% * reg_civic_wt).
%   (ii)  Wedge 2 (L07): Squeezing CAB (>50% WCC cut), community halls & volunteer clubs
%         erodes unpaid civic/kaumatua co-production psi_club_buffer (folded into active K_whanau).
%   (iii) Wedge 3 (L08): Collapsing urban venue/festival gig ecology (concentrated 2.1x in
%         Large k=3 Poneke & 1.35x in Auckland k=4) accelerates age 20-35 creative z_h exit
%         to Melbourne/Sydney (+V_Abroad_Reg_Shift) & trims urban z_h span productivity.
%   (iv)  Wedge 4 (L11): Erodes Social Cohesion Index (-4.8 pts nationally; -7.6 pts in k=3)
%         while automatic stabilizers claw back ~62% of claimed cash OBEGAL savings by Yr 3.
if ShockOpts.ArtsCivicWCCSqueeze
    reg_civic_wt = [0.75, 0.85, 2.10, 1.35]; % [Rural, Small, Large (WCC Poneke), Auckland]

    % (a) Narrow Year-1 cash budget saving (~NZD 0.16B/yr = 0.035% of GDP before clawback):
    Params_Out.Debt_to_GDP_Init = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) - s * 0.0004;

    % (b) Gate 2 & Gate 3 adolescent creative/sport mentoring & psychosocial hazard (Wedge 1):
    Params_Out.G_ECE_2        = getfield_def(Params_Out, 'G_ECE_2', 0.065) * (1.0 - s * 0.038);
    lam_psy_curr              = getfield_def(Params_Out, 'lambda_psy_vec', [0.38, 0.38, 0.38, 0.38]);
    Params_Out.lambda_psy_vec = min(0.65, lam_psy_curr .* (1.0 + s * 0.085 * reg_civic_wt));

    % (c) Join-or-Die adult/kaumatua club & CAB safety-net erosion (Wedge 2 -> K_whanau community buffer):
    mort_iso_curr                  = getfield_def(Params_Out, 'psi_club_buffer_vec', [1.0, 1.0, 1.0, 1.0]);
    Params_Out.psi_club_buffer_vec = mort_iso_curr .* (1.0 - s * 0.065 * [1.15, 1.10, 1.45, 0.95]);

    % (d) Creative venue/festival contraction -> z_h enterprise & trans-Tasman exit (Wedge 3):
    zh_mult_curr                  = getfield_def(Params_Out, 'Z_h_reg_mult', [1.00, 1.00, 1.00, 1.00]);
    Params_Out.Z_h_reg_mult       = zh_mult_curr .* (1.0 - s * 0.011 * reg_civic_wt);
    v_abr_reg                     = getfield_def(Params_Out, 'V_Abroad_Reg_Shift', [0.0, 0.0, 0.0, 0.0]);
    Params_Out.V_Abroad_Reg_Shift = v_abr_reg + s * 0.018 * reg_civic_wt;

    % (e) Hysteresis & Social Cohesion erosion (Wedge 4: asymmetric organizational loss = 1.08x):
    Params_Out.Civic_Hysteresis_Mult = 1.08;
    Params_Out.Cohesion_Shock_Pts    = getfield_def(Params_Out, 'Cohesion_Shock_Pts', 0.0) - s * 4.80;
end

% SHOCK 16: Off-Book Paris NDC1/NDC2 Liability + Clean Car Discount Repeal
% Empirical Anchor: NZ Treasury Paper TP 26/01 (11 June 2026) & OIA 20250807:
%   Baseline 84-96 MtCO2e NDC1 shortfall (NZD 4.4B-5.0B PV) widened +22-28 Mt
%   by Clean Car EV repeal (3-yr EV deferral), ETS auction floor/forestry
%   uncertainty, offshore gas co-investment, & Dec 2025 methane cut (14%-24%).
% Vectorized 1x4 Regional Channels [Rural, Small, Large, Auckland]:
%   (a) EV deferral locks in higher household fossil share & raises imported oil
%       subsistence drag ebar_k across Rural (+6.5%, 3.0x Auckland) & Small (+5.2%).
%   (b) 'offshore_pay' books deadweight sovereign Article 6 credit outflow (+1.85% GDP debt,
%       ~NZD 1.45B/yr at full pay / NZD 0.725B/yr hybrid = 0.17% of GDP -> +0.25 pp PAYE tax wedge
%       on working-age labor base rather than inflating domestic bondholder return r).
%   (c) 'default_fta_penalty' triggers EU-NZ FTA Ch. 19 non-regression export drag on Rural (-3.4%)
%       & Small (-2.4%) z_h agribusiness plus +22 bps sovereign borrowing spread (+0.80x fiscal
%       debt-service pass-through to tau_l & -1.20x firm cost-of-capital wage drag).
if ShockOpts.ParisNDCLiabilityAndEVRollback
    ndc_mode = lower(ShockOpts.NDC_Settlement_Mode);
    w_pay    = double(strcmp(ndc_mode, 'offshore_pay')) + 0.5 * double(strcmp(ndc_mode, 'hybrid'));
    w_def    = double(strcmp(ndc_mode, 'default_fta_penalty')) + 0.5 * double(strcmp(ndc_mode, 'hybrid'));

    % (a) Clean Car Discount repeal -> lower HH clean-switch elasticity & higher rural fuel drag:
    Params_Out.eps_h_energy = max(0.15, getfield_def(Params_Out, 'eps_h_energy', 0.350) - s * 0.120);
    ebar_curr               = getfield_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
    Params_Out.ebar_k_vec   = ebar_curr .* (1.0 + s * [0.065, 0.052, 0.030, 0.022]);

    % (b) Offshore Article 6 credit outflow (TP 26/01 NZD 6.5B-8.4B widened gap -> sovereign debt):
    Params_Out.Debt_to_GDP_Init        = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s * w_pay * 0.0185;
    Params_Out.Offshore_NDC_Drain_BNZD = getfield_def(Params_Out, 'Offshore_NDC_Drain_BNZD', 0.0) + s * w_pay * 1.45;

    % (c) Default / non-regression channel (Sept 2026 EU-FTA complaint -> Rural/Small z_h export penalty + r_sov):
    zh_curr                 = getfield_def(Params_Out, 'Z_h_reg_mult', [1.00, 1.00, 1.00, 1.00]);
    Params_Out.Z_h_reg_mult = zh_curr .* (1.0 - s * w_def * [0.034, 0.024, 0.008, 0.006]);
    Params_Out.r_sov_spread = getfield_def(Params_Out, 'r_sov_spread', 0.0) + s * w_def * 0.0022;

    % (d) Sovereign tax-financing closure (prevents external debt drain from acting as a windfall r hike):
    Params_Out.tau_l = getfield_def(Params_Out, 'tau_l', 0.220) ...
        + 0.0025 * (Params_Out.Offshore_NDC_Drain_BNZD / 0.725) ...
        + 0.80   * Params_Out.r_sov_spread;
end

%% ========================================================================
%  GROUP B: COALITION "PRO-GROWTH / TAX RELIEF / FOREIGN CAPITAL" LEVERS
%  ========================================================================

% SHOCK 9: Budget 2024 Personal Income Tax Bracket Cut (~NZD 14.7B / 4 yrs)
% Mechanism: Bracket threshold indexation (~NZD 3.7B/yr = 0.85% of GDP) lowers effective
% working-age PAYE rate tau_l by -1.2 pp while adding +2.4% of GDP to net core Crown debt.
if ShockOpts.IncomeTaxBracketCut
    Params_Out.tau_l            = getfield_def(Params_Out, 'tau_l', 0.220) - s13 * 0.012;
    Params_Out.Debt_to_GDP_Init = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s13 * 0.024;
end

% SHOCK 10: Active Investor Plus (AIP) Visa Refresh ($3.4B-$5.4B Inflow + $5M+ Home Right)
% Mechanism: Relaxing English/residency rules & granting $5M+ luxury residential purchase rights
% loosens domestic firm collateral constraints (+0.045 lambda_col) and lifts metro z_h (+1.2% Large,
% +1.8% Auckland), while bidding up top-tier urban land/house prices (+1.8% Q_Auckland).
if ShockOpts.ActiveInvestorVisa
    Params_Out.lambda_col      = getfield_def(Params_Out, 'lambda_col', 1.800) + s13 * 0.045;
    Q_curr                     = getfield_def(Params_Out, 'Q_k_vec', [1.03, 1.37, 2.00, 3.02]);
    Params_Out.Q_k_vec         = Q_curr .* (1 + s13 * [0.012, 0.010, 0.008, 0.018]);

    zf_L = getfield_def(Params_Out, 'z_f_Large',    [0.83, 1.50]);
    zf_A = getfield_def(Params_Out, 'z_f_Auckland', [0.90, 1.75]);
    Params_Out.z_f_Large(2)    = zf_L(2) * (1 + s13 * 0.012);
    Params_Out.z_f_Auckland(2) = zf_A(2) * (1 + s13 * 0.018);
end

% SHOCK 11: Budget 2025 "Investment Boost" (20% Immediate Asset Expensing, $1.7B/yr)
% Mechanism: Allowing immediate 20% first-year tax depreciation on new productive business assets
% lowers the effective marginal corporate/capital tax wedge tau_k by -2.2 pp (+1.1% GDP debt cost).
if ShockOpts.InvestmentBoost20Pct
    Params_Out.tau_k            = getfield_def(Params_Out, 'tau_k', 0.250) - s13 * 0.022;
    Params_Out.Debt_to_GDP_Init = getfield_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + s13 * 0.011;
end

%% ========================================================================
%  SYNC REGIONAL FIELDS & COMPUTE SOCIAL COHESION (S_t) AND TI CPI_t
%  ========================================================================
[Params_Out, ShockMeta, z_grid_Out] = compute_cohesion_and_sync(Params_Out, Regions, ShockMeta, z_grid_Out, false);

end

%% ========================================================================
%  LOCAL HELPER FUNCTIONS
%  ========================================================================
function [P, Meta, z_grid_Out] = compute_cohesion_and_sync(P, Regions, Meta, z_grid_Out, is_reanchor)
HH_Names   = strcat('HH_',   Regions);
Firm_Names = strcat('Firm_', Regions);
dt_val     = getfield_def(P, 'dt', 5);
scale_dt   = dt_val / 5;

% 0. Canonical Population & Firm Weights from Single Source of Truth (Configure_TimeGrid_Params)
if isfield(P, 'Pop_Weight_HH') && isstruct(P.Pop_Weight_HH)
    w_hh_row = ptype_to_row(P.Pop_Weight_HH, HH_Names, P.Pop_Weights_4);
else
    w_hh_row = P.Pop_Weights_4(:)';
end
w_hh_row = w_hh_row / sum(w_hh_row);
w_hh_col = w_hh_row(:); % [4 x 1] column operator for national inner products

% 1. Endogenous Kaiako Price-Manifold Deflator: G_ece_eff(Q_k) = G_ece * (Q_reg_base / Q_k)^nu_kaiako
%    Reads PType P.Q_reg_base first unless Q_reg_base_vec was explicitly re-anchored (e.g. 2023 HYEFU)
if isfield(P, 'Q_reg_base_vec') && ~isempty(P.Q_reg_base_vec)
    Q_base_row = P.Q_reg_base_vec(:)';
else
    Q_base_row = ptype_to_row(getfield_def(P, 'Q_reg_base', struct()), HH_Names, [1.03, 1.37, 2.00, 3.02]);
end
Q_now_row = getfield_def(P, 'Q_k_vec', ptype_to_row(getfield_def(P, 'Q_reg', struct()), HH_Names, Q_base_row));
nu_k      = getfield_def(P, 'nu_kaiako', 0.350);

P.Kaiako_Deflator_Vec = (Q_base_row ./ Q_now_row) .^ nu_k;
P.Kaiako_Deflator     = row_to_ptype(P.Kaiako_Deflator_Vec, HH_Names);

% 2. Sync all regional vectors to VFI-ready PType fields FIRST (HH_<Reg> & Firm_<Reg>)
[P, z_grid_Out] = sync_regional_fields(P, Regions, HH_Names, Firm_Names, Q_base_row, Q_now_row, scale_dt, z_grid_Out, is_reanchor);

% 3. Extract PType-Synced Regional Vectors [1 x 4] for Full-Distribution Cohesion & CPI
g1_sched0  = P.G_ece1_sched(1);     % 0.045 from SSOT
ygr_sched0 = P.YouthGrant_sched(1); % 0.030 from SSOT

G1_eff_row = ptype_to_row(P.G_ECE_1_eff,  HH_Names, repmat(g1_sched0, 1, 4));
Q_reg_row  = ptype_to_row(P.Q_reg,        HH_Names, Q_base_row);
v_abr_row  = ptype_to_row(P.V_Abroad_Add, HH_Names, zeros(1, 4));
zh_now_row = cellfun(@(f) P.z_f_grid.(f)(2), Firm_Names); % Includes Shock #2/#10/#15/#16 z_h shifts
zh_ref_row = [1.15, 1.28, 1.50, 1.75];

zeta_hardship = 125.0; % Sensitivity to struggling/hardship launch share (h_1..h_2)
zeta_ret      = 160.0; % Sensitivity to native youth skilled emigration (Abroad)
zeta_churn    =  85.0; % Penalty on excess replacement-migration turnover above bar_Churn

tau_l_now   = getfield_def(P, 'tau_l', 0.220);
tau_k_now   = getfield_def(P, 'tau_k', 0.250);
v_abroad_sc = getfield_def(P, 'V_Abroad_SkillPrem_Shift', 0.0);
y_grant     = getfield_def(P, 'YouthGrant', ygr_sched0);
coh_direct  = getfield_def(P, 'Cohesion_Shock_Pts', 0.0);

% [1 x 4] Regional Hardship & Emigration Shifts across PTypes
d_Strug_row = max(-0.205, -0.38 * (G1_eff_row - g1_sched0) ...
    + 0.045 * (Q_reg_row - Q_base_row) ...
    + 0.15  * (tau_l_now - 0.220));

d_Emig_row  = max(-0.050,  0.32  * (v_abroad_sc + v_abr_row) ...
    + 0.042 * (Q_reg_row  - Q_base_row) ...
    - 0.45  * (y_grant    - ygr_sched0) ...
    + 0.35  * (tau_l_now  - 0.220) ...
    + 0.18  * (tau_k_now  - 0.250) ...
    - 0.06  * (zh_now_row - zh_ref_row));
d_Churn_row = max(0.0, 0.65 * d_Emig_row);

% Regional baseline hardship shares from SSOT (P.base_struggle_vec = [19.8, 18.2, 15.6, 14.3]%)
base_strug_row = 0.01 * getfield_def(P, 'base_struggle_vec', [19.8, 18.2, 15.6, 14.3]);
% Derive baseline emigration from SSOT 4x5 Gumbel utility matrix u_target_4x5 if Base_Emig_Share unset:
if isfield(P, 'u_target_4x5') && isequal(size(P.u_target_4x5), [4, 5])
    exp_u         = exp(P.u_target_4x5);
    base_emig_row = (exp_u(:, 5) ./ sum(exp_u, 2))'; % [1 x 4] Abroad Gumbel probability
else
    base_emig_row = [0.018, 0.091, 0.234, 0.070];
end
base_emig_nat = getfield_def(P, 'Base_Emig_Share', base_emig_row * w_hh_col);

% Regional Social Cohesion S_{k,t} [1 x 4]: weights coh_direct by regional civic exposure so
% Wellington (Large k=3, weight 1.59x) hits -7.63 direct pts while national inner product = -4.80 pts:
civic_norm_row = [0.75, 0.85, 2.10, 1.35] / ([0.75, 0.85, 2.10, 1.35] * w_hh_col);
St_reg_row     = 100.0 - zeta_hardship * d_Strug_row ...
    - zeta_ret      * d_Emig_row  ...
    - zeta_churn    * d_Churn_row ...
    + coh_direct    * civic_norm_row;

% Contract [1 x 4] PType diagnostics with [4 x 1] SSOT Pop_Weights_4:
Meta.Struggling_By_PType     = row_to_ptype(base_strug_row + d_Strug_row, HH_Names);
Meta.Emig_By_PType           = row_to_ptype(base_emig_row  + d_Emig_row,  HH_Names);
Meta.Cohesion_St_By_PType    = row_to_ptype(St_reg_row,                   HH_Names);
Meta.Frac_Struggling_Imputed = (base_strug_row + d_Strug_row) * w_hh_col;
Meta.Emig_Nat_Imputed        = base_emig_nat + (d_Emig_row * w_hh_col);
Meta.Social_Cohesion_St      = St_reg_row * w_hh_col;
Meta.TI_Social_Credit_CPI    = 81.0 + 0.423 * (Meta.Social_Cohesion_St - 100.0);
end

function [P, z_grid_Out] = sync_regional_fields(P, Regions, HH_Names, Firm_Names, Q_base_row, Q_vec, scale_dt, z_grid_Out, is_reanchor)
w_direct_vec = getfield_def(P, 'w_k_vec',            ptype_to_row(getfield_def(P, 'w_reg',       struct()), HH_Names, [0.85, 0.93, 1.05, 1.18]));
ebar_vec     = getfield_def(P, 'ebar_k_vec',         ptype_to_row(getfield_def(P, 'ebar_energy', struct()), HH_Names, [0.048, 0.036, 0.022, 0.016]));
mu_base      = getfield_def(P, 'mu_maint_base',      0.0400);
mu_wedge_vec = getfield_def(P, 'mu_rates_wedge_vec', [0.0, 0.0, 0.0, 0.0]);
k_defl       = getfield_def(P, 'Kaiako_Deflator_Vec',[1, 1, 1, 1]);
G1_base      = getfield_def(P, 'G_ECE_1',            P.G_ece1_sched(1));
G2_base      = getfield_def(P, 'G_ECE_2',            P.G_ece2_sched(1));
zh_reg_mult  = getfield_def(P, 'Z_h_reg_mult',       [1, 1, 1, 1]);
v_abr_vec    = getfield_def(P, 'V_Abroad_Reg_Shift', [0, 0, 0, 0]);
lam_psy_vec  = getfield_def(P, 'lambda_psy_vec',     [0.38, 0.38, 0.38, 0.38]);
club_vec     = getfield_def(P, 'psi_club_buffer_vec',[1, 1, 1, 1]);

% 1. Sync Firm Productivity Ceilings [z_l; z_h] & GE Capital/TFP MPL Pass-Through to Regional Wages:
%    With Cobb-Douglas capital share alpha_k = 0.33 (alpha_k/(1-alpha_k) = 0.49), high-tech z_h
%    firm share ~60% implies ~0.45 wage elasticity wrt z_h, -0.28 wrt user-cost tax wedge tau_k
%    (Shock #11 Investment Boost), +0.08 wrt Guvenen collateral multiplier lambda_col (Shock #10 AIP),
%    and -1.20 wrt sovereign borrowing spread r_sov_spread (Shock #16 FTA risk premium).
def_zf_mat    = [0.70, 0.75, 0.83, 0.90; 1.15, 1.28, 1.50, 1.75];
zh_ref_vec    = [1.15, 1.28, 1.50, 1.75];
tau_k_delta   = getfield_def(P, 'tau_k', 0.250)      - 0.250;
lam_col_delta = getfield_def(P, 'lambda_col', 1.800) - 1.800;
r_spread_ann  = getfield_def(P, 'r_sov_spread', 0.0);
w_ge_vec      = w_direct_vec;

for k = 1:4
    zf_field = ['z_f_', Regions{k}];
    firm_tp  = Firm_Names{k};
    if isfield(P, zf_field) && numel(P.(zf_field)) >= 2
        zf_pair = P.(zf_field)(:);
    elseif isfield(P, 'z_f_grid') && isfield(P.z_f_grid, firm_tp)
        zf_pair = P.z_f_grid.(firm_tp)(:);
    else
        zf_pair = def_zf_mat(:, k);
    end
    zf_pair(2)           = zf_pair(2) * zh_reg_mult(k); % Apply Shock #15 & #16 z_h multiplier
    P.z_f_grid.(firm_tp) = zf_pair;
    if isstruct(z_grid_Out)
        z_grid_Out.(firm_tp) = zf_pair;
    end
    if ~is_reanchor
        d_ln_zh     = (zf_pair(2) - zh_ref_vec(k)) / zh_ref_vec(k);
        ge_cap_lift = -0.28 * tau_k_delta + 0.08 * lam_col_delta - 1.20 * r_spread_ann;
        ge_tfp_lift = 0.45 * d_ln_zh;
        w_ge_vec(k) = w_direct_vec(k) * (1.0 + ge_cap_lift + ge_tfp_lift);
    end
end

% 2. Sync VFI-Ready PType Fields & Scalars:
%    - Keep G_ece_stage1, G_ece_stage2, G_ece SCALAR because ReturnFn_SpatialHH (lines 71-73)
%      multiplies them by kaiako_cooling = (Q_reg_base / Q_reg)^0.35 internally, and
%      Build_IntergenTransitionMatrix (line 75) evaluates scalar (G_ece_stage2 - 0.045).
%    - Retain PType structs G_ECE_1_eff & G_ECE_2_eff for diagnostic verification tables.
P.Q_reg_base      = row_to_ptype(Q_base_row,             HH_Names);
P.Q_reg           = row_to_ptype(Q_vec,                  HH_Names);
P.w_reg           = row_to_ptype(w_ge_vec,               HH_Names, Firm_Names);
P.ebar_energy     = row_to_ptype(ebar_vec,               HH_Names);
P.mu_maint        = row_to_ptype(mu_base + mu_wedge_vec, HH_Names); % Baseline 4.0% + Shock #14 council rates wedge
P.upsilon_h_reg   = row_to_ptype(repmat(getfield_def(P, 'upsilon_h', 0.0095), 1, 4), HH_Names);
P.gbar_ece        = getfield_def(P, 'gbar_ece',          getfield_def(P, 'gbar_ECE', 0.020));
P.gbar_ECE        = P.gbar_ece; % Retained for diagnostic script backward compatibility

P.G_ece_stage1    = G1_base;
P.G_ece_stage2    = G2_base;
P.G_ece           = G1_base;
P.G_ECE_1_eff     = row_to_ptype(G1_base * k_defl,       HH_Names);
P.G_ECE_2_eff     = row_to_ptype(G2_base * k_defl,       HH_Names);

P.V_Abroad_Add    = row_to_ptype(v_abr_vec,              HH_Names);
P.lambda_psy      = row_to_ptype(lam_psy_vec,            HH_Names);
P.psi_club_buffer = row_to_ptype(club_vec,               HH_Names);

% 3. Compound Working-Age HC Depreciation delta_hc via SSOT scale_dt (0.087 per 5-yr benchmark):
hc_mult    = getfield_def(P, 'delta_hc_mult', 1.000);
P.delta_hc = 1 - (1 - min(0.45, 0.087 * hc_mult)) ^ scale_dt;

% 4. Update Active Regional Whanau & Civic Co-Production Network Capacity K_whanau(k):
%    Combines elder community housing retention ((Q_base/Q_now)^0.35), statutory NZ Super age
%    grandparent time availability, and Shock #15 Wedge 2 volunteer/CAB club buffer psi_club_buffer.
super_age_eff   = 20 + (P.Jr - 1) * P.dt;
elder_time_mult = exp(-P.eta_elder_whanau * max(0, super_age_eff - 65));
for k = 1:4
    hh_tp           = HH_Names{k};
    elder_home_mult = min(1.15, max(0.50, (P.p_super / 0.18) * ((Q_base_row(k) / Q_vec(k)) ^ 0.35)));
    club_mult       = 1.0;
    if ~is_reanchor
        club_mult = club_vec(k);
    end
    P.K_whanau.(hh_tp) = P.K_whanau_base.(hh_tp) * elder_time_mult * elder_home_mult * club_mult;
end
end

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

function row_vec = ptype_to_row(S, FieldNames, def_row)
if isstruct(S) && all(isfield(S, FieldNames))
    row_vec = cellfun(@(f) S.(f), FieldNames);
    row_vec = row_vec(:)';
else
    row_vec = def_row(:)';
end
end

function S = row_to_ptype(row_vec, PrimaryNames, SecondaryNames)
S = cell2struct(num2cell(row_vec(:)'), PrimaryNames, 2);
if nargin >= 3 && ~isempty(SecondaryNames)
    for k = 1:numel(SecondaryNames)
        S.(SecondaryNames{k}) = row_vec(k);
    end
end
end
