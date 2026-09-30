import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/core/offline/controllers/atlas_offline_controller.dart';
import 'package:projeto_atlas/core/offline/models/offline_operation.dart';
import 'package:projeto_atlas/core/offline/models/offline_sync_models.dart';
import 'package:projeto_atlas/core/offline/services/offline_repository.dart';
import 'package:projeto_atlas/core/offline/services/offline_sync_coordinator.dart';
import 'package:projeto_atlas/core/session/atlas_session_controller.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

AtlasRemoteSession _session(String company) => AtlasRemoteSession(
  accessToken: 'test-token',
  refreshToken: 'test-refresh',
  expiresInSeconds: 3600,
  userId: 'operator',
  userName: 'Operador',
  email: 'operator@example.invalid',
  companyId: company,
  tenantId: 'tenant-$company',
  role: 'operator',
  companies: const <AtlasRemoteCompanySession>[],
  effectivePermissions: const <String>{'sync.read', 'sync.manage'},
  farmIds: <String>['farm-$company'],
  savedAt: DateTime.utc(2026, 9, 30),
);

AtlasRemoteFarm _farm(String company) => AtlasRemoteFarm(
  id: 'farm-$company',
  tenantId: 'tenant-$company',
  companyId: company,
  name: 'Fazenda de teste',
  city: '',
  state: '',
  animals: 0,
  area: 0,
  active: true,
);

class _Session extends AtlasSessionController {
  AtlasRemoteSession? current = _session('company-a');
  AtlasRemoteFarm? selected = _farm('company-a');

  @override
  AtlasRemoteSession? get session => current;

  @override
  AtlasRemoteFarm? get activeFarm => selected;

  void switchTo(String company) {
    current = _session(company);
    selected = _farm(company);
    notifyListeners();
  }
}

OfflineConflict _conflict({int remoteVersion = 1}) => OfflineConflict(
  id: 'operation-a',
  operationId: 'operation-a',
  entityType: 'farm_note',
  entityId: 'note-a',
  localPayload: const <String, dynamic>{'value': 'local'},
  remotePayload: const <String, dynamic>{'value': 'old'},
  localVersion: 0,
  remoteVersion: remoteVersion,
  status: 'open',
  createdAt: DateTime.utc(2026, 9, 30),
  serverConflictId: 'server-conflict-a',
  farmId: 'farm-company-a',
);

Map<String, dynamic> _updatedConflict() => <String, dynamic>{
  'id': 'server-conflict-a',
  'operation_id': 'operation-a',
  'farm_id': 'farm-company-a',
  'entity_type': 'farm_note',
  'entity_id': 'note-a',
  'local_payload': <String, dynamic>{'value': 'local'},
  'remote_payload': <String, dynamic>{'value': 'new'},
  'local_version': 0,
  'remote_version': 2,
  'status': 'open',
  'created_at': '2026-09-30T00:00:00Z',
};

class _Repository extends OfflineRepository {
  OfflineConflict? current = _conflict();
  int imports = 0;

  @override
  Future<OfflineQueueStats> queueStats({
    required String companyId,
    String? farmId,
  }) async => OfflineQueueStats(
    pending: 0,
    retry: 0,
    conflicts: companyId == 'company-a' ? 1 : 0,
    failed: 0,
    accepted: 0,
  );

  @override
  Future<List<OfflineConflict>> conflicts({
    required String companyId,
    String? farmId,
    String status = 'open',
  }) async => companyId == 'company-a' && current != null
      ? <OfflineConflict>[current!]
      : <OfflineConflict>[];

  @override
  Future<List<OfflineOperation>> failedOperations({
    required String companyId,
    String? farmId,
    int limit = 50,
  }) async => <OfflineOperation>[];

  @override
  Future<void> importRemoteConflicts({
    required String companyId,
    required String tenantId,
    required List<Map<String, dynamic>> conflicts,
  }) async {
    expect(companyId, 'company-a');
    expect(tenantId, 'tenant-company-a');
    imports += 1;
    current = _conflict(
      remoteVersion: (conflicts.single['remote_version'] as num).toInt(),
    );
    current = OfflineConflict(
      id: current!.id,
      operationId: current!.operationId,
      entityType: current!.entityType,
      entityId: current!.entityId,
      localPayload: current!.localPayload,
      remotePayload: Map<String, dynamic>.from(
        conflicts.single['remote_payload'] as Map,
      ),
      localVersion: current!.localVersion,
      remoteVersion: current!.remoteVersion,
      status: 'open',
      createdAt: current!.createdAt,
      serverConflictId: current!.serverConflictId,
      farmId: current!.farmId,
    );
  }
}

class _Coordinator extends OfflineSyncCoordinator {
  _Coordinator({this.remote, this.failFetch = false});

