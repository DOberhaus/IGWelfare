% prove_cache.m  --  id: cache
% Does Run_All_NZ_Intergen_Suite.m load a per-step checkpoint that was built for a DIFFERENT configuration?
% Takes the five real cache-load conditions (the `if Use_Saved_Cache && ... exist(Cache_StepN, 'file') ...` lines of
% whichever Run_All_NZ_Intergen_Suite.m is on the path, steps 1,2,3,4,6) and evaluates each against
%   (a) a checkpoint stored with another config hash, (b) a checkpoint with no hash (written by the old code),
%   (c) a checkpoint stored with the current hash (control).
% Run with main's tree on the path, then the branch's. Prints ONE line:
%   cache <RED|GREEN> stale_accepted=<n>/10 matching_accepted=<m>/5
% RED = at least one stale checkpoint would be loaded; GREEN = none, and every matching one still loads.
cc_here = pwd; cc_tmp = tempname(); mkdir(cc_tmp); cd(cc_tmp);
cc_src   = fileread(which('Run_All_NZ_Intergen_Suite'));
cc_lines = regexp(cc_src, '[^\n]*if Use_Saved_Cache && ~Force_Recompute_All && exist\(Cache_Step\d[^\n]*', 'match');
cc_cur   = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
x = [1 2 3];
Cache_CfgHash = '00000000000000000000000000000000';  save('f_other.mat', 'x', 'Cache_CfgHash');
clear Cache_CfgHash;                                  save('f_nohash.mat', 'x');
Cache_CfgHash = cc_cur;                               save('f_match.mat', 'x', 'Cache_CfgHash');
Use_Saved_Cache = true; Force_Recompute_All = false;
cc_files = {'f_other.mat', 'f_nohash.mat', 'f_match.mat'};
cc_acc = zeros(1, 3);
for cc_i = 1:numel(cc_lines)
    cc_expr = regexprep(strtrim(cc_lines{cc_i}), '^if\s+', '');
    cc_tok  = regexp(cc_expr, 'exist\((Cache_Step\d)', 'tokens', 'once');
    for cc_f = 1:3
        Cache_CfgHash = cc_cur;                       % the current run's hash (unused by main's condition)
        eval([cc_tok{1} ' = cc_files{cc_f};']);
        cc_acc(cc_f) = cc_acc(cc_f) + double(eval(cc_expr));
    end
end
cd(cc_here); rmdir(cc_tmp, 's');
cc_stale = cc_acc(1) + cc_acc(2);
if numel(cc_lines) == 5 && cc_stale == 0 && cc_acc(3) == 5, cc_v = 'GREEN'; else, cc_v = 'RED'; end
fprintf('cache %s stale_accepted=%d/10 matching_accepted=%d/5\n', cc_v, cc_stale, cc_acc(3));
clear cc_* Cache_Step1 Cache_Step2 Cache_Step3 Cache_Step4 Cache_Step6 Cache_CfgHash Use_Saved_Cache Force_Recompute_All x
