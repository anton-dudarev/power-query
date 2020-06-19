let
	Source = Excel.CurrentWorkbook(){[Name = "CWB_WorkSheet"]}[Content],
	RemovedOtherColumns = Table.SelectColumns(Source, {"Сотрудник", "Дата", "Комментарий"}),
	AddedIndex = Table.AddIndexColumn(RemovedOtherColumns, "Index", 0, 1),
	ChangedType = Table.TransformColumnTypes(
		AddedIndex, 
		{
			{"Сотрудник", type text}, 
			{"Комментарий", type text}, 
			{"Дата", type date}, 
			{"Index", Int64.Type}
		}
	),
	ReorderedColumns = Table.ReorderColumns(ChangedType, {"Дата", "Сотрудник", "Комментарий"}),
	RenamedColumns = Table.RenameColumns(
		ReorderedColumns, 
		{{"Дата", "Date"}, {"Сотрудник", "ECC_Name"}, {"Комментарий", "Description"}}
	),
	SortedRows = Table.Sort(RenamedColumns, {{"Date", Order.Descending}})
in
	SortedRows