function F = ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt)
%% INFINITE-HORIZON FIRM / ENTREPRENEUR RETURN FUNCTION (Guvenen et al. Source 6)
% Solves static capital/labor demand with collateral constraint k <= lambda * a
% and dynamic internal equity accumulation a' under wealth tax (tau_a) vs profit tax (tau_k).

F = -Inf;

% Marginal return to capital for firm with productivity z after optimizing out labor n:
% From Guvenen et al. (Source 6, Eq 7):
marg_prod_k = alpha_k * (((1 - alpha_k) ./ w_reg) .^ ((1 - alpha_k) ./ alpha_k)) .* z;
user_cost_k = r + delta_k;

% Collateral-constrained excess return pi(z) (Source 6, Eq 7):
    % High-productivity firm (z_h) borrows up to collateral limit k = lambda_col * a
    % Low-productivity firm (z_l) does not borrow/produce; lends net worth at rate r
is_operating = double(marg_prod_k > user_cost_k);
pi_excess    = is_operating .* ((marg_prod_k - user_cost_k) * lambda_col) + (1.0 - is_operating) .* (0);

% Gross-of-saving return R(z) under book-value wealth tax (tau_a) and capital tax (tau_k)
% (Guvenen et al., Source 6, Eq 9, compounded over dt-year period):
R_z = (1 - tau_a) .^ dt + (1 - tau_k) * (r + pi_excess);

% Dividend / entrepreneurial payout c_f = R(z)*a - a' (Source 6, Eq 8 & 84)
div_payout = R_z .* a - aprime;

% Log objective over dividend/entrepreneurial payout (Source 6, Eq 1 & 84)
F = log(max(div_payout, realmin)) + log(double(div_payout > 0));


end
