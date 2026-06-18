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
   "V(n)" -> "Vertex count per iteration", "D(n)" -> "Graph diameter per iteration",
   "Volume Growth" -> "Ball Volume Growth per iteration", "Log Diff Q" -> "Log Difference Quotients q(r)",
   "Dimensions" -> "Ball growth dimension per iteration", "Curvatures" -> "Ball growth curvature per iteration"|>;
row[id_] := With[{r = table[id]}, <|"Rule" -> Hyperlink[id, url[id]], "State" -> r["StateThumb"],
   "Gen" -> r["Generation"], "Vertices" -> r["Vertices"], "Edges" -> r["Edges"], "Diameter" -> r["Diameter"],
   "Vertex Growth" -> rnd[r["VertexGrowth"], 0.1], "Diameter Growth" -> rnd[r["DiameterGrowth"], 0.01],
   "Graph Dim" -> rnd[r["GraphDimension"], 0.01], "Ball Dim" -> ar[r["Dimension"], r["DimensionError"]],
   "Ball Curv" -> ar[r["Curvature"], r["CurvatureError"]], "Stability" -> rnd[r["StabilityScore"], 0.001],
   "V(n)" -> r["VertexThumb"], "D(n)" -> r["DiameterThumb"], "Volume Growth" -> r["VolumeThumb"],
   "Log Diff Q" -> r["LDQThumb"], "Dimensions" -> r["DimThumb"], "Curvatures" -> r["CurvThumb"]|>];
cols = {"Rule", "State", "Gen", "Vertices", "Edges", "Diameter", "Vertex Growth", "Diameter Growth",
   "Graph Dim", "Ball Dim", "Ball Curv", "Stability", "V(n)", "D(n)", "Volume Growth", "Log Diff Q", "Dimensions", "Curvatures"};
tableOf[ids_] := Dataset[(KeyTake[row[#], cols]) & /@ ids, Alignment -> {Center, Center}, MaxItems -> {25, All},
   ItemStyle -> {FontSize -> 13}, HeaderStyle -> Directive[FontSize -> 13, Bold], HeaderDisplayFunction -> (Tooltip[#, Lookup[headerTips, #, #]] &)];
landscape := Module[{pts = Select[{#["Dimension"], #["Curvature"], #["StabilityScore"]} & /@ Values[table], VectorQ[#, NumericQ] &]},
   Legended[Graphics[{PointSize[0.008], Point[pts[[All, {1, 2}]], VertexColors -> (Blend[{StandardRed, StandardGreen}, #] & /@ pts[[All, 3]])]},
      Frame -> True, FrameLabel -> {"dimension", "curvature"}, Background -> White, ImageSize -> 620, AspectRatio -> 1/GoldenRatio,
      PlotLabel -> "Dimension-Curvature landscape of all " <> ToString[Length[pts]] <> " rules (color = stability)"],
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
