function Params = Configure_TimeGrid_Params(Params, dt, n_z_pts, DataSpec)
%% CONFIGURE_TIMEGRID_PARAMS
% Single Source of Truth for Time-Grid, Demographic, Spatial, Whanau, and
% Intergenerational Calibration Parameters across all 5D and 4D scripts.
% Wave 1 Three-Layer Contract Integration:
%   - Layer 1 (DataSpec)        : Load_Empirical_Profile (cohort, regions, currency, demography, moments)
%   - Layer 2 (RolloutSpec)     : Load_Rollout_Schedule  (kinematic wave staging & commissioning frictions)
%   - Layer 3 (ContingencySpec) : Load_Contingency_Policy (state-contingent phase/echelon unlock gates)

if nargin < 1 || isempty(Params)
    Params = struct();
end
if nargin >= 4 && ~isempty(DataSpec)
    if ischar(DataSpec) || isstring(DataSpec)
        DataSpec = Load_Empirical_Profile(DataSpec);
    end
elseif isfield(Params, 'DataSpec') && isstruct(Params.DataSpec) && isfield(Params.DataSpec, 'Digest')
    DataSpec = Load_Empirical_Profile(Params.DataSpec.Profile_ID);
elseif isfield(Params, 'Profile_Name') && ~isempty(Params.Profile_Name)
    DataSpec = Load_Empirical_Profile(Params.Profile_Name);
elseif isfield(Params, 'Calibration_Anchor') && ~isempty(Params.Calibration_Anchor)
    DataSpec = Load_Empirical_Profile(Params.Calibration_Anchor);
else
    DataSpec = Load_Empirical_Profile('NZ_Dunedin1972');
end

% Store portable DataSpec (without machine-local directory strings) inside Params for cache hashing
Params.Profile_ID         = DataSpec.Profile_ID;
Params.Calibration_Anchor = DataSpec.Legacy_Alias;
Params.DataSpec           = rmfield(DataSpec, {'Profile_Dir', 'Parent_Profile_Dir'});

if nargin < 2 || isempty(dt)
    if isfield(Params, 'dt') && ~isempty(Params.dt)
        dt = Params.dt;
    else
        dt = 5;
    end
end
if nargin < 3 || isempty(n_z_pts)
    if isfield(Params, 'n_z_pts') && ~isempty(Params.n_z_pts)
        n_z_pts = Params.n_z_pts;
    else
        n_z_pts = 7;
    end
end
Params.dt      = dt;
scale_dt       = dt / 5;  % Ratio relative to the 5-year calibration benchmark
Params.n_z_pts = n_z_pts; % N-point Rouwenhorst regional productivity grid

%% 1. LIFE-CYCLE HORIZON (AGES 20-99) & RETIREMENT BOUNDARY (AGE 65)
Params.J    = round(80 / dt);           % 16 (dt=5), 27 (dt=3), 40 (dt=2)
Params.Jr   = 1 + round(45 / dt);       % 10 (dt=5), 16 (dt=3), 23 (dt=2)
Params.agej = 1:Params.J;

%% 2. CHILDHOOD & LIFECYCLE HUMAN CAPITAL WINDOWS
Params.j_s1_start     = 1 + round(10 / dt);               % Age 30: j=3 (dt=5), j=4 (dt=3), j=6 (dt=2)
Params.n_stage1_steps = max(1, round(5 / dt));            % 1 (dt=5), 2 (dt=3), 3 (dt=2)
Params.j_s1_end       = Params.j_s1_start + Params.n_stage1_steps - 1;

Params.j_s2_start     = Params.j_s1_end + 1;              % Age 35: j=4 (dt=5), j=6 (dt=3), j=9 (dt=2)
Params.n_stage2_steps = max(1, round(5 / dt));            % 1 (dt=5), 2 (dt=3), 3 (dt=2)
Params.j_s2_end       = Params.j_s2_start + Params.n_stage2_steps - 1;

Params.j_child_launch = min(Params.J, Params.j_s2_end + 1); % j=5 (dt=5), j=8 (dt=3), j=12 (dt=2)

%% 3. TREASURY OLG SURVIVAL, FERTILITY, & MIGRATION VECTORS (INTERPOLATED TO J)
sj_5yr  = DataSpec.Demography_5yr.sj(:)';
fj_5yr  = DataSpec.Demography_5yr.fj(:)';
mig_5yr = DataSpec.Demography_5yr.mig_rate_j(:)';
Params.sj_5yr_ref = sj_5yr; % Retained for dt-invariant OLG cohort pyramid benchmarks

