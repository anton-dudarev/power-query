let
  Source = {PRM_FirstYear .. Date.Year(DateTime.FixedLocalNow())}, 
  ConvertedtoTable = Table.FromList(
    Source, 
    Splitter.SplitByNothing(), 
    null, 
    null, 
    ExtraValues.Error
  ), 
  RenamedColumns = Table.RenameColumns(ConvertedtoTable, {{"Column1", "Year"}}), 
  InvokedCustomFunction = Table.AddColumn(
    RenamedColumns, 
    "fnGetDays", 
    each fnGetDays([Year])
  ), 
  ExpandedDates = Table.ExpandTableColumn(
    InvokedCustomFunction, 
    "fnGetDays", 
    {"Attribute:d.1", "Attribute:d.2", "Attribute:t", "Attribute:h", "Date"}, 
    {"Attribute:d.1", "Attribute:d.2", "Attribute:t", "Attribute:h", "Date"}
  ), 
  ChangedType = Table.TransformColumnTypes(
    ExpandedDates, 
    {
      {"Year", Int64.Type}, 
      {"Attribute:d.1", Int64.Type}, 
      {"Attribute:d.2", Int64.Type}, 
      {"Attribute:t", Int64.Type}, 
      {"Attribute:h", Int64.Type}, 
      {"Date", type date}
    }
  ), 
  MergedQueries = Table.NestedJoin(
    ChangedType, 
    {"Year", "Attribute:h"}, 
    SRC_Holidays, 
    {"Year", "Attribute:id"}, 
    "SRC_Holidays", 
    JoinKind.LeftOuter
  ), 
  ExpandedHolidays = Table.ExpandTableColumn(
    MergedQueries, 
    "SRC_Holidays", 
    {"Attribute:title"}, 
    {"Attribute:title"}
  ), 
  RemovedOtherColumns = Table.SelectColumns(ExpandedHolidays, {"Date", "Attribute:title"}), 
  RenamedColumns1 = Table.RenameColumns(
    RemovedOtherColumns, 
    {{"Attribute:title", "Holiday"}}
  ), 
  SortedRows = Table.Sort(RenamedColumns1, {{"Date", Order.Descending}}), 
  TableBuffer = Table.Buffer(Table.Distinct(SortedRows))
in
  TableBuffer
