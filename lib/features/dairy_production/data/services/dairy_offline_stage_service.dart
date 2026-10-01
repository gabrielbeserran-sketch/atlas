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
      for (final candidate in candidates) {
        final keyArgs = <Object?>[
          companyId,
          tenantId,
          farmId,
          candidate.entityType,
          candidate.entityId,
        ];
        final prior = await txn.query(
          'dairy_sync_stage',
          where:
              'company_id = ? AND tenant_id = ? AND farm_id = ? '
              'AND entity_type = ? AND entity_id = ?',
          whereArgs: keyArgs,
          limit: 1,
        );
        if (prior.isNotEmpty) {
          if (prior.single['payload_json'] != jsonEncode(candidate.payload)) {
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
          'payload_json': jsonEncode(candidate.payload),
          'staged_at': DateTime.now().toUtc().toIso8601String(),
        });
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
