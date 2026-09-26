import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/farm_operations/data/services/atlas_operations_repository.dart';
import 'operations_scoped_save_test.dart' show operation;

AtlasOperationsRepository repository(
  String tenant,
  String company,
  String farm,
) => AtlasOperationsRepository.scoped(
  tenantId: tenant,
  companyId: company,
  farmId: farm,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'mesmo farmId em empresas/tenants distintos nunca compartilha tarefas',
    () async {
      await repository('t', 'a', 'f').save([operation('a', 'f')]);
      expect(await repository('t', 'b', 'f').load(), isEmpty);
      expect(await repository('other', 'a', 'f').load(), isEmpty);
      await repository('t', 'b', 'f').save([operation('b', 'f')]);
      expect((await repository('t', 'a', 'f').load()).single.id, 'a');
      expect((await repository('t', 'b', 'f').load()).single.id, 'b');
    },
  );
  test(
    'persistência e exclusão isoladas por fazenda após reconstruir repositório',
    () async {
      await repository('t', 'c', 'f').save([operation('a', 'f')]);
      await repository('t', 'c', 'g').save([operation('b', 'g')]);
      expect(
        (await repository('t', 'c', 'f').loadReadOnly(farmId: 'f')).single.id,
        'a',
      );
      await repository('t', 'c', 'f').save([]);
      expect((await repository('t', 'c', 'g').load()).single.id, 'b');
    },
  );
  test('legado preservado não é importado mesmo com farmId igual', () async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = jsonEncode([operation('legacy', 'f').toJson()]);
    await prefs.setString('atlas_farm_operations_v1', legacy);
    final scoped = repository('t', 'c', 'f');
    expect(await scoped.load(), isEmpty);
    expect(await scoped.hasLegacyData(), isTrue);
    await scoped.save([operation('new', 'f')]);
    expect(prefs.getString('atlas_farm_operations_v1'), legacy);
    expect((await scoped.load()).single.id, 'new');
  });
  test('escopo incompleto ou farmId divergente são recusados', () async {
    expect(() => repository('', 'c', 'f'), throwsArgumentError);
    expect(() => repository('t', '', 'f'), throwsArgumentError);
    expect(() => repository('t', 'c', ' '), throwsArgumentError);
    final scoped = repository('t', 'c', 'f');
    await expectLater(scoped.load(farmId: 'g'), throwsArgumentError);
    expect(() => scoped.save([], farmId: 'g'), throwsArgumentError);
    await expectLater(
      scoped.save([operation('wrong', 'g')]),
      throwsArgumentError,
    );
    expect(await scoped.load(), isEmpty);
  });
  test(
    'codificação de chave não colide com separadores nos identificadores',
    () {
      expect(
        AtlasOperationsRepository.scopedKey('a:b', 'c', 'f'),
        isNot(AtlasOperationsRepository.scopedKey('a', 'b:c', 'f')),
      );
    },
  );
  test('corromper v2 não sobrescreve v1 nem outra empresa', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AtlasOperationsRepository.scopedKey('t', 'a', 'f'),
      '{bad',
    );
    await repository('t', 'b', 'f').save([operation('b', 'f')]);
    await expectLater(
      repository('t', 'a', 'f').save([]),
      throwsFormatException,
    );
    expect(
      prefs.getString(AtlasOperationsRepository.scopedKey('t', 'a', 'f')),
      '{bad',
    );
    expect((await repository('t', 'b', 'f').load()).single.id, 'b');
  });
  test('consumidores oficiais constroem repositório isolado', () {
    for (final file in [
      'lib/features/farm_operations/presentation/screens/atlas_operations_center_screen.dart',
      'lib/features/field_operations/presentation/screens/farm_field_center_screen.dart',
    ]) {
      final source = File(file).readAsStringSync();
      expect(source, contains('AtlasOperationsRepository.scoped('));
      expect(source, isNot(contains('AtlasOperationsRepository()')));
    }
  });
}
