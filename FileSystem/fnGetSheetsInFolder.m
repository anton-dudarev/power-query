/* //Create a table with info on all sheets in any Excel files in a particular folder.
//Usage: Files.SheetsInFolder = Load("Files.SheetsInFolder"), Source = Files.SheetsInFolder("C:\path\to\my\folder\")
//Result: [a table containing the binary file content, file names, sheet tables, and sheet names for each sheet in each spreadsheet in the given folder] */ 

(FolderPath as text) as table => 
  let
    Source = Folder.Files(FolderPath),
    FilteredRows = Table.SelectRows(Source, each Text.Start([Extension], 3) = ".xl"),
    RemovedOtherColumns = Table.SelectColumns(FilteredRows, {"Content", "Name"}),
    NoTemps = Table.SelectRows(RemovedOtherColumns, each not Text.StartsWith([Name], "~$")),
    InsertedCustom = Table.AddColumn(NoTemps, "Sheets", each Excel.Workbook([Content])),
    Expanded = Table.ExpandTableColumn(InsertedCustom, "Sheets", {"Data", "Name"}, {"D", "N"}),
    NoPrintAreas = Table.SelectRows(Expanded, each not Text.Contains([N], "$"))
  in
    NoPrintAreas