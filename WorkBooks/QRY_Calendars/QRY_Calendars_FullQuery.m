// fnGetCountryCalendar
(Country as text, Year1 as number, Year2 as nullable number) => 
  let
    Y2 = if Year2 = null then Year1 else Year2,
    Source = Table.FromColumns(
      {
        Lines.FromBinary(
          Web.Contents(
            "https://www.timeanddate.com/calendar/custom.html?mty=1&ctf=4&hol=9&typ=3&hod=7&holmark=1&display=2&cdt=1&wdf=3&mtm=2&cols=1&country="
              & Country
              & "&year="
              & Text.From(Year1)
              & "&y2="
            & Text.From(Y2)
          )
        )
      }
    ),
    #"Filtered Rows" = Table.SelectRows(Source, each Text.Contains([Column1], "<div id=calarea>")),
    CalAreaText = #"Filtered Rows"{0}[Column1],
    Custom1 = Text.PositionOf(CalAreaText, "<table "),
    Custom2 = Text.PositionOf(CalAreaText, "</table>", Occurrence.Last),
    TableAsText = Text.Range(CalAreaText, Custom1, Custom2 - Custom1 + 8),
    CalTableAsList = Text.Split(TableAsText, "<tr>"),
    #"Replaced Closing tr" = List.ReplaceValue(CalTableAsList, "</tr>", "", Replacer.ReplaceText),
    #"Converted to Table" = Table.FromList(
      #"Replaced Closing tr", 
      Splitter.SplitByNothing(), 
      null, 
      null, 
      ExtraValues.Error
    ),
    #"Filtered Target Rows" = Table.SelectRows(
      #"Converted to Table", 
      each Text.Contains([Column1], "<td class=cn") or Text.Contains([Column1], "<td class=""cn")
        or Text.Contains([Column1], "<th>")
    ),
    #"Added Headers" = Table.AddColumn(
      #"Filtered Target Rows", 
      "Titles", 
      each if Text.Contains([Column1], "<th>") then [Column1] else null
    ),
    #"Added Days rows" = Table.AddColumn(
      #"Added Headers", 
      "Day Rows", 
      each if not Text.Contains([Column1], "<th>") then [Column1] else null
    ),
    #"Added Working Days Ind" = Table.AddColumn(
      #"Added Days rows", 
      "Working Day", 
      each if Text.Contains([Column1], "cn minititle") then "N" else "Y"
    ),
    #"Added MM YYYY" = Table.AddColumn(
      #"Added Working Days Ind", 
      "MM YYYY", 
      each try Text.Range([Titles], Text.PositionOf([Titles], """>") + 2, 7) otherwise null
    ),
    #"Added Days Dirty" = Table.AddColumn(
      #"Added MM YYYY", 
      "Days Dirty", 
      each if [Day Rows] <> null then Text.Range(
        [Day Rows], 
        Text.PositionOf([Day Rows], ">") + 1, 
        2
      ) else null
    ),
    #"Clean Days Dirty" = Table.ReplaceValue(
      #"Added Days Dirty", 
      "<", 
      "", 
      Replacer.ReplaceText, 
      {"Days Dirty"}
    ),
    #"Filled Down MM YYYY" = Table.FillDown(#"Clean Days Dirty", {"MM YYYY"}),
    #"Removed Other Columns" = Table.SelectColumns(
      #"Filled Down MM YYYY", 
      {"Working Day", "MM YYYY", "Days Dirty"}
    ),
    #"Filtered nulls" = Table.SelectRows(#"Removed Other Columns", each ([Days Dirty] <> null)),
    #"Convert to Date" = Table.AddColumn(
      #"Filtered nulls", 
      "Date", 
      each #date(
        Number.From(Text.End([MM YYYY], 4)), 
        Number.From(Text.Start([MM YYYY], 2)), 
        Number.From([Days Dirty])
      )
    ),
    #"Removed Other Columns1" = Table.SelectColumns(#"Convert to Date", {"Date", "Working Day"}),
    #"Added Country" = Table.AddColumn(#"Removed Other Columns1", "Country", each Country),
    #"Reordered Columns" = Table.ReorderColumns(
      #"Added Country", 
      {"Country", "Date", "Working Day"}
    ),
    #"Changed Type" = Table.TransformColumnTypes(
      #"Reordered Columns", 
      {{"Date", type date}, {"Working Day", type text}, {"Country", type text}}
    ),
    #"Sorted Rows" = Table.Sort(#"Changed Type", {{"Date", Order.Ascending}})
  in
    #"Sorted Rows"

// lstWeekNumbers
let
  Source = {0..54},
    ConvertedToTable = Table.FromList(
    Source,
    Splitter.SplitByNothing(),
    null,
    null,
    ExtraValues.Error
  ),
TableToList = Table.ToList(Table.TransformColumnTypes(ConvertedToTable, {{"Column1", type text}}))
in
TableToList

// fnGetHolidays
(Year as text) => 
  let
    Source = Web.Page(
      Web.Contents(
        "https://www.timeanddate.com/calendar/custom.html?year=" & Text.From(Year)
        & "&month=1&months=12&country=20&typ=2&display=2&cols=1&lang=ru&fdow=1&wno=1&hol=25166137&hcl=2&cdt=32&holm=1&doy=1&df=1"
      )
    ),
    Data = Source{0}[Data],
    DemotedHeaders = Table.AddColumn(
      Table.DemoteHeaders(Data), 
      "Custom", 
      each if Value.Is([Column1], type table) then [Column1] else null
    ),
    AddedYearMonth = Table.AddColumn(
      DemotedHeaders, 
      "Year Month", 
      each if Value.Is([Column1], type table) then null else [Column1]
    ),
    RemovedColumn1 = Table.RemoveColumns(AddedYearMonth, {"Column1"}),
    ExpandTableColumn = Table.ExpandTableColumn(
      Table.FillDown(RemovedColumn1, {"Year Month"}), 
      "Custom", 
      {"Column1", "Column2", "Column3"}, 
      {"Column1", "Column2", "Column3"}
    ),
    FilterColumn1NotNull = Table.SelectRows(ExpandTableColumn, each ([Column1] <> null)),
    SplittedColumnByDelimiter = Table.SplitColumn(
      FilterColumn1NotNull, 
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
    ReplacedNullValues = Table.ReplaceValue(
      Custom1, 
      null, 
      "", 
      Replacer.ReplaceValue, 
      {"Column3.2.2"}
    ),
    MergedColumns = Table.CombineColumns(
      ReplacedNullValues, 
      {"Column3.2.1", "Column3.2.2"}, 
      Combiner.CombineTextByDelimiter("", QuoteStyle.None), 
      "Праздники"
    ),
    TrimmedText = Table.TransformColumns(MergedColumns, {{"Праздники", Text.Trim, type text}}),
    ReplacedErrors = Table.ReplaceErrorValues(TrimmedText, {{"Праздники", null}}),
    AddedYear = Table.AddColumn(ReplacedErrors, "Year", each Year),
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

// lstYears
let
    Source = {2018..2022}
in
    Source

// CAL_TimeAndDate_GetHolidays_01
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
  AddedYear = Table.AddColumn(#"Replaced Errors", "Year", each Text.From(2020)),
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

// CAL_TimeAndDate_GetHolidays_02
let
  Source = Web.Page(
    Web.Contents(
      "https://www.timeanddate.com/calendar/custom.html?year=" & Text.From(lstYears{1})
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
  AddedYear = Table.AddColumn(#"Replaced Errors", "Year", each Text.From(2020)),
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

// CAL_TimeAndDate_GetHolidays_03
let
  Source = Web.Page(
    Web.Contents(
      "https://www.timeanddate.com/calendar/custom.html?year=" & Text.From(lstYears{2})
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
  AddedYear = Table.AddColumn(#"Replaced Errors", "Year", each Text.From(2020)),
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

// CAL_TimeAndDate_GetHolidays_04
let
  Source = Web.Page(
    Web.Contents(
      "https://www.timeanddate.com/calendar/custom.html?year=" & Text.From(lstYears{3})
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
  AddedYear = Table.AddColumn(#"Replaced Errors", "Year", each Text.From(2020)),
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

// CAL_Generated_Staging
let
	Source = #date(lstYears{0}, 1, 1),
	ListDatesFromStart = List.Dates(
		Source, 
		Number.From(#date(lstYears{3}, 12, 31)) - Number.From(Source), 
		#duration(1, 0, 0, 0)
	),
	ConvertedToTable = Table.FromList(
		ListDatesFromStart, 
		Splitter.SplitByNothing(), 
		null, 
		null, 
		ExtraValues.Ignore
	),
	SortedRows = Table.Sort(ConvertedToTable, {{"Column1", Order.Descending}}),
	InsertedDayOfWeek = Table.AddColumn(
		Table.RenameColumns(SortedRows, {{"Column1", "Дата"}}), 
		"День недели", 
		each Date.DayOfWeek([Дата]), 
		Int64.Type
	),
	InsertedDayOfMonth = Table.AddColumn(InsertedDayOfWeek, "День_Месяца", each Date.Day([Дата])),
	InsertedDaysInMonth = Table.AddColumn(
		InsertedDayOfMonth, 
		"Дней в месяце", 
		each Date.DaysInMonth([Дата]), 
		Int64.Type
	),
	InsertedDayName = Table.AddColumn(
		Table.AddColumn(InsertedDaysInMonth, "День года", each Date.DayOfYear([Дата]), Int64.Type), 
		"Название дня", 
		each Date.DayOfWeekName([Дата]), 
		type text
	),
	InsertedWeekOfYear = Table.AddColumn(
		InsertedDayName, 
		"Неделя года", 
		each Date.WeekOfYear([Дата]), 
		Int64.Type
	),
	InsertedMonth = Table.AddColumn(InsertedWeekOfYear, "Месяц", each Date.Month([Дата]), Int64.Type),
	InsertedMonthName = Table.AddColumn(
		InsertedMonth, 
		"Название месяца", 
		each Date.MonthName([Дата]), 
		type text
	),
	InsertedYear = Table.AddColumn(InsertedMonthName, "Год", each Date.Year([Дата]), Int64.Type),
	RenamedColumns = Table.RenameColumns(
		InsertedYear, 
		{
			{"Название дня", "Day_Fullname"}, 
			{"Неделя года", "Week"}, 
			{"День недели", "Day_Week"}, 
			{"Месяц", "Month"}, 
			{"Название месяца", "Month_Fullname"}, 
			{"Дней в месяце", "Days_in_Month"}, 
			{"Дата", "Date"}, 
			{"День_Месяца", "Day"}, 
			{"Год", "Year"}, 
			{"День года", "Day_Year"}
		}
	),
	RequestIsWeekend = Table.AddColumn(
		RenamedColumns, 
		"isWeekend", 
		each Json.Document(
			Web.Contents(
				"https://isdayoff.ru/" & Text.From([Year]) & Text.PadStart(Text.From([Month]), 2, "0")
					& Text.PadStart(Text.From([Day]), 2, "0")
				& "?cc=ru"
			)
		)
	),
	ReorderedColumns = Table.ReorderColumns(
		RequestIsWeekend, 
		{
			"Date", 
			"Week", 
			"isWeekend", 
			"Day", 
			"Day_Week", 
			"Days_in_Month", 
			"Day_Fullname", 
			"Month", 
			"Month_Fullname", 
			"Year"
		}
	),
	RenamedColumns2 = Table.RenameColumns(
		ReorderedColumns, 
		{{"Day_Fullname", "Day_Long"}, {"Month_Fullname", "Month_Long"}}
	),
	AddedMonthShortName = Table.AddColumn(
		RenamedColumns2, 
		"Month_Short", 
		each Text.Start([Month_Long], 3)
	),
	ChangedType = Table.TransformColumnTypes(AddedMonthShortName,{{"Date", type date}, {"Week", Int64.Type}, {"isWeekend", Int64.Type}, {"Day", Int64.Type}, {"Day_Year", Int64.Type}, {"Day_Week", Int64.Type}, {"Days_in_Month", Int64.Type}, {"Month", Int64.Type}, {"Year", Int64.Type}, {"Month_Short", type text}, {"Month_Long", type text}, {"Day_Long", type text}}),
	UppercasedMonth = Table.TransformColumns(ChangedType, {{"Month_Short", Text.Upper, type text}}),
	RemovedDuplicatesAndBuffer = Table.Buffer(Table.Distinct(UppercasedMonth, {"Date"}))
in
    RemovedDuplicatesAndBuffer

// CAL_AccumulatedHolidays
let
  Source = Table.Combine(
    {
      fnGetHolidays(Text.From(lstYears{0})), 
      fnGetHolidays(Text.From(lstYears{1})), 
      fnGetHolidays(Text.From(lstYears{2})), 
      fnGetHolidays(Text.From(lstYears{3}))
    }
  ),
  FixedCOVIDValue = Table.ReplaceValue(
    Source, 
    "COVID-", 
    "COVID-19", 
    Replacer.ReplaceText, 
    {"Holidays"}
  ),
  SortedRows = Table.Sort(
    FixedCOVIDValue, 
    {{"Year", Order.Descending}, {"Day_Year", Order.Descending}}
  ),
    TableBuffer = Table.Buffer(SortedRows)
in
  TableBuffer

// pSetWorkSheetYear
2020 meta [IsParameterQuery=true, Type="Number", IsParameterQueryRequired=true]

// CAL_RollingCalendar_Staging
let
  Source = #date(pSetWorkSheetYear, 1, 1),
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

// Shared
let
  Source = Table.Sort(Record.ToTable(#shared), {{"Name", Order.Ascending}}),
  Categorized = Table.AddColumn(
    Source, 
    "Status", 
    each if Record.HasFields(#sections[Section1], [Name]) then "User defined" else "Built in"
  ),
  // Annoying I need to filter out user defined stuff, but this resolves a cyclic reference caused if both F and this refer to all custom functions (which includes each other)
  Filtered = Table.SelectRows(Categorized, each [Status] = "Built in"),
  AddType = Table.AddColumn(Filtered, "Type", each Value_TypeToText([Value])),
  AddTypeRec = Table.AddColumn(AddType, "TypeRecurs", each Value_TypeToText([Value], true)),
  AddCat = Table.AddColumn(AddTypeRec, "Category", each 
    let
      cut = Text.Split(Text.Replace([Name], "_", "."), ".")
    in
      (try if List.Contains({"Database", "Type"}, cut{1}) then cut{1} else cut{0} otherwise "Custom")),
  Return = AddCat
in
  Return

// fnCheckDuplicates
(TableName as table, ColumnName as text) =>

let
    ListValues = Table.Column(TableName, ColumnName),
    CountValues = List.NonNullCount(ListValues),
    CountDistinctValues = List.NonNullCount(List.Distinct(ListValues)),
    CheckDuplicatesResult = if CountValues <> CountDistinctValues
    then false
    else true

in
    CheckDuplicatesResult

// pFolderPath
"c:\Users\anoub\OneDrive\Armtek\" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// DIR_GTP_Emp
let
    Source = Excel.Workbook(File.Contents(pFolderPath & "ENV.xlsx"), null, true),
    DIR_GTP_Emp_Table = Source{[Item="DIR_GTP_Emp",Kind="Table"]}[Data],
    #"Removed Other Columns" = Table.SelectColumns(DIR_GTP_Emp_Table,{"ECC_ID", "CRM_ID", "GTP_Dept_ID", "ECC_Name", "Lastname", "Firstname", "Patronymic", "Login_Citrix"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Other Columns",{{"ECC_ID", type text}, {"CRM_ID", type text}, {"GTP_Dept_ID", type text}, {"ECC_Name", type text}, {"Lastname", type text}, {"Firstname", type text}, {"Patronymic", type text}, {"Login_Citrix", type text}})
in
    #"Changed Type"

// CAL_GetHolidays_2018
let
    Source = fnGetHolidays(Text.From(lstYears{0}))
in
    Source

// Example
let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i45WMjDUAyIjA0NzJR0lY0M9QyMYJz8vOVUpVgefktz8vJKMnEoCqgpLE4tKUotA6mIB", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type text) meta [Serialized.Text = true]) in type table [period_start = _t, period_end = _t, schedule = _t]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"period_start", type date}, {"period_end", type date}, {"schedule", type text}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type", "ListOfDates", each List.Transform({Number.From([period_start])..Number.From([period_end])}, each Date.From(_))),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "ListOfNewRows", each if [schedule]="once" then {[period_start]} else if [schedule]="monthly" then List.Distinct(List.Transform([ListOfDates], each Date.StartOfMonth(_))) else List.Distinct(List.Transform([ListOfDates], each Date.StartOfQuarter(_)))),
    #"Expanded ListOfNewRows" = Table.ExpandListColumn(#"Added Custom1", "ListOfNewRows")
in
    #"Expanded ListOfNewRows"

// CAL_GetHolidays_2019
let
    Source = fnGetHolidays(Text.From(lstYears{1}))
in
    Source

// CAL_GetHolidays_2020
let
    Source = fnGetHolidays(Text.From(lstYears{2}))
in
    Source

// CAL_GetHolidays_2021
let
    Source = fnGetHolidays(Text.From(lstYears{3}))
in
    Source

// CAL_RollingCalendar
let
  Source = CAL_RollingCalendar_Staging,
  MergedQueries = Table.NestedJoin(Source, {"Date"}, CAL_WorkSheet, {"Date"}, "CAL_WorkSheet", JoinKind.LeftOuter),
  ExpandedWorkSheet = Table.ExpandTableColumn(MergedQueries, "CAL_WorkSheet", {"Week", "Day", "Day_Year", "Day_Week", "is_WorkDay", "Days_in_Month", "WorkDays_in_Month", "WeekDays_in_Month", "Day_Short", "Day_Long", "Month", "Month_Short", "Month_Long", "Year", "Holidays"}, {"Week", "Day", "Day_Year", "Day_Week", "is_WorkDay", "Days_in_Month", "WorkDays_in_Month", "WeekDays_in_Month", "Day_Short", "Day_Long", "Month", "Month_Short", "Month_Long", "Year", "Holidays"})
in
  ExpandedWorkSheet

// CAL_WorkSheet
let
  Source = CAL_Generated_Staging,
  MergedQueries = Table.NestedJoin(
    Source, 
    {"Day_Year", "Year"}, 
    CAL_AccumulatedHolidays, 
    {"Day_Year", "Year"}, 
    "CAL_AccumulateHolidays", 
    JoinKind.LeftOuter
  ),
  ExpandedHolidays = Table.ExpandTableColumn(
    MergedQueries, 
    "CAL_AccumulateHolidays", 
    {"Day_Short", "Holidays"}, 
    {"Day_Short", "Holidays"}
  ),
  SwapedWorkDayValue = Table.AddColumn(
    ExpandedHolidays, 
    "is_WorkDay", 
    each if [isWeekend] = 0 then 1 else 0
  ),
  RemovedColumns = Table.RemoveColumns(SwapedWorkDayValue, {"isWeekend"}),
  GroupedRows = Table.Group(
    RemovedColumns, 
    {"Year", "Month"}, 
    {
      {"WorkDays_in_Month", each List.Sum([is_WorkDay]), type number}, 
      {
        "Grouped", 
        each _, 
        type table[
          Date = date, 
          Week = number, 
          is_WorkDay = number, 
          Day = number, 
          Day_Year = number, 
          Day_Week = number, 
          Days_in_Month = number, 
          Day_Short = text, 
          Day_Long = text, 
          Month = number, 
          Month_Short = text, 
          Month_Long = text, 
          Year = number, 
          Holidays = text
        ]
      }
    }
  ),
  ExpandedRows = Table.ExpandTableColumn(
    GroupedRows, 
    "Grouped", 
    {
      "Date", 
      "Week", 
      "is_WorkDay", 
      "Day", 
      "Day_Year", 
      "Day_Week", 
      "Days_in_Month", 
      "Day_Short", 
      "Day_Long", 
      "Month_Short", 
      "Month_Long", 
      "Holidays"
    }, 
    {
      "Date", 
      "Week", 
      "is_WorkDay", 
      "Day", 
      "Day_Year", 
      "Day_Week", 
      "Days_in_Month", 
      "Day_Short", 
      "Day_Long", 
      "Month_Short", 
      "Month_Long", 
      "Holidays"
    }
  ),
  AddedWeekDaysColumn = Table.AddColumn(
    ExpandedRows, 
    "WeekDays_in_Month", 
    each [Days_in_Month] - [WorkDays_in_Month]
  ),
  ReorderedColumns = Table.ReorderColumns(
    AddedWeekDaysColumn, 
    {
      "Date", 
      "Week", 
      "Day", 
      "Day_Year", 
      "Day_Week", 
      "is_WorkDay", 
      "Days_in_Month", 
      "WorkDays_in_Month", 
      "WeekDays_in_Month", 
      "Day_Short", 
      "Day_Long", 
      "Month", 
      "Month_Short", 
      "Month_Long", 
      "Year", 
      "Holidays"
    }
  ),
  ChangedType = Table.TransformColumnTypes(
    ReorderedColumns, 
    {
      {"Days_in_Month", Int64.Type}, 
      {"WorkDays_in_Month", Int64.Type}, 
      {"WeekDays_in_Month", Int64.Type}, 
      {"Week", Int64.Type}, 
      {"is_WorkDay", type logical}, 
      {"Day", Int64.Type}, 
      {"Day_Year", Int64.Type}, 
      {"Day_Week", Int64.Type}, 
      {"Month", Int64.Type}, 
      {"Year", Int64.Type}
    }
  ),
  SortedAndRemovedDuplicates = Table.Distinct(
    Table.Sort(ChangedType, {{"Date", Order.Descending}}), 
    {"Date"}
  )
in
  SortedAndRemovedDuplicates

// vDateToday
let
    Source = Date.From(DateTime.FixedLocalNow())
in
    Source

// vLastRefresh
let
    Source = #table(type table[LastRefresh=datetime], {{DateTime.FixedLocalNow()}})
in
    Source

// fnLastNDays
(DaysNumber as number) => 
  let
    Source = List.Dates(Date.AddDays(vDateToday, - DaysNumber), DaysNumber, #duration(1, 0, 0, 0)),
    SortedItems = List.Sort(Source, Order.Descending)
  in
    SortedItems

// CWB_WorkSheet
let
  Source = Excel.CurrentWorkbook(){[Name = "CWB_WorkSheet"]}[Content],
  RemovedOtherColumns = Table.SelectColumns(Source, {"Сотрудник", "Начало", "Конец", "Примечание"}),
  AddedIndex = Table.AddIndexColumn(RemovedOtherColumns, "Index", 0, 1),
  ChangedType = Table.TransformColumnTypes(
    AddedIndex, 
    {
      {"Сотрудник", type text}, 
      {"Примечание", type text}, 
      {"Начало", type date},
      {"Конец", type date},
      {"Index", Int64.Type}
    }
  )
in
    ChangedType

// CAL_WorkDays
let
  Source = CAL_Generated_Staging,
  MergedQueries = Table.NestedJoin(
    Source, 
    {"Day_Year", "Year"}, 
    CAL_AccumulatedHolidays, 
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
  AddedCustom = Table.AddColumn(
    ExpandedHolidays, 
    "isWorkDay", 
    each if [isWeekend] = 0 then 1 else 0
  ),
  RemovedColumns = Table.RemoveColumns(
    AddedCustom, 
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
    ExpandedGroup = Table.ExpandTableColumn(GroupedRows, "Grouped", {"Date", "Holidays"}, {"Date", "Holidays"}),
  ChangedType1 = Table.TransformColumnTypes(ExpandedGroup, {{"WorkDays", Int64.Type}}),
  AddedWeekEndsColumn = Table.AddColumn(
    ChangedType1, 
    "WeekEnds", 
    each [Days_in_Month] - [WorkDays]
  ),
  ChangedType2 = Table.TransformColumnTypes(AddedWeekEndsColumn, {{"WeekEnds", Int64.Type}}),
    ReorderedColumns = Table.ReorderColumns(ChangedType2,{"Date", "Year", "Month_Long", "Days_in_Month", "WorkDays", "WeekEnds", "Holidays"}),
    SortedAndRemovedDuplicates = Table.Distinct(Table.Sort(ReorderedColumns,{{"Date", Order.Descending}}), {"Date"})
in
    SortedAndRemovedDuplicates