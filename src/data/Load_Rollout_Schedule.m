function RolloutSpec = Load_Rollout_Schedule(DataSpec, Rollout_Mode)
%% LAYER 2 CONTRACT: KINEMATIC POLICY ROLLOUT & IMPLEMENTATION FRICTION SCHEDULE
% File: src/data/Load_Rollout_Schedule.m
% Usage:
%   RolloutSpec = Load_Rollout_Schedule(DataSpec, 'TeKahuiWaka');
%   RolloutSpec = Load_Rollout_Schedule(DataSpec, 'SingleShot');
%   RolloutSpec = Load_Rollout_Schedule(DataSpec, 'Frictionless_Textbook');
%
% Separates "how a policy track unfolds in relative years tau = 1..T once launched"
% from Layer 1 baseline empirical data (DataSpec) and Layer 3 state-contingent triggers.
% Vectorizes the echelon-to-region and national population-weighted wave matrices.

if nargin < 1 || isempty(DataSpec)
    DataSpec = Load_Empirical_Profile('NZ_Dunedin1972');
elseif ischar(DataSpec) || isstring(DataSpec)
    DataSpec = Load_Empirical_Profile(DataSpec);
end

if nargin < 2 || isempty(Rollout_Mode)
    Rollout_Mode = 'TeKahuiWaka';
end
if isstring(Rollout_Mode)
    Rollout_Mode = char(Rollout_Mode);
end

% Normalize legacy 'Armada' alias -> 'TeKahuiWaka'
mode_clean = strtrim(Rollout_Mode);
if any(strcmpi(mode_clean, {'TeKahuiWaka', 'Armada', 'Staged'}))
    mode_key = 'TeKahuiWaka';
elseif any(strcmpi(mode_clean, {'SingleShot', 'Day1', 'Single_Shot'}))
    mode_key = 'SingleShot';
elseif any(strcmpi(mode_clean, {'Frictionless_Textbook', 'Frictionless', 'Textbook'}))
    mode_key = 'Frictionless_Textbook';
else
    mode_key = mode_clean;
end

fric_path = resolve_sched_file('rollout_frictions.yaml', DataSpec);
Fric_YAML = Read_IGW_YAML(fric_path);

if ~isfield(Fric_YAML, mode_key)
    error('IGWelfare:UnknownRolloutMode', ...
        'Rollout_Mode "%s" (key "%s") not defined in %s.', Rollout_Mode, mode_key, fric_path);
end
mode_cfg = Fric_YAML.(mode_key);

sched_csv_path = resolve_sched_file(mode_cfg.Schedule_CSV, DataSpec);
S_CSV          = Read_IGW_CSV(sched_csv_path);

ss2_csv_path   = resolve_sched_file('ss2_dividend_harvest.csv', DataSpec);
SS2_CSV        = Read_IGW_CSV(ss2_csv_path);

N_waves    = S_CSV.N_Rows;
N_echelons = DataSpec.N_Echelons;
ech_map    = DataSpec.Echelon_Idx(:)';          % [1 x N_reg] e.g. [1, 1, 2, 3]
w_pop_col  = DataSpec.Pop_Shares(:);            % [N_reg x 1] column vector
b_ygr_row  = DataSpec.Reg_Table.sh_ygr_base0(:)'; % [1 x N_reg] baseline Gate-3 mentoring coverage

% Assemble [N_waves x N_echelons] matrices
ECE_Ech     = zeros(N_waves, N_echelons);
Mnt_Ech     = zeros(N_waves, N_echelons);
YGr_New_Ech = zeros(N_waves, N_echelons);
Elc_Ech     = zeros(N_waves, N_echelons);

for e = 1:N_echelons
    ECE_Ech(:, e)     = S_CSV.(sprintf('ECE_Ech%d',     e))(:);
    Mnt_Ech(:, e)     = S_CSV.(sprintf('Mnt_Ech%d',     e))(:);
    YGr_New_Ech(:, e) = S_CSV.(sprintf('YGr_New_Ech%d', e))(:);
    Elc_Ech(:, e)     = S_CSV.(sprintf('Elc_Ech%d',     e))(:);
end

% Compute Echelon-level baseline Gate-3 mentoring share via vectorized accumarray
ech_pop_w   = accumarray(ech_map(:), w_pop_col, [N_echelons, 1]);
ech_ygr_num = accumarray(ech_map(:), w_pop_col .* b_ygr_row(:), [N_echelons, 1]);
b_ech_row   = (ech_ygr_num ./ max(1e-12, ech_pop_w))'; % [1 x N_echelons]
YGr_Tot_Ech = b_ech_row + (1.0 - b_ech_row) .* YGr_New_Ech;

