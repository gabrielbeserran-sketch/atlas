
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_backend_foundation/domain/models/atlas_backend_foundation_record.dart';
import 'package:projeto_atlas/features/atlas_backend_foundation/domain/services/atlas_backend_foundation_analytics_service.dart';

void main() {
  test('calcula analytics do backend', () {
    const service = AtlasBackendFoundationAnalyticsService();
    const record = AtlasBackendFoundationRecord(
      id: '1',
      module: AtlasBackendFoundationModule.backendFoundation,
      feature: 'Rotas e controladores',
      title: 'API principal',
      date: '04/08/2026',
      status: 'Ativo',
      priority: 'Alta',
      environment: 'Desenvolvimento',
      resourceName: 'Backend',
      routeOrTable: '/health',
      companyName: 'Atlas',
      ownerName: 'Equipe',
      progressPercent: 80,
      availabilityPercent: 99,
      errorRatePercent: 1,
      latencyMs: 120,
      alertCount: 0,
      notes: '',
      createdAt: '',
      updatedAt: '',
    );

    final result = service.analyze(
      module: AtlasBackendFoundationModule.backendFoundation,
      records: const [record],
    );

    expect(result.recordCount, 1);
    expect(result.operationalCount, 1);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
