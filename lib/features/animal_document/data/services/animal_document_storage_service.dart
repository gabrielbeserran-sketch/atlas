import 'dart:convert';
import 'dart:io';

import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_media_remote_service.dart';
import 'package:projeto_atlas/features/animal_document/domain/models/animal_document_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Documentos do animal com backend como única autoridade.
///
/// O cache local existe apenas para leitura contingencial sem rede.
class AnimalDocumentStorageService {
  AnimalDocumentStorageService({AnimalMediaRemoteService? remote})
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
    return 'atlas_animal_documents_cache_'
        '${_normalize(farmName)}_'
        '${_normalize(groupName)}_'
        '${_normalize(animalId)}';
  }

  Future<List<AnimalDocumentData>> loadDocuments({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    try {
      final remoteItems = await _remote.list(
        animalId: animalId,
        kind: 'document',
      );

      final documents = <AnimalDocumentData>[];
      for (final item in remoteItems) {
        final metadata = Map<String, dynamic>.from(
          (item['metadata'] as Map?) ?? const <String, dynamic>{},
        );

        var reference = metadata['externalReference']?.toString() ?? '';
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

        documents.add(
          AnimalDocumentData.fromMap({
            ...metadata,
            'id': item['id']?.toString() ?? '',
            'reference': reference,
            'createdAt':
                item['created_at']?.toString() ??
                metadata['createdAt']?.toString(),
            'updatedAt':
                item['updated_at']?.toString() ??
                metadata['updatedAt']?.toString(),
          }),
        );
      }

      await _saveCache(
        farmName: farmName,
        groupName: groupName,
        animalId: animalId,
        documents: documents,
      );
      return documents;
    } catch (_) {
      return _loadCache(
        farmName: farmName,
        groupName: groupName,
        animalId: animalId,
      );
    }
  }

  Future<void> saveDocuments({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalDocumentData> documents,
  }) async {
    final existing = await _remote.list(
      animalId: animalId,
      kind: 'document',
    );
    final existingIds = {
      for (final item in existing) item['id']?.toString() ?? '',
    }..remove('');

    final desiredIds = <String>{};

    for (final document in documents) {
      final localReference = document.reference.trim();
      final isLocalFile =
          localReference.isNotEmpty && FileSystemEntity.isFileSync(localReference);
      final isExternalUrl = Uri.tryParse(localReference)?.hasScheme == true &&
          (localReference.startsWith('http://') ||
              localReference.startsWith('https://'));

      final metadata = {
        'type': document.type,
        'category': document.category,
        'title': document.title,
        'date': document.date,
        'expirationDate': document.expirationDate,
        'issuer': document.issuer,
        'notes': document.notes,
        'isFavorite': document.isFavorite,
        'createdAt': document.createdAt,
        'updatedAt': document.updatedAt,
        if (isExternalUrl) 'externalReference': localReference,
      };

      if (existingIds.contains(document.id)) {
        desiredIds.add(document.id);
        await _remote.updateMetadata(
          animalId: animalId,
          mediaId: document.id,
          metadata: metadata,
        );

        if (isLocalFile && !_remote.isAtlasCachePath(localReference)) {
          await _remote.replaceContent(
            animalId: animalId,
            mediaId: document.id,
            filePath: localReference,
          );
        }
        continue;
      }

      final created = await _remote.create(
        animalId: animalId,
        kind: 'document',
        metadata: metadata,
        filePath: isLocalFile ? localReference : '',
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

    final confirmed = await loadDocuments(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
    );
    await _saveCache(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
      documents: confirmed,
    );
  }

  Future<List<AnimalDocumentData>> _loadCache({
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
            (item) => AnimalDocumentData.fromMap(
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
    required List<AnimalDocumentData> documents,
  }) {
    return _preferences.setString(
      _key(farmName: farmName, groupName: groupName, animalId: animalId),
      jsonEncode(documents.map((item) => item.toMap()).toList()),
    );
  }
}
