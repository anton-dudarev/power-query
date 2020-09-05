/* Remove all uicode symbols from text
// Originally written by Chris Webb: https://cwebbbi.wordpress.com/2014/08/18/removing-punctuation-from-text-in-power-query/
// Usage: newText = fnTextRemoveSymbols("a,b,c") newText
// Result: newText = "abc" */ 

(InputText as text) as text => 
  let
    //get a list of lists containing the numbers of Unicode punctuation characters
    NumberLists = {{0..31}, {33..47}, {58..64}, {91..96}, {123..191}},
    //turn this into a single list
    CombinedList = List.Combine(NumberLists),
    //get a list of all the punctuation characters that these numbers represent
    PunctuationList = List.Transform(CombinedList, each Character.FromNumber(_)),
    //some text to test this on
    //InputText = "Hello! My name is Chris, and I'm hoping that this *cool* post will help you!",
    //the text with punctuation removed
    OutputText = Text.Remove(InputText, PunctuationList)
  in
    OutputText