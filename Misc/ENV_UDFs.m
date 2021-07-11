// List of queries in the workbook
let
  Source = Record.FieldNames(#shared),
  UDF = List.Select(Source, each Record.HasFields(#sections[Section1], _)),
  FilteredFunctions = List.Select(
    UDF,
    each not Text.StartsWith(_, "fn") and not Text.StartsWith(_, "M_")
  ),
  SortedItems = List.Sort(FilteredFunctions, Order.Ascending),
  Result = List.Buffer(SortedItems)
in
  Result
