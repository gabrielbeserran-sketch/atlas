import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_lookup_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeClient extends AtlasHttpClient {
  _FakeClient(this.respond);

  final Future<AtlasHttpResponse> Function(Map<String, dynamic>) respond;
  final calls = <Map<String, dynamic>>[];

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
    expect(method, 'POST');
    expect(path, '/offline/dairy/lookup');
    expect(authenticated, isTrue);
    calls.add(body!);
    return respond(body);
  }
}

class _CapabilityClient extends AtlasHttpClient {
  _CapabilityClient(this.body, {this.onRequest});

  final Map<String, dynamic> body;
  final void Function()? onRequest;

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
    expect(method, 'GET');
    expect(path, '/offline/status');
    expect(authenticated, isTrue);
    expect(transientRetries, 0);
    onRequest?.call();
    return _response(this.body);
  }
}

AtlasHttpResponse _response(Map<String, dynamic> body) => AtlasHttpResponse(
  statusCode: 200,
  body: body,
  headers: const <String, String>{},
);

const first = DairyLookupKey(
  entityType: 'dairy_daily_production',
  entityId: 'farm-a:2026-09-30',
);
const second = DairyLookupKey(
  entityType: 'dairy_herd_snapshot',
  entityId: 'farm-a:2026-09-30',
);

Map<String, dynamic> item(
  DairyLookupKey key, {
  bool found = true,
  int version = 1,
  bool deleted = false,
  Map<String, dynamic>? payload,
}) => <String, dynamic>{
  'entity_type': key.entityType,
  'entity_id': key.entityId,
  'found': found,
  'version': version,
  'deleted': deleted,
  'payload':
      payload ??
      (found
          ? key.entityType == 'dairy_daily_production'
                ? <String, dynamic>{
                    'date': '2026-09-30T00:00:00.000',
                    'morning_liters': 12,
                    'afternoon_liters': 8,
                    'cows_milked': 5,
                    'farm_id': 'farm-a',
                  }
                : <String, dynamic>{
                    'date': '2026-09-30T00:00:00.000',
                    'eligible_cows': 10,
                    'lactating_cows': 5,
                    'dry_cows': 5,
                    'farm_id': 'farm-a',
                  }
          : <String, dynamic>{}),
};

