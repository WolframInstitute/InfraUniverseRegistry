(* BuildVolumeGrowthTable - per-rule Volume-Growth table data. Get-loaded by
   GenerateVolumeGrowthNotebooks.wls. All formatting (Hyperlinks, rounding, dashes, thumbnails,
   column names) happens HERE so the notebook needs no helper functions - just the baked data
   (allRules = scalar metrics for every rule, exampleData = fully-formatted display rows for the
   featured rules) + inline Dataset/Graphics. The display code (landscape, table, queries) lives in
   Notebooks/VolumeGrowth_Table.md, the notebook's source. Geometry: WolframInstitute`InfraGeometry` (BallVolumes,
   LogDifferenceQuotients, DimensionCurvatureFit) + WolframInstitute`DiscreteGeometry` (Hypergraph2Section). thumbOpts and finalStateThumb
   are overridable (the generator bumps them to big sizes for the featured thumbnails). *)

Needs["WolframInstitute`DiscreteGeometry`"];
Needs["WolframInstitute`InfraGeometry`"];
Needs["SetReplace`"];

strip = # /. Around[a_, _] :> a &;
numQ = NumericQ[# /. Around[a_, _] :> a] &;
dash = Style["\[LongDash]", GrayLevel[0.55], 20];
url[id_] := "https://www.wolframphysics.org/universes/" <> id <> "/";
ar[v_, e_] := If[NumericQ[v], Around[v, e], dash];
rnd[x_, d_] := If[NumericQ[x], Round[x, d], dash];
slope[ys_] :=
  With[{n = Length[ys]}, If[n < 2, 0., Module[{x = Range[n]}, N[(n Total[x ys] - Total[x] Total[ys]) / (n Total[x^2] - Total[x]^2)]]]];
seriesColors[n_, c1_, c2_] := Blend[{c1, c2}, #] & /@ Subdivide[0., 1., Max[n - 1, 1]];
mt[m_] := {{m, If[Abs[N@m] >= 10, Round[m], Round[N@m, 0.1]]}};

dimcurvSeq[rec_] :=
  (If[Length[#] < 2, Missing[], DimensionCurvatureFit[Transpose[{Range[Length[#]], #}]]] &) /@ (LogDifferenceQuotients /@ rec["Growths"]);
numAssocQ = AssociationQ[#] && numQ[#["Dimension"]] && numQ[#["ScalarCurvature"]] &;
lastFit[rec_] := Module[{dc = Select[dimcurvSeq[rec], numAssocQ]}, If[dc === {}, Missing[], Last[dc]]];
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
globalDimension[rec_] := With[{v = Last[rec["VertexCounts"]], r = finalDiameter[rec]/2}, If[TrueQ[r > 1], Log[v]/Log[r], Missing[]]];
diameterGrowth[rec_] := slope[rec["Diameters"]];
vertexGrowth[rec_] := slope[rec["VertexCounts"]];

thumbOpts = Sequence[ImageSize -> 104, AspectRatio -> 0.8, Frame -> True, PlotRangePadding -> Scaled[0.03],
   ImagePadding -> {{36, 5}, {22, 5}}, Background -> White, BaseStyle -> {FontSize -> 15},
   Mesh -> All, MeshStyle -> Directive[PointSize[0.016], Black]];
growthThumb[rec_] :=
  Module[{vol = Lookup[rec, "VolumeMeans", rec["Growths"]], sv = strip[Lookup[rec, "VolumeMeans", rec["Growths"]]]},
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
  TimeConstrained[Quiet @ ImageResize[Rasterize[ResourceFunction["WolframModelPlot"][rec["FinalState"], ImageSize -> 140], ImageResolution -> 72], {UpTo[140], UpTo[140]}], 90, dash];

(* per-rule scalar metrics -> baked as allRules (drives the landscape + queries) *)
volumeGrowthScalars[rec_] :=
  <|"Dimension" -> dimension[rec], "DimensionError" -> dimensionError[rec], "Curvature" -> curvature[rec],
    "CurvatureError" -> curvatureError[rec], "Vertices" -> Last[rec["VertexCounts"]], "Diameter" -> finalDiameter[rec],
    "GlobalDimension" -> globalDimension[rec], "DiameterGrowth" -> diameterGrowth[rec], "VertexGrowth" -> vertexGrowth[rec],
    "StabilityScore" -> stabilityScore[rec]|>;

(* exampleData -> a display row for EVERY rule: the featured rules first with full thumbnails, then
   the rest with a dash in each thumbnail column and scalars taken from the precomputed allRules (no
   refit). The notebook table cell is just Dataset[Values @ exampleData] - no formatting at display time *)
exampleRow[id_, rec_] :=
  <|"Rule" -> Hyperlink[id, url[id]], "State" -> finalStateThumb[rec],
    "Generation" -> Length[rec["VertexCounts"]], "Edges" -> Length[rec["FinalState"]], "Vertices" -> Last[rec["VertexCounts"]],
    "Vertex Growth" -> rnd[vertexGrowth[rec], 0.1], "Vertices/gen" -> vertexThumb[rec],
    "Diameter" -> finalDiameter[rec], "Diameter Growth" -> rnd[diameterGrowth[rec], 0.01], "Diameter/gen" -> diameterThumb[rec],
    "Global Dimension" -> rnd[globalDimension[rec], 0.01], "Dimension" -> ar[dimension[rec], dimensionError[rec]], "Dimensions" -> dimensionThumb[rec],
    "Curvature" -> ar[curvature[rec], curvatureError[rec]], "Curvatures" -> curvatureThumb[rec],
    "Volume Growth" -> growthThumb[rec], "Log Diff Q" -> ldqThumb[rec], "Stability Score" -> rnd[stabilityScore[rec], 0.001]|>;
plainRow[id_, rec_, s_] :=
  <|"Rule" -> Hyperlink[id, url[id]], "State" -> dash,
    "Generation" -> Length[rec["VertexCounts"]], "Edges" -> Length[rec["FinalState"]], "Vertices" -> s["Vertices"],
    "Vertex Growth" -> rnd[s["VertexGrowth"], 0.1], "Vertices/gen" -> dash,
    "Diameter" -> s["Diameter"], "Diameter Growth" -> rnd[s["DiameterGrowth"], 0.01], "Diameter/gen" -> dash,
    "Global Dimension" -> rnd[s["GlobalDimension"], 0.01], "Dimension" -> ar[s["Dimension"], s["DimensionError"]], "Dimensions" -> dash,
    "Curvature" -> ar[s["Curvature"], s["CurvatureError"]], "Curvatures" -> dash,
    "Volume Growth" -> dash, "Log Diff Q" -> dash, "Stability Score" -> rnd[s["StabilityScore"], 0.001]|>;
buildExampleData[raw_, scalars_, featured_] :=
  Association[Join[(# -> exampleRow[#, raw[#]]) & /@ featured,
     (# -> plainRow[#, raw[#], scalars[#]]) & /@ DeleteCases[Keys[raw], Alternatives @@ featured]]];
