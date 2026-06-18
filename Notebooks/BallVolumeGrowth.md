# Ball Volume Growth Characteristics

## Initialization

```wolfram
Needs["WolframInstitute`Infrageometry`"];
dataFile = FileNameJoin[{NotebookDirectory[], "AverageBallVolumeGrowths.wxf"}];
data = Select[Replace[Import[dataFile], Except[_Association] -> <||>], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
exId = "wm3382";

url[id_] := "https://www.wolframphysics.org/universes/" <> id <> "/";
ruleLink[id_] := Hyperlink[id, url[id]];
strip = # /. Around[a_, _] :> a &;
numQ = NumericQ[# /. Around[a_, _] :> a] &;

fit[q_] :=
  If[Length[q] < 2, {Missing[], Missing[]},
   Module[{cv = strip[q], k = Length[q], x, rs, mat, c},
    x = N[Range[k] (Range[k] + 1)];
    rs = If[k < 5, Range[k],
      Module[{k0 = 5, sx, sxx, sq, sqq, sxq, rse, tol},
       sx = Prepend[Accumulate[x], 0.]; sxx = Prepend[Accumulate[x^2], 0.];
       sq = Prepend[Accumulate[cv], 0.]; sqq = Prepend[Accumulate[cv^2], 0.];
       sxq = Prepend[Accumulate[x cv], 0.];
       rse = {i, j} |-> Module[
          {m = N[j - i + 1], ax = sx[[j + 1]] - sx[[i]], axx = sxx[[j + 1]] - sxx[[i]],
           aq = sq[[j + 1]] - sq[[i]], aqq = sqq[[j + 1]] - sqq[[i]], axq = sxq[[j + 1]] - sxq[[i]], b},
          b = (m axq - ax aq)/(m axx - ax^2);
          Sqrt[Max[aqq - (aq - b ax) aq/m - b axq, 0.]/(m - 2)]];
       tol = Max[2 Quantile[Table[rse[i, i + k0 - 1], {i, 1, k - k0 + 1}], 1/4], 1.*^-10];
       Range @@ SelectFirst[
         Catenate[Table[{i, i + len - 1}, {len, k, k0, -1}, {i, 1, k - len + 1}]],
         p |-> rse[p[[1]], p[[2]]] <= tol, {1, k}]]];
    mat = PseudoInverse[Transpose[{ConstantArray[1., Length[rs]], x[[rs]]}]];
    c = mat . q[[rs]];
    {c[[1]], -3 (c[[1]] + 2) c[[2]]}]];

dimcurvSeq[rec_] := fit /@ (LogDifferenceQuotients /@ rec["Growths"]);
lastFit[rec_] := Module[{dc = Select[dimcurvSeq[rec], numQ[#[[1]]] && numQ[#[[2]]] &]}, If[dc === {}, Missing[], Last[dc]]];
dimension[rec_] := Replace[lastFit[rec], {{d_, _} :> strip[d], _ :> Missing[]}];
dimensionError[rec_] := Replace[lastFit[rec], {{Around[_, e_], _} :> e, {_, _} :> 0., _ :> Missing[]}];
curvature[rec_] := Replace[lastFit[rec], {{_, k_} :> strip[k], _ :> Missing[]}];
curvatureError[rec_] := Replace[lastFit[rec], {{_, Around[_, e_]} :> e, {_, _} :> 0., _ :> Missing[]}];
trajectory[rec_] := Cases[Transpose[{strip[dimcurvSeq[rec]], rec["VertexCounts"]}], {{_?NumericQ, _?NumericQ}, _}];
stabilityScore[rec_] :=
  Module[{t = trajectory[rec], tail},
   tail = If[Length[t] >= 2, Take[t[[All, 1]], -Ceiling[Length[t]/3]], {}];
   If[Length[tail] >= 2, 1./(1. + Max[EuclideanDistance @@@ Subsets[tail, {2}]]), Missing[]]];
finalDiameter[rec_] := Last[rec["Diameters"]];
growthClass[rec_] :=
  Module[{dia = rec["Diameters"], k},
   k = Length[dia];
   Which[k < 2, "static", Last[dia] > dia[[Max[1, k - 2]]], "expanding",
    Last[dia] < dia[[Max[1, k - 2]]], "contracting", True, "static"]];
graphDimension[rec_] :=
  With[{v = Last[rec["VertexCounts"]], d = finalDiameter[rec]}, If[TrueQ[d > 1], Log[v]/Log[d], Missing[]]];

scalars[rec_] :=
  <|"Dimension" -> dimension[rec], "Curvature" -> curvature[rec], "Vertices" -> Last[rec["VertexCounts"]],
    "Diameter" -> finalDiameter[rec], "GraphDimension" -> graphDimension[rec], "Growth" -> growthClass[rec],
    "Stability" -> stabilityScore[rec]|>;

graphOf[edges_] := Graph[DeleteCases[UndirectedEdge[a_, a_]][DeleteDuplicates[UndirectedEdge @@@ Catenate[Subsets[#, {2}] & /@ edges]]]];
graphOpts = Sequence[VertexStyle -> Black, VertexSize -> {"Scaled", 0.012}, EdgeStyle -> Directive[Opacity[0.25], StandardGray]];
dash = Style["\[LongDash]", GrayLevel[0.55], 20];
seriesColors[n_, c1_, c2_] := Blend[{c1, c2}, #] & /@ Subdivide[0., 1., Max[n - 1, 1]];
thumbOpts = Sequence[ImageSize -> 175, AspectRatio -> 0.72, Frame -> True, PlotRangePadding -> Scaled[0.03],
   ImagePadding -> {{34, 6}, {20, 6}}, Background -> White, BaseStyle -> {FontSize -> 11},
   Mesh -> All, MeshStyle -> Directive[PointSize[0.014], Black]];

headerTips = <|
   "Rule" -> "Rule Name", "State" -> "Final State", "Gen" -> "Final Generation",
   "Vertices" -> "Final Vertex Count", "Edges" -> "Final Edge Count", "Diameter" -> "Final Graph Diameter",
   "Growth" -> "Graph Growth: diameter trend (expanding / static / contracting)",
   "Graph Dim" -> "Final Graph Dimension = log V / log D",
   "Ball Dim" -> "Final Ball Growth Dimension (volume-growth fit)",
   "Ball Curv" -> "Final Ball Growth Curvature (volume-growth fit)",
   "Stability" -> "Stability Score = 1/(1 + tail diameter); higher = more converged",
   "Vertex Growth" -> "Vertex count per iteration", "Volume Growth" -> "Ball Volume Growth: averaged V(r) per iteration",
   "Log Diff Q" -> "Log Difference Quotients q(r) = d log V / d log r",
   "Dimensions" -> "Ball growth dimension per iteration", "Curvatures" -> "Ball growth curvature per iteration"|>;
defaultColumns = {"Rule", "State", "Gen", "Vertices", "Edges", "Diameter", "Growth",
   "Graph Dim", "Ball Dim", "Ball Curv", "Stability",
   "Vertex Growth", "Volume Growth", "Log Diff Q", "Dimensions", "Curvatures"};

buildTable[recs_Association, cols_ : defaultColumns] :=
  Module[{mt, cell},
   mt[m_] := {{m, If[Abs[N@m] >= 10, Round[m], Round[N@m, 0.1]]}};
   cell[col_, id_, rec_] := Switch[col,
     "Rule", ruleLink[id],
     "State", With[{g = graphOf[rec["FinalState"]]}, If[VertexCount[g] < 1, dash, Rasterize @ Graph[g, ImageSize -> 150, graphOpts, Background -> White]]],
     "Gen", Length[rec["VertexCounts"]],
     "Vertices", Last[rec["VertexCounts"]],
     "Edges", Length[rec["FinalState"]],
     "Diameter", finalDiameter[rec],
     "Growth", growthClass[rec],
     "Graph Dim", With[{x = graphDimension[rec]}, If[NumericQ[x], Round[x, 0.01], dash]],
     "Ball Dim", With[{v = dimension[rec]}, If[NumericQ[v], Around[v, dimensionError[rec]], dash]],
     "Ball Curv", With[{v = curvature[rec]}, If[NumericQ[v], Around[v, curvatureError[rec]], dash]],
     "Stability", With[{x = stabilityScore[rec]}, If[NumericQ[x], Round[x, 0.001], dash]],
     "Vertex Growth", With[{vc = rec["VertexCounts"]}, If[Length[vc] < 2, dash,
        Rasterize @ ListLinePlot[vc, PlotStyle -> Directive[AbsoluteThickness[2], StandardBrown],
          FrameTicks -> {{mt[Max[vc]], None}, {mt[Length[vc]], None}}, thumbOpts]]],
     "Volume Growth", With[{vol = rec["Growths"], sv = strip[rec["Growths"]]}, If[Max[Length /@ sv] < 2, dash,
        Rasterize @ ListLinePlot[vol, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[vol], StandardYellow, StandardRed]),
          FrameTicks -> {{mt[Max[Flatten[sv]]], None}, {mt[Max[Length /@ sv]], None}}, thumbOpts]]],
     "Log Diff Q", With[{q = LogDifferenceQuotients /@ rec["Growths"]}, With[{fl = Flatten[strip[q]]},
        If[fl === {} || Max[Length /@ q] < 2, dash,
         Rasterize @ Quiet @ ListLinePlot[q, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[q], StandardYellow, StandardGreen]),
           FrameTicks -> {{mt[Max[fl]], None}, {mt[Max[Length /@ q]], None}}, thumbOpts]]]],
     "Dimensions", With[{d = DeleteCases[MapIndexed[{First[#2], #1[[1]]} &, dimcurvSeq[rec]], {_, _Missing}]}, If[Length[d] < 1, dash,
        Rasterize @ ListLinePlot[d, PlotStyle -> Directive[AbsoluteThickness[2], StandardBlue], IntervalMarkersStyle -> StandardBlue,
          FrameTicks -> {{mt[Max[strip[d[[All, 2]]]]], None}, {mt[Max[d[[All, 1]]]], None}}, thumbOpts]]],
     "Curvatures", With[{d = DeleteCases[MapIndexed[{First[#2], #1[[2]]} &, dimcurvSeq[rec]], {_, _Missing}]}, If[Length[d] < 1, dash,
        Rasterize @ ListLinePlot[d, PlotStyle -> Directive[AbsoluteThickness[2], StandardPurple], IntervalMarkersStyle -> StandardPurple,
          FrameTicks -> {{mt[Max[strip[d[[All, 2]]]]], None}, {mt[Max[d[[All, 1]]]], None}}, thumbOpts]]],
     _, dash];
   Dataset[(id |-> With[{rec = recs[id]}, Association[(col |-> col -> cell[col, id, rec]) /@ cols]]) /@ Keys[recs],
     Alignment -> {Center, Center}, MaxItems -> {25, All}, ItemStyle -> {FontSize -> 14},
     HeaderStyle -> Directive[FontSize -> 14, Bold], HeaderDisplayFunction -> (Tooltip[#, Lookup[headerTips, #, #]] &)]];

rangeTable[recs_Association, cols_ : defaultColumns, perPage_ : 10] :=
  DynamicModule[{ids = Keys[recs], n = Length[recs], range},
   range = {1, Min[perPage, n]};
   Column[{
     Row[{"rules ", InputField[Dynamic[range[[1]]], Number, FieldSize -> 4], " to ",
       InputField[Dynamic[range[[2]]], Number, FieldSize -> 4], " of ", n}],
     Dynamic[With[{a = Clip[Round[Min[range]], {1, n}], b = Clip[Round[Max[range]], {1, n}]},
        buildTable[KeyTake[recs, ids[[a ;; b]]], cols]]]}]];
```

