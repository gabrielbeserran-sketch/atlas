import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/financial_document_remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mantém cópias locais dos comprovantes até o servidor confirmar o anexo.
class FinancialOfflinePhotoQueue {
  FinancialOfflinePhotoQueue({
    SharedPreferencesAsync? preferences,
    FinancialDocumentRemoteService? documents,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _documents = documents ?? FinancialDocumentRemoteService();

  final SharedPreferencesAsync _preferences;
  final FinancialDocumentRemoteService _documents;

  String _key(String farmName) =>
      'atlas_finance_photo_queue_${farmName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

  /// Copia a foto para o armazenamento interno e a associa ao id local.
  Future<String> stage({
    required String farmName,
    required String entryId,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Foto fiscal não localizada neste dispositivo.');
    }
    final directory = await getApplicationDocumentsDirectory();
    final targetDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}atlas_finance_pending',
    );
    await targetDirectory.create(recursive: true);
    final suffix = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final target = File(
      '${targetDirectory.path}${Platform.pathSeparator}$entryId$suffix',
    );
    await source.copy(target.path);
    final queued = await _read(farmName);
    queued[entryId] = _QueuedPhoto(path: target.path);
    await _write(farmName, queued);
    return target.path;
  }

  /// Registra o id remoto depois que o lançamento pendente foi confirmado.
  Future<void> markRemoteEntry({
    required String farmName,
    required String localEntryId,
    required String remoteEntryId,
  }) async {
    final queued = await _read(farmName);
    final item = queued[localEntryId];
    if (item == null || remoteEntryId.trim().isEmpty) return;
    queued[localEntryId] = item.copyWith(remoteEntryId: remoteEntryId.trim());
    await _write(farmName, queued);
  }

  /// Faz upload apenas de lançamentos já confirmados. Em erro, preserva tudo.
  Future<int> syncReady(String farmName) async {
    final queued = await _read(farmName);
    var uploaded = 0;
    for (final entry in Map<String, _QueuedPhoto>.from(queued).entries) {
      final item = entry.value;
      if (item.remoteEntryId.isEmpty) continue;
      final file = File(item.path);
      if (!await file.exists()) continue;
      try {
        await _documents.upload(
          entryId: item.remoteEntryId,
          filePath: item.path,
        );
        await file.delete();
        queued.remove(entry.key);
        uploaded++;
      } catch (_) {
        // Mantém arquivo e vínculo para uma próxima sincronização.
      }
    }
    await _write(farmName, queued);
    return uploaded;
  }

  Future<int> pendingCount(String farmName) async =>
      (await _read(farmName)).length;

  /// Informa se um lançamento específico ainda possui comprovante preservado.
  Future<bool> hasPendingForEntry({
    required String farmName,
    required String entryId,
  }) async => (await _read(farmName)).containsKey(entryId);

  Future<Map<String, _QueuedPhoto>> _read(String farmName) async {
    final raw = await _preferences.getString(_key(farmName));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return decoded.map(
        (key, value) => MapEntry(
          key,
          _QueuedPhoto.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(String farmName, Map<String, _QueuedPhoto> queue) =>
      _preferences.setString(
        _key(farmName),
        jsonEncode(queue.map((key, item) => MapEntry(key, item.toJson()))),
      );
}

class _QueuedPhoto {
  const _QueuedPhoto({required this.path, this.remoteEntryId = ''});

  factory _QueuedPhoto.fromJson(Map<String, dynamic> json) => _QueuedPhoto(
    path: json['path']?.toString() ?? '',
    remoteEntryId: json['remote_entry_id']?.toString() ?? '',
  );

  final String path;
  final String remoteEntryId;

  _QueuedPhoto copyWith({String? remoteEntryId}) => _QueuedPhoto(
    path: path,
    remoteEntryId: remoteEntryId ?? this.remoteEntryId,
  );

  Map<String, String> toJson() => {
    'path': path,
    'remote_entry_id': remoteEntryId,
  };
}
