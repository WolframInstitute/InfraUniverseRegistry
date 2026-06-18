# InfraUniverseRegistry — infrageometry across the Wolfram Physics universe registry

## Context

We want to measure **infrageometric observables** (volume growth → dimension → scalar
curvature) for *all* notable candidate-universe rules in the Wolfram Physics registry
(https://www.wolframphysics.org/universes/), and run **horizontal** experiments *across*
rules (not a deep vertical study per rule).

The registry is reachable programmatically through `ResourceFunction["WolframModelData"]`.
This repo is currently empty (only `.claude/`). We mirror the proven structure of the
sibling `InfraElements` project (README, CLAUDE.md, `Code/ Scripts/ Wiki/ Notebooks/`,
cloud-published notebooks).

### Feasibility — already verified live
- `WolframModelData[]` → **947 rule short-codes** (`wm3382`, …).
- `WolframModelData[id, prop]` gives `Rule`, `InitialCondition`, `RuleSignature`,
  `RuleComplexity`, `RuleNodeCounts`, `MaximumArity`, `DocumentationLink`
  (a cloud notebook `…/wolfram-universe-registry/universes/<id>`).
- `Needs["SetReplace`"]` → `WolframModel[rule, init, n]` evolves; `"FinalState"` → connected graph.
- `Needs["WolframInstitute`Infrageometry`"]` already provides every observable we need:
  - `BallVolumes`, `ShellAreas`, `LogDifferenceQuotients`
  - `VolumeGrowthObservables[g, centers]` → per-center assoc with
    `BallDimension`, `BallScalarCurvature`, `SphereDimension`, `SphereScalarCurvature`,
    `BallLogDifferenceQuotients`, `BallWindow`, … (Bishop-Gromov windowed fit).
  - `OllivierRicciCurvature`, `FormanRicciCurvature` (kept as secondary cross-checks).
- End-to-end check: `wm3382`, 12 gens → 2026-vertex connected graph → BallDimension ≈ 4.17,
  scalar curvature ≈ 0.32, ~13 s for 40 centers. **No new geometry needs to be invented** —
  this is orchestration, data management, and presentation.

### Decisions (confirmed with user)
- **Sampling**: evolve every generation `n = 1,2,3,…` with an **adaptive stop**
  (vertex cap, generation cap, or system death/fixed-point). Subsumes "5 sizes" and
  "n=1..10". Memoize per `(ruleId, n)`; dataset is extendable later.
- **Dimension & curvature estimator**: `VolumeGrowthObservables` windowed linear fit
  (intercept = dimension, slope = scalar curvature, same fit) evaluated at the **largest
  reliable generation**. Also store `Max[q]` alongside for comparison.

### Reproducibility (pinned)
Every stored observable must be **byte-for-byte regenerable**. Two sources of nondeterminism
exist and are both pinned:
- **Evolution order.** Drive `WolframModel` with an explicit deterministic event-ordering
  function — `"EventOrderingFunction" -> {"LeastRecentEdge", "RuleOrdering", "RuleIndex"}`
  (the standard sorted ordering). The ordering string is recorded in every record
  (`"EventOrderingFunction"`) so a future change of default cannot silently alter results.
- **Center sampling.** Centers are chosen by `SeedRandom[seed]` immediately followed by
  `RandomSample[VertexList[g], UpTo[centers]]` with a fixed module-level `seed`. The seed is
  recorded (`"CenterSeed"`). `UpTo` makes small graphs (fewer vertices than `centers`) safe.
- **Disconnectedness.** `VolumeGrowthObservables` assumes a connected graph. If the final
  state is disconnected we compute on the **largest connected component**
  (`First@SortBy[ConnectedGraphComponents[g], -VertexCount[#] &]`), recording `"Connected"`,
  `"ComponentCount"`, and `"UsedComponentVertexCount"`. Centers are sampled from that
  component only.

---

## Data model (the one thing everything derives from)

A single **long, memoized** association saved to disk, keyed `{ruleId, n}`:

```
Data/observables.wxf :: <| {ruleId, n} -> <|
    "VertexCount" -> _, "EdgeCount" -> _, "Connected" -> _Boolean,
    "ComponentCount" -> _Integer, "UsedComponentVertexCount" -> _Integer,
    "Generations" -> n, "Centers" -> _Integer,
    "MeanBallVolumes" -> {V0,V1,...},      (* averaged over sampled centers *)
    "MeanShellAreas"  -> {A0,A1,...},
    "MeanBallLogDiffQuotient" -> {q1,q2,...},
    "BallDimension" -> _, "BallScalarCurvature" -> _,
    "SphereDimension" -> _, "SphereScalarCurvature" -> _,
    "MaxQ" -> _,                            (* secondary dimension estimator *)
    "Window" -> {rmin,rmax},
    (* reproducibility / provenance *)
    "EventOrderingFunction" -> {"LeastRecentEdge","RuleOrdering","RuleIndex"},
    "CenterSeed" -> _Integer,
    "TerminationReason" -> _String          (* from the evolution object, see below *)
  |> |>
```

Plus a static metadata table:

```
Data/registry.wxf :: <| ruleId -> <| "Rule","InitialCondition","RuleSignature",
    "RuleComplexity","MaximumArity","RuleNodeCounts","DocumentationLink",
    "Skipped" -> _Boolean, "SkipReason" -> _String |> |>
```

Both written **incrementally** (resumable batch). Extending = compute more `n` or more
rules and merge. Graphs are *not* stored (regenerable from rule+init+n under the pinned
event ordering); compact thumbnails are cached on demand in `Data/thumbnails/`.

### Evolve once, slice generations
Do **not** re-evolve per `n`. Evolve once to the cap into a single
`WolframModelEvolutionObject`, then extract the generation-`n` hypergraph for each `n` from
that one object (its generation-indexed state). One evolution instead of N, and every
per-`n` graph is an exact prefix of the same run — eliminating cross-`n` inconsistency.

### Caps and termination
Express the adaptive stop via the WolframModel mixed step spec
`<|"MaxGenerations" -> ~20, "MaxVertices" -> ~4000|>`, wrapped per rule in
`TimeConstrained` / `MemoryConstrained`. Record the evolution object's `"TerminationReason"`
(`MaxGenerations`, `MaxVertices`, `FixedPoint`, `TimeConstraint`, …). This is a *first-class*
field used directly by growth classification — see below — rather than re-derived from
whether `V(n)` looks bounded.

### Derived, per-rule (computed from the long dataset, cached in `Data/summary.wxf`)
- **Growth**: sequence `V(n)`; fit best of {constant, linear, power `r^a`, exponential};
  store `{class ∈ expanding|same|contracting|unclear, formula, exponentOrRate, R2}`.
  Drive the class primarily by `"TerminationReason"`:
  `FixedPoint` ⇒ `same`/`contracting` (evolution froze/died, bounded V);
  `MaxVertices`/`MaxGenerations` ⇒ `expanding` (hit a cap while still growing);
  `TimeConstraint` ⇒ `unclear` (capped before a verdict);
  ambiguous fits within caps ⇒ `unclear`.
- **Dimension / Curvature**: `BallDimension`/`BallScalarCurvature` at the largest reliable `n`
  (+ stability flag: did it plateau across the last few generations?).

---

## Repo structure (mirrors InfraElements)

```
README.md, CLAUDE.md, .gitignore
Code/
  Tools.wl            shared utilities, loaders (Needs SetReplace + Infrageometry)
  Registry.wl         rule metadata access over WolframModelData
  Observables.wl      RuleGraph[id,n], RuleObservables[id,n], adaptive sweep, memo I/O
  Growth.wl           growth classification + formula fitting
  Visualization.wl    the three revised plotting functions (below)
  ObservablesTest.wl  VerificationTest + TestReport on a small rule sample
Scripts/
  scrape_registry.wls    947 rules' metadata -> Data/registry.wxf + Wiki table
  build_observables.wls  resumable batch -> Data/observables.wxf (caps, parallel kernels)
  build_summary.wls      observables -> Data/summary.wxf (growth, dim, curv per rule)
  publish_notebooks.wls  deploy cloud notebooks (InfraElements pattern)
  download_notebooks.wls (optional) fetch DocumentationLink notebooks -> Wiki md
Data/                  (gitignored heavy data) registry.wxf observables.wxf summary.wxf thumbnails/
Notebooks/             generated .nb (sources in NotebooksLLM/ markdown, via new-notebook skill)
Wiki/                  Index.md Status.md Log.md Plans/ Concepts/ Resources/
```

---

## The three plotting functions to (re)write — `Code/Visualization.wl`

1. **`LogDiffQuotientPlot[id]`** — per-rule diagnostic. Overlay the mean log-difference
   quotient `q(r)` curves for all available generations `n` of that rule (pastel,
   light→dark by `n`), with the fitted dimension level and fit window shaded. This is the
   "log difference of averaged ball-volume growth across sizes" plot.

2. **`DimensionCurvatureScatter[summary]`** — the master horizontal view. `x = BallDimension`,
   `y = BallScalarCurvature`, one point per rule, `Tooltip`/hover → graph thumbnail +
   `LogDiffQuotientPlot` mini. Labeled, color-coded by growth class.

3. **`RuleDimension[id] / RuleCurvature[id]`** — the estimator extraction (the "from the max?"
   question): windowed-fit value at largest reliable `n`, with `MaxQ` exposed as alternative.

Plus grid builders `DimensionGrid[summary, {lo,hi}]` and `CurvatureGrid[summary, {lo,hi}]`
for the binned-section notebooks.

---

## Presentation — cloud notebooks (built via `new-notebook` skill, published like InfraElements)

1. **`Overview.nb`** — main artifact: `DimensionCurvatureScatter` with hover thumbnails +
   log-diff-quotient mini-plots; summary of method.
2. **`Growth.nb`** — growth classification: expanding / same / contracting / unclear sections,
   each a grid of rule thumbnails + fitted formula; a `V(n)` overlay.
3. **`Dimensions.nb`** — sections `[0,1) [1,2) [2,3) …`, each a grid of rule thumbnails + values.
4. **`Curvature.nb`** — sections by curvature bins (negative / ~0 / positive), grids.

(Per-rule diagnostic notebooks are generated *on demand*, not 947 static files — this repo is horizontal.)

---

## Build phases (validate-then-scale)

- **Phase 0 — Scaffold.** README, CLAUDE.md (note deps: SetReplace, Infrageometry paclet),
  dirs, Wiki skeleton (Index/Status/Log/Plans/Concepts/Resources), `.gitignore` Data/.
- **Phase 1 — Registry.** `Code/Registry.wl` + `scrape_registry.wls` → `Data/registry.wxf`
  (947 rules) + a Wiki markdown table. Cheap, immediate. Rules with missing or over-large
  `"InitialCondition"` are recorded with `"Skipped" -> True` and a `"SkipReason"` so the
  observable batch can skip them and the counts reconcile.
- **Phase 2 — Observables core + validate on ~30 rules.** `Code/Observables.wl`
  (`RuleGraph`, `RuleObservables`, evolve-once sweep, largest-component handling, memo
  merge/save) + `ObservablesTest.wl`. Tune caps: maxVertices ≈ 4000, genCap ≈ 20,
  centers ≈ 30 (sample), per-rule timeout. Confirm dimension/curvature/growth look sane on
  the sample and that records carry `EventOrderingFunction`, `CenterSeed`, `TerminationReason`.
- **Phase 3 — Growth.** `Code/Growth.wl` classification (termination-reason driven) + formula
  fitting; `build_summary.wls`.
- **Phase 4 — Visualization + notebooks.** The three functions + grids; build
  `Overview/Growth/Dimensions/Curvature` notebooks from sample data.
- **Phase 5 — Scale.** Run `build_observables.wls` over all 947 in background (parallel
  kernels, incremental WXF, resumable); rebuild summary; regenerate + publish notebooks.
- **Phase 6 — (optional) Notebook scraping.** `download_notebooks.wls` pulls per-rule
  DocumentationLink notebooks → Wiki md.

### Performance / caps
~13 s per 2000-vertex graph (40 centers). With 30 centers + adaptive checkpoints, ~30–90 s/rule
→ full 947 ≈ several hours single-thread; use `ParallelMap`/`LaunchKernels` + incremental save.
Caps prevent explosive rules from stalling the batch; the cap that fired is recorded as
`TerminationReason` and feeds the growth classification (`expanding`/`unclear`).

---

## Verification

All kernel-dependent verification runs in the **user's local Wolfram environment** (the
remote planning container has no kernel/paclets).

- **Pipeline (live, already passing):** load both paclets, evolve `wm3382`, build graph,
  `VolumeGrowthObservables` → finite BallDimension & curvature.
- **`ObservablesTest.wl`** via `TestReport`: on a 5-rule fixture — graph connected (or
  largest-component selected), ball volumes monotone non-decreasing, dimension/curvature
  finite, memo round-trips through WXF.
- **Reproducibility:** re-running a fixed `(ruleId, n)` with the recorded
  `EventOrderingFunction` + `CenterSeed` yields **identical** observables; every stored
  record has a non-empty `TerminationReason`.
- **Spot checks:** a rule known to look ~3D should land near dimension 3 in `Overview.nb`;
  grids in `Dimensions.nb`/`Curvature.nb` populate every bin that has members; growth classes
  partition all rules.
- **Data integrity:** `registry.wxf` has 947 entries; `observables.wxf` is resumable
  (re-running the batch skips computed `(ruleId,n)` and only fills gaps); the set of observed
  rules plus the `Skipped` rules reconciles to the full 947.