if dt == 5 && numel(sj_5yr) == Params.J
    Params.sj         = sj_5yr;
    Params.fj         = fj_5yr;
    Params.mig_rate_j = mig_5yr;
else
    age_5yr_mid = DataSpec.Demography_5yr.Age_Mid(:)';
    age_dt_mid  = linspace(20 + dt/2, 100 - dt/2, Params.J);

    sj_interp         = interp1(age_5yr_mid, sj_5yr, age_dt_mid, 'pchip');
    Params.sj         = max(0, min(0.999, sj_interp)) .^ scale_dt;
    Params.sj(end)    = 0.0;

    Params.fj         = max(0, interp1(age_5yr_mid, fj_5yr, age_dt_mid, 'linear', 0)) * scale_dt;
    Params.mig_rate_j = interp1(age_5yr_mid, mig_5yr, age_dt_mid, 'linear', 0) * scale_dt;
end

%% 4. COMPOUNDED DISCOUNT, RETURN, DEPRECIATION, & TRANSITION RATES
Params.beta_hh   = 0.985^dt;
Params.beta_firm = 0.9815^dt;
if ~isfield(Params, 'r');         Params.r         = (1 + 0.20)^scale_dt - 1; end
if ~isfield(Params, 'delta_hc');  Params.delta_hc  = 1 - (1 - 0.087)^scale_dt; end
if ~isfield(Params, 'delta_k');   Params.delta_k   = 1 - (1 - 0.06)^dt; end

Params.T_trans_years = 60;
Params.T_trans       = round(Params.T_trans_years / dt); % 12 (dt=5), 20 (dt=3), 30 (dt=2)
Params.zeta_cohort   = 1 - (1 - 0.085)^scale_dt;

%% 5. CANONICAL REGIONAL POPULATION, WHANAU, HARDSHIP, & MIGRATION CALIBRATION (FROM LAYER 1 DATASPEC)
N_reg_ds              = DataSpec.N_reg;
Reg_Names_ds          = DataSpec.Regions;
RT_ds                 = DataSpec.Reg_Table;
Params.N_reg          = N_reg_ds;
Params.Regions        = Reg_Names_ds;
Params.Reg_Names_4    = Reg_Names_ds;
Params.Reg_Names_5    = DataSpec.Reg_Names_Plus_Nat;
Params.External_Dest_Label    = DataSpec.External_Dest_Label;
Params.Primate_Region_ID      = DataSpec.Primate_Region_ID;
Params.Primate_Region_Idx     = DataSpec.Primate_Region_Idx;
Params.Primate_HH_Type        = ['HH_', DataSpec.Primate_Region_ID];
Params.Representative_Urban_ID  = DataSpec.Representative_Urban_ID;
Params.Representative_Urban_Idx = DataSpec.Representative_Urban_Idx;

if ~isfield(Params, 'Pop_Weights_4'),  Params.Pop_Weights_4  = DataSpec.Pop_Shares;  end
if ~isfield(Params, 'Firm_Weights_4'), Params.Firm_Weights_4 = DataSpec.Firm_Shares; end
Params.Pop_Weights_5  = [Params.Pop_Weights_4, 1.000]; % Final column = National (100% population weight)
ech_idx_col           = DataSpec.Echelon_Idx(:);
Params.Pop_Weights_3  = accumarray(ech_idx_col, Params.Pop_Weights_4(:), [DataSpec.N_Echelons, 1])';

% Generalized Monetary & Reporting Anchors (with legacy NZD aliases retained for compatibility)
Params.Currency_ISO           = DataSpec.Monetary.Currency_ISO;
Params.Currency_Symbol        = DataSpec.Monetary.Currency_Symbol;
Params.Currency_Unit_Billions = DataSpec.Monetary.Currency_Unit_Billions;
Params.Currency_Base_Year     = DataSpec.Monetary.Base_Year;
Params.Currency_Base_Scale    = DataSpec.Monetary.Currency_Base_Scale;
Params.CE_Monetary_Scale_Nat  = DataSpec.Monetary.CE_Monetary_Scale_Nat;
Params.GDP_Base_Billions      = DataSpec.Monetary.GDP_Base_Billions;
Params.NZD_Per_CE_Nat         = Params.CE_Monetary_Scale_Nat;
Params.GDP_2026_BNZD          = Params.GDP_Base_Billions;
Params.Estate_Exemption       = DataSpec.Institutions.Estate_Exemption;
Params.Target_NetMig_Rate     = DataSpec.Institutions.Target_NetMig_Rate;
Params.w_External             = DataSpec.Institutions.w_External;
Params.Q_External             = DataSpec.Institutions.Q_External;

