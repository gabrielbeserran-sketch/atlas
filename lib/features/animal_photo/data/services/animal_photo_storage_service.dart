import 'dart:convert';
import 'dart:io';

import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_media_remote_service.dart';
import 'package:projeto_atlas/features/animal_photo/domain/models/animal_photo_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fotos do animal com autoridade remota.
///
/// SharedPreferences guarda somente o último snapshot confirmado e caminhos
/// de cache temporário para contingência offline.
class AnimalPhotoStorageService {
  AnimalPhotoStorageService({AnimalMediaRemoteService? remote})
    : _remote = remote ?? AnimalMediaRemoteService();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AnimalMediaRemoteService _remote;

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _key({
    required String farmName,
    required String groupName,
    required String animalId,
  }) {
    return 'atlas_animal_photos_cache_'
        '${_normalize(farmName)}_'
        '${_normalize(groupName)}_'
        '${_normalize(animalId)}';
  }

  Future<List<AnimalPhotoData>> loadPhotos({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    try {
      final remoteItems = await _remote.list(
        animalId: animalId,
        kind: 'photo',
      );

      final photos = <AnimalPhotoData>[];
      for (final item in remoteItems) {
        final metadata = Map<String, dynamic>.from(
          (item['metadata'] as Map?) ?? const <String, dynamic>{},
        );
        var reference = '';

        if (item['has_file'] == true) {
          try {
            reference = await _remote.cacheContent(
              animalId: animalId,
              mediaId: item['id']?.toString() ?? '',
              originalFilename: item['original_filename']?.toString() ?? '',
            );
          } catch (_) {
            reference = '';
          }
        }

        photos.add(
          AnimalPhotoData.fromMap({
            ...metadata,
            'id': item['id']?.toString() ?? '',
            'reference': reference,
            'createdAt':
                item['created_at']?.toString() ??
                metadata['createdAt']?.toString() ??
                '',
          }),
        );
      }

      final normalized = _ensureSinglePrimary(photos);
      normalized.sort(
        (first, second) => _parse(second.date).compareTo(_parse(first.date)),
      );
      await _saveCache(
        farmName: farmName,
        groupName: groupName,
        animalId: animalId,
        photos: normalized,
      );
      return normalized;
    } catch (_) {
      return _loadCache(
        farmName: farmName,
        groupName: groupName,
        animalId: animalId,
      );
    }
  }

  Future<void> savePhotos({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalPhotoData> photos,
  }) async {
    final desired = _ensureSinglePrimary(photos);
    final existing = await _remote.list(animalId: animalId, kind: 'photo');
    final existingIds = {
      for (final item in existing) item['id']?.toString() ?? '',
    }..remove('');

    final desiredIds = <String>{};

    for (final photo in desired) {
      final metadata = {
        'date': photo.date,
        'title': photo.title,
        'notes': photo.notes,
        'isPrimary': photo.isPrimary,
        'createdAt': photo.createdAt,
      };

      if (existingIds.contains(photo.id)) {
        desiredIds.add(photo.id);
        await _remote.updateMetadata(
          animalId: animalId,
          mediaId: photo.id,
          metadata: metadata,
        );

        if (photo.reference.trim().isNotEmpty &&
            FileSystemEntity.isFileSync(photo.reference) &&
            !_remote.isAtlasCachePath(photo.reference)) {
          await _remote.replaceContent(
            animalId: animalId,
            mediaId: photo.id,
            filePath: photo.reference,
          );
        }
        continue;
      }

      final created = await _remote.create(
        animalId: animalId,
        kind: 'photo',
        metadata: metadata,
        filePath: photo.reference,
      );
      final createdId = created['id']?.toString() ?? '';
      if (createdId.isNotEmpty) desiredIds.add(createdId);
    }

    for (final item in existing) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !desiredIds.contains(id)) {
        await _remote.delete(animalId: animalId, mediaId: id);
      }
    }

    // Só grava cache depois que todas as mutações remotas terminaram.
    final confirmed = await loadPhotos(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
    );
    await _saveCache(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
      photos: confirmed,
    );
  }

  Future<List<AnimalPhotoData>> _loadCache({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    final saved = await _preferences.getString(
      _key(farmName: farmName, groupName: groupName, animalId: animalId),
    );
    if (saved == null || saved.isEmpty) return [];

    try {
      final decoded = AtlasTextNormalizer.normalize(jsonDecode(saved)) as List<dynamic>;
      return decoded
          .map(
            (item) => AnimalPhotoData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCache({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalPhotoData> photos,
  }) {
    return _preferences.setString(
      _key(farmName: farmName, groupName: groupName, animalId: animalId),
      jsonEncode(photos.map((photo) => photo.toMap()).toList()),
    );
  }

  List<AnimalPhotoData> _ensureSinglePrimary(List<AnimalPhotoData> photos) {
    if (photos.isEmpty) return [];
    final firstPrimaryIndex = photos.indexWhere((photo) => photo.isPrimary);
    final primaryIndex = firstPrimaryIndex == -1 ? 0 : firstPrimaryIndex;

    return List<AnimalPhotoData>.generate(
      photos.length,
      (index) => photos[index].copyWith(isPrimary: index == primaryIndex),
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
