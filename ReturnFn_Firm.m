function F = ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt, ...
    mu_monop_reg, rho_olig_reg, rho_farm_reg, lambda_col_mult)

%% INFINITE-HORIZON FIRM / ENTREPRENEUR RETURN FUNCTION (Guvenen et al. Source 6 + Duopoly/Farm-to-Marae)
% Solves static capital/labor demand with collateral constraint k <= lambda * a
% and dynamic internal equity accumulation a' under wealth tax (tau_a) vs profit tax (tau_k).

F = -Inf;

% 1. Marginal return to capital for firm with productivity z after optimizing out labor n
%    Upstream monopsony markdown mu_monop_reg in (0, 1] depresses rural/provincial operating revenue in SS0:
z_eff       = mu_monop_reg * z;
marg_prod_k = alpha_k * (((1 - alpha_k) / w_reg)^((1 - alpha_k) / alpha_k)) * z_eff + rho_farm_reg;
user_cost_k = r + delta_k;

% 2. Collateral-constrained excess return pi(z) vs. passive oligopoly rent extraction (Source 6, Eq 7):
if marg_prod_k > user_cost_k
    % High-productivity operating firm (z_h) borrows up to bankable collateral limit
    % (relaxed by Farm-to-School / Farm-to-Marae forward contracts via lambda_col_mult):
    pi_excess = (marg_prod_k - user_cost_k) * (lambda_col * lambda_col_mult);
    olig_rent = 0;
else
    % Low-productivity / passive incumbent firm (z_l) does not borrow for new production;
    % lends net worth at rate r and captures extracted retail oligopoly rent yield rho_olig_reg:
    pi_excess = 0;
    olig_rent = rho_olig_reg;
end

% 3. Gross-of-saving return R(z) under book-value wealth tax (tau_a) and capital tax (tau_k)
%    (Guvenen et al., Source 6, Eq 9, over dt-year period):
R_z = (1 - tau_a)^dt + (1 - tau_k) * (r + olig_rent + pi_excess);

% Dividend / entrepreneurial payout c_f = R(z)*a - a' (Source 6, Eq 8 & 84)
div_payout = R_z * a - aprime;

if div_payout <= 0
    return;
end

% Log objective over dividend/entrepreneurial payout (Source 6, Eq 1 & 84)
F = log(div_payout);


end
