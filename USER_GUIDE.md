# Intergenerational Welfare Model: Workbench User Guide

This guide outlines the modular directory layout, the Three-Layer Data & Policy Architecture, and how to configure and execute individual scripts or full suite runs in MATLAB and GNU Octave.

---

## 1. Architectural Principles

The `IGWelfare` repository separates empirical grounding, rollout staging, governance contingencies, and numerical solvers across two orthogonal contracts:

### A. The Three-Layer Data & Policy Stack (`profiles/<Profile_ID>/`)
1. **Layer 1 — Empirical World (`DataSpec = Load_Empirical_Profile(Profile_Name)`):**
   * Pure, idempotent loader reading `profile.yaml`, `regions.csv`, `demography_5yr.csv`, `migration_utility.csv`, `transition_sorting.csv`, and `target_moments.csv`.
   * Built-in profiles include `'NZ_Dunedin1972'` (legacy alias `'Dunedin_22'`) and `'NZ_GUiNZ2009'` (legacy alias `'MetroSqueeze_GUiNZ'`, demonstrating single-parent `Inherits_From` profile inheritance), plus `profiles/TEMPLATE_Profile/` for custom jurisdictions.
2. **Layer 2 — Kinematic Rollout Schedule (`RolloutSpec = Load_Rollout_Schedule(DataSpec, Rollout_Mode)`):**
   * Defines how investment gates, regional echelons, tax ramps, and implementation frictions (`tau_friction_0`, `phi_adj_bottleneck`, `gamma_learning`) unfold in relative track time (`'TeKahuiWaka'`, `'SingleShot'`, or `'Frictionless_Textbook'`).
3. **Layer 3 — State-Contingent Governance (`ContingencySpec = Load_Contingency_Policy(DataSpec, Policy_Name)`):**
   * Declarative YAML gate policies (`'contingent_armada'`, `'fixed_calendar_2050'`) evaluated via `Evaluate_Contingency_Gates.m` to determine *when* and *whether* downstream tracks (such as `SS2` dividend harvest) unlock based on realized fiscal and human-capital metrics.

### B. Three-Tier Content-Hashed Caching (`Get_ModelConfigHash.m` & `Validate_CacheConfig.m`)
* **`SS0_*` (Steps 1–5 Baseline Steady State):** Hashed strictly on Layer 1 `DataSpec` + structural baseline parameters. Editing rollout modes or contingency gates **never** invalidates baseline 5D/4D steady-state caches.
* **`SSReform_*` (Step 6 Reform Steady States):** Hashed on `SS0_*` + asymptotic delivery multipliers (`Rollout_Mode`), invariant to Layer 3 contingency rules.
* **`Trans_*` (Step 7+ Transition & VaR):** Hashed on all three layers (`DataSpec` + `RolloutSpec` + `ContingencySpec`).
* Outputs and caches are automatically isolated per profile under `output/<Profile_ID>/` and `cache/<Profile_ID>/`.

---

## 2. Repository Directory Hierarchy

* `setup_igw_paths.m` — Idempotent root path & VFIToolkit bootstrap for MATLAB and GNU Octave
* `profiles/` — Modular CSV + YAML empirical profiles, schedules, and contingency policies
* `src/data/` — `Load_Empirical_Profile.m`, `Load_Rollout_Schedule.m`, `Load_Contingency_Policy.m`, `Evaluate_Contingency_Gates.m`, `Read_IGW_YAML.m`, `Read_IGW_CSV.m`
* `src/config/` — `Configure_TimeGrid_Params.m`, `Build_Phase_Registry.m`, `Get_ModelConfigHash.m`, `Validate_CacheConfig.m`
* `src/models/` — Bellman return functions (`ReturnFn_*`) and lifecycle experience-asset kernels (`*aprimeFn.m`)
* `src/solvers/` — `Build_IntergenTransitionMatrix.m`, phase-split VFI, and stationary distribution operators
* `src/calibration/` — `Calibrate_NZ_Moments.m`
* `src/utils/` — `IGW_Log.m` and Octave/GPU helper utilities
* `pipelines/` — Top-level orchestrators (`Run_All_NZ_Intergen_Suite.m`, `NZ_4Region_Master.m`, `TransPath_4Region_Master.m`, counterfactual & decomposition modules)
* `plots/` — Publication figure and actuarial valuation scripts (`Plot_*.m`)

