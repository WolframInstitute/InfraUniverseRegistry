#!/usr/bin/env wolframscript
(* Generate Notebooks/VolumeGrowth_Table.{nb,md} and _Single.{nb,md}, both fully evaluated
   (input + output) so they render statically in the Wolfram Cloud without a kernel.

   Table is self-contained: the data (20 featured rows with BIG rasterized bitmap thumbnails +
   every rule's scalars) and the definitions live in a FOLDED Initialization section at the END;
   the display cells above are pre-evaluated, and re-evaluating the notebook gives the live,
   interactive Dataset. Everything is computed from the (std) raw data - no table.wxf needed.

   Error bars are the standard deviation of ball volume across all center vertices. *)

scriptDir = DirectoryName[$InputFileName];
root = ParentDirectory[scriptDir];
nbDir = FileNameJoin[{root, "Notebooks"}];

(* ---------- shared compute; BIG rasterized thumbnails for the 20 featured rows ---------- *)
Get[FileNameJoin[{root, "Code", "VolumeGrowth.wl"}]];
thumbOpts = Sequence[ImageSize -> 200, AspectRatio -> 0.8, Frame -> True, PlotRangePadding -> Scaled[0.03],
   ImagePadding -> {{48, 8}, {28, 8}}, Background -> White, BaseStyle -> {FontSize -> 17},
   Mesh -> All, MeshStyle -> Directive[PointSize[0.018], Black]];
finalStateThumb[rec_] := TimeConstrained[Quiet @ Rasterize[WolframModelPlot[rec["FinalState"], ImageSize -> {UpTo[300], UpTo[300]}], ImageResolution -> 72], 120, dash];

raw = Select[Import[FileNameJoin[{root, "Data", "AverageVolumeGrowths.wxf"}]], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
scalarOf[rec_] := <|"Dimension" -> dimension[rec], "DimensionError" -> dimensionError[rec], "Curvature" -> curvature[rec],
   "CurvatureError" -> curvatureError[rec], "Vertices" -> Last[rec["VertexCounts"]], "Diameter" -> finalDiameter[rec],
   "GraphDimension" -> graphDimension[rec], "DiameterGrowth" -> diameterGrowth[rec], "VertexGrowth" -> vertexGrowth[rec],
   "StabilityScore" -> stabilityScore[rec]|>;
scalarData = scalarOf /@ raw;
ranked = ReverseSortBy[Select[Normal[scalarData], NumericQ[#[[2]]["StabilityScore"]] && NumericQ[#[[2]]["Vertices"]] &], (#[[2]]["StabilityScore"] #[[2]]["Vertices"]) &];
top20 = ranked[[;; UpTo[20], 1]];
Print["featured (largest x most stable): ", top20];
featuredRows = Association[(# -> tableRow[#, raw[#]]) & /@ top20];

tableDefs = Import[FileNameJoin[{scriptDir, "VolumeGrowth_TableInit.wl"}], "Text"];
ToExpression[tableDefs];
dataBlob = StringRiffle[{
    "featuredRows = Uncompress[" <> ToString[Compress[featuredRows], InputForm] <> "];",
    "scalarData = Uncompress[" <> ToString[Compress[scalarData], InputForm] <> "];"}, "\n\n"];

q1 = "queryData[scalarData][Select[NumericQ[#Dimension] && 2.5 <= #Dimension <= 3.5 && Abs[#Curvature] < 0.5 && #Vertices >= 1000 &]]";
q2 = "queryData[scalarData][Select[#Vertices >= 500 && NumericQ[#StabilityScore] &]][TakeLargestBy[\"StabilityScore\", 25]]";
q3 = "queryData[scalarData][ReverseSortBy[#StabilityScore Sqrt[#Vertices] &]][;; 25]";
q4 = "queryData[scalarData][TakeLargestBy[\"DiameterGrowth\", 15]]";

(* ---------- emit helpers ---------- *)
ioCells[code_, expr_] := {Cell[BoxData[code], "Input"], Cell[BoxData[ToBoxes[expr]], "Output"]};
toMd = Replace[#, {Cell[t_String, "Title"] :> "# " <> t, Cell[t_String, "Section"] :> "## " <> t,
     Cell[t_String, "Subsection"] :> "### " <> t, Cell[t_String, "Text"] :> t,
     Cell[BoxData[c_String], "Input", ___] :> "```wolfram\n" <> c <> "\n```",
     Cell[BoxData[_], "Output"] :> Nothing, Cell[BoxData[_], "Input", ___] :> Nothing}] &;
flatten = Flatten[{#}] /. Cell[CellGroupData[cs_List, _]] :> Sequence @@ cs &;
emit[base_, cells_] := (Export[FileNameJoin[{nbDir, base <> ".nb"}], Notebook @ Flatten[{cells}]];
   Export[FileNameJoin[{nbDir, base <> ".md"}], StringRiffle[DeleteCases[toMd /@ flatten[cells], ""], "\n\n"], "Text"]);

(* ---------- Table: pre-evaluated display + folded init at end ---------- *)
emit["VolumeGrowth_Table", {
   Cell["Volume Growth: Table", "Title"],
   Cell["Dimension-Curvature Landscape", "Section"],
   ioCells["landscape[scalarData]", landscape[scalarData]],
   Cell["Featured Rules", "Section"],
   ioCells["buildTable[featuredRows]", buildTable[featuredRows]],
   Cell["Queries", "Section"],
   Cell["Queries run over the scalars of all rules.", "Text"],
   Cell["Dimension 2.5-3.5, near-flat curvature, at least 1000 vertices.", "Subsection"], ioCells[q1, ToExpression[q1]],
   Cell["Most converged large rules.", "Subsection"], ioCells[q2, ToExpression[q2]],
   Cell["Recommended ranking: stability score times sqrt(vertices).", "Subsection"], ioCells[q3, ToExpression[q3]],
   Cell["Fastest-expanding rules (by diameter growth).", "Subsection"], ioCells[q4, ToExpression[q4]],
   Cell[CellGroupData[{
      Cell["Initialization", "Section"],
      Cell["Self-contained: 20 featured rows (bitmap thumbnails) + all-rule scalars, then the definitions. The cells above are pre-evaluated; re-evaluate the notebook for the live, interactive Dataset.", "Text"],
      Cell[BoxData[dataBlob], "Input", InitializationCell -> True],
      Cell[BoxData[tableDefs], "Input", InitializationCell -> True]}, Closed]]}];
Print["wrote VolumeGrowth_Table  (nb ", Round[FileByteCount[FileNameJoin[{nbDir, "VolumeGrowth_Table.nb"}]]/1.*^6, 0.1], " MB)"];

(* ---------- Single: fully evaluated ---------- *)
singleInit = Import[FileNameJoin[{scriptDir, "VolumeGrowth_SingleInit.wl"}], "Text"];
ToExpression[StringReplace[singleInit, "ParentDirectory[NotebookDirectory[]]" -> ToString[root, InputForm]]];

exGraphs = "With[{rule = wmd[exId, \"Rule\"], init = wmd[exId, \"InitialCondition\"]}, GraphicsGrid[Partition[WolframModelPlot[#, ImageSize -> {UpTo[120], UpTo[120]}] & /@ Rest[WolframModel[rule, init, spec][\"StatesList\"]], UpTo[5]]]]";
exVolumes = "With[{vol = data[exId][\"Growths\"]}, ListLinePlot[vol, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[vol], StandardYellow, StandardRed]), IntervalMarkers -> \"Bars\", Mesh -> All, Frame -> True, FrameLabel -> {\"Radius\", \"Ball Volume\"}, ImageSize -> 460, PlotRange -> All]]";
exLDQ = "With[{q = LogDifferenceQuotients /@ data[exId][\"Growths\"]}, ListLinePlot[q, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[q], StandardYellow, StandardGreen]), IntervalMarkers -> \"Bars\", Mesh -> All, Frame -> True, FrameLabel -> {\"Radius\", \"Log Difference Quotient\"}, ImageSize -> 460, PlotRange -> All]]";
exDimCurv = "With[{dc = dimcurvSeq[data[exId]]}, GraphicsRow[{ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[1]]} &, dc], {_, _Missing}], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkers -> \"Bars\", IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> {\"Iteration\", \"Dimension\"}], ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[2]]} &, dc], {_, _Missing}], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkers -> \"Bars\", IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> {\"Iteration\", \"Curvature\"}]}, ImageSize -> 640]]";
exVertexEdgeDiam = "With[{vc = data[exId][\"VertexCounts\"], ec = data[exId][\"EdgeCounts\"], dia = data[exId][\"Diameters\"]}, GraphicsRow[{ListLinePlot[vc, PlotStyle -> Directive[AbsoluteThickness[2], StandardBrown], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Vertices\"}], ListLinePlot[ec, PlotStyle -> Directive[AbsoluteThickness[2], StandardRed], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Edges\"}], ListLinePlot[dia, PlotStyle -> Directive[AbsoluteThickness[2], StandardOrange], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Diameter\"}], ListLinePlot[DeleteCases[Table[If[dia[[i]] > 1, {i, Log[vc[[i]]]/Log[dia[[i]]]}, Null], {i, Length[vc]}], Null], PlotStyle -> Directive[AbsoluteThickness[2], StandardBlue], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Graph Dimension\"}]}, ImageSize -> 900]]";
exStabilityRow = "With[{tt = Select[MapIndexed[{First[#2], #1[[1]], #1[[2]], data[exId][\"VertexCounts\"][[First[#2]]]} &, dimcurvSeq[data[exId]] /. Around[a_, _] :> a], NumericQ[#[[2]]] && NumericQ[#[[3]]] &]}, With[{pts = tt[[All, {2, 3}]], gens = tt[[All, 1]], cols = Blend[{StandardGray, StandardRed}, #] & /@ Rescale[tt[[All, 4]]]}, GraphicsRow[{Graphics[{Arrowheads[{{0.05, 0.5}}], Table[{cols[[i + 1]], Arrow[{pts[[i]], pts[[i + 1]]}]}, {i, Length[pts] - 1}], PointSize[0.015], Table[{cols[[i]], Point[pts[[i]]]}, {i, Length[pts]}], Black, Table[Text[Style[gens[[i]], 10], pts[[i]], {-1.3, -1.3}], {i, Length[pts]}]}, Frame -> True, FrameLabel -> {\"Dimension\", \"Curvature\"}, Background -> White, PlotLabel -> \"Geometry Trajectory\"], ListLinePlot[Table[Max[EuclideanDistance @@@ Subsets[pts[[n0 ;;]], {2}]], {n0, 1, Length[pts] - 1}], Mesh -> All, PlotStyle -> Directive[StandardYellow, AbsoluteThickness[2]], Frame -> True, FrameLabel -> {\"N0\", \"Tail Diameter\"}, PlotLabel -> \"Cauchy Tail\"]}, ImageSize -> 720]]]";

emit["VolumeGrowth_Single", {
   Cell["Volume Growth: Single Rule", "Title"],
   Cell["Initialization", "Section"], Cell[BoxData @ singleInit, "Input", InitializationCell -> True],
   Cell["Generations", "Section"], ioCells[exGraphs, ToExpression[exGraphs]],
   Cell["Volume Growth", "Section"], ioCells[exVolumes, ToExpression[exVolumes]],
   Cell["Log Difference Quotients", "Section"], ioCells[exLDQ, ToExpression[exLDQ]],
   Cell["Dimension and Curvature", "Section"], ioCells[exDimCurv, ToExpression[exDimCurv]],
   Cell["Vertex and Edge Count and Diameter", "Section"], ioCells[exVertexEdgeDiam, ToExpression[exVertexEdgeDiam]],
   Cell["Geometric Stability", "Section"], ioCells[exStabilityRow, ToExpression[exStabilityRow]]}];
Print["wrote VolumeGrowth_Single  (nb ", Round[FileByteCount[FileNameJoin[{nbDir, "VolumeGrowth_Single.nb"}]]/1.*^6, 0.1], " MB)"];
