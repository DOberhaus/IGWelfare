function igw_root = setup_igw_paths(quiet, force_reinit)
%% BULLETPROOF IDEMPOTENT PATH, TOOLKIT, & GRAPHICS BOOTSTRAP (MATLAB & GNU OCTAVE)
% File: setup_igw_paths.m
% Automatically invoked by repo-root .octaverc (GNU Octave) and startup.m (MATLAB),
% and safe to call at the top of any standalone script or function.
%
% Guarantees:
%   1. Adds all modular IGWelfare subdirectories (src/*, pipelines, plots) to path.
%   2. Locates sibling VFIToolkit-matlab and VFIToolkit-octave repositories.
%   3. In GNU Octave: runs VFIToolkit_Octave_Setup on the 4 canonical model kernels so
%      compatibility shims (xline, exportgraphics, legend, tables) are ALWAYS active.
%   4. In GNU Octave: configures graphics_toolkit ('qt' when available, 'fltk' in octave-cli,
%      NEVER 'gnuplot' which crashes on hggroup legends) and sets an existing sans-serif font
%      to eliminate 'FreeSans' fontconfig delays.

if nargin < 1 || isempty(quiet)
    quiet = false;
end
if nargin < 2 || isempty(force_reinit)
    force_reinit = false;
end

igw_root = fileparts(mfilename('fullpath'));
if isempty(igw_root)
    igw_root = pwd;
end

% Fast idempotent exit if already initialized in this session (survives 'clear' via root appdata!)
if ~force_reinit && isappdata(0, 'IGW_PATHS_READY') && isequal(getappdata(0, 'IGW_ROOT_DIR'), igw_root) ...
        && exist('Load_Empirical_Profile', 'file') == 2
    return;
end

% 1. Add root and modular subdirectories
rel_dirs = { ...
    '', ...
    fullfile('src', 'data'), ...
    fullfile('src', 'config'), ...
    fullfile('src', 'solvers'), ...
    fullfile('src', 'models'), ...
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

% 2. Locate sibling VFIToolkit-matlab and VFIToolkit-octave
if exist('ValueFnIter_MixHorz_PType', 'file') == 0
    vfi_mat_dir = fullfile(igw_root, '..', 'VFIToolkit-matlab');
    if exist(vfi_mat_dir, 'dir') ~= 0
        addpath(genpath(vfi_mat_dir));
    end
end

vfi_oct_dir = fullfile(igw_root, '..', 'VFIToolkit-octave');
if exist('VFIToolkit_Octave_Setup', 'file') == 0 && exist(vfi_oct_dir, 'dir') ~= 0
    addpath(vfi_oct_dir);
end

% 3. GNU Octave Shim, Kernel, Graphics Toolkit, & Font Hygiene
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    % Activate VFIToolkit-octave shims & register canonical model kernels NOW (after src/models is on path)
    if exist('VFIToolkit_Octave_Setup', 'file') ~= 0
        VFIToolkit_Octave_Setup({ ...
            'ReturnFn_SpatialHH', ...
            'ReturnFn_SpatialHH_Compact4D', ...
            'ReturnFn_Firm', ...
            'HumanCapital_Lifecycle_aprimeFn'});
    end
    % Keep IGWelfare/src/utils ahead of VFIToolkit-octave/shims/matlab (so vfi_active_ax([]) works)
    addpath(fullfile(igw_root, 'src', 'utils'), '-begin');

    % Graphics toolkit discipline:
    %   - Try switching 'fltk' -> 'qt' whenever 'qt' is in available_graphics_toolkits()
    %     (succeeds in 'octave' / 'octave --no-gui' when DISPLAY/window server is reachable;
    %      throws cleanly in 'octave-cli', caught below so 'fltk' remains active).
    %   - NEVER select 'gnuplot' (breaks Octave 11 hggroup/xline legend callbacks).
    if exist('graphics_toolkit', 'file') ~= 0
        try
            if strcmp(graphics_toolkit(), 'fltk') && any(strcmp(available_graphics_toolkits(), 'qt'))
                graphics_toolkit('qt');
            end
        catch
        end
    end

    % Use flat TrueType 'Arial' on macOS/Windows (NEVER Apple's .ttc 'Helvetica', whose sub-faces
    % trigger FreeType missing-glyph spam on TeX subscripts/superscripts like _{ECE} and ^{Econ}!)
    try
        if ismac || ispc
            def_font = 'Arial';
        else
            def_font = 'DejaVu Sans';
        end
        set(0, 'DefaultAxesFontName',   def_font);
        set(0, 'DefaultTextFontName',   def_font);
        set(0, 'DefaultLegendFontName', def_font);
    catch
    end
end

% 4. Record canonical repo root & initialization stamp in root appdata
setappdata(0, 'IGW_ROOT_DIR',    igw_root);
setappdata(0, 'IGW_PATHS_READY', true);

if ~quiet
    fprintf('[IGWelfare] Environment initialized (%s)\n', igw_root);
end


end
