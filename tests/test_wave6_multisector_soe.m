function test_wave6_multisector_soe()
%% TEST_WAVE6_MULTISECTOR_SOE
% Regression gate for Wave 6 (Unified 5-Sector SOE, Exergy, Waring,
% Paris NDC, and Public-Asset Stewardship):
%   1. 5-Sector + Exergy/NDC profile schema, anti-double-counting & inheritance.
%   2. Outer-loop 5-sector exergy activation, internal S4A reactive->capacitating release & BoP NFA/Y.
%   3. Three-Tier Scorecard (Y_SNA vs Atkinson-Waring Y_AW with 79k FTE volunteers & -Y_rem anti-bads).
%   4. Public-Asset Stewardship Ledger (Crown cash mirage vs negative 2%/8% societal PV & buyback cliff).
%   5. Vectorized T_NDC_Path in Compute_TransitionPath_4Region & headless dashboard export.

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);
setup_igw_paths(true);

P0 = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 3));

%% 1. 5-SECTOR & EXERGY PROFILE LOADER CONTRACTS
S_Dun = Load_Sectoral_Exergy_Spec('NZ_Dunedin1972');
S_Gui = Load_Sectoral_Exergy_Spec('NZ_GUiNZ2009');
check(strcmp(S_Dun.Digest, S_Gui.Digest), 'NZ_GUiNZ2009 failed to inherit 5-sector spec digest');
check(numel(S_Dun.SubSector_Table.SubSector_ID) == 11 && height(S_Dun.MacroSector_Table) == 6, 'Expected 11 sub-lanes and 6 macro sectors');
check(abs(S_Dun.Civic_Volunteer_kFTE - 79.0) < 0.5, 'Civic volunteer base deviated from 79.0 kFTE JBWere benchmark');
check(S_Dun.Civic_Def_Share_Paid > 0.25 && S_Dun.Civic_Def_Share_Paid < 0.29, 'Sectors 4 & 5 paid workforce share outside 25%-29%');

%% 2. 5-SECTOR EXERGY, INTERNAL S4A LABOR RELEASE & DEFENCE FX ABSORPTION
figs0  = numel(findall(0, 'Type', 'figure'));
Eq_SS0 = Compute_5Sector_Exergy_Equilibrium(P0, 'SS0_LTFM');
Eq_Ref = Compute_5Sector_Exergy_Equilibrium(P0, 'Phase2_Reform');
Eq_Def0= Compute_5Sector_Exergy_Equilibrium(P0, 'SS0_Defence_3Pct');
Eq_DefR= Compute_5Sector_Exergy_Equilibrium(P0, 'Phase2_Defence_3Pct');

idx50 = find(Eq_Ref.Years == 2050, 1);
check(Eq_Ref.L_S4A_Released_kFTE(idx50) > 60.0 && Eq_Ref.L_S4A_Released_kFTE(end) > 95.0, ...
    'Expected >60k FTE internal S4A reactive labor release by 2050 and >95k FTE (>70%) by SS2');
check(Eq_Ref.Fossil_Import_BNZD_t(idx50) < 0.45 * Eq_SS0.Fossil_Import_BNZD_t(idx50), 'Electrification failed to cut fossil imports >55%');
check(Eq_DefR.NFA_to_GDP_t(end) > Eq_Def0.NFA_to_GDP_t(end) + 0.30, 'Exergy + S2 exports failed to stabilize NFA/Y under 3% Defence');
check(Eq_DefR.r_Sovereign_t(end) < Eq_Def0.r_Sovereign_t(end) - 0.008, 'Reform failed to compress sovereign spread under 3% Defence');

%% 3. THREE-TIER NATIONAL ACCOUNTS & PUBLIC-ASSET STEWARDSHIP LEDGERS (ZERO FIGURE LEAKS)
L_3T  = Compute_ThreeTier_NationalAccounts_Ledger(P0);
L_AS  = Compute_Public_Asset_Stewardship_Ledger(P0);
L_NDC = Compute_NDC_Compliance_Ledger(P0);
figs1 = numel(findall(0, 'Type', 'figure'));
check(figs1 == figs0, 'Pure Phase II ledgers leaked figure handles');

% Under reform, Atkinson-Waring Y_AW exceeds Y_SNA by more than under retrenchment (volunteer/care lift + anti-bads drop):
aw_gap_dom15 = L_3T.SummaryTable.Y_AtkinsonWaring_2050_BNZD(2) - L_3T.SummaryTable.Y_SNA_2050_BNZD(2);
aw_gap_ref   = L_3T.SummaryTable.Y_AtkinsonWaring_2050_BNZD(4) - L_3T.SummaryTable.Y_SNA_2050_BNZD(4);
check(aw_gap_ref > aw_gap_dom15 + 35.0, 'Atkinson-Waring vs SNA wedge failed to widen under Phase II reform');

% Public-Asset Privatization: positive Crown cash in Yrs 0-3, deeply negative 2% societal PV, massive opportunity loss vs turnaround:
check(L_AS.SummaryTable.Crown_Cash_Yr0to3_BNZD(2) > 30.0, 'Privatization Yr 0-3 Crown cash mirage expected > +30B');
check(L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(2) < -10.0, 'Privatization 2% societal PV expected < -10B');
check(L_AS.Opportunity_Loss_2pct_B > 65.0 && L_AS.Opportunity_Loss_8pct_B > 20.0, 'Stewardship opportunity loss unexpectedly small');
check(L_AS.Buyback_Cost_Yr10_BNZD > 75.0, 'Yr-10 buyback cost expected > NZD 75B on NZD 50B block');

% NDC compliance ledger:
check(L_NDC.SummaryTable.PV_Offshore_2pct_BNZD(2) < 0.30 * L_NDC.SummaryTable.PV_Offshore_2pct_BNZD(1), ...
    'Phase II exergy abatement failed to cut 2% PV offshore NDC cost by >70%');

%% 4. VECTORIZED T_NDC_PATH IN COMPUTE_TRANSITIONPATH_4REGION & HEADLESS DASHBOARD
T1_mock = array2table([2,2,2,3; 6,6,7,8; 12,14,15,17; 5,6,6,7; 13,13,14,15; 21,23,25,28], ...
    'VariableNames', {'Rural_CE_Pct','Small_CE_Pct','Large_CE_Pct','Auckland_CE_Pct'});
TP = Compute_TransitionPath_4Region(P0, struct(), T1_mock, struct('Phases', {struct('Code', {'SS0','SS1','SS2'})}));
check(isfield(TP, 'T_NDC_Path') && istable(TP.T_NDC_Path) && height(TP.T_NDC_Path) == TP.T_trans, ...
    'Compute_TransitionPath_4Region failed to populate T_NDC_Path');
check(TP.S_pine_path(end) < TP.S_pine_path(2) && TP.S_native_path(end) > TP.S_native_path(2), ...
    'Exotic pine saturation vs native taiao sink trajectory failed');

tmp_out = tempname;
mkdir(tmp_out);
old_ov  = getenv('IGW_OUTPUT_DIR');
cleanup = onCleanup(@() setenv('IGW_OUTPUT_DIR', old_ov));
setenv('IGW_OUTPUT_DIR', tmp_out);
old_vis = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');
Dash = Plot_Phase2_5Sector_Dashboard(P0);
close all;
set(0, 'DefaultFigureVisible', old_vis);
check(exist(Dash.Fig_Path, 'file') == 2, 'Plot_Phase2_5Sector_Dashboard failed to export PNG');

end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_wave6_multisector_soe: %s', msg);
end
end
