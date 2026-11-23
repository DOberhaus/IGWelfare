function Backend = Resolve_Compute_Backend(Opts)
%% AUTHORITATIVE THREE-BACKEND HARDWARE & RUNTIME CONTRACT
% File: src/utils/Resolve_Compute_Backend.m
% Classifies and provisions the active execution environment once per session:
%   - 'matlab_cuda' : Native MATLAB + Parallel Computing Toolbox CUDA GPU (gpuDeviceCount > 0)
%   - 'matlab_cpu'  : Native MATLAB / MATLAB Online CPU-only (mounts VFIToolkit-octave vectorized CPU layer)
%   - 'octave_pool' : GNU Octave CPU + VFIToolkit-octave shims & optional RAMDisk persistent worker pool
%
% Exposes zero-branching primitives:
%   Backend.Mode         : 'matlab_cuda' | 'matlab_cpu' | 'octave_pool'
%   Backend.IsOctave     : logical scalar
%   Backend.UseGPU       : logical scalar
%   Backend.DeviceName   : human-readable device summary string
%   Backend.MemoryGB     : available device/host memory in GB (NaN if unreported)
%   Backend.ToDevice     : @(x) gpuArray(x) on CUDA, @(x) x on CPU/Octave
%   Backend.Zeros        : @(varargin) zeros(..., 'gpuArray') on CUDA, zeros(...) on CPU/Octave
%   Backend.Ones         : @(varargin) ones(..., 'gpuArray')  on CUDA, ones(...)  on CPU/Octave
%   Backend.FlushConsole : @() fflush(stdout) in Octave, no-op in MATLAB

if nargin < 1 || isempty(Opts)
    Opts = struct();
end

force_cpu = isfield(Opts, 'ForceCPU') && logical(Opts.ForceCPU);
is_oct    = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
has_cuda  = false;
dev_name  = 'Multi-Core CPU';
mem_gb    = NaN;

if ~is_oct && ~force_cpu && exist('gpuDeviceCount', 'file') ~= 0
    try
        if gpuDeviceCount > 0
            has_cuda = true;
            ginfo    = gpuDevice;
            dev_name = char(ginfo.Name);
            mem_gb   = double(ginfo.AvailableMemory) / 1e9;
        end
    catch
        has_cuda = false;
    end
end

Backend = struct();
Backend.IsOctave = is_oct;
Backend.UseGPU   = has_cuda;

if has_cuda
    Backend.Mode       = 'matlab_cuda';
    Backend.DeviceName = dev_name;
    Backend.MemoryGB   = mem_gb;
    Backend.ToDevice   = @(x) gpuArray(x);
    Backend.Zeros      = @(varargin) zeros(varargin{:}, 'gpuArray');
    Backend.Ones       = @(varargin) ones(varargin{:},  'gpuArray');
elseif is_oct
    Backend.Mode       = 'octave_pool';
    Backend.DeviceName = 'GNU Octave Multi-Core CPU (VFIToolkit-octave)';
    Backend.MemoryGB   = NaN;
    Backend.ToDevice   = @(x) x;
    Backend.Zeros      = @(varargin) zeros(varargin{:});
    Backend.Ones       = @(varargin) ones(varargin{:});
else
    Backend.Mode       = 'matlab_cpu';
    Backend.DeviceName = 'MATLAB Multi-Core Host CPU';
    Backend.MemoryGB   = NaN;
    Backend.ToDevice   = @(x) x;
    Backend.Zeros      = @(varargin) zeros(varargin{:});
    Backend.Ones       = @(varargin) ones(varargin{:});
end

if is_oct
    Backend.FlushConsole = @flush_octave_stdout;
else
    Backend.FlushConsole = @noop_flush;
end

% Optional persistent worker pool provisioning / teardown on GNU Octave:
if is_oct && isfield(Opts, 'StopWorkerPool') && logical(Opts.StopWorkerPool)
    if exist('vfi_pool', 'file') ~= 0
        try vfi_pool('stop'); catch, end
    end
    Backend.n_workers = 0;
elseif is_oct && isfield(Opts, 'EnsureWorkerPool') && logical(Opts.EnsureWorkerPool)
    page_screen_output(0);
    req_w = [];
    if isfield(Opts, 'n_workers') && ~isempty(Opts.n_workers)
        req_w = Opts.n_workers;
    end
    Backend.n_workers = ensure_octave_pool(req_w);
elseif isfield(Opts, 'n_workers') && ~isempty(Opts.n_workers)
    Backend.n_workers = Opts.n_workers;
else
    Backend.n_workers = 1;
end

end

function n_active = ensure_octave_pool(req_workers)
n_active = 1;
if exist('vfi_pool', 'file') == 0
    return;
end
pool_st = vfi_pool('status');
if isempty(req_workers)
    if pool_st.active
        n_active = pool_st.ncores;
        return;
    end
    req_workers = min(10, max(1, nproc() - 2));
end
if req_workers > 1
    ram_dir = vfi_ramdisk('mount', 2048);
    pool_st = vfi_pool('ensure', req_workers, ram_dir);
    if ~pool_st.active
        error('IGWelfare:PoolInitFailed', 'Failed to initialize Octave persistent worker pool on %s.', ram_dir);
    end
    n_active = pool_st.ncores;
end
end

function flush_octave_stdout()
fflush(stdout);
end

function noop_flush()
end
