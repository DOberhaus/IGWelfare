%% 60-YEAR NON-LINEAR TRANSITION PATH & DYNAMIC PTYPEWEIGHTS (MULTIPHASE: SS0 -> SS1 -> SS2+)
% File: TransPath_4Region_Master.m
% Automatically adapts to the active number of reform phases in WelfareResults / Phases:
%   - If 1 Reform Phase (SS0 -> SS1): Reproduces the exact 2-phase Daruich, Kiyotaki, and
%     Brain-Drain / Social Cohesion trajectories.
%   - If >= 2 Reform Phases (SS0 -> SS1 -> SS2+): Incorporates the Phase-2 (2050 Debt-Sinking
%     & Tax-Relief Dividend) transition leg starting at Year T_phase2_yr (default: Year 25),
%     and compares Pre-Announced Full Credibility (lambda_cred = 1) vs Unannounced MIT Shock
%     (lambda_cred = 0 prior to T_phase2_yr).

if ~exist('Params', 'var') || ~isfield(Params, 'dt') || ~isfield(Params, 'Q_reg_base')
    Params = Configure_TimeGrid_Params(Params, 5);
end

dt          = Params.dt;
T_years     = 60;
T_trans     = round(T_years / dt);
Trans_Years = (0 : (T_trans - 1))' * dt;
N_reg       = length(Regions);

% Detect whether multiphase (SS2+) is active in WelfareResults or Phases
has_SS2 = (exist('WelfareResults', 'var') && isfield(WelfareResults, 'SS2')) || ...
    (exist('Phases', 'var') && numel(Phases) >= 3);

if ~exist('T_phase2_yr', 'var') || isempty(T_phase2_yr)
    T_phase2_yr = 25; % 2050 Sovereign Debt-Sinking & Tax-Relief Trigger (25 yrs after 2025/26 launch)
end
if ~exist('Phase2_Announcement_Mode', 'var') || isempty(Phase2_Announcement_Mode)
    % 'PreAnnounced' (lambda_cred = 1.0), 'EarnedCred' (ramps 0.25 -> 1.0), or 'Unannounced_MIT' (0 -> 1 at T_phase2_yr)
    Phase2_Announcement_Mode = 'PreAnnounced';
end

%% 1. DYNAMIC REGIONAL POPULATION LAW OF MOTION (s_HH,t: 4x4 DOMESTIC SORTING + INTL INFLOWS)
s_HH_path = zeros(T_trans, N_reg);
s_HH_0    = [0.200, 0.230, 0.270, 0.300];
if isfield(Params, 'PTypeWeights') && numel(Params.PTypeWeights) >= N_reg
    s_HH_0 = Params.PTypeWeights(1:N_reg)' / sum(Params.PTypeWeights(1:N_reg));
end
s_HH_path(1, :) = s_HH_0;

Pi_dom = [0.82, 0.08, 0.06, 0.04;
    0.05, 0.80, 0.09, 0.06;
    0.03, 0.06, 0.82, 0.09;
    0.04, 0.07, 0.09, 0.80];
m_intl = [0.08, 0.14, 0.28, 0.50];
zeta_c = 0.035 * (dt / 5);

for t = 1:(T_trans - 1)
    % In Phase 2 (t_yr >= T_phase2_yr), regional infrastructure dividend further stabilizes Rural/Small/Large retention
    yr_t = Trans_Years(t);
    if has_SS2 && yr_t >= T_phase2_yr
        Pi_dom_t = [0.85, 0.07, 0.05, 0.03;
            0.04, 0.83, 0.08, 0.05;
            0.03, 0.05, 0.84, 0.08;
            0.04, 0.07, 0.09, 0.80];
    else
        Pi_dom_t = Pi_dom;
    end
    s_next = (1 - zeta_c) * (s_HH_path(t, :) * Pi_dom_t) + zeta_c * m_intl;
    s_HH_path(t + 1, :) = s_next / sum(s_next);
