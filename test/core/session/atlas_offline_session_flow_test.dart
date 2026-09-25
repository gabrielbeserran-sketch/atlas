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

  @override
  Future<AtlasRemoteSession> me() {
    meCalls++;
    return refresh.future;
  }

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

AtlasRemoteSession _session({
  String companyId = 'company-a',
  String role = 'owner',
  List<String> farmIds = const ['farm-a'],
}) => AtlasRemoteSession.fromMap({
  'access_token': 'token-de-teste',
  'refresh_token': 'refresh-de-teste',
  'expires_in_seconds': 3600,
  'user_id': 'user-a',
  'user_name': 'Pessoa de teste',
  'email': 'teste@atlas.local',
  'company_id': companyId,
  'tenant_id': 'tenant-a',
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

    api.refresh.completeError(StateError('sem conexão'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, AtlasSessionStatus.authenticated);
    expect(controller.offlineMode, isTrue);
  });

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
}
