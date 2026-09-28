# Volume Growth: Single Rule

## Initialization {closed}

```wolfram init
Needs[ "WolframInstitute`DiscreteGeometry`" ];
Needs[ "WolframInstitute`InfraGeometry`" ];
```

## Generations

```wolfram run
states = Rest @ ResourceFunction[ "WolframModel" ][ {{{1, 2}, {1, 3}} -> {{2, 3}, {2, 4}, {3, 4}, {1, 2}}}, {{1, 1}, {1, 1}},
    <| "MaxGenerations" -> 14, "MaxVertices" -> 5000, "MaxEvents" -> 100000 |> ][ "StatesList" ];

graphs = Hypergraph2Section /@ states;
```

```wolfram eval
GraphicsGrid[ Partition[ ResourceFunction[ "WolframModelPlot" ][ #, ImageSize -> { UpTo[ 120 ], UpTo[ 120 ] } ] & /@ states, UpTo[ 5 ] ] ]
```

## Volume Growth

Volume of a ball of radius r in the shortest‑path metric, with respect to the counting measure.
Plotted is the arithmetic mean and standard deviation computed across all graph vertices.

```wolfram run
ballValues = With[ { vols = BallVolumes[ #, All, All, "Measure" -> "Counting" ] },
     Transpose[ PadRight[ #, Max[ Length /@ vols ], Last[ # ] ] & /@ vols ] ] & /@ graphs;

ballVolumes = Map[ Around[ Mean[ # ], StandardDeviation[ # ] ] &, ballValues, { 2 } ];
```

```wolfram eval
ListLinePlot[ ballVolumes, PlotStyle -> ( Directive[ AbsoluteThickness[ 2 ], # ] & /@ ( Blend[ { StandardYellow, StandardRed }, # ] & /@ Subdivide[ 0., 1., Max[ Length[ ballVolumes ] - 1, 1 ] ] ) ), IntervalMarkers -> "Bars", Mesh -> All, Frame -> True, FrameLabel -> { "Radius", "Ball Volume" }, ImageSize -> 460, PlotRange -> All ]
```

## Log Difference Quotients

Forward log-difference quotient of the volume of a ball of radius r.
Note that the counting measure of an r-ball corresponds to the Hausdorff measure of an (r+1)-ball up to boundary effects.
The latter is the correct one, corresponding to the Riemannian volume.
We take the mean of the log volumes, which corresponds to taking the log of the geometric mean of the volumes. We plot the standard error of the mean.

```wolfram run
meanVolumes = Map[ Exp[ MeanAround[ Log[ # ] ] ] &, ballValues, { 2 } ];
```

```wolfram eval
ListLinePlot[ LogDifferenceQuotients /@ meanVolumes, PlotStyle -> ( Directive[ AbsoluteThickness[ 2 ], # ] & /@ ( Blend[ { StandardYellow, StandardGreen }, # ] & /@ Subdivide[ 0., 1., Max[ Length[ meanVolumes ] - 1, 1 ] ] ) ), IntervalMarkers -> "Bars", Mesh -> All, Frame -> True, FrameLabel -> { "Radius", "Log Difference Quotient" }, ImageSize -> 460, PlotRange -> All ]
```

## Dimension and Curvature

Fit of the log‑difference quotients of volumes, restricted to an automatically determined window consisting of the maximal range of radii over which the linear regression error (in the least‑squares sense) is minimized.

```wolfram run
dimensionCurvature = With[ { quotients = LogDifferenceQuotients[ # ] }, If[ Length[ quotients ] < 2, Missing[], DimensionCurvatureFit[ Transpose[ { Range[ Length[ quotients ] ], quotients } ] ] ] ] & /@ meanVolumes;
```

```wolfram eval
GraphicsRow[ { ListLinePlot[ MapIndexed[ If[ AssociationQ[ #1 ], { First[ #2 ], #1[ "Dimension" ] }, Nothing ] &, dimensionCurvature ], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkers -> "Bars", IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> { "Generation", "Dimension" } ], ListLinePlot[ MapIndexed[ If[ AssociationQ[ #1 ], { First[ #2 ], #1[ "ScalarCurvature" ] }, Nothing ] &, dimensionCurvature ], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkers -> "Bars", IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> { "Generation", "Curvature" } ] }, ImageSize -> 640 ]
```

