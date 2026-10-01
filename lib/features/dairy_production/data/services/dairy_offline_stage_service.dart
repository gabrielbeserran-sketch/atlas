import 'dart:convert';

import 'package:projeto_atlas/core/offline/database/atlas_offline_database.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_herd_snapshot_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DairyStageReport {
  const DairyStageReport({
    required this.added,
    required this.unchanged,
    required this.needsReview,
  });

  final int added;
  final int unchanged;
  final int needsReview;
}

/// Copies legacy local records into a scoped, unsent table. Nothing here
/// changes SharedPreferences, the generic cache or the operation queue.
class DairyOfflineStageService {
  DairyOfflineStageService({
    Database? database,
    DairyProductionStorageService? productionStorage,
    DairyHerdSnapshotStorageService? snapshotStorage,
  }) : _database = database,
       _productionStorage =
           productionStorage ?? DairyProductionStorageService(),
       _snapshotStorage = snapshotStorage ?? DairyHerdSnapshotStorageService();

  final Database? _database;
  final DairyProductionStorageService _productionStorage;
  final DairyHerdSnapshotStorageService _snapshotStorage;

  Future<DairyStageReport> stage({
    required String companyId,
    required String tenantId,
    required String farmId,
  }) async {
    if (companyId.trim().isEmpty ||
        tenantId.trim().isEmpty ||
        farmId.trim().isEmpty) {
      throw StateError('Empresa, tenant e fazenda são obrigatórios.');
    }
    // Load both sources strictly before opening a transaction. A corrupt
    // legacy list must never be mistaken for an empty farm.
    final production = await _productionStorage.load(farmId, strict: true);
    final snapshots = await _snapshotStorage.load(farmId, strict: true);
    final candidates = <_StageCandidate>[];
    var needsReview = 0;
    for (final record in production) {
      try {
        record.validateForSave();
        candidates.add(_dailyCandidate(farmId, record));
      } catch (_) {
        needsReview++;
      }
    }
    for (final snapshot in snapshots) {
      try {
        snapshot.validate();
        candidates.add(_snapshotCandidate(farmId, snapshot));
      } catch (_) {
        needsReview++;
      }
    }

    final db = _database ?? await AtlasOfflineDatabase.instance.database;
    var added = 0;
    var unchanged = 0;
    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'dairy_sync_stage',
        where: 'company_id = ? AND tenant_id = ? AND farm_id = ?',
        whereArgs: <Object?>[companyId, tenantId, farmId],
      );
      final existingByKey = <String, String>{
        for (final row in existingRows)
          '${row['entity_type']}:${row['entity_id']}':
              row['payload_json']?.toString() ?? '',
      };
      for (final candidate in candidates) {
        final key = '${candidate.entityType}:${candidate.entityId}';
        final payloadJson = jsonEncode(candidate.payload);
        final prior = existingByKey[key];
        if (prior != null) {
          if (prior != payloadJson) {
            // Keep both originals available for a later conflict decision.
            needsReview++;
            continue;
          }
          unchanged++;
          continue;
        }
        await txn.insert('dairy_sync_stage', <String, Object?>{
          'company_id': companyId,
          'tenant_id': tenantId,
          'farm_id': farmId,
          'entity_type': candidate.entityType,
          'entity_id': candidate.entityId,
          'payload_json': payloadJson,
          'staged_at': DateTime.now().toUtc().toIso8601String(),
        });
        existingByKey[key] = payloadJson;
        added++;
      }
    });
    return DairyStageReport(
      added: added,
      unchanged: unchanged,
      needsReview: needsReview,
    );
  }

  static String entityId(String farmId, DateTime date) =>
      '$farmId:${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static _StageCandidate _dailyCandidate(
    String farmId,
    DairyDailyProductionData value,
  ) => _StageCandidate(
    'dairy_daily_production',
    entityId(farmId, value.date),
    <String, dynamic>{...value.toMap(), 'farm_id': farmId},
  );

  static _StageCandidate _snapshotCandidate(
    String farmId,
    DairyHerdSnapshotData value,
  ) => _StageCandidate(
    'dairy_herd_snapshot',
    entityId(farmId, value.date),
    <String, dynamic>{...value.toMap(), 'farm_id': farmId},
  );
}

class _StageCandidate {
  const _StageCandidate(this.entityType, this.entityId, this.payload);
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
}

enum DairyReviewStatus {
  waitingForCache,
  sameAsCached,
  differsFromCached,
  deletedInCache,
  localChanged,
  localMissing,
  invalidStage,
  invalidCache,
  scopeConflict,
}

class DairyReviewItem {
  const DairyReviewItem(this.entityType, this.entityId, this.status);
  final String entityType;
  final String entityId;
  final DairyReviewStatus status;

  bool get needsDecision => !const {
    DairyReviewStatus.waitingForCache,
    DairyReviewStatus.sameAsCached,
  }.contains(status);
}

class DairyReviewReport {
  const DairyReviewReport(this.items);
  final List<DairyReviewItem> items;

  int get waiting => items
      .where((item) => item.status == DairyReviewStatus.waitingForCache)
      .length;
  int get matchingCache => items
      .where((item) => item.status == DairyReviewStatus.sameAsCached)
      .length;
  int get needingDecision => items.where((item) => item.needsDecision).length;
}

