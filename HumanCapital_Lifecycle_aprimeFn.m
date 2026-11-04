function thetac_prime = HumanCapital_Lifecycle_aprimeFn(i_c, thetac, agej, ...
    phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
    phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
    gbar_ece, h_par_mean, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_reg, Q_reg_base, K_whanau, Jr, dt)
% HUMANCAPITAL_LIFECYCLE_APRIMEFN
% Parameterized Two-Stage CES Law of Motion for Child Skill (theta_c) with:
%   - Two-Tier Early Vulnerability on Convex d_grid_ic (Node 1 Acute ic=0 vs Node 2 Residual AHC Squeeze)
%   - Marilyn Waring Alloparental Whanau Care Buffer (K_whanau) & Sandwich-Generation Reversal
%   - Stage-2 Adolescent Psychosocial & Relational Morbidity Hazard (lambda_psy: GUiNZ, Youth19, KiVa, ACC ISSC)
%   - State-Contingent Kaiako Supply Deflator & 38% Clinical Trauma Persistence Floor.
% Pure scalar arithmetic for gpuArray/arrayfun compatibility.

thetac_safe = max(thetac, 1e-4);
hp_safe     = max(h_par_mean, 1e-4);

% 1. PRICE-MANIFOLD CONDITIONED KAIAKO WORKFORCE SUPPLY DEFLATOR:
%    Combines cross-regional metropolitan rent drag `kaiako_spatial` and
%    intertemporal reform housing cooling `kaiako_cooling`:
kaiako_spatial = (1.65 / max(0.80, Q_reg)) ^ 0.34;
kaiako_cooling = (max(0.50, Q_reg_base) / max(0.50, Q_reg)) ^ 0.35;
kaiako_prod    = kaiako_spatial * kaiako_cooling;

% 2. ACTIVE MONTESSORI / TUAKANA-TEINA / GRAEME DINGLE MENTORING INTENSITY:
G_ece2_real = G_ece_stage2 * kaiako_prod;
M_mentor    = min(1.0, max(0.0, 0.173 + 20.0 * (G_ece2_real - 0.065)));

% 3. TWO-TIER VULNERABILITY ON CONVEX d_grid_ic & MARILYN WARING WHANAU CARE BUFFER:
%    - is_acute_corner: Node 1 Severe Material Hardship (DEP-17 9+, i_c == 0)
%    - is_ahc_squeeze : Node 2 Residual AHC Squeeze & Paper Support (first interior rung i_c = 0.0203)
super_age_yrs    = 20 + (Jr - 1) * dt;
is_super_cut     = double(super_age_yrs > 65.5);
is_acute_corner  = double(i_c < 0.005);
is_ahc_squeeze   = double((i_c >= 0.005) && (i_c < 0.035));
is_corner_stress = is_acute_corner + 0.55 * is_ahc_squeeze;

psi_sandwich = 0.28;
K_whanau_net = K_whanau - psi_sandwich * is_super_cut * is_corner_stress;
K_whanau_pos = max(0.0, K_whanau_net);

% Marilyn Waring (1988) unpaid alloparental whanau care substitution:
% Particularly critical for Node 2 (is_ahc_squeeze) families whose paper transfers are captured by rent Q_reg
waring_whanau_s1 = (0.110 + 0.035 * is_ahc_squeeze) * K_whanau_pos;

if (agej >= j_s1_start) && (agej <= j_s1_end)
    % =====================================================================
    % STAGE 1: FIRST 2000 DAYS (Ages 0-5, phi1_ces = 0.35 > 0)
    % =====================================================================
    kappa_down     = 0.15;
    G_ece1_eff     = (G_ece_stage1 * kaiako_prod) * (1.0 + kappa_down * M_mentor) ...
        + waring_whanau_s1;
    inv_raw1       = max(0.35 * i_c + G_ece1_eff + gbar_ece, 1e-4);
    inv_tot1       = 0.52 + 1.15 * inv_raw1;
    inside1        = gamma1_self * (thetac_safe ^ phi1_ces) ...
        + gamma1_inv  * (inv_tot1    ^ phi1_ces) ...
        + gamma1_par  * (hp_safe     ^ phi1_ces);
    thetac_target1 = inside1 ^ (1.0 / phi1_ces);

    w1 = 1.0 / max(1.0, n_stage1_steps);
    thetac_prime = (1.0 - w1) * thetac_safe + w1 * thetac_target1;