---

## 3. Setting Up Your Workbench Manually

Initialize your MATLAB or GNU Octave session from the repository root with `setup_igw_paths()`:

    clear; clc; close all;
    setup_igw_paths();

    % Initialize structural + 3-layer parameters (defaults to 'NZ_Dunedin1972' + 'TeKahuiWaka')
    Params = struct( ...
        'Profile_Name',       'NZ_Dunedin1972', ... % Or 'NZ_GUiNZ2009'
        'Rollout_Mode',       'TeKahuiWaka',    ... % 'TeKahuiWaka', 'SingleShot', or 'Frictionless_Textbook'
        'Contingency_Policy', 'contingent_armada', ...
        'dt',                 3, ...
        'n_z_pts',            7);
    Params = Configure_TimeGrid_Params(Params, Params.dt);

    % Optional GNU Octave persistent worker pool initialization for VFI solvers
    if exist('OCTAVE_VERSION', 'builtin') ~= 0 && exist('vfi_pool', 'file') ~= 0
        VFIToolkit_Octave_Setup({'ReturnFn_SpatialHH', 'ReturnFn_SpatialHH_Compact4D', ...
            'ReturnFn_Firm', 'HumanCapital_Lifecycle_aprimeFn'});
    end

To run the full suite from the command line with overrides:

    setup_igw_paths();
    Profile_Name = 'NZ_GUiNZ2009';
    Params = struct('dt', 3, 'Rollout_Mode', 'SingleShot');
    run('pipelines/Run_All_NZ_Intergen_Suite.m');

---

## 4. Invoking GNU Octave & MATLAB: Dos and Don'ts

The repository root includes both **`.octaverc`** (for GNU Octave) and **`startup.m`** (for MATLAB), which automatically invoke `setup_igw_paths()`—adding all `src/**`, `pipelines/`, and `plots/` directories, loading `VFIToolkit-matlab` and `VFIToolkit-octave` shims, and configuring safe graphics defaults before your first command runs.

### Recommended Invocations (From Repo Root)
* **Interactive GNU Octave Terminal (with `qt` offscreen plotting support):**
      octave --no-gui
* **Batch / One-Liner GNU Octave Execution:**
      octave --no-gui --eval "run(which('Run_All_NZ_Intergen_Suite.m'));"
      octave --no-gui --eval "Plot_ActuarialContinuationValuation([], struct('Profile_Name','NZ_GUiNZ2009'), 'National');"
* **Pure Compute-Only CLI (no Qt library overhead when no plots are exported):**
      octave-cli
* **Batch MATLAB Execution:**
      matlab -batch "run(which('Run_All_NZ_Intergen_Suite.m'));"

### Critical Don'ts
1. **Do NOT pass `--norc` or `-f` to Octave without calling `setup_igw_paths()`:** Passing `--norc` suppresses `.octaverc`, leaving `src/**` and `VFIToolkit_Octave_Setup` unloaded unless your `--eval` string starts with `setup_igw_paths(true);`.
2. **Do NOT set `graphics_toolkit('gnuplot')` in Octave:** Octave 11's `gnuplot` backend cannot render modern `hggroup` primitives (`xline`, translucent `fill` bands) inside legends. Leave graphics on `'qt'` or `'fltk'` as configured by `setup_igw_paths()`.
3. **Do NOT create `'Visible', 'off'` figures manually under `octave-cli` (`fltk`) before `exportgraphics`:** In `octave-cli` (where Qt GUI is unlinked), FLTK requires a visible OpenGL buffer during capture. Check `strcmp(graphics_toolkit(), 'fltk')` (as in `Plot_ActuarialContinuationValuation.m`) or run under GUI-linked `octave` when true headless window suppression is required.
4. **Do NOT hardcode relative paths like `run('NZ_4Region_Master.m')` when calling across subfolders:** Use `run(which('NZ_4Region_Master.m'))` so both MATLAB and GNU Octave resolve pipeline scripts cleanly from any working directory.
