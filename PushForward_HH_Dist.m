function StationaryDist = PushForward_HH_Dist(StationaryDist, jequaloneDist, Cache, Regions)
% Pushes jequaloneDist forward across all J ages using cached Tan operators
for r_idx = 1:length(Regions)
    hh_type = ['HH_', Regions{r_idx}];
    C       = Cache.(hh_type);
    DistKron = zeros(C.N_a * C.N_z, C.J);
    dist_jj  = reshape(double(gather(jequaloneDist.(hh_type))), [C.N_a * C.N_z, 1]);
    DistKron(:, 1) = dist_jj;

    for jj = 1:(C.J - 1)
        % Step 1 of Tan: sparse endogenous + experience-asset push (at most 2*N_a*N_z nnz)
        dist_mid = reshape(C.GammaT{jj} * dist_jj, [C.N_a, C.N_z]);
        % Step 2 of Tan: dense [N_a x N_z] * [N_z x N_z] BLAS GEMM
        dist_jj  = reshape(dist_mid * C.pi_z, [C.N_a * C.N_z, 1]);
        DistKron(:, jj + 1) = dist_jj;
    end

    DistKron = DistKron .* C.mewj;
    StationaryDist.(hh_type) = reshape(DistKron, [C.n_a_vec, C.N_z, C.J]);
end


end
