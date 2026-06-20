(* BuildVolumeGrowthTable - per-rule Volume-Growth table data + the Table notebook's display defs.
   Get-loaded by GenerateVolumeGrowthNotebooks.wls, which (1) calls buildVolumeGrowthTable[raw, ids,
   columns] for the featured rows and volumeGrowthScalars for every rule, and (2) lifts the paclet-free
   block between DISPLAY-BEGIN/DISPLAY-END verbatim into the self-contained Table notebook.  Geometry is
   the WolframInstitute`Infrageometry` paclet (BallVolumes / LogDifferenceQuotients / DimensionCurvatureFit,
   window = Automatic).  raw[id] is one record of Data/AverageVolumeGrowths.wxf :: <|"Growths",
   "VertexCounts", "EdgeCounts", "Diameters", "FinalState", ...|>.  thumbOpts and finalStateThumb are
   overridable after loading (the generator bumps them to big sizes for the 20 featured rows). *)

Needs["WolframInstitute`Infrageometry`"];
Needs["SetReplace`"];

(* ===== Display defs: paclet-free; each takes its data as an argument.  The generator copies this
   block verbatim into the Table notebook (which embeds featuredRows / scalarData as Uncompress blobs
   above it), so the cloud notebook needs no paclet and no external files. ===== *)
(* DISPLAY-BEGIN *)
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
     Graphics[Table[Tooltip[Hyperlink[{cf[p[[6]]], PointSize[0.011], Point[{p[[2]], p[[4]]}]}, url[p[[1]]]],
         Column[{Style[p[[1]], Bold], Row[{"dim ", Around[p[[2]], p[[3]]], "   curv ", Around[p[[4]], p[[5]]]}]}]], {p, inr}],
      Frame -> True, FrameLabel -> {"Dimension", "Curvature"}, PlotRange -> {dr, cr}, Background -> White,
      ImageSize -> 640, AspectRatio -> 1/GoldenRatio],
     BarLegend[{cf, {0, 1}}, LegendLabel -> "Stability Score", LegendMarkerSize -> 300]]];
(* DISPLAY-END *)

