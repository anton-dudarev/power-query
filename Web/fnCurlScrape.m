/*
// Scrape a web page, raising an error with a curl command for debugging purposes in case the response is empty.
// Usage: fnCurlScrape("http://google.com", [#"Referer"="http://google.com"])
// Result: a binary representation of the Google front-page */ 

(Url as text, optional Options as record) as binary => 
  let
    Response = Web.Contents(Url, Options),
    Buffered = Binary.Buffer(Response),
    Meta = try Value.Metadata(Response) otherwise null,
    Status = if Buffered = null then 0 else Meta[Response.Status],
    Return = 
      if Status = 0 or Status >= 400 // Binary.Length(Buffered) = 0 then 
        error Error.Record("ScrapeFailed", fnGetCurl(Url, Options), Meta)
      else 
        Buffered
  in
    Return