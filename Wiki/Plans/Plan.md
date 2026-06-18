# Plan & Design

## Goal
Map the infrageometric landscape of the [Wolfram notable universes](https://www.wolframphysics.org/universes/)
as they evolve under generational rewriting — three ways: **horizontal** (statistics across rules),
**evolutional** (across generations), **individual** (one universe).

## Pipeline (local tooling under `Scripts/`, gitignored)
1. `rebuild_all.wls` — evolve each rule with `WolframModel` (caps 14 gen / 5000 vertices / 100000
   events, per-rule time cap); measure the geometric-mean ball-volume growth over all vertices; store
   `<|Growths, VertexCounts, EdgeCounts, Diameters, FinalState|>` to
   `Notebooks/AverageBallVolumeGrowths.wxf`. Parallel, resumable.
2. `retry_failed.wls` — partial recovery of heavy/timed-out rules: keep the generations that fit the
   time budget (flagged `Partial`); atomic saves.
3. `generate_notebooks.wls` — assemble `Notebooks/BallVolumeGrowth.nb` (+ `.md` source) from the
   inline functions in `Scripts/nb/functions.wl`.
4. `deploy_cloud.wls` — build the fully precomputed table and `CloudDeploy` it (public, kernel-free
   paging); the README links to it.

## Observables
- Ball dimension & scalar curvature: Bishop-Gromov windowed fit of q(r) = d log V / d log r, with
  `Around` error bars.
- Graph dimension = log V / log D (whole-graph aspect); a gap vs the ball dimension flags filaments.
- Growth class from the diameter trend; Stability Score from convergence of the (d,K) trajectory.

## TBD
- Multiway / multicomputation observables ([Hypergraph Rewriting Engine](https://github.com/WolframInstitute/HypergraphRewritingEngine),
  [Multicomputation](https://github.com/WolframInstitute/Multicomputation)).
- Deeper evolutional and per-rule views beyond the current Individual Characteristics.
