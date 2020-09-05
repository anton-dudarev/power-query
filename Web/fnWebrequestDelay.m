(Url as text) =>
  let
    // request data
    RequestDataRecord = fnGetjson(Web.Contents(Url)),
    // wait 10x for 5 seconds
    WaitForList = List.Repeat({5}, 10),
    // wait until the response is COMPLETE, but max 50 secs
    WaitForStatus = List.MatchesAny(
        WaitForList, 
        each Function.InvokeAfter(
            () => fnGetjson(Web.Contents(Url)), 
            #duration(0, 0, 0, _)
          )
          = "OK"
      ),
    // download file if WaitForStatus was successful
    DownloadFile = if WaitForStatus then fnGetjson(Web.Contents(Url)) else null
  in
    DownloadFile