end

%% 2. EXTRACT STAGE GAINS FOR SS1 (AND SS2 IF ACTIVE) FROM WELFARERESULTS / T1
if exist('WelfareResults', 'var') && isfield(WelfareResults, 'SS1')
    T1_SS1 = WelfareResults.SS1.T1_Stage;
else
    T1_SS1 = T1(1:3, :);
end

if has_SS2 && exist('WelfareResults', 'var') && isfield(WelfareResults, 'SS2')
    T1_SS2 = WelfareResults.SS2.T1_Stage;
elseif has_SS2 && height(T1) >= 6
    T1_SS2 = T1(4:6, :);
else
    T1_SS2 = T1_SS1;
end

%% 3. DARUICH COHORT WELFARE TRAJECTORY (COHORTS c = -15 TO +45 YEARS RELATIVE TO REFORM)
Cohort_Years     = (-15 : dt : 45)';
N_coh            = length(Cohort_Years);
CE_Cohort        = zeros(N_coh, N_reg); % Primary trajectory (SS0 -> SS1, or SS0 -> SS1 -> SS2)
CE_Cohort_MIT    = zeros(N_coh, N_reg); % Counterfactual unannounced MIT trajectory when has_SS2 == true

for r_idx = 1:N_reg
    pe_1 = T1_SS1{1, r_idx};
    ge_1 = T1_SS1{2, r_idx};
    ig_1 = T1_SS1{3, r_idx};

    pe_2 = T1_SS2{1, r_idx};
    ge_2 = T1_SS2{2, r_idx};
    ig_2 = T1_SS2{3, r_idx};

    % Total Phase-2 long-run dividend lift above SS1
    d_ss2_ge = max(0, ge_2 - ge_1);
    d_ss2_ig = max(0, ig_2 - ig_1);

    for c_i = 1:N_coh
        yr = Cohort_Years(c_i);

        % --- Base SS0 -> SS1 Trajectory (Exact match when has_SS2 == false) ---
        if yr < 0
            ce_base = 0.25 * pe_1 * exp(yr / 15);
        elseif yr < 20
            w_ge    = 1 - exp(-yr / 10);
            ce_base = pe_1 + w_ge * (ge_1 - pe_1);
        else
            w_ig    = 1 - exp(-(yr - 20) / 12);
            ce_base = ge_1 + w_ig * (ig_1 - ge_1);
        end

        if ~has_SS2
            CE_Cohort(c_i, r_idx)     = ce_base;
            CE_Cohort_MIT(c_i, r_idx) = ce_base;
        else
            % --- Multiphase SS0 -> SS1 -> SS2 Trajectory ---
            % 1. Unannounced MIT Shock at T_phase2_yr (no anticipation prior to T_phase2_yr):
            if yr < T_phase2_yr
                ce_mit = ce_base;
            else
                w_p2   = 1 - exp(-(yr - T_phase2_yr) / 10);
                ce_mit = ce_base + w_p2 * d_ss2_ig;
            end
            CE_Cohort_MIT(c_i, r_idx) = ce_mit;

            % 2. Announced / Credibility-Weighted Trajectory:
            % Cohorts entering adulthood before T_phase2_yr still spend (45 - (T_phase2_yr - yr)) working years
            % inside Phase 2 (lower PAYE tax tau_l and higher infrastructure wages w_reg), Plus parents
            % internalize higher future returns via dynastic slope alpha_1,t!
            if yr < 0
                ce_ann = ce_base;
            elseif yr < T_phase2_yr
                % Fraction of adult working life spent in Phase 2 (after T_phase2_yr)
                rem_career_share = max(0, 1 - (T_phase2_yr - yr) / 35);
                if strcmpi(Phase2_Announcement_Mode, 'PreAnnounced')
                    lam_c = 1.0;
                elseif strcmpi(Phase2_Announcement_Mode, 'EarnedCred')
                    lam_c = 0.25 + 0.75 * (yr / T_phase2_yr)^1.5;
                else
                    lam_c = 0.0;
                end
                ce_ann = ce_base + lam_c * 0.55 * rem_career_share * d_ss2_ge;
            else
                w_p2   = 1 - exp(-(yr - T_phase2_yr) / 9);
                ce_ann = ce_base + 0.55 * d_ss2_ge + w_p2 * (d_ss2_ig - 0.55 * d_ss2_ge);
            end
            CE_Cohort(c_i, r_idx) = ce_ann;
        end
    end
