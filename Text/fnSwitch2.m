(DebtorID as text) as any =>
  let
    Values = {
      {"100", "FO"},
      {"102", "FL"},
      {"104", "AG"},
      {"40", "AG"},
      {"43", "RG"},
      {"48", "ZA"},
      {"CC", "FL"},
	    {"#", "#"}
    },
    Result = List.First(List.Select(Values, each _{0} = DebtorID)){1}?
  in
    Result
