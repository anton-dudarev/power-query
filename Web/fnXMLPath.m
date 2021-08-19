// [Power Query] return the table at the end of the path eg. xmlPath(XML,{"auditfile","customersSuppliers","customerSupplier"})   

(Xml as table, Path as list) =>
  let
    isEmptyTable = each Type.Is(Value.Type(_), Table.Type) and List.Count(Table.ToRows(_)) = 0,
    XmlRow2record = (rec, row) =>
      Record.AddField(rec, row{0}, if isEmptyTable(row{2}) then null else row{2}),
    XmlTableExpandNode = (XmlTable, Node) =>
      List.Accumulate(
        Table.SelectRows(XmlTable, each [Name] = Node)[Value],
        #table(1, {}),
        (s, c) => s & c
      ),
    Head = List.RemoveLastN(path, 1),
    Tail = List.Last(path),
    ExceptTail = List.Accumulate(Head, Xml, XmlTableExpandNode),
    TailRecords = List.Transform(
      Table.SelectRows(ExceptTail, each [Name] = Tail)[Value],
      each List.Accumulate(Table.ToRows(_), [], XmlRow2record)
    ),
    Result = Table.FromRecords(TailRecords)
  in
    Result
