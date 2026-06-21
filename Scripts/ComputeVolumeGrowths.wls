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
(* per radius, over centers: geometric mean +- SEM (Exp[MeanAround[Log V]] = exp of the mean of ln V,
   error sigma_lnV/Sqrt[n]) drives the log-difference quotients / dimension-curvature fit; arithmetic
   mean +- standard deviation (Around[Mean, StandardDeviation]) drives the volume plots. Both kept. *)
volumes[state_] :=
  Module[{graph = Hypergraph2Section[state], vols, perRadius},
   If[VertexCount[graph] < 2, Return[<|"Geom" -> {Around[1, 0]}, "Arith" -> {Around[1, 0]}|>]];
   vols = BallVolumes[graph, All, All, "Measure" -> "Counting"];
   perRadius = Transpose[PadRight[#, Max[Length /@ vols], Last[#]] & /@ vols];
   <|"Geom" -> (Exp[MeanAround[Log[#]]] & /@ perRadius), "Arith" -> (Around[Mean[#], StandardDeviation[#]] & /@ perRadius)|>];
compute[spec_] :=
  Module[{s, geom = {}, arith = {}, vcs = {}, ecs = {}, dias = {}, v},
   s = TimeConstrained[Rest[WolframModel[spec[[2]]["Rule"], spec[[2]]["InitialCondition"],
        <|"MaxGenerations" -> 14, "MaxVertices" -> 5000, "MaxEvents" -> 100000|>]["StatesList"]], 150, $Failed];
   If[s === $Failed || Length[s] < 1, Return[<|"Failed" -> True|>]];
   Do[v = TimeConstrained[volumes[s[[i]]], 150, $Aborted];
      If[v === $Aborted, Break[]];
      AppendTo[geom, v["Geom"]]; AppendTo[arith, v["Arith"]]; AppendTo[vcs, Length[Union[Flatten[s[[i]]]]]];
      AppendTo[ecs, Length[s[[i]]]]; AppendTo[dias, Length[v["Geom"]] - 1], {i, Length[s]}];
   If[geom === {}, <|"Failed" -> True|>,
    <|"Growths" -> geom, "VolumeMeans" -> arith, "VertexCounts" -> vcs, "EdgeCounts" -> ecs, "Diameters" -> dias,
      "FinalState" -> s[[Length[geom]]], "Partial" -> (Length[geom] < Length[s])|>]];

dir = ParentDirectory[DirectoryName[$InputFileName]];
dataFile = FileNameJoin[{dir, "Data", "AverageVolumeGrowths.wxf"}];
save[d_] := (Export[dataFile <> ".tmp", d, "WXF"]; RenameFile[dataFile <> ".tmp", dataFile, OverwriteTarget -> True]);
data = If[FileExistsQ[dataFile], Import[dataFile], <||>];
nRules = If[Length[$ScriptCommandLine] > 1, ToExpression[$ScriptCommandLine[[2]]], All];
cleanQ[a_] := AssociationQ[a] && (KeyExistsQ[a, "VolumeMeans"] || TrueQ[a["Failed"]]);

nk = Max[2, Floor[$ProcessorCount/2]];
LaunchKernels[nk]; ParallelEvaluate[Needs["SetReplace`"]; Needs["WolframInstitute`Infrageometry`"]]; DistributeDefinitions[volumes, compute];
allids = If[nRules === All, wmd[], wmd[][[ ;; UpTo[nRules] ]]];
todo = Select[allids, ! cleanQ[data[#]] &];
Print["[", DateString["ISODateTime"], "] ", Length@allids, " rules, to compute: ", Length@todo, "  on ", $KernelCount, " kernels"];

(* specs are fetched per batch (wmd[batch, All]) - fetching all ~947 at once hangs the resource
   connection, while 40 at a time is fast and the results cache. Invalid ids (no rule) -> Failed. *)
done = 0;
Do[Module[{specs, validIds},
    specs = Select[Transpose[{batch, wmd[batch, All]}], MatchQ[#[[2]]["Rule"], {(_Rule | _RuleDelayed) ..}] &];
    validIds = #[[1]] & /@ specs;
    AssociateTo[data, Association @ ParallelMap[#[[1]] -> compute[#] &, specs, Method -> "FinestGrained"]];
    AssociateTo[data, Association[# -> <|"Failed" -> True|> & /@ Complement[batch, validIds]]]];
   save[data]; done += Length@batch;
   Print["[", DateString["ISODateTime"], "] ", done, "/", Length@todo,
      "  valid=", Count[Values@data, _?(KeyExistsQ[#, "VolumeMeans"] &)], " partial=", Count[Values@data, _?(TrueQ[#["Partial"]] &)]],
   {batch, Partition[todo, 40, 40, 1, {}]}];
Print["[", DateString["ISODateTime"], "] DONE. valid=", Count[Values@data, _?(KeyExistsQ[#, "VolumeMeans"] &)],
   " partial=", Count[Values@data, _?(TrueQ[#["Partial"]] &)], " failed=", Count[Values@data, _?(TrueQ[#["Failed"]] &)]];
