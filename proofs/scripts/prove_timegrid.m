% prove_timegrid.m  --  id: timegrid
% Configure_TimeGrid_Params is called again on an already-configured Params (Run_All_NZ_Intergen_Suite.m,
% NZ_4Region_Master.m, WelfareDecomposition_4Region.m). Idempotent = the second and third call change nothing.
% Run with the tree under test on the path (9fc339a = our previous base, c23787e = upstream main, then the branch).
% Prints ONE line:
%   timegrid <RED|GREEN> beta_hh_after_calls_1_2_3=<a>,<b>,<c> params_equal=<0|1>
% RED = a repeated call changed Params; GREEN = three calls at dt = 3 leave Params identical.
tg_P1 = Configure_TimeGrid_Params(struct(), 3);
tg_P2 = Configure_TimeGrid_Params(tg_P1, 3);
tg_P3 = Configure_TimeGrid_Params(tg_P2, 3);
tg_eq = isequal(tg_P1, tg_P2) && isequal(tg_P2, tg_P3);
if tg_eq, tg_v = 'GREEN'; else, tg_v = 'RED'; end
fprintf('timegrid %s beta_hh_after_calls_1_2_3=%.6f,%.6f,%.6f params_equal=%d\n', tg_v, tg_P1.beta_hh, tg_P2.beta_hh, tg_P3.beta_hh, tg_eq);
clear tg_*
