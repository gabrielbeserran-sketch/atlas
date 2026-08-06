import 'dart:convert';

import 'package:projeto_atlas/features/animal_photo/domain/models/animal_photo_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalPhotoStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _key({
    required String farmName,
    required String groupName,
    required String animalId,
  }) {
    return 'atlas_animal_photos_'
        '${_normalize(farmName)}_'
        '${_normalize(groupName)}_'
        '${_normalize(animalId)}';
  }

  Future<List<AnimalPhotoData>> loadPhotos({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    final saved = await _preferences.getString(
      _key(
        farmName: farmName,
        groupName: groupName,
        animalId: animalId,
      ),
    );

    if (saved == null || saved.isEmpty) return [];

    try {
      final decoded = jsonDecode(saved) as List<dynamic>;
      final photos = decoded
          .map(
            (item) => AnimalPhotoData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      photos.sort(
        (first, second) =>
            _parse(second.date).compareTo(_parse(first.date)),
      );

      return photos;
    } catch (_) {
      return [];
    }
  }

  Future<void> savePhotos({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalPhotoData> photos,
  }) async {
    final normalized = _ensureSinglePrimary(photos);
    final encoded = jsonEncode(
      normalized.map((photo) => photo.toMap()).toList(),
    );

    await _preferences.setString(
      _key(
        farmName: farmName,
        groupName: groupName,
        animalId: animalId,
      ),
      encoded,
    );
  }

  List<AnimalPhotoData> _ensureSinglePrimary(
    List<AnimalPhotoData> photos,
  ) {
    if (photos.isEmpty) return [];

    final firstPrimaryIndex = photos.indexWhere(
      (photo) => photo.isPrimary,
    );

    final primaryIndex =
        firstPrimaryIndex == -1 ? 0 : firstPrimaryIndex;

    return List<AnimalPhotoData>.generate(
      photos.length,
      (index) => photos[index].copyWith(
        isPrimary: index == primaryIndex,
      ),
    );
  }

  DateTime _parse(String value) {
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;

    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime(1900);
  }
}
