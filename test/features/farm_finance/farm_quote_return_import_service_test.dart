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

  test('calcula uma proposta estruturada pelos valores dos itens', () {
    final result = FarmQuoteReturnImportService().import(
      bytes: _structuredReturnsWorkbook(),
      request: request,
      importedAt: DateTime(2026, 9, 6),
    );

    expect(result.warnings, isEmpty);
    expect(result.proposals, hasLength(1));
    expect(result.proposals.single.supplierName, 'Fornecedor C');
    expect(result.proposals.single.totalAmount, 1005);
  });

  test('permite incorporar uma proposta estruturada sem fornecedor', () {
    final result = FarmQuoteReturnImportService().import(
      bytes: _structuredReturnsWorkbook(supplier: ''),
      request: request,
      importedAt: DateTime(2026, 9, 6),
    );

    expect(result.proposals, hasLength(1));
    expect(result.proposals.single.supplierName, 'Fornecedor não identificado');
    expect(result.proposals.single.totalAmount, 1005);
    expect(result.warnings.single, contains('Fornecedor não informado'));
  });

  test('localiza o fornecedor pelo rótulo mesmo após ajuste na planilha', () {
    final result = FarmQuoteReturnImportService().import(
      bytes: _structuredReturnsWorkbook(
        supplier: 'Fornecedor D',
        labelColumn: 1,
      ),
      request: request,
      importedAt: DateTime(2026, 9, 6),
    );

    expect(result.warnings, isEmpty);
    expect(result.proposals.single.supplierName, 'Fornecedor D');
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
      row[1] is num
          ? DoubleCellValue((row[1] as num).toDouble())
          : TextCellValue(row[1].toString()),
      TextCellValue(row[2].toString()),
      TextCellValue(row[3].toString()),
    ]);
  }
  return workbook.encode()!;
}

List<int> _structuredReturnsWorkbook({
  String supplier = 'Fornecedor C',
  int labelColumn = 0,
}) {
  final workbook = Excel.createExcel();
  final defaultSheet = workbook.getDefaultSheet();
  if (defaultSheet != null) workbook.rename(defaultSheet, 'Retornos');
  final sheet = workbook['Retornos'];
  sheet.appendRow([TextCellValue('PROPOSTA COMERCIAL — RETORNO DE COTAÇÃO')]);
  sheet.appendRow(
    labelColumn == 0
        ? [TextCellValue('Fornecedor'), TextCellValue(supplier)]
        : [
            TextCellValue(''),
            TextCellValue('Fornecedor'),
            TextCellValue(supplier),
          ],
  );
  sheet.appendRow([
    TextCellValue('Data da proposta'),
    TextCellValue('05/09/2026'),
  ]);
  sheet.appendRow([
    TextCellValue('Prazo / condições'),
    TextCellValue('Frete incluso'),
  ]);
  sheet.appendRow([
    TextCellValue('Item'),
    TextCellValue('Unidade'),
    TextCellValue('Quantidade'),
    TextCellValue('Valor unitário (R\$)'),
    TextCellValue('Valor total (R\$)'),
  ]);
  sheet.appendRow([
    TextCellValue('Ração mineral'),
    TextCellValue('saco'),
    DoubleCellValue(20),
    DoubleCellValue(50),
    FormulaCellValue('C6*D6'),
  ]);
  sheet.appendRow([
    TextCellValue(''),
    TextCellValue(''),
    TextCellValue(''),
    TextCellValue('Frete (R\$)'),
    DoubleCellValue(15),
  ]);
  sheet.appendRow([
    TextCellValue(''),
    TextCellValue(''),
    TextCellValue(''),
    TextCellValue('Desconto (R\$)'),
    DoubleCellValue(10),
  ]);
  return workbook.encode()!;
}
