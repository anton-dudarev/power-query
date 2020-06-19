let
	Source = {0..54},
	ConvertedToTable = Table.FromList(
		Source, 
		Splitter.SplitByNothing(), 
		null, 
		null, 
		ExtraValues.Error
	),
	TableToList = Table.ToList(Table.TransformColumnTypes(ConvertedToTable, {{"Column1", type text}}))
in
	TableToList