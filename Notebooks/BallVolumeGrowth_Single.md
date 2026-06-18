# Ball Volume Growth: Single Rule

## Initialization

```wolfram
Needs["SetReplace`"];
Get[FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Code", "BallVolumeGrowth.wl"}]];
data = Select[Import[FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Data", "AverageBallVolumeGrowths.wxf"}]], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
wmd = ResourceFunction["WolframModelData"];
spec = <|"MaxGenerations" -> 14, "MaxVertices" -> 5000, "MaxEvents" -> 100000|>;
exId = "wm3382";
```

## Graph at each iteration

```wolfram
With[{rule = wmd[exId, "Rule"], init = wmd[exId, "InitialCondition"]}, GraphicsGrid[Partition[Graph[graphOf[#], ImageSize -> 110, graphOpts] & /@ Rest[WolframModel[rule, init, spec]["StatesList"]], UpTo[5]]]]
```

## Ball volume growth

```wolfram
With[{vol = data[exId]["Growths"]}, ListLinePlot[vol, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[vol], StandardYellow, StandardRed]), Mesh -> All, Frame -> True, FrameLabel -> {"radius r", "V(r)"}, ImageSize -> 460, PlotRange -> All]]
```

## Log difference quotients

```wolfram
With[{q = LogDifferenceQuotients /@ data[exId]["Growths"]}, ListLinePlot[q, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[q], StandardYellow, StandardGreen]), Mesh -> All, Frame -> True, FrameLabel -> {"r", "q(r)"}, ImageSize -> 460, PlotRange -> All]]
```

## Dimension and curvature per iteration

```wolfram
With[{dc = dimcurvSeq[data[exId]]}, GraphicsRow[{ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[1]]} &, dc], {_, _Missing}], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> {"iteration", "dimension"}], ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[2]]} &, dc], {_, _Missing}], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> {"iteration", "curvature"}]}, ImageSize -> 640]]
```

## Vertex growth

```wolfram
ListLinePlot[data[exId]["VertexCounts"], PlotStyle -> StandardBrown, Mesh -> All, Frame -> True, FrameLabel -> {"iteration", "vertices"}, ImageSize -> 460]
```

## Dimension-curvature trajectory (gray to red by vertices)

```wolfram
With[{t = trajectory[data[exId]]}, Legended[Graphics[{Thick, Line[t[[All, 1]], VertexColors -> (Blend[{StandardGray, StandardRed}, #] & /@ Rescale[t[[All, 2]]])], PointSize[0.025], Point[t[[All, 1]], VertexColors -> (Blend[{StandardGray, StandardRed}, #] & /@ Rescale[t[[All, 2]]])]}, Frame -> True, FrameLabel -> {"dimension", "curvature"}, AspectRatio -> 1/GoldenRatio, ImageSize -> 480, Background -> White], BarLegend[{Blend[{StandardGray, StandardRed}, Rescale[#, MinMax[t[[All, 2]]]]] &, MinMax[t[[All, 2]]]}, LegendLabel -> "vertices"]]]
```

## Stability (Cauchy tail diameter)

```wolfram
With[{p = trajectory[data[exId]][[All, 1]]}, ListLinePlot[Table[Max[EuclideanDistance @@@ Subsets[p[[n0 ;;]], {2}]], {n0, 1, Length[p] - 1}], Mesh -> All, PlotStyle -> StandardBlue, Frame -> True, FrameLabel -> {"n0", "tail diameter"}, PlotLabel -> "stability: Cauchy tail diameter (score = 1/(1+min))", ImageSize -> 480, PlotRange -> All]]
```