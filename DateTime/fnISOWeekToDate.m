/*
based on https://en.wikipedia.org/wiki/ISO_week_date#Calculating_a_date_given_the_year.2C_week_number_and_weekday

format input like: `2017-W02-7`

homepage: <https://gist.github.com/r-k-b/18d898e5eed786c9240e3804b167a5ca>
*/

let
    getDateFromISO8601Week = (inputIsoWeek as text) as date =>
        let
            getDayOfWeek = (d as date) =>
                let
                    result = 1 + Date.DayOfWeek(d, Day.Monday)
                in
                    result,

            isoWeekYear = Number.FromText(
                Text.Range(inputIsoWeek, 0, 4)
            ),

            isoWeek = Number.FromText(
                Text.Range(inputIsoWeek, 6, 2)
            ),

            isoWeekDay = Number.FromText(
                Text.Range(inputIsoWeek, 9, 1)
            ),

            // this doesn't seem right...
            weekdayOfJan4th = getDayOfWeek(#date(isoWeekYear, 1, 4)),

            // this doesn't seem right...
            daysInYear = Date.DayOfYear(#date(isoWeekYear, 12, 31)),

            // this doesn't seem right...
            daysInPriorYear = Date.DayOfYear(#date(isoWeekYear - 1, 12, 31)),

            correction = weekdayOfJan4th + 3,

            ordinal = isoWeek * 7 + isoWeekDay - correction,

            adjustedOrdinal =
                if
                    ordinal < 1
                then
                    ordinal + daysInPriorYear
                else
                    if
                        ordinal > daysInYear
                    then
                        ordinal - daysInYear
                    else
                        ordinal,

            calendarYear =
                if
                    ordinal < 1
                then
                    isoWeekYear - 1
                else
                    if
                        ordinal > daysInYear
                    then
                        isoWeekYear + 1
                    else
                        isoWeekYear,

            theDate = Date.AddDays(#date(calendarYear, 1, 1), adjustedOrdinal - 1)
        in
            theDate
in
    getDateFromISO8601Week
