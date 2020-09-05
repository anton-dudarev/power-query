let
  Source = Lines.FromBinary(Web.Contents("http://www.ifias.ru/region.html")),
  ConvertedBinaryToTable = Table.FromList(
      Source, 
      Splitter.SplitByNothing(), 
      null, 
      null, 
      ExtraValues.Error
    ),
  FilteredRows = Table.SelectRows(
      ConvertedBinaryToTable, 
      each Text.Contains([Column1], "http")
    ),
    FilteredRows2  = Table.SelectRows(
      FilteredRows, 
      each Text.Contains([Column1], "<tr><td>")
    ),
  Column1 = FilteredRows2{0}[Column1],
  SplittedText = Text.Split(Column1, "<tr><td>"),
  ConvertedListToTable = Table.FromList(
      SplittedText, 
      Splitter.SplitByNothing(), 
      null, 
      null, 
      ExtraValues.Ignore
    ),
  ChangedType = Table.TransformColumnTypes(
      ConvertedListToTable, 
      {{"Column1", type text}}
    ),
  SplittedColumnsByDelimiter = Table.SplitColumn(
      ChangedType, 
      "Column1", 
      Splitter.SplitTextByDelimiter("""", QuoteStyle.None), 
      {"Column1.1", "Column1.2", "Column1.3", "Column1.4", "Column1.5"}
    ),
  ChangedType2 = Table.TransformColumnTypes(
      SplittedColumnsByDelimiter, 
      {
        {"Column1.1", type text}, 
        {"Column1.2", type text}, 
        {"Column1.3", type text}, 
        {"Column1.4", type text}, 
        {"Column1.5", type text}
      }
    ),
  FilteredRows3 = Table.SelectRows(ChangedType2, each ([Column1.5] <> null)),
  RemovedColumns = Table.RemoveColumns(
      FilteredRows3, 
      {"Column1.3", "Column1.4"}
    ),
  ReorderedColumns = Table.ReorderColumns(
      RemovedColumns, 
      {"Column1.1", "Column1.5", "Column1.2"}
    ),
  RefinedRegionsId = Table.AddColumn(
      ReorderedColumns, 
      "Код_Регион", 
      each Text.BetweenDelimiters([Column1.1], ">", "<")
    ),
  RefinedRegionsId2 = Table.AddColumn(
      RefinedRegionsId, 
      "Регион", 
      each Text.BetweenDelimiters([Column1.5], ">", "<")
    ),
  RemovedColumns2 = Table.RemoveColumns(RefinedRegionsId2, {"Column1.1", "Column1.5"}),
  ReorderedColumns2 = Table.ReorderColumns(
      RemovedColumns2, 
      {"Код_Регион", "Регион", "Column1.2"}
    ),
  RenamedColumns = Table.RenameColumns(
      ReorderedColumns2, 
      {{"Column1.2", "Url"}}
    ),
  ChangedType3 = Table.TransformColumnTypes(
      RenamedColumns, 
      {{"Код_Регион", type text}, {"Регион", type text}, {"Url", type text}}
    )
in
  ChangedType3
