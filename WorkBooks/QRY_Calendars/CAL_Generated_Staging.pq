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
  ChangedType = Table.TransformColumnTypes(
    AddedMonthShortName, 
    {
      {"Date", type date}, 
      {"Week", Int64.Type}, 
      {"isWeekend", Int64.Type}, 
      {"Day", Int64.Type}, 
      {"Day_Year", Int64.Type}, 
      {"Day_Week", Int64.Type}, 
      {"Days_in_Month", Int64.Type}, 
      {"Month", Int64.Type}, 
      {"Year", Int64.Type}, 
      {"Month_Short", type text}, 
      {"Month_Long", type text}, 
      {"Day_Long", type text}
    }
  ),
  UppercasedMonth = Table.TransformColumns(ChangedType, {{"Month_Short", Text.Upper, type text}}),
  RemovedDuplicatesAndBuffer = Table.Buffer(Table.Distinct(UppercasedMonth, {"Date"}))
in
  RemovedDuplicatesAndBuffer