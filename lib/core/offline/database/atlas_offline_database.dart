import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AtlasOfflineDatabase {
  AtlasOfflineDatabase._();

  static final AtlasOfflineDatabase instance = AtlasOfflineDatabase._();

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    sqfliteFfiInit();

    final String baseDirectory = Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.systemTemp.path;
    final Directory directory = Directory(
      '$baseDirectory${Platform.pathSeparator}ProjetoAtlas',
    );
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final String databasePath =
        '${directory.path}${Platform.pathSeparator}atlas_offline_v1.db';

    return databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int version) async {
          await db.execute(
            'CREATE TABLE entity_cache ('
            'entity_type TEXT NOT NULL, '
            'entity_id TEXT NOT NULL, '
            'version INTEGER NOT NULL DEFAULT 0, '
            'payload_json TEXT NOT NULL, '
            'deleted INTEGER NOT NULL DEFAULT 0, '
            'updated_at TEXT NOT NULL, '
            'PRIMARY KEY(entity_type, entity_id)'
            ')',
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
            'last_error TEXT NOT NULL DEFAULT ""'
            ')',
          );
          await db.execute(
            'CREATE INDEX ix_operation_queue_status_created '
            'ON operation_queue(status, created_at)',
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
            'operation_id TEXT NOT NULL, '
            'entity_type TEXT NOT NULL, '
            'entity_id TEXT NOT NULL, '
            'local_payload_json TEXT NOT NULL, '
            'remote_payload_json TEXT NOT NULL, '
            'local_version INTEGER NOT NULL, '
            'remote_version INTEGER NOT NULL, '
            'status TEXT NOT NULL DEFAULT "open", '
            'created_at TEXT NOT NULL'
            ')',
          );
          await db.execute(
            'CREATE TABLE draft_forms ('
            'id TEXT PRIMARY KEY, '
            'form_type TEXT NOT NULL, '
            'payload_json TEXT NOT NULL, '
            'updated_at TEXT NOT NULL'
            ')',
          );
        },
      ),
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