Params.K_whanau_base_vec = RT_ds.K_whanau_base(:)';
for r_i = 1:N_reg_ds
    hh_k   = ['HH_',   Reg_Names_ds{r_i}];
    firm_k = ['Firm_', Reg_Names_ds{r_i}];
    if ~isfield(Params, 'K_whanau_base') || ~isfield(Params.K_whanau_base, hh_k)
        Params.K_whanau_base.(hh_k) = RT_ds.K_whanau_base(r_i);
    end
    if ~isfield(Params, 'Q_reg_base') || ~isfield(Params.Q_reg_base, hh_k)
        Params.Q_reg_base.(hh_k) = RT_ds.Q_base(r_i);
    end
    if ~isfield(Params, 'w_reg_base') || ~isfield(Params.w_reg_base, hh_k)
        Params.w_reg_base.(hh_k)   = RT_ds.w_base(r_i);
        Params.w_reg_base.(firm_k) = RT_ds.w_base(r_i);
    end
    if ~isfield(Params, 'Q_reg') || ~isfield(Params.Q_reg, hh_k)
        Params.Q_reg.(hh_k) = RT_ds.Q_base(r_i);
    end
    if ~isfield(Params, 'w_reg') || ~isfield(Params.w_reg, hh_k)
        Params.w_reg.(hh_k)   = RT_ds.w_base(r_i);
        Params.w_reg.(firm_k) = RT_ds.w_base(r_i);
    end
    if ~isfield(Params, 'delta_H') || ~isfield(Params.delta_H, hh_k)
        Params.delta_H.(hh_k) = RT_ds.delta_H(r_i);
    end
    if ~isfield(Params, 'G_reg') || ~isfield(Params.G_reg, hh_k)
        Params.G_reg.(hh_k) = RT_ds.G_trend(r_i);
    end
    if ~isfield(Params, 'ebar_energy') || ~isfield(Params.ebar_energy, hh_k)
        Params.ebar_energy.(hh_k) = RT_ds.ebar_energy(r_i);
    end
    if ~isfield(Params, 'Transfer_Geo') || ~isfield(Params.Transfer_Geo, hh_k)
        Params.Transfer_Geo.(hh_k) = RT_ds.Transfer_Geo(r_i);
    end
end
if ~isfield(Params, 'K_whanau')
    Params.K_whanau = Params.K_whanau_base;
end

% Canonical regional early hardship targets (%) & launch skill drift vector
Params.base_struggle_vec = RT_ds.struggle_pct(:)';
Params.reg_skill_drift   = RT_ds.skill_drift(:)';

% Canonical N_reg x (N_reg + 1) Gumbel migration utility matrix [Regions..., External]
Params.u_target_4x5 = DataSpec.u_target_mig;

% Canonical Daruich (2018) regional endogenous intergenerational skill & retention lift
Params.daruich_ig_mult = RT_ds.daruich_mult(:)';

if ~isfield(Params, 'leak_rate_super_up'), Params.leak_rate_super_up = 0.45; end % 45% disability/hardship leak when age > 65
if ~isfield(Params, 'offset_super_down'),  Params.offset_super_down  = 0.25; end % 25% ACC/Jobseeker savings when age < 65

