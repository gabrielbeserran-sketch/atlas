import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_commercial_operations/domain/models/atlas_commercial_operation_record.dart';
import 'package:projeto_atlas/features/atlas_commercial_operations/domain/services/atlas_commercial_operation_analytics_service.dart';

void main() {
  const service =
      AtlasCommercialOperationAnalyticsService();

  test('calculates commercial operation analytics', () {
    final records = [
      AtlasCommercialOperationRecord(
        id: '1',
        module:
            AtlasCommercialOperationModule.digitalAuction,
        feature: 'Cadastro de lotes',
        title: 'Lote 001',
        date: '04/08/2026',
        status: 'Publicado',
        counterparty: 'Leiloeira',
        externalId: 'LOT-001',
        amount: 120000,
        costAmount: 6000,
        quantity: 20,
        distanceKm: 0,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasCommercialOperationRecord(
        id: '2',
        module:
            AtlasCommercialOperationModule.digitalAuction,
        feature: 'Documentação pós-leilão',
        title: 'Documento pendente',
        date: '04/08/2026',
        status: 'Atenção',
        counterparty: '',
        externalId: '',
        amount: 0,
        costAmount: 0,
        quantity: 1,
        distanceKm: 0,
        progressPercent: 50,
        alertCount: 1,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasCommercialOperationModule.digitalAuction,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.netAmount, 114000);
    expect(result.totalQuantity, 21);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
