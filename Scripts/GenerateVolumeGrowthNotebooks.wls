#!/usr/bin/env wolframscript
(* Generate Notebooks/VolumeGrowth_Table.{nb,md} and _Single.{nb,md}, both fully evaluated
   (input + output) so they render statically in the Wolfram Cloud without a kernel.

   Table is self-contained: the data (20 featured rows with BIG rasterized bitmap thumbnails +
   every rule's scalars) and the display defs (lifted verbatim from BuildVolumeGrowthTable.wls,
   between its DISPLAY-BEGIN/DISPLAY-END markers) live in a FOLDED Initialization section at the
   END; the display cells above are pre-evaluated, and re-evaluating the notebook gives the live,
   interactive Dataset. Single is one rule computed live from the paclet (Hypergraph2Section +
   BallVolumes + DimensionCurvatureFit). No Code/ file, no *Init.wl.

   Error bars are the standard deviation of ball volume across all center vertices. *)

scriptDir = DirectoryName[$InputFileName];
root = ParentDirectory[scriptDir];
nbDir = FileNameJoin[{root, "Notebooks"}];

(* shared table-building defs: generation (scalars + thumbnails) + the notebook display block *)
buildScript = FileNameJoin[{scriptDir, "BuildVolumeGrowthTable.wls"}];
Get[buildScript];
displayDefs = StringTrim @ First @ StringCases[Import[buildScript, "Text"],
   Shortest["(* DISPLAY-BEGIN *)" ~~ s___ ~~ "(* DISPLAY-END *)"] :> s];

(* Fetch the Single rule's spec up front (fresh kernel): WolframModelData's resource fetch goes
   flaky after the heavy Table run, so bake the rule + initial condition into the Single init as
   literals -> self-contained notebook, no late/live lookup. *)
exId = "wm3382";
wmSpec = ResourceFunction["WolframModelData"][{exId}, All][[1]];

(* BIG thumbnails for the 20 featured rows: override the small defaults from the build script *)
thumbOpts = Sequence[ImageSize -> 200, AspectRatio -> 0.8, Frame -> True, PlotRangePadding -> Scaled[0.03],
   ImagePadding -> {{48, 8}, {28, 8}}, Background -> White, BaseStyle -> {FontSize -> 17},
   Mesh -> All, MeshStyle -> Directive[PointSize[0.018], Black]];
finalStateThumb[rec_] := TimeConstrained[Quiet @ Rasterize[WolframModelPlot[rec["FinalState"], ImageSize -> {UpTo[300], UpTo[300]}], ImageResolution -> 72], 120, dash];

