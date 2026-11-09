% prove_anchor.m  --  id: anchor
% FertilityBargaining_Module.m anchors the super-age U-curve to T1 (made by WelfareDecomposition_4Region.m, Run_All
% Step 6) when T1 is in the base workspace, and otherwise to a typed constant. Does a fallback to the typed constant
% say so? Runs the real anchor block -- the lines of whichever FertilityBargaining_Module.m is on the path from
% "% Anchor CE_UCurve_SS2" up to (not including) "idx_64_u" -- in two situations: (1) no T1 in the workspace
% (the order in Run_All, Step 3 before Step 6), (2) a T1 that is not a usable table.
% Run with main's tree on the path, then the branch's. Prints ONE line:
%   anchor <RED|GREEN> announced=<n>/2 ce_anchor_64=<value used>
% RED = the typed constant was used without an IGW:TypedAnchor warning and log line; GREEN = both cases announced.
an_here = pwd; an_tmp = tempname(); mkdir(an_tmp); cd(an_tmp);
% GNU Octave has no istable (datatypes package); the anchor block calls it only when a T1 exists. Test-only stand-in:
% a variable is never a table here, which is all case (2) needs.
an_shim = (exist('istable', 'file') == 0 && exist('istable', 'builtin') == 0);
if an_shim
    an_fid = fopen(fullfile(an_tmp, 'istable.m'), 'w');
    fprintf(an_fid, 'function t = istable(x)\nt = false;\nend\n');
    fclose(an_fid);
    addpath(an_tmp); % (an_tmp is the cwd while the block runs; its absolute path is what goes on the path)
end
an_src = fileread(which('FertilityBargaining_Module'));
an_a   = strfind(an_src, '% Anchor CE_UCurve_SS2');
an_b   = strfind(an_src, 'idx_64_u');
an_blk = an_src(an_a(1):an_b(1)-1);
super_age_ss2_target = 64.0;
Reg_HH_Shares = [0.16 0.24 0.259 0.341];
an_announced = 0;
for an_case = 1:2
    evalin('base', 'clear T1');
    if an_case == 2, assignin('base', 'T1', 5); end
    lastwarn('');
    if exist('igw_run.log', 'file') == 2, delete('igw_run.log'); end
    eval(an_blk);
    [~, an_wid] = lastwarn();
    an_nlog = 0;
    if exist('igw_run.log', 'file') == 2
        an_nlog = numel(strfind(fileread('igw_run.log'), 'IGW:TypedAnchor'));
    end
    an_announced = an_announced + double(strcmp(an_wid, 'IGW:TypedAnchor') && an_nlog == 1);
end
evalin('base', 'clear T1');
cd(an_here);
if an_shim, rmpath(an_tmp); end
rmdir(an_tmp, 's');
if an_announced == 2, an_v = 'GREEN'; else, an_v = 'RED'; end
fprintf('anchor %s announced=%d/2 ce_anchor_64=%.6f\n', an_v, an_announced, ce_anchor_64);
clear an_* ce_anchor_64 ce_anchor_why T1_ws super_age_ss2_target Reg_HH_Shares
