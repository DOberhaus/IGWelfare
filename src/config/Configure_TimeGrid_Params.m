function Params = Configure_TimeGrid_Params(Params, dt, n_z_pts, DataSpec)
%% BACKWARD-COMPATIBLE DELEGATE TO CONFIGURE_MODEL_PARAMS (4-TIER PROVENANCE PIPELINE)
% File: src/config/Configure_TimeGrid_Params.m
% Delegates directly to Configure_Model_Params(Params, dt, n_z_pts, DataSpec)
% with canonical default dt = 3 years.

if nargin < 1, Params   = struct(); end
if nargin < 2, dt       = [];       end
if nargin < 3, n_z_pts  = [];       end
if nargin < 4, DataSpec = [];       end

Params = Configure_Model_Params(Params, dt, n_z_pts, DataSpec);

end