elseif (agej >= j_s2_start) && (agej <= j_s2_end)
    % =====================================================================
    % STAGE 2: SCHOOL YEARS & ADOLESCENCE (Ages 6-17, phi2_ces = -0.95 < 0)
    % =====================================================================
    w2 = 1.0 / max(1.0, n_stage2_steps);

    % Non-fungible Whanau Trust Gating:
    M_trust_gated = M_mentor * (0.45 + 0.55 * min(1.0, K_whanau_pos / 0.35));

    % 1. EXPLICIT UNBANKED SKILL GAIN FADE-OUT (Bailey et al. 2017; Cunha et al. 2010):
    delta_theta_fade = 0.14 * w2;
    theta_base       = 0.78;
    thetac_retained  = max(1e-4, thetac_safe - delta_theta_fade * (1.0 - M_trust_gated) * max(0.0, thetac_safe - theta_base));

    % 2. STAGE-2 CES SKILL PRODUCTION (Harmonic-Mean Bottleneck phi2_ces = -0.95 < 0):
    inv_raw2    = max(0.35 * i_c + G_ece2_real + gbar_ece + 0.105 * K_whanau_pos, 1e-4);
    inv_tot2    = 0.66 + 1.10 * inv_raw2;
    inside2     = gamma2_self * (thetac_retained ^ phi2_ces) ...
        + gamma2_inv  * (inv_tot2        ^ phi2_ces) ...
        + gamma2_par  * (hp_safe         ^ phi2_ces);
    thetac_ces2 = inside2 ^ (1.0 / phi2_ces);

    % 3. COMPOUNDED HOUSEHOLD & ADOLESCENT PSYCHOSOCIAL MORBIDITY SHOCK (Document 1B / 2A Section 3.3):
    %    - lambda_psy: Cross-income relational/digital/trauma hazard (GUiNZ 52.4% depressive escalation,
    %      Youth19 23% clinical depression, PISA/KiVa 32-35% bullying, ACC ISSC sensitive claims).
    %      Inoculated by KiVa/Tuakana peer norms (M_trust_gated) and Planet Youth family time (K_whanau_pos).
    %    - Retains a 38% clinical persistence floor (0.38 * 0.22 = 0.0836) for acute clinical trauma (CAMHS/ACC).
    lambda_psy_raw  = 0.22 * (1.0 - 0.52 * M_trust_gated) * (1.0 - 0.35 * min(1.0, K_whanau_pos / 0.38));
    lambda_psy      = max(0.22 * 0.38, lambda_psy_raw);

    % Multiplicative compounding when psychosocial shock intersects with household corner/squeeze stress:
    compounded_load = is_corner_stress + lambda_psy * (1.0 + 0.65 * is_corner_stress);
    unbuffered_mult = (1.0 - 0.55 * K_whanau_net) * (1.0 - 0.80 * M_trust_gated);
    insul_mult      = max(0.38 * (0.35 * is_acute_corner + lambda_psy), max(0.0, unbuffered_mult));

    psi_unemp_step  = 0.033 * compounded_load * insul_mult;
    kappa_up_step   = 0.036 * max(0.0, M_trust_gated - 0.173);
    Psi_adolescent  = -psi_unemp_step + kappa_up_step;

    thetac_target2 = thetac_ces2 * exp(Psi_adolescent);
    thetac_prime   = (1.0 - w2) * thetac_retained + w2 * thetac_target2;
else
    thetac_prime = thetac;
end


end
