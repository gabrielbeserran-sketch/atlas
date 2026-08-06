import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/atlas_offline_database.dart';
import '../models/offline_operation.dart';

class OfflineRepository {
  OfflineRepository({AtlasOfflineDatabase? database})
      : _database = database ?? AtlasOfflineDatabase.instance;

  final AtlasOfflineDatabase _database;

  Future<void> enqueue(OfflineOperation operation) async {
    final Database db = await _database.database;
    await db.insert(
      'operation_queue',
      operation.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<OfflineOperation>> pending({int limit = 200}) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      'operation_queue',
      where: 'status IN (?, ?)',
      whereArgs: const <Object?>['pending', 'retry'],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(OfflineOperation.fromDatabase).toList(growable: false);
  }

  Future<void> markAccepted(String id) async {
    final Database db = await _database.database;
    await db.update(
      'operation_queue',
      const <String, Object?>{'status': 'accepted', 'last_error': ''},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> markFailed(
    String id,
    String error, {
    bool permanent = false,
  }) async {
    final Database db = await _database.database;
    await db.rawUpdate(
      'UPDATE operation_queue '
      'SET attempts = attempts + 1, status = ?, last_error = ? '
      'WHERE id = ?',
      <Object?>[permanent ? 'failed' : 'retry', error, id],
    );
  }

  Future<int> getCursor() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: const <Object?>['cursor'],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.first['value']?.toString() ?? '') ?? 0;
  }

  Future<void> setCursor(int value) async {
    final Database db = await _database.database;
    await db.insert(
      'sync_metadata',
      <String, Object?>{'key': 'cursor', 'value': '$value'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> applyChange(Map<String, dynamic> change) async {
    final Database db = await _database.database;
    await db.insert(
      'entity_cache',
      <String, Object?>{
        'entity_type': change['entity_type']?.toString() ?? '',
        'entity_id': change['entity_id']?.toString() ?? '',
        'version': change['version'] is int ? change['version'] as int : 0,
        'payload_json': jsonEncode(change['payload'] ?? const {}),
        'deleted': change['deleted'] == true ? 1 : 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveConflict({
    required OfflineOperation operation,
    required int remoteVersion,
    required Map<String, dynamic> remotePayload,
  }) async {
    final Database db = await _database.database;
    await db.insert(
      'local_conflicts',
      <String, Object?>{
        'id': operation.id,
        'operation_id': operation.id,
        'entity_type': operation.entityType,
        'entity_id': operation.entityId,
        'local_payload_json': jsonEncode(operation.payload),
        'remote_payload_json': jsonEncode(remotePayload),
        'local_version': operation.baseVersion,
        'remote_version': remoteVersion,
        'status': 'open',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.update(
      'operation_queue',
      const <String, Object?>{'status': 'conflict'},
      where: 'id = ?',
      whereArgs: <Object?>[operation.id],
    );
  }
}
