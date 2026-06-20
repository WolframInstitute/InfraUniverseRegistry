#!/usr/bin/env wolframscript
(* Build the raw data: evolve every registry rule and measure the averaged ball-volume growth.
   Writes Data/AverageVolumeGrowths.wxf :: <|id -> <|Growths, VertexCounts, EdgeCounts,
   Diameters, FinalState|>|>. Volumes are computed generation-by-generation and kept for every
   generation that fits the per-generation time cap; heavy rules are kept Partial. Geometry is the
   WolframInstitute`Infrageometry` paclet (Hypergraph2Section + BallVolumes "Counting"); the per-radius
   value is the geometric mean over centers Exp[MeanAround[Log V]]. Half the cores, atomic saves,
   resumable. Usage: wolframscript -file ComputeVolumeGrowths.wls [nRules] *)

Needs["SetReplace`"];
Needs["WolframInstitute`Infrageometry`"];
wmd = ResourceFunction["WolframModelData"];
volumes[state_] :=
  Module[{graph = Graph[DeleteCases[UndirectedEdge[a_, a_]][DeleteDuplicates[UndirectedEdge @@@ Catenate[Subsets[#, {2}] & /@ state]]]], vols},
   If[VertexCount[graph] < 2, Return[{Around[1, 0]}]];
   vols = BallVolumes[graph, All, All, "Measure" -> "Counting"];
   Exp[MeanAround[Log[#]]] & /@ Transpose[PadRight[#, Max[Length /@ vols], Last[#]] & /@ vols]];
compute[spec_] :=
  Module[{s, g = {}, vcs = {}, ecs = {}, dias = {}, v},
   s = TimeConstrained[Rest[WolframModel[spec[[2]]["Rule"], spec[[2]]["InitialCondition"],
        <|"MaxGenerations" -> 14, "MaxVertices" -> 5000, "MaxEvents" -> 100000|>]["StatesList"]], 150, $Failed];
   If[s === $Failed || Length[s] < 1, Return[<|"Failed" -> True|>]];
   Do[v = TimeConstrained[volumes[s[[i]]], 150, $Aborted];
      If[v === $Aborted, Break[]];
      AppendTo[g, v]; AppendTo[vcs, Length[Union[Flatten[s[[i]]]]]];
      AppendTo[ecs, Length[s[[i]]]]; AppendTo[dias, Length[v] - 1], {i, Length[s]}];
   If[g === {}, <|"Failed" -> True|>,
    <|"Growths" -> g, "VertexCounts" -> vcs, "EdgeCounts" -> ecs, "Diameters" -> dias,
      "FinalState" -> s[[Length[g]]], "Partial" -> (Length[g] < Length[s])|>]];

dir = ParentDirectory[DirectoryName[$InputFileName]];
dataFile = FileNameJoin[{dir, "Data", "AverageVolumeGrowths.wxf"}];
save[d_] := (Export[dataFile <> ".tmp", d, "WXF"]; RenameFile[dataFile <> ".tmp", dataFile, OverwriteTarget -> True]);
data = If[FileExistsQ[dataFile], Import[dataFile], <||>];
nRules = If[Length[$ScriptCommandLine] > 1, ToExpression[$ScriptCommandLine[[2]]], All];
cleanQ[a_] := AssociationQ[a] && (KeyExistsQ[a, "Growths"] || TrueQ[a["Failed"]]);

nk = Max[2, Floor[$ProcessorCount/2]];
LaunchKernels[nk]; ParallelEvaluate[Needs["SetReplace`"]; Needs["WolframInstitute`Infrageometry`"]]; DistributeDefinitions[volumes, compute];
allids = If[nRules === All, wmd[], wmd[][[ ;; UpTo[nRules] ]]];
Print["[", DateString["ISODateTime"], "] metadata for ", Length@allids, " rules..."];
specs = Select[Transpose[{allids, wmd[allids, All]}], MatchQ[#[[2]]["Rule"], {(_Rule | _RuleDelayed) ..}] &];
todo = Select[specs, ! cleanQ[data[#[[1]]]] &];
Print["valid: ", Length@specs, "  to compute: ", Length@todo, "  on ", $KernelCount, " kernels"];

done = 0;
Do[AssociateTo[data, Association @ ParallelMap[#[[1]] -> compute[#] &, batch]];
   save[data]; done += Length@batch;
   Print["[", DateString["ISODateTime"], "] ", done, "/", Length@todo,
      "  valid=", Count[Values@data, _?(KeyExistsQ[#, "Growths"] &)], " partial=", Count[Values@data, _?(TrueQ[#["Partial"]] &)]],
   {batch, Partition[todo, 40, 40, 1, {}]}];
Print["[", DateString["ISODateTime"], "] DONE. valid=", Count[Values@data, _?(KeyExistsQ[#, "Growths"] &)],
   " partial=", Count[Values@data, _?(TrueQ[#["Partial"]] &)], " failed=", Count[Values@data, _?(TrueQ[#["Failed"]] &)]];
