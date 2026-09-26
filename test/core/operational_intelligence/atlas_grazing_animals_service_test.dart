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
}
