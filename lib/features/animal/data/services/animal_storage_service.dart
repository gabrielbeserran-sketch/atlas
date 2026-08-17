import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local de animais com leitura remote-first.
///
/// A API pecuária é a autoridade quando conectada. O armazenamento local
/// guarda apenas o último snapshot confirmado para contingência offline.
class AnimalStorageService {
  AnimalStorageService({
    AnimalEnterpriseService? enterprise,
    AtlasEnterpriseApiClient? api,
  }) : _enterprise = enterprise ?? AnimalEnterpriseService(),
       _api = api ?? AtlasEnterpriseApiClient.instance;

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AnimalEnterpriseService _enterprise;
  final AtlasEnterpriseApiClient _api;

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _createStorageKey({
    required String farmName,
    required String groupName,
  }) {
    final normalizedFarm = _normalize(farmName);
    final normalizedGroup = _normalize(groupName);
    return 'atlas_animals_${normalizedFarm}_$normalizedGroup';
  }

  Future<List<AnimalData>> loadAnimals({
    required String farmName,
    required String groupName,
  }) async {
    final remoteContext = await _resolveRemoteContext(
      farmName: farmName,
      groupName: groupName,
    );
    if (remoteContext != null) {
      try {
        final remote = await _enterprise.listAnimals(
          farmId: remoteContext.farmId,
          lotId: remoteContext.lotId,
        );
        await _saveCache(
          farmName: farmName,
          groupName: groupName,
          animals: remote,
        );
        return remote;
      } on AtlasEnterpriseApiException {
        // Usa abaixo apenas o último snapshot remoto confirmado.
      } catch (_) {
        // Falha de rede/parsing mantém a contingência offline disponível.
      }
    }

    return _loadLocal(farmName: farmName, groupName: groupName);
  }

  Future<List<AnimalData>> _loadLocal({
    required String farmName,
    required String groupName,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
    );
    final savedData = await _preferences.getString(storageKey);
    if (savedData == null || savedData.isEmpty) return <AnimalData>[];
    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;
      return decodedData
          .map(
            (item) =>
                AnimalData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return <AnimalData>[];
    }
  }

  Future<void> saveAnimals({
    required String farmName,
    required String groupName,
    required List<AnimalData> animals,
  }) async {
    final previousAnimals = await _loadLocal(
      farmName: farmName,
      groupName: groupName,
    );
    await _saveCache(
      farmName: farmName,
      groupName: groupName,
      animals: animals,
    );
    await _publishChangeEvents(
      farmName: farmName,
      groupName: groupName,
      previousAnimals: previousAnimals,
      currentAnimals: animals,
    );
  }

  Future<void> _saveCache({
    required String farmName,
    required String groupName,
    required List<AnimalData> animals,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
    );
    await _preferences.setString(
      storageKey,
      jsonEncode(animals.map((animal) => animal.toMap()).toList()),
    );
  }

