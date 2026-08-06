import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_climate_enterprise/domain/models/atlas_climate_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_climate_enterprise/domain/services/atlas_climate_enterprise_analytics_service.dart';

void main() {
  const service = AtlasClimateEnterpriseAnalyticsService();

  test('calculates climate enterprise analytics', () {
    final records = [
      AtlasClimateEnterpriseRecord(
        id: '1',
        module:
            AtlasClimateEnterpriseModule.climateIntelligence,
        feature: 'Tendências',
        title: 'Tendência de chuva',
        date: '04/08/2026',
        status: 'Validado',
        farmName: 'Fazenda A',
        areaName: 'Piquete 1',
        metricName: 'Precipitação',
        currentValue: 40,
        projectedValue: 65,
        referenceValue: 50,
        unit: 'mm',
        probabilityPercent: 75,
        confidencePercent: 85,
        riskPercent: 20,
        progressPercent: 100,
        alertCount: 0,
        horizonDays: 15,
        source: 'Estação',
        responsible: 'Gestor',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasClimateEnterpriseRecord(
        id: '2',
        module:
            AtlasClimateEnterpriseModule.climateIntelligence,
        feature: 'Impactos produtivos',
        title: 'Déficit hídrico',
        date: '04/08/2026',
        status: 'Atenção',
        farmName: 'Fazenda A',
        areaName: 'Piquete 2',
        metricName: 'Déficit',
        currentValue: 30,
        projectedValue: 45,
        referenceValue: 15,
        unit: 'mm',
        probabilityPercent: 70,
        confidencePercent: 65,
        riskPercent: 75,
        progressPercent: 50,
        alertCount: 1,
        horizonDays: 10,
        source: 'Estimativa',
        responsible: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasClimateEnterpriseModule.climateIntelligence,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.averageCurrent, 35);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
