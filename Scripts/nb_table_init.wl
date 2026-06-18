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
   "Vertices/gen" -> "Vertex count per iteration", "Diameter/gen" -> "Graph diameter per iteration",
   "Volume Growth" -> "Ball Volume Growth per iteration", "Log Diff Q" -> "Log Difference Quotients q(r) = d log V / d log r",
   "Dimensions" -> "Ball growth dimension per iteration", "Curvatures" -> "Ball growth curvature per iteration"|>;
row[id_] := With[{r = data[id]}, <|"Rule" -> Hyperlink[id, url[id]], "State" -> r["StateThumb"],
   "Gen" -> r["Generation"], "Vertices" -> r["Vertices"], "Edges" -> r["Edges"], "Diameter" -> r["Diameter"],
   "Vertex Growth" -> rnd[r["VertexGrowth"], 0.1], "Diameter Growth" -> rnd[r["DiameterGrowth"], 0.01],
   "Graph Dim" -> rnd[r["GraphDimension"], 0.01], "Ball Dim" -> ar[r["Dimension"], r["DimensionError"]],
   "Ball Curv" -> ar[r["Curvature"], r["CurvatureError"]], "Stability" -> rnd[r["StabilityScore"], 0.001],
   "Vertices/gen" -> r["VertexThumb"], "Diameter/gen" -> r["DiameterThumb"], "Volume Growth" -> r["VolumeThumb"],
   "Log Diff Q" -> r["LDQThumb"], "Dimensions" -> r["DimThumb"], "Curvatures" -> r["CurvThumb"]|>];
defaultColumns = {"Rule", "State", "Gen", "Edges", "Vertices", "Vertex Growth", "Vertices/gen",
   "Diameter", "Diameter Growth", "Diameter/gen", "Graph Dim", "Ball Dim", "Dimensions",
   "Ball Curv", "Curvatures", "Volume Growth", "Log Diff Q", "Stability"};
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

landscape[] := Module[{pts, ds, cs},
   pts = Select[{#1, #2["Dimension"], #2["Curvature"], #2["StabilityScore"]} & @@@ Normal[data],
      NumericQ[#[[2]]] && NumericQ[#[[3]]] && NumericQ[#[[4]]] &];
   ds = pts[[All, 2]]; cs = pts[[All, 3]];
   Legended[
     Graphics[Table[Tooltip[{Blend[{StandardRed, StandardGreen}, p[[4]]], PointSize[0.011], Point[{p[[2]], p[[3]]}]},
         Column[{Style[p[[1]], Bold], Row[{"dim ", Round[p[[2]], 0.01], "   curv ", Round[p[[3]], 0.01], "   stab ", Round[p[[4]], 0.01]}]}]], {p, pts}],
      Frame -> True, FrameLabel -> {"dimension", "curvature"},
      PlotRange -> {Quantile[ds, {0.05, 0.95}], Quantile[cs, {0.05, 0.95}]}, Background -> White,
      ImageSize -> 580, AspectRatio -> 1/GoldenRatio, PlotLabel -> "Dimension-Curvature landscape (color = stability; hover for rule)"],
     BarLegend[{Blend[{StandardRed, StandardGreen}, #] &, {0, 1}}, LegendLabel -> "stability"]]];
