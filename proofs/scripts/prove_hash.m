% prove_hash.m  --  id: hash
% Get_ModelConfigHash must give a different cache path when ANY part of Params changes. The old version hashed a sample
% of at most ~8192 bytes of getByteStreamFromArray(...) (MATLAB-only builtin), so a change inside a large array can
% leave the path unchanged. Measures: for 200 single-element changes spread across a 20000-element Params field, how
% many produce a different cache path. Run with main's Get_ModelConfigHash.m on the MATLAB path, then the branch's.
% Prints ONE line:
%   hash <RED|GREEN> detected=<n>/200 first_missed_element=<k or none>
%   RED = at least one change left the cache path unchanged; GREEN = all 200 changes were detected.
% Under GNU Octave the old function cannot run (no getByteStreamFromArray): prints "hash SKIP octave".
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    disp('hash SKIP octave');
else
    hp_here = pwd;
    hp_tmp  = tempname();
    mkdir(hp_tmp);
    cd(hp_tmp);
    hp_N    = 20000;
    hp_P    = struct('dt', 3, 'big', (1:hp_N)' / 7, 'tag', 'x');
    hp_base = Get_ModelConfigHash('prove_hash', hp_P, 1, 2, 3, 4);
    hp_idx  = round(linspace(50, hp_N - 50, 200));
    hp_det  = 0;
    hp_miss = 'none';
    for hp_k = 1:numel(hp_idx)
        hp_Q = hp_P;
        hp_Q.big(hp_idx(hp_k)) = hp_Q.big(hp_idx(hp_k)) + 1;
        hp_path = Get_ModelConfigHash('prove_hash', hp_Q, 1, 2, 3, 4);
        if ~strcmp(hp_path, hp_base)
            hp_det = hp_det + 1;
        elseif strcmp(hp_miss, 'none')
            hp_miss = sprintf('%d', hp_idx(hp_k));
        end
    end
    cd(hp_here);
    rmdir(hp_tmp, 's');
    if hp_det == numel(hp_idx), hp_v = 'GREEN'; else, hp_v = 'RED'; end
    fprintf('hash %s detected=%d/%d first_missed_element=%s\n', hp_v, hp_det, numel(hp_idx), hp_miss);
    clear hp_*
end
