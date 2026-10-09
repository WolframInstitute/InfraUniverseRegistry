#!/usr/bin/env wolframscript
(* Generate Notebooks/VolumeGrowth_{Table,Single}.nb from the matching .md SOURCE files.

   The .md files are the single source of truth: they hold all prose, section structure, and
   display/analysis code. This script parses them into cells, evaluates the code (so the .nb is
   fully evaluated and renders statically in the cloud), and injects the things markdown cannot
   carry -- the Table's baked data blob and every Output cell.

   Markdown conventions (per code fence and heading):
     ```wolfram             plain Input, not evaluated (e.g. the local rebuild cells)
     ```wolfram init        InitializationCell, evaluated for side effects, no Output
     ```wolfram run         evaluated for side effects, plain Input, no Output (setup cells)
     ```wolfram eval        evaluated; Input (open) + baked Output
     ```wolfram bake        evaluated; Input (folded) + baked Output
     ```wolfram inject:KEY  body replaced by the generated text inj[KEY], as an init cell
     ## Heading {closed}    section wrapped in a Closed (folded) cell group

   Table needs no paclet (self-contained data + core WL); Single loads the paclet via its init cell
   and computes one rule live (Hypergraph2Section + BallVolumes + DimensionCurvatureFit).

   Usage: wolframscript -file GenerateVolumeGrowthNotebooks.wls [Table|Single]. A Table run is a
   cache hit (seconds); a Single run does the live wm3382 recompute (minutes). NEVER edit the .nb
   by hand -- edit the .md and regenerate, or the change is lost on the next run. *)

scriptDir = DirectoryName[$InputFileName];
root = ParentDirectory[scriptDir];
nbDir = FileNameJoin[{root, "Notebooks"}];
buildScript = FileNameJoin[{scriptDir, "BuildVolumeGrowthTable.wls"}];

target = If[Length[$ScriptCommandLine] > 1, $ScriptCommandLine[[2]], "All"];
doTable = MatchQ[target, "All" | "Table"];
doSingle = MatchQ[target, "All" | "Single"];

