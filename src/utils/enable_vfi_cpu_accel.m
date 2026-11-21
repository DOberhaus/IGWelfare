function tf = enable_vfi_cpu_accel(vfiOctaveDir)
%ENABLE_VFI_CPU_ACCEL Mount VFIToolkit-octave vectorized CPU solvers in MATLAB No-GPU.
%   Leaves MATLAB native builtins and graphics untouched (never adds shims/matlab).
%   Safe no-op if a CUDA GPU is active or if running under GNU Octave (which uses
%   VFIToolkit_Octave_Setup instead).

isOctave = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
hasGpu   = (~isOctave && exist('gpuDeviceCount', 'file') ~= 0 && gpuDeviceCount > 0);

if isOctave || hasGpu
    tf = false;
    return;
end

if nargin < 1 || isempty(vfiOctaveDir)
    igwRoot = getappdata(0, 'IGW_ROOT_DIR');
    if isempty(igwRoot)
        igwRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    end
    vfiOctaveDir = fullfile(fileparts(igwRoot), 'VFIToolkit-octave');
end

if exist(vfiOctaveDir, 'dir') ~= 7
    tf = false;
    return;
end

addpath(fullfile(vfiOctaveDir, 'uinfhorz'),           '-begin');
addpath(fullfile(vfiOctaveDir, 'ufhorz', 'matrices'), '-begin');
addpath(fullfile(vfiOctaveDir, 'ufhorz', 'solvers'),  '-begin');
addpath(fullfile(vfiOctaveDir, 'ufhorz'),             '-begin');
addpath(fullfile(vfiOctaveDir, 'shims',  'pool'),     '-begin');
addpath(fullfile(vfiOctaveDir, 'shims',  'vfi'),      '-begin');

if exist('vfi_vectorized_registry', 'file') ~= 0
    vfi_vectorized_registry('add', { ...
        'ReturnFn_SpatialHH', ...
        'ReturnFn_SpatialHH_Compact4D', ...
        'ReturnFn_Firm', ...
        'HumanCapital_Lifecycle_aprimeFn', ...
        'BenPorath_aprimeFn'});
end

tf = true;


end
