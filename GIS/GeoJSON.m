let
  sq = (x, y) => {{{x, y}, {x + 1, y}, {x + 1, y + 1}, {x, y + 1}, {x, y}}},
  test = [type = "FeatureCollection", features = {
    [type = "Feature", properties = [ID = 5], geometry = [type = "Polygon", coordinates = {
      {{0, 0}, {1, 0}, {1, 1}, {0, 1}, {0, 0}}
    }]]
  }],
  geoLine = List.Accumulate(
      {1..100}, 
      {}, 
      (se, ce) => List.Accumulate(
          {1..100}, 
          se, 
          (s, c) => s
            & {
            [type = "Feature", properties = [ID = c * 100 + ce], geometry = [
              type = "Polygon", 
              coordinates = sq(ce, c)
            ]]
          }
        )
    ),
  geoLineFull = [type = "FeatureCollection", features = geoLine],
  out = Json.FromValue(geoLineFull)
in
  out