## Vertex and Edge Count and Diameter

```wolfram eval
With[ { vertexCounts = VertexCount /@ graphs, edgeCounts = Length /@ states, diameters = ( Length[ # ] - 1 & ) /@ ballVolumes }, GraphicsRow[ { ListLinePlot[ vertexCounts, PlotStyle -> Directive[ AbsoluteThickness[ 2 ], StandardBrown ], Mesh -> All, Frame -> True, FrameLabel -> { "Generation", "Vertices" } ], ListLinePlot[ edgeCounts, PlotStyle -> Directive[ AbsoluteThickness[ 2 ], StandardRed ], Mesh -> All, Frame -> True, FrameLabel -> { "Generation", "Edges" } ], ListLinePlot[ diameters, PlotStyle -> Directive[ AbsoluteThickness[ 2 ], StandardOrange ], Mesh -> All, Frame -> True, FrameLabel -> { "Generation", "Diameter" } ] }, ImageSize -> 720 ] ]
```

Global graph-dimension estimate log V / log R from the radius scale, where R = D/2 is half the diameter.

```wolfram eval
With[ { vertexCounts = VertexCount /@ graphs, radii = ( ( Length[ # ] - 1 )/2 & ) /@ ballVolumes }, ListLinePlot[ DeleteCases[ Table[ If[ radii[[ i ]] > 1, { i, Log[ vertexCounts[[ i ]] ] / Log[ radii[[ i ]] ] }, Null ], { i, Length[ vertexCounts ] } ], Null ], PlotStyle -> Directive[ AbsoluteThickness[ 2 ], StandardBlue ], Mesh -> All, Frame -> True, FrameLabel -> { "Generation", "Global Dimension" }, ImageSize -> 460, PlotRange -> All ] ]
```

## Dimension-Curvature Stability

```wolfram eval
With[ { trajectory = Select[ MapIndexed[ If[ AssociationQ[ #1 ], { First[ #2 ], #1[ "Dimension" ] /. Around[ a_, _ ] :> a, #1[ "ScalarCurvature" ] /. Around[ a_, _ ] :> a, VertexCount[ graphs[[ First[ #2 ] ]] ] }, Nothing ] &, dimensionCurvature ], NumericQ[ #[[ 2 ]] ] && NumericQ[ #[[ 3 ]] ] & ] }, With[ { points = trajectory[[ All, { 2, 3 } ]], generations = trajectory[[ All, 1 ]], colors = Blend[ { StandardGray, StandardRed }, # ] & /@ Rescale[ trajectory[[ All, 4 ]] ] }, GraphicsRow[ { Graphics[ { Arrowheads[ { { 0.05, 0.5 } } ], Table[ { colors[[ i + 1 ]], Arrow[ { points[[ i ]], points[[ i + 1 ]] } ] }, { i, Length[ points ] - 1 } ], PointSize[ 0.015 ], Table[ { colors[[ i ]], Point[ points[[ i ]] ] }, { i, Length[ points ] } ], Black, Table[ Text[ Style[ generations[[ i ]], 10 ], points[[ i ]], { -1.3, -1.3 } ], { i, Length[ points ] } ] }, Frame -> True, FrameLabel -> { "Dimension", "Curvature" }, Background -> White, PlotLabel -> "Geometry Trajectory" ], ListLinePlot[ Table[ Max[ EuclideanDistance @@@ Subsets[ points[[ n0 ;; ]], { 2 } ] ], { n0, 1, Length[ points ] - 1 } ], Mesh -> All, PlotStyle -> Directive[ StandardYellow, AbsoluteThickness[ 2 ] ], Frame -> True, FrameLabel -> { Subscript[ n, 0 ], "Tail Diameter" }, PlotLabel -> "Cauchy Tail" ] }, ImageSize -> 720 ] ] ]
```