## Rebuild Data

DATA is rebuilt offline by Scripts/rebuild_all.wls. Evaluate this to clear the in-session thumbnail cache and force re-render.

```wolfram
$thumbs = <||>
```

## Summary Table

Pick a rule range (by order, 1 to N) with the two From/To fields; only the chosen rows are computed, and revisited rows are instant.

```wolfram
rangeTable[data, defaultColumns]
```

## Queries

### Data query: runs the column functions live on the original data. Always works, recomputes each time.

```wolfram
dataQuery = Dataset[scalars /@ data]
```

Dimension 2.5-3.5, near-flat curvature, at least 1000 vertices.

```wolfram
dataQuery[Select[NumericQ[#Dimension] && 2.5 <= #Dimension <= 3.5 && Abs[#Curvature] < 0.5 && #Vertices >= 1000 &]]
```

Most converged large rules (highest stability score first).

```wolfram
dataQuery[Select[#Vertices >= 500 && NumericQ[#Stability] &]][TakeLargestBy["Stability", 25]]
```

Recommended ranking: stability score times sqrt(vertices).

```wolfram
dataQuery[Select[NumericQ[#Stability] &]][ReverseSortBy[#Stability Sqrt[#Vertices] &]][;; 25]
```

Growth-class tally.

```wolfram
dataQuery[Counts, "Growth"]
```

