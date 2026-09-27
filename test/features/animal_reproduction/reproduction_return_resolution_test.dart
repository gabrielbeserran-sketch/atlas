import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
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
  Map<String, dynamic>? saved;
  bool dropResolution = false;
  bool offline = false;
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
      saved = {...body!, 'id': 'event', 'animal_id': 'cow'};
    }
    final response = {...?saved};
    if (dropResolution) response['metadata_json'] = {};
    return AtlasHttpResponse(
      statusCode: 200,
      body: method == 'GET' ? [response] : response,
      headers: {},
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
      expect(result.past, 0);
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
}
