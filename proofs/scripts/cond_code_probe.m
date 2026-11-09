function [cond_half_pct, cond_zero_pop] = cond_code_probe()
% Extract Build_Custom_Table14_Fiscal_CSV from whichever Plot_ChildFiscal_SSankey.m is on
% the path, run it on a synthetic ledger and return CondPerChild for
%   node 14: Pop 0.5%, Flow 0.30 kNZD   (correct Cond = 60)
%   node  1: Pop 0%,   Flow 0.40 kNZD   (zero-population node)
% MATLAB has table and round(X,N); Octave has neither, so a struct shim and a textual
% round(X,2) rewrite are used there only (neither touches the Cond formula).
src = which('Plot_ChildFiscal_SSankey.m');
if isempty(src), error('cond_code_probe:path', 'Plot_ChildFiscal_SSankey.m not on path'); end
txt = fileread(src);
a = strfind(txt, 'function T_Fiscal = Build_Custom_Table14_Fiscal_CSV');
b = strfind(txt, 'function [img_Merged, fig_pos] = Stitch_NPanels_Canvas');
fn = txt(a(1):b(1) - 1);
if exist('OCTAVE_VERSION', 'builtin')   % Octave has no round(X, N): rewrite it textually, Octave only
    fn = regexprep(fn, 'round\(([^\n]*),\s*2\)', '(round(($1)*100)/100)');
end
d = tempname; mkdir(d);
fid = fopen(fullfile(d, 'Build_Custom_Table14_Fiscal_CSV.m'), 'w'); fwrite(fid, fn); fclose(fid);
if ~exist('table', 'file') && ~exist('table', 'builtin')
    fid = fopen(fullfile(d, 'table.m'), 'w');
    fwrite(fid, sprintf(['function T = table(varargin)\n' ...
        'T = struct();\nT.(''Gate'') = varargin{1};\nT.(''Node_Name'') = varargin{2};\nend\n']));
    fclose(fid);
end
oldp = path; addpath(d);
cleaner = onCleanup(@() cleanup_probe(oldp, d));
L.Pop_S1_Birth = [0 0.2 1 0.3];  L.Pop_S2_ECE_4Node = [0.1 0.2 0.3 0.4];
L.Pop_S3_Adol_5Node = [0.2 0.2 0.2 0.2 0.2];  L.Pop_S4_Skill = [0.005 0.5 0.495];
L.Pop_S5_Career = [0.2 0.2 0.2 0.2 0.2];
L.S1_Birth_kNZD = [0.4 1 1 1];  L.S2_ECE_4Node_kNZD = ones(1, 4);
L.S3_Adol_5Node_kNZD = ones(1, 5);  L.S4_Skill_kNZD = [0.3 1 1];
L.S5_Career_kNZD = ones(1, 5);  L.S6_Fiscal_kNZD = ones(1, 8);
T = Build_Custom_Table14_Fiscal_CSV({L}, {'SS0'});
c = T.SS0_CondPerChild_kNZD;
cond_half_pct = c(14);
cond_zero_pop = c(1);
end

function cleanup_probe(oldp, d)
path(oldp);
try, rmdir(d, 's'); catch, end
end
