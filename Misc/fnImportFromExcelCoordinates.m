// https://www.thebiccountant.com/2017/08/18/how-to-import-from-excel-with-cell-coordinates-in-power-query-and-power-bi/

let func =  
 // fnImportExcelByCoordinates
// Author: Imke Feldmann - http://www.thebiccountant.com/ - Link to article: http://wp.me/p6lgsG-EI

let
    Source = (FullFilePath as text, SheetName as text, StartCell as text, optional EndCell as text) =>

let

// Start of function-record ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fn= [
 RowColIndex =

 // Returns the row- & column index of the Excel-cell-notation (like "A3")

(Coordinates as text) =>
let
    Source = Coordinates,
    NumbersAsText = List.Transform({0..9}, each Text.From(_)),
    TextToList = Text.ToList(Source),
    
    //Where is the first number?
    SplitPosition = List.PositionOfAny(TextToList, NumbersAsText),
    
    //Extract all letters and convert them to their number-value
    ListCol = List.Reverse(List.Transform(Text.ToList(Text.Range(Source,0,SplitPosition)), 
                                          each Character.ToNumber(_)-64)),
    
    //The position of the letter implies that a certain amount of columns lies to the left already: 
    //This is calculated here (Number.Power(26, Position) and zipped to match the number values from prev step
    ColIndex = List.Sum(List.Transform(List.Zip({List.Transform({0..List.Count(ListCol)-1}, each Number.Power(26,_)), 
                                                ListCol}), 
                                       each List.Product(_))),
    RowIndex = Number.FromText(Text.Range(Source,SplitPosition, Text.Length(Source)-SplitPosition)),
    Custom1 = [column=ColIndex, row=RowIndex]
in
    Custom1

 ,UnzipFile =
// Function comes from: http://sql10.blogspot.de/2016/06/reading-zip-files-in-powerquery-m.html

let
    Source = (ZIPFile) => 
let
    Header = BinaryFormat.Record([
        MiscHeader = BinaryFormat.Binary(14),
        BinarySize = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        FileSize   = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        FileNameLen= BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
        ExtrasLen  = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian)    
    ]),

    HeaderChoice = BinaryFormat.Choice(
        BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        each if _ <> 67324752             // not the IsValid number? then return a dummy formatter
            then BinaryFormat.Record([IsValid = false, Filename=null, Content=null])
            else BinaryFormat.Choice(
                    BinaryFormat.Binary(26),      // Header payload - 14+4+4+2+2
                    each BinaryFormat.Record([
                        IsValid  = true,
                        Filename = BinaryFormat.Text(Header(_)[FileNameLen]), 
                        Extras   = BinaryFormat.Text(Header(_)[ExtrasLen]), 
                        Content  = BinaryFormat.Transform(
                            BinaryFormat.Binary(Header(_)[BinarySize]),
                            (x) => try Binary.Buffer(Binary.Decompress(x, Compression.Deflate)) otherwise null
                        )
                        ]),
                        type binary                   // enable streaming
                )
    ),

    ZipFormat = BinaryFormat.List(HeaderChoice, each _[IsValid] = true),

    Entries = List.Transform(
        List.RemoveLastN( ZipFormat(ZIPFile), 1),
        (e) => [FileName = e[Filename], Content = e[Content] ]
    )
in
    Table.FromRecords(Entries)
in
    Source

 ,InternalExcelSheetName =
 
 // In the XML-files the sheets don't carry the names that are visible to the users, but indexed "sheet"
 // This function will lookup the internal sheet name from the visible one

(File, SheetName as text) =>
let
  //  Path = ..YourFilePath..,
  //  SheetName = "Sample4",
    Source = Excel.Workbook(File, null, true),
    #"Filtered Rows" = Table.SelectRows(Source, each ([Kind] = "Sheet")),
    #"Added Index" = Table.AddIndexColumn(#"Filtered Rows", "Index", 1, 1),
    #"Filtered Rows2" = Table.SelectRows(#"Added Index", each ([Name] = SheetName)),
    #"Merged Columns" = Table.CombineColumns(Table.TransformColumnTypes(#"Filtered Rows2", {{"Index", type text}}, "en-US"),{"Kind", "Index"},
                                            Combiner.CombineTextByDelimiter("", QuoteStyle.None),"SheetName"),
    Custom1 = Text.Lower(#"Merged Columns"[SheetName]{0})
in
    Custom1
 ],
 // End of function record ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff


