% prove_ras.m  --  id: ras
% pruneAndBalanceFlowMatrix promises that source-block row sums stay exact after sub-threshold ribbons are pruned
% and the mass is redistributed by RAS scaling. Measures the worst row-sum drift on a 3x6 fixture (threshold 0.15).
% Run with main's pruneAndBalanceFlowMatrix.m on the path, then the branch's. Prints ONE line:
%   ras <RED|GREEN> <max |rowsum(out) - rowsum(in)|>
% RED = drift >= 1e-7 (row sums no longer match the input); GREEN = drift < 1e-7.
ras_B = [0.01  0.40  1.55  0.00  0.00  0.00;
         0.09  0.80  1.50  0.60  0.98  0.20;
         0.00  0.10  1.20  3.10 81.39  6.00];
ras_out   = pruneAndBalanceFlowMatrix(ras_B, 0.15);
ras_drift = max(abs(sum(ras_out, 2) - sum(ras_B, 2)));
if ras_drift < 1e-7, ras_v = 'GREEN'; else, ras_v = 'RED'; end
fprintf('ras %s %.6g\n', ras_v, ras_drift);
clear ras_*