Map<String, dynamic> batch(
  List<Map<String, dynamic>> items, {
  String farmId = 'farm-a',
}) => <String, dynamic>{
  'farm_id': farmId,
  'read_at': '2026-10-01T12:00:00+00:00',
  'items': items,
};

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('capacidade ausente em backend antigo não ativa consulta', () async {
    final service = DairyRemoteLookupService(
      client: _CapabilityClient(<String, dynamic>{'status': 'ready'}),
    );
    expect(await service.supportsLookup(isScopeCurrent: () => true), isFalse);
  });

  test(
    'capacidade explícita habilita consulta, mas troca de escopo invalida',
    () async {
      final service = DairyRemoteLookupService(
        client: _CapabilityClient(<String, dynamic>{
          'capabilities': <String, dynamic>{'dairy_lookup': true},
        }),
      );
      expect(await service.supportsLookup(isScopeCurrent: () => true), isTrue);
      var current = true;
      final switched = DairyRemoteLookupService(
        client: _CapabilityClient(<String, dynamic>{
          'capabilities': <String, dynamic>{'dairy_lookup': true},
        }, onRequest: () => current = false),
      );
      await expectLater(
        switched.supportsLookup(isScopeCurrent: () => current),
        throwsStateError,
      );
    },
  );

  test(
    'confere identidade e devolve ordem pedida, mesmo fora de ordem',
    () async {
      final client = _FakeClient(
        (_) async => _response(
          batch([item(second, found: false, version: 0), item(first)]),
        ),
      );
      final states = await DairyRemoteLookupService(client: client).lookup(
        farmId: 'farm-a',
        keys: const [first, second],
        isScopeCurrent: () => true,
      );
      expect(states.map((state) => state.key.entityType), [
        'dairy_daily_production',
        'dairy_herd_snapshot',
      ]);
      expect(states.first.version, 1);
      expect(states.last.found, isFalse);
      expect(states.first.readAt.isUtc, isTrue);
      expect(client.calls.single['items'], [first.toMap(), second.toMap()]);
    },
  );

  test(
    'resposta faltante, duplicada ou de outra fazenda falha inteira',
    () async {
      for (final invalid in [
        batch([item(first)]),
        batch([item(first), item(first)]),
        batch([item(first), item(second)], farmId: 'farm-b'),
        batch([item(first), item(second)])..['read_at'] = '2026-10-01',
      ]) {
        final service = DairyRemoteLookupService(
          client: _FakeClient((_) async => _response(invalid)),
        );
        await expectLater(
          service.lookup(
            farmId: 'farm-a',
            keys: const [first, second],
            isScopeCurrent: () => true,
          ),
          throwsStateError,
        );
      }
    },
  );

  test('versão, ausência e payload incoerentes não são aceitos', () async {
    for (final invalid in [
      item(first, version: 0),
      item(first, found: false, version: 2),
      item(first, found: false, version: 0, payload: {'x': 1}),
      item(
        first,
        payload: {
          ...item(first)['payload'] as Map<String, dynamic>,
          'farm_id': 'farm-b',
        },
      ),
      item(first, payload: {'date': '2026-09-29'}),
      item(
        first,
        payload: {
          ...item(first)['payload'] as Map<String, dynamic>,
          'morning_liters': -1,
        },
      ),
    ]) {
      await expectLater(
        DairyRemoteLookupService(
          client: _FakeClient((_) async => _response(batch([invalid]))),
        ).lookup(
          farmId: 'farm-a',
          keys: const [first],
          isScopeCurrent: () => true,
        ),
        throwsStateError,
      );
    }
  });

  test('201 registros são consultados em blocos de no máximo 200', () async {
    final keys = List.generate(201, (index) {
      final day = DateTime(2026, 1, 1).add(Duration(days: index));
      final date =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      return DairyLookupKey(
        entityType: 'dairy_daily_production',
        entityId: 'farm-a:$date',
      );
    });
    final client = _FakeClient((body) async {
      final requested = body['items'] as List;
      return _response(
        batch([
          for (final raw in requested)
            <String, dynamic>{
              ...Map<String, dynamic>.from(raw as Map),
              'found': false,
              'version': 0,
              'deleted': false,
              'payload': {},
            },
        ]),
      );
    });
    final states = await DairyRemoteLookupService(
      client: client,
    ).lookup(farmId: 'farm-a', keys: keys, isScopeCurrent: () => true);
    expect(client.calls.map((body) => (body['items'] as List).length), [
      200,
      1,
    ]);
    expect(states.length, 201);
  });

  test('entrada inválida e escopo revogado impedem uso de resposta', () async {
    final client = _FakeClient((_) async => _response(batch([item(first)])));
    final service = DairyRemoteLookupService(client: client);
    await expectLater(
      service.lookup(
        farmId: 'farm-a',
        keys: const [first, first],
        isScopeCurrent: () => true,
      ),
      throwsStateError,
    );
    await expectLater(
      service.lookup(
        farmId: 'farm-b',
        keys: const [first],
        isScopeCurrent: () => true,
      ),
      throwsStateError,
    );
    expect(client.calls, isEmpty);

    var current = true;
    final delayed = _FakeClient((_) async {
      current = false;
      return _response(batch([item(first)]));
    });
    await expectLater(
      DairyRemoteLookupService(client: delayed).lookup(
        farmId: 'farm-a',
        keys: const [first],
        isScopeCurrent: () => current,
      ),
      throwsStateError,
    );
  });

  test('rota ausente propaga falha sem aceitar ausência presumida', () async {
    final client = _FakeClient(
      (_) async => throw const AtlasHttpException(
        'Rota não disponível',
        statusCode: 404,
      ),
    );
    await expectLater(
      DairyRemoteLookupService(client: client).lookup(
        farmId: 'farm-a',
        keys: const [first],
        isScopeCurrent: () => true,
      ),
      throwsA(isA<AtlasHttpException>()),
    );
  });
}