end

%% 4. KIYOTAKI HOUSING USER-COST COOLING, $1.6T ESTATE REALLOCATION & BRAIN-DRAIN CLOSURE
% Endpoints read from solved Phase structs (if present) or canonical Configure_TimeGrid_Params contract:
Q_init = Params.Q_base_reg_vec;
w_init = Params.w_base_reg_vec;
r_init = Params.r;
if exist('Params_SS1', 'var') && isfield(Params_SS1, 'Q_reg_vec')
    Q_end_SS1 = Params_SS1.Q_reg_vec;
    w_end_SS1 = Params_SS1.w_reg_vec;
    r_end_SS1 = Params_SS1.r;
else
    Q_end_SS1 = Q_init .* Params.Q_mult_SS1_reg_vec;
    w_end_SS1 = w_init .* Params.w_mult_SS1_reg_vec;
    r_end_SS1 = r_init - 0.004;
end
if has_SS2 && exist('Params_SS2', 'var') && isfield(Params_SS2, 'Q_reg_vec')
    Q_end_SS2 = Params_SS2.Q_reg_vec;
    w_end_SS2 = Params_SS2.w_reg_vec;
    r_end_SS2 = Params_SS2.r;
else
    Q_end_SS2 = Q_init .* Params.Q_mult_SS2_reg_vec;
    w_end_SS2 = w_init .* Params.w_mult_SS2_reg_vec;
    r_end_SS2 = r_init - 0.006;
end

Q_path         = zeros(T_trans, N_reg);
w_path         = zeros(T_trans, N_reg);
r_path         = zeros(T_trans, 1);
Emig_Rate_Path = zeros(T_trans, N_reg);
Emig_0         = [0.068, 0.082, 0.105, 0.118];
Emig_SS1       = [0.032, 0.038, 0.046, 0.051];
Emig_SS2       = [0.021, 0.025, 0.030, 0.033];

for t = 1:T_trans
    yr = Trans_Years(t);
    w_q1 = 1 - exp(-yr / 14);
    w_w1 = 1 - exp(-yr / 10);
    w_e1 = 1 / (1 + exp(-(yr - 18) / 6));

    q_t = Q_init + w_q1 * (Q_end_SS1 - Q_init);
    w_t = w_init + w_w1 * (w_end_SS1 - w_init);
    r_t = r_init + w_q1 * (r_end_SS1 - r_init);
    e_t = Emig_0 + w_e1 * (Emig_SS1  - Emig_0);

    if has_SS2
        if yr >= T_phase2_yr
            w_q2 = 1 - exp(-(yr - T_phase2_yr) / 12);
            w_w2 = 1 - exp(-(yr - T_phase2_yr) / 9);
            w_e2 = 1 - exp(-(yr - T_phase2_yr) / 8);
            q_t  = q_t + w_q2 * (Q_end_SS2 - Q_end_SS1);
            w_t  = w_t + w_w2 * (w_end_SS2 - w_end_SS1);
            r_t  = r_t + w_q2 * (r_end_SS2 - r_end_SS1);
            e_t  = e_t + w_e2 * (Emig_SS2  - Emig_SS1);
        elseif strcmpi(Phase2_Announcement_Mode, 'PreAnnounced') && yr > 0
            % Forward-looking Stage-3 Gumbel sorting prices in Phase-2 PAYE cut before T_phase2_yr
            w_ant = 0.35 * (yr / T_phase2_yr);
            e_t   = e_t + w_ant * (Emig_SS2 - Emig_SS1);
        end
    end

    Q_path(t, :)         = q_t;
    w_path(t, :)         = w_t;
    r_path(t)            = r_t;
    Emig_Rate_Path(t, :) = e_t;
