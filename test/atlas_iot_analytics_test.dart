import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_iot_platform/domain/models/atlas_iot_record.dart';
import 'package:projeto_atlas/features/atlas_iot_platform/domain/services/atlas_iot_analytics_service.dart';

void main() {
  const service = AtlasIotAnalyticsService();

  test('calculates IoT analytics', () {
    final records = [
      AtlasIotRecord(
        id: '1',
        module: AtlasIotModule.smartScales,
        feature: 'Leituras de peso',
        title: 'Balança principal',
        date: '04/08/2026',
        status: 'Ativo',
        deviceId: 'BAL-001',
        location: 'Curral',
        metricName: 'Peso',
        metricValue: 450,
        unit: 'kg',
        signalPercent: 90,
        batteryPercent: 80,
        alertCount: 0,
        lastSync: '04/08/2026 10:00',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasIotRecord(
        id: '2',
        module: AtlasIotModule.smartScales,
        feature: 'Alertas de inconsistência',
        title: 'Leitura divergente',
        date: '04/08/2026',
        status: 'Atenção',
        deviceId: 'BAL-001',
        location: 'Curral',
        metricName: 'Peso',
        metricValue: 900,
        unit: 'kg',
        signalPercent: 50,
        batteryPercent: 30,
        alertCount: 1,
        lastSync: '04/08/2026 10:05',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasIotModule.smartScales,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.averageMetric, 675);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