(* ---------- markdown source -> notebook cells ---------- *)
(* Triple backtick built from char codes (literal ``` is fragile through some tooling). *)
bq = FromCharacterCode[96]; tq = bq <> bq <> bq;

parseProse[s_] := Module[{t = StringTrim[s], paras},
   If[t === "", Return[{}]];
   paras = StringSplit[t, RegularExpression["\\n[ \\t]*\\n"]];
   Map[Which[
      StringStartsQ[#, "# "], item["title", StringTrim @ StringDrop[#, 2], None],
      StringStartsQ[#, "## "], With[{r = StringTrim @ StringDrop[#, 3]},
         item["section", StringTrim @ StringReplace[r, "{closed}" -> ""], StringEndsQ[r, "{closed}"]]],
      StringStartsQ[#, "### "], item["subsection", StringTrim @ StringDrop[#, 4], None],
      True, item["text", #, None]] &, paras]];

parseSource[md_] := With[
   {fence = tq ~~ "wolfram" ~~ tag : Shortest[___] ~~ "\n" ~~ b : Shortest[___] ~~ "\n" ~~ tq},
   Flatten @ Map[If[StringQ[#], parseProse[#], {item["code", #[[1]], StringTrim[#[[2]]]]}] &,
      StringSplit[md, fence :> codeChunk[b, tag]]]];

groupClosed[items_] := Module[{out = {}, i = 1, n = Length[items], g},
   While[i <= n,
    If[MatchQ[items[[i]], item["section", _, True]],
      g = {items[[i]]}; i++;
      While[i <= n && ! MatchQ[items[[i]], item["section", _, _] | item["title", _, _]],
        AppendTo[g, items[[i]]]; i++];
      AppendTo[out, grp[g]],
      AppendTo[out, items[[i]]]; i++]];
   out];

itemCell[item["title", t_, _], _] := {Cell[t, "Title"]};
itemCell[item["section", t_, _], _] := {Cell[t, "Section"]};
itemCell[item["subsection", t_, _], _] := {Cell[t, "Subsection"]};
itemCell[item["text", t_, _], _] := {Cell[t, "Text"]};
itemCell[item["code", c_, ""], _] := {Cell[BoxData[c], "Input"]};
itemCell[item["code", c_, "init"], _] := (ToExpression[c]; {Cell[BoxData[c], "Input", InitializationCell -> True]});
itemCell[item["code", c_, "run"], _] := (ToExpression[c]; {Cell[BoxData[c], "Input"]});
itemCell[item["code", c_, "eval"], _] := Module[{r = ToExpression[c]},
   {Cell[BoxData[c], "Input"], Cell[BoxData[ToBoxes[r]], "Output"]}];
itemCell[item["code", c_, "bake"], _] := Module[{r = ToExpression[c]},
   {Cell[BoxData[c], "Input", CellOpen -> False], Cell[BoxData[ToBoxes[r]], "Output"]}];
itemCell[item["code", _, tag_ /; StringStartsQ[tag, "inject:"]], inj_] :=
   Module[{blob = inj[StringDrop[tag, StringLength["inject:"]]]},
      ToExpression[blob]; {Cell[BoxData[blob], "Input", InitializationCell -> True]}];

assemble[items_, inj_] := Join @@ Map[
   Replace[#, {
      grp[g_] :> {Cell[CellGroupData[Join @@ (itemCell[#, inj] & /@ g), Closed]]},
      it_ :> itemCell[it, inj]}] &,
   groupClosed[items]];

buildNotebook[base_, inj_] := Module[{cells},
   cells = assemble[parseSource[Import[FileNameJoin[{nbDir, base <> ".md"}], "Text"]], inj];
   Export[FileNameJoin[{nbDir, base <> ".nb"}], Notebook[cells]];
   Print["wrote ", base, "  (nb ", Round[FileByteCount[FileNameJoin[{nbDir, base <> ".nb"}]]/1.*^6, 0.1], " MB)"]];

(* ---------- Table: compute the data, inject it, bake the display outputs ---------- *)
If[ doTable,
Get[buildScript];
(* BIG thumbnails for the 20 featured rows: override the small defaults from the build script *)
thumbOpts = Sequence[ImageSize -> 200, AspectRatio -> 0.8, Frame -> True, PlotRangePadding -> Scaled[0.03],
   ImagePadding -> {{48, 8}, {28, 8}}, Background -> White, BaseStyle -> {FontSize -> 17},
   Mesh -> All, MeshStyle -> Directive[PointSize[0.018], Black]];
finalStateThumb[rec_] := TimeConstrained[Quiet @ ImageResize[Rasterize[ResourceFunction["WolframModelPlot"][rec["FinalState"], ImageSize -> 300], ImageResolution -> 72], {UpTo[300], UpTo[300]}], 120, dash];

dataFile = FileNameJoin[{root, "Data", "AverageVolumeGrowths.wxf"}];
cacheFile = FileNameJoin[{root, "Data", "table.wxf"}];
raw = Select[Import[dataFile], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
(* Example rules = the first 20 universes from https://www.wolframphysics.org/universes/index.html,
   in their index order (matches the registry key order). *)
exampleIds = {"wm11114", "wm1113", "wm1116", "wm1137", "wm1157", "wm1158", "wm1167", "wm1172", "wm1173",
   "wm1194", "wm1199", "wm121", "wm1218", "wm12518", "wm1268", "wm1271", "wm1277", "wm1295", "wm1316", "wm1321"};
(* Local cache: {allRules, exampleData}. Reused unless the source data or BuildVolumeGrowthTable.wls
   is newer, so layout-only re-runs skip the heavy recompute (all-rule scalars + example thumbnails).
   Data/ is gitignored. *)
{allRules, exampleData} = If[
   FileExistsQ[cacheFile] && FileDate[cacheFile] > FileDate[dataFile] && FileDate[cacheFile] > FileDate[buildScript],
   Print["table cache hit: ", cacheFile]; Import[cacheFile],
   Print["computing table data (no valid cache) ..."];
   Module[{all, ex},
    all = volumeGrowthScalars /@ raw;
    Print["example rules (first 20 of the universe index): ", exampleIds];
    ex = buildExampleData[raw, all, exampleIds];
    Export[cacheFile, {all, ex}, "WXF"];
    Print["cached table: ", cacheFile];
    {all, ex}]];

dataBlob = StringRiffle[{
    "exampleData = Uncompress[" <> ToString[Compress[exampleData], InputForm] <> "];",
    "allRules = Uncompress[" <> ToString[Compress[allRules], InputForm] <> "];"}, "\n\n"];

buildNotebook["VolumeGrowth_Table", <|"data" -> dataBlob|>];
];

(* ---------- Single: paclet + live recompute, all driven by the .md ---------- *)
If[ doSingle,
buildNotebook["VolumeGrowth_Single", <||>];
];
