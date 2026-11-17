function Cache = Precompute_HH_StationaryCache(Policy, n_d, n_a, n_z, N_j, d_grid, a_grid, pi_z, Params, simoptions, Regions)
% Precomputes Tan-improvement sparse transition operators {GammaT_j} once per HH region
% so intergenerational fixed-point iterations skip StationaryDist_MixHorz_PType completely.

N_reg = length(Regions);
Cache = struct();

for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    Pol_raw = Policy.(hh_type);
    n_d_vec = n_d.(hh_type);
    n_a_vec = n_a.(hh_type);
    N_z     = prod(n_z.(hh_type));
    J       = N_j.(hh_type);
    is_exp  = isfield(simoptions, 'experienceasset') && isfield(simoptions.experienceasset, hh_type) ...
        && simoptions.experienceasset.(hh_type) == 1;

    l_d  = length(n_d_vec);
    N_a  = prod(n_a_vec);
    Pol  = reshape(gpuArray(Pol_raw), [size(Pol_raw, 1), N_a, N_z, J]);
    pi_z_cpu = double(gather(pi_z.(hh_type)));

    % Unpack region-specific Parameters exactly as StationaryDist_MixHorz_PType does
    Params_reg = Params;
    fnames = fieldnames(Params);
    for kf = 1:length(fnames)
        val = Params.(fnames{kf});
        if isstruct(val) && isfield(val, hh_type)
            Params_reg.(fnames{kf}) = val.(hh_type);
        end
    end

    GammaT = cell(J - 1, 1);
    z_offset = N_a * (0:(N_z - 1)); % [1 x N_z] Tan improvement z-index offset

    if is_exp
        n_a1    = n_a_vec(1:end-1);
        n_a2    = n_a_vec(end);
        N_a1    = prod(n_a1);
        d_g     = gpuArray(d_grid.(hh_type));
        a2_g    = gpuArray(a_grid.(hh_type)(sum(n_a1)+1:end));
        apFn    = simoptions.aprimeFn.(hh_type);
        fn_args = getAnonymousFnInputNames(apFn);
        apParamNames = fn_args(3:end); % after (ic, theta_c)
        which_d = length(n_d_vec);

        II_base = repmat((1:(N_a * N_z))', 2, 1);

        for jj = 1:(J - 1)
            apParamsVec = CreateVectorFromParams(Params_reg, apParamNames, jj);
            [apIdx, apProb] = CreateaprimePolicyExperienceAsset( ...
                Pol(:,:,:,jj), apFn, which_d, n_d_vec, n_a1, n_a2, N_z, d_g, a2_g, apParamsVec);

            a1p = shiftdim(Pol(l_d+1,:,:,jj), 1) + n_a_vec(1) * (shiftdim(Pol(l_d+2,:,:,jj), 1) - 1);
            idx_lo = gather(a1p + N_a1 * (apIdx - 1) + gpuArray(z_offset));
            idx_hi = idx_lo + N_a1;
            p_lo   = double(gather(apProb));

            rows = [idx_lo(:); idx_hi(:)];
            vals = [p_lo(:); 1.0 - p_lo(:)];
            GammaT{jj} = sparse(rows, II_base, vals, N_a * N_z, N_a * N_z);
        end
    else
        % 4D Compact standard endogenous state (n_a = [n_a1, n_h])
        II_base = (1:(N_a * N_z))';
        JJ_ones = ones(N_a * N_z, 1);
        for jj = 1:(J - 1)
            ap = shiftdim(Pol(l_d+1,:,:,jj), 1) + n_a_vec(1) * (shiftdim(Pol(l_d+2,:,:,jj), 1) - 1);
            rows = double(gather(ap + gpuArray(z_offset)));
            GammaT{jj} = sparse(rows(:), II_base, JJ_ones, N_a * N_z, N_a * N_z);
        end
    end

    Cache.(hh_type).GammaT   = GammaT;
    Cache.(hh_type).pi_z     = pi_z_cpu;
    Cache.(hh_type).N_a      = N_a;
    Cache.(hh_type).N_z      = N_z;
    Cache.(hh_type).n_a_vec  = n_a_vec;
    Cache.(hh_type).J        = J;
    Cache.(hh_type).mewj     = reshape(double(gather(Params_reg.mewj)), 1, J);
end


end
