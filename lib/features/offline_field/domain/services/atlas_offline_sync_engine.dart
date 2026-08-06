import '../models/atlas_offline_record.dart';

class AtlasOfflineSyncEngine {
  const AtlasOfflineSyncEngine();

  Future<List<AtlasOfflineRecord>> synchronize({
    required List<AtlasOfflineRecord> records,
    required bool online,
  }) async {
    if (!online) {
      return records;
    }

    final List<AtlasOfflineRecord> updated = <AtlasOfflineRecord>[];

    for (final AtlasOfflineRecord record in records) {
      if (record.status == AtlasOfflineRecordStatus.synchronized) {
        updated.add(record);
        continue;
      }

      await Future<void>.delayed(const Duration(milliseconds: 90));

      updated.add(
        record.copyWith(
          status: AtlasOfflineRecordStatus.synchronized,
          updatedAt: DateTime.now(),
          attempts: record.attempts + 1,
          lastError: '',
        ),
      );
    }

    return updated;
  }

  List<AtlasOfflineRecord> queueRecord({
    required List<AtlasOfflineRecord> records,
    required AtlasOfflineRecord record,
  }) {
    return <AtlasOfflineRecord>[
      record,
      ...records,
    ];
  }
}
