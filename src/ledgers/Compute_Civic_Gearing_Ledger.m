function Out = Compute_Civic_Gearing_Ledger(Params, Opts)
%% PURE TWO-SIDED CIVIC & CREATIVE GEARING SYMMETRY LEDGER (DOC 1E vs. 2024-26 CONTRACTION)
% File: src/ledgers/Compute_Civic_Gearing_Ledger.m
% Evaluates 4-Wedge x 4-Region incidence along 'grassroots_arts_sport_and_civic_commons':
%   - u = +1.0 (Doc 1E Co-Investment: -0.14% CE / -NZD 0.33B/yr Joiner Passport)
%   - u = -1.0 (2024-26 Civic/Cultural Contraction: +0.07% CE / +NZD 0.16B/yr claimed saving)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Pop_Weights_4')
    Params = Configure_Model_Params(struct());
end
if nargin < 2 || isempty(Opts)
    Opts = struct();
end
verbose_flag = isfield(Opts, 'Verbose') && logical(Opts.Verbose);

Pop_W      = Params.Pop_Weights_4(:);
NZD_Per_CE = 2.38;
if isfield(Params, 'NZD_Per_CE_Nat') && ~isempty(Params.NZD_Per_CE_Nat)
    NZD_Per_CE = Params.NZD_Per_CE_Nat;
end

Pos_Civic_4x4 = [ ...
    0.76,  0.85,  0.90,  0.94; ...
    0.82,  0.80,  0.74,  0.72; ...
    0.95,  1.05,  1.22,  1.23; ...
    0.57,  0.61,  0.64,  0.64];

Neg_Civic_4x4 = -[ ...
    0.29,  0.33,  0.52,  0.39; ...
    0.34,  0.33,  0.48,  0.30; ...
    0.38,  0.45,  1.08,  0.68; ...
    0.22,  0.25,  0.44,  0.30];

Neg_StateSci_4x4 = -[ ...
    0.15,  0.18,  0.34,  0.20; ...
    0.22,  0.24,  0.48,  0.25; ...
    0.95,  1.15,  3.28,  1.68; ...
    0.52,  0.60,  1.10,  0.78];

Comb_4x4         = Neg_Civic_4x4 + Neg_StateSci_4x4;

Nat_Pos_W4       = Pos_Civic_4x4    * Pop_W;
Nat_NegCiv_W4    = Neg_Civic_4x4    * Pop_W;
Nat_StateSci_W4  = Neg_StateSci_4x4 * Pop_W;
Nat_Comb_W4      = Comb_4x4         * Pop_W;

Reg_Pos_1x4      = sum(Pos_Civic_4x4,    1);
Reg_NegCiv_1x4   = sum(Neg_Civic_4x4,    1);
Reg_StateSci_1x4 = sum(Neg_StateSci_4x4, 1);
Reg_Comb_1x4     = sum(Comb_4x4,         1);

Cash_Impulse_CE  = [-0.140; +0.070; +0.238; +0.280];
Tot_Nat_CE       = [sum(Nat_Pos_W4); sum(Nat_NegCiv_W4); sum(Nat_StateSci_W4); sum(Nat_Comb_W4)];
Large_CE         = [Reg_Pos_1x4(3);  Reg_NegCiv_1x4(3);  Reg_StateSci_1x4(3);  Reg_Comb_1x4(3)];
Gearing_Mult     = [abs(Tot_Nat_CE(1)) / 0.140; ...
                    abs(Tot_Nat_CE(2)) / 0.070; ...
                    abs(Tot_Nat_CE(3)) / 0.238; ...
                    abs(Tot_Nat_CE(4)) / 0.280];

Regime_Labels = { ...
    'Civic_Commitment_Plus1_Doc1E'; ...
    'Civic_Commitment_Minus1_S15'; ...
    'State_And_Science_Minus1_S05_S06'; ...
    'Combined_State_Science_Civic_Minus1'};

W_Mat = [Nat_Pos_W4'; Nat_NegCiv_W4'; Nat_StateSci_W4'; Nat_Comb_W4'];

Out = struct();
Out.NZD_Per_CE_Nat   = NZD_Per_CE;
Out.Pos_Civic_4x4    = Pos_Civic_4x4;
Out.Neg_Civic_4x4    = Neg_Civic_4x4;
Out.Neg_StateSci_4x4 = Neg_StateSci_4x4;
Out.Gearing_Up       = Gearing_Mult(1);
Out.Gearing_Down     = Gearing_Mult(2);
Out.SummaryTable     = table(Regime_Labels, Cash_Impulse_CE, ...
    W_Mat(:,1), W_Mat(:,2), W_Mat(:,3), W_Mat(:,4), Tot_Nat_CE, Large_CE, Gearing_Mult, ...
    'VariableNames', {'Regime', 'Cash_Impulse_CE_Pct', ...
    'dW1_CE_Pct', 'dW2_CE_Pct', 'dW3_CE_Pct', 'dW4_CE_Pct', ...
    'National_4Wedge_CE_Pct', 'Large_Metro_CE_Pct', 'Gearing_Multiplier'});

if verbose_flag
    disp(Out.SummaryTable);
end
end
