function test_platform_and_toolkits()
%TEST_PLATFORM_AND_TOOLKITS Sanity-check VFIToolkit pathing, Resolve_Compute_Backend, and vfi_active_ax.

Backend = Resolve_Compute_Backend();
mode    = strtrim(getenv('IGWELFARE_TEST_MODE'));

% 1. VFIToolkit entrypoints must be reachable when sibling checkouts exist or in CI
if ~isempty(mode)
    check(exist('ValueFnIter_Case1_FHorz', 'file') ~= 0, ...
        'ValueFnIter_Case1_FHorz missing from path');
    check(exist('StationaryDist_FHorz_Case1', 'file') ~= 0, ...
        'StationaryDist_FHorz_Case1 missing from path');
end

% 2. Verify active GPU vs CPU contract via Resolve_Compute_Backend
if strcmp(mode, 'matlab_gpu')
    check(strcmp(Backend.Mode, 'matlab_cuda') && Backend.UseGPU, ...
        'matlab_gpu requires Resolve_Compute_Backend Mode == matlab_cuda');
    g = Backend.ToDevice([1.0, 2.0; 3.0, 4.0]);
    check(isa(g, 'gpuArray') && max(abs(gather(g * g') - [5, 11; 11, 25]), [], 'all') == 0, ...
        'Backend.ToDevice basic BLAS check failed');
elseif strcmp(mode, 'matlab_nogpu')
    check(strcmp(Backend.Mode, 'matlab_cpu') && ~Backend.UseGPU, ...
        'matlab_nogpu expected Mode == matlab_cpu');
elseif strcmp(mode, 'octave_nogpu')
    check(strcmp(Backend.Mode, 'octave_pool') && Backend.IsOctave, ...
        'octave_nogpu expected Mode == octave_pool');
end

% 3. Headless & dual-axis (yyaxis) axes helper (vfi_active_ax) sanity check
check(exist('vfi_active_ax', 'file') ~= 0, 'vfi_active_ax.m missing from path');
fig = figure('Visible', 'off');
cleanupObj = onCleanup(@() close_if_valid(fig));
ax_created = axes('Parent', fig);
ax_resolved = vfi_active_ax(ax_created);
check(~isempty(ax_resolved) && ishandle(ax_resolved), ...
    'vfi_active_ax failed to return a valid axes handle');
ax_default = vfi_active_ax([]);
check(~isempty(ax_default) && ishandle(ax_default), ...
    'vfi_active_ax([]) failed to resolve active axes handle');
end

function close_if_valid(fig)
if ishandle(fig)
    close(fig);
end
end

function check(cond, msg)
if ~cond
    error('tests:fail', '%s', msg);
end
end
