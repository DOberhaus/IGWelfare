%% TEST_ALL16_SHOCKS_AND_DOC3.M
% Quick CPU sanity test across all 9 modes of Apply_Coalition_2024_Shocks,
% Arts/Civic gearing symmetry, and the TP 26/01 NDC branch ledger.

Modes = {'reanchor_2023'; 'austerity_landlord_only'; 'pro_growth_only'; ...
    'coalition_13_shocks'; 'rates_cap_3_waters'; 'arts_and_civic_cuts'; ...
    'all_but_ndc'; 'ndc'; 'full_16_shocks'};
nM    = numel(Modes);

% Minimal mock Params & Markov pi_z for fast pre-VFI parameter & diagnostic audit
P0 = struct();
pi0 = struct();
Regs = {'Rural', 'Small', 'Large', 'Auckland'};
for r = 1:4
    pi0.(['HH_', Regs{r}]) = repmat([0.08, 0.14, 0.36, 0.26, 0.16], 5, 1);
end

[P_base, pi_base, M_base] = Apply_Coalition_2024_Shocks(P0, pi0, 'reanchor_2023');

Debt_GDP = zeros(nM, 1);
Q_Akl    = zeros(nM, 1);
Ups_Lge  = zeros(nM, 1);
Zh_Lge   = zeros(nM, 1);
Ebar_Rur = zeros(nM, 1);
Coh_St   = zeros(nM, 1);
TI_CPI   = zeros(nM, 1);

for m = 1:nM
    if m == 1
        Pm = P_base; Mm = M_base;
    else
        [Pm, ~, Mm] = Apply_Coalition_2024_Shocks(P_base, pi_base, Modes{m});
    end
    Debt_GDP(m) = 100 * Pm.Debt_to_GDP_Init;
    Q_Akl(m)    = Pm.Q_reg.HH_Auckland;
    Ups_Lge(m)  = 100 * Pm.upsilon_h_reg.HH_Large;
    Zh_Lge(m)   = Pm.z_f_grid.Firm_Large(2);
    Ebar_Rur(m) = Pm.ebar_energy.HH_Rural;
    Coh_St(m)   = Mm.Social_Cohesion_St;
    TI_CPI(m)   = Mm.TI_Social_Credit_CPI;
end

T_Check = table(Modes, round(Debt_GDP,2), round(Q_Akl,3), round(Ups_Lge,3), ...
    round(Zh_Lge,4), round(Ebar_Rur,4), round(Coh_St,2), round(TI_CPI,2), ...
    'VariableNames', {'Mode', 'Debt_PctGDP', 'Q_Auckland', 'Ups_Large_Pct', ...
    'Zh_Large', 'Ebar_Rural', 'Cohesion_St', 'TI_CPI'});
disp('=== 9-MODE PARAMETER & DIAGNOSTIC ISOLATION CHECK ===');
disp(T_Check);

disp('=== SHOCK #15 ARTS & CIVIC GEARING SYMMETRY CHECK ===');
Verify_ArtsCivic_GearingSymmetry;

disp('=== SHOCK #16 PARIS NDC LEDGER CHECK (2% SRTP vs 8% HURDLE) ===');
Out_NDC = Evaluate_NDC_Branch_Ledger();