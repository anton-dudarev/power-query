let
  Source = Table.FromRows(
    Json.Document(
      Binary.Decompress(
        Binary.FromText(
          "i45WMjDUAyIjA0NzJR0lY0M9QyMYJz8vOVUpVgefktz8vJKMnEoCqgpLE4tKUotA6mIB", 
          BinaryEncoding.Base64
        ), 
        Compression.Deflate
      )
    ), 
    let
      _t = ((type text) meta [Serialized.Text = true])
    in
      type table [period_start = _t, period_end = _t, schedule = _t]
  ), 
  #"Changed Type" = Table.TransformColumnTypes(
    Source, 
    {{"period_start", type date}, {"period_end", type date}, {"schedule", type text}}
  ), 
  #"Added Custom" = Table.AddColumn(
    #"Changed Type", 
    "ListOfDates", 
    each List.Transform(
      {Number.From([period_start]) .. Number.From([period_end])}, 
      each Date.From(_)
    )
  ), 
  #"Added Custom1" = Table.AddColumn(
    #"Added Custom", 
    "ListOfNewRows", 
    each 
      if [schedule] = "once" then
        {[period_start]}
      else if [schedule] = "monthly" then
        List.Distinct(List.Transform([ListOfDates], each Date.StartOfMonth(_)))
      else
        List.Distinct(List.Transform([ListOfDates], each Date.StartOfQuarter(_)))
  ), 
  #"Expanded ListOfNewRows" = Table.ExpandListColumn(#"Added Custom1", "ListOfNewRows")
in
  #"Expanded ListOfNewRows"
