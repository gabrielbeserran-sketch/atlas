import 'dart:convert';

import 'package:projeto_atlas/features/animal_document/domain/models/animal_document_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalDocumentStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _createStorageKey({
    required String farmName,
    required String groupName,
    required String animalId,
  }) {
    final normalizedFarm = _normalize(farmName);
    final normalizedGroup = _normalize(groupName);
    final normalizedAnimal = _normalize(animalId);

    return 'atlas_animal_documents_'
        '${normalizedFarm}_'
        '${normalizedGroup}_'
        '$normalizedAnimal';
  }

  Future<List<AnimalDocumentData>> loadDocuments({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
    );

    final savedData = await _preferences.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;

      return decodedData
          .map(
            (item) => AnimalDocumentData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDocuments({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalDocumentData> documents,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
    );

    final encodedData = jsonEncode(
      documents.map((document) => document.toMap()).toList(),
    );

    await _preferences.setString(storageKey, encodedData);
  }
}
