// https://bengribaudo.com/blog/2018/05/18/4447/automating-column-name-renames

(TextValue as text) as text => 
  let
    SplittedIntoParts = Text.Split(TextValue, "_"),
    ChangedCase
      = (InputText as text) as text => 
        if Comparer.Equals(Comparer.OrdinalIgnoreCase, "id", InputText) then 
          Text.Upper(InputText)
        else 
          Text.Proper(InputText),
    TransformedParts = List.Transform(SplittedIntoParts, ChangedCase),
    Result = Text.Combine(TransformedParts, " ")
  in
    Result