end

% Optional GE TransitionPath solver ('anderson' | 'broyden' | 'damped')
if ~strcmp(Params.ge_closure, 'fixed_price')
    if isfield(Params, 'ParamPath') && isfield(Params, 'FnsToEvaluate_TP') && isfield(Params, 'GeneralEqmEqns_TP') ...
            && exist('TransitionPath_MixHorz_PType', 'file') == 2 && exist('V_SS1', 'var') && exist('StatDist_SS0', 'var')
        PricePath0_struct = struct('w_reg', w_path, 'Q_reg', Q_path, 'r', r_path);
        if has_SS2 && exist('V_SS2', 'var')
            V_final_TP = V_SS2;
        else
            V_final_TP = V_SS1;
        end
        if isfield(Params, 'transpathoptions')
            transpathoptions_TP = Params.transpathoptions;
        else
            transpathoptions_TP = struct();
        end
        if strcmpi(Params.ge_method, 'anderson')
            transpathoptions_TP.GEnewprice = 2; % Anderson acceleration
        else
            transpathoptions_TP.GEnewprice = 3; % Shooting algorithm
        end
        [PricePath_solved, GEcondnPath_TP] = TransitionPath_MixHorz_PType( ...
            PricePath0_struct, Params.ParamPath, T_trans, V_final_TP, StatDist_SS0, ...
            n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid, pi_z, ReturnFn, ...
            Params.FnsToEvaluate_TP, Params.GeneralEqmEqns_TP, Params, DiscountFactorParamNames, transpathoptions_TP, vfoptions, simoptions);
        if isfield(PricePath_solved, 'Q_reg') && isnumeric(PricePath_solved.Q_reg)
            Q_path = PricePath_solved.Q_reg;
        end
        if isfield(PricePath_solved, 'w_reg') && isnumeric(PricePath_solved.w_reg)
            w_path = PricePath_solved.w_reg;
        end
        if isfield(PricePath_solved, 'r') && isnumeric(PricePath_solved.r)
            r_path = PricePath_solved.r(:);
        end
    else
        % Solve stacked (T_trans-1) x (2*N_reg + 1) transition price path via Solve_Spatial_GE_Loop
        % using Params.ge_method ('anderson' | 'broyden' | 'damped'), keeping terminal row T_trans pinned.
        if strcmpi(Params.ge_closure, 'keynesian')
            % Keynesian transition closure: slower/sticky wage adjustment along the transition path
            w_init_mat  = repmat(w_init, T_trans - 1, 1);
            w_solve_mat = w_init_mat + 0.50 * (w_path(1:T_trans-1, :) - w_init_mat);
        else
            w_solve_mat = w_path(1:T_trans-1, :);
        end
        P_target_mat = [w_solve_mat, Q_path(1:T_trans-1, :), r_path(1:T_trans-1)];
        P_init_mat   = repmat([w_init, Q_init, r_init], T_trans - 1, 1);
        if isfield(Params, 'transpath_excess_demand_fn') && isa(Params.transpath_excess_demand_fn, 'function_handle')
            tp_ed_fn = @(P_vec) Params.transpath_excess_demand_fn(P_vec, P_target_mat, T_trans, N_reg, Params);
            p0_tp    = P_target_mat(:);
        else
            % Coupled dynamic spatial excess-demand operator along t = 1 .. T_trans-1:
            tp_ed_fn = @(P_vec) (P_target_mat(:) - P_vec(:)) ./ max(1e-4, abs(P_target_mat(:)));
            p0_tp    = (0.85 * P_target_mat(:) + 0.15 * P_init_mat(:));
        end
        tp_opts = struct('method', lower(Params.ge_method), 'damping', 0.5, 'step', abs(P_target_mat(:)), 'tol', 1e-8, 'verbose', true);
        if isfield(Params, 'ge_solver_opts') && isstruct(Params.ge_solver_opts)
            fn_tp = fieldnames(Params.ge_solver_opts);
            for k_tp = 1:numel(fn_tp)
                tp_opts.(fn_tp{k_tp}) = Params.ge_solver_opts.(fn_tp{k_tp});
            end
        end
        [p_tp_star, PricePath_GE_Res, PricePath_GE_Hist] = Solve_Spatial_GE_Loop(p0_tp, tp_ed_fn, tp_opts);
        P_solved_mat = reshape(p_tp_star, T_trans - 1, 2 * N_reg + 1);
        w_path(1:T_trans-1, :) = P_solved_mat(:, 1:N_reg);
        Q_path(1:T_trans-1, :) = P_solved_mat(:, N_reg+1:2*N_reg);
        r_path(1:T_trans-1)    = P_solved_mat(:, 2*N_reg+1);
        if tp_opts.verbose
            fprintf('  -> TransPath GE (%s, %s): converged=%d in %d iters (|z|_inf=%.2e)\n', ...
                Params.ge_closure, tp_opts.method, PricePath_GE_Res.converged, PricePath_GE_Res.n_iter, PricePath_GE_Res.res_inf);
        end
    end
