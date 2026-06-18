(* VolumeGrowth — infrageometric observables for the Wolfram notable universes.
   Compute functions (need WolframInstitute`Infrageometry`) + thumbnail builders + the
   cached-table row builder `tableRow`. Loaded by the Compute / CacheTable scripts and by
   the Single-rule notebook. The Table notebook does NOT load this (it only displays the
   precomputed cached table, no paclet needed). *)

Needs["WolframInstitute`Infrageometry`"];
Needs["SetReplace`"];

url[id_] := "https://www.wolframphysics.org/universes/" <> id <> "/";
ruleLink[id_] := Hyperlink[id, url[id]];
strip = # /. Around[a_, _] :> a &;
numQ = NumericQ[# /. Around[a_, _] :> a] &;

fit[q_] :=
  If[Length[q] < 2, {Missing[], Missing[]},
   Module[{cv = strip[q], k = Length[q], x, rs, mat, c},
    x = N[Range[k] (Range[k] + 1)];
    rs = If[k < 5, Range[k],
      Module[{k0 = 5, sx, sxx, sq, sqq, sxq, rse, tol},
       sx = Prepend[Accumulate[x], 0.]; sxx = Prepend[Accumulate[x^2], 0.];
       sq = Prepend[Accumulate[cv], 0.]; sqq = Prepend[Accumulate[cv^2], 0.];
       sxq = Prepend[Accumulate[x cv], 0.];
       rse = {i, j} |-> Module[
          {m = N[j - i + 1], ax = sx[[j + 1]] - sx[[i]], axx = sxx[[j + 1]] - sxx[[i]],
           aq = sq[[j + 1]] - sq[[i]], aqq = sqq[[j + 1]] - sqq[[i]], axq = sxq[[j + 1]] - sxq[[i]], b},
          b = (m axq - ax aq)/(m axx - ax^2);
          Sqrt[Max[aqq - (aq - b ax) aq/m - b axq, 0.]/(m - 2)]];
       tol = Max[2 Quantile[Table[rse[i, i + k0 - 1], {i, 1, k - k0 + 1}], 1/4], 1.*^-10];
       Range @@ SelectFirst[
         Catenate[Table[{i, i + len - 1}, {len, k, k0, -1}, {i, 1, k - len + 1}]],
         p |-> rse[p[[1]], p[[2]]] <= tol, {1, k}]]];
    mat = PseudoInverse[Transpose[{ConstantArray[1., Length[rs]], x[[rs]]}]];
    c = mat . q[[rs]];
    {c[[1]], -3 (c[[1]] + 2) c[[2]]}]];

dimcurvSeq[rec_] := fit /@ (LogDifferenceQuotients /@ rec["Growths"]);
lastFit[rec_] := Module[{dc = Select[dimcurvSeq[rec], numQ[#[[1]]] && numQ[#[[2]]] &]}, If[dc === {}, Missing[], Last[dc]]];
dimension[rec_] := Replace[lastFit[rec], {{d_, _} :> strip[d], _ :> Missing[]}];
dimensionError[rec_] := Replace[lastFit[rec], {{Around[_, e_], _} :> e, {_, _} :> 0., _ :> Missing[]}];
curvature[rec_] := Replace[lastFit[rec], {{_, k_} :> strip[k], _ :> Missing[]}];
curvatureError[rec_] := Replace[lastFit[rec], {{_, Around[_, e_]} :> e, {_, _} :> 0., _ :> Missing[]}];
trajectory[rec_] := Cases[Transpose[{strip[dimcurvSeq[rec]], rec["VertexCounts"]}], {{_?NumericQ, _?NumericQ}, _}];
stabilityScore[rec_] :=
  Module[{t = trajectory[rec], tail},
   tail = If[Length[t] >= 2, Take[t[[All, 1]], -Ceiling[Length[t]/3]], {}];
   If[Length[tail] >= 2, 1./(1. + Max[EuclideanDistance @@@ Subsets[tail, {2}]]), Missing[]]];
finalDiameter[rec_] := Last[rec["Diameters"]];
growthClass[rec_] :=
  Module[{dia = rec["Diameters"], k},
   k = Length[dia];
   Which[k < 2, "static", Last[dia] > dia[[Max[1, k - 2]]], "expanding",
    Last[dia] < dia[[Max[1, k - 2]]], "contracting", True, "static"]];
graphDimension[rec_] :=
  With[{v = Last[rec["VertexCounts"]], d = finalDiameter[rec]}, If[TrueQ[d > 1], Log[v]/Log[d], Missing[]]];
slope[ys_] := With[{n = Length[ys]},
   If[n < 2, 0., Module[{x = Range[n]}, N[(n Total[x ys] - Total[x] Total[ys])/(n Total[x^2] - Total[x]^2)]]]];
diameterGrowth[rec_] := slope[rec["Diameters"]];
vertexGrowth[rec_] := slope[rec["VertexCounts"]];

scalars[rec_] :=
  <|"Dimension" -> dimension[rec], "Curvature" -> curvature[rec], "Vertices" -> Last[rec["VertexCounts"]],
    "Diameter" -> finalDiameter[rec], "GraphDimension" -> graphDimension[rec], "Growth" -> growthClass[rec],
    "Stability" -> stabilityScore[rec]|>;

graphOf[edges_] := Graph[DeleteCases[UndirectedEdge[a_, a_]][DeleteDuplicates[UndirectedEdge @@@ Catenate[Subsets[#, {2}] & /@ edges]]]];
graphOpts = Sequence[VertexStyle -> Black, VertexSize -> {"Scaled", 0.012}, EdgeStyle -> Directive[Opacity[0.25], StandardGray]];
dash = Style["\[LongDash]", GrayLevel[0.55], 20];
seriesColors[n_, c1_, c2_] := Blend[{c1, c2}, #] & /@ Subdivide[0., 1., Max[n - 1, 1]];
mt[m_] := {{m, If[Abs[N@m] >= 10, Round[m], Round[N@m, 0.1]]}};
(* conservative image size, but LARGE tick labels so a single max tick stays readable at low res *)
thumbOpts = Sequence[ImageSize -> 104, AspectRatio -> 0.8, Frame -> True, PlotRangePadding -> Scaled[0.03],
   ImagePadding -> {{36, 5}, {22, 5}}, Background -> White, BaseStyle -> {FontSize -> 15},
   Mesh -> All, MeshStyle -> Directive[PointSize[0.016], Black]];

growthThumb[rec_] := Module[{vol = rec["Growths"], sv = strip[rec["Growths"]]},
   If[Max[Length /@ sv] < 2, dash,
    Rasterize @ ListLinePlot[vol, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[vol], StandardYellow, StandardRed]),
      FrameTicks -> {{mt[Max[Flatten[sv]]], None}, {mt[Max[Length /@ sv]], None}}, thumbOpts]]];
ldqThumb[rec_] := Module[{q = LogDifferenceQuotients /@ rec["Growths"], sq, fl},
   sq = strip[q]; fl = Flatten[sq];
   If[fl === {} || Max[Length /@ sq] < 2, dash,
    Rasterize @ Quiet @ ListLinePlot[q, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[q], StandardYellow, StandardGreen]),
      FrameTicks -> {{mt[Max[fl]], None}, {mt[Max[Length /@ sq]], None}}, thumbOpts]]];
dimensionThumb[rec_] := Module[{d = DeleteCases[MapIndexed[{First[#2], #1[[1]]} &, dimcurvSeq[rec]], {_, _Missing}]},
   If[Length[d] < 1, dash,
    Rasterize @ ListLinePlot[d, PlotStyle -> Directive[AbsoluteThickness[2], StandardBlue], IntervalMarkersStyle -> StandardBlue,
      FrameTicks -> {{mt[Max[strip[d[[All, 2]]]]], None}, {mt[Max[d[[All, 1]]]], None}}, thumbOpts]]];
curvatureThumb[rec_] := Module[{d = DeleteCases[MapIndexed[{First[#2], #1[[2]]} &, dimcurvSeq[rec]], {_, _Missing}]},
   If[Length[d] < 1, dash,
    Rasterize @ ListLinePlot[d, PlotStyle -> Directive[AbsoluteThickness[2], StandardPurple], IntervalMarkersStyle -> StandardPurple,
      FrameTicks -> {{mt[Max[strip[d[[All, 2]]]]], None}, {mt[Max[d[[All, 1]]]], None}}, thumbOpts]]];
vertexThumb[rec_] := Module[{vc = rec["VertexCounts"]},
   If[Length[vc] < 2, dash,
    Rasterize @ ListLinePlot[vc, PlotStyle -> Directive[AbsoluteThickness[2], StandardBrown],
      FrameTicks -> {{mt[Max[vc]], None}, {mt[Length[vc]], None}}, thumbOpts]]];
diameterThumb[rec_] := Module[{dia = rec["Diameters"]},
   If[Length[dia] < 2, dash,
    Rasterize @ ListLinePlot[dia, PlotStyle -> Directive[AbsoluteThickness[2], StandardOrange],
      FrameTicks -> {{mt[Max[dia]], None}, {mt[Length[dia]], None}}, thumbOpts]]];
finalStateThumb[rec_] := TimeConstrained[Quiet @ Rasterize[WolframModelPlot[rec["FinalState"], ImageSize -> {UpTo[140], UpTo[140]}], ImageResolution -> 72], 90, dash];

tableRow[id_, rec_] := <|
   "Dimension" -> dimension[rec], "DimensionError" -> dimensionError[rec],
   "Curvature" -> curvature[rec], "CurvatureError" -> curvatureError[rec],
   "StabilityScore" -> stabilityScore[rec], "Generation" -> Length[rec["VertexCounts"]],
   "Vertices" -> Last[rec["VertexCounts"]], "Edges" -> Length[rec["FinalState"]], "Diameter" -> finalDiameter[rec],
   "GraphDimension" -> graphDimension[rec], "DiameterGrowth" -> diameterGrowth[rec], "VertexGrowth" -> vertexGrowth[rec],
   "StateThumb" -> finalStateThumb[rec], "VolumeThumb" -> growthThumb[rec], "LDQThumb" -> ldqThumb[rec],
   "DimThumb" -> dimensionThumb[rec], "CurvThumb" -> curvatureThumb[rec], "VertexThumb" -> vertexThumb[rec], "DiameterThumb" -> diameterThumb[rec]|>;
