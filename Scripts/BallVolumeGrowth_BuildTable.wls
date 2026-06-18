#!/usr/bin/env wolframscript
(* Build the cached table: Data/AverageBallVolumeGrowths.wxf -> Data/table.wxf.
   Each row is fully precomputed (query scalars + baked thumbnails) by `tableRow`, so the
   Table notebook (and its cloud deployment) only displays/queries it -- no recomputation.
   Parallel, resumable, atomic saves. Usage: wolframscript -file BallVolumeGrowth_BuildTable.wls *)

dir = ParentDirectory[DirectoryName[$InputFileName]];
codeFile = FileNameJoin[{dir, "Code", "BallVolumeGrowth.wl"}];
dataFile = FileNameJoin[{dir, "Data", "AverageBallVolumeGrowths.wxf"}];
tableFile = FileNameJoin[{dir, "Data", "table.wxf"}];
save[t_] := (Export[tableFile <> ".tmp", t, "WXF"]; RenameFile[tableFile <> ".tmp", tableFile, OverwriteTarget -> True]);

Get[codeFile];
data = Select[Import[dataFile], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
table = If[FileExistsQ[tableFile], Import[tableFile], <||>];
todo = Normal @ KeyDrop[data, Keys[table]];

nk = Max[2, Floor[$ProcessorCount/2]];
LaunchKernels[nk];
ParallelEvaluate[Get[codeFile]];
Print["[", DateString["ISODateTime"], "] caching ", Length@todo, " of ", Length@data, " rows on ", $KernelCount, " kernels"];

done = 0;
Do[
  AssociateTo[table, Select[Association @ ParallelMap[(#[[1]] -> TimeConstrained[tableRow[#[[1]], #[[2]]], 90, Missing[]]) &, batch], AssociationQ]];
  save[table]; done += Length@batch;
  Print["[", DateString["ISODateTime"], "] cached ", done, "/", Length@todo, " (table: ", Length@table, ")"],
  {batch, Partition[todo, 50, 50, 1, {}]}];

Print["[", DateString["ISODateTime"], "] DONE. table.wxf rows = ", Length@table,
   "  size = ", Round[FileByteCount[tableFile]/1.*^6, 0.1], " MB"];
