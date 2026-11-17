function T_Prot = Build_Multiphase_2050_Protocol_Table(Phase_Ledgers, Phase_Codes, Target_Region)
%% BUILD_MULTIPHASE_2050_PROTOCOL_TABLE
N_p   = numel(Phase_Ledgers);
L_ref = Phase_Ledgers{1};

T_Prot = table([L_ref.Net_Fiscal_Balance_kNZD(1); L_ref.Net_Fiscal_Balance_kNZD(2)], ...
    'RowNames', {'Gate5_CareerSorting_J8_11', 'Gate6_AdultFiscalLedger_J10_16'}, ...
    'VariableNames', {sprintf('Baseline_%s_kNZD', Phase_Codes{1})});

for p = 2:N_p
    Lp   = Phase_Ledgers{p};
    code = Phase_Codes{p};
    Omega_1 = max(0, Lp.Net_Fiscal_Balance_kNZD(1) - L_ref.Net_Fiscal_Balance_kNZD(1));
    Omega_2 = max(0, Lp.Net_Fiscal_Balance_kNZD(2) - L_ref.Net_Fiscal_Balance_kNZD(2));

    T_Prot.(sprintf('Reform_%s_kNZD', code))             = [Lp.Net_Fiscal_Balance_kNZD(1); Lp.Net_Fiscal_Balance_kNZD(2)];
    T_Prot.(sprintf('Gain_Omega_%s_kNZD', code))         = [Omega_1; Omega_2];
    T_Prot.(sprintf('DebtSinking_50Pct_%s_kNZD', code))  = [Lp.SinkingFund_50Pct_kNZD(1); Lp.SinkingFund_50Pct_kNZD(2)];
    T_Prot.(sprintf('ReinvestPool_50Pct_%s_kNZD', code)) = [Lp.ReinvestmentPool_50Pct_kNZD(1); Lp.ReinvestmentPool_50Pct_kNZD(2)];
    T_Prot.(sprintf('DebtIntSaved_2050_%s_kNZD', code))  = [Lp.Annual_DebtService_Saving_kNZD(1); Lp.Annual_DebtService_Saving_kNZD(2)];
    T_Prot.(sprintf('InfraYieldDiv_2050_%s_kNZD', code)) = [Lp.Public_Infra_Yield_Dividend_kNZD(1); Lp.Public_Infra_Yield_Dividend_kNZD(2)];
end

fprintf('\n=========================================================================================================\n');
fprintf('SECTION 5 PROTOCOL: MULTIPHASE 2050 SOVEREIGN DEBT-SINKING & REINVESTMENT LEDGER (%s)\n', Target_Region);
fprintf('=========================================================================================================\n');
disp(T_Prot);
for p = 2:N_p
    fprintf('  [%s] Cumulative 2050 Sovereign Debt Reduction (per 60k cohort): %.1f MNZD | Reinvest Pool: %.1f MNZD\n', ...
        Phase_Codes{p}, Phase_Ledgers{p}.Cum_2050_DebtReduction_MNZD, Phase_Ledgers{p}.Cum_2050_ReinvestPool_MNZD);
end
end
