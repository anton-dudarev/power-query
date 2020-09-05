(ColumnName as text) =>
Text.Combine(
    List.RemoveNulls(
        List.Transform(
            Text.ToList(ColumnName), 
            each if Value.Is(Value.FromText(_), type number) then _ else null
          )
      )
  )