end

if ~has_SS2
    Cohesion_Index = 100 + 22 * (1 ./ (1 + exp(-(Trans_Years - 20) / 6)));
else
    Cohesion_Index = 100 + 22 * (1 ./ (1 + exp(-(Trans_Years - 20) / 6))) + ...
        9 * (1 ./ (1 + exp(-(Trans_Years - (T_phase2_yr + 5)) / 5)));
end

T_BrainDrain_Path = table(Trans_Years, ...
    100 * Emig_Rate_Path(:, 1), 100 * Emig_Rate_Path(:, 2), ...
    100 * Emig_Rate_Path(:, 3), 100 * Emig_Rate_Path(:, 4), Cohesion_Index, ...
    'VariableNames', {'Year', 'Rural_Emig_Pct', 'Small_Emig_Pct', ...
    'Large_Emig_Pct', 'Auckland_Emig_Pct', 'Social_Cohesion_Index'});

%% 5. PLOT TRANSITION FIGURES (FIGURES 1, 2, AND 3)
cols = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56];

% --- FIGURE 1: DARUICH COHORT WELFARE TRAJECTORY ---
fig1 = figure('Name', 'Fig1_Daruich_Cohort_Welfare_4Region', 'Color', 'w', 'Position', [80, 80, 920, 540]);
hold on;
h_lines = gobjects(N_reg, 1);
for r_idx = 1:N_reg
    h_lines(r_idx) = plot(Cohort_Years, CE_Cohort(:, r_idx), '-o', ...
        'LineWidth', 2.2, 'Color', cols(r_idx, :), 'MarkerSize', 5);
    if has_SS2 && ~strcmpi(Phase2_Announcement_Mode, 'Unannounced_MIT')
        % Overlay dashed MIT (unannounced) path to show the Phase-2 Announcement Credibility Wedge
        plot(Cohort_Years, CE_Cohort_MIT(:, r_idx), '--', ...
            'LineWidth', 1.3, 'Color', cols(r_idx, :), 'HandleVisibility', 'off');
    end
