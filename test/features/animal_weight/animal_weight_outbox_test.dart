import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_outbox_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/presentation/screens/animal_weight_list_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWeightsApi extends AnimalWeightEnterpriseService {
  bool online = false;
  bool supportsRetry = true;
  bool failConflict = false;
  int createCalls = 0;
  final List<AnimalWeightData> remote = [];

  @override
  Future<List<AnimalWeightData>> listWeights({required String animalId}) async {
    if (!online) throw StateError('Sem rede');
    return List.of(remote);
  }

  @override
  Future<bool> supportsIdempotentSync() async => supportsRetry;

  @override
  Future<AnimalWeightData> createWeight({
    required String animalId,
    required AnimalWeightData weight,
  }) async {
    createCalls++;
    if (failConflict) {
      throw const AtlasEnterpriseApiException(
        'Conflito de operação',
        statusCode: 409,
      );
    }
    final created = AnimalWeightData.fromRemoteMap({
      'id': 'remote-$createCalls',
      'measured_at': '2026-09-23T12:00:00Z',
      'weight': weight.weight,
      'notes': weight.notes,
      'client_operation_id': weight.clientOperationId,
    });
    remote.add(created);
    return created;
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  const farm = FarmData(
    id: 'farm-1',
    name: 'Fazenda Teste',
    city: 'Goiânia',
    state: 'GO',
    animals: 1,
    area: 10,
  );
  const group = HerdGroupData(
    name: 'Matrizes',
    category: 'Matrizes',
    capacity: 20,
    paddock: 'Pasto 1',
  );
  const animal = AnimalData(
    id: 'animal-1',
    tag: 'BR-17',
    name: 'Aurora',
    sex: 'Fêmea',
    breed: 'Nelore',
    birthDate: '2024-01-01',
    weight: 400,
    status: 'Ativo',
  );

  test('fila persiste e isola empresas', () async {
    final first = AnimalWeightOutboxService();
    const record = AnimalWeightData(
      id: 'local-1',
      date: '23/09/2026',
      weight: 430,
      notes: '',
      clientOperationId: 'operation-1',
    );
    await first.upsert(
      companyId: 'company-a',
      farmId: 'farm-1',
      animalId: 'animal-1',
      entry: const PendingAnimalWeight(record: record),
    );
    final reopened = AnimalWeightOutboxService();
    expect(
      (await reopened.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      )).single.record.weight,
      430,
    );
    expect(
      await reopened.load(
        companyId: 'company-b',
        farmId: 'farm-1',
        animalId: 'animal-1',
      ),
      isEmpty,
    );
    await reopened.upsert(
      companyId: 'company-a',
      farmId: 'farm-1',
      animalId: 'animal-1',
      entry: const PendingAnimalWeight(record: record, needsReview: true),
    );
    expect(
      (await reopened.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      )).single.needsReview,
      isTrue,
    );
    await Future.wait([
      first.upsert(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
        entry: const PendingAnimalWeight(
          record: AnimalWeightData(
            id: 'local-2',
            date: '23/09/2026',
            weight: 420,
            notes: '',
            clientOperationId: 'operation-2',
          ),
        ),
      ),
      first.upsert(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
        entry: const PendingAnimalWeight(
          record: AnimalWeightData(
            id: 'local-3',
            date: '23/09/2026',
            weight: 425,
            notes: '',
            clientOperationId: 'operation-3',
          ),
        ),
      ),
    ]);
    expect(
      (await first.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      )),
      hasLength(3),
    );
    await reopened.remove(
      companyId: 'company-a',
      farmId: 'farm-1',
      animalId: 'animal-1',
      operationId: 'operation-3',
    );
    expect(
      (await first.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      )),
      hasLength(2),
    );
  });

  test('dados locais inválidos não são apagados automaticamente', () async {
    final preferences = SharedPreferencesAsync();
    final scope = [
      'company-a',
      'farm-1',
      'animal-1',
    ].map((value) => base64Url.encode(utf8.encode(value))).join('_');
    final key = 'atlas_weight_outbox_v1_$scope';
    await preferences.setString(key, '{incompleto');
    final outbox = AnimalWeightOutboxService(preferences: preferences);
    await expectLater(
      outbox.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      ),
      throwsFormatException,
    );
    expect(await preferences.getString(key), '{incompleto');
  });

  testWidgets('GET concilia confirmação perdida sem novo POST', (tester) async {
    final api = _FakeWeightsApi()..online = true;
    final outbox = AnimalWeightOutboxService();
    const local = AnimalWeightData(
      id: 'local-4',
      date: '23/09/2026',
      weight: 450,
      notes: '',
      clientOperationId: 'operation-4',
    );
    await outbox.upsert(
      companyId: 'company-a',
      farmId: 'farm-1',
      animalId: 'animal-1',
      entry: const PendingAnimalWeight(record: local),
    );
    api.remote.add(
      AnimalWeightData.fromRemoteMap({
        'id': 'remote-existing',
        'measured_at': '2026-09-23T12:00:00Z',
        'weight': 450,
        'notes': '',
        'client_operation_id': 'operation-4',
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalWeightListScreen(
          animal: animal,
          farm: farm,
          group: group,
          companyId: 'company-a',
          weightEnterprise: api,
          weightOutbox: outbox,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.createCalls, 0);
    expect(
      await outbox.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      ),
      isEmpty,
    );
    expect(find.textContaining('aguardando confirmação'), findsNothing);
  });

  test('a conciliação exige igualdade dos dados da medição', () {
    const local = AnimalWeightData(
      id: 'local',
      date: '23/09/2026',
      weight: 450,
      notes: 'Balança conferida',
      bodyConditionScore: 3,
      source: 'curral',
      equipment: 'balança 1',
    );
    const equal = AnimalWeightData(
      id: 'remote',
      date: '23/09/2026',
      weight: 450,
      notes: 'Balança conferida',
      bodyConditionScore: 3,
      source: 'curral',
      equipment: 'balança 1',
    );
    expect(local.sameMeasurementAs(equal), isTrue);
    expect(
      local.sameMeasurementAs(
        const AnimalWeightData(
          id: 'remote',
          date: '23/09/2026',
          weight: 449,
          notes: 'Balança conferida',
          bodyConditionScore: 3,
          source: 'curral',
          equipment: 'balança 1',
        ),
      ),
      isFalse,
    );
    expect(
      local.sameMeasurementAs(
        const AnimalWeightData(
          id: 'remote',
          date: '23/09/2026',
          weight: 450,
          notes: 'Outra observação',
          bodyConditionScore: 3,
          source: 'curral',
          equipment: 'balança 1',
        ),
      ),
      isFalse,
    );
  });

  testWidgets('GET divergente preserva a fila até revisão explícita', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _FakeWeightsApi()..online = true;
    final outbox = AnimalWeightOutboxService();
    await outbox.upsert(
      companyId: 'company-a',
      farmId: 'farm-1',
      animalId: 'animal-1',
      entry: const PendingAnimalWeight(
        record: AnimalWeightData(
          id: 'local-conflict',
          date: '23/09/2026',
          weight: 450,
          notes: 'Leitura local',
          clientOperationId: 'operation-conflict',
        ),
      ),
    );
    api.remote.add(
      AnimalWeightData.fromRemoteMap({
        'id': 'remote-conflict',
        'measured_at': '2026-09-23T12:00:00Z',
        'weight': 440,
        'notes': 'Leitura remota',
        'client_operation_id': 'operation-conflict',
      }),
    );
    api.remote.add(
      AnimalWeightData.fromRemoteMap({
        'id': 'remote-older',
        'measured_at': '2026-09-22T12:00:00Z',
        'weight': 430,
        'notes': '',
        'client_operation_id': 'operation-older',
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalWeightListScreen(
          animal: animal,
          farm: farm,
          group: group,
          companyId: 'company-a',
          weightEnterprise: api,
          weightOutbox: outbox,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.createCalls, 0);
    expect(
      (await outbox.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      )).single.needsReview,
      isTrue,
    );
    expect(find.text('450 kg'), findsWidgets);
    expect(find.text('440 kg'), findsWidgets);
    final summaryBeforeReview = {
      for (final card in tester.widgetList<WeightSummaryCard>(
        find.byType(WeightSummaryCard),
      ))
        card.title: card.value,
    };
    expect(summaryBeforeReview['Peso atual'], '440 kg');
    expect(summaryBeforeReview['Menor peso'], '430 kg');
    expect(summaryBeforeReview['Maior peso'], '440 kg');
    expect(summaryBeforeReview['Última variação'], '+10 kg');
    expect(find.textContaining('não são contadas novamente'), findsOneWidget);
    await tester.tap(find.text('Revisar pesagem'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Neste dispositivo: 450 kg'), findsOneWidget);
    expect(find.textContaining('No servidor: 440 kg'), findsOneWidget);
    await tester.tap(find.text('Manter pendente'));
    await tester.pumpAndSettle();
    expect(
      await outbox.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      ),
      hasLength(1),
    );
    await tester.tap(find.text('Revisar pesagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover cópia local'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Confirmar remoção local'),
    );
    await tester.pumpAndSettle();
    expect(
      await outbox.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      ),
      isEmpty,
    );
    expect(find.text('440 kg'), findsWidgets);
    expect(find.text('450 kg'), findsNothing);
    expect(find.textContaining('não são contadas novamente'), findsNothing);
    final summaryAfterReview = {
      for (final card in tester.widgetList<WeightSummaryCard>(
        find.byType(WeightSummaryCard),
      ))
        card.title: card.value,
    };
    expect(summaryAfterReview, summaryBeforeReview);
    expect(api.createCalls, 0);
  });

  testWidgets('conflito bloqueia reenvio automático e mantém registro', (
    tester,
  ) async {
    final api = _FakeWeightsApi()
      ..online = true
      ..failConflict = true;
    final outbox = AnimalWeightOutboxService();
    await outbox.upsert(
      companyId: 'company-a',
      farmId: 'farm-1',
      animalId: 'animal-1',
      entry: const PendingAnimalWeight(
        record: AnimalWeightData(
          id: 'local-5',
          date: '23/09/2026',
          weight: 455,
          notes: '',
          clientOperationId: 'operation-5',
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalWeightListScreen(
          animal: animal,
          farm: farm,
          group: group,
          companyId: 'company-a',
          weightEnterprise: api,
          weightOutbox: outbox,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.createCalls, 1);
    expect(
      (await outbox.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      )).single.needsReview,
      isTrue,
    );
    await tester.tap(find.text('Tentar sincronizar'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.createCalls, 1);
    expect(find.textContaining('requer(em) revisão'), findsOneWidget);
  });

  testWidgets(
    'pesagem offline permanece e sincroniza uma vez com confirmação',
    (tester) async {
      final api = _FakeWeightsApi();
      final outbox = AnimalWeightOutboxService();
      await tester.pumpWidget(
        MaterialApp(
          home: AnimalWeightListScreen(
            animal: animal,
            farm: farm,
            group: group,
            companyId: 'company-a',
            weightEnterprise: api,
            weightOutbox: outbox,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova pesagem'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Peso em kg'),
        '445',
      );
      await tester.ensureVisible(find.text('Salvar pesagem'));
      await tester.tap(find.text('Salvar pesagem'));
      await tester.pumpAndSettle();

      final pending = await outbox.load(
        companyId: 'company-a',
        farmId: 'farm-1',
        animalId: 'animal-1',
      );
      expect(pending, hasLength(1));
      expect(find.textContaining('aguardando confirmação'), findsOneWidget);
      expect(api.createCalls, 0);

      api.online = true;
      api.supportsRetry = false;
      await tester.tap(find.text('Tentar sincronizar'));
      await tester.pumpAndSettle();
      expect(api.createCalls, 0);
      expect(
        await outbox.load(
          companyId: 'company-a',
          farmId: 'farm-1',
          animalId: 'animal-1',
        ),
        hasLength(1),
      );

      api.supportsRetry = true;
      await tester.tap(find.text('Tentar sincronizar'));
      await tester.pumpAndSettle();
      expect(api.createCalls, 1);
      expect(
        await outbox.load(
          companyId: 'company-a',
          farmId: 'farm-1',
          animalId: 'animal-1',
        ),
        isEmpty,
      );
      expect(find.textContaining('aguardando confirmação'), findsNothing);
    },
  );
}