%% 6. NAMED PARAMETERS FOR NZ SUPER ELIGIBILITY AGE, SENESCENCE, & WHANAU CARE ELASTICITIES
% Literature Anchors:
%   - Rupert & Zanella (2018, J. Labor Econ.) / Compton & Pollak (2014): Grandparent childcare time elasticity
%   - Fan, Seshadri, & Taber (2022) / French (2005, RES): Late-life wage senescence & labor disutility slope
%   - Case & Deaton (2005) / Coe & Van Houtven (2009): Age-morbidity decay & sandwich elder-care labor drag
if ~isfield(Params, 'super_age_base'),           Params.super_age_base           = DataSpec.Institutions.Super_Age_Base; end % Statutory Super baseline age
if ~isfield(Params, 'super_age_SS1'),            Params.super_age_SS1            = DataSpec.Institutions.Super_Age_SS1;  end % Phase 1 (SS1) Super age
if ~isfield(Params, 'super_age_SS2'),            Params.super_age_SS2            = DataSpec.Institutions.Super_Age_SS2;  end % Phase 2 (SS2) Super target age
if ~isfield(Params, 'eta_elder_whanau'),         Params.eta_elder_whanau         = 0.090; end % 9%/yr grandparent time loss for Super > 65
if ~isfield(Params, 'kappa_kuia_max'),           Params.kappa_kuia_max           = 0.160; end % +16% max Kuia/Koroua time boost for Super < 65
if ~isfield(Params, 'tau_kuia_sat'),             Params.tau_kuia_sat             = 1.800; end % Concave saturation scale (yrs below 65)
if ~isfield(Params, 'delta_senescence_post65'),  Params.delta_senescence_post65  = 0.080; end % 8%/yr physiological earning decay past 65
if ~isfield(Params, 'psi_wear_post65'),          Params.psi_wear_post65          = 0.140; end % Annual late-life work disutility slope past 65
if ~isfield(Params, 'psi_wear_early_relief'),    Params.psi_wear_early_relief    = 0.380; end % Pre-65 manual wear relief when Super < 65
if ~isfield(Params, 'theta_healthy_wrk_65'),     Params.theta_healthy_wrk_65     = 0.480; end % Healthy full-time work share among displaced 65yo
if ~isfield(Params, 'lambda_health_decay_65'),   Params.lambda_health_decay_65   = 0.180; end % Morbidity decay rate per yr above 65
if ~isfield(Params, 'phi_geriatric_leak_base'),  Params.phi_geriatric_leak_base  = 1.150; end % Base disability/hospital leak mult (>65)
if ~isfield(Params, 'phi_geriatric_leak_slope'), Params.phi_geriatric_leak_slope = 0.085; end % Annual geriatric hospital leak escalation (>65)
if ~isfield(Params, 'psi_sandwich_wrk_drag'),    Params.psi_sandwich_wrk_drag    = 0.350; end % Adult-child caregiver tax-base drag per sick elder
if ~isfield(Params, 'omega_acc_offset_under65'), Params.omega_acc_offset_under65 = 0.280; end % Age-64 ACC/disability offset share (<65)
if ~isfield(Params, 'lambda_offset_decay_u65'),  Params.lambda_offset_decay_u65  = 0.850; end % Decay rate of ACC offset for younger ages 60-63
if ~isfield(Params, 'nu_peak_earn_u65'),         Params.nu_peak_earn_u65         = 1.050; end % Base tax-capacity weight of 60-64 peak earners
if ~isfield(Params, 'nu_peak_earn_slope_u65'),   Params.nu_peak_earn_slope_u65   = 0.040; end % Additional tax-capacity loss per yr below 65
if ~isfield(Params, 'dep_ratio_2026_anchor'),    Params.dep_ratio_2026_anchor    = DataSpec.Institutions.Dep_Ratio_Anchor; end % OLG dependency ratio anchor at tau_l = 22%
if ~isfield(Params, 'beta_aging_tax_drift'),     Params.beta_aging_tax_drift     = 0.220; end % Marginal PAYE tax sensitivity to dependency ratio
if ~isfield(Params, 'beta_exits_skill_div'),     Params.beta_exits_skill_div     = 0.145; end % Marginal PAYE tax relief per pp of early hardship cut

%% 7. CANONICAL REGIME SCHEDULES & LOCAL PROCUREMENT / MENTORING (z_l -> z_h) UPGRADING
% Literature & Empirical Anchors:
%   - Jon Duffy (Consumer NZ) / Commerce Commission: Retail duopoly & farm-gate monopsony rent extraction
%     blocking rural/provincial enterprise capital formation and trapping regions in low-wage z_l equilibria.
%   - NC State CEFS Farm to ECE (Cosco et al. 2022; Color Me Healthy RCT): +24% to +33% preschool vegetable
%     intake (d = 1.20), +26.6 pp parent nutrition crowding-in (53.5% -> 80.1%), 46% take-home garden produce.
%   - NC State CEFS 2025-2026 Local Food Purchasing Incentive (LFPI) & Bloom et al. (2022): Directing upfront
%     working capital via regional food hubs yields a 1.60x-2.16x local economic multiplier.
%   - NC State CEFS Food Youth Initiative (FYI) & GrowingChange (Sanford): Paid youth agricultural leadership
%     and food-hub apprenticeships achieve a 92% non-recidivism rate and retain skilled rural youth.
if ~isfield(Params, 'Enable_Duopoly_Kai'), Params.Enable_Duopoly_Kai = false; end

% Canonical National Policy Schedules across [SS0, SS1, SS2] (from DataSpec.Regime_Schedules & Reg_Table):
Params.G_ece1_sched     = DataSpec.Regime_Schedules.G_ece1_sched(:)';     % Gate 1 (Ages 0-5) national public investment schedule
Params.G_ece2_sched     = DataSpec.Regime_Schedules.G_ece2_sched(:)';     % Gate 2 (Ages 6-17) national public investment schedule
Params.YouthGrant_sched = DataSpec.Regime_Schedules.YouthGrant_sched(:)'; % Age-20 Opportunity Endowment schedule
Params.w_mult_SS0       = ones(1, N_reg_ds);
Params.w_mult_SS1       = RT_ds.w_mult_SS1(:)';
Params.w_mult_SS2       = RT_ds.w_mult_SS2(:)';
Params.Q_mult_SS0       = ones(1, N_reg_ds);
Params.Q_mult_SS1       = RT_ds.Q_mult_SS1(:)';
Params.Q_mult_SS2       = RT_ds.Q_mult_SS2(:)';

