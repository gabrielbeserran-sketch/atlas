import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_enterprise_50/domain/models/atlas_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_enterprise_50/domain/services/atlas_enterprise_analytics_service.dart';

void main() {
  test('analytics calculates progress, alerts and value', () {
    const service = AtlasEnterpriseAnalyticsService();
    final records = [
      AtlasEnterpriseRecord(
        id: '1',
        packageId: 31,
        stepId: 1,
        title: 'Receita',
        date: '01/01/2026',
        quantity: 2,
        unitValue: 100,
        status: 'Concluído',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasEnterpriseRecord(
        id: '2',
        packageId: 31,
        stepId: 2,
        title: 'Despesa',
        date: '01/01/2026',
        quantity: 1,
        unitValue: 50,
        status: 'Atenção',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];
    final result = service.analyze(records: records, totalCapabilities: 5);
    expect(result.totalRecords, 2);
    expect(result.completedRecords, 1);
    expect(result.alertRecords, 1);
    expect(result.totalValue, 250);
    expect(result.progressPercent, 40);
  });
}
