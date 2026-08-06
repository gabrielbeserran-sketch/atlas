import 'package:projeto_atlas/features/sync_platform/domain/models/atlas_sync_data.dart';

class AtlasSyncEngine {
  const AtlasSyncEngine();

  AtlasSyncSummary summarize(List<AtlasSyncItem> items) {
    final int pending = items.where((AtlasSyncItem item) => item.status == AtlasSyncStatus.pending || item.status == AtlasSyncStatus.syncing).length;
    final int synced = items.where((AtlasSyncItem item) => item.status == AtlasSyncStatus.synced).length;
    final int failed = items.where((AtlasSyncItem item) => item.status == AtlasSyncStatus.failed).length;
    final int conflicts = items.where((AtlasSyncItem item) => item.status == AtlasSyncStatus.conflict).length;
    final int processed = synced + failed + conflicts;
    final double successRate = processed == 0 ? 100 : (synced / processed) * 100;
    final Set<String> modules = items
        .where((AtlasSyncItem item) => item.status != AtlasSyncStatus.synced)
        .map((AtlasSyncItem item) => item.module)
        .toSet();
    return AtlasSyncSummary(
      total: items.length,
      pending: pending,
      synced: synced,
      failed: failed,
      conflicts: conflicts,
      successRate: successRate,
      modulesWithPendingItems: modules.length,
    );
  }

  List<AtlasSyncItem> ordered(List<AtlasSyncItem> items) {
    final List<AtlasSyncItem> result = List<AtlasSyncItem>.from(items);
    result.sort((AtlasSyncItem a, AtlasSyncItem b) {
      final int statusA = _statusWeight(a.status);
      final int statusB = _statusWeight(b.status);
      if (statusA != statusB) {
        return statusB.compareTo(statusA);
      }
      final int priority = b.priority.index.compareTo(a.priority.index);
      if (priority != 0) {
        return priority;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return result;
  }

  int _statusWeight(AtlasSyncStatus status) {
    switch (status) {
      case AtlasSyncStatus.conflict:
        return 5;
      case AtlasSyncStatus.failed:
        return 4;
      case AtlasSyncStatus.pending:
        return 3;
      case AtlasSyncStatus.syncing:
        return 2;
      case AtlasSyncStatus.synced:
        return 1;
    }
  }
}
