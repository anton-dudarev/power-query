let
  start = #table({"SESSION_LAST_COMMAND_START_TIME", "SESSION_LAST_COMMAND"}, {}),
  PreviousLogRows = try Table.ToRows(MetaQuery("EVALUATE (QueryLog)")) otherwise Table.ToRows(start),
  PreviousLog = Table.FromRows(PreviousLogRows, Table.ColumnNames(start)),
  CurrentLog = MetaQuery(
      "SELECT SESSION_LAST_COMMAND_START_TIME, SESSION_LAST_COMMAND 
      FROM 
        $SYSTEM.DISCOVER_SESSIONS 
      WHERE 
        LEFT([SESSION_LAST_COMMAND],27)<>'SELECT SESSION_LAST_COMMAND' 
      AND 
        LEFT([SESSION_LAST_COMMAND],19)<>'EVALUATE (QueryLog)' 
      ORDER BY 
        SESSION_LAST_COMMAND_START_TIME DESC"
    ),
  CurrentLogTop = 
    if Table.RowCount(prevLog) = 0 then 
      Table.FirstN(currLog, 1)
    else 
      Table.SelectRows(
          CurrentLog, 
          each [SESSION_LAST_COMMAND_START_TIME]
            > Table.Last(CurrentLog)[SESSION_LAST_COMMAND_START_TIME]
        ),
  out = Table.Combine({start, PreviousLog, CurrentLogTop})
in
  out
