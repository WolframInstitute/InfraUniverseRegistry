# Volume Growth: Table

## Initialization {closed}

Baked below: allRules — scalar metrics (dimension, scalar curvature, growth rates, stability score) for every rule in the registry; exampleData — fully-formatted display rows for every rule, with thumbnails for the 20 example rules and a dash in each thumbnail column elsewhere.

The cells below rebuild this notebook from source. They shell out to wolframscript and read or write the Data/ folder, so they only work on a local checkout next to the Scripts/ folder — not in the cloud.

Load the raw measurements into raw — the per-rule ball-volume growth, vertex, edge and diameter counts, and final states from which every scalar and thumbnail is derived:

```wolfram
raw = Import[FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Data", "AverageVolumeGrowths.wxf"}]];
Keys[First[raw]]
```

Recompute the ball-volume growth for every rule — re-evolves the whole registry and rewrites Data/AverageVolumeGrowths.wxf (slow; parallel and resumable):

```wolfram
RunProcess[{"wolframscript", "-file", FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Scripts", "ComputeVolumeGrowths.wls"}]}]["StandardOutput"]
```

Or measure just a subset — pass the number of rules as an argument to evolve only the first 50 (handy for a quick test):

```wolfram
RunProcess[{"wolframscript", "-file", FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Scripts", "ComputeVolumeGrowths.wls"}], "50"}]["StandardOutput"]
```

Rebuild the notebooks from that data — recomputes the scalars and thumbnails. Pass "Table" for this notebook, "Single" for the single-rule notebook, or omit the argument to rebuild both (Table is seconds, Single is minutes):

```wolfram
RunProcess[{"wolframscript", "-file", FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Scripts", "GenerateVolumeGrowthNotebooks.wls"}], "Table"}]["StandardOutput"]
```

```wolfram inject:data

```

## Dimension-Curvature Landscape

```wolfram eval
With[{pts = Select[{#1, #2["Dimension"], #2["DimensionError"], #2["Curvature"], #2["CurvatureError"], #2["StabilityScore"]} & @@@ Normal[allRules],
     NumericQ[#[[2]]] && NumericQ[#[[4]]] && NumericQ[#[[6]]] &]},
  Module[{ds = pts[[All, 2]], cs = pts[[All, 4]], scores = pts[[All, 6]], dr, cr, inr, cf, col, mk, tip, url, box},
   dr = Quantile[ds, {0.025, 0.975}]; cr = Quantile[cs, {0.025, 0.975}];
   inr = Select[pts, dr[[1]] <= #[[2]] <= dr[[2]] && cr[[1]] <= #[[4]] <= cr[[2]] &];
   cf = Blend[{StandardGray, StandardGreen}, #] &;
   col[s_] := cf[Mean @ UnitStep[s - scores]];
   mk[p_, sz_] := {col[p[[6]]], PointSize[sz], Point[{p[[2]], p[[4]]}]};
   url[p_] := "https://www.wolframphysics.org/universes/" <> p[[1]] <> "/";
   tip[p_] := Column[{Style[p[[1]], Bold], Row[{"dim ", Around[p[[2]], p[[3]]], "   curv ", Around[p[[4]], p[[5]]]}],
      Replace[exampleData[p[[1]]]["State"], Except[_?ImageQ] -> Nothing]}, Center];
   box = {Directive[StandardRed, AbsoluteThickness[1.5]], Line[{{dr[[1]], cr[[1]]}, {dr[[2]], cr[[1]]}, {dr[[2]], cr[[2]]}, {dr[[1]], cr[[2]]}, {dr[[1]], cr[[1]]}}]};
   Legended[
     Row[{
       Graphics[{Table[Tooltip[Hyperlink[mk[p, 0.004], url[p]], tip[p]], {p, pts}], box},
         Frame -> True, FrameLabel -> {"Dimension", "Curvature"}, Background -> White, ImageSize -> 380, AspectRatio -> 1/GoldenRatio,
         PlotRange -> {Quantile[ds, {0.002, 0.998}], Quantile[cs, {0.002, 0.998}]}, PlotRangeClipping -> True,
         PlotLabel -> Style["all rules", 12]],
       Spacer[20],
       Graphics[Table[Tooltip[Hyperlink[mk[p, 0.006], url[p]], tip[p]], {p, inr}],
         Frame -> True, FrameLabel -> {"Dimension", "Curvature"}, PlotRange -> {dr, cr}, Background -> White,
         ImageSize -> 640, AspectRatio -> 1/GoldenRatio,
         PlotLabel -> Style["central 95%", 12]]}],
     BarLegend[{cf, {0, 1}}, LegendLabel -> "Stability Rank", LegendMarkerSize -> 200]]]]
```

## Example Rules

```wolfram eval
Dataset[ Values @ exampleData, Alignment -> { Center, Center }, MaxItems -> { All, All }, ItemStyle -> { FontSize -> 15 }, HeaderStyle -> Directive[ FontSize -> 15, Bold ] ]
```

## Queries

### Largest, most stable rules: top 20 by stability score × vertex count.

```wolfram eval
Dataset[allRules][Select[NumericQ[#StabilityScore] && NumericQ[#Vertices] &]][TakeLargestBy[#StabilityScore #Vertices &, 20]]
```

### Dimension 2.5-3.5, near-flat curvature, at least 1000 vertices.

```wolfram eval
Dataset[allRules][Select[NumericQ[#Dimension] && 2.5 <= #Dimension <= 3.5 && Abs[#Curvature] < 0.5 && #Vertices >= 1000 &]]
```

### Most converged large rules.

```wolfram eval
Dataset[allRules][Select[#Vertices >= 500 && NumericQ[#StabilityScore] &]][TakeLargestBy["StabilityScore", 25]]
```

### Recommended ranking: stability score times sqrt(vertices).

```wolfram eval
Dataset[allRules][ReverseSortBy[#StabilityScore Sqrt[#Vertices] &]][;; 25]
```

### Fastest-expanding rules (by diameter growth).

```wolfram eval
Dataset[allRules][TakeLargestBy["DiameterGrowth", 15]]
```
