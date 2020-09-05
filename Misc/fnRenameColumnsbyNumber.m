// This function renames columns based on their position.
// The second and third argument are lists, each with the same number of elements.
// ColumnNumbers is 0-based, so the first column is 0.

let
  RenameColumns = (InputTable as table, ColumnNumbers as list, NewColumnNames as list) => 
    let
      OldColumnNames = Table.ColumnNames(InputTable),
      Indexed = List.Zip({OldColumnNames, {0..- 1 + List.Count(OldColumnNames)}}),
      Filtered = List.Select(Indexed, each List.Contains(ColumnNumbers, _{1})),
      IndexRemoved = List.Transform(Filtered, each _{0}),
      RenameList = List.Zip({IndexRemoved, NewColumnNames}),
      RenamedColumns = Table.RenameColumns(InputTable, RenameList)
    in
      RenamedColumns
in
  RenameColumns