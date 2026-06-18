#!/usr/bin/env wolframscript
(* Generate Notebooks/BallVolumeGrowth_Table.{nb,md} and _Single.{nb,md} from the plain-WL
   init snippets. The Table notebook only displays/queries the cached table (no paclet);
   the Single notebook loads Code/BallVolumeGrowth.wl to compute one rule's characteristics. *)
scriptDir = DirectoryName[$InputFileName];
nbDir = FileNameJoin[{ParentDirectory[scriptDir], "Notebooks"}];
tableInit = Import[FileNameJoin[{scriptDir, "nb_table_init.wl"}], "Text"];
singleInit = Import[FileNameJoin[{scriptDir, "nb_single_init.wl"}], "Text"];

q1 = "queryData[Select[NumericQ[#Dimension] && 2.5 <= #Dimension <= 3.5 && Abs[#Curvature] < 0.5 && #Vertices >= 1000 &]]";
q2 = "queryData[Select[#Vertices >= 500 && NumericQ[#StabilityScore] &]][TakeLargestBy[\"StabilityScore\", 25]]";
q3 = "queryData[ReverseSortBy[#StabilityScore Sqrt[#Vertices] &]][;; 25]";
q4 = "queryData[TakeLargestBy[\"DiameterGrowth\", 15]]";

exGraphs = "With[{rule = wmd[exId, \"Rule\"], init = wmd[exId, \"InitialCondition\"]}, GraphicsGrid[Partition[Graph[graphOf[#], ImageSize -> 110, graphOpts] & /@ Rest[WolframModel[rule, init, spec][\"StatesList\"]], UpTo[5]]]]";
exVolumes = "With[{vol = data[exId][\"Growths\"]}, ListLinePlot[vol, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[vol], StandardYellow, StandardRed]), Mesh -> All, Frame -> True, FrameLabel -> {\"radius r\", \"V(r)\"}, ImageSize -> 460, PlotRange -> All]]";
exLDQ = "With[{q = LogDifferenceQuotients /@ data[exId][\"Growths\"]}, ListLinePlot[q, PlotStyle -> (Directive[AbsoluteThickness[2], #] & /@ seriesColors[Length[q], StandardYellow, StandardGreen]), Mesh -> All, Frame -> True, FrameLabel -> {\"r\", \"q(r)\"}, ImageSize -> 460, PlotRange -> All]]";
exDimCurv = "With[{dc = dimcurvSeq[data[exId]]}, GraphicsRow[{ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[1]]} &, dc], {_, _Missing}], PlotStyle -> StandardBlue, Mesh -> All, IntervalMarkersStyle -> StandardBlue, Frame -> True, FrameLabel -> {\"iteration\", \"dimension\"}], ListLinePlot[DeleteCases[MapIndexed[{First[#2], #1[[2]]} &, dc], {_, _Missing}], PlotStyle -> StandardPurple, Mesh -> All, IntervalMarkersStyle -> StandardPurple, Frame -> True, FrameLabel -> {\"iteration\", \"curvature\"}]}, ImageSize -> 640]]";
exVertex = "ListLinePlot[data[exId][\"VertexCounts\"], PlotStyle -> StandardBrown, Mesh -> All, Frame -> True, FrameLabel -> {\"iteration\", \"vertices\"}, ImageSize -> 460]";
exTraj = "With[{t = trajectory[data[exId]]}, Legended[Graphics[{Thick, Line[t[[All, 1]], VertexColors -> (Blend[{StandardGray, StandardRed}, #] & /@ Rescale[t[[All, 2]]])], PointSize[0.025], Point[t[[All, 1]], VertexColors -> (Blend[{StandardGray, StandardRed}, #] & /@ Rescale[t[[All, 2]]])]}, Frame -> True, FrameLabel -> {\"dimension\", \"curvature\"}, AspectRatio -> 1/GoldenRatio, ImageSize -> 480, Background -> White], BarLegend[{Blend[{StandardGray, StandardRed}, Rescale[#, MinMax[t[[All, 2]]]]] &, MinMax[t[[All, 2]]]}, LegendLabel -> \"vertices\"]]]";
exStability = "With[{p = trajectory[data[exId]][[All, 1]]}, ListLinePlot[Table[Max[EuclideanDistance @@@ Subsets[p[[n0 ;;]], {2}]], {n0, 1, Length[p] - 1}], Mesh -> All, PlotStyle -> StandardBlue, Frame -> True, FrameLabel -> {\"n0\", \"tail diameter\"}, PlotLabel -> \"stability: Cauchy tail diameter (score = 1/(1+min))\", ImageSize -> 480, PlotRange -> All]]";

toMd = Replace[#, {Cell[t_String, "Title"] :> "# " <> t, Cell[t_String, "Section"] :> "## " <> t,
    Cell[t_String, "Subsection"] :> "### " <> t, Cell[t_String, "Text"] :> t,
    Cell[BoxData[c_String], "Input"] :> "```wolfram\n" <> c <> "\n```"}] &;
emit[base_, cells_] := (Export[FileNameJoin[{nbDir, base <> ".nb"}], Notebook @ cells];
   Export[FileNameJoin[{nbDir, base <> ".md"}], StringRiffle[toMd /@ cells, "\n\n"], "Text"]);

emit["BallVolumeGrowth_Table", {
   Cell["Ball Volume Growth: Table", "Title"],
   Cell["Initialization", "Section"], Cell[BoxData @ tableInit, "Input"],
   Cell["Table", "Section"],
   Cell["Pick a rule range (by order) with the two From/To fields.", "Text"],
   Cell[BoxData @ "rangeTable[]", "Input"],
   Cell["Dimension-Curvature Landscape", "Section"],
   Cell["All rules in the (dimension, curvature) plane, colored by stability (red = wandering, green = converged).", "Text"],
   Cell[BoxData @ "landscape[]", "Input"],
   Cell["Queries", "Section"],
   Cell["Dimension 2.5-3.5, near-flat curvature, at least 1000 vertices.", "Subsection"], Cell[BoxData @ q1, "Input"],
   Cell["Most converged large rules.", "Subsection"], Cell[BoxData @ q2, "Input"],
   Cell["Recommended ranking: stability score times sqrt(vertices).", "Subsection"], Cell[BoxData @ q3, "Input"],
   Cell["Fastest-expanding rules (by diameter growth).", "Subsection"], Cell[BoxData @ q4, "Input"]}];

emit["BallVolumeGrowth_Single", {
   Cell["Ball Volume Growth: Single Rule", "Title"],
   Cell["Initialization", "Section"], Cell[BoxData @ singleInit, "Input"],
   Cell["Graph at each iteration", "Section"], Cell[BoxData @ exGraphs, "Input"],
   Cell["Ball volume growth", "Section"], Cell[BoxData @ exVolumes, "Input"],
   Cell["Log difference quotients", "Section"], Cell[BoxData @ exLDQ, "Input"],
   Cell["Dimension and curvature per iteration", "Section"], Cell[BoxData @ exDimCurv, "Input"],
   Cell["Vertex growth", "Section"], Cell[BoxData @ exVertex, "Input"],
   Cell["Dimension-curvature trajectory (gray to red by vertices)", "Section"], Cell[BoxData @ exTraj, "Input"],
   Cell["Stability (Cauchy tail diameter)", "Section"], Cell[BoxData @ exStability, "Input"]}];
Print["wrote BallVolumeGrowth_Table and _Single (.nb + .md)"];
