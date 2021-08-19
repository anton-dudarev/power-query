(Origins as text, Destinations as text) =>
  let
    Source = Json.Document(
      Web.Contents(
        "https://maps.googleapis.com/maps/api/distancematrix/json?origins="
          & Uri.EscapeDataString(Origins)
          & "&destinations="
          & Uri.EscapeDataString(Destinations)
          & "&key="
          & APIKey
          & "&traffic_model=pessimistic&mode=driving&departure_time=now&avoid=highways&language=ru"
      )
    )
  in
    Source
