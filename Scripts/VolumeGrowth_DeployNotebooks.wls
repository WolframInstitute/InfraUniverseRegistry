#!/usr/bin/env wolframscript
(* Deploy the two generated notebooks as PUBLIC cloud notebooks. They are self-contained and
   fully evaluated (built by VolumeGrowth_GenerateNotebooks.wls), so they render without a kernel. *)
root = ParentDirectory[DirectoryName[$InputFileName]];
If[! TrueQ[$CloudConnected], CloudConnect[]];
deployNb[base_, cloudName_] := Module[{nb = Import[FileNameJoin[{root, "Notebooks", base <> ".nb"}]], obj},
   obj = CloudDeploy[nb, cloudName, Permissions -> "Public"];
   Print[cloudName, " -> ", First[obj]]; obj];
deployNb["VolumeGrowth_Table", "InfraUniverseRegistry/VolumeGrowth"];
deployNb["VolumeGrowth_Single", "InfraUniverseRegistry/VolumeGrowthSingle"];
