/* //Check if a string contains any of the keywords from a given list
// Usage: fnTextContainsAny("the cat sat on the mat", {"cat", "apple"})
// Result: true */ 

(String as text, Keywords as list) as logical => 
  let
    Count = List.Count(Keywords)
  in
    List.AnyTrue(
        List.Generate(
            () => [i = 0], 
            each [i] < Count, 
            each [i = [i] + 1], 
            each Text.Contains(String, Keywords{[i]})
          )
      )