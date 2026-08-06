import 'package:excel/excel.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/executive_dashboard_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/executive_opinion_service.dart';

class ExecutiveDashboardExcelService {
  static final ExcelColor _green = ExcelColor.fromHexString('#1B5E20');

  static final ExcelColor _darkGreen = ExcelColor.fromHexString('#124317');

  static final ExcelColor _blue = ExcelColor.fromHexString('#1565C0');

  static final ExcelColor _orange = ExcelColor.fromHexString('#EF6C00');

  static final ExcelColor _red = ExcelColor.fromHexString('#C62828');

  static final ExcelColor _purple = ExcelColor.fromHexString('#6A1B9A');

  static final ExcelColor _teal = ExcelColor.fromHexString('#00838F');

  static final ExcelColor _gray = ExcelColor.fromHexString('#607D8B');

  static final ExcelColor _lightGray = ExcelColor.fromHexString('#F2F4F5');

  static final ExcelColor _white = ExcelColor.fromHexString('#FFFFFF');

  static final ExcelColor _darkText = ExcelColor.fromHexString('#263238');

  Future<void> exportDashboard({
    required ExecutiveDashboardData dashboard,
    required ExecutiveOpinionData opinion,
  }) async {
    final excel = Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();

    if (defaultSheet != null && defaultSheet != 'Resumo Executivo') {
      excel.rename(defaultSheet, 'Resumo Executivo');
    }

    _buildSummarySheet(excel: excel, dashboard: dashboard, opinion: opinion);

    _buildKpisSheet(excel: excel, dashboard: dashboard);

    _buildAlertsSheet(excel: excel, dashboard: dashboard);

    _buildRankingsSheet(excel: excel, dashboard: dashboard);

    _buildEvolutionSheet(excel: excel, dashboard: dashboard);

    _buildOpinionSheet(excel: excel, opinion: opinion);

    excel.setDefaultSheet('Resumo Executivo');

    excel.save(fileName: buildExecutiveDashboardExcelFileName(dashboard));
  }

  void _buildSummarySheet({
    required Excel excel,
    required ExecutiveDashboardData dashboard,
    required ExecutiveOpinionData opinion,
  }) {
    final sheet = excel['Resumo Executivo'];

    _appendTitle(sheet: sheet, title: 'PROJETO ATLAS', columns: 6);

    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('F2'),
      customValue: TextCellValue('Dashboard Executivo'),
    );

