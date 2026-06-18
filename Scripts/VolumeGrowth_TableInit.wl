(* Definitions for the Table notebook. Two data objects are assumed already defined above
   (the generator embeds them as Uncompress blobs): featuredRows (the 20 largest, most stable
   rules, fully rendered table rows with big thumbnails) and scalarData (per-rule scalars for
   all rules, for the landscape and the queries). No paclet, no external files. *)
url[id_] := "https://www.wolframphysics.org/universes/" <> id <> "/";
dash = Style["\[LongDash]", GrayLevel[0.55], 20];
ar[v_, e_] := If[NumericQ[v], Around[v, e], dash];
rnd[x_, d_] := If[NumericQ[x], Round[x, d], dash];
headerTips = <|"Rule" -> "Rule Name", "State" -> "Final State", "Generation" -> "Final Generation",
   "Edges" -> "Final Edge Count", "Vertices" -> "Final Vertex Count",
   "Vertex Growth" -> "Vertex-count growth rate per generation (0 static, + expanding, - shrinking)",
   "Vertices/gen" -> "Vertex count per iteration", "Diameter" -> "Final Graph Diameter",
   "Diameter Growth" -> "Diameter growth rate per generation (0 static, + expanding, - shrinking)",
   "Diameter/gen" -> "Graph diameter per iteration", "Graph Dimension" -> "Final Graph Dimension = log V / log D",
   "Dimension" -> "Final Ball Growth Dimension (volume-growth fit)", "Dimensions" -> "Ball growth dimension per iteration",
   "Curvature" -> "Final Ball Growth Curvature (volume-growth fit)", "Curvatures" -> "Ball growth curvature per iteration",
   "Volume Growth" -> "Ball Volume Growth per iteration", "Log Diff Q" -> "Log Difference Quotients q(r) = d log V / d log r",
   "Stability Score" -> "Stability Score = 1/(1 + tail diameter); higher = more converged"|>;
row[id_] := With[{r = featuredRows[id]}, <|"Rule" -> Hyperlink[id, url[id]], "State" -> r["StateThumb"],
   "Generation" -> r["Generation"], "Edges" -> r["Edges"], "Vertices" -> r["Vertices"],
   "Vertex Growth" -> rnd[r["VertexGrowth"], 0.1], "Vertices/gen" -> r["VertexThumb"],
   "Diameter" -> r["Diameter"], "Diameter Growth" -> rnd[r["DiameterGrowth"], 0.01], "Diameter/gen" -> r["DiameterThumb"],
   "Graph Dimension" -> rnd[r["GraphDimension"], 0.01], "Dimension" -> ar[r["Dimension"], r["DimensionError"]], "Dimensions" -> r["DimThumb"],
   "Curvature" -> ar[r["Curvature"], r["CurvatureError"]], "Curvatures" -> r["CurvThumb"],
   "Volume Growth" -> r["VolumeThumb"], "Log Diff Q" -> r["LDQThumb"], "Stability Score" -> rnd[r["StabilityScore"], 0.001]|>];
defaultColumns = {"Rule", "State", "Generation", "Edges", "Vertices", "Vertex Growth", "Vertices/gen", "Diameter",
   "Diameter Growth", "Diameter/gen", "Graph Dimension", "Dimension", "Dimensions", "Curvature", "Curvatures",
   "Volume Growth", "Log Diff Q", "Stability Score"};
buildTable[ids_, cols_ : defaultColumns] := Dataset[(KeyTake[row[#], cols]) & /@ ids, Alignment -> {Center, Center},
   MaxItems -> {25, All}, ItemStyle -> {FontSize -> 15}, HeaderStyle -> Directive[FontSize -> 15, Bold],
   HeaderDisplayFunction -> (Tooltip[#, Lookup[headerTips, #, #]] &)];
featured = Keys[featuredRows];
queryData = Dataset[scalarData];

landscape[] := Module[{pts, ds, cs},
   pts = Select[{#1, #2["Dimension"], #2["Curvature"], #2["StabilityScore"]} & @@@ Normal[scalarData],
      NumericQ[#[[2]]] && NumericQ[#[[3]]] && NumericQ[#[[4]]] &];
   ds = pts[[All, 2]]; cs = pts[[All, 3]];
   Legended[
     Graphics[Table[Tooltip[{Blend[{StandardRed, StandardGreen}, p[[4]]], PointSize[0.011], Point[{p[[2]], p[[3]]}]},
         Column[{Style[p[[1]], Bold], Row[{"dim ", Round[p[[2]], 0.01], "   curv ", Round[p[[3]], 0.01], "   stab ", Round[p[[4]], 0.01]}]}]], {p, pts}],
      Frame -> True, FrameLabel -> {"Dimension", "Curvature"},
      PlotRange -> {Quantile[ds, {0.05, 0.95}], Quantile[cs, {0.05, 0.95}]}, Background -> White,
      ImageSize -> 640, AspectRatio -> 1/GoldenRatio,
      PlotLabel -> "Dimension-Curvature Landscape of All " <> ToString[Length[pts]] <> " Rules (Color = Stability; Hover for Rule)"],
     BarLegend[{Blend[{StandardRed, StandardGreen}, #] &, {0, 1}}, {0, 0.5, 1}, LegendLabel -> "Stability", LegendMarkerSize -> 70]]];
