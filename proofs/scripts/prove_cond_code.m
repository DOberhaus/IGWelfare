% prove_cond_code  Behaviour of the CondPerChild formula in Plot_ChildFiscal_SSankey.m.
% A 0.5% node with Flow 0.30 must give Cond = Flow/(0.5/100) = 60. The 1% floor gives 30.
% Needs cond_code_probe.m and the Plot_ChildFiscal_SSankey.m under test on the path.
[c14, ~] = cond_code_probe();
if abs(c14 - 60) < 1e-6, v = 'GREEN'; else, v = 'RED'; end
disp(['cond_code ' v ' ' num2str(c14)]);