/// A cached server value is only the last received copy, never proof that the
/// live server still has it. This review makes no promotion or network call.
class DairyOfflineReviewService {
  DairyOfflineReviewService({
    Database? database,
    DairyProductionStorageService? productionStorage,
    DairyHerdSnapshotStorageService? snapshotStorage,
  }) : _database = database,
       _productionStorage =
           productionStorage ?? DairyProductionStorageService(),
       _snapshotStorage = snapshotStorage ?? DairyHerdSnapshotStorageService();

  final Database? _database;
  final DairyProductionStorageService _productionStorage;
  final DairyHerdSnapshotStorageService _snapshotStorage;

  Future<DairyReviewReport> review({
    required String companyId,
    required String tenantId,
    required String farmId,
  }) async {
    if (companyId.trim().isEmpty ||
        tenantId.trim().isEmpty ||
        farmId.trim().isEmpty) {
      throw StateError('Empresa, tenant e fazenda são obrigatórios.');
    }
    final production = await _productionStorage.load(farmId, strict: true);
    final snapshots = await _snapshotStorage.load(farmId, strict: true);
    final local = <String, Map<String, dynamic>>{};
    final duplicates = <String>{};
    for (final candidate in [
      ...production.map(
        (value) => DairyOfflineStageService._dailyCandidate(farmId, value),
      ),
      ...snapshots.map(
        (value) => DairyOfflineStageService._snapshotCandidate(farmId, value),
      ),
    ]) {
      final key = '${candidate.entityType}:${candidate.entityId}';
      if (local.containsKey(key)) duplicates.add(key);
      local[key] = candidate.payload;
    }

    final db = _database ?? await AtlasOfflineDatabase.instance.database;
    final staged = await db.query(
      'dairy_sync_stage',
      where: 'company_id = ? AND tenant_id = ? AND farm_id = ?',
      whereArgs: <Object?>[companyId, tenantId, farmId],
      orderBy: 'entity_type, entity_id',
    );
    final cacheRows = await db.query(
      'entity_cache',
      where: 'company_id = ? AND entity_type IN (?, ?)',
      whereArgs: <Object?>[
        companyId,
        'dairy_daily_production',
        'dairy_herd_snapshot',
      ],
    );
    final cacheByKey = <String, Map<String, Object?>>{
      for (final row in cacheRows)
        '${row['entity_type']}:${row['entity_id']}': row,
    };
    final items = <DairyReviewItem>[];
    for (final row in staged) {
      final type = row['entity_type']?.toString() ?? '';
      final id = row['entity_id']?.toString() ?? '';
      final payload = _decodeMap(row['payload_json']);
      DairyReviewStatus status;
      final date = id.startsWith('$farmId:')
          ? id.substring(farmId.length + 1)
          : '';
      final rawPayloadDate = payload?['date'];
      if (!const {
            'dairy_daily_production',
            'dairy_herd_snapshot',
          }.contains(type) ||
          !_validDay(date) ||
          payload == null ||
          payload['farm_id'] != farmId ||
          rawPayloadDate is! String ||
          rawPayloadDate.length < 10 ||
          rawPayloadDate.substring(0, 10) != date) {
        status = DairyReviewStatus.invalidStage;
      } else {
        final key = '$type:$id';
        final current = local[key];
        if (current == null) {
          status = DairyReviewStatus.localMissing;
        } else if (duplicates.contains(key) || !_sameJson(current, payload)) {
          status = DairyReviewStatus.localChanged;
        } else {
          final remote = cacheByKey[key];
          if (remote == null) {
            status = DairyReviewStatus.waitingForCache;
          } else {
            if (remote['tenant_id'] != tenantId ||
                remote['farm_id'] != farmId) {
              status = DairyReviewStatus.scopeConflict;
            } else if ((remote['version'] as num?)?.toInt() == null ||
                (remote['version'] as num).toInt() <= 0 ||
                (remote['deleted'] != 0 && remote['deleted'] != 1)) {
              status = DairyReviewStatus.invalidCache;
            } else if (remote['deleted'] == 1) {
              status = DairyReviewStatus.deletedInCache;
            } else {
              final cachedPayload = _decodeMap(remote['payload_json']);
              status = cachedPayload == null
                  ? DairyReviewStatus.invalidCache
                  : _sameJson(payload, cachedPayload)
                  ? DairyReviewStatus.sameAsCached
                  : DairyReviewStatus.differsFromCached;
            }
          }
        }
      }
      items.add(DairyReviewItem(type, id, status));
    }
    return DairyReviewReport(List.unmodifiable(items));
  }

  static Map<String, dynamic>? _decodeMap(Object? raw) {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw.toString()) as Map);
    } catch (_) {
      return null;
    }
  }

  static bool _validDay(String raw) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return false;
    final date = DateTime.tryParse(raw);
    if (date == null) return false;
    return '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}' ==
        raw;
  }

  static bool _sameJson(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key) || !_sameJson(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_sameJson(left[index], right[index])) return false;
      }
      return true;
    }
    return left == right;
  }
}
