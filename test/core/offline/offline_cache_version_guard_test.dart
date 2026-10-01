import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/services/offline_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, dynamic> change({
  int version = 1,
  String farmId = 'farm-a',
  String entityType = 'dairy_daily_production',
  String entityId = 'farm-a:2026-09-30',
  Map<String, dynamic> payload = const <String, dynamic>{'liters': 20},
  bool deleted = false,
}) => <String, dynamic>{
  'farm_id': farmId,
  'entity_type': entityType,
  'entity_id': entityId,
  'version': version,
  'payload': payload,
  'deleted': deleted,
};

Future<void> apply(
  Database db,
  Map<String, dynamic> item, {
  String tenantId = 'tenant-a',
  String farmId = 'farm-a',
}) => OfflineRepository.applyChangeInDatabase(
  db,
  companyId: 'company-a',
  tenantId: tenantId,
  farmId: farmId,
  change: item,
);

void main() {
  late Database db;

  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE entity_cache ('
      'company_id TEXT NOT NULL, tenant_id TEXT NOT NULL, farm_id TEXT, '
      'entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, '
      'version INTEGER NOT NULL, payload_json TEXT NOT NULL, '
      'deleted INTEGER NOT NULL, updated_at TEXT NOT NULL, '
      'PRIMARY KEY(company_id, entity_type, entity_id))',
    );
  });

  tearDown(() async => db.close());

  Future<Map<String, Object?>> saved() async =>
      (await db.query('entity_cache')).single;

  test('repetição idêntica e página antiga não regridem versão', () async {
    await apply(
      db,
      change(
        version: 2,
        payload: {
          'a': 1,
          'b': [2, 3],
        },
      ),
    );
    final before = await saved();
    await apply(
      db,
      change(
        version: 2,
        payload: {
          'b': [2, 3],
          'a': 1,
        },
      ),
    );
    await apply(db, change(version: 1, payload: {'a': 0}));
    expect(await saved(), before);
  });

  test('mesma versão divergente não substitui o cache', () async {
    await apply(db, change());
    final before = await saved();
    await expectLater(
      apply(db, change(payload: {'liters': 99})),
      throwsStateError,
    );
    expect(await saved(), before);
  });

  test(
    'versão nova e tombstone substituem somente a entidade correta',
    () async {
      await apply(db, change());
      await apply(db, change(version: 2, payload: {'liters': 23}));
      expect((await saved())['version'], 2);
      await apply(db, change(version: 3, payload: {}, deleted: true));
      expect((await saved())['deleted'], 1);
      expect((await saved())['version'], 3);
    },
  );

  test(
    'tenant, fazenda existente e filtro de fazenda não podem mudar',
    () async {
      await apply(db, change());
      final before = await saved();
      await expectLater(
        apply(db, change(version: 2), tenantId: 'tenant-b'),
        throwsStateError,
      );
      await expectLater(
        apply(db, change(version: 2, farmId: 'farm-b'), farmId: 'farm-b'),
        throwsStateError,
      );
      await expectLater(
        apply(db, change(version: 2, farmId: 'farm-b')),
        throwsStateError,
      );
      expect(await saved(), before);
    },
  );

  test('payload ou versão inválidos não criam registros', () async {
    for (final invalid in <Map<String, dynamic>>[
      change(version: 0),
      {...change(), 'version': 1.5},
      {...change(), 'payload': 'texto'},
      {...change(), 'deleted': null},
      {...change(), 'entity_id': ''},
    ]) {
      await expectLater(apply(db, invalid), throwsStateError);
    }
    expect(await db.query('entity_cache'), isEmpty);
  });

  test('tipo legado continua aceito quando sua página é válida', () async {
    await apply(db, change(entityType: 'farm_note', entityId: 'note-1'));
    expect((await saved())['entity_type'], 'farm_note');
  });
}
