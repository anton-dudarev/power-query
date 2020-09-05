// Author: Colin Banfield (https://social.technet.microsoft.com/profile/colin%20banfield/?ws=usercard-mini)
// Source: https://social.technet.microsoft.com/Forums/en-US/ee911661-6cb1-48ac-ae46-d70979b35cb7/homogeneous-list-types-in-m?forum=powerquery

(table as table, optional culture as nullable text) as table => 
  let
    ValidTypes = {
      type any, 
      type number, 
      type date, 
      type datetime, 
      type datetimezone, 
      type time, 
      type duration, 
      type logical, 
      type text, 
      type binary, 
      Int64.Type, 
      Percentage.Type, 
      Currency.Type
    },
    Top200Rows = Table.FirstN(table, 200), //we use up to 200 rows to establish a column type
    ColumnNameList = Table.ColumnNames(Top200Rows),
    ColumnDataLists = List.Accumulate(
        ColumnNameList, 
        {}, 
        (accumulated, i) => accumulated & {Table.Column(Top200Rows, i)}
      ),
    ColumnTypes = List.Transform(ColumnDataLists, (i) => List.ItemType(i)),
    TransformList = List.Select(
        List.Zip({ColumnNameList, ColumnTypes}), 
        each List.Contains(ValidTypes, _{1})
      ),
    TypedTable = Table.TransformColumnTypes(table, TransformList, culture),
    List.ItemType = (list as list) => 
      let
        ItemTypes = List.Transform(
            list, 
            each 
              if Value.Type(Value.FromText(_, culture)) = type number then 
                if Text.Contains(Text.From(_, culture), "%") then 
                  Percentage.Type
                else if Text.Length(
                    Text.Remove(Text.From(_, culture), {"0".."9"} & Text.ToList("., -+eE()/'"))
                  )
                  > 0 then 
                  Currency.Type
                else if Int64.From(_, culture) = Value.FromText(_, culture) then 
                  Int64.Type
                else 
                  type number
              else 
                Value.Type(Value.FromText(_, culture))
          ),
        ListItemType = Type.NonNullable(Type.Union(ItemTypes))
      in
        ListItemType
  in
    TypedTable