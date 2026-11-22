function T_Fiscal = Build_Custom_Table14_Fiscal_CSV(Phase_Ledgers, Phase_Codes)
%% BUILD_CUSTOM_TABLE14_FISCAL_CSV
% Builds the 29-Node, 6-Gate Monetary & 4-Lane Fiscal Decomposition Table (Solution 1):
%   - Gates 1..4 (Nodes 1..16): Childhood & Age-20 Launch
%   - Gate 5 (Nodes 17..21):    Prime Career & Enterprise Sorting (Adversity, Core, z_l Rent, z_h Builder, Abroad)
%   - Gate 6 (Nodes 22..29):    Annualized Adult Fiscal Ledger (Exits 1, 2, 4, Infra/Super, GST/Cap/Estate, PAYE, Exit 3, Abroad)
N_p = numel(Phase_Ledgers);

Gate_Labels = { ...
    'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
    'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
    'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
    'Gate5_J8_11_CareerSorting';     'Gate5_J8_11_CareerSorting';     'Gate5_J8_11_CareerSorting';     'Gate5_J8_11_CareerSorting';     'Gate5_J8_11_CareerSorting'; ...
    'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger'; ...
    'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger'};

Node_Names = { ...
    '1_Material_And_Severe_Hardship';      '2_Residual_AHC_Paper_And_Whanau';     '3_Universal_Birth_Benefit';           '4_Private_Birth_OutOfPocket'; ...
    '5_ECE_Corner_Benefit_Need';           '6_Public_ECE_Wraparound';             '7_High_Intensity_Public_ECE';         '8_Private_Parental_ECE_CashTime'; ...
    '9_HH_Unemp_And_Truancy_Remed';        '10_Psychosocial_CAMHS_ACC_ISSC';      '11_Public_Secondary_Schooling';       '12_Montessori_Tuakana_Public';        '13_Private_Adol_Commit_CashTime'; ...
    '14_Struggling_Tier_h1_h2_Launch';     '15_Core_Skill_Tier_h3_h5_Launch';     '16_Thriving_Tier_h6_h7_Launch'; ...
    '17_Career_Chronic_Adversity_Trap';    '18_Career_Domestic_Core_Workforce';   '19_Career_Passive_Land_Rent_zl';      '20_Career_Productive_Builders_zh';    '21_Career_Emigrated_Abroad'; ...
    '22_Fiscal_Exit1_State_Care_Legacy';   '23_Fiscal_Exit2_Avoidable_Hosp_CAMHS';'24_Fiscal_Exit3_LowerSkill_LostTax';  '25_Fiscal_Exit4_Benefit_LOPE_Justice'; ...
    '26_Fiscal_Infra_Health_NZSuper';      '27_Fiscal_GST_Cap_Estate_Tax';        '28_Fiscal_WorkingAge_PAYE_Tax';       '29_Fiscal_Abroad_BrainDrain_LostTax'};

T_Fiscal = table(Gate_Labels, Node_Names, 'VariableNames', {'Gate', 'Node_Name'});
Flow_Mat = zeros(29, N_p);

for p = 1:N_p
    L = Phase_Ledgers{p};
    c = Phase_Codes{p};

    Pop_29 = 100 * [ ...
        L.Pop_S1_Birth(:); ...
        L.Pop_S2_ECE_4Node(:); ...
        L.Pop_S3_Adol_5Node(:); ...
        L.Pop_S4_Skill(:); ...
        L.Pop_S5_Career(:); ...
        ones(8, 1)];

    Flow_29 = [ ...
        L.S1_Birth_kNZD(:); ...
        L.S2_ECE_4Node_kNZD(:); ...
        L.S3_Adol_5Node_kNZD(:); ...
        L.S4_Skill_kNZD(:); ...
        L.S5_Career_kNZD(:); ...
        L.S6_Fiscal_kNZD(:)];

    Cond_29 = Flow_29 ./ max(1e-9, Pop_29 / 100);
    Cond_29(Pop_29 == 0) = 0;   % guard: a zero-population node must not print Flow x 1e9
    Flow_Mat(:, p) = Flow_29;

    LaneA = zeros(29, 1); LaneB = zeros(29, 1); LaneC = zeros(29, 1); LaneD = zeros(29, 1);
    LaneD(1) = Flow_29(1);
    LaneD(2) = Flow_29(2);
    if isfield(L, 'Whanau_And_Landlord_G1_kNZD'), LaneB(2) = L.Whanau_And_Landlord_G1_kNZD(1); end
    LaneC(3) = Flow_29(3);
    LaneA(4) = 0.63 * Flow_29(4); LaneB(4) = 0.37 * Flow_29(4);

    LaneD(5) = Flow_29(5); LaneC(6:7) = Flow_29(6:7);
    LaneA(8) = 0.60 * Flow_29(8); LaneB(8) = 0.40 * Flow_29(8);

    LaneD(9:10) = Flow_29(9:10); LaneC(11:12) = Flow_29(11:12);
    LaneA(13) = 0.62 * Flow_29(13); LaneB(13) = 0.38 * Flow_29(13);

    LaneD(14) = 0.82 * Flow_29(14); LaneC(14) = 0.18 * Flow_29(14);
    LaneA(15) = 0.29 * Flow_29(15); LaneB(15) = 0.12 * Flow_29(15); LaneC(15) = 0.53 * Flow_29(15); LaneD(15) = 0.06 * Flow_29(15);
    LaneA(16) = 0.37 * Flow_29(16); LaneB(16) = 0.13 * Flow_29(16); LaneC(16) = 0.50 * Flow_29(16);

    % Gate 5 Career Strata (17..21) & Gate 6 Fiscal Accounts (22..29: Exits 1..4 = 22..25, Infra = 26, GST = 27, PAYE = 28, Abroad = 29)
    LaneD([17, 19, 21, 22, 23, 24, 25, 29]) = Flow_29([17, 19, 21, 22, 23, 24, 25, 29]);
    LaneC([18, 20, 26, 27, 28])             = Flow_29([18, 20, 26, 27, 28]);

    T_Fiscal.(sprintf('%s_Pop_Pct', c))               = round(Pop_29, 2);
    T_Fiscal.(sprintf('%s_CohortFlow_kNZD', c))       = round(Flow_29, 2);
    T_Fiscal.(sprintf('%s_CondPerChild_kNZD', c))     = round(Cond_29, 2);
    T_Fiscal.(sprintf('%s_LaneA_PrivCash_kNZD', c))   = round(LaneA, 2);
    T_Fiscal.(sprintf('%s_LaneB_WhanauTime_kNZD', c)) = round(LaneB, 2);
    T_Fiscal.(sprintf('%s_LaneC_PubDev_kNZD', c))     = round(LaneC, 2);
    T_Fiscal.(sprintf('%s_LaneD_RemedRent_kNZD', c))  = round(LaneD, 2);
end

if N_p == 2
    T_Fiscal.Reform_Delta_Flow_kNZD = round(Flow_Mat(:, 2) - Flow_Mat(:, 1), 2);
elseif N_p >= 3
    for p = 2:N_p
        d_col = sprintf('Delta_%s_vs_%s_kNZD', Phase_Codes{p}, Phase_Codes{p-1});
        T_Fiscal.(d_col) = round(Flow_Mat(:, p) - Flow_Mat(:, p-1), 2);
    end
    cum_col = sprintf('Cumul_%s_vs_%s_kNZD', Phase_Codes{N_p}, Phase_Codes{1});
    T_Fiscal.(cum_col) = round(Flow_Mat(:, N_p) - Flow_Mat(:, 1), 2);
end
end