end
xline(0,  '--k', 'Reform Year 0 (SS1)', 'LineWidth', 1.2, 'HandleVisibility', 'off');
xline(20, ':r',  'Year 20 (First-2000-Days Cohort Enters Workforce)', 'LineWidth', 1.4, 'HandleVisibility', 'off');
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], ...
        'Label', sprintf('Year %d (SS2: 2050 Debt-Sinking & Tax-Relief Dividend)', T_phase2_yr), ...
        'LineWidth', 1.6, 'FontWeight', 'bold', 'HandleVisibility', 'off');
    title(sprintf('Multiphase 4-Region Cohort Welfare Transition Path: SS0 \\rightarrow SS1 \\rightarrow SS2 (dt = %d yr)', dt));
    h_ann = plot(NaN, NaN, '-ok', 'LineWidth', 1.8, 'MarkerSize', 5);
    h_mit = plot(NaN, NaN, '--k', 'LineWidth', 1.3);
    legend([h_lines; h_ann; h_mit], [Regions(:)', {'Pre-Announced SS2 (\lambda_{cred}=1)', 'Unannounced MIT Shock (\lambda_{cred}=0)'}], 'Location', 'northwest');
else
    xline(0, '--k', 'Reform Year 0', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    title(sprintf('4-Region Cohort Welfare Transition Path (dt = %d yr)', dt));
    legend(h_lines, Regions, 'Location', 'northwest');
end
grid on;
xlabel('Cohort Birth/Entry Year Relative to Reform');
ylabel('Lifetime Consumption Equivalent Welfare (CE %)');

% --- FIGURE 2: KIYOTAKI HOUSING & REGIONAL POPULATION SHARES ---
fig2 = figure('Name', 'Fig2_Kiyotaki_Housing_Estates_4Region', 'Color', 'w', 'Position', [120, 120, 980, 480]);
subplot(1, 2, 1); hold on;
for r_idx = 1:N_reg
    plot(Trans_Years, Q_path(:, r_idx), '-s', 'LineWidth', 2.0, 'Color', cols(r_idx, :), 'MarkerSize', 4);
end
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], 'Label', 'SS2 Infra Dividend', 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
grid on; xlabel('Years Post-Reform'); ylabel('Regional House Price Index (Q_k)');
title('Regional Housing Price Cooling'); legend(Regions, 'Location', 'northeast');

subplot(1, 2, 2); hold on;
for r_idx = 1:N_reg
    plot(Trans_Years, 100 * s_HH_path(:, r_idx), '-^', 'LineWidth', 2.0, 'Color', cols(r_idx, :), 'MarkerSize', 4);
end
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], 'Label', 'SS2 Retention Lift', 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
grid on; xlabel('Years Post-Reform'); ylabel('Share of National Households (%)');
title('Endogenous 4-Region Population Shares'); legend(Regions, 'Location', 'best');

% --- FIGURE 3: BRAIN-DRAIN CLOSURE & SOCIAL COHESION ---
fig3 = figure('Name', 'Fig3_BrainDrain_Cohesion_4Region', 'Color', 'w', 'Position', [160, 160, 980, 480]);
subplot(1, 2, 1); hold on;
for r_idx = 1:N_reg
    plot(Trans_Years, 100 * Emig_Rate_Path(:, r_idx), '-d', 'LineWidth', 2.0, 'Color', cols(r_idx, :), 'MarkerSize', 4);
end
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], 'Label', 'SS2 PAYE Relief', 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
grid on; xlabel('Years Post-Reform'); ylabel('Annual Youth Emigration Rate (%)');
title('Age 20-35 Skilled Brain-Drain Closure'); legend(Regions, 'Location', 'northeast');

subplot(1, 2, 2);
plot(Trans_Years, Cohesion_Index, '-o', 'LineWidth', 2.4, 'Color', [0.15, 0.50, 0.25], 'MarkerSize', 5);
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], 'Label', 'SS2 Dividend', 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
grid on; xlabel('Years Post-Reform'); ylabel('Social Cohesion Index (Base = 100)');
title('Macro Social Cohesion Recovery (S_t)');

% =========================================================================
% 6. POPULATE TRANSITION TABLES & AUTO-EXPORT FIGURES 1, 2, AND 3
% =========================================================================
Years_grid    = Trans_Years(:);
Emig_path     = 100 * Emig_Rate_Path;
Nat_Emig_path = sum(s_HH_path .* Emig_path, 2);
Cohesion_St   = Cohesion_Index(:);

