import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/atlas_offline_database.dart';
import '../models/offline_operation.dart';
import '../models/offline_sync_models.dart';

class OfflineRepository {
  OfflineRepository({AtlasOfflineDatabase? database})
    : _database = database ?? AtlasOfflineDatabase.instance;

  final AtlasOfflineDatabase _database;

  Future<void> enqueue(OfflineOperation operation) async {
    final db = await _database.database;
    await db.insert(
      'operation_queue',
      operation.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<OfflineOperation>> pending({
    required String companyId,
    String? farmId,
    int limit = 200,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final where = StringBuffer(
      'company_id = ? AND status IN (?, ?) '
      'AND (next_attempt_at IS NULL OR next_attempt_at <= ?)',
    );
    final args = <Object?>[companyId, 'pending', 'retry', now];
    if (farmId != null && farmId.isNotEmpty) {
      where.write(' AND (farm_id = ? OR farm_id IS NULL)');
      args.add(farmId);
    }
    final rows = await db.query(
      'operation_queue',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'created_at ASC',
      limit: limit.clamp(1, 200),
    );
    return rows.map(OfflineOperation.fromDatabase).toList(growable: false);
  }

  Future<OfflineQueueStats> queueStats({
    required String companyId,
    String? farmId,
  }) async {
    final db = await _database.database;
    final where = StringBuffer('company_id = ?');
    final args = <Object?>[companyId];
    if (farmId != null && farmId.isNotEmpty) {
      where.write(' AND (farm_id = ? OR farm_id IS NULL)');
      args.add(farmId);
    }
    final rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS total FROM operation_queue '
      'WHERE ${where.toString()} GROUP BY status',
      args,
    );
    final values = <String, int>{};
    for (final row in rows) {
      values[row['status']?.toString() ?? ''] =
          (row['total'] as num?)?.toInt() ?? 0;
    }
    return OfflineQueueStats(
      pending: values['pending'] ?? 0,
      retry: values['retry'] ?? 0,
      conflicts: values['conflict'] ?? 0,
      failed: values['failed'] ?? 0,
      accepted: values['accepted'] ?? 0,
    );
  }

  Future<void> markAccepted(String id) async {
    final db = await _database.database;
    await db.update(
      'operation_queue',
      <String, Object?>{
        'status': 'accepted',
        'last_error': '',
        'next_attempt_at': null,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> markFailed(
    String id,
    String error, {
    bool permanent = false,
    int currentAttempts = 0,
  }) async {
    final db = await _database.database;
    final nextAttempts = currentAttempts + 1;
    final delaySeconds = (1 << nextAttempts.clamp(1, 8).toInt()) * 5;
    final nextAttemptAt = permanent
        ? null
        : DateTime.now()
              .toUtc()
              .add(Duration(seconds: delaySeconds))
              .toIso8601String();
    await db.update(
      'operation_queue',
      <String, Object?>{
        'attempts': nextAttempts,
        'status': permanent ? 'failed' : 'retry',
        'last_error': error,
        'next_attempt_at': nextAttemptAt,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> purgeAccepted({
    Duration olderThan = const Duration(days: 7),
  }) async {
    final db = await _database.database;
    final cutoff = DateTime.now().toUtc().subtract(olderThan).toIso8601String();
    await db.delete(
      'operation_queue',
      where: 'status = ? AND created_at < ?',
      whereArgs: <Object?>['accepted', cutoff],
    );
  }

  String _cursorKey(String companyId, String? farmId) =>
      'cursor:$companyId:${farmId?.isNotEmpty == true ? farmId : 'all'}';

  Future<int> getCursor({required String companyId, String? farmId}) async {
    final db = await _database.database;
    final rows = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: <Object?>[_cursorKey(companyId, farmId)],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.first['value']?.toString() ?? '') ?? 0;
  }

  Future<void> setCursor({
    required String companyId,
    String? farmId,
    required int value,
  }) async {
    final db = await _database.database;
    await db.insert('sync_metadata', <String, Object?>{
      'key': _cursorKey(companyId, farmId),
      'value': '$value',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> applyChange({
    required String companyId,
    required String tenantId,
    String? farmId,
    required Map<String, dynamic> change,
  }) async {
    final db = await _database.database;
    await db.insert('entity_cache', <String, Object?>{
      'company_id': companyId,
      'tenant_id': tenantId,
      'farm_id': farmId,
      'entity_type': change['entity_type']?.toString() ?? '',
      'entity_id': change['entity_id']?.toString() ?? '',
      'version': (change['version'] as num?)?.toInt() ?? 0,
      'payload_json': jsonEncode(change['payload'] ?? const {}),
      'deleted': change['deleted'] == true ? 1 : 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<OfflineCachedEntity>> cachedEntities({
    required String companyId,
    required String entityType,
    String? farmId,
    bool includeDeleted = false,
  }) async {
    final db = await _database.database;
    final where = StringBuffer('company_id = ? AND entity_type = ?');
    final args = <Object?>[companyId, entityType];
    if (farmId != null && farmId.isNotEmpty) {
      where.write(' AND farm_id = ?');
      args.add(farmId);
    }
    if (!includeDeleted) {
      where.write(' AND deleted = 0');
    }
    final rows = await db.query(
      'entity_cache',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (row) => OfflineCachedEntity(
            entityType: row['entity_type']?.toString() ?? '',
            entityId: row['entity_id']?.toString() ?? '',
            companyId: row['company_id']?.toString() ?? '',
            tenantId: row['tenant_id']?.toString() ?? '',
            farmId: row['farm_id']?.toString(),
            version: (row['version'] as num?)?.toInt() ?? 0,
            payload: Map<String, dynamic>.from(
              jsonDecode(row['payload_json']?.toString() ?? '{}') as Map,
            ),
            deleted: (row['deleted'] as num?)?.toInt() == 1,
            updatedAt:
                DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveConflict({
    required OfflineOperation operation,
    required int remoteVersion,
    required Map<String, dynamic> remotePayload,
    String? serverConflictId,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert('local_conflicts', <String, Object?>{
        'id': operation.id,
        'server_conflict_id': serverConflictId,
        'operation_id': operation.id,
        'company_id': operation.companyId,
        'tenant_id': operation.tenantId,
        'farm_id': operation.farmId,
        'entity_type': operation.entityType,
        'entity_id': operation.entityId,
        'local_payload_json': jsonEncode(operation.payload),
        'remote_payload_json': jsonEncode(remotePayload),
        'local_version': operation.baseVersion,
        'remote_version': remoteVersion,
        'status': 'open',
        'resolution': '',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'resolved_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.update(
        'operation_queue',
        const <String, Object?>{'status': 'conflict'},
        where: 'id = ?',
        whereArgs: <Object?>[operation.id],
      );
    });
  }

  Future<void> importRemoteConflicts({
    required String companyId,
    required String tenantId,
    required List<Map<String, dynamic>> conflicts,
  }) async {
    final db = await _database.database;
    for (final item in conflicts) {
      final serverId = item['id']?.toString() ?? '';
      final operationId = item['operation_id']?.toString() ?? serverId;
      await db.insert('local_conflicts', <String, Object?>{
        'id': operationId,
        'server_conflict_id': serverId,
        'operation_id': operationId,
        'company_id': companyId,
        'tenant_id': tenantId,
        'farm_id': item['farm_id']?.toString(),
        'entity_type': item['entity_type']?.toString() ?? '',
        'entity_id': item['entity_id']?.toString() ?? '',
        'local_payload_json': jsonEncode(item['local_payload'] ?? const {}),
        'remote_payload_json': jsonEncode(item['remote_payload'] ?? const {}),
        'local_version': (item['local_version'] as num?)?.toInt() ?? 0,
        'remote_version': (item['remote_version'] as num?)?.toInt() ?? 0,
        'status': item['status']?.toString() ?? 'open',
        'resolution': '',
        'created_at':
            item['created_at']?.toString() ??
            DateTime.now().toUtc().toIso8601String(),
        'resolved_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<OfflineConflict>> conflicts({
    required String companyId,
    String? farmId,
    String status = 'open',
  }) async {
    final db = await _database.database;
    final where = StringBuffer('company_id = ? AND status = ?');
    final args = <Object?>[companyId, status];
    if (farmId != null && farmId.isNotEmpty) {
      where.write(' AND (farm_id = ? OR farm_id IS NULL)');
      args.add(farmId);
    }
    final rows = await db.query(
      'local_conflicts',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(OfflineConflict.fromDatabase).toList(growable: false);
  }

  Future<void> markConflictResolved({
    required String id,
    required String resolution,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'local_conflicts',
        <String, Object?>{
          'status': 'resolved',
          'resolution': resolution,
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      await txn.update(
        'operation_queue',
        const <String, Object?>{'status': 'accepted', 'last_error': ''},
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    });
  }

  Future<int> databaseSizeBytes() => _database.fileSizeBytes();
}
