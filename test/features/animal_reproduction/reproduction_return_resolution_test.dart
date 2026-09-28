import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/reproduction_return_queue.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_return_resolution.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_return_schedule.dart';

AnimalReproductionData record() => const AnimalReproductionData(
  id: 'event',
  animalId: 'cow',
  date: '01/09/2026',
  expectedDate: '02/09/2026',
  type: 'IATF',
  eventCode: 'iatf',
  result: '',
  bullOrSemen: '',
  responsible: '',
  notes: '',
  metadata: {
    'other': {'keep': 1},
  },
);
AnimalReproductionData resolve({
  String status = 'completed',
  String actor = 'Operador',
  String reason = '',
}) => ReproductionReturnResolution.resolve(
  record(),
  status: status,
  responsible: actor,
  at: DateTime.utc(2026, 9, 3),
  reason: reason,
);

class FakeHttp extends AtlasHttpClient {
  Map<String, dynamic>? saved = {
    ...record().toApi(),
    'id': 'event',
    'animal_id': 'cow',
  };
  bool hasContract = true;
  bool stampAuthor = true;
  int patches = 0;
  bool dropResolution = false;
  bool offline = false;
  bool losePatchResponse = false;
  Future<void> Function()? afterGet;
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
    if (offline) throw StateError('offline');
    if (method == 'PATCH') {
      patches++;
      saved = {...?saved, ...body!, 'id': 'event', 'animal_id': 'cow'};
      final metadata = Map<String, dynamic>.from(
        saved!['metadata_json'] as Map,
      );
      if (stampAuthor && metadata['atlas_return_resolution'] is Map) {
        metadata['atlas_return_resolution'] = {
          ...metadata['atlas_return_resolution'] as Map,
          'authenticated_user_id': 'server-user',
        };
      }
      saved!['metadata_json'] = metadata;
      if (losePatchResponse) {
        throw StateError('Resposta de confirmação perdida');
      }
    }
    final response = {...?saved};
    if (method == 'GET' && afterGet != null) await afterGet!();
    if (dropResolution) response['metadata_json'] = {};
    return AtlasHttpResponse(
      statusCode: 200,
      body: method == 'GET' ? [response] : response,
      headers: hasContract ? {'X-Atlas-Reproduction-Returns': 'v1'} : {},
    );
  }
}

