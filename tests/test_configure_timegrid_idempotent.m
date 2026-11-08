function test_configure_timegrid_idempotent()
%% TEST_CONFIGURE_TIMEGRID_IDEMPOTENT
% Configure_TimeGrid_Params must be idempotent: Run_All_NZ_Intergen_Suite.m, NZ_4Region_Master.m and
% WelfareDecomposition_4Region.m each call it on an already-configured Params. Throws on failure, silent on success.
% No toolboxes, no GPU; runs under MATLAB and GNU Octave.
addpath(fileparts(fileparts(mfilename('fullpath'))));

% 1. Repeated calls at dt = 3 must not change anything (the original defect re-exponentiated beta every call)
P1 = Configure_TimeGrid_Params(struct(), 3);
P2 = Configure_TimeGrid_Params(P1, 3);
P3 = Configure_TimeGrid_Params(P2, 3);
check(P1.beta_hh   == 0.96^3, 'beta_hh after first call is not 0.96^dt');
check(P1.beta_firm == 0.95^3, 'beta_firm after first call is not 0.95^dt');
check(P2.beta_hh   == P1.beta_hh,   'beta_hh changed on the second call (dt = 3)');
check(P2.beta_firm == P1.beta_firm, 'beta_firm changed on the second call (dt = 3)');
check(P3.beta_hh   == P1.beta_hh,   'beta_hh changed on the third call (dt = 3)');
check(isequal(P1, P2) && isequal(P2, P3), 'Params differs after repeated Configure_TimeGrid_Params calls (dt = 3)');

% 2. Same at the other supported grids
for dt = [5 2 1]
    A = Configure_TimeGrid_Params(struct(), dt);
    B = Configure_TimeGrid_Params(A, dt);
    check(isequal(A, B), sprintf('Params not idempotent at dt = %d', dt));
    check(A.beta_hh == 0.96^dt, sprintf('beta_hh != 0.96^dt at dt = %d', dt));
end

% 3. Changing dt on an already-configured Params must equal configuring from scratch at the new dt
R = Configure_TimeGrid_Params(Configure_TimeGrid_Params(struct(), 3), 5);
S = Configure_TimeGrid_Params(struct(), 5);
check(isequal(R, S), 'dt 3 -> 5 on the same Params differs from a fresh dt = 5 configuration');

% 4. A caller-supplied beta is read as a 5-yr factor (original behaviour) and is not rescaled again on later calls
U1 = Configure_TimeGrid_Params(struct('beta_hh', 0.80), 3);
U2 = Configure_TimeGrid_Params(U1, 3);
check(U1.beta_hh == (0.80^(1/5))^3, 'caller-supplied beta_hh not converted as (beta^(1/5))^dt');
check(isequal(U1, U2), 'Params with a caller-supplied beta_hh is not idempotent');

% 5. A value the caller changes between calls is an override and survives
O = Configure_TimeGrid_Params(struct(), 3);
O.r = 0.5;
O.beta_firm = 0.90;
O = Configure_TimeGrid_Params(O, 3);
check(O.r == 0.5, 'caller override of r was overwritten');
check(O.beta_firm == (0.90^(1/5))^3, 'caller override of beta_firm was ignored');

% 6. Bookkeeping stays flat: every struct-valued Params field is keyed by PType names (HH_* / Firm_*), as the VFI Toolkit
% reads struct parameters per PType; the dt bookkeeping is plain numeric (dt_applied, beta_*_ann)
T = Configure_TimeGrid_Params(Configure_TimeGrid_Params(struct(), 3), 3);
check(isnumeric(T.dt_applied) && isscalar(T.dt_applied) && T.dt_applied == 3, 'dt_applied is not the plain number dt');
fn = fieldnames(T);
for k = 1:numel(fn)
    if isstruct(T.(fn{k}))
        sub = fieldnames(T.(fn{k}));
        check(all(strncmp(sub, 'HH_', 3) | strncmp(sub, 'Firm_', 5)), ...
            sprintf('struct-valued Params field %s is not keyed by PType names', fn{k}));
    end
end
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_configure_timegrid_idempotent: %s', msg);
end
end
