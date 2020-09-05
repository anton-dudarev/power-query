let
	Source = Table.FromRows(
		Json.Document(
			Binary.Decompress(
				Binary.FromText("VYxBCoAwDAS/EnLORX1O6SHFUITahkgRf2/UXiSXze4wIeCEhKxa5AA2AZOVIHH1+4pLSmknRgo4O9qMax7slwmysY5Ku7mKYPel/bDXsLghlS5JzLYxPz/GeAM=", BinaryEncoding.Base64), Compression.Deflate
			)
		),
	let _t = ((type text) meta [Serialized.Text = true]) in type table [id = _t, text = _t]
	),
	ChangedType = Table.TransformColumnTypes(Source,{{"id", Int64.Type}, {"text", type text}}),
	SplittedColumnByDelimiter = Table.ExpandListColumn(Table.TransformColumns(ChangedType, {{"text", Splitter.SplitTextByDelimiter(", ", QuoteStyle.Csv),
	let ItemType = (type nullable text) meta [Serialized.Text = true] in type {ItemType}}}), "text"),
	SplittedColumnByDelimiter1 = Table.SplitColumn(SplittedColumnByDelimiter, "text", Splitter.SplitTextByEachDelimiter({" "}, QuoteStyle.Csv, false), {"text.1", "text.2"}),
	CapitalizedEachWord = Table.TransformColumns(SplittedColumnByDelimiter1,{{"text.1", Text.Proper, type text}}),
	MergedColumns = Table.CombineColumns(CapitalizedEachWord,{"text.1", "text.2"},Combiner.CombineTextByDelimiter(" ", QuoteStyle.None),"text"),
	GroupedRows = Table.Group(MergedColumns, {"id"}, {{"text", each _[text], type list}}),
	ExtractedValues = Table.TransformColumns(GroupedRows, {"text", each Text.Combine(List.Transform(_, Text.From), ", "), type text})
in
	ExtractedValues