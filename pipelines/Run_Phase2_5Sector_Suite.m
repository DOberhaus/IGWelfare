%% PHASE II 5-SECTOR SOE, EXERGY, ATKINSON-WARING & PUBLIC-ASSET SUITE (DOCUMENT 4)
% File: pipelines/Run_Phase2_5Sector_Suite.m
% Executes the outer-loop 5-Sector Small Open Economy, Keen-Labrousse Exergy,
% Paris NDC / Pine-Saturation, Three-Tier (SNA / Atkinson-Waring / CE%), and
% Public-Asset Stewardship ledgers, exporting CSVs and the 4-Panel Dashboard.

if ~exist('Params', 'var') || ~isstruct(Params)
    Params = struct();
end
if ~isfield(Params, 'dt') || isempty(Params.dt)
    Params.dt = 3;
end
[Params, Regions] = Ensure_Workbench_Initialized(Params, struct('RequireWorkerPool', false));
OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag = Params.Calibration_Anchor;

fprintf('\n=== 1. DOCUMENT 4 5-SECTOR EMPIRICAL BASELINE ROLLUP ===\n');
SecSpec = Load_Sectoral_Exergy_Spec(Params.Profile_ID);
disp(SecSpec.MacroSector_Table);

fprintf('\n=== 2. THREE-TIER NATIONAL ACCOUNTS & WARING SATELLITE SCORECARD (2050) ===\n');
ThreeTierOut = Compute_ThreeTier_NationalAccounts_Ledger(Params, struct('Verbose', true));

fprintf('\n=== 3. PUBLIC-ASSET PRIVATIZATION VS. STEWARDSHIP TURNAROUND LEDGER ===\n');
AssetOut = Compute_Public_Asset_Stewardship_Ledger(Params, struct('Verbose', true));

fprintf('\n=== 4. PARIS NDC, PINE SATURATION & EXERGY ABATEMENT LEDGER ===\n');
NDCOut = Compute_NDC_Compliance_Ledger(Params, struct('Verbose', true));

writetable(SecSpec.MacroSector_Table, fullfile(OutputDir, sprintf('Table_Phase2_5Sector_Baseline_%s.csv', AnchorTag)));
writetable(ThreeTierOut.SummaryTable, fullfile(OutputDir, sprintf('Table_Phase2_ThreeTier_Scorecard_%s.csv', AnchorTag)));
writetable(AssetOut.SummaryTable,     fullfile(OutputDir, sprintf('Table_Phase2_PublicAsset_Stewardship_%s.csv', AnchorTag)));
writetable(NDCOut.SummaryTable,       fullfile(OutputDir, sprintf('Table_Phase2_NDC_Exergy_Compliance_%s.csv', AnchorTag)));

DashOut = Plot_Phase2_5Sector_Dashboard(Params);
