// https://www.thebiccountant.com/2016/12/06/how-to-store-tables-longer-than-11-mio-rows-in-excel/

(Input) =>
let

// Debug function
// Source = LongTable,

   Source = Input,
   JSON = Json.FromValue(Source),
   Compress = Binary.Compress(JSON, Compression.Deflate),
   ToText = Binary.ToText(Compress),
   TextLength = Text.Length(ToText),
   ChunkUp = {0..Number.RoundUp(TextLength/30000)-1},
   ConvertToTable = Table.FromList(ChunkUp, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
   StartPosition = Table.AddColumn(ConvertToTable, "Start", each [Column1]*30000),
   Elements = Table.AddColumn(StartPosition , "Custom", each Text.Range(ToText , [Column1]*30000, List.Min({TextLength-[Column1]*30000,30000})))
in
   Elements 
   
   let
    Source = (LinkbackTable) =>

let
// Debug function
// LinkbackTable= LinkbackTable,

    Source = Excel.CurrentWorkbook(){[Name=LinkbackTable]}[Content],
    CombineText = Text.Combine(Source[Custom], ""),
    ConvertToBinary = Binary.FromText(CombineText),
    CompressBinary = Binary.Decompress(ConvertToBinary, Compression.Deflate),
    OpenJSON = Json.Document(CompressBinary),
    ConvertToTable = Table.FromList(OpenJSON, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    ExpandAllColumns = Table.ExpandRecordColumn(ConvertToTable, "Column1", Record.FieldNames(ConvertToTable[Column1]{0}), Record.FieldNames(ConvertToTable[Column1]{0}))
in
    ExpandAllColumns
in
    Source
