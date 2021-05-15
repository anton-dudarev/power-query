// Replicate a CASE Statement (or SWITCH) with wildcards and forced casing options
// Usage: fnSwitch(Column1, true, true)

(Text as text, Like as logical, ForceCase as logical) as any =>
  let
    Values = {
      {"foo", "returnVal"}, 
      {"bar", "returnVal2"}
    }, 
    CaseSensitive = if ForceCase then Text else Text.Lower(Text), 
    Result = 
      if Like then
        List.First(List.Select(Values, each Text.Contains(CaseSensitive, _{0}))){1}?
      else
        List.First(List.Select(Values, each _{0} = CaseSensitive)){1}?
  in
    Result
