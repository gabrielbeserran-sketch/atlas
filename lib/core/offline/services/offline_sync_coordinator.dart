import 'dart:io';

import '../../network/atlas_http_client.dart';
import '../models/offline_operation.dart';
import '../models/offline_sync_models.dart';
import 'offline_repository.dart';

typedef OfflineSyncProgress =
    void Function(String phase, int completed, int total);

class OfflineSyncCoordinator {
  OfflineSyncCoordinator({
    AtlasHttpClient? client,
    OfflineRepository? repository,
  }) : _client = client ?? AtlasHttpClient(),
       _repository = repository ?? OfflineRepository();

  final AtlasHttpClient _client;
  final OfflineRepository _repository;

  static Map<String, Map<String, dynamic>> validatedBatchResults(
    List<OfflineOperation> operations,
    List<Map<String, dynamic>> results,
  ) {
    final expected = operations.map((item) => item.id).toSet();
    if (expected.length != operations.length ||
        results.length != expected.length) {
      throw StateError(
        'Resposta de sincronização incompleta; fila preservada.',
      );
    }
    final byId = <String, Map<String, dynamic>>{};
    for (final result in results) {
      final id = result['operation_id']?.toString() ?? '';
      if (!expected.contains(id) || byId.containsKey(id)) {
        throw StateError(
          'Resposta de sincronização inconsistente; fila preservada.',
        );
      }
      byId[id] = result;
    }
    return byId;
  }

  static bool isPermanentRejection(Map<String, dynamic> result) =>
      result['retryable'] == false;

  Future<String> registerDevice({required String deviceKey}) async {
    final response = await _client.send(
      'POST',
      '/offline/devices/register',
      body: <String, dynamic>{
        'device_key': deviceKey,
        'name': Platform.localHostname,
        'platform': Platform.operatingSystem,
        'app_version': 'flutter',
      },
    );
    return response.asMap()['id']?.toString() ?? deviceKey;
  }

  Future<OfflineServerStatus> serverStatus() async {
    final response = await _client.send('GET', '/offline/status');
    return OfflineServerStatus.fromMap(response.asMap());
  }

  Future<List<Map<String, dynamic>>> fetchRemoteConflicts() async {
    final response = await _client.send(
      'GET',
      '/offline/conflicts',
      queryParameters: const <String, String>{'status': 'open'},
    );
    return response.asMapList();
  }