### Table query: reads the cached table. Fast, but covers only rules already rendered or precomputed.

```wolfram
tableQuery = Dataset[$cache]
```

Most converged cached rules.

```wolfram
tableQuery[Select[NumericQ[#StabilityScore] &]][TakeLargestBy["StabilityScore", 25]]
```

Growth-class tally over cached rules.

```wolfram
tableQuery[Counts, "GrowthClass"]
```

## Dimension-Curvature Landscape

```wolfram
With[{pts = DeleteCases[
    Module[{lf = lastFit[data[#]]}, {#, If[MatchQ[lf, {_, _}], strip[lf[[1]]], Missing[]],
        If[MatchQ[lf, {_, _}], strip[lf[[2]]], Missing[]], Last[data[#]["VertexCounts"]]}] & /@ Keys[data],
    {_, _Missing, _, _} | {_, _, _Missing, _}], nbins = 7},
 With[{lo = Min[pts[[All, 4]]], hi = Max[pts[[All, 4]]]},
  With[{grouped = KeySort @ GroupBy[pts, Clip[Ceiling[nbins (#[[4]] - lo)/(hi - lo + 1)], {1, nbins}] &]},
   Legended[
    ListPlot[Map[Callout[{#[[2]], #[[3]]}, Hyperlink[#[[1]], url[#[[1]]]]] &, #] & /@ Values[grouped],
     PlotStyle -> (Blend[{StandardYellow, StandardRed}, (# - 1)/(nbins - 1)] & /@ Keys[grouped]),
     Frame -> True, FrameLabel -> {"dimension", "curvature"}, Background -> White,
     ImageSize -> 560, PlotLabel -> "Dimension-Curvature Landscape"],
    BarLegend[{Blend[{StandardYellow, StandardRed}, Rescale[#, {lo, hi}]] &, {lo, hi}}, LegendLabel -> "vertices"]]]]]
```

