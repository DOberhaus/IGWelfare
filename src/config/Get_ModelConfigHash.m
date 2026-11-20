function [cache_filepath, is_cached] = Get_ModelConfigHash(tag_str, Params, n_d, n_a, n_z, N_j, ForceRecompute)
%% AUTOMATIC CONTENT-HASHED .MAT CACHE MANAGER
% File: Get_ModelConfigHash.m
% Returns the path to a cached .mat file in ./Cache_NZ_Intergen/ whose filename
% embeds a 32-char lower-case hex MD5 of (Params, n_d, n_a, n_z, N_j). If ForceRecompute == true,
% is_cached is forced to false so the caller recomputes and overwrites the cache.
%
% Key: the WHOLE configuration is serialised with jsonencode (every element of every array, in field order) and
% hashed with MD5 -- java.security.MessageDigest in MATLAB, hash('md5', ...) in GNU Octave. (An earlier version hashed
% a sample of at most ~8-16k bytes of getByteStreamFromArray, which misses changes inside large arrays, reduced the
% digest to ~16 effective bits, and does not exist in Octave.)
%
% Caveats:
%   - Precision: jsonencode prints doubles to ~15 significant digits in MATLAB (Octave prints the shortest round-trip
%     string), so a relative change below ~1e-15 is not seen, and MATLAB and Octave hashes of the same Params differ.
%   - NaN, +Inf and -Inf all encode as null and are indistinguishable from each other.
%   - Function handles (anywhere in the inputs, including inside struct fields and cells) are skipped, not hashed.
%     Params as built by Configure_TimeGrid_Params holds only numeric arrays and structs. Other unsupported types
%     (objects) make jsonencode raise its own error.
%   - The key covers the inputs passed in, not the code of the model scripts.
%   - No MD5 available (MATLAB without the JVM, or the Octave hash() call fails): the run is NOT stopped. IGW_Log
%     records IGW:NoMD5 and the returned path is Cache_<tag>_nomd5_<timestamp>_<unique>.mat with is_cached = false,
%     a name that never matches an existing file, so the caller recomputes and (re)writes its checkpoint. The path
%     holds no 32-hex digest, so Run_All's extracted Cache_CfgHash is empty and Validate_CacheConfig rejects (and
%     logs) every checkpoint until MD5 is available again.

if nargin < 7 || isempty(ForceRecompute)
    ForceRecompute = false;
end

% Resolve profile-scoped cache directory when Profile_ID or Cache_Dir is present
igw_root = getappdata(0, 'IGW_ROOT_DIR');
if isempty(igw_root), igw_root = pwd; end
if isstruct(Params) && isfield(Params, 'Cache_Dir') && ~isempty(Params.Cache_Dir)
    CacheDir = Params.Cache_Dir;
elseif isstruct(Params) && isfield(Params, 'Profile_ID') && ~isempty(Params.Profile_ID)
    CacheDir = fullfile(igw_root, 'cache', Params.Profile_ID);
else
    CacheDir = fullfile(igw_root, 'Cache_NZ_Intergen');
end
if ~exist(CacheDir, 'dir')
    mkdir(CacheDir);
end

