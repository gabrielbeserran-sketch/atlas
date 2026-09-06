import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';
import 'package:projeto_atlas/features/farm_finance/domain/services/farm_quote_return_import_service.dart';

void main() {
  const request = FarmQuoteRequest(
    id: 'cot-1',
    title: 'Ração',
    itemsDescription: 'Ração mineral',
    suppliers: ['Fornecedor A', 'Fornecedor B'],
    createdAt: '2026-09-05T10:00:00.000',
    proposals: [
      FarmSupplierProposal(
        supplierName: 'Fornecedor A',
        totalAmount: 1500,
        receivedAt: '2026-09-05T10:00:00.000',
      ),
    ],
  );

  test('importa retorno válido e preserva proposta já existente', () {
    final result = FarmQuoteReturnImportService().import(
      bytes: _returnsWorkbook([
        ['Fornecedor B', 980.50, '05/09/2026', 'Frete incluso'],
      ]),
      request: request,
      importedAt: DateTime(2026, 9, 6),
    );

    expect(result.warnings, isEmpty);
    expect(result.proposals, hasLength(1));
    expect(result.proposals.single.supplierName, 'Fornecedor B');
    expect(result.proposals.single.totalAmount, 980.50);
    expect(result.proposals.single.receivedAt, startsWith('2026-09-05'));
  });

  test('ignora fornecedor duplicado e valor inválido com avisos', () {
    final result = FarmQuoteReturnImportService().import(
      bytes: _returnsWorkbook([
        ['Fornecedor A', 1000, '05/09/2026', 'Duplicado'],
        ['Fornecedor C', '', '05/09/2026', 'Sem valor'],
      ]),
      request: request,
      importedAt: DateTime(2026, 9, 6),
    );

    expect(result.proposals, isEmpty);
    expect(result.warnings, hasLength(2));
  });
}

List<int> _returnsWorkbook(List<List<Object>> rows) {
  final workbook = Excel.createExcel();
  final defaultSheet = workbook.getDefaultSheet();
  if (defaultSheet != null) workbook.rename(defaultSheet, 'Retornos');
  final sheet = workbook['Retornos'];
  sheet.appendRow([TextCellValue('RETORNOS DE FORNECEDORES')]);
  sheet.appendRow([
    TextCellValue('Fornecedor'),
    TextCellValue('Valor total (R\$)'),
    TextCellValue('Data de recebimento'),
    TextCellValue('Observações'),
  ]);
  for (final row in rows) {
    sheet.appendRow([
      TextCellValue(row[0].toString()),
      row[1] is num ? DoubleCellValue((row[1] as num).toDouble()) : TextCellValue(row[1].toString()),
      TextCellValue(row[2].toString()),
      TextCellValue(row[3].toString()),
    ]);
  }
  return workbook.encode()!;
}
