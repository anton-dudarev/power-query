/* Returns the number of occurrences of a substring (needle) within another string (haystack).
// Usage: fnTextClout("Abba", "b")
// Result: 2 */ 

(Text1 as text, Text2 as text) as number => List.Count(Text.Split(Text1, Text2)) - 1