  final Future<List<Map<String, dynamic>>>? remote;
  final bool failFetch;

  @override
  Future<Map<String, dynamic>> resolveConflict({
    required OfflineConflict conflict,
    required String resolution,
    Map<String, dynamic>? mergedPayload,
    String note = '',
  }) async =>
      throw const AtlasHttpException('O registro mudou.', statusCode: 409);

  @override
  Future<List<Map<String, dynamic>>> fetchRemoteConflicts() async {
    if (failFetch) throw StateError('Servidor indisponível');
    return remote ?? <Map<String, dynamic>>[_updatedConflict()];
  }

  @override
  Future<OfflineServerStatus> serverStatus() async => const OfflineServerStatus(
    ready: true,
    activeDevices: 1,
    openConflicts: 1,
    latestCursor: 2,
    maxBatchSize: 200,
    maxPullPage: 1000,
  );
}

class _DelayedSyncCoordinator extends _Coordinator {
  final Completer<void> entered = Completer<void>();
  final Completer<void> release = Completer<void>();
  bool Function()? currentScope;

  @override
  Future<String> registerDevice({required String deviceKey}) async =>
      'device-test';

  @override
  Future<OfflineSyncReport> synchronize({
    required String companyId,
    required String tenantId,
    required String deviceId,
    required bool Function() isScopeCurrent,
    String? farmId,
    OfflineSyncProgress? onProgress,
  }) async {
    currentScope = isScopeCurrent;
    entered.complete();
    await release.future;
    if (!isScopeCurrent()) throw StateError('Contexto mudou.');
    return OfflineSyncReport(
      pushed: 0,
      conflicts: 0,
      rejected: 0,
      pulled: 0,
      nextCursor: 0,
      startedAt: DateTime.utc(2026, 9, 30),
      finishedAt: DateTime.utc(2026, 9, 30),
    );
  }
}

void main() {
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('409 atualiza a comparação e exige nova decisão', () async {
    final session = _Session();
    final repository = _Repository();
    final controller = AtlasOfflineController(
      sessionController: session,
      repository: repository,
      coordinator: _Coordinator(),
    );
    try {
      await controller.load();
      await controller.resolve(controller.conflicts.single, 'keep_local');
      expect(repository.imports, 1);
      expect(controller.conflicts.single.remoteVersion, 2);
      expect(controller.conflicts.single.remotePayload, <String, dynamic>{
        'value': 'new',
      });
      expect(controller.error, contains('Compare os dados atualizados'));
    } finally {
      controller.dispose();
      session.dispose();
    }
  });

  test(
    'falha ao recarregar preserva conflito e mostra erro original',
    () async {
      final session = _Session();
      final repository = _Repository();
      final controller = AtlasOfflineController(
        sessionController: session,
        repository: repository,
        coordinator: _Coordinator(failFetch: true),
      );
      try {
        await controller.load();
        await controller.resolve(controller.conflicts.single, 'keep_local');
        expect(repository.imports, 0);
        expect(controller.conflicts.single.remoteVersion, 1);
        expect(controller.error, 'O registro mudou.');
      } finally {
        controller.dispose();
        session.dispose();
      }
    },
  );

  test(
    'troca de empresa durante a busca não importa conflito antigo',
    () async {
      final session = _Session();
      final repository = _Repository();
      final remote = Completer<List<Map<String, dynamic>>>();
      final controller = AtlasOfflineController(
        sessionController: session,
        repository: repository,
        coordinator: _Coordinator(remote: remote.future),
      );
      try {
        await controller.load();
        final resolution = controller.resolve(
          controller.conflicts.single,
          'keep_local',
        );
        await Future<void>.delayed(Duration.zero);
        session.switchTo('company-b');
        remote.complete(<Map<String, dynamic>>[_updatedConflict()]);
        await resolution;
        await Future<void>.delayed(Duration.zero);
        expect(repository.imports, 0);
        expect(controller.conflicts, isEmpty);
      } finally {
        controller.dispose();
        session.dispose();
      }
    },
  );

  test('troca A→B→A invalida resposta de sincronização antiga', () async {
    final session = _Session();
    final coordinator = _DelayedSyncCoordinator();
    final controller = AtlasOfflineController(
      sessionController: session,
      repository: _Repository(),
      coordinator: coordinator,
    );
    try {
      final work = controller.synchronize();
      await coordinator.entered.future;
      session.switchTo('company-b');
      session.switchTo('company-a');
      expect(coordinator.currentScope!(), isFalse);
      coordinator.release.complete();
      await work;
      expect(controller.lastReport, isNull);
    } finally {
      controller.dispose();
      session.dispose();
    }
  });
}
