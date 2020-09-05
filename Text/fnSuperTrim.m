/* Function removes double presents of specified characters. By default remove double spaces and leading + ending spaces. Like TRIM function in Excel Original is taked from Ken Puls's blog http://www.excelguru.ca/blog/2015/10/08/clean-whitespace-in-powerquery/ */ 

(Text as text, optional CharToTrim as text) => 
  let
    Char = if CharToTrim = null then " " else CharToTrim,
    Split = Text.Split(Text, Char),
    RemoveBlanks = List.Select(Split, each _ <> ""),
    Result = Text.Combine(RemoveBlanks, Char)
  in
    Result