import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_reproductive_premium/domain/models/atlas_reproductive_premium_record.dart';
import 'package:projeto_atlas/features/atlas_reproductive_premium/domain/services/atlas_reproductive_premium_analytics_service.dart';

void main() {
  const service =
      AtlasReproductivePremiumAnalyticsService();

  test('calculates reproductive premium analytics', () {
    final records = [
      AtlasReproductivePremiumRecord(
        id: '1',
        module:
            AtlasReproductivePremiumModule.advancedIatf,
        feature: 'Inseminações',
        title: 'Lote IATF 01',
        date: '04/08/2026',
        status: 'Concluído',
        animalReference: 'Lote 1',
        protocol: 'Protocolo A',
        geneticReference: 'Touro 123',
        metricName: 'Prenhez',
        metricValue: 55,
        unit: '%',
        confidencePercent: 90,
        successPercent: 55,
        cost: 5000,
        progressPercent: 100,
        alertCount: 0,
        responsible: 'Veterinário',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasReproductivePremiumRecord(
        id: '2',
        module:
            AtlasReproductivePremiumModule.advancedIatf,
        feature: 'Resultados e auditoria',
        title: 'Revisão pendente',
        date: '04/08/2026',
        status: 'Atenção',
        animalReference: 'Lote 2',
        protocol: 'Protocolo B',
        geneticReference: '',
        metricName: 'Concepção',
        metricValue: 40,
        unit: '%',
        confidencePercent: 60,
        successPercent: 40,
        cost: 3000,
        progressPercent: 50,
        alertCount: 1,
        responsible: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasReproductivePremiumModule.advancedIatf,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalCost, 8000);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
