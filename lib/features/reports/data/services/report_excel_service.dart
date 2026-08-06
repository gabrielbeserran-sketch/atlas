import 'package:excel/excel.dart';
import 'package:projeto_atlas/features/reports/data/services/report_pdf_service.dart';

class ReportExcelService {
  static final ExcelColor _green = ExcelColor.fromHexString('#1B5E20');
  static final ExcelColor _lightGreen = ExcelColor.fromHexString('#E8F5E9');
  static final ExcelColor _darkText = ExcelColor.fromHexString('#263238');
  static final ExcelColor _gray = ExcelColor.fromHexString('#F2F4F5');
  static final ExcelColor _red = ExcelColor.fromHexString('#C62828');
  static final ExcelColor _blue = ExcelColor.fromHexString('#1565C0');
  static final ExcelColor _orange = ExcelColor.fromHexString('#EF6C00');
  static final ExcelColor _white = ExcelColor.fromHexString('#FFFFFF');

  Future<void> exportReport({required ReportPdfData report}) async {
    final excel = Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();

    if (defaultSheet != null && defaultSheet != 'Resumo') {
      excel.rename(defaultSheet, 'Resumo');
    }

    _buildSummarySheet(excel: excel, report: report);

    _buildExpenseCategoriesSheet(excel: excel, report: report);

    _buildFinancialRankingSheet(excel: excel, report: report);

    _buildInventoryRankingSheet(excel: excel, report: report);

    _buildAlertsSheet(excel: excel, report: report);

    _buildDiagnosisSheet(excel: excel, report: report);

    _buildActionPlanSheet(excel: excel, report: report);

    _buildPropertiesSheet(excel: excel, report: report);

    for (final farm in report.farms) {
      _buildFarmSheet(excel: excel, farm: farm);
    }

    excel.setDefaultSheet('Resumo');

    final fileName = _createFileName(report);

    excel.save(fileName: fileName);
  }

  void _buildSummarySheet({
    required Excel excel,
    required ReportPdfData report,
  }) {
    final sheet = excel['Resumo'];

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('F1'),
      customValue: TextCellValue('PROJETO ATLAS'),
    );

