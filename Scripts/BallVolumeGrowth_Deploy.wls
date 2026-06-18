#!/usr/bin/env wolframscript
(* Deploy a small PUBLIC cloud object: all-rules dimension-curvature landscape (colored by
   stability) + a curated 20-row table of the largest, most stable rules. Static, a few MB. *)
dir = ParentDirectory[DirectoryName[$InputFileName]];
table = Import[FileNameJoin[{dir, "Data", "table.wxf"}]];

url[id_] := "https://www.wolframphysics.org/universes/" <> id <> "/";
dash = Style["\[LongDash]", GrayLevel[0.55], 20];
ar[v_, e_] := If[NumericQ[v], Around[v, e], dash];
rnd[x_, d_] := If[NumericQ[x], Round[x, d], dash];
headerTips = <|"Rule" -> "Rule Name", "State" -> "Final State", "Gen" -> "Final Generation",
   "Vertices" -> "Final Vertex Count", "Edges" -> "Final Edge Count", "Diameter" -> "Final Graph Diameter",
   "Vertex Growth" -> "Vertex-count growth rate per generation (0 static, + expanding, - shrinking)",
   "Diameter Growth" -> "Diameter growth rate per generation (0 static, + expanding, - shrinking)",
   "Graph Dim" -> "Final Graph Dimension = log V / log D", "Ball Dim" -> "Final Ball Growth Dimension",
   "Ball Curv" -> "Final Ball Growth Curvature", "Stability" -> "Stability Score (higher = more converged)",
   "Vertices/gen" -> "Vertex count per iteration", "Diameter/gen" -> "Graph diameter per iteration",
   "Volume Growth" -> "Ball Volume Growth per iteration", "Log Diff Q" -> "Log Difference Quotients q(r)",
   "Dimensions" -> "Ball growth dimension per iteration", "Curvatures" -> "Ball growth curvature per iteration"|>;
row[id_] := With[{r = table[id]}, <|"Rule" -> Hyperlink[id, url[id]], "State" -> r["StateThumb"],
   "Gen" -> r["Generation"], "Vertices" -> r["Vertices"], "Edges" -> r["Edges"], "Diameter" -> r["Diameter"],
   "Vertex Growth" -> rnd[r["VertexGrowth"], 0.1], "Diameter Growth" -> rnd[r["DiameterGrowth"], 0.01],
   "Graph Dim" -> rnd[r["GraphDimension"], 0.01], "Ball Dim" -> ar[r["Dimension"], r["DimensionError"]],
   "Ball Curv" -> ar[r["Curvature"], r["CurvatureError"]], "Stability" -> rnd[r["StabilityScore"], 0.001],
   "Vertices/gen" -> r["VertexThumb"], "Diameter/gen" -> r["DiameterThumb"], "Volume Growth" -> r["VolumeThumb"],
   "Log Diff Q" -> r["LDQThumb"], "Dimensions" -> r["DimThumb"], "Curvatures" -> r["CurvThumb"]|>];
cols = {"Rule", "State", "Gen", "Edges", "Vertices", "Vertex Growth", "Vertices/gen",
   "Diameter", "Diameter Growth", "Diameter/gen", "Graph Dim", "Ball Dim", "Dimensions",
   "Ball Curv", "Curvatures", "Volume Growth", "Log Diff Q", "Stability"};
tableOf[ids_] := Dataset[(KeyTake[row[#], cols]) & /@ ids, Alignment -> {Center, Center}, MaxItems -> {25, All},
   ItemStyle -> {FontSize -> 13}, HeaderStyle -> Directive[FontSize -> 13, Bold], HeaderDisplayFunction -> (Tooltip[#, Lookup[headerTips, #, #]] &)];
landscape := Module[{pts, ds, cs},
   pts = Select[{#1, #2["Dimension"], #2["Curvature"], #2["StabilityScore"]} & @@@ Normal[table],
      NumericQ[#[[2]]] && NumericQ[#[[3]]] && NumericQ[#[[4]]] &];
   ds = pts[[All, 2]]; cs = pts[[All, 3]];
   Legended[Graphics[Table[Tooltip[{Blend[{StandardRed, StandardGreen}, p[[4]]], PointSize[0.011], Point[{p[[2]], p[[3]]}]},
         Column[{Style[p[[1]], Bold], Row[{"dim ", Round[p[[2]], 0.01], "   curv ", Round[p[[3]], 0.01], "   stab ", Round[p[[4]], 0.01]}]}]], {p, pts}],
      Frame -> True, FrameLabel -> {"dimension", "curvature"},
      PlotRange -> {Quantile[ds, {0.05, 0.95}], Quantile[cs, {0.05, 0.95}]}, Background -> White, ImageSize -> 640, AspectRatio -> 1/GoldenRatio,
      PlotLabel -> "Dimension-Curvature landscape of all " <> ToString[Length[pts]] <> " rules (color = stability; hover for rule)"],
     BarLegend[{Blend[{StandardRed, StandardGreen}, #] &, {0, 1}}, LegendLabel -> "stability"]]];

ranked = ReverseSortBy[Select[Normal[table], NumericQ[#[[2]]["StabilityScore"]] && NumericQ[#[[2]]["Vertices"]] &], (#[[2]]["StabilityScore"] #[[2]]["Vertices"]) &];
top20 = ranked[[;; UpTo[20], 1]];
Print["top 20: ", top20];
If[! TrueQ[$CloudConnected], CloudConnect[]];
content = Column[{Style["Ball Volume Growth \[Dash] Wolfram Notable Universes", Bold, 24],
   Style["All " <> ToString[Length[table]] <> " rules in the dimension-curvature plane (colored by stability), and the 20 rules with the largest, most stable final state.", GrayLevel[0.4], 14],
   landscape, Style["Top 20: largest, most stable rules", Bold, 18], tableOf[top20]}, Spacings -> 2.5];
obj = CloudDeploy[content, "InfraUniverseRegistry/BallVolumeGrowth", Permissions -> "Public"];
Print["DEPLOYED URL: ", First[obj]];
