import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/reproduction_return_queue.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/animal_reproduction_list_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Http extends AtlasHttpClient {
  Completer<void>? gate;
  bool offline = false;
  int reads = 0;

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
    reads++;
    if (offline) throw StateError('offline');
    await gate?.future;
    return const AtlasHttpResponse(
      statusCode: 200,
      body: [
        {
          'id': 'event-1',
          'animal_id': 'animal-1',
          'event_type': 'iatf',
          'occurred_at': '2026-09-01',
          'expected_at': '2026-10-01',
          'metadata_json': {},
        },
      ],
      headers: {},
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('cache local abre sem aguardar GET pendente', () async {
    final http = _Http();
    final scope = const ReturnQueueScope('tenant', 'company', 'farm', 'user');
    final storage = AnimalReproductionStorageService(
      httpClient: http,
      scopeProvider: (_) async => scope,
    );
    await storage.refreshRecords(farmId: 'farm', animalId: 'animal-1');
    http.gate = Completer<void>();
    final refresh = storage.refreshRecords(
      farmId: 'farm',
      animalId: 'animal-1',
    );
    expect(
      (await storage.loadCachedRecords(
        farmId: 'farm',
        animalId: 'animal-1',
      )).single.id,
      'event-1',
    );
    expect(http.reads, 2);
    http.gate!.complete();
    await refresh;
  });

  test(
    'mesmos nomes e animal não atravessam conta, usuário ou fazenda',
    () async {
      final http = _Http();
      var scope = const ReturnQueueScope('tenant', 'company', 'farm', 'user');
      final storage = AnimalReproductionStorageService(
        httpClient: http,
        scopeProvider: (_) async => scope,
      );
      await storage.refreshRecords(farmId: 'farm', animalId: 'animal-1');
      expect(
        (await storage.loadCachedRecords(
          farmId: 'farm',
          animalId: 'animal-1',
        )).length,
        1,
      );
      for (final other in [
        const ReturnQueueScope('other', 'company', 'farm', 'user'),
        const ReturnQueueScope('tenant', 'other', 'farm', 'user'),
        const ReturnQueueScope('tenant', 'company', 'other', 'user'),
        const ReturnQueueScope('tenant', 'company', 'farm', 'other'),
      ]) {
        scope = other;
        expect(
          await storage.loadCachedRecords(
            farmId: other.farmId,
            animalId: 'animal-1',
          ),
          isEmpty,
        );
      }
    },
  );

  test('resposta tardia após troca de conta não é exibida nem salva', () async {
    final http = _Http()..gate = Completer<void>();
    var scope = const ReturnQueueScope('tenant', 'company', 'farm', 'user');
    final storage = AnimalReproductionStorageService(
      httpClient: http,
      scopeProvider: (_) async => scope,
    );
    final pending = storage.refreshRecords(
      farmId: 'farm',
      animalId: 'animal-1',
    );
    await Future<void>.delayed(Duration.zero);
    scope = const ReturnQueueScope('tenant', 'another-company', 'farm', 'user');
    http.gate!.complete();
    await expectLater(pending, throwsStateError);
    expect(
      await storage.loadCachedRecords(farmId: 'farm', animalId: 'animal-1'),
      isEmpty,
    );
  });

  test(
    'cache nominal antigo não é importado sem proprietário verificável',
    () async {
      final old = AnimalReproductionStorageService(httpClient: _Http());
      await old.loadRecords(
        farmName: 'Mesmo nome',
        groupName: 'Mesmo lote',
        animalId: 'animal-1',
      );
      final scoped = AnimalReproductionStorageService(
        httpClient: _Http()..offline = true,
        scopeProvider: (_) async =>
            const ReturnQueueScope('tenant', 'company', 'farm', 'user'),
      );
      expect(
        await scoped.loadRecords(
          farmId: 'farm',
          farmName: 'Mesmo nome',
          groupName: 'Mesmo lote',
          animalId: 'animal-1',
        ),
        isEmpty,
      );
    },
  );

  testWidgets('lista mostra cópia local enquanto GET ainda não respondeu', (
    tester,
  ) async {
    final http = _Http();
    final storage = AnimalReproductionStorageService(
      httpClient: http,
      scopeProvider: (_) async =>
          const ReturnQueueScope('tenant', 'company', 'farm', 'user'),
    );
    await storage.refreshRecords(farmId: 'farm', animalId: 'animal-1');
    http.gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalReproductionListScreen(
          storage: storage,
          farm: const FarmData(
            id: 'farm',
            name: 'Fazenda',
            city: 'Cidade',
            state: 'GO',
            animals: 1,
            area: 10,
          ),
          group: const HerdGroupData(
            name: 'Lote',
            category: 'Vacas',
            capacity: 10,
            paddock: 'A',
          ),
          animal: const AnimalData(
            id: 'animal-1',
            tag: '001',
            name: 'Aurora',
            sex: 'Fêmea',
            breed: 'Nelore',
            birthDate: '01/01/2020',
            weight: 400,
            status: 'Ativo',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.textContaining('Histórico local aberto'), findsOneWidget);
    expect(find.text('Aurora'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    http.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.textContaining('Histórico atualizado'), findsOneWidget);
  });
}
