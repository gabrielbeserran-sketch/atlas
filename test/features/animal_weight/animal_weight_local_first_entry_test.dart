import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/presentation/screens/animal_weight_list_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _RecordingStorage extends AnimalWeightStorageService {
  final List<bool> remotePreferences = [];

  @override
  Future<List<AnimalWeightData>> loadWeights({
    required String farmName,
    required String groupName,
    required String animalId,
    bool preferRemote = true,
  }) async {
    remotePreferences.add(preferRemote);
    return [];
  }

  @override
  Future<void> saveWeights({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalWeightData> weights,
  }) async {}
}

class _RecordingEnterprise extends AnimalWeightEnterpriseService {
  int listCalls = 0;

  @override
  Future<List<AnimalWeightData>> listWeights({required String animalId}) async {
    listCalls++;
    return [];
  }
}

void main() {
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

  testWidgets('atalho abre formulário antes de ler o servidor', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final storage = _RecordingStorage();
    final enterprise = _RecordingEnterprise();
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalWeightListScreen(
          animal: animal,
          farm: farm,
          group: group,
          autoOpenCreate: true,
          weightStorage: storage,
          weightEnterprise: enterprise,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Registrar pesagem'), findsOneWidget);
    expect(storage.remotePreferences, [false]);
    expect(enterprise.listCalls, 0);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(enterprise.listCalls, 1);
  });
}
