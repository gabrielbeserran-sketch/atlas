import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_rural_business/domain/models/atlas_rural_business_record.dart';
import 'package:projeto_atlas/features/atlas_rural_business/domain/services/atlas_rural_business_analytics_service.dart';

void main() {
  const service = AtlasRuralBusinessAnalyticsService();

  test('calculates rural business analytics', () {
    final records = [
      AtlasRuralBusinessRecord(
        id: '1',
        module: AtlasRuralBusinessModule.ruralCredit,
        feature: 'Linhas de crédito',
        title: 'Crédito de custeio',
        date: '04/08/2026',
        status: 'Aprovado',
        counterparty: 'Banco',
        externalId: 'PROP-001',
        amount: 100000,
        costAmount: 15000,
        quantity: 12,
        termDays: 365,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasRuralBusinessRecord(
        id: '2',
        module: AtlasRuralBusinessModule.ruralCredit,
        feature: 'Garantias e documentos',
        title: 'Documento pendente',
        date: '04/08/2026',
        status: 'Atenção',
        counterparty: '',
        externalId: '',
        amount: 0,
        costAmount: 0,
        quantity: 1,
        termDays: 0,
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
      module: AtlasRuralBusinessModule.ruralCredit,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.netAmount, 85000);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
