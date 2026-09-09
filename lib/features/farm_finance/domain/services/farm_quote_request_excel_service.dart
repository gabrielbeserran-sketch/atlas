import 'package:excel/excel.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';

/// Produz a planilha que acompanha uma solicitação de cotação.
///
/// A planilha é deliberadamente uma exportação, não uma nova fonte de dados:
/// a solicitação continua sendo persistida pelo Atlas e os retornos devem ser
/// revisados antes de serem registrados como propostas no aplicativo.
class FarmQuoteRequestExcelService {
  static final ExcelColor _green = ExcelColor.fromHexString('#1B5E20');
  static final ExcelColor _lightGreen = ExcelColor.fromHexString('#E8F5E9');
  static final ExcelColor _white = ExcelColor.fromHexString('#FFFFFF');

  List<int> build({required FarmData farm, required FarmQuoteRequest request}) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Solicitação') {
      excel.rename(defaultSheet, 'Solicitação');
    }

    final requestSheet = excel['Solicitação'];
    _buildRequestSheet(requestSheet, farm, request);

    final returnsSheet = excel['Retornos'];
    _buildReturnsSheet(returnsSheet, request);

    excel.setDefaultSheet('Solicitação');
    return excel.encode() ?? <int>[];
  }

  String suggestedFileName(FarmQuoteRequest request) {
    final normalized = request.title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final suffix = normalized.isEmpty ? 'cotacao' : normalized;
    return 'solicitacao_atlas_$suffix.xlsx';
  }

  void _buildRequestSheet(
    Sheet sheet,
    FarmData farm,
    FarmQuoteRequest request,
  ) {
    _appendTitle(sheet, 'SOLICITAÇÃO DE COTAÇÃO — PROJETO ATLAS', 4);
    _appendLabelValue(sheet, 'Fazenda', farm.name);
    _appendLabelValue(sheet, 'Localidade', '${farm.city} - ${farm.state}');
    _appendLabelValue(sheet, 'Solicitação', request.title);
    _appendLabelValue(sheet, 'Criada em', _formatDate(request.createdAt));
    _appendLabelValue(sheet, 'Código interno', request.id);
    if (request.deadline?.trim().isNotEmpty == true) {
      _appendLabelValue(sheet, 'Retorno até', _formatDate(request.deadline!));
    }
    if (request.deliveryInstructions.trim().isNotEmpty) {
      _appendLabelValue(sheet, 'Entrega', request.deliveryInstructions);
    }
    if (request.paymentTerms.trim().isNotEmpty) {
      _appendLabelValue(sheet, 'Pagamento', request.paymentTerms);
    }
    _appendSection(sheet, 'Itens solicitados', 4);
    _appendTableHeader(sheet, const [
      'Item',
      'Unidade',
      'Quantidade',
      'Observações',
    ]);
    for (final item in request.normalizedItems) {
      sheet.appendRow([
        TextCellValue(item.description),
        TextCellValue(item.unit),
        DoubleCellValue(item.quantity),
        TextCellValue(''),
      ]);
    }
    sheet.setColumnWidth(0, 42);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 38);
  }

  void _buildReturnsSheet(Sheet sheet, FarmQuoteRequest request) {
    _appendTitle(sheet, 'PROPOSTA COMERCIAL — RETORNO DE COTAÇÃO', 5);
    _appendLabelValue(sheet, 'Fornecedor', 'Preencher pelo fornecedor');
    _appendLabelValue(sheet, 'Data da proposta', 'Preencher no retorno');
    _appendLabelValue(sheet, 'Prazo / condições', 'Preencher no retorno');
    _appendTableHeader(sheet, const [
      'Item',
      'Unidade',
      'Quantidade',
      'Valor unitário (R\$)',
      'Valor total (R\$)',
    ]);

    final firstItemRow = sheet.maxRows;
    for (final item in request.normalizedItems) {
      final rowIndex = sheet.maxRows;
      final excelRow = rowIndex + 1;
      sheet.appendRow([
        TextCellValue(item.description),
        TextCellValue(item.unit),
        DoubleCellValue(item.quantity),
        TextCellValue(''),
        FormulaCellValue('C$excelRow*D$excelRow'),
      ]);
      _currencyStyle(sheet, rowIndex, 3);
      _currencyStyle(sheet, rowIndex, 4);
    }
    final lastItemRow = sheet.maxRows - 1;
    final freightRow = sheet.maxRows;
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Frete (R\$)'),
      TextCellValue(''),
    ]);
    _currencyStyle(sheet, freightRow, 4);
    final discountRow = sheet.maxRows;
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Desconto (R\$)'),
      TextCellValue(''),
    ]);
    _currencyStyle(sheet, discountRow, 4);
    final totalRow = sheet.maxRows;
    final firstExcelRow = firstItemRow + 1;
    final lastExcelRow = lastItemRow + 1;
    final freightExcelRow = freightRow + 1;
    final discountExcelRow = discountRow + 1;
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('TOTAL DA PROPOSTA (R\$)'),
      FormulaCellValue(
        'SUM(E$firstExcelRow:E$lastExcelRow)+E$freightExcelRow-E$discountExcelRow',
      ),
    ]);
    _currencyStyle(sheet, totalRow, 4, bold: true);

    sheet.setColumnWidth(0, 42);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 22);
  }

  void _appendTableHeader(Sheet sheet, List<String> labels) {
    final row = sheet.maxRows;
    sheet.appendRow(labels.map(TextCellValue.new).toList(growable: false));
    _styleRange(
      sheet,
      startRow: row,
      endRow: row,
      startColumn: 0,
      endColumn: labels.length - 1,
      style: CellStyle(
        backgroundColorHex: _green,
        fontColorHex: _white,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      ),
    );
  }

  void _currencyStyle(Sheet sheet, int row, int column, {bool bold = false}) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .cellStyle = CellStyle(
      bold: bold,
      numberFormat: CustomNumericNumFormat(
        formatCode: 'R\$ #,##0.00;[Red]-R\$ #,##0.00',
      ),
    );
  }

  void _appendTitle(Sheet sheet, String title, int columns) {
    final row = sheet.maxRows;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: columns - 1, rowIndex: row),
      customValue: TextCellValue(title),
    );
    _styleRange(
      sheet,
      startRow: row,
      endRow: row,
      startColumn: 0,
      endColumn: columns - 1,
      style: CellStyle(
        backgroundColorHex: _green,
        fontColorHex: _white,
        fontSize: 14,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      ),
    );
  }

  void _appendSection(Sheet sheet, String title, int columns) {
    final row = sheet.maxRows;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: columns - 1, rowIndex: row),
      customValue: TextCellValue(title),
    );
    _styleRange(
      sheet,
      startRow: row,
      endRow: row,
      startColumn: 0,
      endColumn: columns - 1,
      style: CellStyle(
        backgroundColorHex: _lightGreen,
        fontColorHex: _green,
        bold: true,
      ),
    );
  }

  void _appendLabelValue(Sheet sheet, String label, String value) {
    final row = sheet.maxRows;
    sheet.appendRow([TextCellValue(label), TextCellValue(value)]);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = CellStyle(
      backgroundColorHex: _lightGreen,
      fontColorHex: _green,
      bold: true,
    );
  }

  void _styleRange(
    Sheet sheet, {
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

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}
