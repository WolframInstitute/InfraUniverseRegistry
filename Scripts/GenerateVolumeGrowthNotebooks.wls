#!/usr/bin/env wolframscript
(* Generate Notebooks/VolumeGrowth_Table.{nb,md} and _Single.{nb,md}, both fully evaluated
   (input + output) so they render statically in the Wolfram Cloud without a kernel.

   Table is self-contained: the baked data (exampleRules = fully-formatted display rows for the
   featured rules; allRules = scalar metrics for every rule) lives in a FOLDED Initialization
   section at the top, and the display cells (landscape, table, queries) are INLINE code with
   pre-evaluated output -- no helper functions in the notebook. Single is one rule computed live
   from the paclet (Hypergraph2Section + BallVolumes + DimensionCurvatureFit). No Code/, no *Init.wl. *)

scriptDir = DirectoryName[$InputFileName];
root = ParentDirectory[scriptDir];
nbDir = FileNameJoin[{root, "Notebooks"}];

(* shared generation defs (scalars, thumbnails, formatting -> exampleRules / allRules). The inline
   landscape code is lifted from the LANDSCAPE-BEGIN/END comment and baked into the notebook cell. *)
buildScript = FileNameJoin[{scriptDir, "BuildVolumeGrowthTable.wls"}];
Get[buildScript];
landscapeCode = StringTrim @ First @ StringCases[Import[buildScript, "Text"],
   "(* LANDSCAPE-BEGIN" ~~ Shortest[___] ~~ "\n" ~~ Shortest[s___] ~~ "LANDSCAPE-END" :> s];

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
(* Local cache: {allRules, exampleRules}. Reused unless the source data or BuildVolumeGrowthTable.wls
   is newer, so layout-only re-runs skip the heavy recompute (all-rule scalars + featured thumbnails).
   Data/ is gitignored. *)
{allRules, exampleRules} = If[
   FileExistsQ[cacheFile] && FileDate[cacheFile] > FileDate[dataFile] && FileDate[cacheFile] > FileDate[buildScript],
   Print["table cache hit: ", cacheFile]; Import[cacheFile],
   Print["computing table data (no valid cache) ..."];
   Module[{all, ranked, top20, ex},
    all = volumeGrowthScalars /@ raw;
    ranked = ReverseSortBy[Select[Normal[all], NumericQ[#[[2]]["StabilityScore"]] && NumericQ[#[[2]]["Vertices"]] &], (#[[2]]["StabilityScore"] #[[2]]["Vertices"]) &];
    top20 = ranked[[;; UpTo[20], 1]];
    Print["featured (largest x most stable): ", top20];
    ex = buildExampleRules[raw, top20];
    Export[cacheFile, {all, ex}, "WXF"];
    Print["cached table: ", cacheFile];
    {all, ex}]];

dataBlob = StringRiffle[{
    "exampleRules = Uncompress[" <> ToString[Compress[exampleRules], InputForm] <> "];",
    "allRules = Uncompress[" <> ToString[Compress[allRules], InputForm] <> "];"}, "\n\n"];

tableCode = "Dataset[Values @ exampleRules, Alignment -> {Center, Center}, MaxItems -> {25, All}, ItemStyle -> {FontSize -> 15}, HeaderStyle -> Directive[FontSize -> 15, Bold]]";
q1 = "Dataset[allRules][Select[NumericQ[#Dimension] && 2.5 <= #Dimension <= 3.5 && Abs[#Curvature] < 0.5 && #Vertices >= 1000 &]]";
q2 = "Dataset[allRules][Select[#Vertices >= 500 && NumericQ[#StabilityScore] &]][TakeLargestBy[\"StabilityScore\", 25]]";
q3 = "Dataset[allRules][ReverseSortBy[#StabilityScore Sqrt[#Vertices] &]][;; 25]";
q4 = "Dataset[allRules][TakeLargestBy[\"DiameterGrowth\", 15]]";
q0 = "Dataset[allRules][Select[NumericQ[#StabilityScore] && NumericQ[#Vertices] &]][TakeLargestBy[#StabilityScore #Vertices &, 20]]";

(* ---------- emit helpers ---------- *)
(* display code cells are folded (CellOpen -> False): the cloud shows the pre-evaluated output, the
   code is one click away. *)
ioCells[code_, expr_] := {Cell[BoxData[code], "Input", CellOpen -> False], Cell[BoxData[ToBoxes[expr]], "Output"]};
toMd = Replace[#, {Cell[t_String, "Title"] :> "# " <> t, Cell[t_String, "Section"] :> "## " <> t,
     Cell[t_String, "Subsection"] :> "### " <> t, Cell[t_String, "Text"] :> t,
     Cell[BoxData[c_String], "Input", ___] :> "```wolfram\n" <> c <> "\n```",
     Cell[BoxData[_], "Output"] :> Nothing, Cell[BoxData[_], "Input", ___] :> Nothing}] &;
flatten = Flatten[{#}] /. Cell[CellGroupData[cs_List, _]] :> Sequence @@ cs &;
emit[base_, cells_] := (Export[FileNameJoin[{nbDir, base <> ".nb"}], Notebook @ Flatten[{cells}]];
   Export[FileNameJoin[{nbDir, base <> ".md"}], StringRiffle[DeleteCases[toMd /@ flatten[cells], ""], "\n\n"], "Text"]);

(* ---------- Table: folded data at top, then inline display (no helper functions) ---------- *)
emit["VolumeGrowth_Table", {
   Cell["Volume Growth: Table", "Title"],
   Cell[CellGroupData[{
      Cell["Initialization", "Section"],
      Cell[BoxData[dataBlob], "Input", InitializationCell -> True]}, Closed]],
   Cell["Dimension-Curvature Landscape", "Section"],
   ioCells[landscapeCode, ToExpression[landscapeCode]],
   Cell["Featured Rules", "Section"],
   ioCells[tableCode, ToExpression[tableCode]],
   Cell["Queries", "Section"],
   Cell["Over all rules' scalar metrics (not just the example rows).", "Text"],
   Cell["Dataset[allRules][TakeLargestBy[StabilityScore \[Times] Vertices, 20]]  (Featured Rules)", "Subsection"], ioCells[q0, ToExpression[q0]],
   Cell["Dimension 2.5-3.5, near-flat curvature, at least 1000 vertices.", "Subsection"], ioCells[q1, ToExpression[q1]],
   Cell["Most converged large rules.", "Subsection"], ioCells[q2, ToExpression[q2]],
   Cell["Recommended ranking: stability score times sqrt(vertices).", "Subsection"], ioCells[q3, ToExpression[q3]],
   Cell["Fastest-expanding rules (by diameter growth).", "Subsection"], ioCells[q4, ToExpression[q4]]}];
Print["wrote VolumeGrowth_Table  (nb ", Round[FileByteCount[FileNameJoin[{nbDir, "VolumeGrowth_Table.nb"}]]/1.*^6, 0.1], " MB)"];

(* ---------- Single: fully evaluated; geometry + fit from the paclet, dynamics from WFR ---------- *)
singleInit = "Needs[ \"WolframInstitute`Infrageometry`\" ];

ruleName = \"wm3382\";

states = Rest @ ResourceFunction[ \"WolframModel\" ][ " <> ToString[wmSpec["Rule"], InputForm] <> ", " <> ToString[wmSpec["InitialCondition"], InputForm] <> ",
    <| \"MaxGenerations\" -> 14, \"MaxVertices\" -> 5000, \"MaxEvents\" -> 100000 |> ][ \"StatesList\" ];

graphs = Hypergraph2Section /@ states;";

ballSetup = "ballValues = With[ { vols = BallVolumes[ #, All, All, \"Measure\" -> \"Counting\" ] },
     Transpose[ PadRight[ #, Max[ Length /@ vols ], Last[ # ] ] & /@ vols ] ] & /@ graphs;

ballVolumes = Map[ Around[ Mean[ # ], StandardDeviation[ # ] ] &, ballValues, { 2 } ];";

meanSetup = "meanVolumes = Map[ Exp[ MeanAround[ Log[ # ] ] ] &, ballValues, { 2 } ];";

dimSetup = "dimensionCurvature = With[ { quotients = LogDifferenceQuotients[ # ] }, If[ Length[ quotients ] < 2, Missing[], DimensionCurvatureFit[ Transpose[ { Range[ Length[ quotients ] ], quotients } ] ] ] ] & /@ meanVolumes;";

ToExpression /@ {singleInit, ballSetup, meanSetup, dimSetup};

exGraphs = "GraphicsGrid[ Partition[ ResourceFunction[ \"WolframModelPlot\" ][ #, ImageSize -> { UpTo[ 120 ], UpTo[ 120 ] } ] & /@ states, UpTo[ 5 ] ] ]";
exVolumes = "ListLinePlot[ ballVolumes, PlotStyle -> ( Directive[ AbsoluteThickness[ 2 ], # ] & /@ ( Blend[ { StandardYellow, StandardRed }, # ] & /@ Subdivide[ 0., 1., Max[ Length[ ballVolumes ] - 1, 1 ] ] ) ), IntervalMarkers -> \"Bars\", Mesh -> All, Frame -> True, FrameLabel -> { \"Radius\", \"Ball Volume\" }, ImageSize -> 460, PlotRange -> All ]";
exLDQ = "ListLinePlot[ LogDifferenceQuotients /@ meanVolumes, PlotStyle -> ( Directive[ AbsoluteThickness[ 2 ], # ] & /@ ( Blend[ { StandardYellow, StandardGreen }, # ] & /@ Subdivide[ 0., 1., Max[ Length[ meanVolumes ] - 1, 1 ] ] ) ), IntervalMarkers -> \"Bars\", Mesh -> All, Frame -> True, FrameLabel -> { \"Radius\", \"Log Difference Quotient\" }, ImageSize -> 460, PlotRange -> All ]";
exDimCurv = "GraphicsRow[ { ListLinePlot[ MapIndexed[ If[ AssociationQ[ #1 ], { First[ #2 ], #1[ \"Dimension\" ] }, Nothing ] &, dimensionCurvature ], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkers -> \"Bars\", IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> { \"Generation\", \"Dimension\" } ], ListLinePlot[ MapIndexed[ If[ AssociationQ[ #1 ], { First[ #2 ], #1[ \"ScalarCurvature\" ] }, Nothing ] &, dimensionCurvature ], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkers -> \"Bars\", IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> { \"Generation\", \"Curvature\" } ] }, ImageSize -> 640 ]";
exVertexEdgeDiam = "With[ { vertexCounts = VertexCount /@ graphs, edgeCounts = Length /@ states, diameters = ( Length[ # ] - 1 & ) /@ ballVolumes }, GraphicsRow[ { ListLinePlot[ vertexCounts, PlotStyle -> Directive[ AbsoluteThickness[ 2 ], StandardBrown ], Mesh -> All, Frame -> True, FrameLabel -> { \"Generation\", \"Vertices\" } ], ListLinePlot[ edgeCounts, PlotStyle -> Directive[ AbsoluteThickness[ 2 ], StandardRed ], Mesh -> All, Frame -> True, FrameLabel -> { \"Generation\", \"Edges\" } ], ListLinePlot[ diameters, PlotStyle -> Directive[ AbsoluteThickness[ 2 ], StandardOrange ], Mesh -> All, Frame -> True, FrameLabel -> { \"Generation\", \"Diameter\" } ], ListLinePlot[ DeleteCases[ Table[ If[ diameters[[ i ]] > 1, { i, Log[ vertexCounts[[ i ]] ] / Log[ diameters[[ i ]] ] }, Null ], { i, Length[ vertexCounts ] } ], Null ], PlotStyle -> Directive[ AbsoluteThickness[ 2 ], StandardBlue ], Mesh -> All, Frame -> True, FrameLabel -> { \"Generation\", \"Global Dimension\" } ] }, ImageSize -> 900 ] ]";
exStabilityRow = "With[ { trajectory = Select[ MapIndexed[ If[ AssociationQ[ #1 ], { First[ #2 ], #1[ \"Dimension\" ] /. Around[ a_, _ ] :> a, #1[ \"ScalarCurvature\" ] /. Around[ a_, _ ] :> a, VertexCount[ graphs[[ First[ #2 ] ]] ] }, Nothing ] &, dimensionCurvature ], NumericQ[ #[[ 2 ]] ] && NumericQ[ #[[ 3 ]] ] & ] }, With[ { points = trajectory[[ All, { 2, 3 } ]], generations = trajectory[[ All, 1 ]], colors = Blend[ { StandardGray, StandardRed }, # ] & /@ Rescale[ trajectory[[ All, 4 ]] ] }, GraphicsRow[ { Graphics[ { Arrowheads[ { { 0.05, 0.5 } } ], Table[ { colors[[ i + 1 ]], Arrow[ { points[[ i ]], points[[ i + 1 ]] } ] }, { i, Length[ points ] - 1 } ], PointSize[ 0.015 ], Table[ { colors[[ i ]], Point[ points[[ i ]] ] }, { i, Length[ points ] } ], Black, Table[ Text[ Style[ generations[[ i ]], 10 ], points[[ i ]], { -1.3, -1.3 } ], { i, Length[ points ] } ] }, Frame -> True, FrameLabel -> { \"Dimension\", \"Curvature\" }, Background -> White, PlotLabel -> \"Geometry Trajectory\" ], ListLinePlot[ Table[ Max[ EuclideanDistance @@@ Subsets[ points[[ n0 ;; ]], { 2 } ] ], { n0, 1, Length[ points ] - 1 } ], Mesh -> All, PlotStyle -> Directive[ StandardYellow, AbsoluteThickness[ 2 ] ], Frame -> True, FrameLabel -> { \"N0\", \"Tail Diameter\" }, PlotLabel -> \"Cauchy Tail\" ] }, ImageSize -> 720 ] ] ]";

emit["VolumeGrowth_Single", {
   Cell["Volume Growth: Single Rule", "Title"],
   Cell[CellGroupData[{Cell["Initialization", "Section"], Cell[BoxData @ singleInit, "Input", InitializationCell -> True]}, Closed]],
   Cell["Generations", "Section"], ioCells[exGraphs, ToExpression[exGraphs]],
   Cell["Volume Growth", "Section"], Cell["Pointwise volume growth (mean \[PlusMinus] \[Sigma]).", "Text"], Cell[BoxData @ ballSetup, "Input"], ioCells[exVolumes, ToExpression[exVolumes]],
   Cell["Log Difference Quotients", "Section"], Cell["Log-difference quotient of the mean volume growth (mean \[PlusMinus] \[Sigma]/Sqrt[vertex count]).", "Text"], Cell[BoxData @ meanSetup, "Input"], ioCells[exLDQ, ToExpression[exLDQ]],
   Cell["Dimension and Curvature", "Section"], Cell["Dimension and curvature from the mean volume growth.", "Text"], Cell[BoxData @ dimSetup, "Input"], ioCells[exDimCurv, ToExpression[exDimCurv]],
   Cell["Vertex and Edge Count and Diameter", "Section"], ioCells[exVertexEdgeDiam, ToExpression[exVertexEdgeDiam]],
   Cell["Dimension-Curvature Stability", "Section"], ioCells[exStabilityRow, ToExpression[exStabilityRow]]}];
Print["wrote VolumeGrowth_Single  (nb ", Round[FileByteCount[FileNameJoin[{nbDir, "VolumeGrowth_Single.nb"}]]/1.*^6, 0.1], " MB)"];