void main() {
  test('data impossível com auditoria correspondente não vale como baixa', () {
    final closed = resolve();
    final audit = closed.metadata['atlas_return_resolution'] as Map;
    final invalid = AnimalReproductionData.fromMap({
      ...closed.toMap(),
      'expectedDate': '31/02/2026',
      'metadata': {
        ...closed.metadata,
        'atlas_return_resolution': {...audit, 'expected_date': '31/02/2026'},
      },
    });
    expect(invalid.returnResolutionStatus, isNull);
  });
  test(
    'auditoria incompleta ou data futura não remove previsão da triagem',
    () {
      final closed = resolve();
      final audit = closed.metadata['atlas_return_resolution'] as Map;
      for (final change in [
        {'responsible': ''},
        {'resolved_at': 'ilegível'},
        {
          'resolved_at': DateTime.now()
              .add(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
        },
        {'status': 'unknown'},
      ]) {
        final invalid = AnimalReproductionData.fromMap({
          ...closed.toMap(),
          'metadata': {
            ...closed.metadata,
            'atlas_return_resolution': {...audit, ...change},
          },
        });
        expect(invalid.returnResolutionStatus, isNull);
        expect(
          ReproductionReturnSchedule.calculate([
            invalid,
          ], referenceDate: DateTime(2026, 9, 27)).past,
          1,
        );
      }
    },
  );
  test(
    'resolver exige origem/previsão existentes e não aceita data futura',
    () {
      for (final change in [
        {'date': '31/02/2026'},
        {'expectedDate': ''},
        {'id': ''},
      ]) {
        expect(
          () => ReproductionReturnResolution.resolve(
            AnimalReproductionData.fromMap({...record().toMap(), ...change}),
            status: 'completed',
            responsible: 'Operador',
            at: DateTime.utc(2026, 9, 3),
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => ReproductionReturnResolution.resolve(
          record(),
          status: 'completed',
          responsible: 'Operador',
          at: DateTime.now().add(const Duration(days: 1)),
        ),
        throwsArgumentError,
      );
    },
  );
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  test(
    'resolução preserva previsão, outros metadados e auditoria em round-trip',
    () {
      final closed = resolve();
      expect(closed.expectedDate, record().expectedDate);
      expect(closed.returnResolutionStatus, 'completed');
      expect(closed.metadata['other'], record().metadata['other']);
      expect(
        AnimalReproductionData.fromMap(closed.toMap()).returnResolutionStatus,
        'completed',
      );
      final remote = AnimalReproductionData.fromMap({
        ...closed.toApi(),
        'id': closed.id,
      });
      expect(remote.returnResolutionStatus, 'completed');
      expect(closed.withAnimalId('cow').returnResolutionStatus, 'completed');
      expect(record().metadata.containsKey('atlas_return_resolution'), isFalse);
    },
  );
  test(
    'cancelamento exige motivo e resolução não sobrescreve baixa existente',
    () {
      expect(() => resolve(status: 'cancelled'), throwsArgumentError);
      expect(
        resolve(
          status: 'cancelled',
          reason: 'Replanejado',
        ).returnResolutionStatus,
        'cancelled',
      );
      expect(() => resolve(actor: ''), throwsArgumentError);
      expect(() => resolve(status: 'unknown'), throwsArgumentError);
      expect(
        () => ReproductionReturnResolution.resolve(
          resolve(),
          status: 'cancelled',
          responsible: 'Outro',
          at: DateTime.utc(2026, 9, 4),
          reason: 'teste',
        ),
        throwsStateError,
      );
    },
  );
  test(
    'alterar previsão ou ID invalida baixa anterior sem apagar a auditoria',
    () {
      final closed = resolve();
      for (final change in [
        {'expectedDate': '04/09/2026'},
        {'id': 'other'},
        {'date': '04/09/2026'},
      ]) {
        final edited = AnimalReproductionData.fromMap({
          ...closed.toMap(),
          ...change,
        });
        expect(edited.returnResolutionStatus, isNull);
        expect(edited.metadata['atlas_return_resolution'], isNotNull);
      }
    },
  );
  test(
    'triagem exclui somente resolução válida, mantendo registros antigos pendentes de conferência',
    () {
      final result = ReproductionReturnSchedule.calculate([
        resolve(),
      ], referenceDate: DateTime(2026, 9, 27));
      expect(result.past, 1);
      final draft = resolve();
      final confirmed = AnimalReproductionData.fromMap({
        ...draft.toMap(),
        'metadata': {
          ...draft.metadata,
          'atlas_return_resolution': {
            ...draft.metadata['atlas_return_resolution'] as Map,
            'authenticated_user_id': 'server-user',
          },
        },
      });
      expect(
        ReproductionReturnSchedule.calculate([
          confirmed,
        ], referenceDate: DateTime(2026, 9, 27)).past,
        0,
      );
      expect(
        ReproductionReturnSchedule.calculate([
          record(),
        ], referenceDate: DateTime(2026, 9, 27)).past,
        1,
      );
    },
  );
  test(
    'confirmar servidor e reabrir offline preserva resolução no cache',
    () async {
      final http = FakeHttp();
      final storage = AnimalReproductionStorageService(httpClient: http);
      final saved = await storage.updateRecord(
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
        record: resolve(),
      );
      expect(saved.returnResolutionStatus, 'completed');
      http.offline = true;
      final reopened = await AnimalReproductionStorageService(
        httpClient: http,
      ).loadRecords(farmName: 'Teste', groupName: 'Grupo', animalId: 'cow');
      expect(reopened.single.returnResolutionStatus, 'completed');
    },
  );
  test('servidor que ignora metadados não confirma sucesso na baixa', () async {
    final http = FakeHttp()..dropResolution = true;
    await expectLater(
      AnimalReproductionStorageService(httpClient: http).updateRecord(
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
        record: resolve(),
      ),
      throwsStateError,
    );
  });
  test('contrato antigo é recusado antes de enviar qualquer baixa', () async {
    final http = FakeHttp()..hasContract = false;
    await expectLater(
      AnimalReproductionStorageService(httpClient: http).resolveReturn(
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
        record: record(),
        status: 'completed',
        responsible: 'Operador',
      ),
      throwsStateError,
    );
    expect(http.patches, 0);
  });
  test(
    'baixa exige autoria do servidor e retry confirmado não reenvia',
    () async {
      final http = FakeHttp();
      final storage = AnimalReproductionStorageService(httpClient: http);
      final saved = await storage.resolveReturn(
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
        record: record(),
        status: 'completed',
        responsible: 'Operador',
      );
      expect(saved.hasConfirmedReturnResolution, isTrue);
      await storage.resolveReturn(
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
        record: record(),
        status: 'completed',
        responsible: 'Outro',
      );
      expect(http.patches, 1);
      final old = FakeHttp()..stampAuthor = false;
      await expectLater(
        AnimalReproductionStorageService(httpClient: old).resolveReturn(
          farmName: 'Teste',
          groupName: 'Grupo',
          animalId: 'cow',
          record: record(),
          status: 'completed',
          responsible: 'Operador',
        ),
        throwsStateError,
      );
    },
  );
  test('previsão alterada no servidor impede baixa obsoleta', () async {
    final http = FakeHttp();
    http.saved!['expected_date'] = '2026-09-04';
    await expectLater(
      AnimalReproductionStorageService(httpClient: http).resolveReturn(
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
        record: record(),
        status: 'completed',
        responsible: 'Operador',
      ),
      throwsStateError,
    );
    expect(http.patches, 0);
  });
  const scope = ReturnQueueScope('tenant', 'company', 'farm', 'user');
  AnimalReproductionStorageService queued(FakeHttp http) =>
      AnimalReproductionStorageService(
        httpClient: http,
        scopeProvider: (_) async => scope,
      );
  AnimalReproductionData confirmedSource() => AnimalReproductionData.fromMap({
    ...record().toMap(),
    'synced': true,
    'animalId': 'cow',
  });

  test('baixa offline persiste sem retirar previsão da triagem', () async {
    final http = FakeHttp()..offline = true;
    final storage = queued(http);
    final first = await storage.queueReturn(
      farmId: 'farm',
      record: confirmedSource(),
      status: 'completed',
      responsible: ' Operador ',
    );
    final reopened = await queued(
      http,
    ).pendingReturns(farmId: 'farm', animalId: 'cow');
    expect(reopened.single.audit, first.audit);
    expect(first.conflict, isEmpty);
    expect(
      ReproductionReturnSchedule.calculate([
        confirmedSource(),
      ], referenceDate: DateTime(2026, 9, 27)).past,
      1,
    );
    expect(http.patches, 0);
  });
  test(
    'fila isola usuário/empresa/fazenda e mantém primeira intenção',
    () async {
      final http = FakeHttp();
      final storage = queued(http);
      final first = await storage.queueReturn(
        farmId: 'farm',
        record: confirmedSource(),
        status: 'completed',
        responsible: 'Operador',
      );
      final duplicate = await storage.queueReturn(
        farmId: 'farm',
        record: confirmedSource(),
        status: 'completed',
        responsible: 'Outro',
      );
      expect(duplicate.audit, first.audit);
      await expectLater(
        storage.queueReturn(
          farmId: 'farm',
          record: confirmedSource(),
          status: 'cancelled',
          responsible: 'Outro',
          reason: 'Mudança',
        ),
        throwsStateError,
      );
      final queue = ReproductionReturnQueue();
      for (final other in [
        const ReturnQueueScope('tenant', 'company', 'farm', 'other-user'),
        const ReturnQueueScope('tenant', 'other-company', 'farm', 'user'),
        const ReturnQueueScope('tenant', 'company', 'other-farm', 'user'),
      ]) {
        expect(await queue.read(other), isEmpty);
      }
    },
  );
  test('reconexão confirma uma vez e limpa apenas fila da conta', () async {
    final http = FakeHttp()..offline = true;
    final storage = queued(http);
    await storage.queueReturn(
      farmId: 'farm',
      record: confirmedSource(),
      status: 'cancelled',
      responsible: 'Operador',
      reason: 'Nova data',
    );
    http.offline = false;
    expect(
      await storage.syncQueuedReturns(
        farmId: 'farm',
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
      ),
      1,
    );
    expect(http.patches, 1);
    expect(
      (await queued(http).pendingReturns(farmId: 'farm', animalId: 'cow')),
      isEmpty,
    );
    expect(
      await storage.syncQueuedReturns(
        farmId: 'farm',
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
      ),
      0,
    );
    expect(http.patches, 1);
    expect(
      (await storage.loadRecords(
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
      )).single.hasConfirmedReturnResolution,
      isTrue,
    );
  });
  test(
    'resposta perdida reconcilia pela mesma auditoria sem segundo PATCH',
    () async {
      final http = FakeHttp()..losePatchResponse = true;
      final storage = queued(http);
      final pending = await storage.queueReturn(
        farmId: 'farm',
        record: confirmedSource(),
        status: 'completed',
        responsible: 'Operador',
      );
      await expectLater(
        storage.syncQueuedReturns(
          farmId: 'farm',
          farmName: 'Teste',
          groupName: 'Grupo',
          animalId: 'cow',
        ),
        throwsStateError,
      );
      expect(
        (await storage.pendingReturns(
          farmId: 'farm',
          animalId: 'cow',
        )).single.audit,
        pending.audit,
      );
      http.losePatchResponse = false;
      expect(
        await storage.syncQueuedReturns(
          farmId: 'farm',
          farmName: 'Teste',
          groupName: 'Grupo',
          animalId: 'cow',
        ),
        1,
      );
      expect(http.patches, 1);
    },
  );
  test('previsão divergente vira conflito persistente sem PATCH', () async {
    final http = FakeHttp();
    final storage = queued(http);
    await storage.queueReturn(
      farmId: 'farm',
      record: confirmedSource(),
      status: 'completed',
      responsible: 'Operador',
    );
    http.saved!['expected_date'] = '2026-09-04';
    expect(
      await storage.syncQueuedReturns(
        farmId: 'farm',
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
      ),
      0,
    );
    expect(http.patches, 0);
    expect(
      (await queued(
        http,
      ).pendingReturns(farmId: 'farm', animalId: 'cow')).single.conflict,
      contains('mudou'),
    );
  });
  test('servidor antigo e rede ausente preservam fila sem envio', () async {
    final http = FakeHttp()..hasContract = false;
    final storage = queued(http);
    await storage.queueReturn(
      farmId: 'farm',
      record: confirmedSource(),
      status: 'completed',
      responsible: 'Operador',
    );
    await expectLater(
      storage.syncQueuedReturns(
        farmId: 'farm',
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
      ),
      throwsStateError,
    );
    http.hasContract = true;
    http.offline = true;
    await expectLater(
      storage.syncQueuedReturns(
        farmId: 'farm',
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
      ),
      throwsStateError,
    );
    expect(
      (await storage.pendingReturns(farmId: 'farm', animalId: 'cow')).length,
      1,
    );
    expect(http.patches, 0);
  });
  test('evento não confirmado não pode receber baixa local', () async {
    await expectLater(
      queued(FakeHttp()).queueReturn(
        farmId: 'farm',
        record: record(),
        status: 'completed',
        responsible: 'Operador',
      ),
      throwsStateError,
    );
  });
  test('duas inclusões simultâneas não perdem nenhuma intenção', () async {
    final storage = queued(FakeHttp());
    final second = AnimalReproductionData.fromMap({
      ...confirmedSource().toMap(),
      'id': 'event-2',
    });
    await Future.wait([
      storage.queueReturn(
        farmId: 'farm',
        record: confirmedSource(),
        status: 'completed',
        responsible: 'Operador',
      ),
      storage.queueReturn(
        farmId: 'farm',
        record: second,
        status: 'cancelled',
        responsible: 'Operador',
        reason: 'Outra visita',
      ),
    ]);
    expect(
      (await storage.pendingReturns(farmId: 'farm', animalId: 'cow')).length,
      2,
    );
  });
  test('fila ilegível não é apagada silenciosamente', () async {
    const key = 'atlas_reproduction_return_queue_v1_tenant_company_farm_user';
    final prefs = SharedPreferencesAsync();
    await prefs.setString(key, 'arquivo corrompido');
    await expectLater(
      ReproductionReturnQueue(preferences: prefs).read(scope),
      throwsStateError,
    );
    expect(await prefs.getString(key), 'arquivo corrompido');
  });
  test('troca de conta após GET interrompe antes do PATCH', () async {
    final http = FakeHttp();
    var current = scope;
    final storage = AnimalReproductionStorageService(
      httpClient: http,
      scopeProvider: (_) async => current,
    );
    await storage.queueReturn(
      farmId: 'farm',
      record: confirmedSource(),
      status: 'completed',
      responsible: 'Operador',
    );
    http.afterGet = () async {
      current = const ReturnQueueScope(
        'tenant',
        'company',
        'farm',
        'other-user',
      );
    };
    await expectLater(
      storage.syncQueuedReturns(
        farmId: 'farm',
        farmName: 'Teste',
        groupName: 'Grupo',
        animalId: 'cow',
      ),
      throwsStateError,
    );
    expect(http.patches, 0);
    current = scope;
    expect(
      (await storage.pendingReturns(farmId: 'farm', animalId: 'cow')).length,
      1,
    );
  });
}