    _styleRange(
      sheet: sheet,
      startRow: 0,
      endRow: 0,
      startColumn: 0,
      endColumn: 5,
      style: _titleStyle(),
    );

    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('F2'),
      customValue: TextCellValue('Relatório Gerencial Pecuário'),
    );

    _styleRange(
      sheet: sheet,
      startRow: 1,
      endRow: 1,
      startColumn: 0,
      endColumn: 5,
      style: _subtitleStyle(),
    );

    _appendLabelValue(sheet, 'Relatório', report.reportTitle);
    _appendLabelValue(sheet, 'Propriedade', report.farmFilter);
    _appendLabelValue(sheet, 'Período', report.periodLabel);
    _appendLabelValue(sheet, 'Data de emissão', report.issueDate);

    _appendSectionHeader(sheet, 'Resumo executivo', columns: 6);

    _appendMetricRow(
      sheet,
      'Fazendas',
      IntCellValue(report.farms.length),
      _green,
    );

    _appendMetricRow(
      sheet,
      'Receitas',
      DoubleCellValue(report.totalIncome),
      _green,
      currency: true,
    );

    _appendMetricRow(
      sheet,
      'Despesas',
      DoubleCellValue(report.totalExpenses),
      _red,
      currency: true,
    );

    _appendMetricRow(
      sheet,
      'Resultado',
      DoubleCellValue(report.totalBalance),
      report.totalBalance >= 0 ? _green : _red,
      currency: true,
    );

    _appendMetricRow(
      sheet,
      'Valor do estoque',
      DoubleCellValue(report.totalInventoryValue),
      _blue,
      currency: true,
    );

    _appendMetricRow(
      sheet,
      'Compromissos',
      IntCellValue(report.totalAgendaTasks),
      _blue,
    );

    _appendMetricRow(
      sheet,
      'Estoque baixo',
      IntCellValue(report.lowStockCount),
      report.lowStockCount > 0 ? _orange : _green,
    );

    _appendMetricRow(
      sheet,
      'Produtos vencidos',
      IntCellValue(report.expiredItemsCount),
      report.expiredItemsCount > 0 ? _red : _green,
    );

    _appendMetricRow(
      sheet,
      'Tarefas atrasadas',
      IntCellValue(report.overdueTasksCount),
      report.overdueTasksCount > 0 ? _red : _green,
    );

    _appendMetricRow(
      sheet,
      'Tarefas urgentes',
      IntCellValue(report.urgentTasksCount),
      report.urgentTasksCount > 0 ? _red : _green,
    );

    _appendSectionHeader(sheet, 'Observação gerencial', columns: 6);

    final insightRow = sheet.maxRows;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: insightRow),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: insightRow + 2),
      customValue: TextCellValue(buildManagementInsight(report)),
    );

    _styleRange(
      sheet: sheet,
      startRow: insightRow,
      endRow: insightRow + 2,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _lightGreen,
        fontColorHex: _darkText,
        textWrapping: TextWrapping.WrapText,
        verticalAlign: VerticalAlign.Center,
      ),
    );

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
  }

  void _buildExpenseCategoriesSheet({
    required Excel excel,
    required ReportPdfData report,
  }) {
    final sheet = excel['Despesas por categoria'];

    _appendTitle(sheet, 'Despesas por categoria', columns: 4);

    _appendTableHeader(sheet, [
      'Posição',
      'Categoria',
      'Valor',
      'Participação',
    ]);

    for (var index = 0; index < report.expenseCategories.length; index++) {
      final category = report.expenseCategories[index];

      final participation = report.totalExpenses <= 0
          ? 0.0
          : category.value / report.totalExpenses;

      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        IntCellValue(index + 1),
        TextCellValue(category.name),
        DoubleCellValue(category.value),
        DoubleCellValue(participation),
      ]);

      _applyCurrencyFormat(
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        ),
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        numberFormat: CustomNumericNumFormat(formatCode: '0.0%'),
      );
    }

    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 18);
  }

  void _buildFinancialRankingSheet({
    required Excel excel,
    required ReportPdfData report,
  }) {
    final sheet = excel['Ranking financeiro'];

    _appendTitle(sheet, 'Ranking financeiro', columns: 5);

    _appendTableHeader(sheet, [
      'Posição',
      'Propriedade',
      'Cidade',
      'Estado',
      'Resultado',
    ]);

    for (var index = 0; index < report.financialRanking.length; index++) {
      final farm = report.financialRanking[index];
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        IntCellValue(index + 1),
        TextCellValue(farm.name),
        TextCellValue(farm.city),
        TextCellValue(farm.state),
        DoubleCellValue(farm.balance),
      ]);

      final resultCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
      );

      resultCell.cellStyle = CellStyle(
        fontColorHex: farm.balance >= 0 ? _green : _red,
        bold: true,
        numberFormat: _currencyFormat(),
      );
    }

    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 32);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 20);
  }

  void _buildInventoryRankingSheet({
    required Excel excel,
    required ReportPdfData report,
  }) {
    final sheet = excel['Ranking de estoque'];

    _appendTitle(sheet, 'Ranking de estoque', columns: 5);

    _appendTableHeader(sheet, [
      'Posição',
      'Propriedade',
      'Cidade',
      'Estado',
      'Valor do estoque',
    ]);

    for (var index = 0; index < report.inventoryRanking.length; index++) {
      final farm = report.inventoryRanking[index];
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        IntCellValue(index + 1),
        TextCellValue(farm.name),
        TextCellValue(farm.city),
        TextCellValue(farm.state),
        DoubleCellValue(farm.inventoryValue),
      ]);

      final valueCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
      );

      valueCell.cellStyle = CellStyle(
        fontColorHex: _blue,
        bold: true,
        numberFormat: _currencyFormat(),
      );
    }

    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 32);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 22);
  }

  void _buildAlertsSheet({
    required Excel excel,
    required ReportPdfData report,
  }) {
    final sheet = excel['Alertas'];

    _appendTitle(sheet, 'Alertas operacionais', columns: 4);

    _appendTableHeader(sheet, [
      'Indicador',
      'Quantidade',
      'Descrição',
      'Situação',
    ]);

    final alerts = [
      _ExcelAlert(
        title: 'Estoque baixo',
        value: report.lowStockCount,
        description: 'Produtos no estoque mínimo ou abaixo.',
        severity: report.lowStockCount > 0
            ? _ExcelAlertSeverity.warning
            : _ExcelAlertSeverity.normal,
      ),
      _ExcelAlert(
        title: 'Produtos vencidos',
        value: report.expiredItemsCount,
        description: 'Produtos cadastrados fora da validade.',
        severity: report.expiredItemsCount > 0
            ? _ExcelAlertSeverity.critical
            : _ExcelAlertSeverity.normal,
      ),
      _ExcelAlert(
        title: 'Tarefas atrasadas',
        value: report.overdueTasksCount,
        description: 'Compromissos da agenda fora do prazo.',
        severity: report.overdueTasksCount > 0
            ? _ExcelAlertSeverity.critical
            : _ExcelAlertSeverity.normal,
      ),
      _ExcelAlert(
        title: 'Tarefas urgentes',
        value: report.urgentTasksCount,
        description: 'Prioridades urgentes ainda abertas.',
        severity: report.urgentTasksCount > 0
            ? _ExcelAlertSeverity.critical
            : _ExcelAlertSeverity.normal,
      ),
    ];

    for (final alert in alerts) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(alert.title),
        IntCellValue(alert.value),
        TextCellValue(alert.description),
        TextCellValue(_alertLabel(alert.severity)),
      ]);

      final color = _alertColor(alert.severity);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 46);
    sheet.setColumnWidth(3, 16);
  }

  void _buildDiagnosisSheet({
    required Excel excel,
    required ReportPdfData report,
  }) {
    final sheet = excel['Diagnóstico'];

    _appendTitle(sheet, 'Diagnóstico gerencial Atlas', columns: 6);

    _appendTableHeader(sheet, [
      'Prioridade',
      'Diagnóstico',
      'Situação',
      'Descrição',
      'Recomendação',
      'Responsável sugerido',
    ]);

    final insights = buildExcelManagementInsights(report);

    for (var index = 0; index < insights.length; index++) {
      final insight = insights[index];
      final rowIndex = sheet.maxRows;
      final color = excelInsightColor(insight.severity);

      sheet.appendRow([
        IntCellValue(index + 1),
        TextCellValue(insight.title),
        TextCellValue(excelInsightSeverityLabel(insight.severity)),
        TextCellValue(insight.message),
        TextCellValue(insight.recommendation),
        TextCellValue(excelSuggestedResponsible(insight.title)),
      ]);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
        textWrapping: TextWrapping.WrapText,
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      for (final columnIndex in [3, 4, 5]) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = CellStyle(
          textWrapping: TextWrapping.WrapText,
          verticalAlign: VerticalAlign.Top,
        );
      }
    }

    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 48);
    sheet.setColumnWidth(4, 58);
    sheet.setColumnWidth(5, 28);
  }

  void _buildActionPlanSheet({
    required Excel excel,
    required ReportPdfData report,
  }) {
    final sheet = excel['Plano de ação'];

    _appendTitle(sheet, 'Plano de ação gerencial', columns: 7);

    _appendTableHeader(sheet, [
      'Nº',
      'Problema',
      'Ação recomendada',
      'Prazo',
      'Classificação',
      'Responsável',
      'Status',
    ]);

    final actions = buildExcelManagementInsights(
      report,
    ).map(ExcelActionPlanItem.fromInsight).toList();

    for (var index = 0; index < actions.length; index++) {
      final action = actions[index];
      final rowIndex = sheet.maxRows;
      final color = excelActionDeadlineColor(action.deadline);

      sheet.appendRow([
        IntCellValue(index + 1),
        TextCellValue(action.title),
        TextCellValue(action.action),
        TextCellValue(action.deadlineText),
        TextCellValue(excelActionDeadlineLabel(action.deadline)),
        TextCellValue(action.responsible),
        TextCellValue('Pendente'),
      ]);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
        textWrapping: TextWrapping.WrapText,
      );

      for (final columnIndex in [2, 5]) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = CellStyle(
          textWrapping: TextWrapping.WrapText,
          verticalAlign: VerticalAlign.Top,
        );
      }

      for (final columnIndex in [3, 4]) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = CellStyle(
          fontColorHex: color,
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        backgroundColorHex: _gray,
        fontColorHex: _darkText,
        horizontalAlign: HorizontalAlign.Center,
        bold: true,
      );
    }

    sheet.setColumnWidth(0, 10);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 58);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 28);
    sheet.setColumnWidth(6, 16);
  }

  void _buildPropertiesSheet({
    required Excel excel,
    required ReportPdfData report,
  }) {
    final sheet = excel['Propriedades'];

    _appendTitle(sheet, 'Resultado por propriedade', columns: 15);

    _appendTableHeader(sheet, [
      'Propriedade',
      'Cidade',
      'Estado',
      'Área (ha)',
      'Receitas',
      'Despesas',
      'Resultado',
      'Valor do estoque',
      'Produtos',
      'Estoque baixo',
      'Vencidos',
      'Pendentes',
      'Atrasadas',
      'Urgentes',
      'Situação financeira',
    ]);

    for (final farm in report.farms) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(farm.name),
        TextCellValue(farm.city),
        TextCellValue(farm.state),
        DoubleCellValue(farm.area),
        DoubleCellValue(farm.income),
        DoubleCellValue(farm.expenses),
        DoubleCellValue(farm.balance),
        DoubleCellValue(farm.inventoryValue),
        IntCellValue(farm.inventoryItemsCount),
        IntCellValue(farm.lowStockCount),
        IntCellValue(farm.expiredItemsCount),
        IntCellValue(farm.pendingTasksCount),
        IntCellValue(farm.overdueTasksCount),
        IntCellValue(farm.urgentTasksCount),
        TextCellValue(farm.balance >= 0 ? 'POSITIVA' : 'NEGATIVA'),
      ]);

      for (final columnIndex in [4, 5, 6, 7]) {
        _applyCurrencyFormat(
          sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: columnIndex,
              rowIndex: rowIndex,
            ),
          ),
        );
      }

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: farm.balance >= 0 ? _green : _red,
        bold: true,
        numberFormat: _currencyFormat(),
      );
    }

    final widths = [
      30.0,
      20.0,
      10.0,
      12.0,
      18.0,
      18.0,
      18.0,
      20.0,
      12.0,
      14.0,
      12.0,
      12.0,
      12.0,
      12.0,
      18.0,
    ];

    for (var index = 0; index < widths.length; index++) {
      sheet.setColumnWidth(index, widths[index]);
    }
  }

  void _buildFarmSheet({required Excel excel, required FarmPdfSummary farm}) {
    final sheetName = _safeSheetName(farm.name, excel.tables.keys.toSet());

    final sheet = excel[sheetName];

    _appendTitle(sheet, farm.name, columns: 4);

    _appendLabelValue(sheet, 'Cidade', farm.city);

    _appendLabelValue(sheet, 'Estado', farm.state);

    _appendLabelValue(sheet, 'Área', '${_formatNumber(farm.area)} hectares');

    _appendSectionHeader(sheet, 'Resumo financeiro', columns: 4);

    _appendFarmValue(sheet, 'Receitas', farm.income, _green);

    _appendFarmValue(sheet, 'Despesas', farm.expenses, _red);

    _appendFarmValue(
      sheet,
      'Resultado',
      farm.balance,
      farm.balance >= 0 ? _green : _red,
    );

    _appendFarmValue(sheet, 'Valor do estoque', farm.inventoryValue, _blue);

    _appendSectionHeader(sheet, 'Indicadores operacionais', columns: 4);

    final operationalRows = [
      ['Produtos', farm.inventoryItemsCount],
      ['Estoque baixo', farm.lowStockCount],
      ['Produtos vencidos', farm.expiredItemsCount],
      ['Tarefas pendentes', farm.pendingTasksCount],
      ['Tarefas atrasadas', farm.overdueTasksCount],
      ['Tarefas urgentes', farm.urgentTasksCount],
    ];

    for (final row in operationalRows) {
      sheet.appendRow([
        TextCellValue(row[0] as String),
        IntCellValue(row[1] as int),
      ]);
    }

    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
  }

  void _appendTitle(Sheet sheet, String title, {required int columns}) {
    final rowIndex = sheet.maxRows;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: columns - 1, rowIndex: rowIndex),
      customValue: TextCellValue(title),
    );

    _styleRange(
      sheet: sheet,
      startRow: rowIndex,
      endRow: rowIndex,
      startColumn: 0,
      endColumn: columns - 1,
      style: _titleStyle(),
    );
  }

  void _appendSectionHeader(Sheet sheet, String title, {required int columns}) {
    final rowIndex = sheet.maxRows;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: columns - 1, rowIndex: rowIndex),
      customValue: TextCellValue(title),
    );

    _styleRange(
      sheet: sheet,
      startRow: rowIndex,
      endRow: rowIndex,
      startColumn: 0,
      endColumn: columns - 1,
      style: CellStyle(
        backgroundColorHex: _lightGreen,
        fontColorHex: _green,
        bold: true,
      ),
    );
  }

  void _appendTableHeader(Sheet sheet, List<String> headers) {
    final rowIndex = sheet.maxRows;

    sheet.appendRow(headers.map<CellValue>(TextCellValue.new).toList());

    _styleRange(
      sheet: sheet,
      startRow: rowIndex,
      endRow: rowIndex,
      startColumn: 0,
      endColumn: headers.length - 1,
      style: _headerStyle(),
    );
  }

  void _appendLabelValue(Sheet sheet, String label, String value) {
    final rowIndex = sheet.maxRows;

    sheet.appendRow([TextCellValue(label), TextCellValue(value)]);

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      backgroundColorHex: _gray,
      fontColorHex: _darkText,
      bold: true,
    );
  }

  void _appendMetricRow(
    Sheet sheet,
    String label,
    CellValue value,
    ExcelColor color, {
    bool currency = false,
  }) {
    final rowIndex = sheet.maxRows;

    sheet.appendRow([TextCellValue(label), value]);

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      backgroundColorHex: _gray,
      fontColorHex: _darkText,
      bold: true,
    );

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      fontColorHex: color,
      bold: true,
      numberFormat: currency ? _currencyFormat() : NumFormat.standard_0,
    );
  }

  void _appendFarmValue(
    Sheet sheet,
    String label,
    double value,
    ExcelColor color,
  ) {
    final rowIndex = sheet.maxRows;

    sheet.appendRow([TextCellValue(label), DoubleCellValue(value)]);

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      backgroundColorHex: _gray,
      fontColorHex: _darkText,
      bold: true,
    );

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      fontColorHex: color,
      bold: true,
      numberFormat: _currencyFormat(),
    );
  }

  void _styleRange({
    required Sheet sheet,
    required int startRow,
    required int endRow,
    required int startColumn,
    required int endColumn,
    required CellStyle style,
  }) {
    for (var row = startRow; row <= endRow; row++) {
      for (var column = startColumn; column <= endColumn; column++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: row,
                  ),
                )
                .cellStyle =
            style;
      }
    }
  }

  void _applyCurrencyFormat(Data cell) {
    cell.cellStyle = CellStyle(numberFormat: _currencyFormat());
  }

  CellStyle _titleStyle() {
    return CellStyle(
      backgroundColorHex: _green,
      fontColorHex: _white,
      fontSize: 16,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  CellStyle _subtitleStyle() {
    return CellStyle(
      backgroundColorHex: _lightGreen,
      fontColorHex: _green,
      fontSize: 12,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  CellStyle _headerStyle() {
    return CellStyle(
      backgroundColorHex: _green,
      fontColorHex: _white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
  }

  CustomNumericNumFormat _currencyFormat() {
    return CustomNumericNumFormat(
      formatCode: 'R\$ #,##0.00;[Red]-R\$ #,##0.00',
    );
  }

  String _createFileName(ReportPdfData report) {
    final farmName = report.farmFilter.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    final date = report.issueDate.replaceAll('/', '-').replaceAll(' ', '_');

    return 'relatorio_atlas_${farmName}_$date.xlsx';
  }

  String _safeSheetName(String name, Set<String> existingNames) {
    var safeName = name.replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ').trim();

    if (safeName.isEmpty) {
      safeName = 'Fazenda';
    }

    if (safeName.length > 31) {
      safeName = safeName.substring(0, 31);
    }

    var candidate = safeName;
    var suffix = 2;

    while (existingNames.contains(candidate)) {
      final suffixText = ' $suffix';
      final maximumBaseLength = 31 - suffixText.length;

      final baseName = safeName.length > maximumBaseLength
          ? safeName.substring(0, maximumBaseLength)
          : safeName;

      candidate = '$baseName$suffixText';
      suffix++;
    }

    return candidate;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  ExcelColor _alertColor(_ExcelAlertSeverity severity) {
    switch (severity) {
      case _ExcelAlertSeverity.normal:
        return _green;
      case _ExcelAlertSeverity.warning:
        return _orange;
      case _ExcelAlertSeverity.critical:
        return _red;
    }
  }

  String _alertLabel(_ExcelAlertSeverity severity) {
    switch (severity) {
      case _ExcelAlertSeverity.normal:
        return 'NORMAL';
      case _ExcelAlertSeverity.warning:
        return 'ATENÇÃO';
      case _ExcelAlertSeverity.critical:
        return 'CRÍTICO';
    }
  }
}

class ExcelManagementInsight {
  const ExcelManagementInsight({
    required this.title,
    required this.message,
    required this.recommendation,
    required this.severity,
    required this.priority,
  });

  final String title;
  final String message;
  final String recommendation;
  final ExcelInsightSeverity severity;
  final int priority;
}

enum ExcelInsightSeverity { normal, warning, critical }

enum ExcelActionDeadline { immediate, shortTerm, monitoring }

class ExcelActionPlanItem {
  const ExcelActionPlanItem({
    required this.title,
    required this.action,
    required this.deadline,
    required this.deadlineText,
    required this.responsible,
  });

  factory ExcelActionPlanItem.fromInsight(ExcelManagementInsight insight) {
    final deadline = excelDeadlineFromInsight(insight);

    return ExcelActionPlanItem(
      title: insight.title,
      action: insight.recommendation,
      deadline: deadline,
      deadlineText: excelSuggestedDeadlineText(deadline),
      responsible: excelSuggestedResponsible(insight.title),
    );
  }

  final String title;
  final String action;
  final ExcelActionDeadline deadline;
  final String deadlineText;
  final String responsible;
}

List<ExcelManagementInsight> buildExcelManagementInsights(
  ReportPdfData report,
) {
  final insights = <ExcelManagementInsight>[];

  final negativeFarms = report.farms.where((farm) {
    return farm.balance < 0;
  }).length;

  if (report.totalBalance < 0) {
    insights.add(
      ExcelManagementInsight(
        title: 'Resultado financeiro negativo',
        message:
            'As despesas superaram as receitas em '
            '${formatCurrency(report.totalBalance.abs())}.',
        recommendation:
            'Revisar os maiores centros de custo, adiar gastos não essenciais '
            'e elaborar um plano de recuperação do caixa.',
        severity: ExcelInsightSeverity.critical,
        priority: 100,
      ),
    );
  }

  if (report.totalIncome == 0 && report.totalExpenses > 0) {
    insights.add(
      const ExcelManagementInsight(
        title: 'Ausência de receitas no período',
        message:
            'Foram registradas despesas, mas nenhuma receita foi identificada.',
        recommendation:
            'Verificar se as vendas e demais entradas foram cadastradas '
            'e revisar o planejamento comercial da propriedade.',
        severity: ExcelInsightSeverity.critical,
        priority: 95,
      ),
    );
  }

  if (report.overdueTasksCount > 0) {
    insights.add(
      ExcelManagementInsight(
        title: 'Atividades atrasadas',
        message:
            '${report.overdueTasksCount} '
            '${report.overdueTasksCount == 1 ? 'atividade está' : 'atividades estão'} '
            'fora do prazo.',
        recommendation:
            'Reorganizar a agenda, definir responsáveis e concluir primeiro '
            'as tarefas de maior impacto sanitário ou produtivo.',
        severity: ExcelInsightSeverity.critical,
        priority: 88,
      ),
    );
  }

  if (report.urgentTasksCount > 0) {
    insights.add(
      ExcelManagementInsight(
        title: 'Prioridades urgentes abertas',
        message:
            '${report.urgentTasksCount} '
            '${report.urgentTasksCount == 1 ? 'tarefa urgente permanece aberta' : 'tarefas urgentes permanecem abertas'}.',
        recommendation:
            'Confirmar imediatamente responsáveis, materiais necessários '
            'e prazos de execução.',
        severity: ExcelInsightSeverity.critical,
        priority: 86,
      ),
    );
  }

  if (report.expiredItemsCount > 0) {
    insights.add(
      ExcelManagementInsight(
        title: 'Produtos vencidos no estoque',
        message:
            '${report.expiredItemsCount} '
            '${report.expiredItemsCount == 1 ? 'produto vencido foi identificado' : 'produtos vencidos foram identificados'}.',
        recommendation:
            'Separar os itens, registrar a destinação correta e revisar '
            'o controle de validade do estoque.',
        severity: ExcelInsightSeverity.critical,
        priority: 84,
      ),
    );
  }

  if (negativeFarms > 0) {
    insights.add(
      ExcelManagementInsight(
        title: 'Propriedades com resultado negativo',
        message:
            '$negativeFarms de ${report.farms.length} '
            '${negativeFarms == 1 ? 'propriedade apresenta' : 'propriedades apresentam'} '
            'resultado financeiro negativo.',
        recommendation:
            'Analisar as propriedades separadamente, comparar custos por '
            'hectare e definir planos de ação específicos.',
        severity: negativeFarms == report.farms.length
            ? ExcelInsightSeverity.critical
            : ExcelInsightSeverity.warning,
        priority: 75,
      ),
    );
  }

  if (report.lowStockCount > 0) {
    insights.add(
      ExcelManagementInsight(
        title: 'Produtos com estoque baixo',
        message:
            '${report.lowStockCount} '
            '${report.lowStockCount == 1 ? 'produto está' : 'produtos estão'} '
            'no nível mínimo ou abaixo.',
        recommendation:
            'Avaliar a reposição conforme o calendário sanitário, nutricional '
            'e operacional.',
        severity: ExcelInsightSeverity.warning,
        priority: 65,
      ),
    );
  }

  if (insights.isEmpty) {
    insights.add(
      const ExcelManagementInsight(
        title: 'Operação sem pendências críticas',
        message:
            'Os dados do relatório não apresentam alertas financeiros, '
            'operacionais ou de estoque relevantes.',
        recommendation:
            'Manter os registros atualizados e acompanhar periodicamente '
            'os indicadores da operação.',
        severity: ExcelInsightSeverity.normal,
        priority: 10,
      ),
    );
  }

  insights.sort((first, second) => second.priority.compareTo(first.priority));

  return insights.take(6).toList();
}

ExcelActionDeadline excelDeadlineFromInsight(ExcelManagementInsight insight) {
  if (insight.severity == ExcelInsightSeverity.critical ||
      insight.priority >= 85) {
    return ExcelActionDeadline.immediate;
  }

  if (insight.severity == ExcelInsightSeverity.warning ||
      insight.priority >= 60) {
    return ExcelActionDeadline.shortTerm;
  }

  return ExcelActionDeadline.monitoring;
}

String excelSuggestedDeadlineText(ExcelActionDeadline deadline) {
  switch (deadline) {
    case ExcelActionDeadline.immediate:
      return 'Até 48 horas';
    case ExcelActionDeadline.shortTerm:
      return 'Até 7 dias';
    case ExcelActionDeadline.monitoring:
      return 'Próxima revisão';
  }
}

String excelActionDeadlineLabel(ExcelActionDeadline deadline) {
  switch (deadline) {
    case ExcelActionDeadline.immediate:
      return 'IMEDIATA';
    case ExcelActionDeadline.shortTerm:
      return 'CURTO PRAZO';
    case ExcelActionDeadline.monitoring:
      return 'ACOMPANHAR';
  }
}

String excelSuggestedResponsible(String title) {
  final normalized = title.toLowerCase();

  if (normalized.contains('financeir') ||
      normalized.contains('receita') ||
      normalized.contains('despesa')) {
    return 'Gestor financeiro';
  }

  if (normalized.contains('estoque') || normalized.contains('produto')) {
    return 'Responsável pelo estoque';
  }

  if (normalized.contains('atividade') ||
      normalized.contains('tarefa') ||
      normalized.contains('prioridade')) {
    return 'Gerente da fazenda';
  }

  if (normalized.contains('propriedade')) {
    return 'Consultor e gestor';
  }

  return 'Gestor responsável';
}

ExcelColor excelInsightColor(ExcelInsightSeverity severity) {
  switch (severity) {
    case ExcelInsightSeverity.normal:
      return ExcelColor.fromHexString('#1B5E20');
    case ExcelInsightSeverity.warning:
      return ExcelColor.fromHexString('#EF6C00');
    case ExcelInsightSeverity.critical:
      return ExcelColor.fromHexString('#C62828');
  }
}

String excelInsightSeverityLabel(ExcelInsightSeverity severity) {
  switch (severity) {
    case ExcelInsightSeverity.normal:
      return 'POSITIVO';
    case ExcelInsightSeverity.warning:
      return 'ATENÇÃO';
    case ExcelInsightSeverity.critical:
      return 'CRÍTICO';
  }
}

ExcelColor excelActionDeadlineColor(ExcelActionDeadline deadline) {
  switch (deadline) {
    case ExcelActionDeadline.immediate:
      return ExcelColor.fromHexString('#C62828');
    case ExcelActionDeadline.shortTerm:
      return ExcelColor.fromHexString('#EF6C00');
    case ExcelActionDeadline.monitoring:
      return ExcelColor.fromHexString('#1565C0');
  }
}

class _ExcelAlert {
  const _ExcelAlert({
    required this.title,
    required this.value,
    required this.description,
    required this.severity,
  });

  final String title;
  final int value;
  final String description;
  final _ExcelAlertSeverity severity;
}

enum _ExcelAlertSeverity { normal, warning, critical }
