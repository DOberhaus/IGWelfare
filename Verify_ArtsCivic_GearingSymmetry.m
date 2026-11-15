% VERIFY_ARTSCIVIC_GEARINGSYMMETRY
% Pure CPU matrix check reconciling Document 1E (+Delta T1E) vs. Shock #15 Disinvestment

if ~exist('Params', 'var') || ~isfield(Params, 'Pop_Weights_4')
    Params = Configure_TimeGrid_Params(struct());
end
Pop_W      = Params.Pop_Weights_4(:); % [4 x 1] from launch SSOT
NZD_Per_CE = Params.NZD_Per_CE_Nat;   % 2.38 BNZD/yr per 1% CE from launch SSOT

% 1. Positive Investment (Doc 1E Table 19E: -0.14% CE / -NZD 0.33B/yr seed) [4 Wedges x 4 Regions]
Pos_Arts_4x4 = [ ...
    0.76,  0.85,  0.90,  0.94; ... % +Delta W1: Sistema/Kapa Haka & lambda_psy buffer
    0.82,  0.80,  0.74,  0.72; ... % +Delta W2: Join-or-Die 50% hazard drop & club space
    0.95,  1.05,  1.22,  1.23; ... % +Delta W3: Creative z_h IP & youth retention
    0.57,  0.61,  0.64,  0.64];    % +Delta W4: Bridging cohesion (126 -> 134.5) & TFR

% 2. Negative Disinvestment: Shock #15 Alone (+0.07% CE / +NZD 0.16B/yr claimed saving)
%    Reflects Poneke (k=3) & Auckland (k=4) concentration + 1.08x organizational hysteresis
Neg_Shock15_4x4 = -[ ...
    0.29,  0.33,  0.52,  0.39; ... % -Delta W1: Creatives in Schools & Tu Manawa axed (-0.39% Nat)
    0.34,  0.33,  0.48,  0.30; ... % -Delta W2: CAB (>50% WCC cut) & hall fee squeeze (-0.36% Nat)
    0.38,  0.45,  1.08,  0.68; ... % -Delta W3: Venue/festival & creative z_h brain drain (-0.68% Nat)
    0.22,  0.25,  0.44,  0.30];    % -Delta W4: Civic trust erosion & acute health spillovers (-0.31% Nat)

% 3. Shock #5 + #6 Public Sector & Science Dissolutions (~NZD 1.90B/yr gross; k=3 heavy)
Neg_PubSci_4x4 = -[ ...
    0.15,  0.18,  0.34,  0.20; ... % -Delta W1: Household job-loss shock on Yr 8-10 youth
    0.22,  0.24,  0.48,  0.25; ... % -Delta W2: Provincial & Wellington service-hub closures
    0.95,  1.15,  3.28,  1.68; ... % -Delta W3: 6k+ roles, Callaghan/NIWA/Marsden & 177 WCC closures
    0.52,  0.60,  1.10,  0.78];    % -Delta W4: Automatic-stabilizer clawback & TFR deferral

Nat_Pos_W4     = Pos_Arts_4x4    * Pop_W;
Nat_Shock15_W4 = Neg_Shock15_4x4 * Pop_W;
Nat_Comb_4     = (Neg_Shock15_4x4 + Neg_PubSci_4x4)'; % [4 Regions x 4 Wedges]
Reg_Comb_Tot   = sum(Nat_Comb_4, 2);                  % Regional totals (k=3 Wellington = -7.72% CE!)

Gear_Up_Arts   = sum(Nat_Pos_W4)             / 0.140; % +24.29x upward gearing
Gear_Dn_Arts   = abs(sum(Nat_Shock15_W4))    / 0.070; % -24.89x downward gearing

fprintf('Upward Arts-Civic Gearing (Doc 1E):   %+.2f%% CE on -0.14%% seed  = %.2fx\n', sum(Nat_Pos_W4), Gear_Up_Arts);
fprintf('Downward Shock #15 Gearing (2024-26): %+.2f%% CE on +0.07%% saved = %.2fx\n', sum(Nat_Shock15_W4), Gear_Dn_Arts);
fprintf('Combined State + Arts Contraction:    %+.2f%% CE National | %+.2f%% CE in Large (Poneke)\n', ...
    Reg_Comb_Tot' * Pop_W, Reg_Comb_Tot(3));