let
	Source = Table.Combine(
		{
			fnGetHolidays(Text.From(lstYears{0})), 
			fnGetHolidays(Text.From(lstYears{1})), 
			fnGetHolidays(Text.From(lstYears{2})), 
			fnGetHolidays(Text.From(lstYears{3}))
		}
	),
	FixedCOVIDValue = Table.ReplaceValue(
		Source, 
		"COVID-", 
		"COVID-19", 
		Replacer.ReplaceText, 
		{"Holidays"}
	),
	SortedRows = Table.Sort(
		FixedCOVIDValue, 
		{{"Year", Order.Descending}, {"Day_Year", Order.Descending}}
	)
in
	SortedRows