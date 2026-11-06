function F = ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt)
%% INFINITE-HORIZON FIRM / ENTREPRENEUR RETURN FUNCTION (Guvenen et al. Source 6)
% Solves static capital/labor demand with collateral constraint k <= lambda * a
% and dynamic internal equity accumulation a' under wealth tax (tau_a) vs profit tax (tau_k).

F = -Inf;

% Marginal return to capital for firm with productivity z after optimizing out labor n:
% From Guvenen et al. (Source 6, Eq 7), augmented for NZ NDC trade & ETS channels:
reform_prog = min(1.0, max(0.0, tau_a / 0.015)); % 0 in SS0 (status quo), 1 in SS1/SS2 reform
ndc_trade_z = z * (1.0 - 0.045 * (1.0 - reform_prog) + 0.035 * reform_prog); % CBAM drag in SS0 -> Clean-Green lift in SS1/SS2
marg_prod_k = alpha_k * (((1 - alpha_k) / w_reg)^((1 - alpha_k) / alpha_k)) * ndc_trade_z;
user_cost_k = r + delta_k;

% Collateral-constrained excess return pi(z) (Source 6, Eq 7):
if marg_prod_k > user_cost_k
    % High-productivity operating firm (z_h) borrows up to collateral limit k = lambda_col * a
    pi_excess = (marg_prod_k - user_cost_k) * lambda_col;
else
    % Low-productivity passive land/pine portfolio (z_l) lends at r; receives untaxed exotic
    % pine ETS / dairy land-rent wedge in SS0 (reform_prog == 0), eliminated in SS1/SS2:
    pi_excess = 0.008 * (1.0 - reform_prog) * dt;
end

% Gross-of-saving return R(z) under book-value wealth tax (tau_a) and capital tax (tau_k)
% (Guvenen et al., Source 6, Eq 9, compounded over dt-year period):
R_z = (1 - tau_a)^dt + (1 - tau_k) * (r + pi_excess);

% Dividend / entrepreneurial payout c_f = R(z)*a - a' (Source 6, Eq 8 & 84)
div_payout = R_z * a - aprime;

if div_payout <= 0
    return;
end

% Log objective over dividend/entrepreneurial payout (Source 6, Eq 1 & 84)
F = log(div_payout);


end
