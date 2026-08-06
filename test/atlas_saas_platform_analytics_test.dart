import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_saas_platform/domain/models/atlas_saas_platform_record.dart';
import 'package:projeto_atlas/features/atlas_saas_platform/domain/services/atlas_saas_platform_analytics_service.dart';

void main() {
  const service = AtlasSaasPlatformAnalyticsService();

  test('calculates SaaS platform analytics', () {
    final records = [
      AtlasSaasPlatformRecord(
        id: '1',
        module: AtlasSaasPlatformModule.accessControl,
        feature: 'Usuários',
        title: 'Administrador',
        date: '04/08/2026',
        status: 'Ativo',
        owner: 'Administrador geral',
        externalId: 'USR-001',
        companyName: 'Empresa Atlas',
        farmName: 'Fazenda A',
        amount: 100,
        quantity: 1,
        usagePercent: 80,
        progressPercent: 100,
        alertCount: 0,
        dueDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasSaasPlatformRecord(
        id: '2',
        module: AtlasSaasPlatformModule.accessControl,
        feature: 'Permissões',
        title: 'Revisão pendente',
        date: '04/08/2026',
        status: 'Atenção',
        owner: '',
        externalId: '',
        companyName: '',
        farmName: '',
        amount: 0,
        quantity: 1,
        usagePercent: 40,
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
      module: AtlasSaasPlatformModule.accessControl,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalAmount, 100);
    expect(result.totalQuantity, 2);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
