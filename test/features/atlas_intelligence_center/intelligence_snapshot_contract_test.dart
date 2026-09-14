import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('prioridades e cenários reutilizam o contexto da fazenda', () {
    final screen = read(
      'lib/features/atlas_intelligence_center/presentation/screens/atlas_intelligence_center_screen.dart',
    );
    final service = read(
      'lib/features/atlas_intelligence_center/data/services/atlas_intelligence_service.dart',
    );
    final router = read('backend/app/routers/ai_operational.py');

    expect(screen, contains('String? contextSnapshotId;'));
    expect(screen, contains('Future<void> ensureSnapshot(String farmId)'));
    expect(screen, contains('contextSnapshotId: contextSnapshotId'));
    expect(service, contains("'context_snapshot_id': contextSnapshotId"));
    expect(router, contains('class RecommendationsIn(BaseModel)'));
    expect(router, contains('Snapshot de contexto não encontrado.'));
    expect(router, contains("'context_snapshot_id':payload.context_snapshot_id or ''"));
  });
}
