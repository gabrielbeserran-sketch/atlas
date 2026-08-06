import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_auth_sync_enterprise/domain/models/atlas_auth_sync_record.dart';
import 'package:projeto_atlas/features/atlas_auth_sync_enterprise/domain/services/atlas_auth_sync_analytics_service.dart';

void main() {
  const service = AtlasAuthSyncAnalyticsService();

  test('calculates auth and sync analytics', () {
    const records = [
      AtlasAuthSyncRecord(
        id: '1',
        module: AtlasAuthSyncModule.synchronizationEngine,
        feature: 'Fila persistente',
        title: 'Fila principal',
        date: '04/08/2026',
        status: 'Ativo',
        priority: 'Alta',
        environment: 'Produção',
        userName: 'Administrador',
        companyName: 'Atlas',
        deviceName: 'Windows',
        resourceName: 'Fila offline',
        versionLabel: 'v1',
        progressPercent: 80,
        successRatePercent: 95,
        riskPercent: 20,
        pendingCount: 2,
        retryCount: 1,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasAuthSyncModule.synchronizationEngine,
      records: records,
    );

    expect(result.recordCount, 1);
    expect(result.operationalCount, 1);
    expect(result.totalPending, 2);
    expect(result.totalRetries, 1);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
