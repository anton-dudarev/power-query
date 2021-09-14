let func =   
 (MyTable as table,
MySearchStrings as any,
optional AllAny as text,
optional CaseInsensitive as text,
optional PartialMatch as text ) =>

let 
/* Debug Parameters                         ___Description for function parameters
MyTable = MyTable,                          // Table to search trough
MySearchStrings = {"INCOME STATEMENTs"},    // Can be entered as text for a single search string or as a list of search strings
AllAny = null,                              // optional: If list of search strings, true will be returned if any of the search strings are included. –>
                                            // Can be set to "All" and then all search strings must be included somewhere in the table
CaseInsensitive = null,                     // Case sensitivity is the default-mode, but any value entered here will change to case insensitive mode
PartialMatch = "x",                         // By default the values of the cells must match the search strings fully. But a parameter here will switch to partial match.
*/ //End of Debug Parameters

    // Creates a variable for the type of the search string
    typeSearchStrings = if Value.Is(MySearchStrings, type text) then "Text" else "List",


// *** 1) Create functon-modules that can later be executed sequentially  ***


    // If the search string is text, then a functions will simply be applied to it, 
    // but if it is a list, then the function has to be applied to each element of the list (using List.Transform) 

    fnTextOrList =      Record.Field([  Text = (x, fn) => fn(x), 
                                        List = (x, fn) => List.Transform(x, fn)], 
                                        typeSearchStrings),

    // If the search string is text, then these option are irrelevant (and shall be ignored, in case there are any entries for it)
    // but if it is a list, then the respective function shall be choosen. Default-value is "Any".

    fnAllAny =          if typeSearchStrings = "Text" 
                            then (x) => x
                            else Record.Field([ All = List.AllTrue, 
                                                Any = List.AnyTrue], 
                                                if AllAny = null then "Any" else Text.Proper(AllAny)), // Default is "Any"

    // Transforms to lower if CaseInsensitive, otherwise leaves the value unchanged

    fnCaseInsensitive = if CaseInsensitive = null 
                            then (x) => x 
                            else (x) => Text.Lower(x), 
                            
    // The default-value for PartialMatch is false and in that case, a list item has to match the search string completely (List.Contains),
    // but if there is an entry in "PartialMatch", then each item in the list has to be checked if it contains any of the search strings:
    // List.Transform iterates through the TableList and checks each of its items if it contains the string (Text.Contains)

    fnPartialMatch =    if PartialMatch = null 
                            then (x) => List.Contains(AdjustTableListToCaseSensitivity,x)
                            else (x) => List.AnyTrue(List.Transform(AdjustTableListToCaseSensitivity, (z) => Text.Contains(z, x))),


// *** 2) Execute function-modules sequentially ***

    TransformTableToList = List.Combine(Table.ToRows(MyTable)),
    AdjustTableListToCaseSensitivity = List.Transform(TransformTableToList, fnCaseInsensitive),
    AdjustSearchStringsToCaseSensitivity = fnTextOrList(MySearchStrings, fnCaseInsensitive),
    CheckForMatches = fnTextOrList(AdjustSearchStringsToCaseSensitivity, fnPartialMatch),
    ChooseIfAllOrAny = fnAllAny(CheckForMatches)
in
    ChooseIfAllOrAny ,
documentation = [
Documentation.Name =  " Table.ContainsAnywhere.pq",
Documentation.Description = " Checks if a string or list of strings is contained somewhere in the table. ",
Documentation.LongDescription = " Checks if a string or list of strings is contained somewhere in the table. <code>AllAny</code> parameter accepts ""All"" if all search parameters from the list must be found. <code>CaseInsensitive</code> parameter accepts any entry to change the default case sensitive mode to case insensitive instead. <code>PartialMatch</code> accepts any entry to change from the default full match requirement to a partial match. ",
Documentation.Category = " Table ",
Documentation.Source = " www.TheBIccountant.com .  https://wp.me/p6lgsG-14c . ",
Documentation.Version = " 1.0 ",
Documentation.Author = " Imke Feldmann: www.TheBIccountant.com. https://wp.me/p6lgsG-14c . ",
Documentation.Examples = {[Description =  "  ",
Code = " Table.ContainsAnywhere.pq(#table( {""Class"", ""Name""}, List.Zip( { {""Fruit"" ,""Fruit"" ,""Vegetable""}, {""Pear"" ,""Pineapple"" ,""Cucumber""} } ) ), {""Apple"", ""Pear""}, ""All"", ""x"", ""y"") ",
Result = " true "]}]
  
 in  
  Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation))  
