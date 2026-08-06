import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_cloud_security_enterprise/domain/models/atlas_cloud_security_record.dart';
import 'package:projeto_atlas/features/atlas_cloud_security_enterprise/domain/services/atlas_cloud_security_analytics_service.dart';

void main() {
  const service = AtlasCloudSecurityAnalyticsService();

  test('calculates cloud security analytics', () {
    final records = [
      AtlasCloudSecurityRecord(
        id: '1',
        module:
            AtlasCloudSecurityModule.professionalAuthentication,
        feature: 'Login seguro',
        title: 'Autenticação principal',
        date: '04/08/2026',
        dueDate: '10/08/2026',
        status: 'Seguro',
        priority: 'Alta',
        environment: 'Produção',
        resourceName: 'Login',
        userName: 'Administrador',
        companyName: 'Atlas',
        providerName: 'Provedor A',
        versionLabel: 'v1',
        progressPercent: 100,
        availabilityPercent: 99.9,
        riskPercent: 10,
        alertCount: 0,
        retryCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasCloudSecurityRecord(
        id: '2',
        module:
            AtlasCloudSecurityModule.professionalAuthentication,
        feature: 'Autenticação multifator',
        title: 'MFA pendente',
        date: '04/08/2026',
        dueDate: '01/08/2026',
        status: 'Atenção',
        priority: 'Urgente',
        environment: 'Produção',
        resourceName: 'MFA',
        userName: '',
        companyName: 'Atlas',
        providerName: '',
        versionLabel: '',
        progressPercent: 40,
        availabilityPercent: 80,
        riskPercent: 75,
        alertCount: 1,
        retryCount: 2,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasCloudSecurityModule.professionalAuthentication,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalRetries, 2);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
