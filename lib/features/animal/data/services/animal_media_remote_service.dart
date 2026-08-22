import 'dart:convert';
import 'dart:io';

import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AnimalMediaRemoteService {
  AnimalMediaRemoteService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<Map<String, dynamic>>> list({
    required String animalId,
    required String kind,
  }) {
    return _api.requestList(
      'GET',
      '/animal-media/$animalId',
      queryParameters: {'kind': kind},
    );
  }

  Future<Map<String, dynamic>> create({
    required String animalId,
    required String kind,
    required Map<String, dynamic> metadata,
    String filePath = '',
  }) async {
    final fields = {'kind': kind, 'metadata_json': jsonEncode(metadata)};

    if (filePath.trim().isNotEmpty && FileSystemEntity.isFileSync(filePath)) {
      return _api.uploadFile(
        'POST',
        '/animal-media/$animalId',
        filePath: filePath,
        fields: fields,
      );
    }

    // FastAPI multipart permite ausência do arquivo. Para manter uma única
    // interface de criação, registros sem arquivo usam um arquivo temporário
    // somente quando necessário. Fotos sempre exigem arquivo no Flutter.
    if (kind == 'photo') {
      throw const AnimalMediaRemoteException(
        'A foto precisa apontar para um arquivo local válido antes do upload.',
      );
    }

    final externalReference = metadata['externalReference']?.toString() ?? '';
    if (externalReference.isEmpty) {
      throw const AnimalMediaRemoteException(
        'O documento precisa possuir arquivo local ou referência web.',
      );
    }

    // Documentos externos sem bytes usam o endpoint JSON dedicado.
    return _api.request(
      'POST',
      '/animal-media/$animalId/reference',
      body: {'kind': kind, 'metadata': metadata},
    );
  }

  Future<Map<String, dynamic>> updateMetadata({
    required String animalId,
    required String mediaId,
    required Map<String, dynamic> metadata,
  }) {
    return _api.request(
      'PATCH',
      '/animal-media/$animalId/$mediaId',
      body: {'metadata': metadata},
    );
  }

  Future<Map<String, dynamic>> replaceContent({
    required String animalId,
    required String mediaId,
    required String filePath,
  }) {
    return _api.uploadFile(
      'PUT',
      '/animal-media/$animalId/$mediaId/content',
      filePath: filePath,
    );
  }

  Future<void> delete({
    required String animalId,
    required String mediaId,
  }) async {
    await _api.request('DELETE', '/animal-media/$animalId/$mediaId');
  }

  Future<String> cacheContent({
    required String animalId,
    required String mediaId,
    required String originalFilename,
  }) async {
    final suffix = _safeSuffix(originalFilename);
    final directory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}atlas_media_cache',
    );
    await directory.create(recursive: true);

    final destination = File(
      '${directory.path}${Platform.pathSeparator}$mediaId$suffix',
    );

    if (await destination.exists() && await destination.length() > 0) {
      return destination.path;
    }

    final bytes = await _api.downloadBytes(
      '/animal-media/$animalId/$mediaId/content',
    );
    await destination.writeAsBytes(bytes, flush: true);
    return destination.path;
  }

  bool isAtlasCachePath(String value) {
    return value.contains(
      '${Platform.pathSeparator}atlas_media_cache${Platform.pathSeparator}',
    );
  }

  String _safeSuffix(String filename) {
    final normalized = filename.toLowerCase();
    for (final suffix in const [
      '.jpeg',
      '.jpg',
      '.png',
      '.webp',
      '.pdf',
      '.docx',
      '.doc',
      '.xlsx',
      '.xls',
      '.csv',
      '.txt',
    ]) {
      if (normalized.endsWith(suffix)) return suffix;
    }
    return '';
  }
}

class AnimalMediaRemoteException implements Exception {
  const AnimalMediaRemoteException(this.message);

  final String message;

  @override
  String toString() => message;
}