(* ===== Generation: per-rule scalars + baked thumbnails (uses the paclet + the display dash). ===== *)
strip = # /. Around[a_, _] :> a &;
numQ = NumericQ[# /. Around[a_, _] :> a] &;
slope[ys_] :=
  With[{n = Length[ys]},
   If[n < 2, 0., Module[{x = Range[n]}, N[(n Total[x ys] - Total[x] Total[ys]) / (n Total[x^2] - Total[x]^2)]]]];
seriesColors[n_, c1_, c2_] := Blend[{c1, c2}, #] & /@ Subdivide[0., 1., Max[n - 1, 1]];
mt[m_] := {{m, If[Abs[N@m] >= 10, Round[m], Round[N@m, 0.1]]}};

(* per-generation dimension/curvature: index-based quotients -> windowed paclet fit (Around-valued
   Growths carry their spread to Around d / R); Missing on generations too short to fit *)
dimcurvSeq[rec_] :=
  (If[Length[#] < 2, Missing[], DimensionCurvatureFit[Transpose[{Range[Length[#]], #}]]] &) /@ (LogDifferenceQuotients /@ rec["Growths"]);
numAssocQ = AssociationQ[#] && numQ[#["Dimension"]] && numQ[#["ScalarCurvature"]] &;
lastFit[rec_] :=
  Module[{dc = Select[dimcurvSeq[rec], numAssocQ]}, If[dc === {}, Missing[], Last[dc]]];
dimension[rec_] := Replace[lastFit[rec], {a_?AssociationQ :> strip[a["Dimension"]], _ :> Missing[]}];
dimensionError[rec_] := Replace[lastFit[rec], {a_?AssociationQ :> Replace[a["Dimension"], {Around[_, e_] :> e, _ :> 0.}], _ :> Missing[]}];
curvature[rec_] := Replace[lastFit[rec], {a_?AssociationQ :> strip[a["ScalarCurvature"]], _ :> Missing[]}];
curvatureError[rec_] := Replace[lastFit[rec], {a_?AssociationQ :> Replace[a["ScalarCurvature"], {Around[_, e_] :> e, _ :> 0.}], _ :> Missing[]}];
trajectoryPts[rec_] := Cases[dimcurvSeq[rec], a_?numAssocQ :> {strip[a["Dimension"]], strip[a["ScalarCurvature"]]}];
stabilityScore[rec_] :=
  Module[{pts = trajectoryPts[rec], tail},
   tail = If[Length[pts] >= 2, Take[pts, -Ceiling[Length[pts]/3]], {}];
   If[Length[tail] >= 2, 1./(1. + Max[EuclideanDistance @@@ Subsets[tail, {2}]]), Missing[]]];
finalDiameter[rec_] := Last[rec["Diameters"]];
graphDimension[rec_] :=
  With[{v = Last[rec["VertexCounts"]], d = finalDiameter[rec]}, If[TrueQ[d > 1], Log[v]/Log[d], Missing[]]];
diameterGrowth[rec_] := slope[rec["Diameters"]];
vertexGrowth[rec_] := slope[rec["VertexCounts"]];

thumbOpts = Sequence[ImageSize -> 104, AspectRatio -> 0.8, Frame -> True, PlotRangePadding -> Scaled[0.03],
   ImagePadding -> {{36, 5}, {22, 5}}, Background -> White, BaseStyle -> {FontSize -> 15},
   Mesh -> All, MeshStyle -> Directive[PointSize[0.016], Black]];
growthThumb[rec_] :=
  Module[{vol = rec["Growths"], sv = strip[rec["Growths"]]},
   If[Max[Length /@ sv] < 2, dash,
    Rasterize @ ListLinePlot[vol, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[vol], StandardYellow, StandardRed]),
      IntervalMarkers -> "Bars", FrameTicks -> {{mt[Max[Flatten[sv]]], None}, {mt[Max[Length /@ sv]], None}}, thumbOpts]]];
ldqThumb[rec_] :=
  Module[{q = LogDifferenceQuotients /@ rec["Growths"], sq, fl},
   sq = strip[q]; fl = Flatten[sq];
   If[fl === {} || Max[Length /@ sq] < 2, dash,
    Rasterize @ Quiet @ ListLinePlot[q, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[q], StandardYellow, StandardGreen]),
      IntervalMarkers -> "Bars", FrameTicks -> {{mt[Max[fl]], None}, {mt[Max[Length /@ sq]], None}}, thumbOpts]]];
dimensionThumb[rec_] :=
  Module[{d = Cases[MapIndexed[{First[#2], #1} &, dimcurvSeq[rec]], {i_, a_?numAssocQ} :> {i, a["Dimension"]}]},
   If[Length[d] < 1, dash,
    Rasterize @ ListLinePlot[d, PlotStyle -> Directive[AbsoluteThickness[2], StandardBlue], IntervalMarkersStyle -> StandardBlue,
      IntervalMarkers -> "Bars", FrameTicks -> {{mt[Max[strip[d[[All, 2]]]]], None}, {mt[Max[d[[All, 1]]]], None}}, thumbOpts]]];
curvatureThumb[rec_] :=
  Module[{d = Cases[MapIndexed[{First[#2], #1} &, dimcurvSeq[rec]], {i_, a_?numAssocQ} :> {i, a["ScalarCurvature"]}]},
   If[Length[d] < 1, dash,
    Rasterize @ ListLinePlot[d, PlotStyle -> Directive[AbsoluteThickness[2], StandardPurple], IntervalMarkersStyle -> StandardPurple,
      IntervalMarkers -> "Bars", FrameTicks -> {{mt[Max[strip[d[[All, 2]]]]], None}, {mt[Max[d[[All, 1]]]], None}}, thumbOpts]]];
vertexThumb[rec_] :=
  Module[{vc = rec["VertexCounts"]},
   If[Length[vc] < 2, dash,
    Rasterize @ ListLinePlot[vc, PlotStyle -> Directive[AbsoluteThickness[2], StandardBrown],
      IntervalMarkers -> "Bars", FrameTicks -> {{mt[Max[vc]], None}, {mt[Length[vc]], None}}, thumbOpts]]];
diameterThumb[rec_] :=
  Module[{dia = rec["Diameters"]},
   If[Length[dia] < 2, dash,
    Rasterize @ ListLinePlot[dia, PlotStyle -> Directive[AbsoluteThickness[2], StandardOrange],
      IntervalMarkers -> "Bars", FrameTicks -> {{mt[Max[dia]], None}, {mt[Length[dia]], None}}, thumbOpts]]];
finalStateThumb[rec_] :=
  TimeConstrained[Quiet @ Rasterize[WolframModelPlot[rec["FinalState"], ImageSize -> {UpTo[140], UpTo[140]}], ImageResolution -> 72], 90, dash];

columnFields = <|"Rule" -> {}, "State" -> {"StateThumb"}, "Generation" -> {"Generation"}, "Edges" -> {"Edges"},
   "Vertices" -> {"Vertices"}, "Vertex Growth" -> {"VertexGrowth"}, "Vertices/gen" -> {"VertexThumb"},
   "Diameter" -> {"Diameter"}, "Diameter Growth" -> {"DiameterGrowth"}, "Diameter/gen" -> {"DiameterThumb"},
   "Graph Dimension" -> {"GraphDimension"}, "Dimension" -> {"Dimension", "DimensionError"}, "Dimensions" -> {"DimThumb"},
   "Curvature" -> {"Curvature", "CurvatureError"}, "Curvatures" -> {"CurvThumb"}, "Volume Growth" -> {"VolumeThumb"},
   "Log Diff Q" -> {"LDQThumb"}, "Stability Score" -> {"StabilityScore"}|>;
fieldFn = <|"Generation" -> (Length[#["VertexCounts"]] &), "Edges" -> (Length[#["FinalState"]] &),
   "Vertices" -> (Last[#["VertexCounts"]] &), "VertexGrowth" -> vertexGrowth, "Diameter" -> finalDiameter,
   "DiameterGrowth" -> diameterGrowth, "GraphDimension" -> graphDimension, "Dimension" -> dimension,
   "DimensionError" -> dimensionError, "Curvature" -> curvature, "CurvatureError" -> curvatureError,
   "StabilityScore" -> stabilityScore, "StateThumb" -> finalStateThumb, "VolumeThumb" -> growthThumb,
   "LDQThumb" -> ldqThumb, "DimThumb" -> dimensionThumb, "CurvThumb" -> curvatureThumb,
   "VertexThumb" -> vertexThumb, "DiameterThumb" -> diameterThumb|>;

volumeGrowthRow[rec_, columns_] :=
  AssociationMap[fieldFn[#][rec] &, Union @ Flatten[Lookup[columnFields, columns, {}]]];
buildVolumeGrowthTable[raw_, ids_, columns_ : Automatic] :=
  With[{cols = Replace[columns, Automatic :> defaultColumns]}, Association[(# -> volumeGrowthRow[raw[#], cols]) & /@ ids]];
volumeGrowthScalars[rec_] :=
  <|"Dimension" -> dimension[rec], "DimensionError" -> dimensionError[rec], "Curvature" -> curvature[rec],
    "CurvatureError" -> curvatureError[rec], "Vertices" -> Last[rec["VertexCounts"]], "Diameter" -> finalDiameter[rec],
    "GraphDimension" -> graphDimension[rec], "DiameterGrowth" -> diameterGrowth[rec], "VertexGrowth" -> vertexGrowth[rec],
    "StabilityScore" -> stabilityScore[rec]|>;
