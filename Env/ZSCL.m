let
  Source = File.Contents(PRM_RootPath & ".0_Data_Raw\10_SAP\ERP\ZSCL_REPORTS.TXT"), 
  FixedDoubleQuotes = List.ReplaceValue(
    Lines.FromBinary(
      File.Contents(PRM_RootPath & ".0_Data_Raw\10_SAP\ERP\ZSCL_REPORTS.TXT"), 
      null, 
      null, 
      1251
    ), 
    """""", 
    """", 
    Replacer.ReplaceText
  ), 
  ReplacedPipeSimbols = List.ReplaceValue(FixedDoubleQuotes, "|", " ", Replacer.ReplaceText), 
  SourceColumnNumber = List.NonNullCount(
    List.Distinct(
      Table.Transpose(
        Table.ReplaceValue(
          Table.Range(
            Csv.Document(
              Source, 
              [Delimiter = "#(tab)", Columns = 100, Encoding = 1251, QuoteStyle = QuoteStyle.None]
            ), 
            3, 
            1
          ), 
          "", 
          "#", 
          Replacer.ReplaceValue, 
          {"Column1"}
        )
      )[Column1]
    )
  ), 
  GeneratedColumnNames = List.Generate(
    () => 1, 
    each _ <= SourceColumnNumber, 
    each _ + 1, 
    each "Column" & Text.From(_)
  ), 
  ConvertedListToTable = Table.FromList(
    List.Skip(ReplacedPipeSimbols, 3), 
    Splitter.SplitTextByDelimiter("#(tab)", QuoteStyle.None), 
    GeneratedColumnNames
  ), 
  RemovedFirstColumn = Table.RemoveColumns(ConvertedListToTable, {"Column1"}), 
  PromotedHeaders = Table.Skip(
    Table.PromoteHeaders(RemovedFirstColumn, [PromoteAllScalars = true]), 
    1
  ), 
  ErrorStatusColumnMissed = 
    if Table.HasColumns(PromotedHeaders, {"Статус"}) = true then
      PromotedHeaders
    else
      fnCustomError(1, PromotedHeaders), 
  RenamedPartnerColumn = try
    Table.RenameColumns(ErrorStatusColumnMissed, {{"Наим.заказчика", "Partner.Temp"}})
  otherwise
    Table.RenameColumns(ErrorStatusColumnMissed, {{"Наименование заказчика", "Partner.Temp"}}), 
  RenamedDebtorColumn = try
    Table.RenameColumns(RenamedPartnerColumn, {{"Наим.дебитора", "Debtor.Temp"}})
  otherwise
    Table.RenameColumns(RenamedPartnerColumn, {{"Наименование дебитора", "Debtor.Temp"}}), 
  ColumnNames = Table.ColumnNames(RenamedDebtorColumn), 
  RenamedColumns = Table.RenameColumns(
    RenamedDebtorColumn, 
    {
      {"Отдел сбыт", "Отдел сбыта ТП ID"}, 
      {"Назв.отдТП", "Отдел сбыта ТП"}, 
      {"Торговый п", "ТП ID"}, 
      {"Имя Предст", "ТП"}, 
      {"Partner.Temp", "Заказчик"}, 
      {"Debtor.Temp", "Дебитор"}, 
      {"ОтдСб", "Отдел сбыта ID"}, 
      {"ГрСб", "СПП ID"}, 
      {"Название", "СПП"}, 
      {"Заказчик", "AG ID"}, 
      {"Дебитор", "RGWEZA ID"}, 
      {"ПрУдТкст", "Признак удаления"}, 
      {"Классиф.", "Программа ID"}, 
      {"ГрКл", "Сегмент ID"}, 
      {"Статус", "Статус включенного клиента"}, 
      {"СП", "Способ платежа ID"}, 
      {"ДатаСозд", "Дата создания"}, 
      {"НеАдр.Дост", "Не адрес доставки"}, 
      {"Регион", "Регион ID"}, 
      {"№ дома", "Дом"}, 
      {"П/индекс", "Почтовый индекс"}, 
      {"ПО по умол", "Пункт отгрузки по умолчанию"}, 
      {"ТранспЗона", "Транспортная зона"}, 
      {"ГЦ", "Группа цен"}, 
      {"ГЦ_1", "Группа цен.1"}, 
      {"ПрБлТкст", "Признак блокировки"}, 
      {"Непл.НДС", "НДС"}, 
      {"Сектор", "Сектор юрлица"}, 
      {"Отгрузка с", "Отгрузка самовывозом"}, 
      {"Зак.Кросс-", "Закупка Кросс-докинг"}, 
      {"Рас.Кросс-", "Рассылка Кросс-докинг"}, 
      {"Ст.", "Страна ID"}, 
      {"Продающий", "Продающий завод"}, 
      {"Кред.управ", "Кредитное управление"}, 
      {"Группа", "Группа счетов"}
    }
  ), 
  ColumnNamesNew = List.RemoveItems(Table.ColumnNames(RenamedColumns), {"Дата создания"}), 
  ReplacedXByText = Table.ReplaceValue(
    RenamedColumns, 
    "X", 
    "ДА", 
    Replacer.ReplaceText, 
    {
      "Признак удаления", 
      "Не адрес доставки", 
      "Признак блокировки", 
      "ИП", 
      "НДС", 
      "ФЛ", 
      "Рассылка Кросс-докинг", 
      "Закупка Кросс-докинг"
    }
  ), 
  ReplacedBlankByText = Table.ReplaceValue(
    ReplacedXByText, 
    "", 
    "НЕТ", 
    Replacer.ReplaceValue, 
    {
      "Признак удаления", 
      "Не адрес доставки", 
      "Признак блокировки", 
      "ИП", 
      "НДС", 
      "ФЛ", 
      "Рассылка Кросс-докинг", 
      "Закупка Кросс-докинг"
    }
  ), 
  ChangedTypeText = Table.TransformColumnTypes(
    ReplacedBlankByText, 
    List.Transform(ColumnNamesNew, each {_, type text})
  ), 
  ChangedTypeDate = Table.TransformColumnTypes(ChangedTypeText, {{"Дата создания", type date}}), 
  RemovedDuplicates = Table.Distinct(ChangedTypeDate)
in
  RemovedDuplicates
