import 'package:excel/excel.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class ReportActionExcelService {
  static final ExcelColor _green = ExcelColor.fromHexString('#1B5E20');

  static final ExcelColor _lightGreen = ExcelColor.fromHexString('#E8F5E9');

  static final ExcelColor _darkText = ExcelColor.fromHexString('#263238');

  static final ExcelColor _gray = ExcelColor.fromHexString('#F2F4F5');

  static final ExcelColor _mediumGray = ExcelColor.fromHexString('#607D8B');

  static final ExcelColor _red = ExcelColor.fromHexString('#C62828');

  static final ExcelColor _lightRed = ExcelColor.fromHexString('#FFEBEE');

  static final ExcelColor _blue = ExcelColor.fromHexString('#1565C0');

  static final ExcelColor _lightBlue = ExcelColor.fromHexString('#E3F2FD');

  static final ExcelColor _orange = ExcelColor.fromHexString('#EF6C00');

  static final ExcelColor _lightOrange = ExcelColor.fromHexString('#FFF3E0');

  static final ExcelColor _white = ExcelColor.fromHexString('#FFFFFF');

  Future<void> exportReport({required ReportActionExcelData report}) async {
    final excel = Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();

    if (defaultSheet != null && defaultSheet != 'Resumo') {
      excel.rename(defaultSheet, 'Resumo');
    }

    _buildSummarySheet(excel: excel, report: report);

    _buildActionsSheet(excel: excel, report: report);

    _buildHistorySheet(excel: excel, report: report);

    excel.setDefaultSheet('Resumo');

    excel.save(fileName: report.fileName);
  }

  void _buildSummarySheet({
    required Excel excel,
    required ReportActionExcelData report,
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
      customValue: TextCellValue('Relatório de Ações Gerenciais'),
    );

    _styleRange(
      sheet: sheet,
      startRow: 1,
      endRow: 1,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _lightGreen,
        fontColorHex: _green,
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      ),
    );

    sheet.appendRow([
      TextCellValue('Escopo'),
      TextCellValue(report.scopeLabel),
      TextCellValue('Emissão'),
      TextCellValue(report.issueDate),
      TextCellValue('Responsável'),
      TextCellValue(report.consultantName),
    ]);

    _styleRange(
      sheet: sheet,
      startRow: 2,
      endRow: 2,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _gray,
        fontColorHex: _darkText,
        bold: true,
        textWrapping: TextWrapping.WrapText,
        verticalAlign: VerticalAlign.Center,
      ),
    );

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
      startRow: 3,
      endRow: 3,
      startColumn: 0,
      endColumn: 5,
      style: _headerStyle(),
    );

    sheet.appendRow([
      TextCellValue('Total de ações'),
      IntCellValue(report.totalCount),
      TextCellValue('Ações abertas'),
      IntCellValue(report.openCount),
      TextCellValue('Taxa de conclusão'),
      TextCellValue(
        '${(report.completionRate * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
      ),
    ]);

    sheet.appendRow([
      TextCellValue('Pendentes'),
      IntCellValue(report.pendingCount),
      TextCellValue('Em andamento'),
      IntCellValue(report.inProgressCount),
      TextCellValue('Concluídas'),
      IntCellValue(report.completedCount),
    ]);

    sheet.appendRow([
      TextCellValue('Canceladas'),
      IntCellValue(report.cancelledCount),
      TextCellValue('Atrasadas'),
      IntCellValue(report.overdueCount),
      TextCellValue('Urgentes'),
      IntCellValue(report.urgentCount),
    ]);

    _styleSummaryValue(sheet: sheet, rowIndex: 4, columnIndex: 1, color: _blue);

    _styleSummaryValue(
      sheet: sheet,
      rowIndex: 4,
      columnIndex: 3,
      color: _orange,
    );

    _styleSummaryValue(
      sheet: sheet,
      rowIndex: 4,
      columnIndex: 5,
      color: report.completionRate >= 0.75
          ? _green
          : report.completionRate >= 0.40
          ? _blue
          : _orange,
    );

    _styleSummaryValue(
      sheet: sheet,
      rowIndex: 5,
      columnIndex: 1,
      color: _orange,
    );

    _styleSummaryValue(sheet: sheet, rowIndex: 5, columnIndex: 3, color: _blue);

    _styleSummaryValue(
      sheet: sheet,
      rowIndex: 5,
      columnIndex: 5,
      color: _green,
    );

    _styleSummaryValue(
      sheet: sheet,
      rowIndex: 6,
      columnIndex: 1,
      color: _mediumGray,
    );

    _styleSummaryValue(
      sheet: sheet,
      rowIndex: 6,
      columnIndex: 3,
      color: report.overdueCount > 0 ? _red : _green,
    );

    _styleSummaryValue(
      sheet: sheet,
      rowIndex: 6,
      columnIndex: 5,
      color: report.urgentCount > 0 ? _red : _green,
    );

    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('Status'),
      TextCellValue('Quantidade'),
      TextCellValue('Participação'),
    ]);

    _styleRange(
      sheet: sheet,
      startRow: 8,
      endRow: 8,
      startColumn: 0,
      endColumn: 2,
      style: _headerStyle(),
    );

    final statusRows = [
      _ActionStatusSummary(status: 'Pendente', count: report.pendingCount),
      _ActionStatusSummary(
        status: 'Em andamento',
        count: report.inProgressCount,
      ),
      _ActionStatusSummary(status: 'Concluída', count: report.completedCount),
      _ActionStatusSummary(status: 'Cancelada', count: report.cancelledCount),
    ];

    for (final item in statusRows) {
      final participation = report.totalCount == 0
          ? 0.0
          : item.count / report.totalCount * 100;

      sheet.appendRow([
        TextCellValue(item.status),
        IntCellValue(item.count),
        TextCellValue(
          '${participation.toStringAsFixed(1).replaceAll('.', ',')}%',
        ),
      ]);

      final rowIndex = sheet.maxRows - 1;
      final statusColor = _statusColor(item.status);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: statusColor,
        bold: true,
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: statusColor,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    sheet.appendRow([]);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheet.maxRows),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: sheet.maxRows),
      customValue: TextCellValue(_buildManagementMessage(report)),
    );

    _styleRange(
      sheet: sheet,
      startRow: sheet.maxRows - 1,
      endRow: sheet.maxRows - 1,
      startColumn: 0,
      endColumn: 5,
      style: CellStyle(
        backgroundColorHex: _lightGreen,
        fontColorHex: _green,
        bold: true,
        textWrapping: TextWrapping.WrapText,
        verticalAlign: VerticalAlign.Center,
      ),
    );

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 19);
    sheet.setColumnWidth(2, 24);
    sheet.setColumnWidth(3, 19);
    sheet.setColumnWidth(4, 24);
    sheet.setColumnWidth(5, 24);
  }

  void _buildActionsSheet({
    required Excel excel,
    required ReportActionExcelData report,
  }) {
    final sheet = excel['Ações'];

    _appendTitle(sheet, 'Ações gerenciais', columns: 14);

    _appendTableHeader(sheet, [
      'ID',
      'Fazenda / Escopo',
      'Problema identificado',
      'Ação recomendada',
      'Responsável',
      'Prazo',
      'Prioridade',
      'Status',
      'Situação do prazo',
      'Data de criação',
      'Data de conclusão',
      'Origem',
      'Observações',
      'Movimentações',
    ]);

    final actions = List<ReportActionItemData>.from(report.actions)
      ..sort(compareReportActions);

    for (final action in actions) {
      final historyCount = report.historyByActionId[action.id]?.length ?? 0;

      final rowIndex = sheet.maxRows;

      sheet.appendRow([
        TextCellValue(action.id),
        TextCellValue(
          action.farmName.isEmpty ? 'Todas as fazendas' : action.farmName,
        ),
        TextCellValue(action.title),
        TextCellValue(action.action),
        TextCellValue(
          action.responsible.isEmpty ? 'Não definido' : action.responsible,
        ),
        TextCellValue(action.deadline.isEmpty ? 'Sem prazo' : action.deadline),
        TextCellValue(action.priority),
        TextCellValue(action.status),
        TextCellValue(
          action.isOverdue
              ? 'Atrasada'
              : action.isCompleted
              ? 'Concluída'
              : action.hasDeadline
              ? 'No prazo'
              : 'Sem prazo',
        ),
        TextCellValue(action.createdAt),
        TextCellValue(action.completedAt),
        TextCellValue(action.source),
        TextCellValue(action.notes),
        IntCellValue(historyCount),
      ]);

      _styleActionRow(sheet: sheet, rowIndex: rowIndex, action: action);
    }

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 36);
    sheet.setColumnWidth(3, 58);
    sheet.setColumnWidth(4, 28);
    sheet.setColumnWidth(5, 17);
    sheet.setColumnWidth(6, 17);
    sheet.setColumnWidth(7, 18);
    sheet.setColumnWidth(8, 19);
    sheet.setColumnWidth(9, 18);
    sheet.setColumnWidth(10, 18);
    sheet.setColumnWidth(11, 28);
    sheet.setColumnWidth(12, 46);
    sheet.setColumnWidth(13, 16);
  }

  void _buildHistorySheet({
    required Excel excel,
    required ReportActionExcelData report,
  }) {
    final sheet = excel['Histórico'];

    _appendTitle(sheet, 'Histórico das ações gerenciais', columns: 11);

    _appendTableHeader(sheet, [
      'ID do evento',
      'ID da ação',
      'Ação',
      'Fazenda / Escopo',
      'Tipo de evento',
      'Descrição',
      'Valor anterior',
      'Novo valor',
      'Data e hora',
      'Usuário',
      'Origem',
    ]);

    final actionById = {for (final action in report.actions) action.id: action};

    final allHistory = <ReportActionHistoryData>[];

    for (final entries in report.historyByActionId.values) {
      allHistory.addAll(entries);
    }

    allHistory.sort(compareReportActionHistory);

    for (final item in allHistory) {
      final action = actionById[item.actionId];
      final rowIndex = sheet.maxRows;
      final eventColor = _historyEventColor(item);

      sheet.appendRow([
        TextCellValue(item.id),
        TextCellValue(item.actionId),
        TextCellValue(item.actionTitle),
        TextCellValue(
          action?.farmName.isEmpty == false
              ? action!.farmName
              : 'Todas as fazendas',
        ),
        TextCellValue(item.eventType),
        TextCellValue(item.description),
        TextCellValue(item.previousValue),
        TextCellValue(item.newValue),
        TextCellValue(item.createdAt),
        TextCellValue(item.createdBy.isEmpty ? 'Usuário' : item.createdBy),
        TextCellValue(item.source.isEmpty ? 'Sistema' : item.source),
      ]);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        fontColorHex: eventColor,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      for (final columnIndex in [2, 3, 5, 6, 7, 9, 10]) {
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

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 34);
    sheet.setColumnWidth(3, 28);
    sheet.setColumnWidth(4, 19);
    sheet.setColumnWidth(5, 52);
    sheet.setColumnWidth(6, 28);
    sheet.setColumnWidth(7, 28);
    sheet.setColumnWidth(8, 22);
    sheet.setColumnWidth(9, 24);
    sheet.setColumnWidth(10, 26);
  }

  void _appendTitle(Sheet sheet, String title, {required int columns}) {
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
      style: _titleStyle(),
    );
  }

  void _appendTableHeader(Sheet sheet, List<String> values) {
    sheet.appendRow(values.map(TextCellValue.new).toList());

    final rowIndex = sheet.maxRows - 1;

    _styleRange(
      sheet: sheet,
      startRow: rowIndex,
      endRow: rowIndex,
      startColumn: 0,
      endColumn: values.length - 1,
      style: _headerStyle(),
    );
  }

  void _styleActionRow({
    required Sheet sheet,
    required int rowIndex,
    required ReportActionItemData action,
  }) {
    final statusColor = action.isOverdue ? _red : _statusColor(action.status);

    final statusBackground = action.isOverdue
        ? _lightRed
        : _statusBackgroundColor(action.status);

    for (final columnIndex in [1, 2, 3, 4, 11, 12]) {
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

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      fontColorHex: _priorityColor(action.priority),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      backgroundColorHex: statusBackground,
      fontColorHex: statusColor,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      backgroundColorHex: action.isOverdue ? _lightRed : _gray,
      fontColorHex: action.isOverdue ? _red : _darkText,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
        .cellStyle = CellStyle(
      fontColorHex: _blue,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  void _styleSummaryValue({
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

  CellStyle _titleStyle() {
    return CellStyle(
      backgroundColorHex: _green,
      fontColorHex: _white,
      bold: true,
      fontSize: 18,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
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

  ExcelColor _statusColor(String status) {
    switch (status) {
      case 'Em andamento':
        return _blue;
      case 'Concluída':
        return _green;
      case 'Cancelada':
        return _mediumGray;
      default:
        return _orange;
    }
  }

  ExcelColor _statusBackgroundColor(String status) {
    switch (status) {
      case 'Em andamento':
        return _lightBlue;
      case 'Concluída':
        return _lightGreen;
      case 'Cancelada':
        return _gray;
      default:
        return _lightOrange;
    }
  }

  ExcelColor _priorityColor(String priority) {
    switch (priority) {
      case 'Muito alta':
      case 'Urgente':
        return _red;
      case 'Alta':
        return _orange;
      case 'Média':
      case 'Normal':
        return _blue;
      default:
        return _green;
    }
  }

  ExcelColor _historyEventColor(ReportActionHistoryData item) {
    if (item.isCompletion) {
      return _green;
    }

    if (item.isCancellation) {
      return _mediumGray;
    }

    if (item.isDeadlineChange) {
      return _orange;
    }

    if (item.isPriorityChange) {
      return _red;
    }

    if (item.isResponsibleChange || item.isStatusChange) {
      return _blue;
    }

    return _green;
  }

  String _buildManagementMessage(ReportActionExcelData report) {
    if (report.overdueCount > 0) {
      return 'Observação gerencial: existem '
          '${report.overdueCount} '
          '${report.overdueCount == 1 ? 'ação atrasada' : 'ações atrasadas'}. '
          'Priorize a revisão dos prazos e responsáveis.';
    }

    if (report.completionRate >= 0.75) {
      return 'Observação gerencial: o plano apresenta bom avanço. '
          'Mantenha o acompanhamento das ações restantes.';
    }

    if (report.inProgressCount > 0) {
      return 'Observação gerencial: o plano está em execução. '
          'Acompanhe os prazos e registre as conclusões.';
    }

    return 'Observação gerencial: o plano ainda está no início. '
        'Defina responsáveis e inicie as ações prioritárias.';
  }
}

class ReportActionExcelData {
  const ReportActionExcelData({
    required this.scopeLabel,
    required this.issueDate,
    required this.consultantName,
    required this.actions,
    required this.historyByActionId,
  });

  final String scopeLabel;
  final String issueDate;
  final String consultantName;

  final List<ReportActionItemData> actions;

  final Map<String, List<ReportActionHistoryData>> historyByActionId;

  int get totalCount {
    return actions.length;
  }

  int get pendingCount {
    return actions.where((action) {
      return action.isPending;
    }).length;
  }

  int get inProgressCount {
    return actions.where((action) {
      return action.isInProgress;
    }).length;
  }

  int get completedCount {
    return actions.where((action) {
      return action.isCompleted;
    }).length;
  }

  int get cancelledCount {
    return actions.where((action) {
      return action.isCancelled;
    }).length;
  }

  int get overdueCount {
    return actions.where((action) {
      return action.isOverdue;
    }).length;
  }

  int get urgentCount {
    return actions.where((action) {
      return action.isUrgent && action.isOpen;
    }).length;
  }

  int get openCount {
    return actions.where((action) {
      return action.isOpen;
    }).length;
  }

  double get completionRate {
    final considered = actions.where((action) {
      return !action.isCancelled;
    }).length;

    if (considered == 0) {
      return 0;
    }

    return completedCount / considered;
  }

  String get fileName {
    final normalizedScope = scopeLabel.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    final normalizedDate = issueDate
        .replaceAll('/', '-')
        .replaceAll(':', '-')
        .replaceAll(' ', '_');

    return 'acoes_gerenciais_'
        '${normalizedScope}_'
        '$normalizedDate.xlsx';
  }
}

class _ActionStatusSummary {
  const _ActionStatusSummary({required this.status, required this.count});

  final String status;
  final int count;
}
