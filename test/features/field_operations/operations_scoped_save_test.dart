import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/farm_operations/data/services/atlas_operations_repository.dart';
import 'package:projeto_atlas/features/farm_operations/domain/models/atlas_farm_operation.dart';

AtlasFarmOperation operation(String id, String? farm) => AtlasFarmOperation(
  id: id,
  farmId: farm,
  title: id,
  description: '',
  type: AtlasOperationType.pasture,
  status: AtlasOperationStatus.planned,
  priority: AtlasOperationPriority.medium,
  responsible: '',
  team: const [],
  equipment: const [],
  scheduledAt: DateTime(2026, 9, 26),
  estimatedHours: 1,
  actualHours: 0,
  plannedCost: 10,
  actualCost: 0,
  progress: 0,
  notes: '',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('editar ou excluir A preserva B e registros sem vínculo', () async {
    final repository = AtlasOperationsRepository();
    await repository.save([
      operation('a', 'A'),
      operation('b', 'B'),
      operation('legado', null),
    ]);
    await repository.save([
      operation('a', 'A').copyWith(title: 'Editada'),
    ], farmId: 'A');
    expect((await repository.load(farmId: 'A')).single.title, 'Editada');
    expect((await repository.load(farmId: 'B')).single.id, 'b');
    await repository.save([], farmId: 'A');
    expect(await repository.load(farmId: 'A'), isEmpty);
    expect(
      (await repository.load()).map((e) => e.id),
      unorderedEquals(['b', 'legado']),
    );
  });
  test('registros sem fazenda não aparecem em consultas específicas', () async {
    final repository = AtlasOperationsRepository();
    await repository.save([operation('legado', null)]);
    expect(await repository.load(farmId: 'A'), isEmpty);
    expect((await repository.load()).single.id, 'legado');
  });
  test(
    'salvamentos concorrentes de fazendas distintas não se apagam',
    () async {
      await Future.wait([
        AtlasOperationsRepository().save([operation('a', 'A')], farmId: 'A'),
        AtlasOperationsRepository().save([operation('b', 'B')], farmId: 'B'),
      ]);
      expect(
        (await AtlasOperationsRepository().load()).map((e) => e.id),
        unorderedEquals(['a', 'b']),
      );
    },
  );
  test(
    'escopo errado, vazio e IDs duplicados não alteram armazenamento',
    () async {
      final repository = AtlasOperationsRepository();
      await repository.save([operation('b', 'B')], farmId: 'B');
      final prefs = await SharedPreferences.getInstance();
      final original = prefs.getString('atlas_farm_operations_v1');
      await expectLater(
        repository.save([operation('a', 'B')], farmId: 'A'),
        throwsArgumentError,
      );
      await expectLater(repository.save([], farmId: ''), throwsArgumentError);
      await expectLater(
        repository.save([
          operation('a', 'A'),
          operation('a', 'A'),
        ], farmId: 'A'),
        throwsArgumentError,
      );
      expect(prefs.getString('atlas_farm_operations_v1'), original);
      await repository.save([operation('a', 'A')], farmId: 'A');
      expect((await repository.load()).length, 2);
    },
  );
  test('ID de outra fazenda é recusado sem perda de registros', () async {
    final repository = AtlasOperationsRepository();
    await repository.save([operation('b', 'B')], farmId: 'B');
    await expectLater(
      repository.save([operation('b', 'A')], farmId: 'A'),
      throwsStateError,
    );
    expect((await repository.load()).single.farmId, 'B');
  });
  test('conteúdo corrompido não é substituído silenciosamente', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atlas_farm_operations_v1', '{invalid');
    await expectLater(
      AtlasOperationsRepository().save([], farmId: 'A'),
      throwsFormatException,
    );
    expect(prefs.getString('atlas_farm_operations_v1'), '{invalid');
  });
  test(
    'campos legados desconhecidos de outra fazenda são preservados',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final legacy = {
        ...operation('b', 'B').toJson(),
        'extra': {'source': 'original'},
      };
      await prefs.setString('atlas_farm_operations_v1', jsonEncode([legacy]));
      await AtlasOperationsRepository().save([
        operation('a', 'A'),
      ], farmId: 'A');
      expect(
        (jsonDecode(prefs.getString('atlas_farm_operations_v1')!) as List)
            .first,
        legacy,
      );
    },
  );
}