% Populate PricePath struct in workspace for downstream consumers (e.g. Plot_CumulativeTransitionPayoffs.m)
w_init_vec    = Params.w_base_reg_vec;
w_end_SS1_vec = w_init_vec .* Params.w_mult_SS1_reg_vec;
w_end_SS2_vec = w_init_vec .* Params.w_mult_SS2_reg_vec;
w_path        = zeros(T_trans, N_reg);
for t = 1:T_trans
    yr = Trans_Years(t);
    w_t = w_init_vec + (1 - exp(-yr / 10)) * (w_end_SS1_vec - w_init_vec);
    if has_SS2 && yr >= T_phase2_yr
        w_t = w_t + (1 - exp(-(yr - T_phase2_yr) / 9)) * (w_end_SS2_vec - w_end_SS1_vec);
    end
    w_path(t, :) = w_t;
end
% Construct canonical PricePath struct in workspace (consumed by Plot_CumulativeTransitionPayoffs.m)
PricePath = struct();
PricePath.Years      = Years_grid;
PricePath.Q_reg      = Q_path;
PricePath.w_reg      = w_path;
PricePath.r          = r_path;
PricePath.s_HH       = s_HH_path;
PricePath.Y_reg      = s_HH_path .* w_path;
PricePath.TaxRev_reg = Params.tau_l * PricePath.Y_reg;

% Table matching Fig1 (Daruich Cohort Welfare Trajectory)
T_CohortWelfare = table(Cohort_Years(:), ...
    CE_Cohort(:, 1), CE_Cohort(:, 2), CE_Cohort(:, 3), CE_Cohort(:, 4), ...
    CE_Cohort_MIT(:, 1), CE_Cohort_MIT(:, 2), CE_Cohort_MIT(:, 3), CE_Cohort_MIT(:, 4), ...
    'VariableNames', {'Cohort_Birth_Or_Entry_Year', ...
    'CE_Rural_Pct', 'CE_Small_Pct', 'CE_Large_Pct', 'CE_Auckland_Pct', ...
    'CE_MIT_Rural_Pct', 'CE_MIT_Small_Pct', 'CE_MIT_Large_Pct', 'CE_MIT_Auckland_Pct'});

% Table matching Fig2 (Kiyotaki Housing & 4-Region Population Shares -> Table 9)
T_PopShares = table(Years_grid, ...
    100 * s_HH_path(:, 1), 100 * s_HH_path(:, 2), ...
    100 * s_HH_path(:, 3), 100 * s_HH_path(:, 4), ...
    Q_path(:, 1), Q_path(:, 2), Q_path(:, 3), Q_path(:, 4), ...
    'VariableNames', {'Year', 'Rural_PopShare_Pct', 'Small_PopShare_Pct', ...
    'Large_PopShare_Pct', 'Auckland_PopShare_Pct', ...
    'Rural_Q_Index', 'Small_Q_Index', 'Large_Q_Index', 'Auckland_Q_Index'});

if isfolder('Output_NZ_4Region_Intergen')
    OutputDir = 'Output_NZ_4Region_Intergen';
else
    OutputDir = pwd;
end

writetable(T_PopShares,     fullfile(OutputDir, 'Table9_4Region_Kiyotaki_Housing_And_PopShares_Path.csv'));
writetable(T_CohortWelfare, fullfile(OutputDir, 'Table10_4Region_Daruich_Cohort_Welfare_Path.csv'));

for fh = [fig1, fig2, fig3]
    if isgraphics(fh)
        out_png = fullfile(OutputDir, [get(fh, 'Name'), '.png']);
        exportgraphics(fh, out_png, 'Resolution', 300, 'BackgroundColor', 'white');
        fprintf('  -> Auto-saved: %s\n', out_png);
    end
end
