function [Params, Regions, Reg_HH_Shares] = Ensure_Workbench_Initialized(Params, Opts)
%% UNIFIED STANDALONE & PIPELINE WORKBENCH BOOTSTRAP CONTRACT
% File: src/config/Ensure_Workbench_Initialized.m
% Ensures modular paths, VFI Toolkit shims, optional GNU Octave worker pool, and
% the 4-tier epistemic Params struct are initialized identically across every
% standalone or suite-invoked pipeline script.
%
% Inputs:
%   Params : Existing Params struct (or [] / struct() on cold standalone start)
%   Opts   : Optional struct supporting:
%              .RequireToolkit    (default: false) -> throws IGWelfare:MissingToolkit if VFI Toolkit absent
%              .RequireWorkerPool (default: false) -> mounts RAMDisk & ensures Octave vfi_pool when n_workers > 1
%              .ForceConfigure    (default: false) -> re-runs Configure_Model_Params even if DataSpec_Digest exists
%              .Regions           (optional caller Regions override)
%              .Reg_HH_Shares     (optional caller Reg_HH_Shares override)

if nargin < 1 || isempty(Params)
    Params = struct();
end
if nargin < 2 || isempty(Opts)
    Opts = struct();
end

% 1. Ensure IGWelfare modular paths & Octave shims are registered (fast O(1) appdata check)
if exist('setup_igw_paths', 'file') == 2
    setup_igw_paths(true);
else
    here = fileparts(mfilename('fullpath'));
    cand = fullfile(fileparts(fileparts(here)), 'setup_igw_paths.m');
    if exist(cand, 'file') == 2
        run(cand);
    end
end

% 2. Optional VFI Toolkit presence check for heavy VFI solver scripts
if isfield(Opts, 'RequireToolkit') && logical(Opts.RequireToolkit)
    if exist('ValueFnIter_MixHorz_PType', 'file') == 0
        error('IGWelfare:MissingToolkit', ...
            'VFIToolkit not found on path. Add VFIToolkit-matlab (and VFIToolkit-octave in Octave) via startup.m or .octaverc.');
    end
end

% 3. Optional GNU Octave persistent worker pool bootstrap for VFI solver scripts
if isfield(Opts, 'RequireWorkerPool') && logical(Opts.RequireWorkerPool)
    if exist('OCTAVE_VERSION', 'builtin') ~= 0 && exist('vfi_pool', 'file') ~= 0
        if ~isfield(Params, 'n_workers') || isempty(Params.n_workers)
            pool_st = vfi_pool('status');
            if pool_st.active
                Params.n_workers = pool_st.ncores;
            else
                Params.n_workers = []; % Let vfi_pool('ensure') auto-detect physical cores
            end
        end
        if isempty(Params.n_workers) || Params.n_workers > 1
            ram_dir = vfi_ramdisk('mount', 2048);
            pool_st = vfi_pool('ensure', Params.n_workers, ram_dir);
            if ~pool_st.active
                error('IGWelfare:PoolInitFailed', 'Failed to initialize Octave persistent worker pool on %s.', ram_dir);
            end
            Params.n_workers = pool_st.ncores;
        end
    end
end

% 4. Initialize or refresh 4-tier epistemic parameter contract (default dt = 3, n_z_pts = 7)
force_cfg = isfield(Opts, 'ForceConfigure') && logical(Opts.ForceConfigure);
if force_cfg || ~isfield(Params, 'dt') || ~isfield(Params, 'DataSpec_Digest')
    Params = Configure_Model_Params(Params);
end

% 5. Resolve canonical Regions & Household Population Shares
if isfield(Opts, 'Regions') && ~isempty(Opts.Regions)
    Regions = Opts.Regions;
else
    Regions = Params.Regions;
end

if isfield(Opts, 'Reg_HH_Shares') && ~isempty(Opts.Reg_HH_Shares)
    Reg_HH_Shares = Opts.Reg_HH_Shares(:);
else
    Reg_HH_Shares = Params.Pop_Weights_4(:);
end

end
