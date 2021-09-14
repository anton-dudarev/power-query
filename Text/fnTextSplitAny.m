let func =   
 (string as text, separator as any) =>

let

/* Debug parameters
    string = "Do I need gloves for Power Query?",
    separator = {"s", "need ", "Do ", "?", "g", "for "},
*/     

    SeparatorIsTypeList = Value.Is(separator, type list),

    ListFunction = List.Accumulate(separator, 
                                  {string}, 
                                  (state, current) => 
                                    let 
                                        DoForEveryItemInTheList = List.Transform(state, each Text.Split(_, current)),
                                        FlattenNestedList = List.Combine(DoForEveryItemInTheList),
                                        RemoveEmpties = List.Select(FlattenNestedList, each _<>"" and _<>" ")
                                    in
                                        RemoveEmpties
                                        ),

    TextFunction = Text.SplitAny(string, separator),

    Result = if SeparatorIsTypeList then ListFunction else TextFunction

in
    Result ,
documentation = [
Documentation.Name =  " Text.SplitAnyNew ",
Documentation.Description = " Splits text to a list by each delimiter. Delimters can either be each character from a string or each string from a list. ",
Documentation.LongDescription = " Splits text to a list by each delimiter. Delimters can either be each character from a string or each string from a list. ",
Documentation.Category = " Text ",
Documentation.Source = " https://wp.me/p6lgsG-Yr . ",
Documentation.Version = " 1.0 ",
Documentation.Author = " Imke Feldmann: www.TheBIccountant.com: https://wp.me/p6lgsG-Yr  . ",
Documentation.Examples = {[Description =  " See this blogpost: https://wp.me/p6lgsG-Yr  ",
Code = " TextSplitAnyNew(""Do I need gloves for Power Query?"", {""s"", ""need"", ""do"", ""?"", ""g"", ""for""}) ",
Result = " {""I"", ""love"", ""Power Query""} "]}]
  
 in  
  Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation))
