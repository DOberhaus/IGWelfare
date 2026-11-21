function test_wave4_platform_contracts()
%% TEST_WAVE4_PLATFORM_CONTRACTS
% Enforces Wave 4 platform rationalization & single-source abstraction contracts:
%   1. Static zero-scatter audit: forbids raw OCTAVE_VERSION, gpuDeviceCount, gpuArray(,
%      vfi_restore_tables(, fflush(, and .BoxFace outside setup_igw_paths.m and src/utils/.
%   2. Resolve_Compute_Backend contract (native vs ForceCPU, ToDevice, Zeros, Ones, FlushConsole).
%   3. IGW_MD5_Hex RFC 1321 test vectors & struct determinism.
%   4. IGW_Restore_Tables multi-output passthrough.
%   5. IGW_UI_Style & unified vfi_active_ax dual-axis (yyaxis) peer resolution.

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);
setup_igw_paths(true);

%% 1. STATIC ZERO-SCATTER AUDIT ACROSS APPLICATION, MODEL, SOLVER, CONFIG, PLOT, & TEST LAYERS
checked_dirs = { ...
    fullfile(repo_root, 'pipelines'), ...
    fullfile(repo_root, 'plots'), ...
    fullfile(repo_root, 'src', 'config'), ...
    fullfile(repo_root, 'src', 'data'), ...
    fullfile(repo_root, 'src', 'models'), ...
    fullfile(repo_root, 'src', 'solvers'), ...
    fullfile(repo_root, 'src', 'calibration'), ...
    fullfile(repo_root, 'tests')};

% Build token strings dynamically so this test file itself doesn't self-trigger on literal strings!
forbidden_tokens = { ...
    ['OCTAVE_', 'VERSION'], ...
    ['gpuDevice', 'Count'], ...
    ['gpu', 'Array('], ...
    ['vfi_restore_', 'tables('], ...
    ['ff', 'lush('], ...
    ['.Box', 'Face']};

for d_i = 1:numel(checked_dirs)
    mfiles = dir(fullfile(checked_dirs{d_i}, '*.m'));
    for f_i = 1:numel(mfiles)
        fpath = fullfile(checked_dirs{d_i}, mfiles(f_i).name);
        lines = strsplit(fileread(fpath), char(10));
        for ln_i = 1:numel(lines)
            s = strtrim(lines{ln_i});
            if isempty(s) || s(1) == '%', continue; end
            pct = strfind(s, '%');
            if ~isempty(pct), s = s(1:pct(1)-1); end
            for t_i = 1:numel(forbidden_tokens)
                tok = forbidden_tokens{t_i};
                check(isempty(strfind(s, tok)), ...
                    sprintf('%s:%d violates Wave 4 platform boundary with raw token "%s"', ...
                    mfiles(f_i).name, ln_i, tok));
            end
        end
    end
end

%% 2. RESOLVE_COMPUTE_BACKEND CONTRACT
B_nat = Resolve_Compute_Backend();
check(ismember(B_nat.Mode, {'matlab_cuda', 'matlab_cpu', 'octave_pool'}), ...
    sprintf('Unexpected Backend.Mode: %s', B_nat.Mode));
B_cpu = Resolve_Compute_Backend(struct('ForceCPU', true));
check(~B_cpu.UseGPU, 'ForceCPU failed to disable UseGPU');
Z_mat = B_cpu.Zeros(2, 3);
O_mat = B_cpu.Ones(2, 3);
check(isequal(size(Z_mat), [2, 3]) && all(Z_mat(:) == 0), 'Backend.Zeros failed');
check(isequal(size(O_mat), [2, 3]) && all(O_mat(:) == 1), 'Backend.Ones failed');
check(isequal(B_cpu.ToDevice([1, 2]), [1, 2]), 'CPU Backend.ToDevice failed identity check');
B_cpu.FlushConsole();

%% 3. IGW_MD5_HEX RFC 1321 VECTORS & STRUCT DETERMINISM
check(strcmp(IGW_MD5_Hex(''),    'd41d8cd98f00b204e9800998ecf8427e'), 'MD5("") RFC 1321 mismatch');
check(strcmp(IGW_MD5_Hex('abc'), '900150983cd24fb0d6963f7d28e17f72'), 'MD5("abc") RFC 1321 mismatch');
s_a = struct('alpha', 1.25, 'beta', [1, 2, 3]);
check(strcmp(IGW_MD5_Hex(s_a), IGW_MD5_Hex(s_a)) && numel(IGW_MD5_Hex(s_a)) == 32, ...
    'IGW_MD5_Hex struct determinism check failed');

%% 4. IGW_RESTORE_TABLES MULTI-ARG CONTRACT
[r1, r2] = IGW_Restore_Tables([10, 20], struct('k', 5));
check(isequal(r1, [10, 20]) && isstruct(r2) && r2.k == 5, 'IGW_Restore_Tables corrupted passthrough inputs');

%% 5. IGW_UI_STYLE & UNIFIED VFI_ACTIVE_AX DUAL-AXIS CONTRACT
vis_str = IGW_UI_Style('headless_vis');
check(ismember(vis_str, {'on', 'off'}), 'IGW_UI_Style headless_vis returned invalid visibility');
[x_all, x_sub] = IGW_UI_Style('bar_x', {'A', 'B', 'C'});
check(numel(x_all) == 3 && numel(x_sub) == 2, 'IGW_UI_Style bar_x returned wrong lengths');

fig = figure('Visible', 'off');
cleanupObj = onCleanup(@() close_fig_safe(fig));
ax = axes('Parent', fig);
plot(ax, [1, 2, 3], [2, 4, 6], 'DisplayName', 'TestSeries');
IGW_UI_Style('bar_xticks', ax, {'A', 'B', 'C'});
lgd = legend(ax, 'show');
IGW_UI_Style('legend_alpha', lgd, 0.90);

yyaxis(ax, 'left');
set(vfi_active_ax(ax), 'YColor', [0.75, 0.10, 0.10]);
c_left = get(vfi_active_ax(ax), 'YColor');
yyaxis(ax, 'right');
set(vfi_active_ax(ax), 'YColor', [0.10, 0.50, 0.20]);
c_right = get(vfi_active_ax(ax), 'YColor');
yyaxis(ax, 'left');
c_left_after = get(vfi_active_ax(ax), 'YColor');
check(max(abs(c_left - c_left_after)) < 1e-6 && max(abs(c_left - c_right)) > 0.2, ...
    'vfi_active_ax overwrote left YColor when styling right yyaxis');

end

function close_fig_safe(fig)
if ishandle(fig)
    close(fig);
end
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_wave4_platform_contracts: %s', msg);
end
end
