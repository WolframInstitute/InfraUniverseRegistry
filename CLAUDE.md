# InfraUniverseRegistry

Horizontal infrageometric study across the Wolfram notable-universe registry (~947 rules):
ball-volume growth → dimension and scalar curvature per rule, plus vertex/edge/diameter growth
and a geometric Stability Score. Research/exploratory code. Layout:

- `Code/VolumeGrowth.wl` — shared functions: the windowed Bishop-Gromov fit `fit` (dimension =
  intercept, curvature from slope, with `Around` errors), per-generation `dimcurvSeq`, scalars
  (`dimension`, `curvature`, `graphDimension` = log V / log D, `stabilityScore`, `diameterGrowth`,
  `vertexGrowth`), thumbnail builders, and `tableRow[id, rec]` (one cached table row). Needs
  `WolframInstitute`Infrageometry`` + `SetReplace``.
- `Scripts/` — `VolumeGrowth_Compute.wls` (run `WolframModel`, measure, write
  `Data/AverageVolumeGrowths.wxf`), `VolumeGrowth_CacheTable.wls` (render all rows →
  `Data/table.wxf`, a disposable cache for local browsing — the notebook generator does NOT use
  it), `VolumeGrowth_GenerateNotebooks.wls` (generate the two notebooks, both fully evaluated,
  computing everything from the raw data), `VolumeGrowth_DeployNotebooks.wls` (CloudDeploy them, Public). The two
  `VolumeGrowth_{Table,Single}Init.wl` files are the notebooks' Initialization-cell source,
  embedded verbatim by the generator (kept as real `.wl` so they stay editable, not string literals).
- `Notebooks/` — generated `VolumeGrowth_Table.{nb,md}` and `VolumeGrowth_Single.{nb,md}`.
- `Data/` — gitignored. `AverageVolumeGrowths.wxf` is the measurement source of truth;
  `table.wxf` is the regenerable cache.
- `Wiki/` — plain markdown (`Index.md`, `Status.md`, `Log.md`, `Plans/`, `Resources/`).

## Data

`Data/AverageVolumeGrowths.wxf` (gitignored) :: `<| id -> <|"Growths" (geometric-mean ball-volume
sequence per generation, `Around[mean, std]` where the error is the **standard deviation across
all center vertices** — the spread of V(r), not the precision of the mean), "VertexCounts",
"EdgeCounts", "Diameters", "FinalState", "Partial"|> |>`. (`VolumeGrowth_Compute.wls` measures
`Exp[Around[Mean, StandardDeviation]]` of `Log V(r)` over centers.) Derived scalars and thumbnails
are never stored here — they are recomputed by `tableRow` into the cache `table.wxf`.

## Notebooks (both deployed Public to the Wolfram Cloud)

- **Table** — self-contained, no paclet. Display cells (`landscape[]`, `buildTable[featured]`,
  queries) are **pre-evaluated** (baked output cells) so the cloud renders them immediately; the
  data (two `Uncompress` blobs: `featuredRows` = 20 largest/most-stable rules with big **bitmap**
  thumbnails, and `scalarData` = every rule's scalars) plus the definitions live in a **folded
  Initialization section at the end**. Re-evaluating the notebook gives the live, interactive
  `Dataset`. Sections: Dimension-Curvature Landscape · Featured Rules + Queries · (folded) Initialization.
- **Single** — one example rule via `Code/VolumeGrowth.wl`, generated **fully evaluated** (input +
  output cells) so it renders statically in the cloud. Sections: Initialization · Generations ·
  Volume Growth · Log Difference Quotients · Dimension and Curvature · Vertex and Edge Count and
  Diameter · Geometric Stability (geometry trajectory beside the Cauchy tail).

`VolumeGrowth_GenerateNotebooks.wls` overrides `thumbOpts`/`finalStateThumb` to large sizes for the
20 featured rows. Error bars everywhere are the **standard deviation of ball volume across centers**
(stored directly in the data). The old `AverageVolumeGrowths.sem.wxf` (gitignored backup) holds the
prior SEM-based version; std = `SEM·√N` with N = the generation's vertex count.

## Conventions

- "Stability Score" = `1/(1 + tail diameter)` of the (dimension, curvature) trajectory over its
  last 1/3 of generations; higher = more converged.
- Growth rates (`vertexGrowth`, `diameterGrowth`) are signed least-squares slopes per generation:
  0 static, − shrinking, + expanding.
- Rule URLs: `https://www.wolframphysics.org/universes/<id>/`; the WFR `WolframModelData` page is
  the canonical rule reference.

## Gotcha

`Needs["SetReplace`"]` + `Needs["WolframInstitute`Infrageometry`"]` both define `IndexHypergraph`;
the shadow warning is harmless. Writing files under the Dropbox CloudStorage path can hit `EPERM`
through the editor tools — write via shell heredoc instead.
