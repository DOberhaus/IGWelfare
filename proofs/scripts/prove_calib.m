% prove_calib.m  --  id: calib
% Calibrate_NZ_Moments.m Stage 2 runs fminsearch with MaxIter 40 and used to keep only [x_opt, fval_opt], so hitting the
% iteration cap (exitflag 0, not converged) went unreported. Runs the real Stage-2 lines of whichever
% Calibrate_NZ_Moments.m is on the path (from "fwd_logit =" through "theta_calibrated") against a stand-in objective that
% cannot converge in 40 iterations (SMM objective + VFI are replaced by a badly scaled quadratic; the lines under test are
% not changed), then checks with an independent fminsearch call that the optimiser really did not converge.
% Run with main's tree on the path, then the branch's. Prints ONE line:
%   calib <RED|GREEN> exitflag=<independent exitflag> IGW_NoConvergence_warning=<0|1> log_lines=<n>
% RED = optimiser stopped at the cap and nothing was announced; GREEN = announced (warning and log line).
ca_here = pwd; ca_tmp = tempname(); mkdir(ca_tmp); cd(ca_tmp);
ca_src = fileread(which('Calibrate_NZ_Moments'));
ca_a   = strfind(ca_src, 'fwd_logit = @');
ca_b   = strfind(ca_src, 'theta_calibrated');
ca_e   = find(ca_src(ca_b(1):end) == char(10), 1);
ca_blk = ca_src(ca_a(1):ca_b(1) + ca_e - 2);
lb = [0.15; 0.005; 0.18;  0.040; 0.040;  1.50; 1.50; 0.15];
ub = [0.75; 0.080; 0.55;  0.150; 0.180;  4.00; 8.00; 1.20];
best_theta = 0.5 * (lb + ub) + 0.01 * (ub - lb);
calib_options = optimset('Display', 'off', 'MaxIter', 40, 'TolX', 1e-3, 'TolFun', 1e-4);
obj_fn = @(th) sum(((th - 0.9 * ub) ./ (ub - lb)) .^ 2 .* [1; 1e3; 1; 1e3; 1; 1e3; 1; 1e3]);
inv_logit = @(p) log((p - lb) ./ max(1e-6, ub - p));
lastwarn('');
eval(ca_blk);
[~, ca_wid] = lastwarn();
[~, ~, ca_ef] = fminsearch(@(x) obj_fn(fwd_logit(x)), x0, calib_options);
ca_nlog = 0;
if exist('igw_run.log', 'file') == 2
    ca_nlog = numel(strfind(fileread('igw_run.log'), 'IGW:NoConvergence'));
end
cd(ca_here); rmdir(ca_tmp, 's');
ca_w = strcmp(ca_wid, 'IGW:NoConvergence');
if ca_ef ~= 1 && ~(ca_w && ca_nlog > 0), ca_v = 'RED'; else, ca_v = 'GREEN'; end
fprintf('calib %s exitflag=%d IGW_NoConvergence_warning=%d log_lines=%d\n', ca_v, ca_ef, ca_w, ca_nlog);
clear ca_* lb ub best_theta calib_options obj_fn inv_logit fwd_logit x0 x_opt fval_opt exitflag_opt output_opt theta_calibrated
