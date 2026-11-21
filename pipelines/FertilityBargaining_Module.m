%% INTRA-HOUSEHOLD FERTILITY BARGAINING, HYPERBOLIC DELAY, WHANAU NETWORKS & NZ SUPER U-CURVE
% File: pipelines/FertilityBargaining_Module.m
% Pipeline orchestration script delegating pure math to Compute_FiscalSolvency_And_Fertility.m
% and rendering/CSV export to Plot_FertilityBargaining.m.
% Outputs:
%   - FertOut (full pure contract struct)
%   - T_Fert1 (Table7_4Region_Fertility_Bargaining_TFR.csv)
%   - T_Fert2 (Table8_4Region_Fertility_Struggling_NZSuperTax.csv)
%   - T_UCurve (Table8B_SuperAge_UCurve_60to75.csv)
%   - FigFert_4Region_Bargaining_Solvency.png (rendered immediately unless Defer_Fertility_Plot == true)

wb_opts = struct();
if exist('Regions', 'var') && ~isempty(Regions),             wb_opts.Regions       = Regions;       end
if exist('Reg_HH_Shares', 'var') && ~isempty(Reg_HH_Shares), wb_opts.Reg_HH_Shares = Reg_HH_Shares; end
if ~exist('Params', 'var'), Params = struct(); end
[Params, Regions, Reg_HH_Shares] = Ensure_Workbench_Initialized(Params, wb_opts);

if exist('StationaryDist_5D_BM', 'var')
    StatDist_5D_In = StationaryDist_5D_BM;
elseif exist('StationaryDist', 'var')
    StatDist_5D_In = StationaryDist;
else
    error('IGWelfare:MissingBaseline5D', 'FertilityBargaining_Module requires StationaryDist_5D_BM (or StationaryDist) in workspace.');
end

fert_opts = struct('Regions', {Regions}, 'Reg_HH_Shares', Reg_HH_Shares);
if exist('T1', 'var') && istable(T1)
    fert_opts.T1 = T1;
end

%% 1. PURE MATHEMATICAL EVALUATION (6 SCENARIOS + AGE 60-75 SOLVENCY U-CURVE)
FertOut = Compute_FiscalSolvency_And_Fertility(Params, StatDist_5D_In, n_a_5D, n_z, a_grid_5D, fert_opts);

% Unpack canonical workspace outputs & synchronize SS2 fiscal solvency fields on Params:
Params.tau_l_SS2_req_pct = FertOut.tau_l_SS2_req_pct;
Params.tau_l_delta_SS2   = FertOut.tau_l_delta_SS2;

FertScenarios  = FertOut.FertScenarios;
TFR_mat        = FertOut.TFR_mat;
DiffFert_mat   = FertOut.DiffFert_mat;
Struggling_mat = FertOut.Struggling_mat;
DepRatio_vec   = FertOut.DepRatio_vec;
ReqTax_vec     = FertOut.ReqTax_vec;
T_Fert1        = FertOut.T_Fert1;
T_Fert2        = FertOut.T_Fert2;
SuperAge_Grid  = FertOut.SuperAge_Grid;
Tax_UCurve_SS2 = FertOut.Tax_UCurve_SS2;
Dep_UCurve_SS2 = FertOut.Dep_UCurve_SS2;
TFR_UCurve_SS2 = FertOut.TFR_UCurve_SS2;
Stn_UCurve_SS2 = FertOut.Stn_UCurve_SS2;
CE_UCurve_SS2  = FertOut.CE_UCurve_SS2;
Tax_UCurve_SS0 = FertOut.Tax_UCurve_SS0;
T_UCurve       = FertOut.T_UCurve;

%% 2. RENDER 2x2 FIGURE & EXPORT CSV TABLES (UNLESS DEFERRED UNTIL STEP 6 T1 IS SOLVED)
if ~(exist('Defer_Fertility_Plot', 'var') && Defer_Fertility_Plot)
    plot_opts = struct();
    plot_opts.Export_Tables_Figures = (exist('Export_Tables_Figures', 'var') && Export_Tables_Figures);
    if exist('OutputDir', 'var') && ~isempty(OutputDir)
        plot_opts.OutputDir = OutputDir;
    end
    figFert = Plot_FertilityBargaining(FertOut, Params, plot_opts);
end
