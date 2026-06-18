# Log

## 2026-06-16
- Planned project; refined via Ultraplan (reproducibility pins, evolve-once-slice, termination-driven growth).
- Verified pipeline live: `WolframModelData[]` → 947 rules; SetReplace `WolframModel` evolve-once + `StatesList` generation slicing; `Infrageometry` `VolumeGrowthObservables` → dimension/curvature.
- Scaffolded repo (Phase 0). Wrote `Code/{Tools,Registry,Observables}.wl` and `Scripts/{scrape_registry,build_observables}.wls` (Phases 1–2).
- Scraped registry: 947 rules, 0 skipped.
- Diagnosed/fixed a sweep hang: `CompleteGenerationsCount` (not `GenerationsCount`) for the generation slice; added `MaxEvents` bound + per-rule `SessionTime` budget + per-generation `TimeConstrained`; `EventOrderingFunction` fallback for non-hypergraph rules; silenced benign `LeastSquares::matrix`.
- Validated observables on 30 rules (486 records). Refined growth classification to be trajectory-based; added `AtVertexCount` reliability field and low-confidence filtering in the dimension–curvature map.
- Wrote `Code/{Growth,Visualization,ObservablesTest}.wl` + `Scripts/build_summary.wls` (Phases 3–4). Tests 7/7. Both signature plots render.
- `volumes` now averages over **all** vertices via one `GraphDistanceMatrix` + cumulative `BinCounts` per row (was 20 random centers) — deterministic, tight error bars.
- **Parallel Rebuild Data** (user): `LaunchKernels` + `ParallelMap` over rules, batched (40) with incremental `Export`, resumable (skips rules already having `"Volumes"`); rule/init/URL prefetched on main and distributed (subkernels only need `SetReplace`). Rule Name in the table is now a `Hyperlink` to the rule's registry URL (stored as `"URL"`). Graph-iteration grid uses `GraphicsGrid`. Guarded `fit` fixed the `PseudoInverse` errors; stale-data `Missing` errors are resolved by re-running Rebuild (key is `"Volumes"`).
- Reworked the notebook again (user): title *Ball Volume Growth Characteristics*; sections Initialization / Rebuild Data / Summary Table / Dimension-Curvature Landscape / Individual Characteristics. **Store the geometric-mean ball volume sequence** (not the q-sequence); derive q/dim/curv in the notebook. Guarded `fit` (fixes `PseudoInverse::matrix` on degenerate rules). Summary table: Rule Name, Final State graph, Final Iteration, Final Vertex Count, Vertex Growth, Ball Volume Growths, Log Difference Quotients, per-iteration Dimensions & Curvatures plots; sortable `Dataset`, capped to 15 rows for quick render; data points via `Mesh->All`. Colors: volume/q yellow→red, dimension yellow→green, curvature yellow→purple, vertex growth red. Code formatted multi-line (Export preserves it). Individual Characteristics has separate cells incl. a graph-per-iteration grid.
- Reworked the notebook per user: title *Ball Volume Growth Observables*; only two helpers (`qSequence`, `fit`); q/dimension/curvature at the **geometric mean** of ball volumes; `fit` = faithful port of the paclet's Bishop-Gromov windowed regression; **Summary** table with graph + q(r) + vertex-growth thumbnails, dimension±/curvature±/vertices/vertex-slope; **Dimension-Curvature Landscape** (labelled scatter); **Example** section. Generation colors ramp StandardYellow→Orange→Red, vertex-growth line StandardRed. Filter out registry ids whose `"Rule"` is a `Failure` (fixes the `dimCurvPlot` errors). Store `FinalState` for thumbnails.
- Consolidated to a **single notebook** `BallVolumeGrowth.nb` (per user): one sortable table, a q(r)-overlay section for characteristic rules (extreme dim/curv, all generations with error bars), and a dimension-curvature plane. Storage now keeps q-sequences **per generation** (for the overlays). Added `qPlot`, `characteristicRules`, `dimCurvPlot` inline.
- **Simplified to self-contained notebooks (per user): removed the `Code/` folder entirely.** All logic now inline in each notebook's Initialization cell (load paclets, `universeData`, `qSequence` with `MeanAround` error bars, `dimensionCurvature` simple BG fit, `growth`, `registryTable`). Storage = `Notebooks/universes.wxf` `<|id -> <|VertexCounts, Q|>|>`. Three notebooks (Dimensions/Curvature/Growth) = init + regenerate + itemized columns + sortable table. Deleted obsolete scripts; `generate_notebooks.wls` writes the notebooks.
- Refactored storage (per user): store **raw q-sequences** per universe — `radialQ[MeanAround /@ Transpose@BallVolumes[...]]`, with `Around` error bars — instead of precomputed fits. Ported the paclet's `dimensionCurvature` to `fitDimensionCurvature[qSeq]` (in `Growth.wl`); dimension/curvature now fitted in the notebooks with error bars. Observables keyed per universe (was per `{rule,n}`). Notebooks slimmed to init + regenerate + one sortable `registryTable` Dataset (sorted by dimension/curvature/growth). Tests 8/8.

## 2026-06-18
- Restructured around `AverageBallVolumeGrowths.wxf` (Growths, VertexCounts, EdgeCounts, Diameters,
  FinalState); raised caps to 14 generations / 5000 vertices; full parallel rebuild, then a
  **partial-recovery** pass keeping the cheap early generations of heavy rules (`Partial`). Coverage ~945/947.
- Rewrote the table layer as one `buildTable[data, columns]` (renders a given subset) + `rangeTable`
  (From/To range); bitmap thumbnails (no live-graphics lag), max-only ticks, black mesh dots, error-bar
  fences, em-dash for missing. New columns: Final Generation/Edges, Graph Dimension (log V/log D);
  growth by **diameter trend**; **Stability Score** = 1/(1 + tail diameter of (d,K) over its last third),
  higher = more converged. Queries split into Data query / Table query (Dataset operator forms).
- Slimmed the repo to docs + the notebook's markdown source; data and `.wls` scripts kept local; the
  generated `.nb` is deployed to the Wolfram Cloud (link in README). Added a Conventional Commits hook
  and compactified the git history.
