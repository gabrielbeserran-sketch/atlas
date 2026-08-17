import 'dart:convert';

class OfflineQueueStats {
  const OfflineQueueStats({
    required this.pending,
    required this.retry,
    required this.conflicts,
    required this.failed,
    required this.accepted,
  });

  final int pending;
  final int retry;
  final int conflicts;
  final int failed;
  final int accepted;

  int get waiting => pending + retry;
  int get attention => conflicts + failed;
  int get total => waiting + attention + accepted;
}

class OfflineConflict {
  const OfflineConflict({
    required this.id,
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.localPayload,
    required this.remotePayload,
    required this.localVersion,
    required this.remoteVersion,
    required this.status,
    required this.createdAt,
    this.serverConflictId,
    this.farmId,
  });

  final String id;
  final String operationId;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> remotePayload;
  final int localVersion;
  final int remoteVersion;
  final String status;
  final DateTime createdAt;
  final String? serverConflictId;
  final String? farmId;

  factory OfflineConflict.fromDatabase(Map<String, Object?> row) {
    return OfflineConflict(
      id: row['id']?.toString() ?? '',
      operationId: row['operation_id']?.toString() ?? '',
      entityType: row['entity_type']?.toString() ?? '',
      entityId: row['entity_id']?.toString() ?? '',
      localPayload: Map<String, dynamic>.from(
        jsonDecode(row['local_payload_json']?.toString() ?? '{}') as Map,
      ),
      remotePayload: Map<String, dynamic>.from(
        jsonDecode(row['remote_payload_json']?.toString() ?? '{}') as Map,
      ),
      localVersion: (row['local_version'] as num?)?.toInt() ?? 0,
      remoteVersion: (row['remote_version'] as num?)?.toInt() ?? 0,
      status: row['status']?.toString() ?? 'open',
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      serverConflictId: row['server_conflict_id']?.toString(),
      farmId: row['farm_id']?.toString(),
    );
  }
}

class OfflineCachedEntity {
  const OfflineCachedEntity({
    required this.entityType,
    required this.entityId,
    required this.companyId,
    required this.tenantId,
    required this.version,
    required this.payload,
    required this.deleted,
    required this.updatedAt,
    this.farmId,
  });

  final String entityType;
  final String entityId;
  final String companyId;
  final String tenantId;
  final String? farmId;
  final int version;
  final Map<String, dynamic> payload;
  final bool deleted;
  final DateTime updatedAt;
}

class OfflineSyncReport {
  const OfflineSyncReport({
    required this.pushed,
    required this.conflicts,
    required this.rejected,
    required this.pulled,
    required this.nextCursor,
    required this.startedAt,
    required this.finishedAt,
  });

  final int pushed;
  final int conflicts;
  final int rejected;
  final int pulled;
  final int nextCursor;
  final DateTime startedAt;
  final DateTime finishedAt;

  Duration get duration => finishedAt.difference(startedAt);
}

class OfflineServerStatus {
  const OfflineServerStatus({
    required this.ready,
    required this.activeDevices,
    required this.openConflicts,
    required this.latestCursor,
    required this.maxBatchSize,
    required this.maxPullPage,
  });

  final bool ready;
  final int activeDevices;
  final int openConflicts;
  final int latestCursor;
  final int maxBatchSize;
  final int maxPullPage;

  factory OfflineServerStatus.fromMap(Map<String, dynamic> map) {
    return OfflineServerStatus(
      ready: map['status']?.toString() == 'ready',
      activeDevices: (map['active_devices'] as num?)?.toInt() ?? 0,
      openConflicts: (map['open_conflicts'] as num?)?.toInt() ?? 0,
      latestCursor: (map['latest_cursor'] as num?)?.toInt() ?? 0,
      maxBatchSize: (map['max_batch_size'] as num?)?.toInt() ?? 200,
      maxPullPage: (map['max_pull_page'] as num?)?.toInt() ?? 1000,
    );
  }
}