/* Debug/Follow-Along parameters pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp
StartCell = "E3",
EndCell = "H9",
FullFilePath = ..YourFilePath..,
SheetName = "Sample1",
 pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp*/ 



    File = File.Contents(FullFilePath),
    InternalSheetName = fn[InternalExcelSheetName](File, SheetName),
    UnizpFile = fn[UnzipFile](File),
    FilterSheet = Table.SelectRows(UnizpFile, each [FileName] = "xl/worksheets/"&InternalSheetName&".xml"),
    XmlTables = Table.AddColumn(FilterSheet, "XmlTable", each Xml.Tables([Content])),
    Range = Table.AddColumn(XmlTables, "Range", each Table.SelectRows([XmlTable], each [Name]="dimension")[Table]{0}{0}[#"Attribute:ref"]),
    XmlTable = Table.SelectRows(Range{0}[XmlTable], each [Name]="sheetData")[Table]{0}[Table]{0},
    #"Expanded c" = Table.ExpandTableColumn(XmlTable, "c", {"Attribute:r", "v"}, {"Attribute:r.1", "v"}),
    FirstNonEmptyCell = List.First(List.Sort(Table.SelectRows(#"Expanded c", each ([v] <> null))[#"Attribute:r.1"])),
    RowColIndexFirstNonEmpty = fn[RowColIndex](FirstNonEmptyCell),
    RowColIndexFirstRange = fn[RowColIndex](Text.Split(Range[Range]{0}, ":"){0}),

    // Gap between the official "Range" (that is imported to PP or PBI) and the cell with the first value
    Offset = [column= RowColIndexFirstNonEmpty[column]- RowColIndexFirstRange[column], row= RowColIndexFirstNonEmpty[row]- RowColIndexFirstRange[row]],
    RowColIndexStartCell = fn[RowColIndex](StartCell),

    // The number of leading rows and columns to delete is the gap between the coordinates to the first non-empty-cell plus the Offset to cater for the empty cells
    DeleteFirstXColumns = RowColIndexStartCell[column]-RowColIndexFirstNonEmpty[column]+Offset[column],
    DeleteFirstXRows = RowColIndexStartCell[row]-RowColIndexFirstNonEmpty[row]+Offset[row],
    Workbook = Excel.Workbook(File),
    #"Filtered Rows" = Table.SelectRows(Workbook, each ([Kind] = "Sheet") and ([Name] = SheetName))[Data]{0},
    RemoveFirstRows = Table.Skip(#"Filtered Rows", DeleteFirstXRows),
    RemoveFirstColumns = Table.RemoveColumns(RemoveFirstRows, List.FirstN(Table.ColumnNames(RemoveFirstRows), DeleteFirstXColumns)),
    RowColIndexEndCell = fn[RowColIndex](EndCell),
    TableWidth = RowColIndexEndCell[column]-RowColIndexStartCell[column]+1,
    TableLength = RowColIndexEndCell[row]-RowColIndexStartCell[row]+1,
    Custom1 = RemoveFirstColumns,
    KeptFirstRows = Table.FirstN(Custom1,TableLength),

    // The parameter for the end of the range (EndCell) is opional, so otherwise the table with jsut deleted leading rows & colums will be taken
    KeptFirstColumns = try Table.SelectColumns(KeptFirstRows,List.FirstN(Table.ColumnNames(KeptFirstRows), TableWidth)) otherwise RemoveFirstColumns
in
    KeptFirstColumns

// Function documentation - ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
	
in
    Source
, documentation = [
Documentation.Name =  " fnExcel.WorksheetByCoordinates
", Documentation.Description = " Pass the coordinates in a worksheet as parameters for the import-range in Excel
" , Documentation.LongDescription = " Pass the coordinates in a worksheet as parameters for the import-range in Excel
", Documentation.Category = " Accessing data functions
", Documentation.Source = " local
", Documentation.Author = " Imke Feldmann: www.TheBIccountant.com
", Documentation.Examples = {[Description =  " 
" , Code = " Check this blogpost explaining how it works: http://wp.me/p6lgsG-EI
 ", Result = " 
"]}] 
 in 
  Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation)) 
