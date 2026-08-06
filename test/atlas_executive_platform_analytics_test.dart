import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_executive_platform/domain/models/atlas_executive_platform_record.dart';
import 'package:projeto_atlas/features/atlas_executive_platform/domain/services/atlas_executive_platform_analytics_service.dart';

void main() {
  const service =
      AtlasExecutivePlatformAnalyticsService();

  test('calculates executive platform analytics', () {
    final records = [
      AtlasExecutivePlatformRecord(
        id: '1',
        module:
            AtlasExecutivePlatformModule.globalExecutiveDashboard,
        feature: 'Indicadores globais',
        title: 'Indicador consolidado',
        date: '04/08/2026',
        dueDate: '10/08/2026',
        status: 'Validado',
        priority: 'Alta',
        farmName: 'Fazenda A',
        companyName: 'Atlas',
        ownerName: 'Gestor',
        metricName: 'Eficiência',
        currentValue: 82,
        targetValue: 90,
        referenceValue: 75,
        unit: '%',
        progressPercent: 90,
        confidencePercent: 95,
        riskPercent: 20,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasExecutivePlatformRecord(
        id: '2',
        module:
            AtlasExecutivePlatformModule.globalExecutiveDashboard,
        feature: 'Riscos prioritários',
        title: 'Risco pendente',
        date: '04/08/2026',
        dueDate: '01/08/2026',
        status: 'Atenção',
        priority: 'Urgente',
        farmName: 'Fazenda B',
        companyName: 'Atlas',
        ownerName: '',
        metricName: 'Risco',
        currentValue: 75,
        targetValue: 20,
        referenceValue: 30,
        unit: '%',
        progressPercent: 30,
        confidencePercent: 70,
        riskPercent: 80,
        alertCount: 1,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasExecutivePlatformModule.globalExecutiveDashboard,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.averageCurrent, 78.5);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
