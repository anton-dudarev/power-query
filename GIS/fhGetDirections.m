(Origin, Destination) =>

let
  Source = Json.Document(
      Web.Contents(
          "https://maps.googleapis.com/maps/api/directions/json?"
            & "origin=" & Uri.EscapeDataString(Origin)
            & "&destination=" & Uri.EscapeDataString(Destination)
          & "&key=" & GoogleApiToken, 
          [Headers = [#"Content-Type" = "application/json"]]
        )
    )
in
  Source
