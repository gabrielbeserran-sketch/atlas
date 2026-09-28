import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/reproduction_overview_snapshot_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

AtlasRemoteSession _session({
  String user = 'user-1',
  String company = 'company-1',
  List<String> farms = const ['farm-1'],
  bool canRead = true,
}) => AtlasRemoteSession(
  accessToken: 'test',
  refreshToken: 'test',
  expiresInSeconds: 3600,
  userId: user,
  userName: '',
  email: '',
  companyId: company,
  tenantId: 'tenant-1',
  role: 'worker',
  companies: const [],
  effectivePermissions: canRead ? const {'reproduction.read'} : const {},
  farmIds: farms,
  savedAt: DateTime(2026, 9, 28),
);

const _farm = FarmData(
  id: 'farm-1',
  name: 'Fazenda Um',
  city: 'Cidade',
  state: 'GO',
  animals: 1,
  area: 100,
);
const _group = HerdGroupData(
  id: 'lot-1',
  name: 'Matrizes',
  category: 'Matrizes',
  capacity: 100,
  paddock: 'P1',
);
const _animal = AnimalData(
  id: 'animal-1',
  lotId: 'lot-1',
  tag: '42',
  name: 'Aurora',
  sex: 'Fêmea',
  breed: 'Nelore',
  birthDate: '01/01/2020',
  weight: 450,
  status: 'Ativo',
);

AnimalReproductionData _event() => const AnimalReproductionData(
  id: 'event-1',
  animalId: 'animal-1',
  type: 'IATF',
  date: '01/09/2026',
  result: '',
  bullOrSemen: '',
  responsible: '',
  notes: '',
);

class _Fixture {
  AtlasRemoteSession session = _session();
  bool failGroups = false;
  Completer<void>? gate;
  Completer<void>? farmStarted;
  int farmCalls = 0;
  int groupCalls = 0;
  int animalCalls = 0;
  int recordCalls = 0;
  List<AnimalReproductionData> records = [_event()];

  ReproductionOverviewSnapshotService create() =>
      ReproductionOverviewSnapshotService(
        preferences: SharedPreferencesAsync(),
        sessionProvider: () async => session,
        farmsProvider: () async {
          farmCalls++;
          if (farmStarted != null && !farmStarted!.isCompleted) {
            farmStarted!.complete();
          }
          await gate?.future;
          return [_farm];
        },
        groupsProvider: (_) async {
          groupCalls++;
          if (failGroups) throw StateError('offline');
          return [_group];
        },
        animalsProvider: (_, _) async {
          animalCalls++;
          return [_animal];
        },
        recordsProvider: (_, _) async {
          recordCalls++;
          return records;
        },
      );
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'visão confirmada reabre sem consultar os quatro níveis remotos',
    () async {
      final fixture = _Fixture();
      final service = fixture.create();
      expect((await service.loadCached()).available, isFalse);
      await service.refresh();
      final before = [
        fixture.farmCalls,
        fixture.groupCalls,
        fixture.animalCalls,
        fixture.recordCalls,
      ];
      final cached = await service.loadCached();
      expect(cached.available, isTrue);
      expect(cached.entries.single.animal.name, 'Aurora');
      expect(cached.entries.single.records.single.id, 'event-1');
      expect([
        fixture.farmCalls,
        fixture.groupCalls,
        fixture.animalCalls,
        fixture.recordCalls,
      ], before);
    },
  );

  test('falha parcial não substitui snapshot íntegro', () async {
    final fixture = _Fixture();
    final service = fixture.create();
    await service.refresh();
    fixture.failGroups = true;
    expect(service.refresh(), throwsStateError);
    final cached = await service.loadCached();
    expect(cached.available, isTrue);
    expect(cached.entries.single.records.single.id, 'event-1');
  });

  test('identidade, permissão e fazenda selecionada isolam a cópia', () async {
    final fixture = _Fixture();
    final service = fixture.create();
    await service.refresh();
    fixture.session = _session(user: 'user-2');
    expect((await service.loadCached()).available, isFalse);
    fixture.session = _session(company: 'company-2');
    expect((await service.loadCached()).available, isFalse);
    fixture.session = _session(farms: ['farm-2']);
    expect((await service.loadCached()).available, isFalse);
    fixture.session = _session(canRead: false);
    expect(service.loadCached(), throwsStateError);
    fixture.session = _session();
    expect(
      (await service.loadCached(
        selectedFarm: _farm.copyWith(id: 'farm-2'),
      )).available,
      isFalse,
    );
  });

  test('troca de conta durante GET não persiste o retorno antigo', () async {
    final fixture = _Fixture();
    final service = fixture.create();
    fixture.gate = Completer<void>();
    fixture.farmStarted = Completer<void>();
    final pending = service.refresh();
    await fixture.farmStarted!.future;
    fixture.session = _session(user: 'user-2');
    fixture.gate!.complete();
    await expectLater(pending, throwsStateError);
    fixture.session = _session();
    expect((await service.loadCached()).available, isFalse);
  });

  test('leitura confirmada vazia não é confundida com cache ausente', () async {
    final fixture = _Fixture();
    final service = ReproductionOverviewSnapshotService(
      preferences: SharedPreferencesAsync(),
      sessionProvider: () async => fixture.session,
      farmsProvider: () async => [_farm],
      groupsProvider: (_) async => [],
    );
    await service.refresh();
    final cached = await service.loadCached(selectedFarm: _farm);
    expect(cached.available, isTrue);
    expect(cached.entries, isEmpty);
  });

  testWidgets('tela mostra snapshot antes do GET pendente', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = _Fixture();
    final service = fixture.create();
    await service.refresh();
    fixture.gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: ReproductionOverviewScreen(snapshotService: service)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.textContaining('Visão local aberta'), findsOneWidget);
    expect(find.text('Aurora'), findsOneWidget);
    fixture.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.text('Visão reprodutiva atualizada.'), findsOneWidget);
  });

  testWidgets('sem snapshot offline não apresenta métricas como zero', (
    tester,
  ) async {
    final fixture = _Fixture()..failGroups = true;
    final service = fixture.create();
    await tester.pumpWidget(
      MaterialApp(home: ReproductionOverviewScreen(snapshotService: service)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.textContaining('sem cópia completa'), findsOneWidget);
    expect(find.text('Fêmeas'), findsNothing);
  });
}