% Regional Duopoly, Monopsony, & Local Food vectors ordered by DataSpec.Regions
% Retained for full compatibility with FertilityBargaining_Module and suite scripts
Params.M_olig_SS0          = RT_ds.M_olig_SS0(:)';    % Status quo grocery duopoly markup
Params.M_olig_SS1          = RT_ds.M_olig_SS1(:)';    % Phase-1 Commerce Commission + Co-op reform
Params.M_olig_SS2          = RT_ds.M_olig_SS2(:)';    % Phase-2 full competitive convergence
Params.alpha_food_nd_vec   = RT_ds.alpha_food_nd(:)'; % Cardinal-calibrated grocery incidence
Params.mu_monop_SS0        = RT_ds.mu_monop_SS0(:)';  % Farm-gate wholesale monopsony markdown
Params.mu_monop_SS1        = RT_ds.mu_monop_SS1(:)';  % Grocery supply code + grower bargaining
Params.mu_monop_SS2        = RT_ds.mu_monop_SS2(:)';  % Full farm-gate price parity
Params.phi_local_SS0       = RT_ds.phi_local_SS0(:)'; % SS0 local school/marae food share
Params.phi_local_SS1       = RT_ds.phi_local_SS1(:)'; % SS1 Farm-to-School & Farm-to-Marae switch
Params.phi_local_SS2       = RT_ds.phi_local_SS2(:)'; % SS2 mature regional food hubs
Params.kappa_olig_schedule = [0.000, 0.700, 1.000];        % [SS0, SS1, SS2] enforcement intensity
Params.G_food_share        = 0.012; % Public school/ECE nutrition procurement budget
Params.chi_farm_col        = 0.120; % Collateral relaxation from bankable local food contracts
Params.kappa_bypass_olig   = 0.250; % Direct Farm-to-Marae/Co-op household bypass of retail markup
Params.nu_kai_quality      = 0.180; % Fresh local kai nutritional efficacy elasticity (Ka Ora, Ka Ako)
Params.psi_retire_T        = 0.850; % Rate at which duopoly/monopsony relief retires Transfer_Geo
Params.T_reg_min_floor     = [0.008, 0.005, 0.000, 0.000]; % Residual remote-geography floor
Params.rho_olig_vec        = [0.008, 0.007, 0.005, 0.004] * scale_dt; % Passive z_l oligopoly rent yield
Params.rho_farm_vec        = [0.002, 0.002, 0.001, 0.001] * scale_dt; % Active z_h local kai contract yield

% If caller passed scalar G_ece_stage1 / G_ece_stage2 / G_ece, promote to *_base and reset to struct()
if isfield(Params, 'G_ece_stage1') && ~isstruct(Params.G_ece_stage1)
    Params.G_ece_stage1_base = Params.G_ece_stage1;
end
if isfield(Params, 'G_ece_stage2') && ~isstruct(Params.G_ece_stage2)
    Params.G_ece_stage2_base = Params.G_ece_stage2;
end
if isfield(Params, 'G_ece') && ~isstruct(Params.G_ece)
    Params.G_ece_base = Params.G_ece;
end

if ~isfield(Params, 'G_ece_stage1_base'),   Params.G_ece_stage1_base   = Params.G_ece1_sched(1); end
if ~isfield(Params, 'G_ece_stage2_base'),   Params.G_ece_stage2_base   = Params.G_ece2_sched(1); end
if ~isfield(Params, 'G_ece_base'),          Params.G_ece_base          = Params.G_ece_stage1_base; end
if ~isfield(Params, 'active_M_olig_vec'),    Params.active_M_olig_vec    = Params.M_olig_SS0;    end
if ~isfield(Params, 'active_mu_monop_vec'),  Params.active_mu_monop_vec  = Params.mu_monop_SS0;  end
if ~isfield(Params, 'active_phi_local_vec'), Params.active_phi_local_vec = Params.phi_local_SS0; end

% Reset to struct() so Octave never errors when converting a double to a regional struct
Params.G_ece_stage1    = struct();
Params.G_ece_stage2    = struct();
Params.G_ece           = struct();
Params.M_olig_reg      = struct();
Params.mu_monop_reg    = struct();
Params.rho_olig_reg    = struct();
Params.rho_farm_reg    = struct();
Params.lambda_col_mult = struct();

