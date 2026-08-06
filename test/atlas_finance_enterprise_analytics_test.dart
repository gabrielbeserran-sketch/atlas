import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_finance_enterprise/domain/models/atlas_finance_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_finance_enterprise/domain/services/atlas_finance_enterprise_analytics_service.dart';

void main() {
  const service =
      AtlasFinanceEnterpriseAnalyticsService();

  test('calculates finance enterprise analytics', () {
    final records = [
      AtlasFinanceEnterpriseRecord(
        id: '1',
        module:
            AtlasFinanceEnterpriseModule.projectedCashFlow,
        feature: 'Receitas projetadas',
        title: 'Receita mensal',
        date: '04/08/2026',
        status: 'Validado',
        companyName: 'Empresa Atlas',
        farmName: 'Fazenda A',
        category: 'Venda de animais',
        plannedValue: 100000,
        actualValue: 95000,
        projectedValue: 110000,
        referenceValue: 90000,
        riskPercent: 20,
        confidencePercent: 90,
        progressPercent: 100,
        alertCount: 0,
        periodLabel: 'Agosto/2026',
        responsible: 'Financeiro',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasFinanceEnterpriseRecord(
        id: '2',
        module:
            AtlasFinanceEnterpriseModule.projectedCashFlow,
        feature: 'Alertas de liquidez',
        title: 'Risco de caixa',
        date: '04/08/2026',
        status: 'Atenção',
        companyName: 'Empresa Atlas',
        farmName: 'Fazenda A',
        category: 'Caixa',
        plannedValue: 50000,
        actualValue: 30000,
        projectedValue: 20000,
        referenceValue: 40000,
        riskPercent: 70,
        confidencePercent: 60,
        progressPercent: 50,
        alertCount: 1,
        periodLabel: 'Setembro/2026',
        responsible: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasFinanceEnterpriseModule.projectedCashFlow,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalPlanned, 150000);
    expect(result.totalActual, 125000);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
