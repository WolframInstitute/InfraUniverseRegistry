# Status

**Self-contained notebooks; no `Code/` folder.** All logic is inline in each notebook's
Initialization cell. `Scripts/generate_notebooks.wls` writes the three notebooks.

- **One notebook** `BallVolumeGrowth.nb` (title *Ball Volume Growth Characteristics*): Initialization
  (helpers `volumes` + `fit`) · Rebuild Data (inline, valid rules only) · Summary Table (sortable
  `Dataset`, capped to 15 rows: Rule Name, Final State graph, Final Iteration, Final Vertex Count,
  Vertex Growth, Ball Volume Growths, Log Difference Quotients, per-iteration Dimensions & Curvatures
  plots) · Dimension-Curvature Landscape (labelled scatter) · Individual Characteristics (graph-per-
  iteration grid + volume/LDQ/dim-curv/vertex-growth example cells). All validated by rendering.
- Stored observable = **geometric-mean ball volume sequence** per generation, averaged over **all**
  vertices via one `GraphDistanceMatrix` + cumulative `BinCounts` (`Around` error bars; deterministic);
  q/dimension/curvature derived via the paclet's Bishop-Gromov fit (`fit` guarded against short input).
- **Rebuild is parallel** (`ParallelMap`, batched, resumable); Rule Name links to the registry URL.
- Colors: volume & q(r) yellow→red; dimension yellow→green; curvature yellow→purple; vertex growth red.
- **Storage**: `Notebooks/universes.wxf` (gitignored) :: `<|ruleId -> <|VertexCounts, Volumes (per gen), FinalState|>|>`.
- **Fits in the notebook**: simple Bishop-Gromov linear fit of the stored q-sequence; dimension &
  curvature come out as `Around` (error bars).

**Next:** run the Regenerate cell with `wmd[]` (all 947, multi-hour) to populate `universes.wxf`,
then the tables show the full registry.

**History:** an earlier elaborate `Code/`-folder pipeline (per-center fits, time budgets, grids,
scatter) was replaced by this minimal inline design at the user's request. See Log.
