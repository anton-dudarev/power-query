let
  StartTime = #datetime(1900, 1, 1, 0, 0, 0),
  Increment = #duration(0, 0, 1, 0),
  Times = List.DateTimes(StartTime, 24 * 60, Increment),
  ConvertedToTable = Table.FromList(Times, Splitter.SplitByNothing()),
  RenamedColumns = Table.RenameColumns(ConvertedToTable, {{"Column1", "Время"}}),
  ChangedType = Table.TransformColumnTypes(RenamedColumns, {{"Время", type time}}),
  AddedHour = Table.AddColumn(
    ChangedType,
    "Час",
    each Text.PadStart(Text.From(Time.Hour([Время])), 2, "0"),
    type text
  ),
  AddedMinute = Table.AddColumn(
    AddedHour,
    "Минута",
    each Text.PadStart(Text.From(Time.Minute([Время])), 2, "0"),
    type text
  ),
  AddedHourMinute = Table.AddColumn(
    AddedMinute,
    "Час Минута",
    each [Час] & ":" & [Минута],
    type text
  ),
  AddedTimeIndex = Table.AddColumn(
    AddedHourMinute,
    "TimeIndex",
    each Time.Hour([Время]) * 60 + Time.Minute([Время]),
    Int64.Type
  ),
  RemovedDuplicates = Table.Distinct(AddedTimeIndex, {"TimeIndex"})
in
  RemovedDuplicates
