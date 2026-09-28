import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/reproduction_return_queue.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/animal_reproduction_list_screen.dart';
import 'package:projeto_atlas/features/animal_reproduction_enterprise/presentation/screens/animal_reproduction_enterprise_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Http extends AtlasHttpClient {
  Completer<void>? gate;
  bool offline = false;
  int reads = 0;
  List<Map<String, dynamic>> rows = [
    {
      'id': 'event-1',
      'animal_id': 'animal-1',
      'event_type': 'iatf',
      'occurred_at': '2026-09-01',
      'expected_at': '2026-10-01',
      'metadata_json': <String, dynamic>{},
    },
  ];

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
    return AtlasHttpResponse(statusCode: 200, body: rows, headers: const {});
  }
}

class _OutOfOrderHttp extends AtlasHttpClient {
  final firstStarted = Completer<void>();
  final releaseFirst = Completer<void>();
  int reads = 0;
  Map<String, dynamic>? current = {
    'id': 'event-1',
    'animal_id': 'animal-1',
    'event_type': 'IATF',
    'occurred_at': '2026-09-01',
    'notes': 'antigo',
    'metadata_json': <String, dynamic>{},
  };

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
    if (method == 'GET') {
      reads++;
      if (reads == 1) {
        final stale = {...?current};
        firstStarted.complete();
        await releaseFirst.future;
        return AtlasHttpResponse(
          statusCode: 200,
          body: [stale],
          headers: const {},
        );
      }
      return AtlasHttpResponse(
        statusCode: 200,
        body: current == null
            ? []
            : [
                {...?current},
              ],
        headers: const {},
      );
    }
    if (method == 'PATCH') current = {...?current, ...?body};
    if (method == 'DELETE') current = null;
    return const AtlasHttpResponse(
      statusCode: 200,
      body: <String, dynamic>{},
      headers: {},
    );
  }
}

const _farm = FarmData(
  id: 'farm',
  name: 'Fazenda',
  city: 'Cidade',
  state: 'GO',
  animals: 1,
  area: 10,
);
const _group = HerdGroupData(
  name: 'Lote',
  category: 'Vacas',
  capacity: 10,
  paddock: 'A',
);
const _animal = AnimalData(
  id: 'animal-1',
  tag: '001',
  name: 'Aurora',
  sex: 'Fêmea',
  breed: 'Nelore',
  birthDate: '01/01/2020',
  weight: 400,
  status: 'Ativo',
);

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

  for (final operation in ['editar', 'excluir']) {
    test(
      'GET antigo não reverte cache após $operation em outra instância',
      () async {
        final http = _OutOfOrderHttp();
        const scope = ReturnQueueScope('tenant', 'company', 'farm', 'user');
        AnimalReproductionStorageService service() =>
            AnimalReproductionStorageService(
              httpClient: http,
              scopeProvider: (_) async => scope,
            );
        final reader = service();
        final writer = service();
        final staleRefresh = reader.refreshRecords(
          farmId: 'farm',
          animalId: 'animal-1',
        );
        await http.firstStarted.future;
        if (operation == 'editar') {
          await writer.updateRecord(
            farmId: 'farm',
            farmName: 'Fazenda',
            groupName: 'Lote',
            animalId: 'animal-1',
            record: const AnimalReproductionData(
              id: 'event-1',
              animalId: 'animal-1',
              type: 'IATF',
              date: '01/09/2026',
              result: '',
              bullOrSemen: '',
              responsible: '',
              notes: 'novo',
            ),
          );
        } else {
          await writer.deleteRecord(
            farmId: 'farm',
            farmName: 'Fazenda',
            groupName: 'Lote',
            animalId: 'animal-1',
            recordId: 'event-1',
          );
        }
        http.releaseFirst.complete();
        await expectLater(staleRefresh, throwsStateError);
        final cached = await reader.loadCachedRecords(
          farmId: 'farm',
          animalId: 'animal-1',
        );
        if (operation == 'editar') {
          expect(cached.single.notes, 'novo');
        } else {
          expect(cached, isEmpty);
        }
      },
    );
  }

  test('confirmação antiga não substitui edição mais recente', () async {
    final http = _OutOfOrderHttp();
    const scope = ReturnQueueScope('tenant', 'company', 'farm', 'user');
    AnimalReproductionStorageService service() =>
        AnimalReproductionStorageService(
          httpClient: http,
          scopeProvider: (_) async => scope,
        );
    Future<AnimalReproductionData> edit(String notes) => service().updateRecord(
      farmId: 'farm',
      farmName: 'Fazenda',
      groupName: 'Lote',
      animalId: 'animal-1',
      record: AnimalReproductionData(
        id: 'event-1',
        animalId: 'animal-1',
        type: 'IATF',
        date: '01/09/2026',
        result: '',
        bullOrSemen: '',
        responsible: '',
        notes: notes,
      ),
    );
    final older = edit('primeira');
    await http.firstStarted.future;
    expect((await edit('segunda')).notes, 'segunda');
    http.releaseFirst.complete();
    await expectLater(older, throwsStateError);
    expect(
      (await service().loadCachedRecords(
        farmId: 'farm',
        animalId: 'animal-1',
      )).single.notes,
      'segunda',
    );
  });

  test('snapshot ausente difere de leitura confirmada vazia', () async {
    final http = _Http()..rows = [];
    final storage = AnimalReproductionStorageService(
      httpClient: http,
      scopeProvider: (_) async =>
          const ReturnQueueScope('tenant', 'company', 'farm', 'user'),
    );
    final missing = await storage.loadCachedSnapshot(
      farmId: 'farm',
      animalId: 'animal-1',
    );
    expect(missing.available, isFalse);
    expect(missing.records, isEmpty);
    await storage.refreshRecords(farmId: 'farm', animalId: 'animal-1');
    http.offline = true;
    final confirmedEmpty = await storage.loadCachedSnapshot(
      farmId: 'farm',
      animalId: 'animal-1',
    );
    expect(confirmedEmpty.available, isTrue);
    expect(confirmedEmpty.records, isEmpty);
  });

  testWidgets('Enterprise abre cópia local antes da resposta remota', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        home: AnimalReproductionEnterpriseScreen(
          farm: _farm,
          group: _group,
          animal: _animal,
          storage: storage,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.textContaining('Histórico local aberto'), findsOneWidget);
    expect(find.text('Reprodução de Aurora'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('iatf'), 500);
    expect(find.text('iatf'), findsOneWidget);
    http.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.textContaining('Histórico atualizado'), findsOneWidget);
  });

  testWidgets('Enterprise não inventa zeros sem cópia nem servidor', (
    tester,
  ) async {
    final storage = AnimalReproductionStorageService(
      httpClient: _Http()..offline = true,
      scopeProvider: (_) async =>
          const ReturnQueueScope('tenant', 'company', 'farm', 'user'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalReproductionEnterpriseScreen(
          farm: _farm,
          group: _group,
          animal: _animal,
          storage: storage,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.textContaining('sem cópia confirmada'), findsOneWidget);
    expect(
      find.text('Sem base reprodutiva confirmada neste dispositivo.'),
      findsOneWidget,
    );
    expect(find.text('Nenhum registro reprodutivo.'), findsNothing);
  });
}
