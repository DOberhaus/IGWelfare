function [Params, Provenance] = Configure_Model_Params(Params, dt, n_z_pts, DataSpec, CalibSpec, RegimeSpec)
%% CANONICAL 4-TIER EPISTEMIC PARAMETER BUILDER (IDEMPOTENT & PTYPE-PURE)
% File: src/config/Configure_Model_Params.m
% Orchestrates the strict 4-tier parameter provenance pipeline:
%   Tier A: Configure_Grid_And_Prefs(Params, dt, n_z_pts)
%   Tier B: Apply_Empirical_Data(Params, DataSpec)
%   Tier C: Apply_Calibrated_Params(Params, CalibSpec)
%   Tier D: Apply_Policy_Regime(Params, RegimeSpec)
%
% Preserves VFI Toolkit's flat/PType-only struct contract on Params while optionally
% returning a full field-by-field Provenance report as the second output argument.

if nargin < 1 || isempty(Params), Params = struct(); end
if nargin < 2, dt         = []; end
if nargin < 3, n_z_pts    = []; end
if nargin < 4, DataSpec   = []; end
if nargin < 5, CalibSpec  = []; end
if nargin < 6, RegimeSpec = ''; end

Params = Configure_Grid_And_Prefs(Params, dt, n_z_pts);
Params = Apply_Empirical_Data(Params, DataSpec);
Params = Apply_Calibrated_Params(Params, CalibSpec);
Params = Apply_Policy_Regime(Params, RegimeSpec);

if nargout >= 2
    Provenance = Describe_Params_Provenance(Params);
end

end
