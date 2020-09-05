/*
    Created By: Alex Powers
    Website: http://www.itsnotaboutthecell.com
    LinkedIn: https://www.linkedin.com/in/alexmpowers/
    Contact: alexmpowers@itsnotaboutthecell.com
*/
// Google Search Query: https://www.google.com/search?q=
// Instructions: Pass through the search value to return the first page URL's from Google's search query.
// Ex. Cats (There's going to be a lot)
// Challenge: Determine total number or results and create a list to paginate the results

(Search as text) => 
  let
    Source = Text.FromBinary(Web.Contents("http://www.google.com/search?q=" & Search)),
    GetHyperlink = (Counter as number) => 
      let
        Hyperlink = Text.BetweenDelimiters(Source, "/url?q=", "&amp", Counter)
      in
        /* Where Recursive Function Begins - with the if statement we offer ourselves a way out of if a blank string is returned otherwise we continue to increment through the page where the text between the delimiters is "/url?q=" and "&amp" */
        if Hyperlink = "" then {} else List.Combine({{Hyperlink}, @GetHyperlink(Counter + 1)}),
    Output = GetHyperlink(0)
  in
    Output