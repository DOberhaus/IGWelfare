% prove_standins.m  --  id: standins
% Missing SS1 / SS2 results in the base workspace: does Build_Phase_Registry say so?
% Run with the files under test on the MATLAB / Octave path (main's, then the branch's); prints ONE line:
%   standins <RED|GREEN> <measured value>
% RED   = stand-in values were substituted with no IGW:PhaseStandIn warning and no log line.
% GREEN = the substitution raised IGW:PhaseStandIn and wrote igw_run.log lines.
% Works in a scratch directory; plants and then clears a few base-workspace variables (never run in a live session).
ps_vars = {'StatDist_SS0', 'Policy_SS0', 'V_SS0', 'jDist_SS0', 'Params_SS0', 'IG_Diag_SS0'};
ps_here = pwd;
ps_tmp  = tempname();
mkdir(ps_tmp);
cd(ps_tmp);
ps_P0 = struct('G_ece', 0.045, 'tau_l', 0.22);
ps_P0.Q_reg = struct('HH_Rural', 1.05, 'HH_Small', 1.40, 'HH_Large', 2.05, 'HH_Auckland', 3.10);
ps_P0.w_reg = struct('HH_Rural', 0.85, 'HH_Small', 0.93, 'HH_Large', 1.05, 'HH_Auckland', 1.18);
assignin('base', 'StatDist_SS0', 'dist0');
assignin('base', 'Policy_SS0',   'pol0');
assignin('base', 'V_SS0',        'v0');
assignin('base', 'jDist_SS0',    'jd0');
assignin('base', 'Params_SS0',   ps_P0);
assignin('base', 'IG_Diag_SS0',  struct('Emig_By_SkillTier', [0.10 0.20 0.30]));
lastwarn('');
ps_status = 'ok';
try
    ps_out = evalc('ps_Ph = Build_Phase_Registry({''SS0'', ''SS1'', ''SS2''});');
catch ps_err
    ps_status = ['error: ', ps_err.message];
end
[ps_msg, ps_wid] = lastwarn();
ps_nlog = 0;
if exist('igw_run.log', 'file') == 2
    ps_txt  = fileread('igw_run.log');
    ps_nlog = numel(strfind(ps_txt, 'IGW:PhaseStandIn'));
end
ps_g1 = NaN; ps_g2 = NaN;
if strcmp(ps_status, 'ok')
    ps_g1 = ps_Ph(2).Params.G_ece;
    ps_g2 = ps_Ph(3).Params.G_ece;
end
cd(ps_here);
rmdir(ps_tmp, 's');
for ps_k = 1:numel(ps_vars)
    evalin('base', sprintf('clear %s', ps_vars{ps_k}));
end
if strcmp(ps_wid, 'IGW:PhaseStandIn') && ps_nlog > 0
    ps_verdict = 'GREEN';
else
    ps_verdict = 'RED';
end
% (lastwarn can hold an unrelated interpreter notice, so only the IGW:PhaseStandIn id is reported)
fprintf('standins %s status=%s IGW_PhaseStandIn_warning=%d log_lines=%d SS1_G_ece=%.4f SS2_G_ece=%.4f\n', ...
    ps_verdict, ps_status, strcmp(ps_wid, 'IGW:PhaseStandIn'), ps_nlog, ps_g1, ps_g2);
clear ps_*
