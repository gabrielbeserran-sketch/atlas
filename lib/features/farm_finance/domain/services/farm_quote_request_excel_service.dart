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

  List<int> build({
    required FarmData farm,
    required FarmQuoteRequest request,
  }) {
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
    _appendSection(sheet, 'Itens e quantidades', 4);
    sheet.merge(
      CellIndex.indexByString('A8'),
      CellIndex.indexByString('D10'),
      customValue: TextCellValue(request.itemsDescription),
    );
    _styleRange(
      sheet,
      startRow: 7,
      endRow: 9,
      startColumn: 0,
      endColumn: 3,
      style: CellStyle(textWrapping: TextWrapping.WrapText),
    );

    _appendSection(sheet, 'Fornecedores previstos', 4);
    final suppliers = request.suppliers.isEmpty
        ? const ['A definir']
        : request.suppliers;
    for (var index = 0; index < suppliers.length; index++) {
      sheet.appendRow([
        IntCellValue(index + 1),
        TextCellValue(suppliers[index]),
        TextCellValue('Retorno a registrar'),
        TextCellValue(''),
      ]);
    }

    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 24);
    sheet.setColumnWidth(3, 30);
  }

  void _buildReturnsSheet(Sheet sheet, FarmQuoteRequest request) {
    _appendTitle(sheet, 'RETORNOS DE FORNECEDORES', 5);
    sheet.appendRow([
      TextCellValue('Fornecedor'),
      TextCellValue('Valor total (R\$)'),
      TextCellValue('Data de recebimento'),
      TextCellValue('Observações'),
      TextCellValue('Revisado no Atlas'),
    ]);
    _styleRange(
      sheet,
      startRow: 1,
      endRow: 1,
      startColumn: 0,
      endColumn: 4,
      style: CellStyle(
        backgroundColorHex: _green,
        fontColorHex: _white,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      ),
    );

    final rows = request.proposals.isEmpty
        ? request.suppliers.map(
            (supplier) => _ReturnRow(supplier: supplier),
          )
        : request.proposals.map(
            (proposal) => _ReturnRow(
              supplier: proposal.supplierName,
              amount: proposal.totalAmount,
              receivedAt: proposal.receivedAt,
              notes: proposal.notes,
              reviewed: 'Sim',
            ),
          );

    for (final row in rows.take(4)) {
      final rowIndex = sheet.maxRows;
      sheet.appendRow([
        TextCellValue(row.supplier),
        row.amount == null ? TextCellValue('') : DoubleCellValue(row.amount!),
        TextCellValue(_formatDate(row.receivedAt)),
        TextCellValue(row.notes),
        TextCellValue(row.reviewed),
      ]);
      if (row.amount != null) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: 1,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            CellStyle(
              numberFormat: CustomNumericNumFormat(
                formatCode: 'R\$ #,##0.00;[Red]-R\$ #,##0.00',
              ),
            );
      }
    }

    sheet.setColumnWidth(0, 32);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 24);
    sheet.setColumnWidth(3, 48);
    sheet.setColumnWidth(4, 20);
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
            .cellStyle =
        CellStyle(backgroundColorHex: _lightGreen, fontColorHex: _green, bold: true);
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

class _ReturnRow {
  const _ReturnRow({
    required this.supplier,
    this.amount,
    this.receivedAt = '',
    this.notes = '',
    this.reviewed = 'Não',
  });

  final String supplier;
  final double? amount;
  final String receivedAt;
  final String notes;
  final String reviewed;
}