% Vectorized projection from Echelons [N_waves x N_echelons] -> Regions [N_waves x N_reg] & National [N_waves x (N_reg+1)]
ECE_Reg     = ECE_Ech(:, ech_map);
Mnt_Reg     = Mnt_Ech(:, ech_map);
YGr_New_Reg = YGr_New_Ech(:, ech_map);
YGr_Tot_Reg = b_ygr_row + (1.0 - b_ygr_row) .* YGr_New_Reg;
Elc_Reg     = Elc_Ech(:, ech_map);

RolloutSpec                    = struct();
RolloutSpec.Profile_ID         = DataSpec.Profile_ID;
RolloutSpec.Rollout_Mode       = mode_key;
RolloutSpec.N_Waves            = N_waves;
RolloutSpec.Rel_Years          = S_CSV.Rel_Year(:);

% Friction & tax-ramp scalars (PR #18)
RolloutSpec.tau_friction_0     = Fric_YAML.tau_friction_0;
RolloutSpec.tau_friction_floor = Fric_YAML.tau_friction_floor;
RolloutSpec.gamma_learning     = Fric_YAML.gamma_learning;
RolloutSpec.phi_adj_bottleneck = Fric_YAML.phi_adj_bottleneck;
RolloutSpec.delta_adopt_ece    = Fric_YAML.delta_adopt_ece;
RolloutSpec.lambda_adopt_ece   = Fric_YAML.lambda_adopt_ece;
RolloutSpec.T_ramp_LVT_yrs     = Fric_YAML.T_ramp_LVT_yrs;
RolloutSpec.T_ramp_CGT_Est_yrs = Fric_YAML.T_ramp_CGT_Est_yrs;
RolloutSpec.T_ramp_CorpCut_yrs = Fric_YAML.T_ramp_CorpCut_yrs;

RolloutSpec.eta_delivery_SS1   = mode_cfg.eta_delivery_SS1(:)';
RolloutSpec.eta_delivery_SS2   = mode_cfg.eta_delivery_SS2(:)';

% Echelon-level [N_waves x N_echelons] matrices
RolloutSpec.sh_ygr_base0_echelon = b_ech_row;
RolloutSpec.ECE_Echelon          = ECE_Ech;
RolloutSpec.Mnt_Echelon          = Mnt_Ech;
RolloutSpec.YGr_New_Echelon      = YGr_New_Ech;
RolloutSpec.YGr_Tot_Echelon      = YGr_Tot_Ech;
RolloutSpec.Elc_Echelon          = Elc_Ech;

% Region + National [N_waves x (N_reg + 1)] matrices
RolloutSpec.ECE_RegNat     = [ECE_Reg,     ECE_Reg     * w_pop_col];
RolloutSpec.Mnt_RegNat     = [Mnt_Reg,     Mnt_Reg     * w_pop_col];
RolloutSpec.YGr_New_RegNat = [YGr_New_Reg, YGr_New_Reg * w_pop_col];
RolloutSpec.YGr_Tot_RegNat = [YGr_Tot_Reg, YGr_Tot_Reg * w_pop_col];
RolloutSpec.Elc_RegNat     = [Elc_Reg,     Elc_Reg     * w_pop_col];

% Tax-ramp relative schedules [N_waves x 1]
RolloutSpec.LVT_Ramp       = S_CSV.LVT_Ramp(:);
RolloutSpec.CGT_Est_Ramp   = S_CSV.CGT_Est_Ramp(:);
RolloutSpec.CorpCut_Ramp   = S_CSV.CorpCut_Ramp(:);

% SS2 post-unlock relative kinematic ramp
RolloutSpec.SS2_Track = struct( ...
    'Rel_Year_Post_Unlock', SS2_CSV.Rel_Year_Post_Unlock(:), ...
    'TaxRelief_Share',      SS2_CSV.TaxRelief_Share(:), ...
    'SuperAge_Share',       SS2_CSV.SuperAge_Share(:), ...
    'ECE_SS2_TopUp_Share',  SS2_CSV.ECE_SS2_TopUp_Share(:), ...
    'Infra_Dividend_Share', SS2_CSV.Infra_Dividend_Share(:));

RolloutSpec.Digest = compute_md5_local(RolloutSpec);

end

%% --- LOCAL HELPERS ---
function fpath = resolve_sched_file(fname, DataSpec)
p1 = fullfile(DataSpec.Profile_Dir, 'schedules', fname);
if exist(p1, 'file') == 2
    fpath = p1;
    return;
end
if ~isempty(DataSpec.Parent_Profile_Dir)
    p2 = fullfile(DataSpec.Parent_Profile_Dir, 'schedules', fname);
    if exist(p2, 'file') == 2
        fpath = p2;
        return;
    end
end
error('IGWelfare:MissingScheduleFile', 'Schedule file "%s" not found for profile %s.', fname, DataSpec.Profile_ID);
end

function digest = compute_md5_local(S)
digest = IGW_MD5_Hex(S);
end

