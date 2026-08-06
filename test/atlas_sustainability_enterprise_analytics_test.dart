import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_sustainability_enterprise/domain/models/atlas_sustainability_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_sustainability_enterprise/domain/services/atlas_sustainability_enterprise_analytics_service.dart';

void main() {
  const service =
      AtlasSustainabilityEnterpriseAnalyticsService();

  test('calculates sustainability analytics', () {
    final records = [
      AtlasSustainabilityEnterpriseRecord(
        id: '1',
        module:
            AtlasSustainabilityEnterpriseModule.carbonFootprint,
        feature: 'Emissões por atividade',
        title: 'Emissão anual',
        date: '04/08/2026',
        status: 'Validado',
        companyName: 'Empresa Atlas',
        farmName: 'Fazenda A',
        scope: 'Pecuária',
        metricName: 'Emissões',
        currentValue: 900,
        baselineValue: 1000,
        targetValue: 800,
        unit: 'tCO2e',
        qualityPercent: 90,
        progressPercent: 70,
        alertCount: 0,
        dueDate: '',
        responsible: 'Gestor ESG',
        evidence: 'Inventário interno',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasSustainabilityEnterpriseRecord(
        id: '2',
        module:
            AtlasSustainabilityEnterpriseModule.carbonFootprint,
        feature: 'Meta de redução',
        title: 'Meta pendente',
        date: '04/08/2026',
        status: 'Atenção',
        companyName: 'Empresa Atlas',
        farmName: 'Fazenda A',
        scope: 'Pecuária',
        metricName: 'Redução',
        currentValue: 5,
        baselineValue: 0,
        targetValue: 20,
        unit: '%',
        qualityPercent: 60,
        progressPercent: 25,
        alertCount: 1,
        dueDate: '',
        responsible: '',
        evidence: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasSustainabilityEnterpriseModule.carbonFootprint,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalCurrentValue, 905);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
