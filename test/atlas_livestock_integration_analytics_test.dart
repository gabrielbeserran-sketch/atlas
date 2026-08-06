
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_livestock_integration/domain/models/atlas_livestock_integration_record.dart';
import 'package:projeto_atlas/features/atlas_livestock_integration/domain/services/atlas_livestock_integration_analytics_service.dart';

void main() {
  const service =
      AtlasLivestockIntegrationAnalyticsService();

  test('calculates livestock integration analytics', () {
    const records = [
      AtlasLivestockIntegrationRecord(
        id: '1',
        module:
            AtlasLivestockIntegrationModule.eventIntegration,
        feature: 'Reflexos automáticos',
        title: 'Integração de evento sanitário',
        date: '04/08/2026',
        status: 'Integrado',
        priority: 'Alta',
        farmName: 'Fazenda A',
        animalOrLot: 'Lote 1',
        sourceModule: 'Sanidade',
        destinationModule: 'Estoque',
        eventType: 'Tratamento',
        responsible: 'Veterinário',
        progressPercent: 100,
        successRatePercent: 98,
        riskPercent: 10,
        pendingCount: 0,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasLivestockIntegrationModule.eventIntegration,
      records: records,
    );

    expect(result.recordCount, 1);
    expect(result.operationalCount, 1);
    expect(result.pendingCount, 0);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