## Individual Characteristics

### Graph at each iteration

```wolfram
Quiet[Remove["Global`WolframModel"]]; Needs["SetReplace`"];
With[{wmd = ResourceFunction["WolframModelData"]},
 GraphicsGrid[Partition[
   Graph[graphOf[#], ImageSize -> 90, graphOpts] & /@
    Rest[WolframModel[wmd[exId, "Rule"], wmd[exId, "InitialCondition"], <|"MaxGenerations" -> 14, "MaxVertices" -> 5000, "MaxEvents" -> 100000|>]["StatesList"]], UpTo[5]]]]
```

### Ball volume growth

```wolfram
With[{vol = data[exId]["Growths"]},
 ListLinePlot[vol, PlotStyle -> seriesColors[Length[vol], StandardYellow, StandardRed],
  Mesh -> All, Frame -> True, FrameLabel -> {"radius r", "ball volume V(r)"}, ImageSize -> 460, PlotRange -> All]]
```

### Log difference quotients

```wolfram
With[{q = LogDifferenceQuotients /@ data[exId]["Growths"]},
 ListLinePlot[q, PlotStyle -> seriesColors[Length[q], StandardYellow, StandardGreen],
  Mesh -> All, Frame -> True, FrameLabel -> {"r", "q(r) = d log V / d log r"}, ImageSize -> 460, PlotRange -> All]]
```

### Dimension and curvature per iteration (with fit error bars)

```wolfram
With[{dc = dimcurvSeq[data[exId]]},
 GraphicsRow[{
   ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[1]]} &, dc], {_, _Missing}], PlotStyle -> StandardBlue,
    Mesh -> All, IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> {"iteration", "dimension"}],
   ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[2]]} &, dc], {_, _Missing}], PlotStyle -> StandardPurple,
    Mesh -> All, IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> {"iteration", "curvature"}]}, ImageSize -> 640]]
```

### Vertex growth

```wolfram
ListLinePlot[data[exId]["VertexCounts"], PlotStyle -> StandardBrown, Mesh -> All, Frame -> True,
 FrameLabel -> {"iteration", "vertices"}, ImageSize -> 460]
```

### Dimension-curvature trajectory (gray to red by vertices)

```wolfram
With[{t = trajectory[data[exId]]},
 Legended[
  Graphics[{Thick, Line[t[[All, 1]], VertexColors -> (Blend[{StandardGray, StandardRed}, #] & /@ Rescale[t[[All, 2]]])],
    PointSize[0.025], Point[t[[All, 1]], VertexColors -> (Blend[{StandardGray, StandardRed}, #] & /@ Rescale[t[[All, 2]]])]},
   Frame -> True, FrameLabel -> {"dimension", "curvature"}, AspectRatio -> 1/GoldenRatio, ImageSize -> 480,
   Background -> White, PlotLabel -> exId <> " (d,K) trajectory"],
  BarLegend[{Blend[{StandardGray, StandardRed}, Rescale[#, MinMax[t[[All, 2]]]]] &, MinMax[t[[All, 2]]]}, LegendLabel -> "vertices"]]]
```

### Stability (Cauchy tail diameter)

```wolfram
With[{p = trajectory[data[exId]][[All, 1]]},
 ListLinePlot[Table[Max[EuclideanDistance @@@ Subsets[p[[n0 ;;]], {2}]], {n0, 1, Length[p] - 1}],
  Mesh -> All, PlotStyle -> StandardBlue, Frame -> True, FrameLabel -> {"n0", "tail diameter"},
  PlotLabel -> "Cauchy tail diameter (stability score = 1/(1 + min over last n/3))", ImageSize -> 480, PlotRange -> All]]
```