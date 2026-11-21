function [Params_Out, pi_z_Out, ShockMeta, z_grid_Out] = Apply_Coalition_2024_Shocks(Params_In, pi_z_In, Mode, ShockOpts, z_grid_In)
%% BACKWARD-COMPATIBLE DELEGATE TO COMPOSE_POLICY_BUNDLE (CONVENTION-2 COMMITMENT ALGEBRA)
% File: src/config/Apply_Coalition_2024_Shocks.m
if nargin < 2, pi_z_In   = struct(); end
if nargin < 3, Mode      = 'domestic_15_bundle'; end
if nargin < 4, ShockOpts = struct(); end
if nargin < 5, z_grid_In = struct(); end

[Params_Out, pi_z_Out, ShockMeta, z_grid_Out] = Compose_Policy_Bundle( ...
    Params_In, pi_z_In, Mode, ShockOpts, z_grid_In);
end
