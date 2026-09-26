import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_basis_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_sync.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

AtlasPastureGrazingBasis basis(
  String id, {
  int animals = 30,
  String farm = 'f',
}) => AtlasPastureGrazingBasis(
  operationId: id,
  tenantId: 't',
  companyId: 'c',
  farmId: farm,
  effectiveAreaHa: 20,
  grazingAnimals: animals,
  uniqueAreaConfirmed: true,
  recordedAt: DateTime.utc(2026, 1, 1),
);

Map<String, dynamic> remoteMap(AtlasPastureGrazingBasis b) => {
  'client_operation_id': b.operationId,
  'tenant_id': b.tenantId,
  'company_id': b.companyId,
  'farm_id': b.farmId,
  'effective_area_ha': b.effectiveAreaHa,
  'grazing_animals': b.grazingAnimals,
  'unique_area_confirmed': true,
  'recorded_at': b.recordedAt.toUtc().toIso8601String(),
};

class FailingPreferences extends SharedPreferencesAsync {
  FailingPreferences(this.shouldFail);
  final bool Function() shouldFail;
  @override
  Future<void> setString(String key, String value) async {
    if (shouldFail() && !key.endsWith('_reviews')) {
      throw StateError('Falha simulada de escrita.');
    }
    await super.setString(key, value);
  }
}

class FakeRemote implements AtlasGrazingRemote {
  bool enabled = true;
  bool loseResponse = false;
  int uploads = 0;
  int pages = 0;
  List<Map<String, dynamic>> records = [];
  Map<String, dynamic>? badConfirmation;
  @override
  Future<bool> supports(String farmId) async => enabled;
  @override
  Future<List<Map<String, dynamic>>> history(
    String farmId,
    int offset,
    int limit,
  ) async {
    pages++;
    return records.skip(offset).take(limit).toList();
  }

  @override
  Future<Map<String, dynamic>> upload(AtlasPastureGrazingBasis b) async {
    uploads++;
    final record = remoteMap(b);
    records.add(record);
    if (loseResponse) throw const AtlasEnterpriseApiException('timeout');
    return badConfirmation ?? record;
  }
}

