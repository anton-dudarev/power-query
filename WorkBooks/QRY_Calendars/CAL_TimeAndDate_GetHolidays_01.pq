let
	Source = Web.Page(
		Web.Contents(
			"https://www.timeanddate.com/calendar/custom.html?year=" & Text.From(lstYears{0})
			& "&month=1&months=12&country=20&typ=2&display=2&cols=1&lang=ru&fdow=1&wno=1&hol=25166137&hcl=2&cdt=32&holm=1&doy=1&df=1"
		)
	),
	Data = Source{0}[Data],
	AddedCustomColumn = Table.AddColumn(
		Table.DemoteHeaders(Data), 
		"Custom", 
		each if Value.Is([Column1], type table) then [Column1] else null
	),
	AddedYearMonth = Table.AddColumn(
		AddedCustomColumn, 
		"Year Month", 
		each if Value.Is([Column1], type table) then null else [Column1]
	),
	RemovedColumns = Table.RemoveColumns(AddedYearMonth, {"Column1"}),
	FilledDown = Table.FillDown(RemovedColumns, {"Year Month"}),
	ExpandTableColumn = Table.ExpandTableColumn(
		FilledDown, 
		"Custom", 
		{"Column1", "Column2", "Column3"}, 
		{"Column1", "Column2", "Column3"}
	),
	FilterColumnNotNull = Table.SelectRows(ExpandTableColumn, each ([Column1] <> null)),
	SplittedColumnByDelimiter = Table.SplitColumn(
		FilterColumnNotNull, 
		"Column3", 
		Splitter.SplitTextByEachDelimiter({")"}, QuoteStyle.Csv, false), 
		{"Column3.1", "Column3.2"}
	),
	ReplacedValue = Table.ReplaceValue(
		SplittedColumnByDelimiter, 
		"(", 
		"", 
		Replacer.ReplaceText, 
		{"Column3.1"}
	),
	SplittedColumnByWeeknumbers = Table.SplitColumn(
		ReplacedValue, 
		"Column3.2", 
		Splitter.SplitTextByAnyDelimiter(lstWeekNumbers, QuoteStyle.None, false), 
		{"Column3.2.1", "Column3.2.2"}
	),
	Custom1 = Table.ReplaceValue(
		SplittedColumnByWeeknumbers, 
		"Week", 
		"", 
		Replacer.ReplaceText, 
		{"Column3.2.1"}
	),
	ReplacedNullValues = Table.ReplaceValue(Custom1, null, "", Replacer.ReplaceValue, {"Column3.2.2"}),
	MergedColumns = Table.CombineColumns(
		ReplacedNullValues, 
		{"Column3.2.1", "Column3.2.2"}, 
		Combiner.CombineTextByDelimiter("", QuoteStyle.None), 
		"Праздники"
	),
	TrimmedText = Table.TransformColumns(MergedColumns, {{"Праздники", Text.Trim, type text}}),
	#"Replaced Errors" = Table.ReplaceErrorValues(TrimmedText, {{"Праздники", null}}),
	AddedYear = Table.AddColumn(#"Replaced Errors", "Year", each Text.From(lstYears{0})),
	RenamedColumns = Table.RenameColumns(
		AddedYear, 
		{
			{"Column1", "Day"}, 
			{"Column2", "Day_Short"}, 
			{"Column3.1", "Day_Year"}, 
			{"Праздники", "Holidays"}, 
			{"Year Month", "Month_Long"}
		}
	),
	ReorderedColumns = Table.ReorderColumns(
		RenamedColumns, 
		{"Day_Year", "Day", "Day_Short", "Month_Long", "Year", "Holidays"}
	),
	ChangedType = Table.TransformColumnTypes(
		ReorderedColumns, 
		{
			{"Day_Year", Int64.Type}, 
			{"Day", Int64.Type}, 
			{"Year", Int64.Type}, 
			{"Day_Short", type text}, 
			{"Month_Long", type text}, 
			{"Holidays", type text}
		}
	),
	RemovedDuplicates = Table.Distinct(ChangedType, {"Day_Year"})
in
	RemovedDuplicates