import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_governance_operations/domain/models/atlas_governance_operation_record.dart';
import 'package:projeto_atlas/features/atlas_governance_operations/domain/services/atlas_governance_operation_analytics_service.dart';

void main() {
  const service = AtlasGovernanceOperationAnalyticsService();

  test('calculates governance analytics', () {
    final records = [
      AtlasGovernanceOperationRecord(
        id: '1',
        module: AtlasGovernanceOperationModule.qualityManagement,
        feature: 'Padrões e procedimentos',
        title: 'Procedimento de manejo',
        date: '04/08/2026',
        status: 'Conforme',
        responsible: 'Equipe de qualidade',
        externalId: 'POP-001',
        amount: 10000,
        costAmount: 1000,
        quantity: 5,
        scoreValue: 92,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasGovernanceOperationRecord(
        id: '2',
        module: AtlasGovernanceOperationModule.qualityManagement,
        feature: 'Não conformidades',
        title: 'Ação pendente',
        date: '04/08/2026',
        status: 'Atenção',
        responsible: '',
        externalId: '',
        amount: 0,
        costAmount: 0,
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
      module: AtlasGovernanceOperationModule.qualityManagement,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.netAmount, 9000);
    expect(result.totalQuantity, 6);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
