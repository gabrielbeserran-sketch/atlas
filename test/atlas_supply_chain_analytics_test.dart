import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_supply_chain/domain/models/atlas_supply_chain_record.dart';
import 'package:projeto_atlas/features/atlas_supply_chain/domain/services/atlas_supply_chain_analytics_service.dart';

void main() {
  const service = AtlasSupplyChainAnalyticsService();

  test('calculates coverage, value and alerts', () {
    final records = [
      AtlasSupplyChainRecord(
        id: '1',
        module: AtlasSupplyChainModule.purchases,
        feature: 'Solicitações de compra',
        title: 'Compra de vacina',
        date: '04/08/2026',
        status: 'Concluído',
        quantity: 10,
        unitValue: 25,
        counterparty: 'Fornecedor A',
        document: '',
        origin: '',
        destination: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasSupplyChainRecord(
        id: '2',
        module: AtlasSupplyChainModule.purchases,
        feature: 'Aprovação de compras',
        title: 'Aprovação pendente',
        date: '04/08/2026',
        status: 'Atenção',
        quantity: 1,
        unitValue: 100,
        counterparty: '',
        document: '',
        origin: '',
        destination: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasSupplyChainModule.purchases,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.totalValue, 350);
    expect(result.completedCount, 1);
    expect(result.alertCount, 1);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