    _styleRange(
      sheet: sheet,
      startRow: 1,
      endRow: 1,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _lightGray,
        fontColorHex: _green,
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      ),
    );

    sheet.appendRow([
      TextCellValue('Escopo'),
      TextCellValue(dashboard.scopeLabel),
      TextCellValue('Gerado em'),
      TextCellValue(dashboard.generatedAt),
      TextCellValue('Classificação'),
      TextCellValue(executiveClassificationLabel(opinion.classification)),
    ]);

    _styleRange(
      sheet: sheet,
      startRow: 2,
      endRow: 2,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _lightGray,
        fontColorHex: _darkText,
        bold: true,
        textWrapping: TextWrapping.WrapText,
        verticalAlign: VerticalAlign.Center,
      ),
    );

    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('Indicador'),
      TextCellValue('Valor'),
      TextCellValue('Indicador'),
      TextCellValue('Valor'),
      TextCellValue('Indicador'),
      TextCellValue('Valor'),
    ]);

    _styleRange(
      sheet: sheet,
      startRow: 4,
      endRow: 4,
      startColumn: 0,
      endColumn: 5,
      style: _headerStyle(),
    );

    final total = dashboard.findKpi('total_actions');

    final open = dashboard.findKpi('open_actions');

    final completed = dashboard.findKpi('completed_actions');

    final completion = dashboard.findKpi('completion_rate');

    final overdue = dashboard.findKpi('overdue_actions');

    final urgent = dashboard.findKpi('urgent_actions');

    sheet.appendRow([
      TextCellValue('Total de ações'),
      TextCellValue(total?.value ?? '0'),
      TextCellValue('Ações abertas'),
      TextCellValue(open?.value ?? '0'),
      TextCellValue('Ações concluídas'),
      TextCellValue(completed?.value ?? '0'),
    ]);

    sheet.appendRow([
      TextCellValue('Taxa de conclusão'),
      TextCellValue(completion?.value ?? '0%'),
      TextCellValue('Ações atrasadas'),
      TextCellValue(overdue?.value ?? '0'),
      TextCellValue('Ações urgentes'),
      TextCellValue(urgent?.value ?? '0'),
    ]);

    sheet.appendRow([
      TextCellValue('Índice geral'),
      TextCellValue(dashboard.generalPerformanceIndex.toStringAsFixed(0)),
      TextCellValue('Confiança do parecer'),
      TextCellValue(formatOpinionPercentage(opinion.confidence)),
      TextCellValue('Alertas'),
      IntCellValue(dashboard.alerts.length),
    ]);

    _styleMetricValue(sheet: sheet, rowIndex: 5, columnIndex: 1, color: _blue);

    _styleMetricValue(
      sheet: sheet,
      rowIndex: 5,
      columnIndex: 3,
      color: _orange,
    );

    _styleMetricValue(sheet: sheet, rowIndex: 5, columnIndex: 5, color: _green);

    _styleMetricValue(
      sheet: sheet,
      rowIndex: 6,
      columnIndex: 1,
      color: _indicatorColor(
        completion?.status ?? ExecutiveIndicatorStatus.normal,
      ),
    );

    _styleMetricValue(
      sheet: sheet,
      rowIndex: 6,
      columnIndex: 3,
      color: _indicatorColor(
        overdue?.status ?? ExecutiveIndicatorStatus.normal,
      ),
    );

    _styleMetricValue(
      sheet: sheet,
      rowIndex: 6,
      columnIndex: 5,
      color: _indicatorColor(urgent?.status ?? ExecutiveIndicatorStatus.normal),
    );

    _styleMetricValue(
      sheet: sheet,
      rowIndex: 7,
      columnIndex: 1,
      color: _classificationColor(opinion.classification),
    );

    _styleMetricValue(sheet: sheet, rowIndex: 7, columnIndex: 3, color: _blue);

    _styleMetricValue(
      sheet: sheet,
      rowIndex: 7,
      columnIndex: 5,
      color: dashboard.alerts.any((item) => item.isCritical) ? _red : _green,
    );

    sheet.appendRow([]);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheet.maxRows),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: sheet.maxRows),
      customValue: TextCellValue(opinion.diagnosis),
    );

    final diagnosisRow = sheet.maxRows - 1;

    _styleRange(
      sheet: sheet,
      startRow: diagnosisRow,
      endRow: diagnosisRow,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _classificationBackgroundColor(
          opinion.classification,
        ),
        fontColorHex: _classificationColor(opinion.classification),
        bold: true,
        textWrapping: TextWrapping.WrapText,
        verticalAlign: VerticalAlign.Top,
      ),
    );

    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('Tendência'),
      TextCellValue('Direção'),
      TextCellValue('Valor atual'),
      TextCellValue('Valor anterior'),
      TextCellValue('Variação'),
      TextCellValue('Interpretação'),
    ]);

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 5,
      style: _headerStyle(),
    );

    _appendTrendRow(sheet: sheet, trend: dashboard.productivityTrend);

    _appendTrendRow(sheet: sheet, trend: dashboard.delayTrend);

    sheet.setColumnWidth(0, 26);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 24);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 24);
    sheet.setColumnWidth(5, 44);
  }

  void _buildKpisSheet({
    required Excel excel,
    required ExecutiveDashboardData dashboard,
  }) {
    final sheet = excel['KPIs'];

    _appendTitle(sheet: sheet, title: 'Indicadores Executivos', columns: 9);

    _appendTableHeader(
      sheet: sheet,
      headers: [
        'ID',
        'Indicador',
        'Valor exibido',
        'Valor numérico',
        'Tipo',
        'Status',
        'Subtítulo',
        'Variação',
        'Descrição da variação',
      ],
    );

    for (final kpi in dashboard.kpis) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(kpi.id),
        TextCellValue(kpi.title),
        TextCellValue(kpi.value),
        DoubleCellValue(kpi.numericValue),
        TextCellValue(kpi.type.name),
        TextCellValue(kpi.status.name),
        TextCellValue(kpi.subtitle),
        DoubleCellValue(kpi.change),
        TextCellValue(kpi.changeLabel),
      ]);

      final color = _indicatorColor(kpi.status);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      for (final columnIndex in [1, 6, 8]) {
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

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 42);
    sheet.setColumnWidth(7, 16);
    sheet.setColumnWidth(8, 34);
  }

  void _buildAlertsSheet({
    required Excel excel,
    required ExecutiveDashboardData dashboard,
  }) {
    final sheet = excel['Alertas'];

    _appendTitle(sheet: sheet, title: 'Alertas Executivos', columns: 8);

    _appendTableHeader(
      sheet: sheet,
      headers: [
        'ID',
        'Título',
        'Mensagem',
        'Categoria',
        'Severidade',
        'Quantidade',
        'Ação sugerida',
        'Rota',
      ],
    );

    for (final alert in dashboard.alerts) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(alert.id),
        TextCellValue(alert.title),
        TextCellValue(alert.message),
        TextCellValue(alert.category),
        TextCellValue(alert.severity.name),
        IntCellValue(alert.count),
        TextCellValue(alert.actionLabel),
        TextCellValue(alert.route),
      ]);

      final color = _alertColor(alert.severity);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      for (final columnIndex in [1, 2, 6]) {
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

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 52);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 34);
    sheet.setColumnWidth(7, 24);
  }

  void _buildRankingsSheet({
    required Excel excel,
    required ExecutiveDashboardData dashboard,
  }) {
    final sheet = excel['Rankings'];

    _appendTitle(sheet: sheet, title: 'Rankings Executivos', columns: 7);

    _appendRankingBlock(
      sheet: sheet,
      title: 'Ranking por responsável',
      category: 'Responsável',
      items: dashboard.responsibleRanking,
    );

    sheet.appendRow([]);

    _appendRankingBlock(
      sheet: sheet,
      title: 'Ranking por fazenda',
      category: 'Fazenda',
      items: dashboard.farmRanking,
    );

    sheet.appendRow([]);

    _appendRankingBlock(
      sheet: sheet,
      title: 'Ranking por prioridade',
      category: 'Prioridade',
      items: dashboard.priorityRanking,
    );

    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('Distribuição por status')]);

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 6,
      style: _sectionStyle(),
    );

    _appendTableHeader(
      sheet: sheet,
      headers: [
        'Categoria',
        'Status',
        'Quantidade',
        'Percentual',
        'Classificação',
        '',
        '',
      ],
    );

    for (final item in dashboard.statusDistribution) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(item.category),
        TextCellValue(item.label),
        DoubleCellValue(item.value),
        TextCellValue(formatOpinionPercentage(item.percentage)),
        TextCellValue(item.status.name),
        TextCellValue(''),
        TextCellValue(''),
      ]);

      final color = _indicatorColor(item.status);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
      );
    }

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 18);
  }

  void _buildEvolutionSheet({
    required Excel excel,
    required ExecutiveDashboardData dashboard,
  }) {
    final sheet = excel['Evolução'];

    _appendTitle(sheet: sheet, title: 'Evolução Executiva', columns: 7);

    _appendEvolutionBlock(
      sheet: sheet,
      title: 'Evolução mensal',
      points: dashboard.monthlyEvolution,
    );

    sheet.appendRow([]);

    _appendEvolutionBlock(
      sheet: sheet,
      title: 'Evolução semanal',
      points: dashboard.weeklyEvolution,
    );

    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 18);
  }

  void _buildOpinionSheet({
    required Excel excel,
    required ExecutiveOpinionData opinion,
  }) {
    final sheet = excel['Parecer Executivo'];

    _appendTitle(
      sheet: sheet,
      title: 'Parecer Executivo Inteligente',
      columns: 6,
    );

    sheet.appendRow([
      TextCellValue('Escopo'),
      TextCellValue(opinion.scopeLabel),
      TextCellValue('Classificação'),
      TextCellValue(executiveClassificationLabel(opinion.classification)),
      TextCellValue('Índice geral'),
      TextCellValue(opinion.performanceIndex.toStringAsFixed(0)),
    ]);

    sheet.appendRow([
      TextCellValue('Gerado em'),
      TextCellValue(opinion.generatedAt),
      TextCellValue('Confiança'),
      TextCellValue(formatOpinionPercentage(opinion.confidence)),
      TextCellValue('Riscos críticos'),
      TextCellValue(opinion.hasCriticalRisks ? 'Sim' : 'Não'),
    ]);

    _styleRange(
      sheet: sheet,
      startRow: 1,
      endRow: 2,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _lightGray,
        fontColorHex: _darkText,
        bold: true,
        textWrapping: TextWrapping.WrapText,
      ),
    );

    sheet.appendRow([]);

    _appendTextSection(
      sheet: sheet,
      title: 'Diagnóstico geral',
      text: opinion.diagnosis,
      color: _blue,
    );

    sheet.appendRow([]);

    _appendOpinionItemsSection(
      sheet: sheet,
      title: 'Pontos fortes',
      items: opinion.strengths,
      color: _green,
    );

    sheet.appendRow([]);

    _appendOpinionItemsSection(
      sheet: sheet,
      title: 'Gargalos',
      items: opinion.bottlenecks,
      color: _orange,
    );

    sheet.appendRow([]);

    _appendOpinionItemsSection(
      sheet: sheet,
      title: 'Riscos',
      items: opinion.risks,
      color: _red,
    );

    sheet.appendRow([]);

    _appendOpinionItemsSection(
      sheet: sheet,
      title: 'Oportunidades',
      items: opinion.opportunities,
      color: _teal,
    );

    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('Plano de prioridades')]);

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 5,
      style: _sectionStyle(color: _orange),
    );

    _appendTableHeader(
      sheet: sheet,
      headers: [
        'Posição',
        'Prioridade',
        'Descrição',
        'Prazo',
        'Resultado esperado',
        '',
      ],
    );

    for (final item in opinion.priorities) {
      sheet.appendRow([
        IntCellValue(item.position),
        TextCellValue(item.title),
        TextCellValue(item.description),
        TextCellValue(item.deadline),
        TextCellValue(item.expectedResult),
        TextCellValue(''),
      ]);

      final rowIndex = sheet.maxRows - 1;

      for (final columnIndex in [1, 2, 4]) {
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

    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('Recomendações')]);

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 5,
      style: _sectionStyle(color: _purple),
    );

    _appendTableHeader(
      sheet: sheet,
      headers: [
        'Título',
        'Explicação',
        'Ação recomendada',
        'Prioridade',
        'Confiança',
        '',
      ],
    );

    for (final item in opinion.recommendations) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(item.title),
        TextCellValue(item.explanation),
        TextCellValue(item.action),
        TextCellValue(item.priority),
        TextCellValue(formatOpinionPercentage(item.confidence)),
        TextCellValue(''),
      ]);

      final color = _opinionPriorityColor(item.priority);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
      );

      for (final columnIndex in [0, 1, 2]) {
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

    sheet.appendRow([]);

    _appendTextSection(
      sheet: sheet,
      title: 'Resumo executivo',
      text: opinion.executiveSummary,
      color: _purple,
    );

    sheet.setColumnWidth(0, 22);
    sheet.setColumnWidth(1, 38);
    sheet.setColumnWidth(2, 54);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 44);
    sheet.setColumnWidth(5, 18);
  }

  void _appendTrendRow({
    required Sheet sheet,
    required ExecutiveTrendData trend,
  }) {
    final rowIndex = sheet.maxRows;

    sheet.appendRow([
      TextCellValue(trend.label),
      TextCellValue(trend.direction.name),
      DoubleCellValue(trend.currentValue),
      DoubleCellValue(trend.previousValue),
      TextCellValue(formatOpinionPercentage(trend.percentage)),
      TextCellValue(trend.interpretation),
    ]);

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      fontColorHex: _trendColor(trend),
      bold: true,
    );

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      textWrapping: TextWrapping.WrapText,
    );
  }

  void _appendRankingBlock({
    required Sheet sheet,
    required String title,
    required String category,
    required List<ExecutiveRankingItem> items,
  }) {
    sheet.appendRow([TextCellValue(title)]);

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 6,
      style: _sectionStyle(),
    );

    _appendTableHeader(
      sheet: sheet,
      headers: [
        'Posição',
        category,
        'Ações abertas',
        'Concluídas',
        'Desempenho',
        'Classificação',
        '',
      ],
    );

    for (final item in items) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        IntCellValue(item.position),
        TextCellValue(item.label),
        DoubleCellValue(item.value),
        DoubleCellValue(item.secondaryValue),
        TextCellValue(formatOpinionPercentage(item.percentage)),
        TextCellValue(item.status.name),
        TextCellValue(''),
      ]);

      final color = _indicatorColor(item.status);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: color,
        bold: true,
      );
    }
  }

  void _appendEvolutionBlock({
    required Sheet sheet,
    required String title,
    required List<ExecutiveEvolutionPoint> points,
  }) {
    sheet.appendRow([TextCellValue(title)]);

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 6,
      style: _sectionStyle(),
    );

    _appendTableHeader(
      sheet: sheet,
      headers: [
        'Data',
        'Período',
        'Criadas',
        'Concluídas',
        'Atrasadas',
        'Taxa de conclusão',
        'Saldo',
      ],
    );

    for (final point in points) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(point.date),
        TextCellValue(point.label),
        IntCellValue(point.createdCount),
        IntCellValue(point.completedCount),
        IntCellValue(point.overdueCount),
        TextCellValue(formatOpinionPercentage(point.completionRate)),
        IntCellValue(point.balance),
      ]);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: point.balance >= 0 ? _green : _red,
        bold: true,
      );
    }
  }

  void _appendTextSection({
    required Sheet sheet,
    required String title,
    required String text,
    required ExcelColor color,
  }) {
    sheet.appendRow([TextCellValue(title)]);

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 5,
      style: _sectionStyle(color: color),
    );

    final rowIndex = sheet.maxRows;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
      customValue: TextCellValue(text),
    );

    _styleRange(
      sheet: sheet,
      startRow: rowIndex,
      endRow: rowIndex,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _lightGray,
        fontColorHex: _darkText,
        textWrapping: TextWrapping.WrapText,
        verticalAlign: VerticalAlign.Top,
      ),
    );
  }

  void _appendOpinionItemsSection({
    required Sheet sheet,
    required String title,
    required List<ExecutiveOpinionItem> items,
    required ExcelColor color,
  }) {
    sheet.appendRow([TextCellValue(title)]);

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 5,
      style: _sectionStyle(color: color),
    );

    _appendTableHeader(
      sheet: sheet,
      headers: ['Título', 'Descrição', 'Impacto', 'Categoria', '', ''],
    );

    for (final item in items) {
      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(item.title),
        TextCellValue(item.description),
        TextCellValue(item.impact.name),
        TextCellValue(item.category),
        TextCellValue(''),
        TextCellValue(''),
      ]);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: _impactColor(item.impact),
        bold: true,
      );

      for (final columnIndex in [0, 1]) {
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
  }

  void _appendTitle({
    required Sheet sheet,
    required String title,
    required int columns,
  }) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: columns - 1, rowIndex: 0),
      customValue: TextCellValue(title),
    );

    _styleRange(
      sheet: sheet,
      startRow: 0,
      endRow: 0,
      startColumn: 0,
      endColumn: columns - 1,
      style: CellStyle(
        backgroundColorHex: _green,
        fontColorHex: _white,
        bold: true,
        fontSize: 18,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      ),
    );
  }

  void _appendTableHeader({
    required Sheet sheet,
    required List<String> headers,
  }) {
    sheet.appendRow(headers.map(TextCellValue.new).toList());

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: headers.length - 1,
      style: _headerStyle(),
    );
  }

  void _styleMetricValue({
    required Sheet sheet,
    required int rowIndex,
    required int columnIndex,
    required ExcelColor color,
  }) {
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
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
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

  CellStyle _sectionStyle({ExcelColor? color}) {
    final selectedColor = color ?? _darkGreen;

    return CellStyle(
      backgroundColorHex: selectedColor,
      fontColorHex: _white,
      bold: true,
      fontSize: 13,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
  }

  ExcelColor _indicatorColor(ExecutiveIndicatorStatus status) {
    switch (status) {
      case ExecutiveIndicatorStatus.positive:
        return _green;

      case ExecutiveIndicatorStatus.normal:
        return _blue;

      case ExecutiveIndicatorStatus.attention:
        return _orange;

      case ExecutiveIndicatorStatus.critical:
        return _red;
    }
  }

  ExcelColor _alertColor(ExecutiveAlertSeverity severity) {
    switch (severity) {
      case ExecutiveAlertSeverity.information:
        return _green;

      case ExecutiveAlertSeverity.warning:
        return _orange;

      case ExecutiveAlertSeverity.critical:
        return _red;
    }
  }

  ExcelColor _classificationColor(
    ExecutiveOperationClassification classification,
  ) {
    switch (classification) {
      case ExecutiveOperationClassification.excellent:
        return _green;

      case ExecutiveOperationClassification.good:
        return _darkGreen;

      case ExecutiveOperationClassification.attention:
        return _orange;

      case ExecutiveOperationClassification.critical:
        return _red;

      case ExecutiveOperationClassification.severe:
        return ExcelColor.fromHexString('#8E0000');
    }
  }

  ExcelColor _classificationBackgroundColor(
    ExecutiveOperationClassification classification,
  ) {
    switch (classification) {
      case ExecutiveOperationClassification.excellent:
      case ExecutiveOperationClassification.good:
        return ExcelColor.fromHexString('#E8F5E9');

      case ExecutiveOperationClassification.attention:
        return ExcelColor.fromHexString('#FFF3E0');

      case ExecutiveOperationClassification.critical:
      case ExecutiveOperationClassification.severe:
        return ExcelColor.fromHexString('#FFEBEE');
    }
  }

  ExcelColor _impactColor(ExecutiveOpinionImpact impact) {
    switch (impact) {
      case ExecutiveOpinionImpact.low:
        return _green;

      case ExecutiveOpinionImpact.medium:
        return _blue;

      case ExecutiveOpinionImpact.high:
        return _orange;

      case ExecutiveOpinionImpact.critical:
        return _red;
    }
  }

  ExcelColor _opinionPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return _red;

      case 'high':
        return _orange;

      case 'medium':
        return _blue;

      case 'low':
        return _green;

      default:
        return _gray;
    }
  }

  ExcelColor _trendColor(ExecutiveTrendData trend) {
    if (trend.isStable) {
      return _blue;
    }

    if (trend.label == 'Atrasos') {
      return trend.isIncreasing ? _red : _green;
    }

    return trend.isIncreasing ? _green : _red;
  }
}

String buildExecutiveDashboardExcelFileName(ExecutiveDashboardData dashboard) {
  final scope = dashboard.scopeLabel.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );

  final date = dashboard.generatedAt
      .replaceAll('/', '-')
      .replaceAll(':', '-')
      .replaceAll(' ', '_');

  return 'dashboard_executivo_'
      '${scope}_'
      '$date.xlsx';
}
