import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _RemoteWeightHistory extends AnimalWeightEnterpriseService {
  @override
  Future<List<AnimalWeightData>> listWeights({required String animalId}) async {
    return const [
      AnimalWeightData(
        id: 'remote-1',
        date: '25/09/2026',
        weight: 470,
        notes: '',
        isRemote: true,
      ),
    ];
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  const record = AnimalWeightData(
    id: 'weight-1',
    date: '25/09/2026',
    weight: 460,
    notes: '',
    isRemote: true,
  );

  test('cache por IDs não cruza empresas nem fazendas', () async {
    final first = AnimalWeightStorageService(
      companyId: 'company-a',
      farmId: 'farm-1',
    );
    await first.saveWeights(
      farmName: 'Fazenda Atlas',
      groupName: 'Matrizes',
      animalId: 'animal-1',
      weights: [record],
    );
    final sameAnimalOtherCompany = AnimalWeightStorageService(
      companyId: 'company-b',
      farmId: 'farm-1',
    );
    final sameAnimalOtherFarm = AnimalWeightStorageService(
      companyId: 'company-a',
      farmId: 'farm-2',
    );
    expect(
      await sameAnimalOtherCompany.loadWeights(
        farmName: 'Fazenda Atlas',
        groupName: 'Matrizes',
        animalId: 'animal-1',
        preferRemote: false,
      ),
      isEmpty,
    );
    expect(
      await sameAnimalOtherFarm.loadWeights(
        farmName: 'Fazenda Atlas',
        groupName: 'Matrizes',
        animalId: 'animal-1',
        preferRemote: false,
      ),
      isEmpty,
    );
    final sameAnimalRenamedLot = await first.loadWeights(
      farmName: 'Fazenda Atlas Renomeada',
      groupName: 'Novilhas',
      animalId: 'animal-1',
      preferRemote: false,
    );
    expect(sameAnimalRenamedLot.single.weight, 460);
    expect(
      await first.loadWeights(
        farmName: 'Outra fazenda',
        groupName: 'Matrizes',
        animalId: 'animal-1',
        farmId: 'farm-2',
        preferRemote: false,
      ),
      isEmpty,
    );
    expect(
      await first.loadWeights(
        farmName: 'Fazenda sem ID',
        groupName: 'Matrizes',
        animalId: 'animal-1',
        farmId: '',
        preferRemote: false,
      ),
      isEmpty,
    );
  });

  test(
    'cache antigo sem proprietário não é atribuído automaticamente',
    () async {
      final preferences = SharedPreferencesAsync();
      const oldKey = 'atlas_animal_weights_fazenda_atlas_matrizes_animal_1';
      final oldValue = jsonEncode([record.toMap()]);
      await preferences.setString(oldKey, oldValue);
      final scoped = AnimalWeightStorageService(
        preferences: preferences,
        companyId: 'company-a',
        farmId: 'farm-1',
      );
      expect(
        await scoped.loadWeights(
          farmName: 'Fazenda Atlas',
          groupName: 'Matrizes',
          animalId: 'animal-1',
          preferRemote: false,
        ),
        isEmpty,
      );
      expect(await preferences.getString(oldKey), oldValue);
    },
  );

  test('sem empresa e fazenda não grava cache compartilhado', () async {
    final preferences = SharedPreferencesAsync();
    final unscoped = AnimalWeightStorageService(
      preferences: preferences,
      companyId: '',
      farmId: '',
    );
    await unscoped.saveWeights(
      farmName: 'Fazenda Atlas',
      groupName: 'Matrizes',
      animalId: 'animal-1',
      weights: [record],
    );
    expect(await preferences.getKeys(), isEmpty);
  });

  test('leitura confirmada do servidor repovoa o cache isolado', () async {
    final storage = AnimalWeightStorageService(
      companyId: 'company-a',
      farmId: 'farm-1',
      enterprise: _RemoteWeightHistory(),
    );
    final remote = await storage.loadWeights(
      farmName: 'Fazenda Atlas',
      groupName: 'Matrizes',
      animalId: 'animal-1',
    );
    expect(remote.single.weight, 470);
    final offline = await storage.loadWeights(
      farmName: 'Fazenda Atlas',
      groupName: 'Novilhas',
      animalId: 'animal-1',
      preferRemote: false,
    );
    expect(offline.single.weight, 470);
  });
}
