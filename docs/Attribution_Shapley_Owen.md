# Order-independent attribution: Shapley and Owen values for the 11-layer decomposition

Companion to `Shapley_Owen_Attribution.m` and `tests/`. Numbers are national SS2 long-run CE %, as typed in `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m`.

## Why order independence matters for "47.3% from four wedges"
The headline total is already order-invariant: if the seven isolated layers are the singleton values v({i}), the wedge total is v(N) − Σ v({i}) = 24.24 − 12.78 = 11.46, i.e. 47.28%. How that 11.46 is split among Wedges 1–4, and credited to levers or coalitions, depends on the chosen build order and bucketing; Wedges 3 and 4 are defined relative to earlier stacks (Wedge 4 closes the residual). Three-player illustration (tested): building A, B, C gives staircase wedges 4 and 4; building C, B, A gives 3 and 5; the total, 8, is the same.

## How the current wedges relate to Shapley interaction terms
Write the Harsanyi dividend of a lever set S as d(S). Then Shapley φ_i = Σ over S ∋ i of d(S)/|S|, and each wedge is a sum of dividends over one bucket of sets. For two-lever stacks the wedge is exactly the two-way interaction v({A,B}) − v({A}) − v({B}) + v(∅) (checked for Wedge 1 = 3.26 and Wedge 3 = 3.95), and Shapley splits it equally: Dual-Gate gives ECE₁ 5.20 and Tuakana 3.76; stacks give HC 10.935 and Spatial 9.315. The Owen value additionally respects the Document 3 coalitions as a priori unions. If interactions are only pairwise it equals Shapley for any grouping; the grouping matters only through three-way and higher terms (Wedges 2–4).

Document 3's row totals (13.41, 9.24, 6.00, 3.80) sum to 32.45 because each pairwise wedge appears in both partners' rows. Splitting each wedge equally (Shapley under the matrix's own pairwise accounting) gives 10.56, 7.22, 4.08, 2.39, summing to 24.24.

## The "path-dependent" sentence (Document 2B, line 322)
> "Rather than relying on an arbitrary path-dependent Shapley residual, `Plot_Counterfactuals_And_MirrorInvestments.m` constructs an **11-Layer Supermodular Hierarchy**..."

Alternative wording: *Shapley values average each lever's marginal contribution over all orderings and are therefore order-independent; it is a single-path decomposition that is path-dependent.* The 11-layer hierarchy remains a description of isolated effects and stack-level wedges; Shapley/Owen allocates those wedges.

## Populating the value table
Index coalitions by bitmask (lever k ⇔ bit k), levers 1–7 = ECE₁, Tuakana, Estate/Property rebalance, Youth Grant, Geo transfer, Debt-sinking, PAYE/Super-64. Fill a 128-vector with SS2 national CE from the same model-run pipeline, NaN where not run, then call `Shapley_Owen_Attribution(V, 7, unions)`; if a required value is missing the call errors with a count and the first five missing coalitions; the full list is `info.masks_needed` from a stub call such as `Shapley_Owen_Attribution(@(m) 0, 7, unions)`. Existing values: 12 of 128 (∅, 7 singletons, {1,2}, {3,4,5}, {1..5}, grand), assuming those layers come from model runs; the Plot scripts hard-code them.

| Target | New runs |
|---|---|
| Full Shapley, 7 levers | 116 |
| Owen, 4 coalitions {1,2},{4,5},{3},{6,7} | 52 |
| Owen, 3 stacks {1,2},{3,4,5},{6,7} | 36 |
| All 21 pairs (checks the pairwise assumption against 24.24) | 20 |

Each run is one SS2 long-run model run (the current pipeline solves households under typed prices); time per run was not measured here.
