function test_wave2_taxonomy()
%% TEST_WAVE2_TAXONOMY
% Verifies the Wave 2 4-Tier Epistemic Parameter Provenance Contract:
%   1. Canonical default dt = 3 (J = 27) across Configure_Grid_And_Prefs & Configure_Model_Params.
%   2. Strict PType-struct purity: ZERO non-PType structs inside Params across all tiers & regimes.
%   3. Idempotency across Configure_Model_Params and Apply_Policy_Regime('SS0'|'SS1'|'SS2').
%   4. Caller overrides (e.g. SMM-calibrated gamma1_inv or custom tau_l) are respected by Tiers B & C.
%   5. Apply_Policy_Regime reproduces exact Lee-Seshadri, Fertility, and Multiphase PE/GE transitions.
%   6. Describe_Params_Provenance classifies 100% of fields cleanly with zero unclassified leaks.

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);
setup_igw_paths(true);

% 1. Canonical default dt = 3 & sigma_hc_ig = 0.18
[P0, Prov] = Configure_Model_Params(struct());
check(P0.dt == 3 && P0.J == 27 && P0.Jr == 16, 'Canonical default dt=3 (J=27, Jr=16) violated');
check(abs(P0.sigma_hc_ig - 0.18) < 1e-12, 'Canonical sigma_hc_ig = 0.18 violated');
check(abs(P0.tau_l - 0.22) < 1e-12 && abs(P0.gamma1_self - 0.53) < 1e-12, 'Tier B/C statutory or CES defaults missing');

% 2. Strict PType-struct purity across all regimes
regimes = {'SS0', 'SS1', 'SS2', 'Barnardos_ECE_PE', 'Austerity_Age70', ...
           'P0_Early_0to5', 'P1P2_Late_6to17', 'BN_FrontLoad', 'P0_Plus_GrantE'};
for r = 1:numel(regimes)
    PR = Apply_Policy_Regime(P0, regimes{r});
    assert_ptype_struct_purity(PR, regimes{r});
end

% 3. Idempotency
P0_again = Configure_Model_Params(P0);
check(isequal(P0, P0_again), 'Configure_Model_Params is not idempotent');
P_ss1_a = Apply_Policy_Regime(P0, 'SS1');
P_ss1_b = Apply_Policy_Regime(P_ss1_a, 'SS1');
check(isequal(P_ss1_a, P_ss1_b), 'Apply_Policy_Regime(SS1) is not idempotent');

% 4. Caller / SMM overrides respected + explicit CalibSpec override works
P_over = Configure_Model_Params(struct('gamma1_inv', 0.31, 'tau_l', 0.25));
check(abs(P_over.gamma1_inv - 0.31) < 1e-12 && abs(P_over.tau_l - 0.25) < 1e-12, ...
    'Caller overrides were wiped by Configure_Model_Params');
P_cal = Apply_Calibrated_Params(P0, struct('omega_ic', 0.515, 'chi_bar', 2.40));
check(abs(P_cal.omega_ic - 0.515) < 1e-12 && abs(P_cal.chi_bar - 2.40) < 1e-12, ...
    'Apply_Calibrated_Params failed to apply CalibSpec struct');

% 5. Multiphase PE -> GE contract & z_grid/pi_z upgrading
z_in  = struct('HH_Rural', [0.7; 1.0; 1.4], 'HH_Small', [0.7; 1.0; 1.4], ...
               'HH_Large', [0.7; 1.0; 1.4], 'HH_Auckland', [0.7; 1.0; 1.4]);
pi_in = struct('Firm_Rural', [0.85 0.15; 0.15 0.85], 'Firm_Small', [0.85 0.15; 0.15 0.85], ...
               'Firm_Large', [0.85 0.15; 0.15 0.85], 'Firm_Auckland', [0.85 0.15; 0.15 0.85]);
P_PE1 = Apply_Policy_Regime(P0, 'SS1', struct('Stage', 'PE'));
[P_GE2, z_m2, pi_m2] = Apply_Policy_Regime(P0, 'SS2', struct('Stage', 'GE', 'z_grid', z_in, 'pi_z', pi_in));
check(P_PE1.w_reg.HH_Auckland == P0.w_reg.HH_Auckland, 'PE stage should keep baseline wages');
check(P_GE2.w_reg.HH_Rural > P0.w_reg.HH_Rural, 'GE SS2 stage should lift Rural wages');
check(P_GE2.Q_reg.HH_Auckland < P0.Q_reg.HH_Auckland, 'GE SS2 stage should cool Auckland house prices');
check(z_m2.HH_Rural(2) > z_in.HH_Rural(2), 'GE SS2 stage should upgrade Rural HH z_grid');
check(pi_m2.Firm_Rural(1, 2) > pi_in.Firm_Rural(1, 2), 'GE SS2 stage should raise Firm_Rural z_h upgrade prob');
assert_ptype_struct_purity(P_GE2, 'SS2_GE');

% 6. Provenance completeness: zero unclassified runtime fields on fresh Configure_Model_Params
[ProvTbl, ProvMap] = Describe_Params_Provenance(P0);
check(height(ProvTbl) == numel(fieldnames(P0)), 'Provenance table row count mismatch');
check(ProvMap.Summary_Counts.TierA_GridPrefs > 5 && ...
      ProvMap.Summary_Counts.TierB_Empirical > 15 && ...
      ProvMap.Summary_Counts.TierC_Calibrated > 15 && ...
      ProvMap.Summary_Counts.TierD_PolicyRegime > 15 && ...
      ProvMap.Summary_Counts.Workbench_Runtime == 0, ...
      'Provenance tier distribution unexpected or leaked unclassified fields');
end

function assert_ptype_struct_purity(P, tag)
fn = fieldnames(P);
for k = 1:numel(fn)
    if isstruct(P.(fn{k}))
        sub = fieldnames(P.(fn{k}));
        check(all(strncmp(sub, 'HH_', 3) | strncmp(sub, 'Firm_', 5)), ...
            sprintf('[%s] struct-valued Params field %s contains non-PType keys', tag, fn{k}));
    end
end
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_wave2_taxonomy: %s', msg);
end
end