void main() {
  late AtlasPastureGrazingBasisService local;
  late FakeRemote remote;
  late AtlasPastureGrazingSync sync;
  Future<AtlasGrazingSyncResult> run({Future<bool> Function()? guard}) =>
      sync.synchronize(
        tenantId: 't',
        companyId: 'c',
        farmId: 'f',
        isAuthorized: guard ?? () async => true,
      );
  Future<List<AtlasPastureGrazingBasis>> history() =>
      local.loadHistory(tenantId: 't', companyId: 'c', farmId: 'f');
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    local = AtlasPastureGrazingBasisService();
    remote = FakeRemote();
    sync = AtlasPastureGrazingSync(local: local, remote: remote, pageSize: 2);
  });

  test(
    'sem capacidade não consulta nem envia e mantém gravação local',
    () async {
      await local.save(basis('operation-local'));
      remote.enabled = false;
      final result = await run();
      expect(result.sent, 0);
      expect(remote.pages, 0);
      expect(remote.uploads, 0);
      expect(await history(), hasLength(1));
    },
  );

  test(
    'pagina, importa e envia apenas operações ausentes no servidor',
    () async {
      remote.records = [
        for (var i = 0; i < 3; i++) remoteMap(basis('remote-$i')),
      ];
      await local.save(basis('remote-0'));
      await local.save(basis('operation-local'));
      final result = await run();
      expect(remote.pages, 2);
      expect(result.received, 2);
      expect(result.sent, 1);
      expect(await history(), hasLength(4));
      await run();
      expect(remote.uploads, 1);
    },
  );

  test('resposta perdida é conciliada sem repetir POST', () async {
    await local.save(basis('operation-local'));
    remote.loseResponse = true;
    await run();
    expect(await history(), hasLength(1));
    await run();
    expect(remote.uploads, 1);
    expect(remote.records, hasLength(1));
  });

  test(
    'conflito preserva duas versões após reinício e suspende envio',
    () async {
      await local.save(basis('operation-conflict'));
      await local.save(basis('operation-pending'));
      remote.records = [remoteMap(basis('operation-conflict', animals: 99))];
      await run();
      expect(remote.uploads, 0);
      expect(await history(), hasLength(2));
      final restarted = AtlasPastureGrazingSync(local: local, remote: remote);
      final conflicts = await restarted.conflicts('t', 'c', 'f');
      expect((conflicts.single['local'] as Map)['grazingAnimals'], 30);
      expect((conflicts.single['remote'] as Map)['grazingAnimals'], 99);
      expect(await restarted.conflicts('t', 'c', 'other'), isEmpty);
    },
  );

  test(
    'resposta fora do escopo não contamina histórico nem gera envio',
    () async {
      await local.save(basis('operation-local'));
      remote.records = [remoteMap(basis('foreign', farm: 'other'))];
      await run();
      expect(await history(), hasLength(1));
      expect(remote.uploads, 0);
    },
  );

  test(
    'revisão aceita versão remota, arquiva originais e não escreve na API',
    () async {
      final original = basis('operation-review');
      final confirmed = basis('operation-review', animals: 99);
      await local.save(original);
      remote.records = [remoteMap(confirmed)];
      await run();
      await sync.acceptRemoteConflict(
        expectedRemote: confirmed,
        reviewedBy: 'user-1',
        isAuthorized: () async => true,
      );
      expect((await history()).single.grazingAnimals, 99);
      expect(remote.uploads, 0);
      expect(await sync.conflicts('t', 'c', 'f'), isEmpty);
      final restarted = AtlasPastureGrazingBasisService();
      final reviews = await restarted.reviewedHistory(
        tenantId: 't',
        companyId: 'c',
        farmId: 'f',
      );
      expect((reviews.single['local'] as Map)['grazingAnimals'], 30);
      expect((reviews.single['remote'] as Map)['grazingAnimals'], 99);
      expect(reviews.single['reviewedBy'], 'user-1');
      await restarted.acceptReviewedRemote(
        expectedLocal: original,
        remote: confirmed,
        reviewedBy: 'user-1',
      );
      expect(
        await restarted.reviewedHistory(
          tenantId: 't',
          companyId: 'c',
          farmId: 'f',
        ),
        hasLength(1),
      );
      await run();
      expect(remote.uploads, 0);
    },
  );

  test('revisão obsoleta ou sem autorização não altera versões', () async {
    await local.save(basis('operation-review'));
    remote.records = [remoteMap(basis('operation-review', animals: 99))];
    await run();
    await expectLater(
      sync.acceptRemoteConflict(
        expectedRemote: basis('operation-review', animals: 88),
        reviewedBy: 'user-1',
        isAuthorized: () async => true,
      ),
      throwsStateError,
    );
    await expectLater(
      sync.acceptRemoteConflict(
        expectedRemote: basis('operation-review', animals: 99),
        reviewedBy: 'user-1',
        isAuthorized: () async => false,
      ),
      throwsStateError,
    );
    expect((await history()).single.grazingAnimals, 30);
    expect(await sync.conflicts('t', 'c', 'f'), hasLength(1));
    expect(
      await local.reviewedHistory(tenantId: 't', companyId: 'c', farmId: 'f'),
      isEmpty,
    );
  });

  test(
    'revisão fora do escopo ou com versão local incorreta não cria auditoria',
    () async {
      final original = basis('operation-review');
      await local.save(original);
      for (final remoteVersion in [
        basis('operation-review', farm: 'other'),
        basis('other-operation'),
      ]) {
        await expectLater(
          local.acceptReviewedRemote(
            expectedLocal: original,
            remote: remoteVersion,
            reviewedBy: 'user-1',
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        local.acceptReviewedRemote(
          expectedLocal: basis('operation-review', animals: 88),
          remote: basis('operation-review', animals: 99),
          reviewedBy: 'user-1',
        ),
        throwsStateError,
      );
      await expectLater(
        local.acceptReviewedRemote(
          expectedLocal: original,
          remote: basis('operation-review', animals: 99),
          reviewedBy: '',
        ),
        throwsArgumentError,
      );
      expect((await history()).single.grazingAnimals, 30);
      expect(
        await local.reviewedHistory(tenantId: 't', companyId: 'c', farmId: 'f'),
        isEmpty,
      );
    },
  );

  test(
    'falha após arquivar mantém original e repetição não duplica auditoria',
    () async {
      var failHistory = false;
      final preferences = FailingPreferences(() => failHistory);
      local = AtlasPastureGrazingBasisService(preferences: preferences);
      final original = basis('operation-review');
      final confirmed = basis('operation-review', animals: 99);
      await local.save(original);
      failHistory = true;
      await expectLater(
        local.acceptReviewedRemote(
          expectedLocal: original,
          remote: confirmed,
          reviewedBy: 'user-1',
        ),
        throwsStateError,
      );
      expect((await history()).single.grazingAnimals, 30);
      expect(
        await local.reviewedHistory(tenantId: 't', companyId: 'c', farmId: 'f'),
        hasLength(1),
      );
      failHistory = false;
      await local.acceptReviewedRemote(
        expectedLocal: original,
        remote: confirmed,
        reviewedBy: 'user-1',
      );
      expect((await history()).single.grazingAnimals, 99);
      expect(
        await local.reviewedHistory(tenantId: 't', companyId: 'c', farmId: 'f'),
        hasLength(1),
      );
    },
  );

  test('mudança de fazenda durante consulta interrompe sem gravar', () async {
    var checks = 0;
    remote.records = [remoteMap(basis('operation-remote'))];
    await run(guard: () async => ++checks < 3);
    expect(await history(), isEmpty);
    expect(remote.uploads, 0);
  });

  test(
    'confirmação divergente fica preservada e não apaga registro local',
    () async {
      await local.save(basis('operation-local'));
      remote.badConfirmation = remoteMap(basis('operation-local', animals: 99));
      await run();
      expect((await history()).single.grazingAnimals, 30);
      expect(await sync.conflicts('t', 'c', 'f'), hasLength(1));
    },
  );
}
