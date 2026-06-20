# Volume Growth: Single Rule

## Initialization

```wolfram
Needs["WolframInstitute`Infrageometry`"];

ruleName = "wm3382";

states = Rest @ ResourceFunction["WolframModel"][{{{1, 2}, {1, 3}} -> {{2, 3}, {2, 4}, {3, 4}, {1, 2}}}, {{1, 1}, {1, 1}},
    <|"MaxGenerations" -> 14, "MaxVertices" -> 5000, "MaxEvents" -> 100000|>]["StatesList"];

graphs = Hypergraph2Section /@ states;

ballValues = With[{vols = BallVolumes[#, All, All, "Measure" -> "Counting"]},
     Transpose[PadRight[#, Max[Length /@ vols], Last[#]] & /@ vols]] & /@ graphs;

ballVolumes = Map[Around[Mean[#], StandardDeviation[#]] &, ballValues, {2}];

meanVolumes = Map[Exp[MeanAround[Log[#]]] &, ballValues, {2}];

dimensionCurvature = With[{q = LogDifferenceQuotients[#]}, If[Length[q] < 2, Missing[], DimensionCurvatureFit[Transpose[{Range[Length[q]], q}]]]] & /@ meanVolumes;
```

## Generations

```wolfram
GraphicsGrid[Partition[ResourceFunction["WolframModelPlot"][#, ImageSize -> {UpTo[120], UpTo[120]}] & /@ states, UpTo[5]]]
```

## Volume Growth

Pointwise volume growth (mean ± σ).

```wolfram
ListLinePlot[ballVolumes, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ (Blend[{StandardYellow, StandardRed}, #] & /@ Subdivide[0., 1., Max[Length[ballVolumes] - 1, 1]])), IntervalMarkers -> "Bars", Mesh -> All, Frame -> True, FrameLabel -> {"Radius", "Ball Volume"}, ImageSize -> 460, PlotRange -> All]
```

## Log Difference Quotients

Log-difference quotient of the mean volume growth (mean ± σ/Sqrt[vertex count]).

```wolfram
ListLinePlot[LogDifferenceQuotients /@ meanVolumes, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ (Blend[{StandardYellow, StandardGreen}, #] & /@ Subdivide[0., 1., Max[Length[meanVolumes] - 1, 1]])), IntervalMarkers -> "Bars", Mesh -> All, Frame -> True, FrameLabel -> {"Radius", "Log Difference Quotient"}, ImageSize -> 460, PlotRange -> All]
```

## Dimension and Curvature

Dimension and curvature from the mean volume growth.

```wolfram
GraphicsRow[{ListLinePlot[MapIndexed[If[AssociationQ[#1], {First[#2], #1["Dimension"]}, Nothing] &, dimensionCurvature], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkers -> "Bars", IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> {"Generation", "Dimension"}], ListLinePlot[MapIndexed[If[AssociationQ[#1], {First[#2], #1["ScalarCurvature"]}, Nothing] &, dimensionCurvature], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkers -> "Bars", IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> {"Generation", "Curvature"}]}, ImageSize -> 640]
```

## Vertex and Edge Count and Diameter

```wolfram
With[{vc = VertexCount /@ graphs, ec = Length /@ states, dia = (Length[#] - 1 &) /@ ballVolumes}, GraphicsRow[{ListLinePlot[vc, PlotStyle -> Directive[AbsoluteThickness[2], StandardBrown], Mesh -> All, Frame -> True, FrameLabel -> {"Generation", "Vertices"}], ListLinePlot[ec, PlotStyle -> Directive[AbsoluteThickness[2], StandardRed], Mesh -> All, Frame -> True, FrameLabel -> {"Generation", "Edges"}], ListLinePlot[dia, PlotStyle -> Directive[AbsoluteThickness[2], StandardOrange], Mesh -> All, Frame -> True, FrameLabel -> {"Generation", "Diameter"}], ListLinePlot[DeleteCases[Table[If[dia[[i]] > 1, {i, Log[vc[[i]]]/Log[dia[[i]]]}, Null], {i, Length[vc]}], Null], PlotStyle -> Directive[AbsoluteThickness[2], StandardBlue], Mesh -> All, Frame -> True, FrameLabel -> {"Generation", "Graph Dimension"}]}, ImageSize -> 900]]
```

## Dimension-Curvature Stability

```wolfram
With[{tt = Select[MapIndexed[If[AssociationQ[#1], {First[#2], #1["Dimension"] /. Around[a_, _] :> a, #1["ScalarCurvature"] /. Around[a_, _] :> a, VertexCount[graphs[[First[#2]]]]}, Nothing] &, dimensionCurvature], NumericQ[#[[2]]] && NumericQ[#[[3]]] &]}, With[{pts = tt[[All, {2, 3}]], gens = tt[[All, 1]], cols = Blend[{StandardGray, StandardRed}, #] & /@ Rescale[tt[[All, 4]]]}, GraphicsRow[{Graphics[{Arrowheads[{{0.05, 0.5}}], Table[{cols[[i + 1]], Arrow[{pts[[i]], pts[[i + 1]]}]}, {i, Length[pts] - 1}], PointSize[0.015], Table[{cols[[i]], Point[pts[[i]]]}, {i, Length[pts]}], Black, Table[Text[Style[gens[[i]], 10], pts[[i]], {-1.3, -1.3}], {i, Length[pts]}]}, Frame -> True, FrameLabel -> {"Dimension", "Curvature"}, Background -> White, PlotLabel -> "Geometry Trajectory"], ListLinePlot[Table[Max[EuclideanDistance @@@ Subsets[pts[[n0 ;;]], {2}]], {n0, 1, Length[pts] - 1}], Mesh -> All, PlotStyle -> Directive[StandardYellow, AbsoluteThickness[2]], Frame -> True, FrameLabel -> {"N0", "Tail Diameter"}, PlotLabel -> "Cauchy Tail"]}, ImageSize -> 720]]]
```