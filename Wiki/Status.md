# Status

A single self-contained notebook plus its data. **All logic lives inline in the notebook's
Initialization cell.** The build/rebuild/deploy scripts under `Scripts/` are local tooling
(gitignored) and the data lives locally (gitignored). The canonical repo carries only the
markdown docs and the notebook's markdown source; the generated `.nb` is deployed to the
Wolfram Cloud and linked from the README.

## Notebook — *Ball Volume Growth Characteristics*
Source: `Notebooks/BallVolumeGrowth.md`. Sections:
- **Initialization** — loads the data, defines inline functions (`fit`, `dimcurvSeq`,
  `dimension`/`curvature` + errors, `stabilityScore`, `finalDiameter`, `graphDimension`,
  `growthClass`, `scalars`, `graphOf`, `buildTable`, `rangeTable`).
- **Summary Table** — `rangeTable[data, defaultColumns]`: pick a rule range (From/To); only those
  rows render (bitmap thumbnails). Columns: Rule · Final State · Final Generation · Final Vertex
  Count · Final Edge Count · Final Graph Diameter · Graph Growth · Graph Dimension · Ball Growth
  Dimension · Ball Growth Curvature · Stability Score · per-iteration plots (Vertex Growth, Ball
  Volume Growth, Log Diff Quotients, Dimensions, Curvatures).
- **Queries** — Data query (functions computed live on the data) and Table query (cached table),
  via `Dataset` operator forms.
- **Dimension-Curvature Landscape** — one point per rule, colored by vertex count.
- **Individual Characteristics** — one rule: graph per iteration, volume growth, log-diff
  quotients, dimension & curvature per iteration (fit error bars), vertex growth, the (d,K)
  trajectory, and the Cauchy tail-diameter stability plot.

## Measurement
- **Data** `Notebooks/AverageBallVolumeGrowths.wxf` (local) ::
  `<|id -> <|Growths, VertexCounts, EdgeCounts, Diameters, FinalState|>|>`. `Growths` =
  geometric-mean ball-volume sequence per generation, averaged over **all** vertices via one
  `GraphDistanceMatrix` + cumulative `BinCounts` (`Around` error bars, deterministic).
- **Evolution** `WolframModel`, caps 14 generations / 5000 vertices / 100000 events, per-rule time
  cap; parallel, resumable. Heavy rules are kept **partial** (truncated to the generations that fit
  the time budget, flagged `Partial`).
- **Observables** dimension & curvature from the Bishop-Gromov **windowed fit** of
  q(r) = d log V / d log r (`Around` error bars). **Graph Dimension** = log V / log D (whole-graph).
  **Growth** = diameter trend (expanding / static / contracting). **Stability Score** =
  1/(1 + tail diameter of the (d,K) trajectory over its last third); higher = more converged.
- **Coverage** 947 rules; ~945 with geometry (~150 partial); a few still time out.

## Repo layout
- Committed: README, this Wiki, `CLAUDE.md`, `Notebooks/BallVolumeGrowth.md`, `.githooks/commit-msg`.
- Local only (gitignored): `Notebooks/*.wxf` (data), `Notebooks/*.nb` (generated), `Scripts/` (tooling).
