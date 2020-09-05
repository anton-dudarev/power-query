let
  fx = (Text, Regex) => Web.Page(
      "<script> var x='"
        & Text
        & "'; var y=new RegExp('"
        & Regex
      & "','g'); var b=x.match(y); document.write(b); </script>"
    )[Data]{0}[Children]{0}[Children]{1}[Text]{0}
in
  fx
