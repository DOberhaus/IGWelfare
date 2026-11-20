function nFailed = run_all_tests(forceExit)
%RUN_ALL_TESTS Discover and run every tests/test_*.m, MATLAB or Octave, with timing.
if nargin < 1, forceExit = ''; end

suiteTic  = tic();
here      = fileparts(mfilename('fullpath'));
repoRoot  = fileparts(here);
parentDir = fileparts(repoRoot);
addpath(here);
addpath(repoRoot);

isOctave = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
hasGpu   = (~isOctave && exist('gpuDeviceCount', 'file') ~= 0 && gpuDeviceCount > 0);

if isOctave && is_noninteractive()
    debug_on_error(0);
    debug_on_interrupt(0);
end

vfiMatlabDir = fullfile(parentDir, 'VFIToolkit-matlab');
vfiOctaveDir = fullfile(parentDir, 'VFIToolkit-octave');

if exist(vfiMatlabDir, 'dir') == 7 && exist('ValueFnIter_Case1_FHorz', 'file') == 0
    add_vfitoolkit_matlab_selective(vfiMatlabDir);
elseif exist(vfiMatlabDir, 'dir') == 7 && exist('ValueFnIter_MixHorz_PType', 'file') == 0
    % Complement .octaverc if MixHorz_PType wasn't added yet
    mixDir = fullfile(vfiMatlabDir, 'ValueFnIter', 'MixHorz_PType');
    if exist(mixDir, 'dir') == 7, addpath(mixDir); end
end

vecFns = { ...
    'ReturnFn_SpatialHH', ...
    'ReturnFn_SpatialHH_Compact4D', ...
    'ReturnFn_Firm', ...
    'HumanCapital_Lifecycle_aprimeFn', ...
    'BenPorath_aprimeFn'};

if isOctave
    octPkgs = {'parallel', 'statistics', 'datatypes', 'tablicious', 'struct', 'io', 'optim'};
    for ip = 1:numel(octPkgs)
        try pkg('load', octPkgs{ip}); catch, end
    end
    if exist(vfiOctaveDir, 'dir') == 7 && exist('VFIToolkit_Octave_Setup', 'file') == 0
        addpath(vfiOctaveDir);
    end
    if exist('VFIToolkit_Octave_Setup', 'file') ~= 0
        VFIToolkit_Octave_Setup(vecFns, true);
    end
    addpath(fullfile(repoRoot, 'src', 'utils'), '-begin');
    if exist('vfi_pool', 'file') ~= 0
        pool_st = vfi_pool('status');
        if ~pool_st.active
            n_w = min(8, max(2, nproc() - 2));
            if n_w > 1
                vfi_pool('ensure', n_w, vfi_ramdisk('mount', 2048));
            end
        end
    end
elseif ~hasGpu && exist(vfiOctaveDir, 'dir') == 7 && exist('enable_vfi_cpu_accel', 'file') ~= 0
    enable_vfi_cpu_accel(vfiOctaveDir);
end

testMode = strtrim(getenv('IGWELFARE_TEST_MODE'));
if ~isempty(testMode)
    verify_platform_mode(testMode, isOctave, hasGpu);
end

slowWarnSec = str2double(getenv('IGWELFARE_SLOW_WARN_S'));
if isnan(slowWarnSec) || slowWarnSec <= 0
    slowWarnSec = 5.0;
end

listing = dir(fullfile(here, 'test_*.m'));
names = cell(1, numel(listing));
for k = 1:numel(listing)
    names{k} = listing(k).name(1:end-2);
end
names = sort(names);

nPass = 0; nFail = 0; nSkip = 0;
for k = 1:numel(names)
    tTest = tic();
    try
        feval(names{k});
        dtSec = toc(tTest);
        slowTag = '';
        if dtSec >= slowWarnSec
            slowTag = sprintf('  [SLOW >= %.1fs!]', slowWarnSec);
        end
        fprintf('PASS [%6.2fs] %s%s\n', dtSec, names{k}, slowTag);
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
    end
end

totalSec = toc(suiteTic);
if nSkip > 0
    fprintf('%d passed, %d failed (%d skipped) in %.2fs\n', nPass, nFail, nSkip, totalSec);
else
    fprintf('%d passed, %d failed in %.2fs\n', nPass, nFail, totalSec);
end
if nargout > 0, nFailed = nFail; end

if nFail > 0 && (strcmp(forceExit, 'exit') || is_noninteractive())
    exit(1);
end
end

function add_vfitoolkit_matlab_selective(root)
% Mirrors .octaverc selective directory loading (avoids .git and unused folders)
genDirs = { ...
    fullfile(root, 'DiscretizationMethods', 'FTsubcodes'), ...
    fullfile(root, 'Other'), ...
    fullfile(root, 'SubCodes'), ...
    fullfile(root, 'EvaluateFnOnAgentDist')};
for i = 1:numel(genDirs)
    if exist(genDirs{i}, 'dir') == 7, addpath(genpath(genDirs{i})); end
end

flatDirs = { ...
    fullfile(root, 'DiscretizationMethods', 'discretizeAR1_FarmerToda'), ...
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
    fullfile(root, 'StationaryDist', 'FHorz'), ...
    fullfile(root, 'StationaryDist', 'FHorz', 'ExpAsset'), ...
    fullfile(root, 'StationaryDist', 'FHorz', 'ExpAssetz'), ...
    fullfile(root, 'StationaryDist', 'FHorz', 'nProbs')};
for i = 1:numel(flatDirs)
    if exist(flatDirs{i}, 'dir') == 7, addpath(flatDirs{i}); end
end
end

function verify_platform_mode(mode, isOctave, hasGpu)
fprintf('=== IGWelfare Test Runner [mode=%s | octave=%d | gpu=%d] ===\n', ...
    mode, isOctave, hasGpu);
switch mode
    case 'matlab_gpu'
        assert(~isOctave && hasGpu, 'matlab_gpu requires MATLAB with gpuDeviceCount > 0.');
        assert(exist('ValueFnIter_Case1_FHorz', 'file') ~= 0, 'ValueFnIter_Case1_FHorz missing.');
    case 'matlab_nogpu'
        assert(~isOctave && ~hasGpu, 'matlab_nogpu requires MATLAB with no visible GPU.');
        assert(exist('ValueFnIter_Case1_FHorz', 'file') ~= 0, 'ValueFnIter_Case1_FHorz missing.');
    case 'octave_nogpu'
        assert(isOctave, 'octave_nogpu requires GNU Octave.');
        assert(exist('ValueFnIter_Case1_FHorz', 'file') ~= 0, 'ValueFnIter_Case1_FHorz missing.');
    otherwise
        error('Unknown IGWELFARE_TEST_MODE: %s', mode);
end
end

function tf = is_noninteractive()
tf = false;
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    a = argv();
    for i = 1:numel(a)
        if strncmp(a{i}, '--eval', 6), tf = true; return; end
    end
elseif exist('batchStartupOptionUsed', 'file') ~= 0
    tf = batchStartupOptionUsed();
end


end
