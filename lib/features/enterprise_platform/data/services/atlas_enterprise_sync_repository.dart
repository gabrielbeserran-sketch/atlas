import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_enterprise_sync_data.dart';

class AtlasEnterpriseSyncRepository {
  AtlasEnterpriseSyncRepository._();

  static final AtlasEnterpriseSyncRepository instance =
      AtlasEnterpriseSyncRepository._();

  static const String _queueKey = 'atlas_enterprise_24c_sync_queue_v1';
  static const String _conflictsKey = 'atlas_enterprise_24c_sync_conflicts_v1';
  static const String _checkpointsKey =
      'atlas_enterprise_24c_sync_checkpoints_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasEnterpriseSyncOperation>> loadQueue() async {
    return _decodeList(_queueKey, AtlasEnterpriseSyncOperation.fromMap);
  }

  Future<void> saveOperation(AtlasEnterpriseSyncOperation operation) async {
    final values = await loadQueue();
    final index = values.indexWhere(
      (item) => item.operationId == operation.operationId,
    );

    if (index == -1) {
      final duplicateIdempotency = values.any(
        (item) =>
            item.idempotencyKey == operation.idempotencyKey &&
            item.status != AtlasEnterpriseSyncStatus.error,
      );
      if (duplicateIdempotency) return;
      values.add(operation);
    } else {
      values[index] = operation;
    }

    await _preferences.setString(
      _queueKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<AtlasEnterpriseSyncConflict>> loadConflicts() async {
    return _decodeList(_conflictsKey, AtlasEnterpriseSyncConflict.fromMap);
  }

  Future<void> saveConflict(AtlasEnterpriseSyncConflict conflict) async {
    final values = await loadConflicts();
    final index = values.indexWhere((item) => item.id == conflict.id);
    if (index == -1) {
      values.add(conflict);
    } else {
      values[index] = conflict;
    }

    await _preferences.setString(
      _conflictsKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<AtlasEnterpriseSyncCheckpoint>> loadCheckpoints() async {
    return _decodeList(_checkpointsKey, AtlasEnterpriseSyncCheckpoint.fromMap);
  }

  Future<AtlasEnterpriseSyncCheckpoint> checkpoint(String companyId) async {
    final values = await loadCheckpoints();
    for (final item in values) {
      if (item.companyId == companyId) return item;
    }
    return AtlasEnterpriseSyncCheckpoint(
      companyId: companyId,
      cursor: '',
      lastPulledAt: null,
      lastPushedAt: null,
    );
  }

  Future<void> saveCheckpoint(AtlasEnterpriseSyncCheckpoint checkpoint) async {
    final values = await loadCheckpoints();
    final index = values.indexWhere(
      (item) => item.companyId == checkpoint.companyId,
    );
    if (index == -1) {
      values.add(checkpoint);
    } else {
      values[index] = checkpoint;
    }

    await _preferences.setString(
      _checkpointsKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) return <T>[];

    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }
}
