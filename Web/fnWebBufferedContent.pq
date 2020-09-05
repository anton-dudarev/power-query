(url) => 
  let
    BufferedWithMetadata = (binary) => 
      (try Binary.Buffer() otherwise null)
        meta Value.Metadata(binary),
    response = BufferWithMetadata(Web.Contents(url, [ManualStatusHandling = {404}])),
    out = if Value.Metadata(response)[Response.Status] = 404 then null else response
  in
    out
