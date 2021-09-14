let func =   
 (FileOrFolderPath as text) =>

let

CreateTable = if Text.End(FileOrFolderPath,5) = ".xlsx" or Text.End(FileOrFolderPath,5) = ".xlsm" 
then #table({"Content", "Name"}, {{File.Contents(FileOrFolderPath), FileOrFolderPath}}) 
else Folder.Files(FileOrFolderPath) ,
FetchQueries = Table.AddColumn(CreateTable, "FetchQueries", each try fnFetchQueries([Content]) otherwise #table({"Column1"}, {{null}})),
    #"Removed Other Columns" = Table.SelectColumns(FetchQueries,{"Name", "FetchQueries"}),
    #"Expanded FetchQueries" = Table.ExpandTableColumn(#"Removed Other Columns", "FetchQueries", {"Column1"}, {"QueryCode"}),

// Helper functions    

// Fetch queries from [Content]-column
fnFetchQueries = (Source as binary) =>
let 
    UnzipFile = fnUnzipFile(Source),
    // The filename where the queries reside is not known in beforehand. Just that it contains "customXml/item"
    FilterItemFiles = Table.SelectRows(UnzipFile, each Text.StartsWith([FileName], "customXml/item") and not Text.Contains([FileName], "Props")),
    FetchQueriesFromBinary = Table.AddColumn(FilterItemFiles, "fnGetQueriesFromBinary", each fnGetQueriesFromBinary([Content])),
    RemoveErrorRows = Table.RemoveRowsWithErrors(FetchQueriesFromBinary, {"fnGetQueriesFromBinary"}){0}[fnGetQueriesFromBinary]
in
    RemoveErrorRows,


// Extracts the queries from the binary
fnGetQueriesFromBinary = (GrabItem1 as binary) =>
let
    ParseAsXml = Xml.Tables(GrabItem1,null,1252),
    GrabText = ParseAsXml{0}[#"Element:Text"],
    BinaryFromText = Binary.FromText(GrabText, BinaryEncoding.Base64),
    UnzipSection1 = fnUnzipBinary(BinaryFromText, "Formulas/Section1.m"),
    TransformBinaryToList = Lines.FromBinary(UnzipSection1),
    ConvertToTable = Table.FromList(TransformBinaryToList, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
in
    ConvertToTable,

// Unzips the xlsx
fnUnzipFile = (ZIPFile) => 
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
                    BinaryFormat.Binary(26),      // Header payload – 14+4+4+2+2
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
    Table.FromRecords(Entries),

//Unzips the binary content
fnUnzipBinary = (binaryZip,fileName) =>
let
//shorthand
    UInt32 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32,ByteOrder.LittleEndian),
    UInt16 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16,ByteOrder.LittleEndian),
//ZIP file header fixed size structure
    Header = BinaryFormat.Record([
    MiscHeader = BinaryFormat.Binary(14),
                CompressedSize   = UInt32,
                UncompressedSize = UInt32,
                FileNameLen      = UInt16,
                ExtraFieldLen = UInt16]),
//ZIP file header dynamic size structure
    FileData = (h)=> BinaryFormat.Record([
                FileName         = BinaryFormat.Text(h[FileNameLen]),
                ExtraField       = BinaryFormat.Text(h[ExtraFieldLen]),
                UncompressedData = BinaryFormat.Transform(
    BinaryFormat.Binary(h[CompressedSize]),
    (x) =>  try 
    Binary.Buffer(Binary.Decompress(x, Compression.Deflate)) 
    otherwise null)]),
//Parsing the binary in search for PKZIP header signature
    ZipIterator = BinaryFormat.Choice(UInt32, (signature) => if signature <> 0x04034B50 
                                            then BinaryFormat.Record([FileName=null])
                                            else BinaryFormat.Choice(Header,(z)=>FileData(z))),
    ZipFormat = BinaryFormat.List(ZipIterator),
    out = List.Select(ZipFormat(binaryZip), each _[FileName]=fileName)
in
    out{0}[UncompressedData]

in
    #"Expanded FetchQueries" ,
documentation = [
Documentation.Name =  " Xlsx.ExtractQueries ",
Documentation.Description = " Extracts all queries from files in folder or xlsx-files ",
Documentation.LongDescription = " Extracts all queries from files in folder or xlsx-files ",
Documentation.Category = " Other ",
Documentation.Source = " www.TheBIccountant.com .  https://wp.me/p6lgsG-112 . ",
Documentation.Version = " 3.0 – extracts code from xlsm as well ",
Documentation.Author = " Imke Feldmann: www.TheBIccountant.com. https://wp.me/p6lgsG-112 . ",
Documentation.Examples = {[Description =  "  ",
Code = "  ",
Result = "  "]}]
  
 in  
  Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation))
