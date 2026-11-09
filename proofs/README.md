# RED/GREEN proofs for upstream PRs #8 and #9

`run_proofs.m` runs each `scripts/prove_*.m` twice, in MATLAB and in GNU Octave, and prints
`<pr> <proof> <MAIN|BRANCH> <the script's one-line result>`, then `N proofs as expected, M unexpected`
(`run_proofs('exit')` exits 1 if any is unexpected; CI: `.github/workflows/proofs.yml`).
- MAIN = repo root (upstream/main c23787e): root `*.m`, `tests/`, `tools/`, `Output_NZ_4Region_Intergen/*.csv`, copied to a temp tree.
- BRANCH = MAIN plus the overlay `branch/prN/` (the files the PR adds or changes), copied to a second temp tree.
- `branch/pr8/` = danalytics/logged-failures 5a344f6; `branch/pr9/` = danalytics/fix-cond-ras 65ec1fb (both diffed against c23787e).
- Expected: MAIN RED and BRANCH GREEN, except `timegrid` (informational, GREEN on both: fixed upstream) and `hash` under Octave (SKIP on both).
- Scripts are the measured logic unchanged; PR #9's `prove_cond` reads `tests/read_csv_cells.m`, which MAIN lacks, so the runner adds that one helper to MAIN.
