let
  Source = Excel.CurrentWorkbook(){[Name = "CWB_WorkSheet"]}[Content],
  RemovedOtherColumns = Table.SelectColumns(Source, {"Сотрудник", "Начало", "Конец", "Примечание"}),
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