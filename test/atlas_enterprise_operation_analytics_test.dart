import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_enterprise_operations/domain/models/atlas_enterprise_operation_record.dart';
import 'package:projeto_atlas/features/atlas_enterprise_operations/domain/services/atlas_enterprise_operation_analytics_service.dart';

void main() {
  const service =
      AtlasEnterpriseOperationAnalyticsService();

  test('calculates enterprise operation analytics', () {
    final records = [
      AtlasEnterpriseOperationRecord(
        id: '1',
        module: AtlasEnterpriseOperationModule.procurement,
        feature: 'Requisições de compra',
        title: 'Compra de suplemento',
        date: '04/08/2026',
        status: 'Aprovado',
        counterparty: 'Fornecedor A',
        externalId: 'REQ-001',
        amount: 10000,
        costAmount: 500,
        quantity: 50,
        stockLevel: 20,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasEnterpriseOperationRecord(
        id: '2',
        module: AtlasEnterpriseOperationModule.procurement,
        feature: 'Recebimento e conferência',
        title: 'Conferência pendente',
        date: '04/08/2026',
        status: 'Atenção',
        counterparty: '',
        externalId: '',
        amount: 0,
        costAmount: 0,
        quantity: 1,
        stockLevel: 0,
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
      module: AtlasEnterpriseOperationModule.procurement,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.netAmount, 9500);
    expect(result.totalQuantity, 51);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
