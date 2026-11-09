function run_proofs(varargin)
%RUN_PROOFS  RED-on-MAIN / GREEN-on-BRANCH proof runner (MATLAB and GNU Octave).
%   run_proofs            run all proofs, print one line per side, print a summary
%   run_proofs('exit')    same, then exit the interpreter (status 1 if any proof unexpected)
%
%   For every proof two temporary side trees are built under tempdir:
%     MAIN   = the repository root files the proofs need (root *.m, tests/, tools/,
%              Output_NZ_4Region_Intergen/*.csv) -- the worktree root is upstream/main
%     BRANCH = MAIN plus the overlay proofs/branch/<pr>/ (the PR's added/modified files)
%   Each side: cd into it, reset the path, addpath(side, side/tests, side/tools, proofs/scripts),
%   run the prove_* script under evalc, print "<pr> <proof> <MAIN|BRANCH> <result line>".
%   Run it from the proofs/ folder (or anywhere: it locates itself via mfilename).

isOct   = exist('OCTAVE_VERSION', 'builtin') ~= 0;
wantExit = any(strcmp(varargin, 'exit'));

proofsDir = fileparts(mfilename('fullpath'));
rootDir   = fileparts(proofsDir);
scriptDir = fullfile(proofsDir, 'scripts');
startDir  = pwd;
startPath = path;

% Table: pr, proof id, script, expected MAIN verdict, expected BRANCH verdict, setup (files copied from the
% PR overlay into MAIN only: test-support helpers that the measured logic reads but that main does not have).
% prove_hash: getByteStreamFromArray is MATLAB-only, so Octave prints SKIP on both sides.
if isOct, hashMain = 'SKIP'; hashBranch = 'SKIP'; else, hashMain = 'RED'; hashBranch = 'GREEN'; end
P = { ...
    'pr8', 'standins',     'prove_standins',     'RED',      'GREEN',     {}; ...
    'pr8', 'ras',          'prove_ras',          'RED',      'GREEN',     {}; ...
    'pr8', 'rasinfeasible','prove_rasinfeasible','RED',      'GREEN',     {}; ...
    'pr8', 'cache',        'prove_cache',        'RED',      'GREEN',     {}; ...
    'pr8', 'calib',        'prove_calib',        'RED',      'GREEN',     {}; ...
    'pr8', 'anchor',       'prove_anchor',       'RED',      'GREEN',     {}; ...
    'pr8', 'hash',         'prove_hash',         hashMain,   hashBranch,  {}; ...
    'pr8', 'timegrid',     'prove_timegrid',     'GREEN',    'GREEN',     {}; ...   % informational: fixed upstream
    'pr9', 'cond',         'prove_cond',         'RED',      'GREEN',     {fullfile('tests', 'read_csv_cells.m')}; ...
    'pr9', 'cond_code',    'prove_cond_code',    'RED',      'GREEN',     {} };

nOK = 0; nBad = 0;
for k = 1:size(P, 1)
    pr = P{k, 1}; id = P{k, 2}; scr = P{k, 3}; support = P{k, 6};
    overlay = fullfile(proofsDir, 'branch', pr);
    mainDir   = [tempname() '_main'];
    branchDir = [tempname() '_branch'];
    build_side(rootDir, mainDir, '');
    for j = 1:numel(support)      % read_csv_cells.m: test helper only, identical file to the one the PR adds
        if exist(fullfile(mainDir, fileparts(support{j})), 'dir') ~= 7, mkdir(fullfile(mainDir, fileparts(support{j}))); end
        copyfile(fullfile(overlay, support{j}), fullfile(mainDir, support{j}));
    end
    build_side(rootDir, branchDir, overlay);
    sides  = {'MAIN', 'BRANCH'};
    dirs   = {mainDir, branchDir};
    expect = {P{k, 4}, P{k, 5}};
    for s = 1:2
        res = run_one(dirs{s}, scriptDir, scr, id, isOct);
        verdict = '';
        tok = strsplit(strtrim(res), ' ');
        if numel(tok) >= 2, verdict = tok{2}; end
        ok = strcmp(verdict, expect{s});
        flag = '';
        if ok, nOK = nOK + 1; else, nBad = nBad + 1; flag = ['   <-- UNEXPECTED, wanted ' expect{s}]; end
        fprintf('%s %s %s %s%s\n', pr, id, sides{s}, res, flag);
    end
    cd(startDir);
    path(startPath);
    rmdir(mainDir, 's');
    rmdir(branchDir, 's');
end

fprintf('%d proofs as expected, %d unexpected\n', nOK, nBad);

% Exit handling: MATLAB exits only in batch mode or on request; Octave exits when not in the GUI (or on request).
doExit = wantExit;
if isOct
    if ~isguirunning(), doExit = true; end
else
    if exist('batchStartupOptionUsed', 'file') ~= 0 && batchStartupOptionUsed(), doExit = true; end
end
if doExit && nBad > 0
    exit(1);
elseif wantExit
    exit(0);
end
end

function res = run_one(sideDir, scriptDir, scr, id, isOct)
% Run one prove_* script against one side tree; return its one result line.
cd(sideDir);
if isOct
    path(pathdef());
else
    restoredefaultpath();
end
addpath(sideDir);
for sub = {'tests', 'tools'}                       % (main has neither folder; add only what exists)
    if exist(fullfile(sideDir, sub{1}), 'dir') == 7, addpath(fullfile(sideDir, sub{1})); end
end
addpath(scriptDir);
clear('functions');
try
    out = evalc(scr);
    lines = strsplit(out, char(10));
    res = '';
    for i = 1:numel(lines)
        ln = strtrim(lines{i});
        if strncmp(ln, [id ' '], numel(id) + 1), res = ln; end   % last matching line wins
    end
    if isempty(res), res = ['ERROR no result line; output: ' strtrim(out)]; end
catch err
    res = ['ERROR ' strrep(err.message, char(10), ' ')];
end
end

function build_side(rootDir, dest, overlay)
% MAIN = root *.m + tests/ + tools/ + Output csv; with a non-empty overlay, BRANCH = MAIN + overlay.
mkdir(dest);
copyfile(fullfile(rootDir, '*.m'), dest);
sub = {'tests', 'tools'};
for i = 1:numel(sub)
    if exist(fullfile(rootDir, sub{i}), 'dir') == 7
        mkdir(fullfile(dest, sub{i}));
        copyfile(fullfile(rootDir, sub{i}, '*'), fullfile(dest, sub{i}));
    end
end
od = fullfile(rootDir, 'Output_NZ_4Region_Intergen');
if exist(od, 'dir') == 7
    mkdir(fullfile(dest, 'Output_NZ_4Region_Intergen'));
    copyfile(fullfile(od, '*.csv'), fullfile(dest, 'Output_NZ_4Region_Intergen'));
end
if ~isempty(overlay)
    copyfile(fullfile(overlay, '*'), dest);
end
end
