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
    "fngetHolidays", 
    each try fnGetHolidays([Year]) otherwise null
  ), 
  ExpandedHolidaysText = Table.ExpandTableColumn(
    InvokedCustomFunction, 
    "fngetHolidays", 
    {"Attribute:id", "Attribute:title"}, 
    {"Attribute:id", "Attribute:title"}
  ), 
  ChangedType = Table.TransformColumnTypes(
    ExpandedHolidaysText, 
    {{"Year", Int64.Type}, {"Attribute:id", Int64.Type}, {"Attribute:title", type text}}
  )
in
  ChangedType
