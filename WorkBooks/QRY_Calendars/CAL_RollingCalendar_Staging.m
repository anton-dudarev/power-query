let
	Source = #date(CAL_Rolling_Year, 1, 1),
	GeneratedRollingCalendar = List.Dates(
		Source, 
		Number.From(DateTime.FixedLocalNow()) - Number.From(Source), 
		#duration(1, 0, 0, 0)
	),
	ConvertedToTable = Table.FromList(
		GeneratedRollingCalendar, 
		Splitter.SplitByNothing(), 
		null, 
		null, 
		ExtraValues.Error
	),
	RenamedColumns = Table.RenameColumns(ConvertedToTable, {{"Column1", "Date"}}),
	ChangedType = Table.TransformColumnTypes(RenamedColumns, {{"Date", type date}}),
	SortedRows = Table.Sort(ChangedType, {{"Date", Order.Descending}}),
	RemovedDuplicates = Table.Distinct(SortedRows)
in
	RemovedDuplicates