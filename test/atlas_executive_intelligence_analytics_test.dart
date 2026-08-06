import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_executive_intelligence/domain/models/atlas_executive_intelligence_record.dart';
import 'package:projeto_atlas/features/atlas_executive_intelligence/domain/services/atlas_executive_intelligence_analytics_service.dart';

void main() {
  const service =
      AtlasExecutiveIntelligenceAnalyticsService();

  test('calculates executive intelligence analytics', () {
    final records = [
      AtlasExecutiveIntelligenceRecord(
        id: '1',
        module:
            AtlasExecutiveIntelligenceModule.enterpriseCrm,
        feature: 'Clientes e propriedades',
        title: 'Cliente principal',
        date: '04/08/2026',
        status: 'Ativo',
        responsible: 'Consultor',
        externalId: 'CLI-001',
        primaryValue: 100,
        secondaryValue: 80,
        financialImpact: 50000,
        quantity: 1,
        scoreValue: 90,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasExecutiveIntelligenceRecord(
        id: '2',
        module:
            AtlasExecutiveIntelligenceModule.enterpriseCrm,
        feature: 'Pipeline comercial',
        title: 'Proposta pendente',
        date: '04/08/2026',
        status: 'Atenção',
        responsible: '',
        externalId: '',
        primaryValue: 0,
        secondaryValue: 0,
        financialImpact: 15000,
        quantity: 1,
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
          AtlasExecutiveIntelligenceModule.enterpriseCrm,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.financialImpact, 65000);
    expect(result.totalQuantity, 2);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
