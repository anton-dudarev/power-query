(Url as text, Timeout as number, WorkBookTable as table) =>

let
    Source = Excel.CurrentWorkbook(){[Name=WorkBookTable]}[Content],
    IsUrlValid = Table.AddColumn(Source, "URL",
    each try Value.Metadata(Web.Contents(
      Url,
      [Timeout=#duration(0, 0, 0, Timeout),
      ManualStatusHandling={404}]
    ))),
    ExpandedMetadata = Table.ExpandRecordColumn(IsUrlValid, "Value",
      {"Content.Type", "Content.Uri", "Content.Name", "Headers", "Request.Options", "Response.Status"},
      {"Content.Type", "Content.Uri", "Content.Name", "Headers", "Request.Options", "Response.Status"}
    ),
    ExpandedMetadata2 = Table.ExpandRecordColumn(ExpandedMetadata, "Request.Options",
      {"Timeout", "ManualStatusHandling"},
      {"Timeout", "ManualStatusHandling"}
    ),
    RemovedColumns = Table.RemoveColumns(ExpandedMetadata2,
      {"Content.Type", "Content.Uri", "Content.Name", "Headers", "Timeout", "ManualStatusHandling"}
    ),
    ReplacedErrors = Table.ReplaceErrorValues(RemovedColumns, {{"Response.Status", 404}}),
    ChangedType = Table.TransformColumnTypes(ReplacedErrors,{{"Response.Status", type text}})
in
    ChangedType