  Future<OfflineSyncReport> synchronize({
    required String companyId,
    required String tenantId,
    required String deviceId,
    required bool Function() isScopeCurrent,
    String? farmId,
    OfflineSyncProgress? onProgress,
  }) async {
    if (companyId.trim().isEmpty || tenantId.trim().isEmpty) {
      throw StateError(
        'Sincronização bloqueada: empresa e tenant são obrigatórios.',
      );
    }
    if (deviceId.trim().isEmpty) {
      throw StateError(
        'Sincronização bloqueada: dispositivo não identificado.',
      );
    }

    void ensureScope() {
      if (!isScopeCurrent()) {
        throw StateError(
          'A conta ou fazenda mudou durante a sincronização; '
          'a fila permanece disponível para nova tentativa.',
        );
      }
    }

    final startedAt = DateTime.now();
    var pushed = 0;
    var conflicts = 0;
    var rejected = 0;
    var pulled = 0;

    ensureScope();
    onProgress?.call('Preparando fila', 0, 1);
    final operations = await _repository.pending(
      companyId: companyId,
      farmId: farmId,
      limit: 200,
    );
    ensureScope();
    if (operations.any(
      (item) =>
          item.companyId != companyId ||
          item.tenantId != tenantId ||
          (farmId != null && item.farmId != null && item.farmId != farmId),
    )) {
      throw StateError('Fila de sincronização com escopo inconsistente.');
    }

    if (operations.isNotEmpty) {
      ensureScope();
      onProgress?.call('Enviando alterações', 0, operations.length);
      ensureScope();
      final response = await _client.send(
        'POST',
        '/offline/push-batch',
        body: <String, dynamic>{
          'operations': operations.map((item) => item.toApi()).toList(),
          'stop_on_conflict': false,
        },
      );
      ensureScope();
      final data = response.asMap();
      final results = (data['results'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      final resultsById = validatedBatchResults(operations, results);

      for (var index = 0; index < operations.length; index++) {
        ensureScope();
        final operation = operations[index];
        final item = resultsById[operation.id]!;
        if (item['accepted'] == true) {
          await _repository.markAccepted(operation.id);
          pushed++;
        } else if (item['conflict'] == true) {
          await _repository.saveConflict(
            operation: operation,
            remoteVersion: (item['remote_version'] as num?)?.toInt() ?? 0,
            remotePayload: Map<String, dynamic>.from(
              item['remote_payload'] as Map? ?? const <String, dynamic>{},
            ),
          );
          conflicts++;
        } else {
          final permanent = isPermanentRejection(item);
          await _repository.markFailed(
            operation.id,
            item['error']?.toString() ?? 'Falha de sincronização.',
            permanent: permanent,
            currentAttempts: operation.attempts,
          );
          rejected++;
        }
        onProgress?.call('Enviando alterações', index + 1, operations.length);
      }
    }

    var cursor = await _repository.getCursor(
      companyId: companyId,
      farmId: farmId,
    );
    ensureScope();
    var hasMore = false;
    do {
      ensureScope();
      onProgress?.call('Recebendo atualizações', pulled, pulled + 1);
      ensureScope();
      final response = await _client.send(
        'GET',
        '/offline/pull-page',
        queryParameters: <String, String>{
          'cursor': '$cursor',
          'limit': '250',
          if (farmId != null && farmId.isNotEmpty) 'farm_id': farmId,
        },
      );
      ensureScope();
      final data = response.asMap();
      final changes = (data['changes'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      for (final change in changes) {
        ensureScope();
        await _repository.applyChange(
          companyId: companyId,
          tenantId: tenantId,
          farmId: farmId,
          change: change,
        );
        pulled++;
      }
      cursor = (data['next_cursor'] as num?)?.toInt() ?? cursor;
      ensureScope();
      await _repository.setCursor(
        companyId: companyId,
        farmId: farmId,
        value: cursor,
      );
      hasMore = data['has_more'] == true;
    } while (hasMore);

    ensureScope();
    final remoteConflicts = await fetchRemoteConflicts();
    ensureScope();
    await _repository.importRemoteConflicts(
      companyId: companyId,
      tenantId: tenantId,
      conflicts: remoteConflicts,
    );
    ensureScope();
    await _repository.purgeAccepted();

    return OfflineSyncReport(
      pushed: pushed,
      conflicts: conflicts,
      rejected: rejected,
      pulled: pulled,
      nextCursor: cursor,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> resolveConflict({
    required OfflineConflict conflict,
    required String resolution,
    Map<String, dynamic>? mergedPayload,
    String note = '',
  }) async {
    final serverId = conflict.serverConflictId;
    if (serverId == null || serverId.isEmpty) {
      throw const AtlasHttpException(
        'O conflito ainda não possui identificador do servidor. Sincronize novamente.',
        code: 'missing_server_conflict_id',
      );
    }
    final response = await _client.send(
      'POST',
      '/offline/conflicts/$serverId/resolve',
      body: <String, dynamic>{
        'resolution': resolution,
        if (mergedPayload != null) 'merged_payload': mergedPayload,
        'note': note,
      },
    );
    await _repository.markConflictResolved(
      id: conflict.id,
      resolution: resolution,
    );
    return response.asMap();
  }

  Future<void> sendDiagnostics({
    required String deviceId,
    required OfflineQueueStats stats,
  }) async {
    await _client.send(
      'POST',
      '/offline/diagnostics',
      body: <String, dynamic>{
        'device_id': deviceId,
        'queue_size': stats.waiting,
        'failed_operations': stats.failed,
        'local_database_bytes': await _repository.databaseSizeBytes(),
        'free_storage_bytes': 0,
        'clock_offset_seconds': 0,
        'payload': <String, dynamic>{
          'platform': Platform.operatingSystem,
          'conflicts': stats.conflicts,
        },
      },
    );
  }
}
