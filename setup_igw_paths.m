function igw_root = setup_igw_paths(quiet, force_reinit)
%% AUTHORITATIVE PATH, TOOLKIT, BACKEND, & GRAPHICS BOOTSTRAP (MATLAB CUDA, MATLAB CPU, & GNU OCTAVE)
% File: setup_igw_paths.m
% Single source of truth invoked by .octaverc, startup.m, Ensure_Workbench_Initialized, and run_all_tests.
%
% Guarantees:
%   1. Adds all modular IGWelfare subdirectories (src/*, pipelines, plots) to path.
%   2. Selectively mounts sibling VFIToolkit-matlab folders (skipping .git/ and unused directories).
%   3. Registers all 5 canonical vectorized model kernels in VFIToolkit-octave:
%      - On GNU Octave: activates VFIToolkit_Octave_Setup (shims + ufhorz/uinfhorz + Qt/Arial hygiene).
%      - On MATLAB CPU-only (gpuDeviceCount == 0): activates enable_vfi_cpu_accel (ufhorz/uinfhorz only,
%        preserving native MATLAB builtins and HG2 graphics).

if nargin < 1 || isempty(quiet),        quiet        = false; end
if nargin < 2 || isempty(force_reinit), force_reinit = false; end

igw_root = fileparts(mfilename('fullpath'));
if isempty(igw_root), igw_root = pwd; end

is_oct = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
oct_precedence_ok = (~is_oct) || ~isempty(strfind(which('ValueFnIter_InfHorz'), 'VFIToolkit-octave'));
if ~force_reinit && oct_precedence_ok && isappdata(0, 'IGW_PATHS_READY') ...
        && isequal(getappdata(0, 'IGW_ROOT_DIR'), igw_root) ...
        && exist('Load_Empirical_Profile', 'file') == 2 ...
        && exist('Compute_Actuarial_Ledger', 'file') == 2 ...
        && exist('Compute_Helm_TrimTab_Ledger', 'file') == 2 ...
        && (exist('jequaloneDist_PType', 'file') == 2 || exist(fullfile(igw_root, '..', 'VFIToolkit-matlab'), 'dir') ~= 7)
    return;
end

% 1. Add root and modular IGWelfare subdirectories
rel_dirs = { ...
    '', ...
    fullfile('src', 'data'), ...
    fullfile('src', 'config'), ...
    fullfile('src', 'solvers'), ...
    fullfile('src', 'models'), ...
    fullfile('src', 'ledgers'), ...
    fullfile('src', 'calibration'), ...
    fullfile('src', 'utils'), ...
    'pipelines', ...
    'plots'};
for k = 1:numel(rel_dirs)
    d = fullfile(igw_root, rel_dirs{k});
    if exist(d, 'dir') ~= 0
        addpath(d);
    end
end
rehash;

% 2. Selectively mount sibling VFIToolkit-matlab (avoiding .git/ and unused folders)
vfi_mat_dir = fullfile(igw_root, '..', 'VFIToolkit-matlab');
if exist(vfi_mat_dir, 'dir') == 7
    if exist('ValueFnIter_Case1_FHorz', 'file') == 0 || exist('jequaloneDist_PType', 'file') == 0
        mount_vfitoolkit_matlab_selective(vfi_mat_dir);
    elseif exist('ValueFnIter_MixHorz_PType', 'file') == 0
        mix_dir = fullfile(vfi_mat_dir, 'ValueFnIter', 'MixHorz_PType');
        if exist(mix_dir, 'dir') == 7, addpath(mix_dir); end
    end
end

% 3. Canonical vectorized model kernels shared across Octave & MATLAB CPU-only backends
vec_kernels = { ...
    'ReturnFn_SpatialHH', ...
    'ReturnFn_SpatialHH_Compact4D', ...
    'ReturnFn_Firm', ...
    'HumanCapital_Lifecycle_aprimeFn'};

vfi_oct_dir = fullfile(igw_root, '..', 'VFIToolkit-octave');
if is_oct
    oct_pkgs = {'parallel', 'statistics', 'datatypes', 'tablicious', 'struct', 'io', 'optim'};
    for ip = 1:numel(oct_pkgs)
        try pkg('load', oct_pkgs{ip}); catch, end
    end
    if exist('VFIToolkit_Octave_Setup', 'file') == 0 && exist(vfi_oct_dir, 'dir') == 7
        addpath(vfi_oct_dir);
    end
    if exist('VFIToolkit_Octave_Setup', 'file') ~= 0
        VFIToolkit_Octave_Setup(vec_kernels, true);
    end
    % Keep IGWelfare/src/utils ahead of VFIToolkit-octave/shims/matlab so unified vfi_active_ax is used
    addpath(fullfile(igw_root, 'src', 'utils'), '-begin');

    if exist('graphics_toolkit', 'file') ~= 0
        try
            if strcmp(graphics_toolkit(), 'fltk') && any(strcmp(available_graphics_toolkits(), 'qt'))
                graphics_toolkit('qt');
            end
        catch
        end
    end

    try
        if ismac
            def_font = 'Hiragino Sans';
        elseif ispc
            def_font = 'Arial';
        else
            def_font = 'DejaVu Sans';
        end
        set(0, 'DefaultAxesFontName',   def_font);
        set(0, 'DefaultTextFontName',   def_font);
        set(0, 'DefaultLegendFontName', def_font);
    catch
    end
else
    % Native MATLAB: if no CUDA GPU is available (e.g., MATLAB Online), mount vectorized CPU solvers
    Backend = Resolve_Compute_Backend();
    if strcmp(Backend.Mode, 'matlab_cpu') && exist(vfi_oct_dir, 'dir') == 7
        enable_vfi_cpu_accel(vfi_oct_dir, vec_kernels);
    end
end

setappdata(0, 'IGW_ROOT_DIR',    igw_root);
setappdata(0, 'IGW_PATHS_READY', true);

if ~quiet
    fprintf('[IGWelfare] Environment initialized (%s)\n', igw_root);
end
end

function mount_vfitoolkit_matlab_selective(root)
gen_dirs = { ...
    fullfile(root, 'DiscretizationMethods', 'FTsubcodes'), ...
    fullfile(root, 'Other'), ...
    fullfile(root, 'SubCodes'), ...
    fullfile(root, 'EvaluateFnOnAgentDist')};
for i = 1:numel(gen_dirs)
    if exist(gen_dirs{i}, 'dir') == 7, addpath(genpath(gen_dirs{i})); end
end

flat_dirs = { ...
    fullfile(root, 'DiscretizationMethods'), ...
    fullfile(root, 'DiscretizationMethods', 'discretizeAR1_FarmerToda'), ...
    fullfile(root, 'DiscretizationMethods', 'discretizeAR1_Rouwenhorst'), ...
    fullfile(root, 'DiscretizationMethods', 'discretizeAR1_Tauchen'), ...
    fullfile(root, 'ValueFnIter'), ...
    fullfile(root, 'ValueFnIter', 'InfHorz'), ...
    fullfile(root, 'ValueFnIter', 'MixHorz_PType'), ...
    fullfile(root, 'ValueFnIter', 'FHorz'), ...
    fullfile(root, 'ValueFnIter', 'FHorz', 'ExperienceAsset'), ...
    fullfile(root, 'ValueFnIter', 'FHorz', 'ExperienceAssetz'), ...
    fullfile(root, 'ValueFnFromPolicy'), ...
    fullfile(root, 'PolicyInd2Val'), ...
    fullfile(root, 'aprimeFnMatrix'), ...
    fullfile(root, 'ReturnFnMatrix'), ...
    fullfile(root, 'ReturnFnMatrix', 'ExperienceAsset'), ...
    fullfile(root, 'StationaryDist'), ...
    fullfile(root, 'StationaryDist', 'InfHorz'), ...
    fullfile(root, 'StationaryDist', 'FHorz'), ...
    fullfile(root, 'StationaryDist', 'FHorz', 'ExpAsset'), ...
    fullfile(root, 'StationaryDist', 'FHorz', 'ExpAssetz'), ...
    fullfile(root, 'StationaryDist', 'FHorz', 'nProbs'), ...
    fullfile(root, 'StationaryDist', 'FHorzPType'), ...
    fullfile(root, 'StationaryDist', 'MixHorzPType')};
for i = 1:numel(flat_dirs)
    if exist(flat_dirs{i}, 'dir') == 7, addpath(flat_dirs{i}); end
end
end
