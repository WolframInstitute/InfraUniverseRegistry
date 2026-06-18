# InfraUniverseRegistry

Horizontal infrageometric study across the Wolfram Physics universe registry (947 rules):
dimension + curvature per rule, presented as sortable tables. Research/exploratory code.

**Design: there is no `Code/` folder.** All logic lives inline in the notebook's
**Initialization** cell — simple, readable, self-contained. `Scripts/generate_notebooks.wls`
is the only build tool: it writes the single notebook `Notebooks/BallVolumeGrowth.nb`. Keep the
inline code minimal — no defensive wrappers, time budgets, or elaborate window detection.

## What the inline code does

Only **two helper functions** — everything else is inline in the relevant cell.

- `volumes[state]` — builds the graph, computes `GraphDistanceMatrix` **once**, and averages the ball
  volume over **all** vertices as centers: each row's cumulative `BinCounts` is that center's V(r), then
  `Exp[MeanAround[Log[...]]]` per radius gives the geometric-mean sequence with error bars. Deterministic
  (no sampling).
- `fit[q]` — guarded (`Length<2 → Missing`) port of the paclet's Bishop-Gromov fit: linear-core
  window + `q ≈ c₁ + c₂·x`, x=r(r+1) → `{dimension = c₁, curvature = −3(c₁+2)c₂}` as `Around`.
  q itself is the paclet's `LogDifferenceQuotients[volumeSequence]` (computed inline).
- Rebuild cell (inline, **parallel**): `LaunchKernels`, `ParallelEvaluate[Needs["SetReplace`"]]`,
  `DistributeDefinitions[volumes]`, then `ParallelMap` over `Select`-ed valid rules (skip ids whose
  `"Rule"` is a `Failure`), in batches of 40 with `Export` after each (resumable — skips rules that
  already have `"Volumes"`). `WolframModel` `<|MaxGenerations->12, MaxVertices->3000, MaxEvents->30000|>`.
  Stores `<|"VertexCounts", "Volumes" (sequence per generation), "FinalState", "URL"|>`.
  Rule/init/URL are prefetched on the main kernel and distributed, so subkernels never touch the
  resource registry (only need `SetReplace`). Rule Name in the table is a `Hyperlink` to `"URL"`.
- Summary / Landscape / Individual-Characteristics cells (inline). Per generation dimension/curvature
  come from `fit[LogDifferenceQuotients[#]] & /@ Volumes`. Colors: volume growth & q(r) ramp
  `StandardYellow → StandardRed` over generations; dimension-per-iteration `Yellow → Green`;
  curvature-per-iteration `Yellow → Purple`; vertex growth solid `StandardRed`. `Mesh -> All` marks data points.

## Storage

`Notebooks/universes.wxf` (gitignored) :: `<| ruleId -> <|"VertexCounts", "Volumes" (geometric-mean
ball-volume sequence per generation), "FinalState"|> |>` — raw data, written by Rebuild/`rebuild_all.wls`.
`Notebooks/summary.wxf` (gitignored, cache) :: `<| ruleId -> <|"Rule","Dimension","Curvature",
"Vertices","Iterations","Stability"|> |>` — derived per-rule scalars for the Landscape + Queries,
written by `build_summary.wls`/Rebuild, read by Init (instant; recomputing all 875 takes ~90 s).
`Stability` = the Cauchy tail diameter of the (d,K) trajectory (smaller = more converged).
Rule URLs are constructed from the id: `https://www.wolframphysics.org/universes/<id>/`. WXF =
Wolfram binary serialization. q(r)/dimension/curvature/thumbnails are recomputed from `Volumes`, never stored.

## Table columns

Rule · Dimension (±) · Curvature (±) · MaxVertices (confidence: small = unreliable) · Growth.

## Dependencies & gotcha

`Needs["SetReplace`"]`, `Needs["WolframInstitute`Infrageometry`"]`. If a bare kernel pre-creates
`Global`WolframModel`, it shadows `SetReplace`WolframModel` — `Remove["Global`WolframModel"]` then
re-`Needs`, or use `SetReplace`WolframModel`. (In the notebook front end this does not arise.)

## Wiki

`Wiki/` is plain markdown: `Index.md`, `Status.md`, `Log.md`, `Plans/`, `Resources/`.
