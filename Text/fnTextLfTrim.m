let
  fnLfTrim = (Text as text) => 
    let
      Split = Text.Split(Text, "#(lf)"),
      RemoveBlanks = List.Select(Split, each _ <> ""),
      Result = Text.Combine(RemoveBlanks, " ")
    in
      Text.Trim(Result)
in
  fnLfTrim