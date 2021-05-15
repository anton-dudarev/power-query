// Search with regular expressions
// Usage: fnRegExp("Text", "(\d{4})", ";")
// Source: https://www.planetaexcel.ru/techniques/7/13310/

let
  RegExp = (txt as text, regex as text, delim as text) =>
    Web.Page(
      "<script>var x = '" &
      txt &
      "';var delim = '" &
      delim &
      "';var regex = /" &
      regex &
      "/gi;var result = x.match(regex).join(delim);document.write(result);</script>"
    )
    [Data]{0}[Children]{0}[Children]{1}[Text]{0}
in
  RegExp
