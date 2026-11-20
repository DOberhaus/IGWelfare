# New Zealand Intergenerational Welfare Model: Workbench User Guide

This guide outlines the general principles for setting up your workspace, configuring control switches, and executing individual analysis scripts standalone.

---

## 1. Architectural Principles
The IGWelfare repository uses a dual-tier configuration model:
1. **The `Params` Struct:** Holds deep structural economic parameters (time-grid `dt`, retirement age `Jr`, taxation rates, demographic weights, and regional housing user costs `Q_reg`).
2. **Workspace Control Variables:** High-level execution controllers (such as `Target_Regions`, `Active_Phases`, `OutputDir`, and `NZD_Base_Scale`) are managed directly in the MATLAB/Octave workspace or script header. This allows seamless looping over regions and steady-state phases without encumbering core mathematical function signatures.

---

## 2. Setting Up Your Workbench Manually
If you wish to run scripts standalone outside of `Run_All_NZ_Intergen_Suite.m`, initialize your workspace environment with this standard bootstrap sequence:

```matlab
clear; clc; close all;

% Add VFI Toolkit paths (MATLAB & Octave shims)
addpath(genpath('../VFIToolkit-matlab'));
addpath('../VFIToolkit-octave');
VFIToolkit_Octave_Setup({'ReturnFn_SpatialHH', 'ReturnFn_SpatialHH_Compact4D', 'ReturnFn_Firm', 'HumanCapital_Lifecycle_aprimeFn'});

% Initialize core parameters
Params = struct('dt', 3, 'n_z_pts', 7);
Params = Configure_TimeGrid_Params(Params, Params.dt);
