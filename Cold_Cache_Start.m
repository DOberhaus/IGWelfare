cd('C:\GitHub\IGWelfare');
setup_igw_paths(false, true);
addpath(fullfile(pwd, 'src', 'utils'), fullfile(pwd, 'tools'));
rehash; close all;

% Purge saved .mat caches across profiles for a true cold-start benchmark:
delete(fullfile(pwd, 'cache', 'NZ_Dunedin1972', '*.mat'));
delete(fullfile(pwd, 'cache', 'NZ_GUiNZ2009',  '*.mat'));

% Store timers in root appdata so Run_All_NZ_Intergen_Suite's clearvars cannot wipe them:
setappdata(0, 'IGW_BENCH_T0', tic);
setappdata(0, 'IGW_BENCH_TA', tic);

% Stage A: Cold-Cache 4-Region + Abroad 5D/4D VFI, Decomposition & 60-Yr Transition
Force_Recompute_All = true;
Profile_Name        = 'NZ_Dunedin1972';
run(which('Run_All_NZ_Intergen_Suite.m'));
sec_core_olg = toc(getappdata(0, 'IGW_BENCH_TA'));
setappdata(0, 'IGW_BENCH_SEC_A', sec_core_olg);

% Stage B: 5-Sector SOE, Exergy/Waring, Public-Asset, Trim-Tabs & Five-Assembly Clearinghouse
setappdata(0, 'IGW_BENCH_TB', tic);
P_dun = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 3));
run(which('Run_Phase2_5Sector_Suite.m'));
Plot_HelmPhysics_TrimTabs_And_CounterSteering(P_dun);
run(which('Run_Contingency_Suite.m'));
close all;
sec_soe_gov = toc(getappdata(0, 'IGW_BENCH_TB'));
setappdata(0, 'IGW_BENCH_SEC_B', sec_soe_gov);

% Stage C: Doc 3 Coalition Matrix, Doc 1D 13-Wave Sequencing, Sankeys (PNG+HTML+CSV) & GUiNZ Sensitivity
setappdata(0, 'IGW_BENCH_TC', tic);
addpath(fullfile(pwd, 'src', 'utils'), fullfile(pwd, 'tools'));
OutputDir = fullfile(pwd, 'output', 'NZ_Dunedin1972');
chk_mat   = fullfile(OutputDir, 'NZ_4Region_Intergen_Complete_Results.mat');
if (~exist('n_d', 'var') || ~exist('StationaryDist', 'var')) && isfile(chk_mat)
    load(chk_mat);
end
OutputDir = fullfile(pwd, 'output', 'NZ_Dunedin1972');
P_dun     = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 3));

Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole(P_dun);
Plot_Doc1D_LaunchPlans(OutputDir, '', P_dun);
Plot_Doc1D_TeKahuiWakaSequencing(OutputDir, '', P_dun);
close all;

Params                 = P_dun;
Interactive_Hover_Mode = true;
Target_Regions         = {'National'};
Active_Phases          = {'SS0', 'SS1'};
run(which('Plot_ChildFates_SSankey.m'));  close all;
run(which('Plot_ChildFiscal_SSankey.m')); close all;

Target_Regions = {'National', 'Auckland', 'Large', 'Small', 'Urban', 'Rural'};
Active_Phases  = {'SS0', 'SS1', 'SS2'};
run(which('Plot_ChildFates_SSankey.m'));  close all;
run(which('Plot_ChildFiscal_SSankey.m')); close all;
recompute_table14_cond(OutputDir, false, true);

clear OutputDir; if isappdata(0, 'IGW_OUTPUT_DIR'), rmappdata(0, 'IGW_OUTPUT_DIR'); end
Run_WealthTax_Exemption_Sensitivity(struct('Profile_Name', 'NZ_GUiNZ2009'));
close all;
sec_plots_sankey = toc(getappdata(0, 'IGW_BENCH_TC'));
setappdata(0, 'IGW_BENCH_SEC_C', sec_plots_sankey);

% Stage D: 27-Test Automated Verification Harness & Legacy-Folder Guard
setappdata(0, 'IGW_BENCH_TD', tic);
run(which('run_all_tests.m'));
assert(~isfolder(fullfile(pwd, 'Output_NZ_4Region_Intergen')), ...
    'REGRESSION: Legacy Output_NZ_4Region_Intergen folder was recreated!');
sec_tests = toc(getappdata(0, 'IGW_BENCH_TD'));

sec_a     = getappdata(0, 'IGW_BENCH_SEC_A');
sec_b     = getappdata(0, 'IGW_BENCH_SEC_B');
sec_c     = getappdata(0, 'IGW_BENCH_SEC_C');
sec_total = toc(getappdata(0, 'IGW_BENCH_T0'));
for fn = {'IGW_BENCH_T0','IGW_BENCH_TA','IGW_BENCH_TB','IGW_BENCH_TC','IGW_BENCH_TD','IGW_BENCH_SEC_A','IGW_BENCH_SEC_B','IGW_BENCH_SEC_C'}
    if isappdata(0, fn{1}), rmappdata(0, fn{1}); end
end

fprintf('\n====================================================================\n');
fprintf('  COLD-CACHE END-TO-END BENCHMARK SUMMARY (RTX 5090, beta_hh=0.980)\n');
fprintf('--------------------------------------------------------------------\n');
fprintf('  Stage A (Core 4-Region OLG + 60-Yr TransPath) : %6.2f s (%5.2f min)\n', sec_a, sec_a/60);
fprintf('  Stage B (5-Sector SOE, Trim-Tabs & Assembly)  : %6.2f s\n', sec_b);
fprintf('  Stage C (Doc3, Doc1D, 18+29 Sankeys & GUiNZ)  : %6.2f s\n', sec_c);
fprintf('  Stage D (27/27 Regression Test Suite)         : %6.2f s\n', sec_tests);
fprintf('--------------------------------------------------------------------\n');
fprintf('  TOTAL COLD-START WALL TIME                    : %6.2f s (%5.2f min)\n', sec_total, sec_total/60);
fprintf('====================================================================\n');