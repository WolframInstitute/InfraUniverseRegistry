# Volume Growth: Single Rule

## Initialization

```wolfram
Needs["SetReplace`"];
Get[FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Code", "VolumeGrowth.wl"}]];
data = Select[Import[FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Data", "AverageVolumeGrowths.wxf"}]], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
wmd = ResourceFunction["WolframModelData"];
spec = <|"MaxGenerations" -> 14, "MaxVertices" -> 5000, "MaxEvents" -> 100000|>;
exId = "wm3382";
```

## Generations

```wolfram
With[{rule = wmd[exId, "Rule"], init = wmd[exId, "InitialCondition"]}, GraphicsGrid[Partition[WolframModelPlot[#, ImageSize -> {UpTo[120], UpTo[120]}] & /@ Rest[WolframModel[rule, init, spec]["StatesList"]], UpTo[5]]]]
```

## Volume Growth

```wolfram
With[{vol = data[exId]["Growths"]}, ListLinePlot[vol, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[vol], StandardYellow, StandardRed]), IntervalMarkers -> "Fences", Mesh -> All, Frame -> True, FrameLabel -> {"Radius", "Ball Volume"}, ImageSize -> 460, PlotRange -> All]]
```

## Log Difference Quotients

```wolfram
With[{q = LogDifferenceQuotients /@ data[exId]["Growths"]}, ListLinePlot[q, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[q], StandardYellow, StandardGreen]), IntervalMarkers -> "Fences", Mesh -> All, Frame -> True, FrameLabel -> {"Radius", "Log Difference Quotient"}, ImageSize -> 460, PlotRange -> All]]
```

## Dimension and Curvature

```wolfram
With[{dc = dimcurvSeq[data[exId]]}, GraphicsRow[{ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[1]]} &, dc], {_, _Missing}], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> {"Iteration", "Dimension"}], ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[2]]} &, dc], {_, _Missing}], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> {"Iteration", "Curvature"}]}, ImageSize -> 640]]
```

## Vertex and Edge Count and Diameter

```wolfram
With[{vc = data[exId]["VertexCounts"], ec = data[exId]["EdgeCounts"], dia = data[exId]["Diameters"]}, GraphicsRow[{ListLinePlot[vc, PlotStyle -> Directive[AbsoluteThickness[2], StandardBrown], Mesh -> All, Frame -> True, FrameLabel -> {"Generation", "Vertices"}], ListLinePlot[ec, PlotStyle -> Directive[AbsoluteThickness[2], StandardRed], Mesh -> All, Frame -> True, FrameLabel -> {"Generation", "Edges"}], ListLinePlot[dia, PlotStyle -> Directive[AbsoluteThickness[2], StandardOrange], Mesh -> All, Frame -> True, FrameLabel -> {"Generation", "Diameter"}], ListLinePlot[DeleteCases[Table[If[dia[[i]] > 1, {i, Log[vc[[i]]]/Log[dia[[i]]]}, Null], {i, Length[vc]}], Null], PlotStyle -> Directive[AbsoluteThickness[2], StandardBlue], Mesh -> All, Frame -> True, FrameLabel -> {"Generation", "Graph Dimension"}]}, ImageSize -> 900]]
```

## Geometric Stability

```wolfram
With[{tt = Select[MapIndexed[{First[#2], #1[[1]], #1[[2]], data[exId]["VertexCounts"][[First[#2]]]} &, dimcurvSeq[data[exId]] /. Around[a_, _] :> a], NumericQ[#[[2]]] && NumericQ[#[[3]]] &]}, With[{pts = tt[[All, {2, 3}]], gens = tt[[All, 1]], cols = Blend[{StandardGray, StandardRed}, #] & /@ Rescale[tt[[All, 4]]]}, GraphicsRow[{Graphics[{Arrowheads[{{0.05, 0.5}}], Table[{cols[[i + 1]], Arrow[{pts[[i]], pts[[i + 1]]}]}, {i, Length[pts] - 1}], PointSize[0.015], Table[{cols[[i]], Point[pts[[i]]]}, {i, Length[pts]}], Black, Table[Text[Style[gens[[i]], 10], pts[[i]], {-1.3, -1.3}], {i, Length[pts]}]}, Frame -> True, FrameLabel -> {"Dimension", "Curvature"}, Background -> White, PlotLabel -> "Geometry Trajectory"], ListLinePlot[Table[Max[EuclideanDistance @@@ Subsets[pts[[n0 ;;]], {2}]], {n0, 1, Length[pts] - 1}], Mesh -> All, PlotStyle -> Directive[StandardYellow, AbsoluteThickness[2]], Frame -> True, FrameLabel -> {"N0", "Tail Diameter"}, PlotLabel -> "Cauchy Tail"]}, ImageSize -> 720]]]
```