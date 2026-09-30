import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/core/offline/models/offline_operation.dart';
import 'package:projeto_atlas/core/offline/services/offline_repository.dart';
import 'package:projeto_atlas/core/offline/services/offline_sync_coordinator.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

OfflineOperation _operation({String company = 'company-a'}) => OfflineOperation(
  id: 'operation-a',
  idempotencyKey: 'key-a',
  entityType: 'farm_note',
  entityId: 'note-a',
  operationType: 'update',
  payload: const <String, dynamic>{'value': 1},
  baseVersion: 0,
  companyId: company,
  tenantId: 'tenant-$company',
  farmId: 'farm-a',
  deviceId: 'device-a',
  createdAt: DateTime.utc(2026, 9, 30),
);

class _Repository extends OfflineRepository {
  _Repository({this.operations = const <OfflineOperation>[]});

  List<OfflineOperation> operations;
  int accepted = 0;
  int applied = 0;
  int cursorWrites = 0;
  int conflictImports = 0;
  int purges = 0;

  @override
  Future<List<OfflineOperation>> pending({
    required String companyId,
    String? farmId,
    int limit = 200,
  }) async => operations;

  @override
  Future<void> markAccepted(String id) async => accepted++;

  @override
  Future<int> getCursor({required String companyId, String? farmId}) async => 0;

  @override
  Future<void> applyChange({
    required String companyId,
    required String tenantId,
    String? farmId,
    required Map<String, dynamic> change,
  }) async => applied++;

  @override
  Future<void> setCursor({
    required String companyId,
    String? farmId,
    required int value,
  }) async => cursorWrites++;

  @override
  Future<void> importRemoteConflicts({
    required String companyId,
    required String tenantId,
    required List<Map<String, dynamic>> conflicts,
  }) async => conflictImports++;

  @override
  Future<void> purgeAccepted({
    Duration olderThan = const Duration(days: 7),
  }) async => purges++;
}

class _Http extends AtlasHttpClient {
  _Http({this.gatePath});

  final String? gatePath;
  final Completer<AtlasHttpResponse> gate = Completer<AtlasHttpResponse>();
  final List<String> calls = <String>[];

  AtlasHttpResponse response(String path) => AtlasHttpResponse(
    statusCode: 200,
    headers: const <String, String>{},
    body: switch (path) {
      '/offline/push-batch' => <String, dynamic>{
        'results': <Map<String, dynamic>>[
          <String, dynamic>{'operation_id': 'operation-a', 'accepted': true},
        ],
      },
      '/offline/pull-page' => <String, dynamic>{
        'changes': <Map<String, dynamic>>[
          <String, dynamic>{
            'entity_type': 'farm_note',
            'entity_id': 'note-a',
            'version': 1,
            'payload': <String, dynamic>{'value': 1},
            'cursor': 1,
          },
        ],
        'next_cursor': 1,
        'has_more': false,
      },
      '/offline/conflicts' => <Map<String, dynamic>>[],
      _ => throw StateError('Rota inesperada: $path'),
    },
  );

  @override
  Future<AtlasHttpResponse> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    int transientRetries = 2,
  }) async {
    calls.add(path);
    if (path == gatePath) return gate.future;
    return response(path);
  }
}

Future<void> _waitForCall(_Http client, String path) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (client.calls.contains(path)) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw StateError('A rota $path não foi chamada.');
}

Future<void> _run(
  _Repository repository,
  _Http http,
  bool Function() isCurrent,
) => OfflineSyncCoordinator(client: http, repository: repository).synchronize(
  companyId: 'company-a',
  tenantId: 'tenant-company-a',
  farmId: 'farm-a',
  deviceId: 'device-a',
  isScopeCurrent: isCurrent,
);

void main() {
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('resposta de envio atrasada não baixa fila da outra sessão', () async {
    var current = true;
    final repository = _Repository(
      operations: <OfflineOperation>[_operation()],
    );
    final http = _Http(gatePath: '/offline/push-batch');
    final run = _run(repository, http, () => current);
    await _waitForCall(http, '/offline/push-batch');
    current = false;
    http.gate.complete(http.response('/offline/push-batch'));

    await expectLater(run, throwsStateError);
    expect(repository.accepted, 0);
    expect(repository.applied, 0);
    expect(repository.cursorWrites, 0);
  });

  test(
    'resposta de pull atrasada não entra no cache nem avança cursor',
    () async {
      var current = true;
      final repository = _Repository();
      final http = _Http(gatePath: '/offline/pull-page');
      final run = _run(repository, http, () => current);
      await _waitForCall(http, '/offline/pull-page');
      current = false;
      http.gate.complete(http.response('/offline/pull-page'));

      await expectLater(run, throwsStateError);
      expect(repository.applied, 0);
      expect(repository.cursorWrites, 0);
      expect(repository.conflictImports, 0);
    },
  );

  test('resposta de conflitos atrasada não importa outro escopo', () async {
    var current = true;
    final repository = _Repository();
    final http = _Http(gatePath: '/offline/conflicts');
    final run = _run(repository, http, () => current);
    await _waitForCall(http, '/offline/conflicts');
    current = false;
    http.gate.complete(http.response('/offline/conflicts'));

    await expectLater(run, throwsStateError);
    expect(repository.conflictImports, 0);
    expect(repository.purges, 0);
  });

  test('fila com empresa diferente é recusada antes do envio', () async {
    final repository = _Repository(
      operations: <OfflineOperation>[_operation(company: 'company-b')],
    );
    final http = _Http();
    await expectLater(_run(repository, http, () => true), throwsStateError);
    expect(http.calls, isEmpty);
    expect(repository.accepted, 0);
  });

  test('fluxo normal mantém envio, pull e cursor', () async {
    final repository = _Repository(
      operations: <OfflineOperation>[_operation()],
    );
    final http = _Http();
    await _run(repository, http, () => true);
    expect(repository.accepted, 1);
    expect(repository.applied, 1);
    expect(repository.cursorWrites, 1);
    expect(repository.conflictImports, 1);
    expect(repository.purges, 1);
  });
}
