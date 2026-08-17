import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_financial_integrations/domain/models/atlas_financial_integration_record.dart';
import 'package:projeto_atlas/features/atlas_financial_integrations/domain/services/atlas_financial_integration_analytics_service.dart';

void main() {
  const service = AtlasFinancialIntegrationAnalyticsService();

  test('calculates financial integration analytics', () {
    final records = [
      AtlasFinancialIntegrationRecord(
        id: '1',
        module: AtlasFinancialIntegrationModule.receitaFederal,
        feature: 'Cadastro fiscal',
        title: 'Cadastro principal',
        date: '04/08/2026',
        status: 'Concluído',
        externalId: 'RF-001',
        counterparty: 'Receita Federal',
        documentNumber: 'DOC-001',
        amount: 1000,
        feeAmount: 100,
        quantity: 1,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasFinancialIntegrationRecord(
        id: '2',
        module: AtlasFinancialIntegrationModule.receitaFederal,
        feature: 'Pendências fiscais',
        title: 'Pendência',
        date: '04/08/2026',
        status: 'Atenção',
        externalId: '',
        counterparty: '',
        documentNumber: '',
        amount: 0,
        feeAmount: 0,
        quantity: 1,
        progressPercent: 40,
        alertCount: 1,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasFinancialIntegrationModule.receitaFederal,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.netAmount, 900);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
