function Cache = Precompute_HH_StationaryCache(Policy, n_d, n_a, n_z, N_j, d_grid, a_grid, pi_z, Params, simoptions, Regions)
% Precomputes Tan-improvement sparse transition operators {GammaT_j} once per HH region
% so intergenerational fixed-point iterations skip StationaryDist_MixHorz_PType completely.

N_reg = length(Regions);
Cache = struct();
use_gpu = (exist('OCTAVE_VERSION', 'builtin') == 0) ...
    && (exist('gpuDeviceCount', 'file') ~= 0) && (gpuDeviceCount > 0);
if use_gpu
    to_dev = @(x) gpuArray(x);
else
    to_dev = @(x) x;
end

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
    Pol  = reshape(to_dev(Pol_raw), [size(Pol_raw, 1), N_a, N_z, J]);
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
        d_g     = to_dev(d_grid.(hh_type));
        a2_g    = to_dev(a_grid.(hh_type)(sum(n_a1)+1:end));
        apFn    = simoptions.aprimeFn.(hh_type);
        fn_args = getAnonymousFnInputNames(apFn);
        apParamNames = fn_args(3:end); % after (ic, theta_c)
        which_d = length(n_d_vec);

        II_base = repmat((1:(N_a * N_z))', 2, 1);

        if ~use_gpu
            % Precompute static CPU grids once across all J-1 cohorts
            if which_d == 1
                d_sub = d_g(1:n_d_vec(1));
            else
                d_sub = d_g(sum(n_d_vec(1:which_d-1))+1 : sum(n_d_vec(1:which_d)));
            end
            a2_col      = a2_g(:);
            a2_vals     = repelem(a2_col, N_a1, 1);       % [N_a x 1]
            a2_griddiff = a2_col(2:end) - a2_col(1:end-1);
        end

        for jj = 1:(J - 1)
            apParamsVec = CreateVectorFromParams(Params_reg, apParamNames, jj);
            if use_gpu
                [apIdx, apProb] = CreateaprimePolicyExperienceAsset( ...
                    Pol(:,:,:,jj), apFn, which_d, n_d_vec, n_a1, n_a2, N_z, d_g, a2_g, apParamsVec);
            else
                [apIdx, apProb] = local_cpu_expasset_policy( ...
                    Pol(:,:,:,jj), apFn, which_d, N_a, n_a2, N_z, d_sub, a2_col, a2_vals, a2_griddiff, apParamsVec);
            end

            a1p = shiftdim(Pol(l_d+1,:,:,jj), 1) + n_a_vec(1) * (shiftdim(Pol(l_d+2,:,:,jj), 1) - 1);
            idx_lo = gather(a1p + N_a1 * (apIdx - 1) + to_dev(z_offset));
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
            rows = double(gather(ap + to_dev(z_offset)));
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


function [apIdx, apProb] = local_cpu_expasset_policy( ...
    Pol_jj, apFn, which_d, N_a, n_a2, N_z, d_sub, a2_col, a2_vals, a2_griddiff, apParamsVec)
% Exact 0-ULP CPU equivalent of CreateaprimePolicyExperienceAsset (l_dexp=1, l_a2=1)
ParamCell = num2cell(apParamsVec(:)');
d_vals    = reshape(d_sub(Pol_jj(which_d, :, :)), [N_a, N_z]);
ap_mat    = apFn(d_vals, a2_vals, ParamCell{:});          % [N_a x N_z] implicit expansion
ap_vec    = ap_mat(:);                                    % [N_a*N_z x 1]

[~, upIdx] = max(a2_col > ap_vec', [], 1);                % first grid node strictly > ap_vec
loIdx      = max(1, upIdx(:) - 1);

offBottom = (ap_vec <= a2_col(1));
offTop    = (ap_vec >= a2_col(end));
loIdx(offBottom) = 1;
loIdx(offTop)    = n_a2 - 1;

prob = 1.0 - (ap_vec - a2_col(loIdx)) ./ a2_griddiff(loIdx);
prob(offBottom) = 1.0;
prob(offTop)    = 0.0;

apIdx  = reshape(loIdx, [N_a, N_z]);
apProb = reshape(prob,  [N_a, N_z]);


end
