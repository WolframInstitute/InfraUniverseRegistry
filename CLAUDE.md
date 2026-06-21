# InfraUniverseRegistry

Horizontal infrageometric study across the Wolfram notable-universe registry (~947 rules):
ball-volume growth → dimension and scalar curvature per rule, plus vertex/edge/diameter growth
and a geometric Stability Score. Research/exploratory code. The project is **only `.wls` scripts
and notebooks** — no `Code/` dir, no `.wl` library files; all reusable geometry comes from the
`WolframInstitute`Infrageometry`` paclet (`Hypergraph2Section`, `BallVolumes`,
`LogDifferenceQuotients`, `DimensionCurvatureFit`). Layout:

- `Scripts/`
  - `ComputeVolumeGrowths.wls` — evolve every rule (`WolframModel`), measure the averaged
    ball-volume growth from the paclet (`Hypergraph2Section` + `BallVolumes "Counting"`), write
    `Data/AverageVolumeGrowths.wxf`. Parallel, resumable, atomic saves.
    Usage: `wolframscript -file ComputeVolumeGrowths.wls [nRules]`.
  - `BuildVolumeGrowthTable.wls` — **Get-loaded, not run.** Per-rule scalars (`dimension`,
    `curvature` via `DimensionCurvatureFit[q, radii]` with `window = Automatic`, `graphDimension`
    = log V / log D, `stabilityScore`, `diameterGrowth`, `vertexGrowth`) + baked thumbnails;
    `buildVolumeGrowthTable[raw, ids, columns]` builds row data for chosen rules/columns and
    `volumeGrowthScalars[rec]` the per-rule scalars. Also holds the Table notebook's **paclet-free
    display block** between `(* DISPLAY-BEGIN *)` / `(* DISPLAY-END *)` markers (`landscape`,
    `buildTable`, `queryData`, `row`, `headerTips`, `defaultColumns`), which the generator lifts
    out verbatim into the notebook.
  - `GenerateVolumeGrowthNotebooks.wls` — generate both notebooks fully evaluated. Gets
    BuildVolumeGrowthTable.wls; bakes `featuredRows` + `scalarData` (compressed) and the display
    block into the Table notebook; emits the Single notebook from an inline init string.
  - `DeployVolumeGrowthNotebooks.wls` — CloudDeploy both notebooks, Public.
- `Notebooks/` — generated `VolumeGrowth_Table.{nb,md}` and `VolumeGrowth_Single.{nb,md}`.
- `Data/` — gitignored. `AverageVolumeGrowths.wxf` is the measurement source of truth.
- `Wiki/` — plain markdown (`Index.md`, `Status.md`, `Log.md`, `Plans/`, `Resources/`).

## Data

`Data/AverageVolumeGrowths.wxf` (gitignored) :: `<| id -> <|"Growths" (per-generation ball-volume
sequence, geometric mean over centers `Exp[MeanAround[Log V(r)]]` = mean ± standard error of the
mean σ/√n, used for the log-difference quotients / dimension-curvature fit), "VolumeMeans" (same
sequence as arithmetic mean ± standard deviation `Around[Mean, StandardDeviation]`, used for the
volume-growth plots), "VertexCounts", "EdgeCounts", "Diameters", "FinalState", "Partial"|> |>`.
Derived scalars and thumbnails are never stored — `BuildVolumeGrowthTable.wls` recomputes them at
generation time.

## Notebooks (both deployed Public to the Wolfram Cloud)

- **Table** — self-contained, no paclet. Display cells (`landscape[]`, `buildTable[featured]`,
  queries) are **pre-evaluated** (baked output cells) so the cloud renders them immediately; the
  data (two `Uncompress` blobs: `featuredRows` = 20 largest/most-stable rules with big **bitmap**
  thumbnails, and `scalarData` = every rule's scalars) plus the display block live in a **folded
  Initialization section at the end**. Re-evaluating the notebook gives the live, interactive
  `Dataset`. Sections: Dimension-Curvature Landscape · Featured Rules + Queries · (folded) Initialization.
- **Single** — one rule computed live from the paclet (`Hypergraph2Section` + `BallVolumes` +
  `DimensionCurvatureFit`), generated **fully evaluated** (input + output cells) so it renders
  statically in the cloud. Sections: Initialization · Generations · Volume Growth · Log Difference
  Quotients · Dimension and Curvature · Vertex and Edge Count and Diameter · Dimension-Curvature
  Stability (geometry trajectory beside the Cauchy tail).

`GenerateVolumeGrowthNotebooks.wls` overrides `thumbOpts`/`finalStateThumb` to large sizes for the
20 featured rows.

## Conventions

- Dimension/curvature: `DimensionCurvatureFit[LogDifferenceQuotients[vol], Range[Length[q]]]` —
  Bishop-Gromov fit of the index-based log-difference quotients with `window = Automatic`
  (linear-core auto-select); `Around`-valued volumes carry their spread to `Around` d / R.
- "Stability Score" = `1/(1 + tail diameter)` of the (dimension, curvature) trajectory over its
  last 1/3 of generations; higher = more converged.
- Growth rates (`vertexGrowth`, `diameterGrowth`) are signed least-squares slopes per generation:
  0 static, − shrinking, + expanding.
- Rule URLs: `https://www.wolframphysics.org/universes/<id>/`; the WFR `WolframModelData` page is
  the canonical rule reference.

## Gotcha

- `DimensionCurvatureFit[q, radii, window]` (window auto-select) needs a paclet version that ships
  that 3-arg signature; `Needs` loads the **highest** installed `WolframInstitute__Infrageometry-*`,
  so make sure the highest one has it (not an older shadowing build).
- `Needs["SetReplace`"]` + `Needs["WolframInstitute`Infrageometry`"]` both define `IndexHypergraph`;
  the shadow warning is harmless.
- Writing files under the Dropbox CloudStorage path can hit `EPERM` through the editor tools — write
  via shell heredoc instead.
