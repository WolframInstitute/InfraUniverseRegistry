# Ball Volume Growth: Table

## Initialization

```wolfram
tableFile = FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Data", "table.wxf"}];
data = Import[tableFile];

url[id_] := "https://www.wolframphysics.org/universes/" <> id <> "/";
dash = Style["\[LongDash]", GrayLevel[0.55], 20];
ar[v_, e_] := If[NumericQ[v], Around[v, e], dash];
rnd[x_, d_] := If[NumericQ[x], Round[x, d], dash];
headerTips = <|"Rule" -> "Rule Name", "State" -> "Final State", "Gen" -> "Final Generation",
   "Vertices" -> "Final Vertex Count", "Edges" -> "Final Edge Count", "Diameter" -> "Final Graph Diameter",
   "Vertex Growth" -> "Vertex-count growth rate per generation (0 static, + expanding, - shrinking)",
   "Diameter Growth" -> "Diameter growth rate per generation (0 static, + expanding, - shrinking)",
   "Graph Dim" -> "Final Graph Dimension = log V / log D",
   "Ball Dim" -> "Final Ball Growth Dimension (volume-growth fit)",
   "Ball Curv" -> "Final Ball Growth Curvature (volume-growth fit)",
   "Stability" -> "Stability Score = 1/(1 + tail diameter); higher = more converged",
   "V(n)" -> "Vertex count per iteration", "D(n)" -> "Graph diameter per iteration",
   "Volume Growth" -> "Ball Volume Growth per iteration", "Log Diff Q" -> "Log Difference Quotients q(r) = d log V / d log r",
   "Dimensions" -> "Ball growth dimension per iteration", "Curvatures" -> "Ball growth curvature per iteration"|>;
row[id_] := With[{r = data[id]}, <|"Rule" -> Hyperlink[id, url[id]], "State" -> r["StateThumb"],
   "Gen" -> r["Generation"], "Vertices" -> r["Vertices"], "Edges" -> r["Edges"], "Diameter" -> r["Diameter"],
   "Vertex Growth" -> rnd[r["VertexGrowth"], 0.1], "Diameter Growth" -> rnd[r["DiameterGrowth"], 0.01],
   "Graph Dim" -> rnd[r["GraphDimension"], 0.01], "Ball Dim" -> ar[r["Dimension"], r["DimensionError"]],
   "Ball Curv" -> ar[r["Curvature"], r["CurvatureError"]], "Stability" -> rnd[r["StabilityScore"], 0.001],
   "V(n)" -> r["VertexThumb"], "D(n)" -> r["DiameterThumb"], "Volume Growth" -> r["VolumeThumb"],
   "Log Diff Q" -> r["LDQThumb"], "Dimensions" -> r["DimThumb"], "Curvatures" -> r["CurvThumb"]|>];
defaultColumns = {"Rule", "State", "Gen", "Vertices", "Edges", "Diameter", "Vertex Growth", "Diameter Growth",
   "Graph Dim", "Ball Dim", "Ball Curv", "Stability", "V(n)", "D(n)", "Volume Growth", "Log Diff Q", "Dimensions", "Curvatures"};
buildTable[ids_, cols_ : defaultColumns] := Dataset[(KeyTake[row[#], cols]) & /@ ids,
   Alignment -> {Center, Center}, MaxItems -> {25, All}, ItemStyle -> {FontSize -> 14},
   HeaderStyle -> Directive[FontSize -> 14, Bold], HeaderDisplayFunction -> (Tooltip[#, Lookup[headerTips, #, #]] &)];
rangeTable[cols_ : defaultColumns, perPage_ : 10] := DynamicModule[{ids = Keys[data], n = Length[data], range},
   range = {1, Min[perPage, n]};
   Column[{Row[{"rules ", InputField[Dynamic[range[[1]]], Number, FieldSize -> 4], " to ",
       InputField[Dynamic[range[[2]]], Number, FieldSize -> 4], " of ", n}],
     Dynamic[With[{a = Clip[Round[Min[range]], {1, n}], b = Clip[Round[Max[range]], {1, n}]},
        buildTable[ids[[a ;; b]], cols]]]}]];
queryData = Dataset[KeyTake[#, {"Dimension", "Curvature", "Vertices", "Diameter", "GraphDimension", "DiameterGrowth", "VertexGrowth", "StabilityScore"}] & /@ data];

landscape[] := Module[{pts},
   pts = Select[{#["Dimension"], #["Curvature"], #["StabilityScore"]} & /@ Values[data], VectorQ[#, NumericQ] &];
   Legended[
     Graphics[{PointSize[0.008], Point[pts[[All, {1, 2}]],
        VertexColors -> (Blend[{StandardRed, StandardGreen}, #] & /@ pts[[All, 3]])]},
      Frame -> True, FrameLabel -> {"dimension", "curvature"}, Background -> White, ImageSize -> 560,
      AspectRatio -> 1/GoldenRatio, PlotLabel -> "Dimension-Curvature landscape (color = stability)"],
     BarLegend[{Blend[{StandardRed, StandardGreen}, #] &, {0, 1}}, LegendLabel -> "stability"]]];
```

## Table

Pick a rule range (by order) with the two From/To fields.

```wolfram
rangeTable[]
```

## Dimension-Curvature Landscape

All rules in the (dimension, curvature) plane, colored by stability (red = wandering, green = converged).

```wolfram
landscape[]
```

## Queries

### Dimension 2.5-3.5, near-flat curvature, at least 1000 vertices.

```wolfram
queryData[Select[NumericQ[#Dimension] && 2.5 <= #Dimension <= 3.5 && Abs[#Curvature] < 0.5 && #Vertices >= 1000 &]]
```

### Most converged large rules.

```wolfram
queryData[Select[#Vertices >= 500 && NumericQ[#StabilityScore] &]][TakeLargestBy["StabilityScore", 25]]
```

### Recommended ranking: stability score times sqrt(vertices).

```wolfram
queryData[ReverseSortBy[#StabilityScore Sqrt[#Vertices] &]][;; 25]
```

### Fastest-expanding rules (by diameter growth).

```wolfram
queryData[TakeLargestBy["DiameterGrowth", 15]]
```