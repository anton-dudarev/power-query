/*
// Get a curl command string for a given url and options (as used in Web.Contents()) for debugging purposes.
// Usage: fnGetCurl("http://item.taobao.com/item.htm", [Query=[id="16390081398"]])
// Result: 'curl "http://item.taobao.com/item.htm?id=16390081398" -v' */ 

(Url as text, optional Options as record) as text => 
  let
    //Url = "http://item.taobao.com/item.htm?id=16390081398",
    //Options = [Query=null],
    Query = Options[Query],
    Headers = Options[Headers],
    qList = List.Transform(Record.FieldNames(Query), each _ & "=" & Record.Field(Query, _)),
    hList = List.Transform(
        Record.FieldNames(Headers), 
        each " -H """ & _ & ": " & Record.Field(Headers, _) & """"
      ),
    qJoined = try "?" & Text.Combine(qList, "&") otherwise "",
    hJoined = try Text.Combine(hList, "") otherwise "",
    Return = "curl """ & url & qJoined & """" & hJoined & " -v"
  in
    Return