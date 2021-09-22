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
    List.Skip(FixedDoubleQuotes, 3),
    Splitter.SplitTextByDelimiter("#(tab)", QuoteStyle.None),
    GeneratedColumnNames
  ),
  RemovedFirstColumn = Table.RemoveColumns(ConvertedListToTable, {"Column1"}),
  PromotedHeaders = Table.PromoteHeaders(RemovedFirstColumn, [PromoteAllScalars = true]),
  RemovedTopRows = Table.Skip(PromotedHeaders, 1),
  ColumnNames = Table.ColumnNames(RemovedTopRows),
  RenamedColumns = Table.RenameColumns(
    RemovedTopRows,
    {
      {"Отдел сбыт", "Отдел сбыта ТП ID"},
      {"Назв.отдТП", "Отдел сбыта ТП"},
      {"Торговый п", "ТП ID"},
      {"Имя Предст", "ТП"},
      {"ОтдСб", "Отдел сбыта ID"},
      {"ГрСб", "СПП ID"},
      {"Название", "СПП"},
      {"Заказчик", "AG ID"},
      {"Наименование заказчика", "Заказчик"},
      {"Дебитор", "RGWEZA ID"},
      {"Наименование дебитора", "Дебитор"},
      {"ПрУдТкст", "Признак удаления"},
      {"Классиф.", "Программа ID"},
      {"ГрКл", "Сегмент ID"},
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
  ChangedType = Table.TransformColumnTypes(
    ReplacedBlankByText,
    {
      {"Отдел сбыта ТП ID", type text},
      {"Отдел сбыта ТП", type text},
      {"ТП ID", type text},
      {"ТП", type text},
      {"Отдел сбыта ID", type text},
      {"СПП ID", type text},
      {"СПП", type text},
      {"Роль", type text},
      {"AG ID", type text},
      {"Заказчик", type text},
      {"RGWEZA ID", type text},
      {"Дебитор", type text},
      {"Признак удаления", type text},
      {"Программа ID", type text},
      {"Сегмент ID", type text},
      {"Способ платежа ID", type text},
      {"Дата создания", type date},
      {"Создал", type text},
      {"Не адрес доставки", type text},
      {"Регион ID", type text},
      {"Город", type text},
      {"Улица", type text},
      {"Дом", type text},
      {"Почтовый индекс", type text},
      {"Примечания к адресу", type text},
      {"Транспортная зона", type text},
      {"Отгрузка самовывозом", type text},
      {"Пункт отгрузки по умолчанию", type text},
      {"Группа цен", type text},
      {"Группа цен.1", type text},
      {"СБН", type text},
      {"Признак блокировки", type text},
      {"ИП", type text},
      {"НДС", type text},
      {"ФЛ", type text},
      {"ИНН", type text},
      {"ОКПО", type text},
      {"Телефон", type text},
      {"Мобильный", type text},
      {"E-mail", type text},
      {"Страна ID", type text},
      {"Сектор юрлица", type text},
      {"Группа счетов", type text},
      {"Кредитное управление", type text},
      {"Рассылка Кросс-докинг", type text},
      {"Продающий завод", type text},
      {"Закупка Кросс-докинг", type text}
    }
  ),
  RemovedDuplicates = Table.Distinct(ChangedType)
in
  RemovedDuplicates
