function test_returnfn_firm_vectorized()
%TEST_RETURNPN_FIRM_VECTORIZED Verify scalar, 3D broadcasted CPU, and GPU parity for ReturnFn_Firm.

Backend = Resolve_Compute_Backend();
hasGpu  = Backend.UseGPU;
to_dev  = Backend.ToDevice;

% Realistic NZ firm parameters
w_reg      = 1.15;
r          = 0.04;
alpha_k    = 0.33;
lambda_col = 1.50;
delta_k    = 0.06;
tau_k      = 0.28;
tau_a      = 0.005;
dt         = 2.0;

% Orient grids orthogonally for 3D implicit expansion: [n_ap x n_a x n_z]
aprime_vec = linspace(0.1, 8.0, 9)';              % [9 x 1 x 1]
a_row      = linspace(0.2, 8.0, 7);               % [1 x 7 x 1]
z_page     = reshape([0.75, 1.00, 1.35], 1, 1, 3); % [1 x 1 x 3]

% 1. Vectorized 3D tensor call on CPU
F_vec = ReturnFn_Firm(aprime_vec, a_row, z_page, ...
    w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt);
check(isequal(size(F_vec), [9, 7, 3]), ...
    sprintf('Expected [9 7 3] output, got [%s]', num2str(size(F_vec))));

% 2. Scalar contract parity via arrayfun over meshgrid (no C-style nested loops)
[AP, A, Z] = ndgrid(aprime_vec(:), a_row(:), z_page(:));
F_scalar = arrayfun(@(ap, a, z) ReturnFn_Firm(ap, a, z, ...
    w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt), AP, A, Z);

check(isequal(isinf(F_vec), isinf(F_scalar)) && isequal(isnan(F_vec), isnan(F_scalar)), ...
    'Feasibility mask (-Inf / NaN) mismatch between vectorized and scalar ReturnFn_Firm');

finite_mask = isfinite(F_vec);
check(any(finite_mask(:)), 'ReturnFn_Firm produced zero finite states on valid grid');
max_diff_cpu = max(abs(F_vec(finite_mask) - F_scalar(finite_mask)));
check(max_diff_cpu < 1e-12, ...
    sprintf('Scalar vs vectorized CPU mismatch: max diff = %.3e', max_diff_cpu));

% 3. GPU tensor + arrayfun parity when running on CUDA workstation
if hasGpu
    F_gpu_vec = gather(ReturnFn_Firm(to_dev(aprime_vec), to_dev(a_row), to_dev(z_page), ...
        w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt));
    F_gpu_af = gather(arrayfun(@ReturnFn_Firm, ...
        to_dev(AP), to_dev(A), to_dev(Z), ...
        w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt));

    check(isequal(isinf(F_vec), isinf(F_gpu_vec)) && isequal(isinf(F_vec), isinf(F_gpu_af)), ...
        'GPU feasibility mask mismatch in ReturnFn_Firm');
    max_diff_gpu = max([ ...
        max(abs(F_vec(finite_mask) - F_gpu_vec(finite_mask))); ...
        max(abs(F_vec(finite_mask) - F_gpu_af(finite_mask))) ]);
    check(max_diff_gpu < 1e-12, ...
        sprintf('CPU vs GPU ReturnFn_Firm mismatch: max diff = %.3e', max_diff_gpu));
end
end

function check(cond, msg)
if ~cond
    error('tests:fail', '%s', msg);
end


end
