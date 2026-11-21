function ContingencySpec = Load_Contingency_Policy(DataSpec, Policy_Name)
%% LAYER 3 CONTRACT: STATE-CONTINGENT POLICY GOVERNANCE & GATE LOADER
% File: src/data/Load_Contingency_Policy.m
% Usage:
%   ContingencySpec = Load_Contingency_Policy(DataSpec, 'contingent_armada');
%   ContingencySpec = Load_Contingency_Policy(DataSpec, 'fixed_calendar_2050');
%
% Defines declarative governance rules determining WHEN (and WHETHER) downstream
% rollout tracks (e.g., Gate-3 YouthGrant Echelons or SS2 Dividend Harvest) unlock
% based on realized economic/fiscal metrics rather than blind calendar dates.

if nargin < 1 || isempty(DataSpec)
    DataSpec = Load_Empirical_Profile('NZ_Dunedin1972');
elseif ischar(DataSpec) || isstring(DataSpec)
    DataSpec = Load_Empirical_Profile(DataSpec);
end

if nargin < 2 || isempty(Policy_Name)
    Policy_Name = 'fixed_calendar_2050';
end
if isstring(Policy_Name)
    Policy_Name = char(Policy_Name);
end

clean_name = strtrim(Policy_Name);
if isempty(regexp(clean_name, '\.ya?ml$', 'once'))
    fname = [clean_name, '.yaml'];
else
    fname = clean_name;
end

% Map friendly aliases
if any(strcmpi(clean_name, {'contingent', 'TeKahuiWaka_Contingent', 'contingent_armada'}))
    fname = 'contingent_armada.yaml';
elseif any(strcmpi(clean_name, {'fixed', 'calendar', 'Fixed_Calendar_2050', 'fixed_calendar_2050'}))
    fname = 'fixed_calendar_2050.yaml';
end

pol_path = resolve_policy_file(fname, DataSpec);
raw_pol  = Read_IGW_YAML(pol_path);

ContingencySpec                          = struct();
ContingencySpec.Profile_ID               = DataSpec.Profile_ID;
ContingencySpec.Policy_ID                = raw_pol.Policy_ID;
ContingencySpec.Default_Rollout_Mode     = get_f_def(raw_pol, 'Default_Rollout_Mode', 'TeKahuiWaka');
ContingencySpec.SS2_Track_CSV            = get_f_def(raw_pol, 'SS2_Track_CSV', 'ss2_dividend_harvest.csv');
ContingencySpec.Announcement_Mode        = get_f_def(raw_pol, 'Announcement_Mode', 'PreAnnounced');
ContingencySpec.Default_SS2_Fallback_Yr  = get_f_def(raw_pol, 'Default_SS2_Fallback_Year', 25);

if isfield(raw_pol, 'Gates') && iscell(raw_pol.Gates)
    ContingencySpec.Gates = raw_pol.Gates;
else
    ContingencySpec.Gates = {};
end

ContingencySpec.Digest = compute_md5_pol(ContingencySpec);

end

%% --- LOCAL HELPERS ---
function fpath = resolve_policy_file(fname, DataSpec)
p1 = fullfile(DataSpec.Profile_Dir, 'policies', fname);
if exist(p1, 'file') == 2
    fpath = p1;
    return;
end
if ~isempty(DataSpec.Parent_Profile_Dir)
    p2 = fullfile(DataSpec.Parent_Profile_Dir, 'policies', fname);
    if exist(p2, 'file') == 2
        fpath = p2;
        return;
    end
end
error('IGWelfare:MissingPolicyFile', 'Contingency policy "%s" not found for profile %s.', fname, DataSpec.Profile_ID);
end

function val = get_f_def(S, fname, def_val)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    val = S.(fname);
else
    val = def_val;
end
end

function digest = compute_md5_pol(S)
digest = IGW_MD5_Hex(S);
end

