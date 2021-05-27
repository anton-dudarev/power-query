let
  Source = Record.FieldNames(#shared),
  UDF    = List.Select(Source, each Record.HasFields(#sections[Section1], _)),
  Result = List.Buffer(UDF)
in
  Result
