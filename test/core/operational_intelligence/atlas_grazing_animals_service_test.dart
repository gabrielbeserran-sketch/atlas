import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_grazing_animals_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_basis_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

AnimalData animal(String id, {String status = 'Ativo'}) => AnimalData(
  id: id,
  tag: id,
  name: id,
  sex: 'Fêmea',
  breed: 'Nelore',
  birthDate: '',
  weight: 0,
  status: status,
);
AtlasPastureGrazingBasis basis({
  String farm = 'f',
  String company = 'c',
  String tenant = 't',
  String operation = 'operation-1',
  double area = 20,
  DateTime? at,
}) => AtlasPastureGrazingBasis(
  operationId: operation,
  tenantId: tenant,
  companyId: company,
  farmId: farm,
  effectiveAreaHa: area,
  grazingAnimals: 2,
  uniqueAreaConfirmed: true,
  recordedAt: at ?? DateTime.now(),
);

void main() {
  late AtlasGrazingAnimalsService service;
  late List<AnimalData> remote;
  var calls = 0;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    calls = 0;
    remote = [animal('a'), animal('b'), animal('sold', status: 'Vendido')];
    service = AtlasGrazingAnimalsService(
      fetchAnimals: (farm) async {
        calls++;
        return remote;
      },
    );
  });

  test(
    'identifica por ID, persiste após reinício e salva sem nova rede',
    () async {
      final current = basis();
      await service.refreshRoster(current, () async => true);
      await service.saveSelection(current, ['b', 'a'], () async => true);
      expect(calls, 1);
      final restarted = AtlasGrazingAnimalsService(
        fetchAnimals: (_) async => throw StateError('offline'),
      );
      expect((await restarted.loadCurrent(current))?.animalIds, ['a', 'b']);
      await restarted.saveSelection(current, ['a', 'b'], () async => true);
      expect(await restarted.loadHistory(current), hasLength(2));
    },
  );

  test(
    'recusa duplicação, quantidade errada e animal inativo ou desconhecido',
    () async {
      final current = basis();
      await service.refreshRoster(current, () async => true);
      for (final ids in [
        ['a'],
        ['a', 'a'],
        ['a', 'sold'],
        ['a', 'unknown'],
      ]) {
        await expectLater(
          service.saveSelection(current, ids, () async => true),
          throwsArgumentError,
        );
      }
      expect(await service.loadHistory(current), isEmpty);
    },
  );

  test(
    'não compartilha carteira ou vínculo entre tenant empresa e fazenda',
    () async {
      final current = basis();
      await service.refreshRoster(current, () async => true);
      await service.saveSelection(current, ['a', 'b'], () async => true);
      for (final other in [
        basis(farm: 'other'),
        basis(company: 'other'),
        basis(tenant: 'other'),
      ]) {
        expect(await service.loadRoster(other), isNull);
        expect(await service.loadHistory(other), isEmpty);
      }
    },
  );

  test(
    'mudança de operação ou valores da base não reaproveita seleção',
    () async {
      final current = basis();
      await service.refreshRoster(current, () async => true);
      await service.saveSelection(current, ['a', 'b'], () async => true);
      expect(
        await service.loadCurrent(basis(operation: 'operation-2')),
        isNull,
      );
      expect(await service.loadCurrent(basis(area: 21)), isNull);
      expect(await service.loadHistory(current), hasLength(1));
    },
  );

  test(
    'resposta duplicada ou mudança de contexto preserva carteira anterior',
    () async {
      final current = basis();
      await service.refreshRoster(current, () async => true);
      remote = [animal('a'), animal('a')];
      await expectLater(
        service.refreshRoster(current, () async => true),
        throwsFormatException,
      );
      expect((await service.loadRoster(current))?.animals, hasLength(3));
      var checks = 0;
      remote = [animal('other')];
      await expectLater(
        service.refreshRoster(current, () async => ++checks == 1),
        throwsStateError,
      );
      expect((await service.loadRoster(current))?.animals, hasLength(3));
    },
  );

  test('base antiga e salvamento sem autorização não criam seleção', () async {
    final expired = basis(at: DateTime.now().subtract(const Duration(days: 8)));
    await service.refreshRoster(expired, () async => true);
    await expectLater(
      service.saveSelection(expired, ['a', 'b'], () async => true),
      throwsStateError,
    );
    await expectLater(
      service.saveSelection(basis(), ['a', 'b'], () async => false),
      throwsStateError,
    );
    expect(await service.loadHistory(expired), isEmpty);
    final now = DateTime.now();
    expect(
      AtlasGrazingRoster(
        [],
        now.subtract(const Duration(days: 8)),
      ).isCurrent(now),
      isFalse,
    );
    expect(
      AtlasGrazingRoster([], now.add(const Duration(days: 1))).isCurrent(now),
      isFalse,
    );
  });

  test('gravações simultâneas não perdem histórico de seleções', () async {
    final current = basis();
    await service.refreshRoster(current, () async => true);
    await Future.wait(
      List.generate(
        10,
        (_) => service.saveSelection(current, ['a', 'b'], () async => true),
      ),
    );
    expect(await service.loadHistory(current), hasLength(10));
  });

  test('consulta antiga não substitui carteira mais recente', () async {
    final current = basis();
    final first = Completer<List<AnimalData>>();
    final second = Completer<List<AnimalData>>();
    var requests = 0;
    final concurrent = AtlasGrazingAnimalsService(
      fetchAnimals: (_) => ++requests == 1 ? first.future : second.future,
    );
    final older = concurrent.refreshRoster(current, () async => true);
    await Future<void>.delayed(Duration.zero);
    final newer = concurrent.refreshRoster(current, () async => true);
    await Future<void>.delayed(Duration.zero);
    second.complete([animal('new')]);
    expect((await newer).animals.single.id, 'new');
    first.complete([animal('old')]);
    await expectLater(older, throwsStateError);
    expect((await concurrent.loadRoster(current))!.animals.single.id, 'new');
  });

  test('seleção exige a carteira exibida quando há nova consulta', () async {
    final current = basis();
    final first = await service.refreshRoster(current, () async => true);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final second = await service.refreshRoster(current, () async => true);
    expect(first.hasSameData(second), isFalse);
    await expectLater(
      service.saveSelection(
        current,
        ['a', 'b'],
        () async => true,
        expectedRosterAt: first.recordedAt,
      ),
      throwsStateError,
    );
    expect(await service.loadHistory(current), isEmpty);
    await service.saveSelection(
      current,
      ['a', 'b'],
      () async => true,
      expectedRosterAt: second.recordedAt,
    );
    expect((await service.loadCurrent(current))?.rosterAt, second.recordedAt);
  });

  test('comparação de carteira detecta mudança de estado sem mudar IDs', () {
    final at = DateTime.utc(2026, 10, 1);
    final original = AtlasGrazingRoster([
      const AtlasGrazingCandidate('a', 'A', 'Animal A', true),
    ], at);
    expect(original.hasSameData(original), isTrue);
    expect(original.hasSameData(null), isFalse);
    expect(
      original.hasSameData(
        AtlasGrazingRoster([
          const AtlasGrazingCandidate('a', 'A', 'Animal A', false),
        ], at),
      ),
      isFalse,
    );
  });
}
