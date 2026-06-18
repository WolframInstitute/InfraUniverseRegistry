#!/usr/bin/env wolframscript
(* Generate Notebooks/VolumeGrowth_Table.{nb,md} and _Single.{nb,md}, fully evaluated
   (input + output cells) so they render statically in the Wolfram Cloud.
   Table: self-contained (featuredRows = 20 largest/most-stable rules with big thumbnails,
   scalarData = all rules' scalars; both embedded as Uncompress blobs). No external files,
   no paclet at view time. Single: one example rule's full characteristics via Code/VolumeGrowth.wl. *)

scriptDir = DirectoryName[$InputFileName];
root = ParentDirectory[scriptDir];
nbDir = FileNameJoin[{root, "Notebooks"}];

(* ---------- shared compute, with LARGE thumbnails for the 20 cloud rules ---------- *)
Get[FileNameJoin[{root, "Code", "VolumeGrowth.wl"}]];
thumbOpts = Sequence[ImageSize -> 200, AspectRatio -> 0.8, Frame -> True, PlotRangePadding -> Scaled[0.03],
   ImagePadding -> {{48, 8}, {28, 8}}, Background -> White, BaseStyle -> {FontSize -> 17},
   Mesh -> All, MeshStyle -> Directive[PointSize[0.018], Black]];
finalStateThumb[rec_] := TimeConstrained[Quiet @ Rasterize[WolframModelPlot[rec["FinalState"], ImageSize -> {UpTo[260], UpTo[260]}], ImageResolution -> 72], 120, dash];

cached = Import[FileNameJoin[{root, "Data", "table.wxf"}]];
raw = Select[Import[FileNameJoin[{root, "Data", "AverageVolumeGrowths.wxf"}]], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
ranked = ReverseSortBy[Select[Normal[cached], NumericQ[#[[2]]["StabilityScore"]] && NumericQ[#[[2]]["Vertices"]] &], (#[[2]]["StabilityScore"] #[[2]]["Vertices"]) &];
top20 = ranked[[;; UpTo[20], 1]];
Print["featured (largest x most stable): ", top20];
featuredRows = Association[(# -> tableRow[#, raw[#]]) & /@ top20];
scalarKeys = {"Dimension", "DimensionError", "Curvature", "CurvatureError", "Vertices", "Diameter", "GraphDimension", "DiameterGrowth", "VertexGrowth", "StabilityScore"};
scalarData = Association[(# -> KeyTake[cached[#], scalarKeys]) & /@ Keys[cached]];

(* table definitions, shared verbatim with the notebook init cell *)
tableDefs = Import[FileNameJoin[{scriptDir, "nb_table_init.wl"}], "Text"];
ToExpression[tableDefs];
tableInitCell = StringRiffle[{
    "featuredRows = Uncompress[" <> ToString[Compress[featuredRows], InputForm] <> "];",
    "scalarData = Uncompress[" <> ToString[Compress[scalarData], InputForm] <> "];",
    tableDefs}, "\n\n"];

q1 = "queryData[Select[NumericQ[#Dimension] && 2.5 <= #Dimension <= 3.5 && Abs[#Curvature] < 0.5 && #Vertices >= 1000 &]]";
q2 = "queryData[Select[#Vertices >= 500 && NumericQ[#StabilityScore] &]][TakeLargestBy[\"StabilityScore\", 25]]";
q3 = "queryData[ReverseSortBy[#StabilityScore Sqrt[#Vertices] &]][;; 25]";
q4 = "queryData[TakeLargestBy[\"DiameterGrowth\", 15]]";

(* ---------- single-rule environment ---------- *)
singleInit = Import[FileNameJoin[{scriptDir, "nb_single_init.wl"}], "Text"];
exGraphs = "With[{rule = wmd[exId, \"Rule\"], init = wmd[exId, \"InitialCondition\"]}, GraphicsGrid[Partition[WolframModelPlot[#, ImageSize -> {UpTo[120], UpTo[120]}] & /@ Rest[WolframModel[rule, init, spec][\"StatesList\"]], UpTo[5]]]]";
exVolumes = "With[{vol = data[exId][\"Growths\"]}, ListLinePlot[vol, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[vol], StandardYellow, StandardRed]), IntervalMarkers -> \"Fences\", Mesh -> All, Frame -> True, FrameLabel -> {\"Radius\", \"Ball Volume\"}, ImageSize -> 460, PlotRange -> All]]";
exLDQ = "With[{q = LogDifferenceQuotients /@ data[exId][\"Growths\"]}, ListLinePlot[q, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[q], StandardYellow, StandardGreen]), IntervalMarkers -> \"Fences\", Mesh -> All, Frame -> True, FrameLabel -> {\"Radius\", \"Log Difference Quotient\"}, ImageSize -> 460, PlotRange -> All]]";
exDimCurv = "With[{dc = dimcurvSeq[data[exId]]}, GraphicsRow[{ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[1]]} &, dc], {_, _Missing}], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> {\"Iteration\", \"Dimension\"}], ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[2]]} &, dc], {_, _Missing}], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> {\"Iteration\", \"Curvature\"}]}, ImageSize -> 640]]";
exVertexEdgeDiam = "With[{vc = data[exId][\"VertexCounts\"], ec = data[exId][\"EdgeCounts\"], dia = data[exId][\"Diameters\"]}, GraphicsRow[{ListLinePlot[vc, PlotStyle -> Directive[AbsoluteThickness[2], StandardBrown], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Vertices\"}], ListLinePlot[ec, PlotStyle -> Directive[AbsoluteThickness[2], StandardRed], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Edges\"}], ListLinePlot[dia, PlotStyle -> Directive[AbsoluteThickness[2], StandardOrange], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Diameter\"}], ListLinePlot[DeleteCases[Table[If[dia[[i]] > 1, {i, Log[vc[[i]]]/Log[dia[[i]]]}, Null], {i, Length[vc]}], Null], PlotStyle -> Directive[AbsoluteThickness[2], StandardBlue], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Graph Dimension\"}]}, ImageSize -> 900]]";
exStabilityRow = "With[{tt = Select[MapIndexed[{First[#2], #1[[1]], #1[[2]], data[exId][\"VertexCounts\"][[First[#2]]]} &, dimcurvSeq[data[exId]] /. Around[a_, _] :> a], NumericQ[#[[2]]] && NumericQ[#[[3]]] &]}, With[{pts = tt[[All, {2, 3}]], gens = tt[[All, 1]], cols = Blend[{StandardGray, StandardRed}, #] & /@ Rescale[tt[[All, 4]]]}, GraphicsRow[{Graphics[{Arrowheads[{{0.05, 0.5}}], Table[{cols[[i + 1]], Arrow[{pts[[i]], pts[[i + 1]]}]}, {i, Length[pts] - 1}], PointSize[0.015], Table[{cols[[i]], Point[pts[[i]]]}, {i, Length[pts]}], Black, Table[Text[Style[gens[[i]], 10], pts[[i]], {-1.3, -1.3}], {i, Length[pts]}]}, Frame -> True, FrameLabel -> {\"Dimension\", \"Curvature\"}, Background -> White, PlotLabel -> \"Geometry Trajectory\"], ListLinePlot[Table[Max[EuclideanDistance @@@ Subsets[pts[[n0 ;;]], {2}]], {n0, 1, Length[pts] - 1}], Mesh -> All, PlotStyle -> Directive[StandardYellow, AbsoluteThickness[2]], Frame -> True, FrameLabel -> {\"N0\", \"Tail Diameter\"}, PlotLabel -> \"Cauchy Tail\"]}, ImageSize -> 720]]]";

(* ---------- emit helpers ---------- *)
ioCells[code_, expr_] := {Cell[BoxData[code], "Input"], Cell[BoxData[ToBoxes[expr]], "Output"]};
toMd = Replace[#, {Cell[t_String, "Title"] :> "# " <> t, Cell[t_String, "Section"] :> "## " <> t,
     Cell[t_String, "Subsection"] :> "### " <> t, Cell[t_String, "Text"] :> t,
     Cell[BoxData[c_String], "Input"] :> "```wolfram\n" <> c <> "\n```",
     Cell[BoxData[_], "Output"] :> Nothing, Cell[BoxData[_], "Input"] :> Nothing}] &;
emit[base_, cells_] := (Export[FileNameJoin[{nbDir, base <> ".nb"}], Notebook @ Flatten[{cells}]];
   Export[FileNameJoin[{nbDir, base <> ".md"}], StringRiffle[DeleteCases[toMd /@ Flatten[{cells}], ""], "\n\n"], "Text"]);

emit["VolumeGrowth_Table", {
   Cell["Volume Growth: Table", "Title"],
   Cell["Initialization", "Section"], Cell[BoxData @ tableInitCell, "Input", InitializationCell -> True],
   Cell["Dimension-Curvature Landscape", "Section"],
   Cell["All rules in the (dimension, curvature) plane, colored by stability (red = wandering, green = converged). Hover a point for its rule.", "Text"],
   ioCells["landscape[]", landscape[]],
   Cell["Featured Rules", "Section"],
   Cell["The 20 rules with the largest, most stable final state. Hover a column header for its description.", "Text"],
   ioCells["buildTable[featured]", buildTable[featured]],
   Cell["Queries", "Section"],
   Cell["Queries run over the scalars of all rules.", "Text"],
   Cell["Dimension 2.5-3.5, near-flat curvature, at least 1000 vertices.", "Subsection"], ioCells[q1, ToExpression[q1]],
   Cell["Most converged large rules.", "Subsection"], ioCells[q2, ToExpression[q2]],
   Cell["Recommended ranking: stability score times sqrt(vertices).", "Subsection"], ioCells[q3, ToExpression[q3]],
   Cell["Fastest-expanding rules (by diameter growth).", "Subsection"], ioCells[q4, ToExpression[q4]]}];
Print["wrote VolumeGrowth_Table"];

(* now load the single-rule environment (re-Gets Code, resetting thumbOpts to compact - unused here) *)
ToExpression[StringReplace[singleInit, "ParentDirectory[NotebookDirectory[]]" -> ToString[root, InputForm]]];
emit["VolumeGrowth_Single", {
   Cell["Volume Growth: Single Rule", "Title"],
   Cell["Initialization", "Section"], Cell[BoxData @ singleInit, "Input", InitializationCell -> True],
   Cell["Generations", "Section"], ioCells[exGraphs, ToExpression[exGraphs]],
   Cell["Volume Growth", "Section"], ioCells[exVolumes, ToExpression[exVolumes]],
   Cell["Log Difference Quotients", "Section"], ioCells[exLDQ, ToExpression[exLDQ]],
   Cell["Dimension and Curvature", "Section"], ioCells[exDimCurv, ToExpression[exDimCurv]],
   Cell["Vertex and Edge Count and Diameter", "Section"], ioCells[exVertexEdgeDiam, ToExpression[exVertexEdgeDiam]],
   Cell["Geometric Stability", "Section"], ioCells[exStabilityRow, ToExpression[exStabilityRow]]}];
Print["wrote VolumeGrowth_Single"];
