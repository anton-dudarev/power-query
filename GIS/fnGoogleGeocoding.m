(Address as text, optional AddressDetails as text) =>
let
    GoogleMapsRequest = Json.Document(Web.Contents
    (
      "https://maps.googleapis.com/maps/api/geocode/json?sensor=false&language=ru&address=" &
      Uri.EscapeDataString(Address & " " & AddressDetails) &
      "&key=" & ApiKey
    ))
in
    GoogleMapsRequest
