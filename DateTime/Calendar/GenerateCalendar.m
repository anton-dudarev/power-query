let
  Source = #date(PRM_FirstYear, 1, 1),
  ListDatesFromStart = List.Dates(
    Source,
    Number.From(#date(PRM_LastYear, 12, 31)) - Number.From(Source),
    #duration(1, 0, 0, 0)
  ),
  ConvertedToTable = Table.FromList(
    ListDatesFromStart,
    Splitter.SplitByNothing(),
    null,
    null,
    ExtraValues.Ignore
  ),
  ChangedType = Table.TransformColumnTypes(ConvertedToTable, {{"Column1", type date}}),
  InsertedDayOfWeek = Table.AddColumn(
    Table.RenameColumns(ChangedType, {{"Column1", "Дата"}}),
    "Номер дня недели",
    each Date.DayOfWeek([Дата]),
    Int64.Type
  ),
  InsertedDayOfMonth = Table.AddColumn(
    InsertedDayOfWeek,
    "День месяца",
    each Date.Day([Дата]),
    Int64.Type
  ),
  InsertedDaysInMonth = Table.AddColumn(
    InsertedDayOfMonth,
    "Дней в месяце",
    each Date.DaysInMonth([Дата]),
    Int64.Type
  ),
  InsertedDayName = Table.AddColumn(
    Table.AddColumn(InsertedDaysInMonth, "День года", each Date.DayOfYear([Дата]), Int64.Type),
    "Название дня недели",
    each Date.DayOfWeekName([Дата]),
    type text
  ),
  CapitalizedDayName = Table.TransformColumns(
    InsertedDayName,
    {{"Название дня недели", Text.Proper, type text}}
  ),
  DaysShortName = {"пн", "вт", "ср", "чт", "пт", "сб", "вс"},
  AddedDayNameShort = Table.AddColumn(
    CapitalizedDayName,
    "День недели",
    each DaysShortName{[Номер дня недели]},
    type text
  ),
  InsertedMonth = Table.AddColumn(
    AddedDayNameShort,
    "Номер месяца",
    each Date.Month([Дата]),
    Int64.Type
  ),
  InsertedMonthName = Table.AddColumn(
    InsertedMonth,
    "Месяц",
    each Date.MonthName([Дата]),
    type text
  ),
  InsertedYear = Table.AddColumn(InsertedMonthName, "Год", each Date.Year([Дата]), Int64.Type),
  InsertedQuarter = Table.AddColumn(
    InsertedYear,
    "Номер квартала",
    each Date.QuarterOfYear([Дата]),
    Int64.Type
  ),
  QuarterName = {"Не присвоено", "Первый", "Второй", "Третий", "Четвертый"},
  AddedQuarterName = Table.AddColumn(
    InsertedQuarter,
    "Квартал",
    each QuarterName{[Номер квартала]},
    type text
  ),
  MergedQueryHolidays = Table.NestedJoin(
    InsertedQuarter,
    {"Дата"},
    Holidays,
    {"Date"},
    "SRC_RollingHolidays",
    JoinKind.LeftOuter
  ),
  ExpandedHolidays = Table.ExpandTableColumn(
    MergedQueryHolidays,
    "SRC_RollingHolidays",
    {"Holiday"},
    {"Праздник"}
  ),
  InsertedDayTypeID = Table.AddColumn(
    ExpandedHolidays,
    "Рабочий день ID",
    each if [Номер дня недели] <= 4 and [Праздник] = null then 1 else 0,
    Int64.Type
  ),
  InsertedDayType = Table.AddColumn(
    InsertedDayTypeID,
    "Рабочий день",
    each if [Рабочий день ID] = 1 then "Рабочий" else "Выходной",
    type text
  ),
  AddedWeekNumber = Table.AddColumn(
    InsertedDayType,
    "Номер недели",
    each fnDateToISOWeek([Дата]),
    Int64.Type
  ),
  AddedYYMM = Table.AddColumn(
    AddedWeekNumber,
    "YYMM",
    each ([Год] - 2000) * 100 + [Номер месяца],
    Int64.Type
  ),
  AddedDateID = Table.AddColumn(
    AddedYYMM,
    "Дата ID",
    each (Date.Year([Дата]) - Date.Year(Source)) * 12 + Date.Month([Дата]),
    Int64.Type
  ),
  SortedRows = Table.Sort(AddedDateID, {{"Дата", Order.Descending}}),
  RemovedDuplicates = Table.Distinct(SortedRows, {"Дата"}),
  ReorderedColumns = Table.ReorderColumns(
    RemovedDuplicates,
    {
      "Дата",
      "Номер недели",
      "Рабочий день",
      "Название дня недели",
      "День недели",
      "Месяц",
      "Год",
      "Номер месяца",
      "Номер дня недели",
      "День месяца",
      "Дней в месяце",
      "День года",
      "Номер квартала",
      "Рабочий день ID",
      "YYMM",
      "Дата ID",
      "Праздник"
    }
  )
in
  ReorderedColumns
