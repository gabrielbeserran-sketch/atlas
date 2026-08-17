import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_quality_release/domain/models/atlas_quality_release_record.dart';
import 'package:projeto_atlas/features/atlas_quality_release/domain/services/atlas_quality_release_analytics_service.dart';

void main() {
  const service = AtlasQualityReleaseAnalyticsService();

  test('calculates quality and release analytics', () {
    const records = [
      AtlasQualityReleaseRecord(
        id: '1',
        module: AtlasQualityReleaseModule.comprehensiveUnitTests,
        feature: 'Regras de negócio',
        title: 'Testes do motor de indicadores',
        date: '04/08/2026',
        status: 'Aprovado',
        priority: 'Alta',
        environment: 'Homologação',
        responsible: 'Equipe Atlas',
        scope: 'Indicadores',
        evidence: 'Relatório de testes',
        progressPercent: 100,
        passRatePercent: 98,
        coveragePercent: 85,
        riskPercent: 10,
        failureCount: 1,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasQualityReleaseModule.comprehensiveUnitTests,
      records: records,
    );

    expect(result.recordCount, 1);
    expect(result.operationalCount, 1);
    expect(result.failureCount, 1);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
