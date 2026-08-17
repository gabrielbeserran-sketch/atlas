import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/data_intelligence/domain/models/atlas_data_intelligence_snapshot.dart';

void main() {
  test('consolida métricas e registros', () {
    final s = AtlasDataIntelligenceSnapshot.fromResponses(
      analytics: {
        'kpis': 3,
        'records': [
          {'id': '1'},
        ],
      },
      platform: {'jobs': 2},
      realtime: [
        {'value': 10},
      ],
    );
    expect(s.intMetric('kpis'), 3);
    expect(s.intMetric('jobs'), 2);
    expect(s.records('records'), hasLength(1));
  });
}
