(InputData) => 
  let
    JsonOutput = Json.FromValue(InputData),
    OutputText = Text.FromBinary(JsonOutput)
  in
    OutputText
