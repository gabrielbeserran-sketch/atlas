import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_global_platform/domain/models/atlas_global_platform_record.dart';
import 'package:projeto_atlas/features/atlas_global_platform/domain/services/atlas_global_platform_analytics_service.dart';

void main() {
  const service = AtlasGlobalPlatformAnalyticsService();

  test('calculates global coverage and alerts', () {
    final records = [
      AtlasGlobalPlatformRecord(
        id: '1',
        feature: AtlasGlobalPlatformFeature.multiCompany,
        title: 'Empresa Atlas',
        date: '04/08/2026',
        status: 'Ativo',
        entityName: 'Empresa Atlas',
        roleOrScope: 'Tenant principal',
        primaryValue: 2,
        secondaryValue: 0,
        unit: 'empresas',
        endpointOrReference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasGlobalPlatformRecord(
        id: '2',
        feature: AtlasGlobalPlatformFeature.publicApi,
        title: 'API de parceiros',
        date: '04/08/2026',
        status: 'Atenção',
        entityName: 'Parceiro A',
        roleOrScope: 'animals.read',
        primaryValue: 100,
        secondaryValue: 0,
        unit: 'req/min',
        endpointOrReference: '/api/public/v1',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(records);

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, 1);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
