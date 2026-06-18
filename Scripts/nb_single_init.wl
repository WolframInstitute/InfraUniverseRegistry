Needs["SetReplace`"];
Get[FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Code", "BallVolumeGrowth.wl"}]];
data = Select[Import[FileNameJoin[{ParentDirectory[NotebookDirectory[]], "Data", "AverageBallVolumeGrowths.wxf"}]], AssociationQ[#] && KeyExistsQ[#, "Growths"] &];
wmd = ResourceFunction["WolframModelData"];
spec = <|"MaxGenerations" -> 14, "MaxVertices" -> 5000, "MaxEvents" -> 100000|>;
exId = "wm3382";