% Single-Source-of-Truth Regional Struct Population for PType Solvers
Reg_Names = Reg_Names_ds;
duo_on    = double(logical(Params.Enable_Duopoly_Kai));
for r_idx = 1:N_reg_ds
    hh_type   = ['HH_', Reg_Names{r_idx}];
    firm_type = ['Firm_', Reg_Names{r_idx}];
    m_k       = Params.active_M_olig_vec(r_idx);
    alpha_f_k = Params.alpha_food_nd_vec(r_idx);
    mu_k      = Params.active_mu_monop_vec(r_idx);
    phi_k     = Params.active_phi_local_vec(r_idx);
    phi_0     = Params.phi_local_SS0(r_idx);

    % 1. Additive bioavailability/attendance gain on the G_food_share nutrition slice:
    dG_kai_k = duo_on * Params.G_food_share * Params.nu_kai_quality * sqrt(max(0.0, phi_k - phi_0));
    Params.G_ece_stage1.(hh_type) = Params.G_ece_stage1_base + 1.25 * dG_kai_k;
    Params.G_ece_stage2.(hh_type) = Params.G_ece_stage2_base + 0.85 * dG_kai_k;
    Params.G_ece.(hh_type)        = Params.G_ece_base        + 1.00 * dG_kai_k;

    % 2. Composite non-durable price index M_olig_reg weighted by grocery incidence alpha_food_nd_vec(r_idx)
    Params.M_olig_reg.(hh_type)   = 1.0 + duo_on * alpha_f_k * (1.0 - Params.kappa_bypass_olig * phi_k) * (m_k - 1.0);

    % 3. Firm monopsony markdown, passive z_l oligopoly rent, & active z_h local kai contract yield
    Params.mu_monop_reg.(firm_type)    = 1.0 - duo_on * (1.0 - mu_k);
    Params.rho_olig_reg.(firm_type)    = duo_on * Params.rho_olig_vec(r_idx) * max(0.0, (m_k - 1.0) / max(1e-4, Params.M_olig_SS0(r_idx) - 1.0));
    Params.rho_farm_reg.(firm_type)    = duo_on * Params.rho_farm_vec(r_idx) * (phi_k / max(1e-4, phi_0));
    Params.lambda_col_mult.(firm_type) = 1.0 + duo_on * Params.chi_farm_col * phi_k;
end

% 4. Endogenous Regional z_l -> z_h Job & Enterprise Upgrading (Ka Ora, Ka Ako & CEFS LFPI / FYI):
% In SS0, wholesale monopsony extraction & casualization depress Rural (-0.060) and Small (-0.010) job quality (z_l).
% As Gate 1/2 local procurement (1.60x-2.16x LFPI multiplier) & FYI youth career pathways scale up from SS0 to SS2,
% Rural and Small communities bypass rent-seeking intermediaries and upgrade z_l -> z_h:
Params.mu_z_SS0    = RT_ds.mu_z_SS0(:)';
Params.mu_z_SS2    = RT_ds.mu_z_SS2(:)';
Params.sigma_z_vec = RT_ds.sigma_z(:)';

ref_hh_first = ['HH_', Reg_Names{1}];
g1_scalar = Params.G_ece_stage1_base;
if isfield(Params, 'G_ece_stage1')
    if isstruct(Params.G_ece_stage1), g1_scalar = Params.G_ece_stage1.(ref_hh_first); else, g1_scalar = Params.G_ece_stage1; end
end
g2_scalar = Params.G_ece_stage2_base;
if isfield(Params, 'G_ece_stage2')
    if isstruct(Params.G_ece_stage2), g2_scalar = Params.G_ece_stage2.(ref_hh_first); else, g2_scalar = Params.G_ece_stage2; end
end

ece1_prog = (g1_scalar - Params.G_ece1_sched(1)) / max(1e-4, Params.G_ece1_sched(3) - Params.G_ece1_sched(1));
ece2_prog = (g2_scalar - Params.G_ece2_sched(1)) / max(1e-4, Params.G_ece2_sched(3) - Params.G_ece2_sched(1));
phi_prog  = (Params.active_phi_local_vec(1) - Params.phi_local_SS0(1)) / max(1e-4, Params.phi_local_SS2(1) - Params.phi_local_SS0(1));
Params.kai_upgrade_share = min(1.0, max(0.0, max(0.50 * ece1_prog + 0.50 * ece2_prog, phi_prog)));

