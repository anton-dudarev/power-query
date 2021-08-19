(Center as text, Zoom as text, Size as text) =>
  let
    Source = Json.Document(
      Web.Contents(
        "https://maps.googleapis.com/maps/api/staticmap", 
        [
          Query      = [#"center" = Center, #"zoom" = Zoom, #"size" = Size, #"maptype" = "roadmap"], 
          ApiKeyName = APIKey
        ]
      )
    )
  in
    Source
