import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';
import 'package:projeto_atlas/features/farm_finance/domain/services/farm_quote_comparison_service.dart';

void main() {
  const service = FarmQuoteComparisonService();
  const proposals = [
    FarmSupplierProposal(
      supplierName: 'Fornecedor B',
      totalAmount: 1400,
      receivedAt: '2026-09-05T10:00:00.000',
    ),
    FarmSupplierProposal(
      supplierName: 'Fornecedor A',
      totalAmount: 1200,
      receivedAt: '2026-09-05T11:00:00.000',
    ),
    FarmSupplierProposal(
      supplierName: 'Fornecedor C',
      totalAmount: 1280,
      receivedAt: '2026-09-05T12:00:00.000',
    ),
  ];

  test('ordena propostas, aponta a melhor e calcula a diferença', () {
    final ranked = service.rank(proposals);

    expect(ranked.map((item) => item.supplierName), [
      'Fornecedor A',
      'Fornecedor C',
      'Fornecedor B',
    ]);
    expect(service.bestProposal(proposals)?.supplierName, 'Fornecedor A');
    expect(
      service.differenceFromBest(
        proposal: proposals.first,
        proposals: proposals,
      ),
      200,
    );
  });

  test('mantém propostas ao serializar a solicitação', () {
    const request = FarmQuoteRequest(
      id: 'request-1',
      title: 'Compra de suplemento',
      itemsDescription: '20 sacos',
      suppliers: ['Fornecedor A'],
      createdAt: '2026-09-05T10:00:00.000',
      proposals: proposals,
    );

    final restored = FarmQuoteRequest.fromMap(request.toMap());

    expect(restored.proposals, hasLength(3));
    expect(restored.displayStatus, 'Em comparação');
    expect(restored.proposals[1].totalAmount, 1200);
  });
}