% Active regional log(z) Rouwenhorst mean drift & Firm z_l -> z_h Markov transition probabilities:
Params.mu_z_reg_vec     = Params.mu_z_SS0 + Params.kai_upgrade_share * (Params.mu_z_SS2 - Params.mu_z_SS0);
Params.p_zh_upgrade_vec = [0.15, 0.15, 0.15, 0.15] + Params.kai_upgrade_share * [0.08, 0.06, 0.03, 0.01];
Params.p_zl_downgrade_v = [0.15, 0.15, 0.15, 0.15] - Params.kai_upgrade_share * [0.05, 0.04, 0.02, 0.00];

%% 8. Long-term (SS2) Macro Investment Parameters & 13-Wave Te Kāhui Waka Implementation Mechanics
if ~isfield(Params, 'ss2_harvest_div_base'),     Params.ss2_harvest_div_base     = 2.070; end % SS2 debt-sinking (-60 bps) + GE tax-base dividend (pp)
if ~isfield(Params, 'psi_austerity_tax_drag'),   Params.psi_austerity_tax_drag   = 0.220; end % SS2 harvest erosion coefficient when Super > 65

% --- Implementation Friction (tau_friction), Workforce Bottleneck (phi_adj), & Inter-Wave Learning (gamma_learning) ---
% Rollout_Mode:
%   - 'SingleShot'          : 100% Day-1 step shock (suffers full tau_friction_0 = 0.28 & phi_adj*(1.0)^2 = 0.18 bottleneck drag)
%   - 'TeKahuiWaka'         : 13-Wave phased rollout (1/3 regional steps cut phi_adj by 88.9% & compound inter-wave learning)
%   - 'Frictionless_Textbook': Legacy 0-friction textbook upper bound (tau_friction = 0, phi_adj = 0)
% Resolve Layer 3 Contingency Policy & Layer 2 Rollout Schedule Contracts
if ~isfield(Params, 'Contingency_Policy') || isempty(Params.Contingency_Policy)
    Params.Contingency_Policy = 'fixed_calendar_2050';
end
ContingencySpec        = Load_Contingency_Policy(DataSpec, Params.Contingency_Policy);
Params.ContingencySpec = ContingencySpec;

if ~isfield(Params, 'Rollout_Mode') || isempty(Params.Rollout_Mode)
    Params.Rollout_Mode = ContingencySpec.Default_Rollout_Mode;
end
RolloutSpec        = Load_Rollout_Schedule(DataSpec, Params.Rollout_Mode);
Params.RolloutSpec = RolloutSpec;

if ~isfield(Params, 'tau_friction_0'),           Params.tau_friction_0           = RolloutSpec.tau_friction_0;     end % Day-1 uncalibrated commissioning overhead (Coase-North)
if ~isfield(Params, 'tau_friction_floor'),       Params.tau_friction_floor       = RolloutSpec.tau_friction_floor; end % Mature Whanau Ora / high-trust asymptotic friction floor
if ~isfield(Params, 'gamma_learning'),           Params.gamma_learning           = RolloutSpec.gamma_learning;     end % Arrow (1962) / Deming PDSA inter-wave learning rate
if ~isfield(Params, 'phi_adj_bottleneck'),       Params.phi_adj_bottleneck       = RolloutSpec.phi_adj_bottleneck; end % Lucas-Hayashi quadratic workforce surge penalty on (Delta_s)^2
if ~isfield(Params, 'delta_adopt_ece'),          Params.delta_adopt_ece          = RolloutSpec.delta_adopt_ece;    end % Local ECE/mentoring cohort ramp-up lag amplitude
if ~isfield(Params, 'lambda_adopt_ece'),         Params.lambda_adopt_ece         = RolloutSpec.lambda_adopt_ece;   end % Local adoption speed (yr^-1)
if ~isfield(Params, 'ebar_elec_relief_share'),   Params.ebar_elec_relief_share   = RT_ds.ebar_elec_relief(:)';     end % Rewiring Aotearoa net ebar_energy compression
if ~isfield(Params, 'T_ramp_LVT_yrs'),           Params.T_ramp_LVT_yrs           = RolloutSpec.T_ramp_LVT_yrs;     end % Linear phase-in for 1.5% Land Value / Wealth Tax
if ~isfield(Params, 'T_ramp_CGT_Est_yrs'),       Params.T_ramp_CGT_Est_yrs       = RolloutSpec.T_ramp_CGT_Est_yrs; end % Fast phase-in for Capital Gains & Estate Levy
if ~isfield(Params, 'T_ramp_CorpCut_yrs'),       Params.T_ramp_CorpCut_yrs       = RolloutSpec.T_ramp_CorpCut_yrs; end % Synchronized corporate tax cut alongside LVT

