# InfraUniverseRegistry

Horizontal infrageometric study across the Wolfram notable-universe registry (~947 rules):
ball-volume growth → dimension and scalar curvature per rule, plus vertex/edge/diameter growth
and a geometric Stability Score. Research/exploratory code. Layout:

- `Code/VolumeGrowth.wl` — shared functions: the windowed Bishop-Gromov fit `fit` (dimension =
  intercept, curvature from slope, with `Around` errors), per-generation `dimcurvSeq`, scalars
  (`dimension`, `curvature`, `graphDimension` = log V / log D, `stabilityScore`, `diameterGrowth`,
  `vertexGrowth`), thumbnail builders, and `tableRow[id, rec]` (one cached table row). Needs
  `WolframInstitute`Infrageometry`` + `SetReplace``.
- `Scripts/` — `VolumeGrowth_BuildData.wls` (run `WolframModel`, measure, write
  `Data/AverageVolumeGrowths.wxf`), `VolumeGrowth_BuildTable.wls` (render all rows →
  `Data/table.wxf`, the disposable cache), `VolumeGrowth_Notebooks.wls` (generate the two
  notebooks, fully evaluated), `VolumeGrowth_Deploy.wls` (CloudDeploy them, Public). The two
  `nb_*_init.wl` files are the notebooks' Initialization-cell source.
- `Notebooks/` — generated `VolumeGrowth_Table.{nb,md}` and `VolumeGrowth_Single.{nb,md}`.
- `Data/` — gitignored. `AverageVolumeGrowths.wxf` is the measurement source of truth;
  `table.wxf` is the regenerable cache.
- `Wiki/` — plain markdown (`Index.md`, `Status.md`, `Log.md`, `Plans/`, `Resources/`).

## Data

`Data/AverageVolumeGrowths.wxf` (gitignored) :: `<| id -> <|"Growths" (geometric-mean ball-volume
sequence per generation, `Around` with error bars), "VertexCounts", "EdgeCounts", "Diameters",
"FinalState", "Partial"|> |>`. Derived scalars and thumbnails are never stored here — they are
recomputed by `tableRow` into the cache `table.wxf`.

## Notebooks (both deployed Public to the Wolfram Cloud)

- **Table** — self-contained, no paclet at view time. Initialization embeds two `Uncompress`
  blobs: `featuredRows` (the 20 largest, most stable rules, with big hypergraph thumbnails) and
  `scalarData` (every rule's scalars). Sections: Initialization · Dimension-Curvature Landscape
  (`landscape[]`, hover for rule) · Featured Rules (`buildTable[featured]`) + Queries (on all rules).
- **Single** — one example rule via `Code/VolumeGrowth.wl`. Sections: Initialization · Generations ·
  Volume Growth · Log Difference Quotients · Dimension and Curvature · Vertex and Edge Count and
  Diameter · Geometric Stability (geometry trajectory beside the Cauchy tail).

Notebooks are generated **fully evaluated** (input + output cells) so they render statically in
the cloud. `VolumeGrowth_Notebooks.wls` overrides `thumbOpts`/`finalStateThumb` to large sizes
for the 20 cloud rows.

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
