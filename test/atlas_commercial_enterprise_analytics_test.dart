import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_commercial_enterprise/domain/models/atlas_commercial_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_commercial_enterprise/domain/services/atlas_commercial_enterprise_analytics_service.dart';

void main() {
  const service =
      AtlasCommercialEnterpriseAnalyticsService();

  test('calculates commercial enterprise analytics', () {
    final records = [
      AtlasCommercialEnterpriseRecord(
        id: '1',
        module: AtlasCommercialEnterpriseModule.premiumCrm,
        feature: 'Leads e oportunidades',
        title: 'Oportunidade A',
        date: '04/08/2026',
        status: 'Ganho',
        customerName: 'Cliente A',
        companyName: 'Empresa Atlas',
        referenceId: 'OPP-001',
        stage: 'Fechado',
        owner: 'Comercial',
        potentialValue: 100000,
        actualValue: 90000,
        probabilityPercent: 100,
        progressPercent: 100,
        satisfactionPercent: 90,
        alertCount: 0,
        dueDate: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasCommercialEnterpriseRecord(
        id: '2',
        module: AtlasCommercialEnterpriseModule.premiumCrm,
        feature: 'Tarefas comerciais',
        title: 'Retorno pendente',
        date: '04/08/2026',
        status: 'Atenção',
        customerName: 'Cliente B',
        companyName: 'Empresa Atlas',
        referenceId: 'OPP-002',
        stage: 'Proposta',
        owner: '',
        potentialValue: 50000,
        actualValue: 0,
        probabilityPercent: 40,
        progressPercent: 50,
        satisfactionPercent: 0,
        alertCount: 1,
        dueDate: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasCommercialEnterpriseModule.premiumCrm,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalPotentialValue, 150000);
    expect(result.totalActualValue, 90000);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
