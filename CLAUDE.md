# InfraUniverseRegistry

## Related repos

This repo vendors no git submodules.
The sibling repos are **not** cloned into this tree and must never be — a vendored copy
goes stale and then two versions of the same paclet disagree. Read them in place at the
paths below.

| Paclet | Repo, relative to this one | Paclet dir inside it |
|---|---|---|
| Infrageometry | `../../SubProjectsMain/Infrageometry/` | `Infrageometry/Infrageometry/` |
| SyntheticInfrageometry | `../../SubProjectsMain/SyntheticInfrageometry/` | `SyntheticInfrageometry/SyntheticInfrageometry/` |
| InfraAnalysis | `../../SubProjectsOther/InfraAnalysis/` | `InfraAnalysis/InfraAnalysis/` |
| InfraCausality | `../../SubProjectsOther/InfraCausality/` | `InfraCausality/InfraCausality/` |
| InfraGaugeTheory | `../../SubProjectsOther/InfraGaugeTheory/` | `InfraGaugeTheory/` |
| InfraElements | `../InfraElements/` | — *public paclet repo directly, no `Dev` wrapper* |

To use another paclet, prefer the **installed** copy — all of them are in
`~/Library/Wolfram/Paclets/Repository/`, so a plain load works with no path at all:

```wolfram
Needs["WolframInstitute`Infrageometry`"]
```

Reach for a dev checkout only when you need changes that are not published yet, and then
point at the sibling path rather than copying it here:

```wolfram
PacletDirectoryLoad @ FileNameJoin[ { $repoRoot, "..", "..", "SubProjectsMain", "Infrageometry", "Infrageometry" } ]
```

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
    `curvature` via `DimensionCurvatureFit[q, radii]` with `window = Automatic`, `globalDimension`
    = log V / log R with R = D/2 (half the final diameter), `stabilityScore`, `diameterGrowth`, `vertexGrowth`) + baked thumbnails;
    `volumeGrowthScalars[rec]` the per-rule scalars, `buildExampleData[raw, ids]` the formatted
    featured rows. Pure data/thumbnails — the Table's **display code** (landscape, table, queries)
    now lives in the Table `.md`, not here. `thumbOpts`/`finalStateThumb` are overridable.
  - `GenerateVolumeGrowthNotebooks.wls` — **the `.md` files are the single source of truth.** Reads
    `Notebooks/VolumeGrowth_{Table,Single}.md`, parses them into cells, evaluates the code (so the
    `.nb` is fully baked), and **injects** what markdown can't carry — the Table data blob and every
    Output cell. Emits only `.nb`. Markdown conventions: fence tags ` ```wolfram init|run|eval|bake|inject:KEY `
    (plain = unevaluated Input) and `## Heading {closed}` for a folded cell group. For Table it Gets
    BuildVolumeGrowthTable, computes/caches `allRules`+`exampleData`, and injects them at the
    `inject:data` placeholder. Usage: `wolframscript -file GenerateVolumeGrowthNotebooks.wls [Table|Single]`
    — no arg builds both. A `Table` run is a cache hit (seconds); a `Single` run does the live wm3382
    recompute (minutes). **Never hand-edit the `.nb`** — edit the `.md` and regenerate, or the change is lost.
  - `DeployVolumeGrowthNotebooks.wls` — CloudDeploy both notebooks, Public.
- `Notebooks/` — **source** `VolumeGrowth_{Table,Single}.md` (hand-edited) and **generated**
  `VolumeGrowth_{Table,Single}.nb`.
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

## Notebooks (both deployed Public to the Wolfram Cloud, generated from their `.md` source)

- **Table** — self-contained, no paclet. Display cells (landscape, table, queries — `eval` fences
  in the md) are **pre-evaluated** (baked output cells) so the cloud renders them immediately; the
  data (two `Uncompress` blobs: `exampleData` = 20 example rules with big **bitmap** thumbnails, and
  `allRules` = every rule's scalars) lives in a **folded Initialization section** ( `{closed}` ),
  injected at the `inject:data` fence. The Init section also holds local-only **rebuild cells**
  (plain Input, not evaluated) that shell out via wolframscript. Re-evaluating the notebook gives the
  live, interactive `Dataset`. Sections: (folded) Initialization · Dimension-Curvature Landscape ·
  Example Rules · Queries.
- **Single** — one rule computed live from the paclet (`Hypergraph2Section` + `BallVolumes` +
  `DimensionCurvatureFit`), generated **fully evaluated** (`run` cells set up state, `eval` cells
  bake plots) so it renders statically in the cloud. The rule (wm3382) is a literal in the md.
  Sections: Initialization · Generations · Volume Growth · Log Difference Quotients · Dimension and
  Curvature · Vertex and Edge Count and Diameter · Dimension-Curvature Stability.

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
- The old `IndexHypergraph` shadow warning between `SetReplace`` and `WolframInstitute`Infrageometry``
  is gone: Infrageometry no longer exports that symbol (inlined into `IndexComplex`, 2026-08-22), so
  `IndexHypergraph` unambiguously means SetReplace's (sorted) version. The two paclets now share no
  export names at all. Needs an Infrageometry newer than that date.
- Writing files under the Dropbox CloudStorage path can hit `EPERM` through the editor tools — write
  via shell heredoc instead.
- When (re)generating a `.md` source programmatically in a kernel, build the code-fence backticks from
  `FromCharacterCode[96]` (the generator's `tq`); a literal triple-backtick can be corrupted in transit
  through some agent tooling, silently breaking the fence and the parser.