% --- Canonical Existing Gate-3 Mentoring Base & Layer 2 Wave Matrices ---
if ~isfield(Params, 'sh_ygr_base0_vec'), Params.sh_ygr_base0_vec = RT_ds.sh_ygr_base0(:)'; end
w4_col = Params.Pop_Weights_4(:);
b4_row = Params.sh_ygr_base0_vec(:)';

Params.sh_ygr_base0_nat      = b4_row * w4_col;
Params.sh_ygr_base0_5        = [b4_row, Params.sh_ygr_base0_nat];
Params.sh_ygr_base0_3echelon = RolloutSpec.sh_ygr_base0_echelon;

% Echelon-level [N_waves x N_echelons] and Region+National [N_waves x (N_reg + 1)] matrices from RolloutSpec:
Params.Waves_13            = RolloutSpec.Rel_Years(:);
Params.Kahui_ECE_13x3      = RolloutSpec.ECE_Echelon;
Params.Kahui_Mnt_13x3      = RolloutSpec.Mnt_Echelon;
Params.Kahui_YGr_New_13x3  = RolloutSpec.YGr_New_Echelon;
Params.Kahui_YGr_Tot_13x3  = RolloutSpec.YGr_Tot_Echelon;
Params.Kahui_Elc_13x3      = RolloutSpec.Elc_Echelon;

% Recompute YGr_Tot if caller explicitly overrode Params.sh_ygr_base0_vec
YGr_New_Reg_mat            = RolloutSpec.YGr_New_RegNat(:, 1:N_reg_ds);
YGr_Tot_Reg_mat            = b4_row + (1.0 - b4_row) .* YGr_New_Reg_mat;
Params.Kahui_ECE_13x5      = RolloutSpec.ECE_RegNat;
Params.Kahui_Mnt_13x5      = RolloutSpec.Mnt_RegNat;
Params.Kahui_YGr_New_13x5  = RolloutSpec.YGr_New_RegNat;
Params.Kahui_YGr_Tot_13x5  = [YGr_Tot_Reg_mat, YGr_Tot_Reg_mat * w4_col];
Params.Kahui_Elc_13x5      = RolloutSpec.Elc_RegNat;

% Evaluate regime-level effective delivery multiplier eta_delivery_reg [1 x N_reg]:
Params.eta_delivery_SS1    = RolloutSpec.eta_delivery_SS1;
Params.eta_delivery_SS2    = RolloutSpec.eta_delivery_SS2;

N_waves_ro = RolloutSpec.N_Waves;
if isfield(Params, 't_wave_yr') && ~isempty(Params.t_wave_yr) && Params.t_wave_yr >= 1 && Params.t_wave_yr <= N_waves_ro
    w_idx = round(Params.t_wave_yr);
    Params.s_active_ece_vec  = Params.Kahui_ECE_13x5(w_idx, 1:N_reg_ds);
    Params.s_active_ygr_vec  = Params.Kahui_YGr_Tot_13x5(w_idx, 1:N_reg_ds);
    Params.s_active_elec_vec = Params.Kahui_Elc_13x5(w_idx, 1:N_reg_ds);
else
    if ~isfield(Params, 's_active_ece_vec'),  Params.s_active_ece_vec  = ones(1, N_reg_ds); end
    if ~isfield(Params, 's_active_ygr_vec'),  Params.s_active_ygr_vec  = ones(1, N_reg_ds); end
    if ~isfield(Params, 's_active_elec_vec'), Params.s_active_elec_vec = ones(1, N_reg_ds); end
end
if ~isfield(Params, 'eta_deliv_vec'), Params.eta_deliv_vec = Params.eta_delivery_SS1; end

% Apply effective delivery yield (eta_deliv_vec) to the reform increment above SS0 baseline:
for r_idx = 1:N_reg_ds
    hh_type = ['HH_', Reg_Names{r_idx}];
    eta_k   = Params.eta_deliv_vec(r_idx);
    g1_0    = Params.G_ece1_sched(1);
    g2_0    = Params.G_ece2_sched(1);
    Params.G_ece_stage1.(hh_type) = g1_0 + eta_k * (Params.G_ece_stage1.(hh_type) - g1_0);
    Params.G_ece_stage2.(hh_type) = g2_0 + eta_k * (Params.G_ece_stage2.(hh_type) - g2_0);
    Params.G_ece.(hh_type)        = g1_0 + eta_k * (Params.G_ece.(hh_type)        - g1_0);
    Params.s_active_ece.(hh_type) = Params.s_active_ece_vec(r_idx);
end


end
