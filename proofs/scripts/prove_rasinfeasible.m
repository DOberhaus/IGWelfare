% prove_rasinfeasible.m  --  id: rasinfeasible
% When the pruned support cannot satisfy both margins, pruneAndBalanceFlowMatrix used to return a matrix whose row
% sums are off without saying so. Fixture: [2.09 0 0.11; 0.13 2.26 0; 85.06 0 77.31], threshold 0.15.
% Run with main's pruneAndBalanceFlowMatrix.m on the path, then the branch's. Prints ONE line:
%   rasinfeasible <RED|GREEN> row_err=<max row-sum error> IGW_NoConvergence_warning=<0|1>
% RED = row sums are off (> 1e-6) and no IGW:NoConvergence warning was raised; GREEN = the failure was announced.
rasi_X = [2.09 0 0.11;  0.13 2.26 0;  85.06 0 77.31];
lastwarn('');
rasi_out = pruneAndBalanceFlowMatrix(rasi_X, 0.15);
[~, rasi_wid] = lastwarn();
rasi_err = max(abs(sum(rasi_out, 2) - sum(rasi_X, 2)));
rasi_w   = strcmp(rasi_wid, 'IGW:NoConvergence');
if rasi_err > 1e-6 && ~rasi_w, rasi_v = 'RED'; else, rasi_v = 'GREEN'; end
fprintf('rasinfeasible %s row_err=%.6g IGW_NoConvergence_warning=%d\n', rasi_v, rasi_err, rasi_w);
clear rasi_*
