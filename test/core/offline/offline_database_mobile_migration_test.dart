import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/database/atlas_offline_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory root;
  late Directory legacy;
  late Directory durable;

  setUp(() async {
    sqfliteFfiInit();
    root = await Directory.systemTemp.createTemp('atlas_offline_migrate_');
    legacy = await Directory(
      '${root.path}${Platform.pathSeparator}old',
    ).create();
    durable = Directory('${root.path}${Platform.pathSeparator}support');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  String path(Directory folder) =>
      '${folder.path}${Platform.pathSeparator}atlas_offline_v2.db';

  test(
    'migra transação em WAL, preserva origem e reabrir é idempotente',
    () async {
      final source = await databaseFactoryFfi.openDatabase(path(legacy));
      try {
        await source.execute('PRAGMA journal_mode = WAL');
        await source.execute(
          'CREATE TABLE records (id TEXT PRIMARY KEY, n INT)',
        );
        await source.insert('records', {'id': 'ordenha-1', 'n': 42});

        expect(
          await AtlasOfflineDatabase.migrateLegacyDatabase(
            legacyDirectory: legacy,
            durableDirectory: durable,
          ),
          isTrue,
        );
        final copied = await databaseFactoryFfi.openDatabase(path(durable));
        try {
          expect((await copied.query('records')).single['n'], 42);
        } finally {
          await copied.close();
        }
        expect((await source.query('records')).single['n'], 42);
        expect(await File(path(legacy)).exists(), isTrue);

        await source.insert('records', {'id': 'old-only', 'n': 99});
        expect(
          await AtlasOfflineDatabase.migrateLegacyDatabase(
            legacyDirectory: legacy,
            durableDirectory: durable,
          ),
          isFalse,
        );
        final reopened = await databaseFactoryFfi.openDatabase(path(durable));
        try {
          expect((await reopened.query('records')).length, 1);
        } finally {
          await reopened.close();
        }
      } finally {
        await source.close();
      }
    },
  );

  test('sem fonte não cria banco de dados vazio', () async {
    expect(
      await AtlasOfflineDatabase.migrateLegacyDatabase(
        legacyDirectory: legacy,
        durableDirectory: durable,
      ),
      isFalse,
    );
    expect(await File(path(durable)).exists(), isFalse);
  });

  test(
    'falha de origem preserva arquivo e não publica cópia parcial',
    () async {
      await File(path(legacy)).writeAsString('não é SQLite');
      await expectLater(
        AtlasOfflineDatabase.migrateLegacyDatabase(
          legacyDirectory: legacy,
          durableDirectory: durable,
        ),
        throwsA(isA<Exception>()),
      );
      expect(await File(path(legacy)).exists(), isTrue);
      expect(await File(path(durable)).exists(), isFalse);
    },
  );

  test('esquema antigo é bloqueado sem apagar sua fila', () async {
    final database = await databaseFactoryFfi.openDatabase(
      path(legacy),
      options: OpenDatabaseOptions(version: 1),
    );
    try {
      await database.execute('CREATE TABLE operation_queue (id TEXT)');
      await database.insert('operation_queue', {'id': 'pending-1'});
      await expectLater(
        AtlasOfflineDatabase.guardLegacyUpgrade(1),
        throwsStateError,
      );
      expect(
        (await database.query('operation_queue')).single['id'],
        'pending-1',
      );
    } finally {
      await database.close();
    }
  });
}
