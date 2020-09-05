/* Do multiple text replacements in one function call, passing the replacements as a list of lists
// Usage: fnTextReplaceByList("(test)", { {"(", "["}, {")", "]"} })
// Result: "[test]" */ 

(TextString as text, Replacements as list) as text => List.Accumulate(
    Replacements, 
    TextString, 
    (s, x) => Text.Replace(s, x{0}, x{1})
  )