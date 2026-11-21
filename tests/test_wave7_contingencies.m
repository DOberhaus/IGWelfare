function test_wave7_contingencies()
%% TEST_WAVE7_CONTINGENCIES
% Regression gate for Wave 7 (Document 1F Five Citizens' Assembly Clearinghouse
% & 5-Risk State-Contingent Governance Stress-Test):
%   1. Assembly contract schema, 15-contract completeness & profile inheritance.
%   2. Evaluate_Contingency_Gates Sustain_Steps persistence (rejects 1-step transient spikes).
%   3. Clearinghouse reconciliation (15/15 Unified pass vs Day-1 Grant / Cherry-Pick / 50% Split breaches).
%   4. 5-Risk + Polycrisis stress-test: early unlock on-track (< Yr 25), automatic deferral under
%      stock-formation / polycrisis shocks (> Yr 25), lower Yr-60 debt, and positive resilience gains.
%   5. Zero figure leaks in pure ledger & clean headless 4-panel PNG export.

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);
setup_igw_paths(true);

P0 = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 3));

%% 1. ASSEMBLY COMPACT LOADER & INHERITANCE
C_Dun = Load_Assembly_Compact('NZ_Dunedin1972');
C_Gui = Load_Assembly_Compact('NZ_GUiNZ2009');
check(strcmp(C_Dun.Digest, C_Gui.Digest), 'NZ_GUiNZ2009 failed to inherit citizens_assembly_contracts digest');
check(C_Dun.N_Contracts == 15, 'Expected 15 bilateral assembly contracts');

%% 2. EVALUATE_CONTINGENCY_GATES SUSTAIN_STEPS PERSISTENCE CHECK
Spec_Test = Load_Contingency_Policy('NZ_Dunedin1972', 'contingent_armada');
Spec_Test.Gates{2}.Sustain_Steps = 2;
yrs_t = (0:1:30)';
SM_Blip = struct( ...
    'ECE_Active_Share_Nat',    ones(size(yrs_t)), ...
    'Fiscal_Drawdown_GDP_Pct', zeros(size(yrs_t)), ...
    'Struggling_Share_Nat',    0.20 * ones(size(yrs_t)), ...
    'Youth_Emig_Cut_Share',    0.50 * ones(size(yrs_t)), ...
    'Booked_Fiscal_Ratio_2pct',2.00 * ones(size(yrs_t)));
% Single-year transient dip at Year 16 (rebounds at Year 17), then sustained pass from Year 22+:
SM_Blip.Struggling_Share_Nat(yrs_t == 16) = 0.10;
SM_Blip.Struggling_Share_Nat(yrs_t >= 22) = 0.10;
GE_Blip = Evaluate_Contingency_Gates(Spec_Test, yrs_t, SM_Blip);
check(GE_Blip.SS2_Unlock_Year == 23, sprintf('Expected Sustain_Steps=2 to ignore Yr-16 blip and unlock at Yr 23, got %g', GE_Blip.SS2_Unlock_Year));

%% 3. PURE CLEARINGHOUSE & 5-RISK STRESS-TEST INVARIANTS (ZERO FIGURE LEAKS)
figs0 = numel(findall(0, 'Type', 'figure'));
Out7  = Compute_Assembly_Clearinghouse_Ledger(P0);
figs1 = numel(findall(0, 'Type', 'figure'));
check(figs1 == figs0, 'Compute_Assembly_Clearinghouse_Ledger leaked figure handles');

CH = Out7.ClearinghouseTable;
check(CH.Contracts_Passed(1) == 15 && CH.Contracts_Breached(1) == 0, 'Unified 5-Assembly Compact failed 15/15 clearance');
check(CH.Contracts_Breached(2) >= 6, 'Day-1 unsequenced YouthGrant failed to flag skill/capital-at-risk breaches');
check(CH.Contracts_Breached(3) >= 12, 'Cherry-picked no-prevention regime failed to void citizen mandate');
check(CH.Contracts_Breached(4) >= 12, 'Partisan 50% split-the-difference failed to expose threshold starvation');

ST = Out7.StressTestTable;
check(ST.SS2_Yr_Cont(1) < 25, sprintf('Baseline S0 expected early SS2 unlock < Yr 25, got %g', ST.SS2_Yr_Cont(1)));
check(ST.SS2_Yr_Cont(2) > 25 && ST.SS2_Yr_Cont(7) > 25, ...
    sprintf('Expected S1 (%g) and S6 (%g) to defer SS2 past Yr 25', ST.SS2_Yr_Cont(2), ST.SS2_Yr_Cont(7)));
check(all(ST.Contingent_Resilience_Gain_pp(2:end) > 3.5), 'Expected > +3.5 pp contingent resilience dividend across all adverse shocks');
check(all(ST.Yr60Debt_Cont_PctGDP(2:end) < ST.Yr60Debt_Fixed_PctGDP(2:end) - 4.0), 'Two-Key debt shield failed to beat rigid calendar debt');

%% 4. HEADLESS 4-PANEL DASHBOARD EXPORT
has_base_od = evalin('base', 'exist(''OutputDir'', ''var'')');
if has_base_od
    saved_od = evalin('base', 'OutputDir');
    evalin('base', 'clear OutputDir');
    c_od = onCleanup(@() assignin('base', 'OutputDir', saved_od));
end
tmp_out = tempname;
mkdir(tmp_out);
old_ov  = getenv('IGW_OUTPUT_DIR');
c_env   = onCleanup(@() setenv('IGW_OUTPUT_DIR', old_ov));
setenv('IGW_OUTPUT_DIR', tmp_out);
old_vis = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');
Dash7   = Plot_Contingency_And_Assembly_Dashboard(P0);
Dash7C  = Plot_SOE_Shock_Sensitivity_Dashboard(P0);
close all;
set(0, 'DefaultFigureVisible', old_vis);
check(exist(Dash7.Fig_Path, 'file') == 2,  'Plot_Contingency_And_Assembly_Dashboard failed to export PNG');
check(exist(Dash7C.Fig_Path, 'file') == 2, 'Plot_SOE_Shock_Sensitivity_Dashboard failed to export PNG');

%% 5. SUB-WAVE 7C: CONTINUOUS SOE SHOCK RANGES -> K01..K15 BREAKING-POINT INVARIANTS
S7C = Dash7C.Sensitivity;
CST = S7C.ContractSecurityTable;
SFT = S7C.ShockFrontierTable;
check(height(CST) == 15 && height(SFT) == 6 && height(S7C.AssemblyRoadmapTable) == 5, ...
    'Unexpected dimensions in Sub-Wave 7C sensitivity tables');
check(all(CST.Break_Lambda_Cont >= CST.Break_Lambda_Rigid), ...
    'Contingent stabilizers lowered breaking-point tolerance on at least one contract');
check(mean(CST.Buffer_Expansion_dLambda) > 0.40, ...
    'Expected mean breaking-point expansion > +0.40x shock units across K01..K15');
check(all(SFT.Max_All15_Safe_Cont >= 1.00), ...
    'Expected all 15/15 contracts to survive at least a 1.0x single/polycrisis shock under contingent remedies');
check(all(SFT.Intact_1p5x_Cont > SFT.Intact_1p5x_Rigid), ...
    'Expected strictly more intact contracts at 1.5x shock under contingent remedies than rigid calendar');

end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_wave7_contingencies: %s', msg);
end
end
