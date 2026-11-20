%% WAVE 1 STANDALONE PLOT & TABLE SMOKE TEST (MATLAB & GNU OCTAVE)
clear; clc; close all;
setup_igw_paths(true);

P = struct('Profile_Name', 'NZ_GUiNZ2009');

fprintf('--- [1/8] Plot_Fertility_SuperSolvency_2Panel ---\n');
Plot_Fertility_SuperSolvency_2Panel(P); close all;

fprintf('--- [2/8] Plot_Counterfactuals_And_MirrorInvestments ---\n');
Plot_Counterfactuals_And_MirrorInvestments(P); close all;

fprintf('--- [3/8] Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole ---\n');
Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole(P); close all;

fprintf('--- [4/8] Plot_Doc1D_LaunchPlans ---\n');
Plot_Doc1D_LaunchPlans('', '', P); close all;

fprintf('--- [5/8] Plot_Doc1D_TeKahuiWakaSequencing ---\n');
Plot_Doc1D_TeKahuiWakaSequencing('', '', P); close all;

fprintf('--- [6/8] Plot_Hierarchical_Complementarity_Wedges ---\n');
Plot_Hierarchical_Complementarity_Wedges(P); close all;

fprintf('--- [7/8] Plot_WealthBracket_GiveAndGain ---\n');
Plot_WealthBracket_GiveAndGain(P); close all;

fprintf('--- [8/8] Plot_PreEmployment_OpportunityIndex ---\n');
Params = Configure_TimeGrid_Params(P);
run(which('Plot_PreEmployment_OpportunityIndex.m')); close all;

fprintf('\n[ALL 8 PLOT SUITES PASSED] Exported cleanly to output/NZ_GUiNZ2009\n');
