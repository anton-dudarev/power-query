let
	Source = CAL_Generated_Staging,
	MergedQueries = Table.NestedJoin(
		Source, 
		{"Day_Year", "Year"}, 
		CAL_AccumulateHolidays, 
		{"Day_Year", "Year"}, 
		"CAL_AccumulateHolidays", 
		JoinKind.LeftOuter
	),
	ExpandedHolidays = Table.ExpandTableColumn(
		MergedQueries, 
		"CAL_AccumulateHolidays", 
		{"Holidays"}, 
		{"Holidays"}
	),
	RevertWorkDaysValues = Table.AddColumn(
		ExpandedHolidays, 
		"isWorkDay", 
		each if [isWeekend] = 0 then 1 else 0
	),
	RemovedColumns = Table.RemoveColumns(
		RevertWorkDaysValues, 
		{"Day_Year", "Day_Long", "Month_Short", "isWeekend", "Week"}
	),
	ChangedType = Table.TransformColumnTypes(RemovedColumns, {{"isWorkDay", Int64.Type}}),
	GroupedRows = Table.Group(
		ChangedType, 
		{"Year", "Month_Long", "Days_in_Month"}, 
		{
			{"WorkDays", each List.Sum([isWorkDay]), type number}, 
			{"Grouped", each _, type table[Date = date, Holidays = text]}
		}
	),
	ExpandedGroup = Table.ExpandTableColumn(
		GroupedRows, 
		"Grouped", 
		{"Date", "Holidays"}, 
		{"Date", "Holidays"}
	),
	ChangedType1 = Table.TransformColumnTypes(ExpandedGroup, {{"WorkDays", Int64.Type}}),
	AddedWeekEndsColumn = Table.AddColumn(ChangedType1, "WeekEnds", each [Days_in_Month] - [WorkDays]),
	ChangedType2 = Table.TransformColumnTypes(AddedWeekEndsColumn, {{"WeekEnds", Int64.Type}}),
	ReorderedColumns = Table.ReorderColumns(
		ChangedType2, 
		{"Date", "Year", "Month_Long", "Days_in_Month", "WorkDays", "WeekEnds", "Holidays"}
	),
	SortedAndRemovedDuplicates = Table.Distinct(
		Table.Sort(ReorderedColumns, {{"Date", Order.Descending}}), 
		{"Date"}
	)
in
	SortedAndRemovedDuplicates