% Tiered cache-key stripping so downstream schedule/contingency edits never trigger false rebuilds:
%   - 'SS0_*'      (Steps 1-5 Baseline): strips Layer 2 Rollout, eta_delivery_*, & Layer 3 Contingency
%   - 'SSReform_*' (Step 6 SS1/SS2)    : keeps eta_delivery_SS1/SS2, strips wave matrices & Layer 3 Contingency
%   - 'Trans_*'    (Step 7+ Transition): hashes the full 3-layer stack
Params_for_hash = Params;
if isstruct(Params_for_hash) && (strncmpi(tag_str, 'SS0_', 4) || strncmpi(tag_str, 'SS_', 3) || strncmpi(tag_str, 'SSReform_', 9))
    trans_only_fields = { ...
        'RolloutSpec', 'ContingencySpec', 'Contingency_Policy', ...
        't_wave_yr', 'Waves_13', 'Kahui_ECE_13x3', 'Kahui_Mnt_13x3', ...
        'Kahui_YGr_New_13x3', 'Kahui_YGr_Tot_13x3', 'Kahui_Elc_13x3', ...
        'Kahui_ECE_13x5', 'Kahui_Mnt_13x5', 'Kahui_YGr_New_13x5', ...
        'Kahui_YGr_Tot_13x5', 'Kahui_Elc_13x5', 'T_trans_years', 'T_trans', ...
        'T_ramp_LVT_yrs', 'T_ramp_CGT_Est_yrs', 'T_ramp_CorpCut_yrs', ...
        's_active_ece_vec', 's_active_ygr_vec', 's_active_elec_vec', 's_active_ece', 'Cache_Dir'};
    if strncmpi(tag_str, 'SS0_', 4) || strncmpi(tag_str, 'SS_', 3)
        % Baseline SS0 (Steps 1-5) has zero reform increment (G_ece == g1_0), so delivery yields do not enter SS0
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

% Serialise the full contents of Params and the grid sizes (skipping function handles) and hash the text
state_struct        = struct();
state_struct.Params = skip_function_handles(Params_for_hash);
state_struct.n_d    = skip_function_handles(n_d);
state_struct.n_a    = skip_function_handles(n_a);
state_struct.n_z    = skip_function_handles(n_z);
state_struct.N_j    = skip_function_handles(N_j);
hash_hex = md5_hex(jsonencode(state_struct));

clean_tag = regexprep(tag_str, '[^a-zA-Z0-9_]', '_');
if isempty(hash_hex)
    % No MD5: a key that can never match an existing cache, so the caller rebuilds (see header)
    [~, uniq]      = fileparts(tempname);    % unique token without touching the global RNG stream
    cache_filepath = fullfile(CacheDir, sprintf('Cache_%s_nomd5_%s_%s.mat', clean_tag, datestr(now, 'yyyymmddTHHMMSS'), uniq));
    is_cached      = false;
    return
end
cache_filepath = fullfile(CacheDir, sprintf('Cache_%s_%s.mat', clean_tag, hash_hex));
is_cached      = (~ForceRecompute) && (exist(cache_filepath, 'file') == 2);

end

%% ========================================================================
%  LOCAL HELPERS
%% ========================================================================
function hash_hex = md5_hex(str)
% 32-char lower-case hex MD5 of the UTF-8 bytes of str; '' (after logging IGW:NoMD5) when no MD5 is available.
hash_hex = '';
try
    if exist('OCTAVE_VERSION', 'builtin') ~= 0
        hash_hex = lower(hash('md5', str));
    elseif usejava('jvm')
        md = java.security.MessageDigest.getInstance('MD5');
        md.update(typecast(uint8(unicode2native(str, 'UTF-8')), 'int8'));
        hash_hex = lower(reshape(dec2hex(typecast(md.digest(), 'uint8'), 2)', 1, []));
    else
        % Use MATLAB add-on from Steven Huang (2026). MD5 in MATLAB (https://www.mathworks.com/matlabcentral/fileexchange/7919-md5-in-matlab), MATLAB Central File Exchange. Retrieved November 11, 2026.
        % Compile mMD5 using mex compiler, ensure result is on your path, and you are good to go.
        md5_fun = @() mMD5(str);
        [~, hash_hex] = evalc('md5_fun()');
    end
catch err
    hash_hex = '';
    IGW_Log('IGW:NoMD5', 'Get_ModelConfigHash: MD5 failed (%s); cache key forces a rebuild.', err.message);
    return
end
if isempty(hash_hex)
    IGW_Log('IGW:NoMD5', 'Get_ModelConfigHash: no MD5 available (needs Octave hash() or the MATLAB JVM); cache key forces a rebuild.');
end
end

function x = skip_function_handles(x)
% Remove struct fields that hold function handles (in any element of a struct array) and blank cell entries that are
% function handles; recurse into the remaining structs and cells.
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
