import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/platform_hubs/domain/models/atlas_hub_snapshot.dart';

void main() {
  test('converte métricas e registros', () {
    final snapshot = AtlasHubSnapshot.fromMap('Teste', {
      'devices': 4,
      'alerts': '2',
      'items': [
        {'id': '1'},
      ],
    });

    expect(snapshot.metricAsInt('devices'), 4);
    expect(snapshot.metricAsInt('alerts'), 2);
    expect(snapshot.records, hasLength(1));
  });
}
