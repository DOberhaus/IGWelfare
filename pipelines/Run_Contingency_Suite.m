%% FIVE-ASSEMBLY CLEARINGHOUSE, 5-RISK CONTINGENCY & SOE SHOCK-FRONTIER SUITE (DOCUMENT 1F + 4)
% File: pipelines/Run_Contingency_Suite.m
% Executes:
%   1) Document 1F Five Citizens' Assembly Clearinghouse & 5-Risk Two-Key Stress-Test
%   2) Sub-Wave 7C Continuous SOE Exogenous Shock-Range & Contract Breaking-Point Sweep (lambda in [0, 2.5])
% Exports all 5 CSV tables and both 4-panel dashboards to output/<Profile_ID>/.

if ~exist('Params', 'var') || ~isstruct(Params)
    Params = struct();
end
if ~isfield(Params, 'dt') || isempty(Params.dt)
    Params.dt = 3;
end
[Params, Regions] = Ensure_Workbench_Initialized(Params, struct('RequireWorkerPool', false));
OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag = Params.Calibration_Anchor;

ContingencyOut   = Compute_Assembly_Clearinghouse_Ledger(Params, struct('Verbose', true));
ShockFrontierOut = Compute_Contract_Shock_Sensitivity_Ledger(Params, struct('Verbose', true));

writetable(ContingencyOut.ClearinghouseTable,       fullfile(OutputDir, sprintf('Table_Doc1F_Assembly_Clearinghouse_%s.csv', AnchorTag)));
writetable(ContingencyOut.StressTestTable,          fullfile(OutputDir, sprintf('Table_Doc1F_Contingency_5Risk_StressTest_%s.csv', AnchorTag)));
writetable(ShockFrontierOut.ContractSecurityTable,  fullfile(OutputDir, sprintf('Table_Doc1F_Contract_BreakingPoints_%s.csv', AnchorTag)));
writetable(ShockFrontierOut.ShockFrontierTable,     fullfile(OutputDir, sprintf('Table_Doc1F_SOE_Shock_Frontiers_%s.csv', AnchorTag)));
writetable(ShockFrontierOut.AssemblyRoadmapTable,   fullfile(OutputDir, sprintf('Table_Doc1F_Assembly_Telemetry_Roadmap_%s.csv', AnchorTag)));

DashContingency   = Plot_Contingency_And_Assembly_Dashboard(Params);
DashShockFrontier = Plot_SOE_Shock_Sensitivity_Dashboard(Params);
