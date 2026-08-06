import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_platform_resilience/domain/models/atlas_platform_resilience_record.dart';
import 'package:projeto_atlas/features/atlas_platform_resilience/domain/services/atlas_platform_resilience_analytics_service.dart';

void main() {
  const service =
      AtlasPlatformResilienceAnalyticsService();

  test('calculates platform resilience analytics', () {
    final records = [
      AtlasPlatformResilienceRecord(
        id: '1',
        module:
            AtlasPlatformResilienceModule.dataGovernance,
        feature: 'Catálogo de dados',
        title: 'Cadastro de animais',
        date: '04/08/2026',
        status: 'Conforme',
        owner: 'Responsável de dados',
        externalId: 'DATA-001',
        primaryValue: 95,
        secondaryValue: 90,
        financialImpact: 20000,
        quantity: 1,
        scoreValue: 92,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasPlatformResilienceRecord(
        id: '2',
        module:
            AtlasPlatformResilienceModule.dataGovernance,
        feature: 'Qualidade e completude',
        title: 'Campos incompletos',
        date: '04/08/2026',
        status: 'Atenção',
        owner: '',
        externalId: '',
        primaryValue: 0,
        secondaryValue: 0,
        financialImpact: 5000,
        quantity: 10,
        scoreValue: 45,
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
          AtlasPlatformResilienceModule.dataGovernance,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.financialImpact, 25000);
    expect(result.totalQuantity, 11);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
