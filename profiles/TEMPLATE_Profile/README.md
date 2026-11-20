# Custom Country / Cohort Profile Template

Copy this folder to `profiles/<Your_Profile_ID>/` (for example `profiles/FI_FBC1987/` or `profiles/SCO_GUS2005/`).

1. **Full Standalone Profile:** Populate `profile.yaml`, `regions.csv`, `demography_5yr.csv`, `migration_utility.csv`, `transition_sorting.csv`, `target_moments.csv`, `schedules/`, and `policies/`.
2. **Derived Sensitivity Profile (Inheritance):** Set `Inherits_From: NZ_Dunedin1972` (or another base profile) in `profile.yaml` and include only the CSV/YAML files or scalar sections you wish to override (see `profiles/NZ_GUiNZ2009/` for a minimal working example).

Load your profile anywhere in MATLAB or GNU Octave with:

    setup_igw_paths();
    DataSpec = Load_Empirical_Profile('<Your_Profile_ID>');
