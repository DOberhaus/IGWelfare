function [cache_filepath, is_cached] = Get_ModelConfigHash(tag_str, Params, n_d, n_a, n_z, N_j, ForceRecompute)
%% AUTOMATIC CONTENT-HASHED .MAT CACHE MANAGER
% File: src/config/Get_ModelConfigHash.m
% Returns the path to a cached .mat file in ./Cache_NZ_Intergen/ (or Params.Cache_Dir
% when explicitly supplied) whose filename embeds a 32-char lower-case hex MD5 of
% (Params, n_d, n_a, n_z, N_j).

if nargin < 7 || isempty(ForceRecompute)
    ForceRecompute = false;
end

% Default to ./Cache_NZ_Intergen in pwd unless caller explicitly configured Params.Cache_Dir
if isstruct(Params) && isfield(Params, 'Cache_Dir') && ~isempty(Params.Cache_Dir)
    CacheDir = Params.Cache_Dir;
else
    CacheDir = fullfile(pwd, 'Cache_NZ_Intergen');
end
if ~exist(CacheDir, 'dir')
    mkdir(CacheDir);
end

% Tiered cache-key stripping so downstream schedule/contingency edits never trigger false rebuilds:
%   - 'SS0_*'      (Steps 1-5 Baseline): strips Layer 2 Rollout, eta_delivery_*, & Layer 3 Contingency
%   - 'SSReform_*' (Step 6 SS1/SS2)    : keeps eta_delivery_SS1/SS2, strips wave matrices & Layer 3 Contingency
%   - 'Trans_*'    (Step 7+ Transition): hashes the full 3-layer stack
Params_for_hash = Params;
if isstruct(Params_for_hash)
    runtime_only = {'Cache_Dir', 'n_workers', 'Profile_Name'};
    present_rt   = runtime_only(isfield(Params_for_hash, runtime_only));
    if ~isempty(present_rt)
        Params_for_hash = rmfield(Params_for_hash, present_rt);
    end
end

if isstruct(Params_for_hash) && (strncmpi(tag_str, 'SS0_', 4) || strncmpi(tag_str, 'SS_', 3) || strncmpi(tag_str, 'SSReform_', 9))
    trans_only_fields = { ...
        'RolloutSpec', 'ContingencySpec', 'Contingency_Policy', 'Contingency_Policy_ID', ...
        'Contingency_Announcement_Mode', 'Contingency_Digest', 'Rollout_Digest', ...
        't_wave_yr', 'Waves_13', 'Kahui_ECE_13x3', 'Kahui_Mnt_13x3', ...
        'Kahui_YGr_New_13x3', 'Kahui_YGr_Tot_13x3', 'Kahui_Elc_13x3', ...
        'Kahui_ECE_13x5', 'Kahui_Mnt_13x5', 'Kahui_YGr_New_13x5', ...
        'Kahui_YGr_Tot_13x5', 'Kahui_Elc_13x5', 'T_trans_years', 'T_trans', ...
        'T_ramp_LVT_yrs', 'T_ramp_CGT_Est_yrs', 'T_ramp_CorpCut_yrs', ...
        's_active_ece_vec', 's_active_ygr_vec', 's_active_elec_vec', 's_active_ece', ...
        'Trans_Pi_dom_SS1', 'Trans_Pi_dom_SS2', 'Trans_Intl_Inflow_Share', ...
        'Trans_Q_init', 'Trans_Emig_0', 'Trans_Emig_SS1', 'Trans_Emig_SS2', 'kahui_lag_yrs'};
    if strncmpi(tag_str, 'SS0_', 4) || strncmpi(tag_str, 'SS_', 3)
        trans_only_fields = [trans_only_fields, { ...
            'Rollout_Mode', 'eta_delivery_SS1', 'eta_delivery_SS2', 'eta_deliv_vec', ...
            'tau_friction_0', 'tau_friction_floor', 'gamma_learning', ...
            'phi_adj_bottleneck', 'delta_adopt_ece', 'lambda_adopt_ece'}];
    end
    present_tf = trans_only_fields(isfield(Params_for_hash, trans_only_fields));
    if ~isempty(present_tf)
        Params_for_hash = rmfield(Params_for_hash, present_tf);
    end
end

state_struct        = struct();
state_struct.Params = skip_function_handles(Params_for_hash);
state_struct.n_d    = skip_function_handles(n_d);
state_struct.n_a    = skip_function_handles(n_a);
state_struct.n_z    = skip_function_handles(n_z);
state_struct.N_j    = skip_function_handles(N_j);
hash_hex = md5_hex(jsonencode(state_struct));

clean_tag = regexprep(tag_str, '[^a-zA-Z0-9_]', '_');
if isempty(hash_hex)
    [~, uniq]      = fileparts(tempname);
    cache_filepath = fullfile(CacheDir, sprintf('Cache_%s_nomd5_%s_%s.mat', clean_tag, datestr(now, 'yyyymmddTHHMMSS'), uniq));
    is_cached      = false;
    return
end
cache_filepath = fullfile(CacheDir, sprintf('Cache_%s_%s.mat', clean_tag, hash_hex));
is_cached      = (~ForceRecompute) && (exist(cache_filepath, 'file') == 2);

end

function hash_hex = md5_hex(str)
hash_hex = IGW_MD5_Hex(str);
if isempty(hash_hex)
    IGW_Log('IGW:NoMD5', 'Get_ModelConfigHash: no MD5 available (needs Octave hash() or the MATLAB JVM); cache key forces a rebuild.');
end
end

function x = skip_function_handles(x)
if isa(x, 'function_handle')
    x = [];
elseif isstruct(x)
    fn = fieldnames(x);
    for k = 1:numel(fn)
        if any(arrayfun(@(e) isa(e.(fn{k}), 'function_handle'), x(:)))
            x = rmfield(x, fn{k});
        end
    end
    fn = fieldnames(x);
    for i = 1:numel(x)
        for k = 1:numel(fn)
            x(i).(fn{k}) = skip_function_handles(x(i).(fn{k}));
        end
    end
elseif iscell(x)
    for i = 1:numel(x)
        x{i} = skip_function_handles(x{i});
    end
end
end
