(* BuildVolumeGrowthTable - per-rule Volume-Growth table data. Get-loaded by
   GenerateVolumeGrowthNotebooks.wls. All formatting (Hyperlinks, rounding, dashes, thumbnails,
   column names) happens HERE so the notebook needs no helper functions - just the baked data
   (allRules = scalar metrics for every rule, exampleRules = fully-formatted display rows for the
   featured rules) + inline Dataset/Graphics. The inline landscape code lives in the
   LANDSCAPE-BEGIN/END comment and is lifted verbatim into the notebook by the generator (it uses
   the baked allRules + exampleRules). Geometry: WolframInstitute`Infrageometry` (BallVolumes,
   LogDifferenceQuotients, DimensionCurvatureFit) + Hypergraph2Section. thumbOpts and finalStateThumb
   are overridable (the generator bumps them to big sizes for the featured thumbnails). *)

Needs["WolframInstitute`Infrageometry`"];
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
globalDimension[rec_] := With[{v = Last[rec["VertexCounts"]], d = finalDiameter[rec]}, If[TrueQ[d > 1], Log[v]/Log[d], Missing[]]];
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

(* per-rule scalar metrics -> baked as allRules (drives the landscape + queries) *)
volumeGrowthScalars[rec_] :=
  <|"Dimension" -> dimension[rec], "DimensionError" -> dimensionError[rec], "Curvature" -> curvature[rec],
    "CurvatureError" -> curvatureError[rec], "Vertices" -> Last[rec["VertexCounts"]], "Diameter" -> finalDiameter[rec],
    "GlobalDimension" -> globalDimension[rec], "DiameterGrowth" -> diameterGrowth[rec], "VertexGrowth" -> vertexGrowth[rec],
    "StabilityScore" -> stabilityScore[rec]|>;

(* fully-formatted display row for a featured rule -> baked as exampleRules; the notebook table cell
   is just Dataset[Values @ exampleRules] - no helpers, no formatting at display time *)
exampleRow[id_, rec_] :=
  <|"Rule" -> Hyperlink[id, url[id]], "State" -> finalStateThumb[rec],
    "Generation" -> Length[rec["VertexCounts"]], "Edges" -> Length[rec["FinalState"]], "Vertices" -> Last[rec["VertexCounts"]],
    "Vertex Growth" -> rnd[vertexGrowth[rec], 0.1], "Vertices/gen" -> vertexThumb[rec],
    "Diameter" -> finalDiameter[rec], "Diameter Growth" -> rnd[diameterGrowth[rec], 0.01], "Diameter/gen" -> diameterThumb[rec],
    "Global Dimension" -> rnd[globalDimension[rec], 0.01], "Dimension" -> ar[dimension[rec], dimensionError[rec]], "Dimensions" -> dimensionThumb[rec],
    "Curvature" -> ar[curvature[rec], curvatureError[rec]], "Curvatures" -> curvatureThumb[rec],
    "Volume Growth" -> growthThumb[rec], "Log Diff Q" -> ldqThumb[rec], "Stability Score" -> rnd[stabilityScore[rec], 0.001]|>;
buildExampleRules[raw_, ids_] := Association[(# -> exampleRow[#, raw[#]]) & /@ ids];

(* LANDSCAPE-BEGIN  (lifted verbatim into the notebook; self-contained over the baked allRules + exampleRules)
With[{pts = Select[{#1, #2["Dimension"], #2["DimensionError"], #2["Curvature"], #2["CurvatureError"], #2["StabilityScore"]} & @@@ Normal[allRules],
     NumericQ[#[[2]]] && NumericQ[#[[4]]] && NumericQ[#[[6]]] &]},
  Module[{ds = pts[[All, 2]], cs = pts[[All, 4]], dr, cr, inr, ssr, cf, col, mk, tip, ovr},
   dr = Quantile[ds, {0.03, 0.97}]; cr = Quantile[cs, {0.03, 0.97}];
   inr = Select[pts, dr[[1]] <= #[[2]] <= dr[[2]] && cr[[1]] <= #[[4]] <= cr[[2]] &];
   ssr = Quantile[pts[[All, 6]], {0.05, 0.95}];
   cf = Blend[{StandardGray, StandardGreen}, #] &;
   col[s_] := cf[Clip[Rescale[s, ssr], {0, 1}]];
   mk[p_] := {col[p[[6]]], PointSize[0.006], Point[{p[[2]], p[[4]]}]};
   tip[p_] := Column[{Style[p[[1]], Bold], Row[{"dim ", Around[p[[2]], p[[3]]], "   curv ", Around[p[[4]], p[[5]]]}],
      Replace[exampleRules[p[[1]]]["State"], Except[_?ImageQ] -> Nothing]}, Center];
   ovr = Graphics[{StandardGray, PointSize[0.0035], Point[pts[[All, {2, 4}]]],
       Directive[StandardRed, AbsoluteThickness[1.5]], Line[{{dr[[1]], cr[[1]]}, {dr[[2]], cr[[1]]}, {dr[[2]], cr[[2]]}, {dr[[1]], cr[[2]]}, {dr[[1]], cr[[1]]}}]},
      Frame -> True, FrameLabel -> {"Dimension", "Curvature"}, Background -> White, ImageSize -> 360, AspectRatio -> 1/GoldenRatio,
      PlotRange -> {Quantile[ds, {0.002, 0.998}], Quantile[cs, {0.002, 0.998}]},
      PlotLabel -> Style["all rules; red box = region at left", 11]];
   Row[{
     Legended[
       Graphics[Table[Tooltip[Hyperlink[mk[p], "https://www.wolframphysics.org/universes/" <> p[[1]] <> "/"], tip[p]], {p, inr}],
        Frame -> True, FrameLabel -> {"Dimension", "Curvature"}, PlotRange -> {dr, cr}, Background -> White,
        ImageSize -> 640, AspectRatio -> 1/GoldenRatio,
        PlotLabel -> Style["3\[Dash]97% quantile per axis", 12]],
       BarLegend[{cf, ssr}, LegendLabel -> "Stability Score", LegendMarkerSize -> 200]],
     Spacer[20], ovr}]]]
LANDSCAPE-END *)
