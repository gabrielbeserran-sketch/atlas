import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

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
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
    );

    final savedData = await _preferences.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return <AnimalData>[];
    }

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
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
    );

    final previousAnimals = await loadAnimals(
      farmName: farmName,
      groupName: groupName,
    );

    final encodedData = jsonEncode(
      animals.map((animal) => animal.toMap()).toList(),
    );

    await _preferences.setString(storageKey, encodedData);

    await _publishChangeEvents(
      farmName: farmName,
      groupName: groupName,
      previousAnimals: previousAnimals,
      currentAnimals: animals,
    );
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
