(Month as number) =>
  let
    Prefix = try
      {"ый", "ой", "ий", "ый", "ый", "ой", "ой", "ой", "ый", "ый", "ый", "ый"}{
        List.PositionOf({1 .. 12}, Month)
      }
    otherwise
      ""
  in
    Prefix
