(* Definitions for the Table notebook. Pure functions: each takes its data as an argument and
   uses nothing else. The notebook embeds two data objects above this cell (Uncompress blobs):
   featuredRows (20 largest/most-stable rules, fully rendered rows) and scalarData (per-rule
   scalars for all rules). No paclet, no external files. *)
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
defaultColumns = {"Rule", "State", "Generation", "Edges", "Vertices", "Vertex Growth", "Vertices/gen", "Diameter",
   "Diameter Growth", "Diameter/gen", "Graph Dimension", "Dimension", "Dimensions", "Curvature", "Curvatures",
   "Volume Growth", "Log Diff Q", "Stability Score"};
row[rows_, id_] := With[{r = rows[id]}, <|"Rule" -> Hyperlink[id, url[id]], "State" -> r["StateThumb"],
   "Generation" -> r["Generation"], "Edges" -> r["Edges"], "Vertices" -> r["Vertices"],
   "Vertex Growth" -> rnd[r["VertexGrowth"], 0.1], "Vertices/gen" -> r["VertexThumb"],
   "Diameter" -> r["Diameter"], "Diameter Growth" -> rnd[r["DiameterGrowth"], 0.01], "Diameter/gen" -> r["DiameterThumb"],
   "Graph Dimension" -> rnd[r["GraphDimension"], 0.01], "Dimension" -> ar[r["Dimension"], r["DimensionError"]], "Dimensions" -> r["DimThumb"],
   "Curvature" -> ar[r["Curvature"], r["CurvatureError"]], "Curvatures" -> r["CurvThumb"],
   "Volume Growth" -> r["VolumeThumb"], "Log Diff Q" -> r["LDQThumb"], "Stability Score" -> rnd[r["StabilityScore"], 0.001]|>];
buildTable[rows_, ids_ : Automatic, cols_ : defaultColumns] := Dataset[(KeyTake[row[rows, #], cols]) & /@ Replace[ids, Automatic :> Keys[rows]],
   Alignment -> {Center, Center}, MaxItems -> {25, All}, ItemStyle -> {FontSize -> 15}, HeaderStyle -> Directive[FontSize -> 15, Bold],
   HeaderDisplayFunction -> (Tooltip[#, Lookup[headerTips, #, #]] &)];
queryData[scalars_] := Dataset[scalars];

landscape[scalars_] := Module[{cf, pts, ds, cs, dr, cr, inr},
   cf = Blend[{StandardGray, StandardGreen}, #] &;
   pts = Select[{#1, #2["Dimension"], #2["DimensionError"], #2["Curvature"], #2["CurvatureError"], #2["StabilityScore"]} & @@@ Normal[scalars],
      NumericQ[#[[2]]] && NumericQ[#[[4]]] && NumericQ[#[[6]]] &];
   ds = pts[[All, 2]]; cs = pts[[All, 4]];
   dr = Quantile[ds, {0.02, 0.98}]; cr = Quantile[cs, {0.02, 0.98}];
   inr = Select[pts, dr[[1]] <= #[[2]] <= dr[[2]] && cr[[1]] <= #[[4]] <= cr[[2]] &];
   Legended[
     Graphics[Table[Tooltip[{cf[p[[6]]], PointSize[0.011], Point[{p[[2]], p[[4]]}]},
         Column[{Style[p[[1]], Bold], Row[{"dim ", Around[p[[2]], p[[3]]], "   curv ", Around[p[[4]], p[[5]]]}]}]], {p, inr}],
      Frame -> True, FrameLabel -> {"Dimension", "Curvature"}, PlotRange -> {dr, cr}, Background -> White,
      ImageSize -> 640, AspectRatio -> 1/GoldenRatio],
     BarLegend[{cf, {0, 1}}, LegendLabel -> "Stability Score", LegendMarkerSize -> 300]]];
