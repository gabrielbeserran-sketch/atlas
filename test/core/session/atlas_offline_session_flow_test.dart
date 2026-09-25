import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/auth/atlas_active_context.dart';
import 'package:projeto_atlas/core/auth/atlas_offline_pin_service.dart';
import 'package:projeto_atlas/core/session/atlas_session_controller.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _DelayedApi implements AtlasEnterpriseApiClient {
  final refresh = Completer<AtlasRemoteSession>();
  int meCalls = 0;
  final persistFlags = <bool>[];
  List<Map<String, dynamic>> farmResponse = const [];
  Map<String, dynamic> farmDetail = const {};
  bool failFarmList = false;

  @override
  Future<AtlasRemoteSession> me({bool persist = true}) {
    meCalls++;
    persistFlags.add(persist);
    return refresh.future;
  }

  @override
  Future<void> logout() =>
      AtlasEnterpriseRemoteAuthStore.instance.clearSession();

  @override
  Future<List<Map<String, dynamic>>> requestList(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    if (failFarmList) throw StateError('sem conexão');
    return farmResponse;
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async => farmDetail;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _farm = AtlasRemoteFarm(
  id: 'farm-a',
  tenantId: 'tenant-a',
  companyId: 'company-a',
  name: 'Fazenda A',
  city: 'Goiânia',
  state: 'GO',
  animals: 10,
  area: 20,
  active: true,
);

const _otherCompanyFarm = AtlasRemoteFarm(
  id: 'farm-b',
  tenantId: 'tenant-b',
  companyId: 'company-b',
  name: 'Fazenda B',
  city: 'Rio Verde',
  state: 'GO',
  animals: 5,
  area: 10,
  active: true,
);

const _otherTenantFarm = AtlasRemoteFarm(
  id: 'farm-a',
  tenantId: 'tenant-b',
  companyId: 'company-a',
  name: 'Fazenda de outro tenant',
  city: 'Goiânia',
  state: 'GO',
  animals: 1,
  area: 1,
  active: true,
);

const _unauthorizedFarm = AtlasRemoteFarm(
  id: 'farm-c',
  tenantId: 'tenant-a',
  companyId: 'company-a',
  name: 'Fazenda sem permissão',
  city: 'Goiânia',
  state: 'GO',
  animals: 2,
  area: 3,
  active: true,
);

AtlasRemoteSession _session({
  String userId = 'user-a',
  String companyId = 'company-a',
  String tenantId = 'tenant-a',
  String role = 'owner',
  List<String> farmIds = const ['farm-a'],
}) => AtlasRemoteSession.fromMap({
  'access_token': 'token-de-teste',
  'refresh_token': 'refresh-de-teste',
  'expires_in_seconds': 3600,
  'user_id': userId,
  'user_name': 'Pessoa de teste',
  'email': 'teste@atlas.local',
  'company_id': companyId,
  'tenant_id': tenantId,
  'role': role,
  'companies': <Map<String, dynamic>>[],
  'effective_permissions': <String>[],
  'farm_ids': farmIds,
});

Future<void> _saveOfflineContext(AtlasRemoteSession session) async {
  final store = AtlasEnterpriseRemoteAuthStore.instance;
  await store.saveSession(session);
  await store.saveFarmPortfolio([_farm]);
  await store.saveActiveFarm(_farm.id);
  await AtlasOfflinePinService.instance.save('123456');
}

Map<String, dynamic> _farmMap(AtlasRemoteFarm farm) => {
  'id': farm.id,
  'tenant_id': farm.tenantId,
  'company_id': farm.companyId,
  'name': farm.name,
  'city': farm.city,
  'state': farm.state,
  'animals': farm.animals,
  'area': farm.area,
  'active': farm.active,
};

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('reinício offline fica no login e PIN abre sem esperar a API', () async {
    await _saveOfflineContext(_session());
    final api = _DelayedApi();
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    expect(controller.status, AtlasSessionStatus.unauthenticated);
    expect(controller.activeFarm?.id, _farm.id);
    expect(controller.hasOfflineContext, isTrue);
    expect(api.meCalls, 0);

    final invalid = await controller.unlockOffline('000000');
    expect(invalid.unlocked, isFalse);
    expect(controller.status, AtlasSessionStatus.unauthenticated);
    expect(api.meCalls, 0);

    final unlocked = await controller.unlockOffline('123456');
    expect(unlocked.unlocked, isTrue);
    expect(controller.status, AtlasSessionStatus.authenticated);
    expect(controller.offlineMode, isTrue);
    expect(api.meCalls, 1);
    expect(api.persistFlags, [false]);

    api.refresh.completeError(StateError('sem conexão'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, AtlasSessionStatus.authenticated);
    expect(controller.offlineMode, isTrue);
  });

  test(
    'PIN salvo sem sessão é reconhecido mas não desbloqueia dados',
    () async {
      await AtlasOfflinePinService.instance.save('123456');
      final controller = AtlasSessionController(api: _DelayedApi());
      addTearDown(controller.dispose);

      await controller.restore();
      expect(controller.offlinePinConfigured, isTrue);
      expect(
        controller.offlineAccessState,
        AtlasOfflineAccessState.sessionMissing,
      );
      expect(controller.hasOfflineContext, isFalse);
      expect((await controller.unlockOffline('123456')).unlocked, isFalse);
    },
  );

  test('PIN não abre fazenda fora da carteira autorizada', () async {
    await _saveOfflineContext(_session(role: 'worker', farmIds: ['farm-b']));
    final api = _DelayedApi();
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    expect(controller.farms, isEmpty);
    expect(controller.hasOfflineContext, isFalse);
    expect((await controller.unlockOffline('123456')).unlocked, isFalse);
    expect(controller.status, AtlasSessionStatus.unauthenticated);
    expect(AtlasActiveContext.instance.farmId, isNull);
    expect(api.meCalls, 0);
  });

  test(
    'reinício troca fazenda salva de outra empresa também no contexto global',
    () async {
      await _saveOfflineContext(_session());
      final store = AtlasEnterpriseRemoteAuthStore.instance;
      await store.saveFarmPortfolio([_farm, _otherCompanyFarm]);
      await store.saveActiveFarm(_otherCompanyFarm.id);
      final api = _DelayedApi();
      final controller = AtlasSessionController(api: api);
      addTearDown(controller.dispose);

      await controller.restore();
      expect(controller.status, AtlasSessionStatus.unauthenticated);
      expect(controller.farms.map((farm) => farm.id), [_farm.id]);
      expect(controller.activeFarm?.id, _farm.id);
      expect(AtlasActiveContext.instance.farmId, _farm.id);
      expect(await store.loadActiveFarm(), _farm.id);
      expect(controller.hasOfflineContext, isTrue);
      expect(api.meCalls, 0);
    },
  );

  test('PIN não abre sessão sem empresa escolhida', () async {
    await _saveOfflineContext(_session(companyId: ''));
    final api = _DelayedApi();
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    expect(controller.farms, isEmpty);
    expect(controller.hasOfflineContext, isFalse);
    expect((await controller.unlockOffline('123456')).unlocked, isFalse);
    expect(api.meCalls, 0);
  });

  test(
    'PIN não abre cache de outro tenant mesmo com mesmo ID de fazenda',
    () async {
      await _saveOfflineContext(_session());
      await AtlasEnterpriseRemoteAuthStore.instance.saveFarmPortfolio([
        _otherTenantFarm,
      ]);
      final api = _DelayedApi();
      final controller = AtlasSessionController(api: api);
      addTearDown(controller.dispose);

      await controller.restore();
      expect(controller.farms, isEmpty);
      expect(controller.hasOfflineContext, isFalse);
      expect(AtlasActiveContext.instance.farmId, isNull);
      expect((await controller.unlockOffline('123456')).unlocked, isFalse);
      expect(api.meCalls, 0);
    },
  );

  test(
    'tentativas repetidas bloqueiam o PIN mesmo quando o próximo está certo',
    () async {
      await AtlasOfflinePinService.instance.save('123456');
      for (var attempt = 0; attempt < 4; attempt++) {
        final result = await AtlasOfflinePinService.instance.verifyForUnlock(
          '000000',
        );
        expect(result.unlocked, isFalse);
        expect(result.blocked, isFalse);
      }
      final fifth = await AtlasOfflinePinService.instance.verifyForUnlock(
        '000000',
      );
      expect(fifth.blocked, isTrue);
      final correctWhileBlocked = await AtlasOfflinePinService.instance
          .verifyForUnlock('123456');
      expect(correctWhileBlocked.unlocked, isFalse);
      expect(correctWhileBlocked.blocked, isTrue);
    },
  );

  test(
    'releitura remota só conserva fazendas da carteira autorizada',
    () async {
      await _saveOfflineContext(_session(role: 'worker'));
      final api = _DelayedApi()
        ..farmResponse = [
          _farmMap(_otherCompanyFarm),
          _farmMap(_otherTenantFarm),
          _farmMap(_unauthorizedFarm),
          _farmMap(_farm),
        ];
      final controller = AtlasSessionController(api: api);
      addTearDown(controller.dispose);

      await controller.restore();
      await controller.refreshFarms();

      expect(controller.farms.map((farm) => farm.id), [_farm.id]);
      expect(controller.activeFarm?.id, _farm.id);
      expect(
        (await AtlasEnterpriseRemoteAuthStore.instance.loadFarmPortfolio()).map(
          (farm) => farm.id,
        ),
        [_farm.id],
      );
    },
  );

  test('busca direta recusa fazenda fora da empresa', () async {
    await _saveOfflineContext(_session());
    final api = _DelayedApi()..farmDetail = _farmMap(_otherCompanyFarm);
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    await expectLater(controller.selectFarmById('farm-b'), throwsStateError);
    expect(controller.activeFarm?.id, _farm.id);
    expect(AtlasActiveContext.instance.farmId, _farm.id);
    expect(controller.farms.map((farm) => farm.id), [_farm.id]);
  });

  test('busca direta recusa fazenda sem permissão do colaborador', () async {
    await _saveOfflineContext(_session(role: 'worker'));
    final api = _DelayedApi()..farmDetail = _farmMap(_unauthorizedFarm);
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    await expectLater(controller.selectFarmById('farm-c'), throwsStateError);
    expect(controller.activeFarm?.id, _farm.id);
    expect(controller.farms.map((farm) => farm.id), [_farm.id]);
  });

  test('falha na releitura remota mantém carteira local intacta', () async {
    await _saveOfflineContext(_session());
    final api = _DelayedApi()..failFarmList = true;
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    await expectLater(controller.refreshFarms(), throwsStateError);
    expect(controller.activeFarm?.id, _farm.id);
    expect(controller.farms.map((farm) => farm.id), [_farm.id]);
    expect(controller.hasOfflineContext, isTrue);
  });

  test('novo login relê PIN salvo mesmo sem sessão no início', () async {
    await AtlasOfflinePinService.instance.save('123456');
    final api = _DelayedApi();
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    expect(controller.offlinePinConfigured, isTrue);
    expect(
      controller.offlineAccessState,
      AtlasOfflineAccessState.sessionMissing,
    );
    await AtlasEnterpriseRemoteAuthStore.instance.saveFarmPortfolio([_farm]);
    await controller.acceptSession(_session());

    expect(controller.offlinePinConfigured, isTrue);
    expect(controller.hasOfflineContext, isTrue);
    expect(controller.activeFarm?.id, _farm.id);
    expect(api.persistFlags, [false]);
  });

  test('resposta tardia após sair não restaura sessão encerrada', () async {
    await _saveOfflineContext(_session());
    final api = _DelayedApi();
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    expect((await controller.unlockOffline('123456')).unlocked, isTrue);
    await controller.logout();
    api.refresh.complete(_session());
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, AtlasSessionStatus.unauthenticated);
    expect(controller.session, isNull);
    expect(await AtlasEnterpriseRemoteAuthStore.instance.loadSession(), isNull);
    expect(api.persistFlags, [false]);
  });

  test('resposta antiga não substitui nova conta autenticada', () async {
    await _saveOfflineContext(_session());
    final api = _DelayedApi();
    final controller = AtlasSessionController(api: api);
    addTearDown(controller.dispose);

    await controller.restore();
    expect((await controller.unlockOffline('123456')).unlocked, isTrue);
    await AtlasEnterpriseRemoteAuthStore.instance.saveFarmPortfolio([
      _otherCompanyFarm,
    ]);
    final newer = _session(
      userId: 'user-b',
      companyId: 'company-b',
      tenantId: 'tenant-b',
      farmIds: ['farm-b'],
    );
    await controller.acceptSession(newer);
    api.refresh.complete(_session());
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, AtlasSessionStatus.authenticated);
    expect(controller.session?.userId, 'user-b');
    expect(controller.activeFarm?.id, 'farm-b');
    expect(
      (await AtlasEnterpriseRemoteAuthStore.instance.loadSession())?.userId,
      'user-b',
    );
    expect(api.persistFlags, [false, false]);
  });
}
