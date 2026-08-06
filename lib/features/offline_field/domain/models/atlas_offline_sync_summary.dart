import 'atlas_offline_record.dart';

class AtlasOfflineSyncSummary {
  const AtlasOfflineSyncSummary({
    required this.total,
    required this.pending,
    required this.synchronized,
    required this.failed,
    required this.lastActivityAt,
  });

  final int total;
  final int pending;
  final int synchronized;
  final int failed;
  final DateTime? lastActivityAt;

  double get completionRate {
    if (total == 0) {
      return 0;
    }

    return synchronized / total * 100;
  }

  factory AtlasOfflineSyncSummary.fromRecords(
    List<AtlasOfflineRecord> records,
  ) {
    DateTime? lastActivityAt;

    for (final AtlasOfflineRecord record in records) {
      if (lastActivityAt == null || record.updatedAt.isAfter(lastActivityAt)) {
        lastActivityAt = record.updatedAt;
      }
    }

    return AtlasOfflineSyncSummary(
      total: records.length,
      pending: records.where((AtlasOfflineRecord record) {
        return record.status == AtlasOfflineRecordStatus.pending ||
            record.status == AtlasOfflineRecordStatus.syncing;
      }).length,
      synchronized: records.where((AtlasOfflineRecord record) {
        return record.status == AtlasOfflineRecordStatus.synchronized;
      }).length,
      failed: records.where((AtlasOfflineRecord record) {
        return record.status == AtlasOfflineRecordStatus.failed;
      }).length,
      lastActivityAt: lastActivityAt,
    );
  }
}
