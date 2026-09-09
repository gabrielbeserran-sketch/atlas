import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';
import 'package:projeto_atlas/features/farm_finance/domain/services/farm_quote_request_excel_service.dart';

void main() {
  const farm = FarmData(
    id: 'farm-1',
    name: 'Fazenda Atlas',
    city: 'Sobradinho',
    state: 'GO',
    animals: 120,
    area: 80,
  );
  const request = FarmQuoteRequest(
    id: 'quote-1',
    title: 'Compra de suplemento',
    itemsDescription: '20 sacos de suplemento mineral',
    suppliers: ['Fornecedor A', 'Fornecedor B'],
    createdAt: '2026-09-05T10:00:00.000',
    items: [
      FarmQuoteItem(
        description: 'Suplemento mineral',
        unit: 'saco',
        quantity: 20,
      ),
    ],
    proposals: [
      FarmSupplierProposal(
        supplierName: 'Fornecedor A',
        totalAmount: 1200,
        receivedAt: '2026-09-05T12:00:00.000',
        notes: 'Entrega em 48 horas',
      ),
    ],
  );

  test('gera uma planilha comercial neutra com total automático', () {
    final service = FarmQuoteRequestExcelService();
    final bytes = service.build(farm: farm, request: request);
    final workbook = Excel.decodeBytes(bytes);

    expect(bytes, isNotEmpty);
    expect(workbook.tables.keys, containsAll(['Solicitação', 'Retornos']));
    expect(
      workbook['Solicitação'].cell(CellIndex.indexByString('A1')).value,
      isA<TextCellValue>(),
    );
    expect(
      (workbook['Solicitação'].cell(CellIndex.indexByString('A1')).value
              as TextCellValue)
          .value
          .toString(),
      contains('SOLICITAÇÃO DE COTAÇÃO'),
    );
    expect(
      (workbook['Retornos'].cell(CellIndex.indexByString('B2')).value
              as TextCellValue)
          .value
          .toString(),
      'Preencher pelo fornecedor',
    );
    expect(
      (workbook['Retornos'].cell(CellIndex.indexByString('A5')).value
              as TextCellValue)
          .value
          .toString(),
      'Item',
    );
    expect(
      workbook['Retornos'].cell(CellIndex.indexByString('E6')).value,
      const FormulaCellValue('C6*D6'),
    );
    expect(
      service.suggestedFileName(request),
      'solicitacao_atlas_compra_de_suplemento.xlsx',
    );
  });
}