dataFile = FileNameJoin[{root, "Data", "AverageVolumeGrowths.wxf"}];
cacheFile = FileNameJoin[{root, "Data", "table.wxf"}];
raw = Select[Import[dataFile], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
(* Local table cache: {scalarData, featuredRows}. Reused unless the source data or the table-
   building script (BuildVolumeGrowthTable.wls) is newer, so layout-only re-runs skip the heavy
   recompute (all-rule scalars + 20 rasterized thumbnails). Data/ is gitignored. *)
{scalarData, featuredRows} = If[
   FileExistsQ[cacheFile] && FileDate[cacheFile] > FileDate[dataFile] && FileDate[cacheFile] > FileDate[buildScript],
   Print["table cache hit: ", cacheFile]; Import[cacheFile],
   Print["computing table data (no valid cache) ..."];
   Module[{sd, ranked, top20, fr},
    sd = volumeGrowthScalars /@ raw;
    ranked = ReverseSortBy[Select[Normal[sd], NumericQ[#[[2]]["StabilityScore"]] && NumericQ[#[[2]]["Vertices"]] &], (#[[2]]["StabilityScore"] #[[2]]["Vertices"]) &];
    top20 = ranked[[;; UpTo[20], 1]];
    Print["featured (largest x most stable): ", top20];
    fr = buildVolumeGrowthTable[raw, top20, defaultColumns];
    Export[cacheFile, {sd, fr}, "WXF"];
    Print["cached table: ", cacheFile];
    {sd, fr}]];

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

(* ---------- Table: folded init at top, then pre-evaluated display ---------- *)
emit["VolumeGrowth_Table", {
   Cell["Volume Growth: Table", "Title"],
   Cell[CellGroupData[{
      Cell["Initialization", "Section"],
      Cell["Self-contained: 20 featured rows (bitmap thumbnails) + all-rule scalars + the display defs, folded. The display cells below are pre-evaluated so the cloud renders without a kernel; re-evaluate (init runs first) for the live, interactive Dataset.", "Text"],
      Cell[BoxData[dataBlob], "Input", InitializationCell -> True],
      Cell[BoxData[displayDefs], "Input", InitializationCell -> True]}, Closed]],
   Cell["Dimension-Curvature Landscape", "Section"],
   ioCells["landscape[scalarData]", landscape[scalarData]],
   Cell["Featured Rules", "Section"],
   ioCells["buildTable[featuredRows]", buildTable[featuredRows]],
   Cell["Queries", "Section"],
   Cell["Queries run over the scalars of all rules.", "Text"],
   Cell["Dimension 2.5-3.5, near-flat curvature, at least 1000 vertices.", "Subsection"], ioCells[q1, ToExpression[q1]],
   Cell["Most converged large rules.", "Subsection"], ioCells[q2, ToExpression[q2]],
   Cell["Recommended ranking: stability score times sqrt(vertices).", "Subsection"], ioCells[q3, ToExpression[q3]],
   Cell["Fastest-expanding rules (by diameter growth).", "Subsection"], ioCells[q4, ToExpression[q4]]}];
Print["wrote VolumeGrowth_Table  (nb ", Round[FileByteCount[FileNameJoin[{nbDir, "VolumeGrowth_Table.nb"}]]/1.*^6, 0.1], " MB)"];

(* ---------- Single: fully evaluated; geometry + fit from the paclet, dynamics from WFR ---------- *)
singleInit = "Needs[\"WolframInstitute`Infrageometry`\"];

ruleName = \"wm3382\";

states = Rest @ ResourceFunction[\"WolframModel\"][" <> ToString[wmSpec["Rule"], InputForm] <> ", " <> ToString[wmSpec["InitialCondition"], InputForm] <> ",
    <|\"MaxGenerations\" -> 14, \"MaxVertices\" -> 5000, \"MaxEvents\" -> 100000|>][\"StatesList\"];

graphs = Graph[DeleteCases[UndirectedEdge[a_, a_]][DeleteDuplicates[UndirectedEdge @@@ Catenate[Subsets[#, {2}] & /@ #]]]] & /@ states;

ballValues = With[{vols = BallVolumes[#, All, All, \"Measure\" -> \"Counting\"]},
     Transpose[PadRight[#, Max[Length /@ vols], Last[#]] & /@ vols]] & /@ graphs;

ballVolumes = Map[Around[Mean[#], StandardDeviation[#]] &, ballValues, {2}];

meanVolumes = Map[Exp[MeanAround[Log[#]]] &, ballValues, {2}];

dimensionCurvature = With[{q = LogDifferenceQuotients[#]}, If[Length[q] < 2, Missing[], DimensionCurvatureFit[Transpose[{Range[Length[q]], q}]]]] & /@ meanVolumes;";
ToExpression[singleInit];

exGraphs = "GraphicsGrid[Partition[ResourceFunction[\"WolframModelPlot\"][#, ImageSize -> {UpTo[120], UpTo[120]}] & /@ states, UpTo[5]]]";
exVolumes = "ListLinePlot[ballVolumes, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ (Blend[{StandardYellow, StandardRed}, #] & /@ Subdivide[0., 1., Max[Length[ballVolumes] - 1, 1]])), IntervalMarkers -> \"Bars\", Mesh -> All, Frame -> True, FrameLabel -> {\"Radius\", \"Ball Volume\"}, ImageSize -> 460, PlotRange -> All]";
exLDQ = "ListLinePlot[LogDifferenceQuotients /@ meanVolumes, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ (Blend[{StandardYellow, StandardGreen}, #] & /@ Subdivide[0., 1., Max[Length[meanVolumes] - 1, 1]])), IntervalMarkers -> \"Bars\", Mesh -> All, Frame -> True, FrameLabel -> {\"Radius\", \"Log Difference Quotient\"}, ImageSize -> 460, PlotRange -> All]";
exDimCurv = "GraphicsRow[{ListLinePlot[MapIndexed[If[AssociationQ[#1], {First[#2], #1[\"Dimension\"]}, Nothing] &, dimensionCurvature], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkers -> \"Bars\", IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> {\"Generation\", \"Dimension\"}], ListLinePlot[MapIndexed[If[AssociationQ[#1], {First[#2], #1[\"ScalarCurvature\"]}, Nothing] &, dimensionCurvature], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkers -> \"Bars\", IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> {\"Generation\", \"Curvature\"}]}, ImageSize -> 640]";
exVertexEdgeDiam = "With[{vc = VertexCount /@ graphs, ec = Length /@ states, dia = (Length[#] - 1 &) /@ ballVolumes}, GraphicsRow[{ListLinePlot[vc, PlotStyle -> Directive[AbsoluteThickness[2], StandardBrown], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Vertices\"}], ListLinePlot[ec, PlotStyle -> Directive[AbsoluteThickness[2], StandardRed], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Edges\"}], ListLinePlot[dia, PlotStyle -> Directive[AbsoluteThickness[2], StandardOrange], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Diameter\"}], ListLinePlot[DeleteCases[Table[If[dia[[i]] > 1, {i, Log[vc[[i]]]/Log[dia[[i]]]}, Null], {i, Length[vc]}], Null], PlotStyle -> Directive[AbsoluteThickness[2], StandardBlue], Mesh -> All, Frame -> True, FrameLabel -> {\"Generation\", \"Graph Dimension\"}]}, ImageSize -> 900]]";
exStabilityRow = "With[{tt = Select[MapIndexed[If[AssociationQ[#1], {First[#2], #1[\"Dimension\"] /. Around[a_, _] :> a, #1[\"ScalarCurvature\"] /. Around[a_, _] :> a, VertexCount[graphs[[First[#2]]]]}, Nothing] &, dimensionCurvature], NumericQ[#[[2]]] && NumericQ[#[[3]]] &]}, With[{pts = tt[[All, {2, 3}]], gens = tt[[All, 1]], cols = Blend[{StandardGray, StandardRed}, #] & /@ Rescale[tt[[All, 4]]]}, GraphicsRow[{Graphics[{Arrowheads[{{0.05, 0.5}}], Table[{cols[[i + 1]], Arrow[{pts[[i]], pts[[i + 1]]}]}, {i, Length[pts] - 1}], PointSize[0.015], Table[{cols[[i]], Point[pts[[i]]]}, {i, Length[pts]}], Black, Table[Text[Style[gens[[i]], 10], pts[[i]], {-1.3, -1.3}], {i, Length[pts]}]}, Frame -> True, FrameLabel -> {\"Dimension\", \"Curvature\"}, Background -> White, PlotLabel -> \"Geometry Trajectory\"], ListLinePlot[Table[Max[EuclideanDistance @@@ Subsets[pts[[n0 ;;]], {2}]], {n0, 1, Length[pts] - 1}], Mesh -> All, PlotStyle -> Directive[StandardYellow, AbsoluteThickness[2]], Frame -> True, FrameLabel -> {\"N0\", \"Tail Diameter\"}, PlotLabel -> \"Cauchy Tail\"]}, ImageSize -> 720]]]";

emit["VolumeGrowth_Single", {
   Cell["Volume Growth: Single Rule", "Title"],
   Cell[CellGroupData[{Cell["Initialization", "Section"], Cell[BoxData @ singleInit, "Input", InitializationCell -> True]}, Closed]],
   Cell["Generations", "Section"], ioCells[exGraphs, ToExpression[exGraphs]],
   Cell["Volume Growth", "Section"], Cell["Pointwise volume growth (mean \[PlusMinus] \[Sigma]).", "Text"], ioCells[exVolumes, ToExpression[exVolumes]],
   Cell["Log Difference Quotients", "Section"], Cell["Log-difference quotient of the mean volume growth (mean \[PlusMinus] \[Sigma]/Sqrt[vertex count]).", "Text"], ioCells[exLDQ, ToExpression[exLDQ]],
   Cell["Dimension and Curvature", "Section"], Cell["Dimension and curvature from the mean volume growth.", "Text"], ioCells[exDimCurv, ToExpression[exDimCurv]],
   Cell["Vertex and Edge Count and Diameter", "Section"], ioCells[exVertexEdgeDiam, ToExpression[exVertexEdgeDiam]],
   Cell["Dimension-Curvature Stability", "Section"], ioCells[exStabilityRow, ToExpression[exStabilityRow]]}];
Print["wrote VolumeGrowth_Single  (nb ", Round[FileByteCount[FileNameJoin[{nbDir, "VolumeGrowth_Single.nb"}]]/1.*^6, 0.1], " MB)"];
