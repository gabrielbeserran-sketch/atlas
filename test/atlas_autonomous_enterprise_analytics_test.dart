import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_autonomous_enterprise/domain/models/atlas_autonomous_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_autonomous_enterprise/domain/services/atlas_autonomous_enterprise_analytics_service.dart';

void main() {
  const service = AtlasAutonomousEnterpriseAnalyticsService();

  test('calculates autonomous enterprise analytics', () {
    final records = [
      AtlasAutonomousEnterpriseRecord(
        id: '1',
        module: AtlasAutonomousEnterpriseModule.aiOrchestrator,
        feature: 'Fila de decisões',
        title: 'Recomendação aprovada',
        date: '04/08/2026',
        status: 'Aprovado',
        owner: 'Gestor',
        externalId: 'DEC-001',
        priority: 5,
        confidencePercent: 90,
        riskPercent: 20,
        financialImpact: 50000,
        quantity: 1,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasAutonomousEnterpriseRecord(
        id: '2',
        module: AtlasAutonomousEnterpriseModule.aiOrchestrator,
        feature: 'Aprovação humana',
        title: 'Decisão pendente',
        date: '04/08/2026',
        status: 'Atenção',
        owner: '',
        externalId: '',
        priority: 4,
        confidencePercent: 60,
        riskPercent: 65,
        financialImpact: 10000,
        quantity: 1,
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
      module: AtlasAutonomousEnterpriseModule.aiOrchestrator,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.financialImpact, 60000);
    expect(result.totalQuantity, 2);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
