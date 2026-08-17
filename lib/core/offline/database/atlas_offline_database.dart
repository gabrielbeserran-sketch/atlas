import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AtlasOfflineDatabase {
  AtlasOfflineDatabase._();

  static final AtlasOfflineDatabase instance = AtlasOfflineDatabase._();
  static const int schemaVersion = 2;

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    sqfliteFfiInit();
    final directory = await databaseDirectory();
    final databasePath =
        '${directory.path}${Platform.pathSeparator}atlas_offline_v2.db';

    return databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
        },
        onCreate: (db, version) => _createSchema(db),
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _upgradeToVersion2(db);
          }
        },
      ),
    );
  }

  Future<Directory> databaseDirectory() async {
    final baseDirectory =
        Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.systemTemp.path;
    final directory = Directory(
      '$baseDirectory${Platform.pathSeparator}ProjetoAtlas',
    );
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute(
      'CREATE TABLE entity_cache ('
      'company_id TEXT NOT NULL, '
      'tenant_id TEXT NOT NULL, '
      'farm_id TEXT, '
      'entity_type TEXT NOT NULL, '
      'entity_id TEXT NOT NULL, '
      'version INTEGER NOT NULL DEFAULT 0, '
      'payload_json TEXT NOT NULL, '
      'deleted INTEGER NOT NULL DEFAULT 0, '
      'updated_at TEXT NOT NULL, '
      'PRIMARY KEY(company_id, entity_type, entity_id)'
      ')',
    );
    await db.execute(
      'CREATE INDEX ix_entity_cache_scope '
      'ON entity_cache(company_id, farm_id, entity_type, deleted)',
    );
    await db.execute(
      'CREATE TABLE operation_queue ('
      'id TEXT PRIMARY KEY, '
      'idempotency_key TEXT NOT NULL UNIQUE, '
      'entity_type TEXT NOT NULL, '
      'entity_id TEXT NOT NULL, '
      'operation_type TEXT NOT NULL, '
      'payload_json TEXT NOT NULL, '
      'base_version INTEGER NOT NULL DEFAULT 0, '
      'company_id TEXT NOT NULL, '
      'tenant_id TEXT NOT NULL, '
      'farm_id TEXT, '
      'device_id TEXT NOT NULL, '
      'created_at TEXT NOT NULL, '
      'attempts INTEGER NOT NULL DEFAULT 0, '
      'status TEXT NOT NULL DEFAULT "pending", '
      'last_error TEXT NOT NULL DEFAULT "", '
      'next_attempt_at TEXT'
      ')',
    );
    await db.execute(
      'CREATE INDEX ix_operation_queue_scope_status '
      'ON operation_queue(company_id, farm_id, status, next_attempt_at, created_at)',
    );
    await db.execute(
      'CREATE TABLE sync_metadata ('
      'key TEXT PRIMARY KEY, '
      'value TEXT NOT NULL'
      ')',
    );
    await db.execute(
      'CREATE TABLE local_conflicts ('
      'id TEXT PRIMARY KEY, '
      'server_conflict_id TEXT, '
      'operation_id TEXT NOT NULL, '
      'company_id TEXT NOT NULL, '
      'tenant_id TEXT NOT NULL, '
      'farm_id TEXT, '
      'entity_type TEXT NOT NULL, '
      'entity_id TEXT NOT NULL, '
      'local_payload_json TEXT NOT NULL, '
      'remote_payload_json TEXT NOT NULL, '
      'local_version INTEGER NOT NULL, '
      'remote_version INTEGER NOT NULL, '
      'status TEXT NOT NULL DEFAULT "open", '
      'resolution TEXT NOT NULL DEFAULT "", '
      'created_at TEXT NOT NULL, '
      'resolved_at TEXT'
      ')',
    );
    await db.execute(
      'CREATE INDEX ix_local_conflicts_scope_status '
      'ON local_conflicts(company_id, farm_id, status, created_at)',
    );
    await db.execute(
      'CREATE TABLE draft_forms ('
      'id TEXT PRIMARY KEY, '
      'company_id TEXT NOT NULL, '
      'farm_id TEXT, '
      'form_type TEXT NOT NULL, '
      'payload_json TEXT NOT NULL, '
      'updated_at TEXT NOT NULL'
      ')',
    );
  }

  Future<void> _upgradeToVersion2(Database db) async {
    await db.execute('DROP TABLE IF EXISTS entity_cache');
    await db.execute('DROP TABLE IF EXISTS operation_queue');
    await db.execute('DROP TABLE IF EXISTS sync_metadata');
    await db.execute('DROP TABLE IF EXISTS local_conflicts');
    await db.execute('DROP TABLE IF EXISTS draft_forms');
    await _createSchema(db);
  }

  Future<int> fileSizeBytes() async {
    final directory = await databaseDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}atlas_offline_v2.db',
    );
    return file.existsSync() ? file.lengthSync() : 0;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
