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