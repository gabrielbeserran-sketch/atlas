import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:projeto_atlas/core/database/atlas_local_database.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class AtlasSyncSummary {
  const AtlasSyncSummary({
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.pending,
  });

  final int processed;
  final int succeeded;
  final int failed;
  final int pending;
}

class AtlasSyncEngine {
  AtlasSyncEngine({
    AtlasLocalDatabase? localDatabase,
    AtlasHttpClient? httpClient,
  })  : _localDatabase =
            localDatabase ?? AtlasLocalDatabase.instance,
        _httpClient = httpClient ?? AtlasHttpClient();

  final AtlasLocalDatabase _localDatabase;
  final AtlasHttpClient _httpClient;
  final Uuid _uuid = const Uuid();

  Future<String> enqueue({
    required String companyId,
    required String method,
    required String endpoint,
    required String entityType,
    Map<String, dynamic>? payload,
    String? farmId,
    String? entityId,
    String? localVersion,
  }) async {
    final db = await _localDatabase.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'sync_queue',
      {
        'id': id,
        'company_id': companyId,
        'farm_id': farmId,
        'method': method,
        'endpoint': endpoint,
        'payload_json':
            payload == null ? null : jsonEncode(payload),
        'idempotency_key': _uuid.v4(),
        'entity_type': entityType,
        'entity_id': entityId,
        'local_version': localVersion,
        'status': 'pending',
        'attempt_count': 0,
        'last_error': null,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return id;
  }

  Future<AtlasSyncSummary> synchronize() async {
    final connectivity =
        await Connectivity().checkConnectivity();

    if (connectivity.contains(ConnectivityResult.none)) {
      return AtlasSyncSummary(
        processed: 0,
        succeeded: 0,
        failed: 0,
        pending: await pendingCount(),
      );
    }

    final db = await _localDatabase.database;
    final rows = await db.query(
      'sync_queue',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC',
      limit: 100,
    );

    var succeeded = 0;
    var failed = 0;

    for (final row in rows) {
      final id = row['id']! as String;
      final attempts =
          (row['attempt_count'] as int?) ?? 0;

      await db.update(
        'sync_queue',
        {
          'status': 'processing',
          'attempt_count': attempts + 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      try {
        final payloadText =
            row['payload_json'] as String?;
        final payload = payloadText == null
            ? null
            : Map<String, dynamic>.from(
                jsonDecode(payloadText) as Map,
              );

        await _httpClient.send(
          row['method']! as String,
          row['endpoint']! as String,
          body: {
            ...?payload,
            '_idempotency_key':
                row['idempotency_key'],
            '_local_version':
                row['local_version'],
          },
        );

        await db.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [id],
        );

        succeeded++;
      } catch (error) {
        await db.update(
          'sync_queue',
          {
            'status': 'failed',
            'last_error': error.toString(),
            'updated_at':
                DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        failed++;
      }
    }

    return AtlasSyncSummary(
      processed: rows.length,
      succeeded: succeeded,
      failed: failed,
      pending: await pendingCount(),
    );
  }

  Future<int> pendingCount() async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM sync_queue "
      "WHERE status IN ('pending', 'failed', 'processing')",
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> retryAll() async {
    final db = await _localDatabase.database;

    await db.update(
      'sync_queue',
      {
        'status': 'pending',
        'last_error': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: "status = 'failed'",
    );
  }
}
