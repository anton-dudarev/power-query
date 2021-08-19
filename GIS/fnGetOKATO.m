(OKATO as text) =>
  let
    Request  = Web.Page(Web.Contents("https://classifikators.ru/okato/" & OKATO)),
    Response = Request{1}[Data]
  in
    Response
