// https://blog.crossjoin.co.uk/2014/06/25/using-list-generate-to-make-multiple-replacements-of-words-in-text-in-power-query

let
  //Get table of word replacements
  Replacements = Excel.CurrentWorkbook(){[Name = "Replacements"]}[Content],
  //Get table containing text to change
  TextToChange = Excel.CurrentWorkbook(){[Name = "Text"]}[Content],
  //Get list of words to replace
  WordsToReplace = Table.Column(Replacements, "Word To Replace"),
  //Get list of words to replace them with
  WordsToReplaceWith = Table.Column(Replacements, "Replace With"),
  //A non-recursive function to do the replacements
  ReplacementFunction = (InputText) => 
    let
      //Use List.Generate() to do the replacements
      DoReplacement = List.Generate(
          () => [Counter = 0, MyText = InputText], 
          each [Counter] <= List.Count(WordsToReplaceWith), 
          each [Counter = [Counter] + 1, MyText = Text.Replace(
              [MyText], 
              WordsToReplace{[Counter]}, 
              WordsToReplaceWith{[Counter]}
            )], 
          each [MyText]
        ),
      //Return the last item in the list that
      //List.Generate() returns
      GetLastValue = List.Last(DoReplacement)
    in
      GetLastValue,
  //Add a calculated column to call the function on every row in the table
  //containing the text to change
  Output = Table.AddColumn(TextToChange, "Changed Text", each ReplacementFunction([Text]))
in
  Output