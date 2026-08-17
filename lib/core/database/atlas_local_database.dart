import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AtlasLocalDatabase {
  AtlasLocalDatabase._();

  static final AtlasLocalDatabase instance = AtlasLocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null) return current;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final folder = await databaseFactory.getDatabasesPath();

    final opened = await databaseFactory.openDatabase(
      path.join(folder, 'atlas_offline.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');
        },
        onCreate: _create,
      ),
    );

    _database = opened;
    return opened;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cached_entities (
        cache_key TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        company_id TEXT NOT NULL,
        farm_id TEXT,
        entity_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        remote_version TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX ix_cached_entities_scope
      ON cached_entities(entity_type, company_id, farm_id)
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL,
        farm_id TEXT,
        method TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        payload_json TEXT,
        idempotency_key TEXT NOT NULL UNIQUE,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        local_version TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX ix_sync_queue_status
      ON sync_queue(status, created_at)
    ''');

    await db.execute('''
      CREATE TABLE sync_state (
        scope_key TEXT PRIMARY KEY,
        cursor TEXT,
        last_success_at TEXT,
        last_error TEXT
      )
    ''');
  }

  Future<void> cacheEntity({
    required String entityType,
    required String companyId,
    required String entityId,
    required Map<String, dynamic> payload,
    String? farmId,
    String? remoteVersion,
  }) async {
    final db = await database;
    final cacheKey = '$entityType::$companyId::${farmId ?? ''}::$entityId';

    await db.insert('cached_entities', {
      'cache_key': cacheKey,
      'entity_type': entityType,
      'company_id': companyId,
      'farm_id': farmId,
      'entity_id': entityId,
      'payload_json': jsonEncode(payload),
      'remote_version': remoteVersion,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> cachedEntities({
    required String entityType,
    required String companyId,
    String? farmId,
  }) async {
    final db = await database;

    final rows = await db.query(
      'cached_entities',
      where: farmId == null
          ? 'entity_type = ? AND company_id = ?'
          : 'entity_type = ? AND company_id = ? AND farm_id = ?',
      whereArgs: farmId == null
          ? [entityType, companyId]
          : [entityType, companyId, farmId],
      orderBy: 'updated_at DESC',
    );

    return rows
        .map(
          (row) => Map<String, dynamic>.from(
            jsonDecode(row['payload_json']! as String) as Map,
          ),
        )
        .toList();
  }

  Future<void> removeCachedEntity({
    required String entityType,
    required String companyId,
    required String entityId,
    String? farmId,
  }) async {
    final db = await database;

    await db.delete(
      'cached_entities',
      where: 'cache_key = ?',
      whereArgs: ['$entityType::$companyId::${farmId ?? ''}::$entityId'],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
