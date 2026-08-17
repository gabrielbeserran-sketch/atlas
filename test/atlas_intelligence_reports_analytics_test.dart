import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_intelligence_reports_experience/domain/models/atlas_intelligence_reports_record.dart';
import 'package:projeto_atlas/features/atlas_intelligence_reports_experience/domain/services/atlas_intelligence_reports_analytics_service.dart';

void main() {
  const service = AtlasIntelligenceReportsAnalyticsService();

  test('calculates intelligence reports analytics', () {
    const records = [
      AtlasIntelligenceReportsRecord(
        id: '1',
        module: AtlasIntelligenceReportsModule.consolidatedIndicatorEngine,
        feature: 'Fórmula',
        title: 'Indicador de eficiência',
        date: '04/08/2026',
        status: 'Validado',
        priority: 'Alta',
        farmName: 'Fazenda A',
        indicatorName: 'Eficiência',
        dataSource: 'Eventos pecuários',
        periodLabel: 'Mensal',
        responsible: 'Gestor',
        currentValue: 82,
        targetValue: 90,
        confidencePercent: 95,
        riskPercent: 15,
        progressPercent: 90,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasIntelligenceReportsModule.consolidatedIndicatorEngine,
      records: records,
    );

    expect(result.recordCount, 1);
    expect(result.operationalCount, 1);
    expect(result.averageCurrentValue, 82);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
