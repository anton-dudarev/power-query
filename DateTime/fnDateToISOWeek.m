/*
based on <https://en.wikipedia.org/wiki/ISO_week_date#Calculating_the_week_number_of_a_given_date>

M / Power Query doesn't have a native ISO8601 Week Number function, and DAX's
`weeknum(x, 21)` doesn't give the correct ISO Week-Year.

homepage: <https://gist.github.com/r-k-b/18d898e5eed786c9240e3804b167a5ca>
*/

let
    getISO8601Week = (someDate as date) =>
        let
            getDayOfWeek = (d as date) =>
                let
                    result = 1 + Date.DayOfWeek(d, Day.Monday)
                in
                    result,

            getNaiveWeek = (inDate as date) =>
                let
                    // monday = 1, sunday = 7
                    weekday = getDayOfWeek(inDate),

                    weekdayOfJan4th = getDayOfWeek(#date(Date.Year(inDate), 1, 4)),

                    ordinal = Date.DayOfYear(inDate),

                    naiveWeek = Number.RoundDown(
                        (ordinal - weekday + 10) / 7
                    )
                in
                    naiveWeek,

            thisYear = Date.Year(someDate),

            priorYear = thisYear - 1,

            nwn = getNaiveWeek(someDate),

            lastWeekOfPriorYear =
                getNaiveWeek(#date(priorYear, 12, 28)),

            // http://stackoverflow.com/a/34092382/2014893
            lastWeekOfThisYear =
                getNaiveWeek(#date(thisYear, 12, 28)),

            weekYear =
                if
                    nwn < 1
                then
                    priorYear
                else
                    if
                        nwn > lastWeekOfThisYear
                    then
                        thisYear + 1
                    else
                        thisYear,

            weekNumber =
                if
                    nwn < 1
                then
                    lastWeekOfPriorYear
                else
                    if
                        nwn > lastWeekOfThisYear
                    then
                        1
                    else
                        nwn,

            week_dateString =
                Text.PadStart(
                    Text.From(
                        Number.RoundDown(weekNumber)
                    ),
                    2,
                    "0"
                )
        in
            Text.From(weekYear) & "-W" & week_dateString & "-" & Text.From(getDayOfWeek(someDate))
in
    getISO8601Week
