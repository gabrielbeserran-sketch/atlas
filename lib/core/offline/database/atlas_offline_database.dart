import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AtlasOfflineDatabase {
  AtlasOfflineDatabase._();

  static final AtlasOfflineDatabase instance = AtlasOfflineDatabase._();
  static const int schemaVersion = 4;

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
            await guardLegacyUpgrade(oldVersion);
          }
          if (oldVersion < 3) {
            await upgradeToVersion3(db);
          }
          if (oldVersion < 4) {
            await upgradeToVersion4(db);
          }
        },
      ),
    );
  }

  Future<Directory> databaseDirectory() async {
    final legacyBaseDirectory =
        Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.systemTemp.path;
    final legacyDirectory = Directory(
      '$legacyBaseDirectory${Platform.pathSeparator}ProjetoAtlas',
    );
    final directory = Platform.isAndroid || Platform.isIOS
        ? Directory(
            '${(await getApplicationSupportDirectory()).path}'
            '${Platform.pathSeparator}ProjetoAtlas',
          )
        : legacyDirectory;
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    if (directory.path != legacyDirectory.path) {
      await migrateLegacyDatabase(
        legacyDirectory: legacyDirectory,
        durableDirectory: directory,
      );
    }
    return directory;
  }

  /// Creates a consistent copy including committed WAL transactions. The
  /// previous database is left intact so an interrupted migration is retryable.
  static Future<bool> migrateLegacyDatabase({
    required Directory legacyDirectory,
    required Directory durableDirectory,
  }) async {
    const databaseName = 'atlas_offline_v2.db';
    final sourcePath =
        '${legacyDirectory.path}${Platform.pathSeparator}$databaseName';
    final targetPath =
        '${durableDirectory.path}${Platform.pathSeparator}$databaseName';
    if (sourcePath == targetPath ||
        File(targetPath).existsSync() ||
        !File(sourcePath).existsSync()) {
      return false;
    }
    await durableDirectory.create(recursive: true);
    sqfliteFfiInit();
    final staging = File(
      '$targetPath.${DateTime.now().microsecondsSinceEpoch}.migrating',
    );
    try {
      final source = await databaseFactoryFfi.openDatabase(
        sourcePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        final quoted = staging.path.replaceAll("'", "''");
        await source.execute("VACUUM INTO '$quoted'");
      } finally {
        await source.close();
      }
      final snapshot = await databaseFactoryFfi.openDatabase(
        staging.path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        final result = await snapshot.rawQuery('PRAGMA integrity_check');
        if (result.length != 1 || result.single.values.single != 'ok') {
          throw StateError('Cópia do banco offline não passou na integridade.');
        }
      } finally {
        await snapshot.close();
      }
      if (File(targetPath).existsSync()) return false;
      await staging.rename(targetPath);
      return true;
    } finally {
      if (await staging.exists()) await staging.delete();
    }
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
    await upgradeToVersion3(db);
    await upgradeToVersion4(db);
  }

  /// Preparation only: staged dairy records never enter the send queue.
  static Future<void> upgradeToVersion3(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS dairy_sync_stage ('
      'company_id TEXT NOT NULL, '
      'tenant_id TEXT NOT NULL, '
      'farm_id TEXT NOT NULL, '
      'entity_type TEXT NOT NULL, '
      'entity_id TEXT NOT NULL, '
      'payload_json TEXT NOT NULL, '
      'staged_at TEXT NOT NULL, '
      'PRIMARY KEY(company_id, tenant_id, farm_id, entity_type, entity_id)'
      ')',
    );
  }

  /// Local intention only. Entries are not operations and never sync by themselves.
  static Future<void> upgradeToVersion4(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS dairy_sync_decision ('
      'company_id TEXT NOT NULL, '
      'tenant_id TEXT NOT NULL, '
      'farm_id TEXT NOT NULL, '
      'entity_type TEXT NOT NULL, '
      'entity_id TEXT NOT NULL, '
      "choice TEXT NOT NULL CHECK(choice IN ('prefer_local', 'keep_server')), "
      'stage_payload_json TEXT NOT NULL, '
      'remote_version INTEGER NOT NULL, '
      'remote_deleted INTEGER NOT NULL, '
      'remote_payload_json TEXT NOT NULL, '
      'decided_at TEXT NOT NULL, '
      'decided_by TEXT NOT NULL, '
      'PRIMARY KEY(company_id, tenant_id, farm_id, entity_type, entity_id)'
      ')',
    );
  }

  /// A v1 schema has no verified lossless mapping yet. Never erase its queue.
  static Future<void> guardLegacyUpgrade(int oldVersion) async {
    throw StateError(
      'Banco offline v$oldVersion preservado: migração do esquema precisa '
      'ser revisada antes de abrir esta versão.',
    );
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
