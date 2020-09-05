
(FolderPath as text) =>
let
  // text user-defined queries
  Files = Folder.Files(FolderPath), // Folder.Contents
  AddDecode = Table.AddColumn(Files, "Text", each Text.FromBinary([Content])),
  FilterCols = Table.SelectColumns(AddDecode, {"Name", "Text"}),
  TextCol = Table.Column(FilterCols, "Text"),
  TextMerged = Text.Combine(TextCol),
  TextCleaned = TextMerged,
  Return = TextCleaned
in
  Return