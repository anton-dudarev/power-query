(Guid) => 
  let
    Url = "https://suggestions.dadata.ru/suggestions/api/4_1/rs/findById/address",
    Source = Json.Document(
        Web.Contents(
            Url, 
            [Headers = [
              ContentType = "application/json;charset=UTF-8", 
              Accept = "application/json", 
              Authorization = DaDataToken
            ], Query = Json.Document(fnGetJson([query = Guid]))]
          )
      )
  in
    Source
