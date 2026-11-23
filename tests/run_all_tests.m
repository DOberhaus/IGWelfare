function nFailed = run_all_tests(forceExit)
%RUN_ALL_TESTS Discover and run every tests/test_*.m across MATLAB CUDA, MATLAB CPU, and GNU Octave.
if nargin < 1, forceExit = ''; end

suiteTic = tic();
here     = fileparts(mfilename('fullpath'));
repoRoot = fileparts(here);
addpath(here);
addpath(repoRoot);

% Single-source environment, toolkit, and backend initialization:
setup_igw_paths(true);
Backend = Resolve_Compute_Backend();

if Backend.IsOctave
    page_screen_output(0);
    if is_noninteractive()
        debug_on_error(0);
        debug_on_interrupt(0);
    end
    n_w = min(8, max(2, nproc() - 2));
    Backend = Resolve_Compute_Backend(struct('EnsureWorkerPool', true, 'n_workers', n_w));
end

testMode = strtrim(getenv('IGWELFARE_TEST_MODE'));
if ~isempty(testMode)
    verify_platform_mode(testMode, Backend);
end

slowWarnSec = str2double(getenv('IGWELFARE_SLOW_WARN_S'));
if isnan(slowWarnSec) || slowWarnSec <= 0
    slowWarnSec = 5.0;
end

listing = dir(fullfile(here, 'test_*.m'));
names   = sort(cellfun(@(nm) nm(1:end-2), {listing.name}, 'UniformOutput', false));

nPass = 0; nFail = 0; nSkip = 0;
for k = 1:numel(names)
    tTest = tic();
    try
        feval(names{k});
        dtSec = toc(tTest);
        slowTag = '';
        if dtSec >= slowWarnSec
            slowTag = sprintf('  [SLOW >= %.1fs]', slowWarnSec);
        end
        fprintf('PASS [%6.2fs] %s%s\n', dtSec, names{k}, slowTag);
        if Backend.IsOctave, fflush(stdout); end
        nPass = nPass + 1;
    catch err
        dtSec = toc(tTest);
        if strcmp(err.identifier, 'tests:skip')
            fprintf('SKIP [%6.2fs] %s: %s\n', dtSec, names{k}, strtrim(err.message));
            nSkip = nSkip + 1;
        else
            msg = strrep(strtrim(err.message), char(10), [char(10) '     ']);
            fprintf('FAIL [%6.2fs] %s: %s\n', dtSec, names{k}, msg);
            nFail = nFail + 1;
        end
        if Backend.IsOctave, fflush(stdout); end
    end
end

totalSec = toc(suiteTic);
if nSkip > 0
    fprintf('%d passed, %d failed (%d skipped) in %.2fs\n', nPass, nFail, nSkip, totalSec);
else
    fprintf('%d passed, %d failed in %.2fs\n', nPass, nFail, totalSec);
end
if nargout > 0, nFailed = nFail; end

if Backend.IsOctave && (strcmp(forceExit, 'exit') || is_noninteractive())
    if exist('vfi_pool', 'file') ~= 0
        try vfi_pool('stop'); catch, end
    end
    fflush(stdout);
end

if nFail > 0 && (strcmp(forceExit, 'exit') || is_noninteractive())
    exit(1);
elseif strcmp(forceExit, 'exit')
    exit(0);
end
end

function verify_platform_mode(mode, Backend)
fprintf('=== IGWelfare Test Runner [mode=%s | backend=%s | gpu=%d] ===', ...
    mode, Backend.Mode, Backend.UseGPU);
assert(exist('ValueFnIter_Case1_FHorz', 'file') ~= 0, 'ValueFnIter_Case1_FHorz missing.');
switch mode
    case 'matlab_gpu'
        assert(strcmp(Backend.Mode, 'matlab_cuda'), 'matlab_gpu requires Backend.Mode == matlab_cuda.');
    case 'matlab_nogpu'
        assert(strcmp(Backend.Mode, 'matlab_cpu'), 'matlab_nogpu requires MATLAB with no visible GPU.');
    case 'octave_nogpu'
        assert(strcmp(Backend.Mode, 'octave_pool'), 'octave_nogpu requires GNU Octave.');
    otherwise
        error('Unknown IGWELFARE_TEST_MODE: %s', mode);
end
end

function tf = is_noninteractive()
tf = false;
Backend = Resolve_Compute_Backend();
if Backend.IsOctave
    a = argv();
    for i = 1:numel(a)
        if strncmp(a{i}, '--eval', 6), tf = true; return; end
    end
elseif exist('batchStartupOptionUsed', 'file') ~= 0
    tf = batchStartupOptionUsed();
end
end
