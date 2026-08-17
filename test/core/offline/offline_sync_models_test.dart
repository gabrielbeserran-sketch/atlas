import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/models/offline_sync_models.dart';

void main() {
  test('queue stats consolida itens aguardando e itens de atenção', () {
    const stats = OfflineQueueStats(
      pending: 4,
      retry: 2,
      conflicts: 1,
      failed: 3,
      accepted: 8,
    );
    expect(stats.waiting, 6);
    expect(stats.attention, 4);
    expect(stats.total, 18);
  });

  test('status remoto interpreta limites e cursor', () {
    final status = OfflineServerStatus.fromMap(<String, dynamic>{
      'status': 'ready',
      'active_devices': 2,
      'open_conflicts': 3,
      'latest_cursor': 47,
      'max_batch_size': 200,
      'max_pull_page': 1000,
    });
    expect(status.ready, isTrue);
    expect(status.activeDevices, 2);
    expect(status.openConflicts, 3);
    expect(status.latestCursor, 47);
  });
}