  Future<_AnimalRemoteContext?> _resolveRemoteContext({
    required String farmName,
    required String groupName,
  }) async {
    final normalizedFarm = farmName.trim().toLowerCase();
    final normalizedGroup = groupName.trim().toLowerCase();
    if (normalizedFarm.isEmpty || normalizedGroup.isEmpty) return null;
    try {
      final farms = await _api.requestList('GET', '/farms');
      String farmId = '';
      for (final farm in farms) {
        if ((farm['name']?.toString().trim().toLowerCase() ?? '') ==
            normalizedFarm) {
          farmId = farm['id']?.toString().trim() ?? '';
          break;
        }
      }
      if (farmId.isEmpty) return null;
      final lots = await _api.requestList(
        'GET',
        '/livestock/lots',
        queryParameters: {'farm_id': farmId, 'active_only': 'true'},
      );
      for (final lot in lots) {
        if ((lot['name']?.toString().trim().toLowerCase() ?? '') ==
            normalizedGroup) {
          final lotId = lot['id']?.toString().trim() ?? '';
          if (lotId.isNotEmpty) {
            return _AnimalRemoteContext(farmId: farmId, lotId: lotId);
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> clearAnimals({
    required String farmName,
    required String groupName,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
    );

    final previousAnimals = await loadAnimals(
      farmName: farmName,
      groupName: groupName,
    );

    await _preferences.remove(storageKey);

    if (previousAnimals.isEmpty) {
      return;
    }

    final events = previousAnimals
        .map(
          (animal) => _createAnimalEvent(
            type: AtlasEventType.animalDeleted,
            farmName: farmName,
            groupName: groupName,
            animal: animal,
            title: 'Animal excluído',
            description: '${animal.displayName} foi removido do rebanho.',
          ),
        )
        .toList();

    await AtlasEventBus.instance.publishAll(events);
  }

  Future<void> _publishChangeEvents({
    required String farmName,
    required String groupName,
    required List<AnimalData> previousAnimals,
    required List<AnimalData> currentAnimals,
  }) async {
    final previousById = <String, AnimalData>{
      for (final animal in previousAnimals) animal.id: animal,
    };

    final currentById = <String, AnimalData>{
      for (final animal in currentAnimals) animal.id: animal,
    };

    final events = <AtlasEvent>[];

    for (final animal in currentAnimals) {
      final previousAnimal = previousById[animal.id];

      if (previousAnimal == null) {
        events.add(
          _createAnimalEvent(
            type: AtlasEventType.animalCreated,
            farmName: farmName,
            groupName: groupName,
            animal: animal,
            title: 'Animal cadastrado',
            description: '${animal.displayName} foi adicionado ao rebanho.',
          ),
        );
        continue;
      }

      if (!_animalsAreEqual(previousAnimal, animal)) {
        events.add(
          _createAnimalEvent(
            type: AtlasEventType.animalUpdated,
            farmName: farmName,
            groupName: groupName,
            animal: animal,
            title: 'Animal atualizado',
            description: 'Os dados de ${animal.displayName} foram atualizados.',
          ),
        );
      }
    }

    for (final animal in previousAnimals) {
      if (!currentById.containsKey(animal.id)) {
        events.add(
          _createAnimalEvent(
            type: AtlasEventType.animalDeleted,
            farmName: farmName,
            groupName: groupName,
            animal: animal,
            title: 'Animal excluído',
            description: '${animal.displayName} foi removido do rebanho.',
          ),
        );
      }
    }

    if (events.isEmpty) {
      return;
    }

    await AtlasEventBus.instance.publishAll(events);
  }

  bool _animalsAreEqual(AnimalData first, AnimalData second) {
    return jsonEncode(first.toMap()) == jsonEncode(second.toMap());
  }

  AtlasEvent _createAnimalEvent({
    required AtlasEventType type,
    required String farmName,
    required String groupName,
    required AnimalData animal,
    required String title,
    required String description,
  }) {
    final now = DateTime.now();

    return AtlasEvent(
      id: 'animal_${animal.id}_${now.microsecondsSinceEpoch}',
      type: type,
      sourceModule: 'animal',
      title: title,
      description: description,
      occurredAt: now,
      priority: AtlasEventPriority.normal,
      farmName: farmName,
      entityId: animal.id,
      entityType: 'animal',
      payload: <String, dynamic>{
        'groupName': groupName,
        'animalId': animal.id,
        'tag': animal.tag,
        'name': animal.name,
        'displayName': animal.displayName,
        'sex': animal.sex,
        'breed': animal.breed,
        'category': animal.category,
        'status': animal.status,
        'weight': animal.weight,
        'animal': animal.toMap(),
      },
      tags: <String>[
        'animal',
        type.name,
        _normalize(farmName),
        _normalize(groupName),
      ],
    );
  }
}


class _AnimalRemoteContext {
  const _AnimalRemoteContext({required this.farmId, required this.lotId});
  final String farmId;
  final String lotId;
}
