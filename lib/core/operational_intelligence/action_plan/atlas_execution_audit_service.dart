import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_audit_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutionAuditService {
  AtlasExecutionAuditService._();

  static final AtlasExecutionAuditService instance =
      AtlasExecutionAuditService._();

  static const String _storageKey =
      'atlas_execution_audit_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasExecutionAuditEntry>> load({
    String? entityId,
    String? farmName,
  }) async {
    final all = await _loadAll();
    final normalizedFarm =
        farmName?.trim().toLowerCase();

    final filtered = all.where((entry) {
      final matchesEntity =
          entityId == null || entry.entityId == entityId;
      final matchesFarm = normalizedFarm == null ||
          normalizedFarm.isEmpty ||
          entry.farmName?.trim().toLowerCase() ==
              normalizedFarm;

      return matchesEntity && matchesFarm;
    }).toList()
      ..sort(
        (first, second) =>
            second.changedAt.compareTo(first.changedAt),
      );

    return filtered;
  }

  Future<void> record({
    required String entityType,
    required String entityId,
    required String entityTitle,
    required String fieldName,
    required Object? oldValue,
    required Object? newValue,
    required String source,
    String changedBy = 'Usuário local',
    String? farmName,
  }) async {
    final oldText = _normalize(oldValue);
    final newText = _normalize(newValue);

    if (oldText == newText) {
      return;
    }

    final now = DateTime.now();
    final all = await _loadAll();

    all.add(
      AtlasExecutionAuditEntry(
        id: 'audit_${now.microsecondsSinceEpoch}_'
            '${all.length}',
        entityType: entityType,
        entityId: entityId,
        entityTitle: entityTitle,
        fieldName: fieldName,
        oldValue: oldText,
        newValue: newText,
        changedAt: now,
        changedBy: changedBy,
        source: source,
        farmName: farmName,
      ),
    );

    await _saveAll(all);
  }

  Future<List<AtlasExecutionAuditEntry>>
      _loadAll() async {
    final encoded =
        await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasExecutionAuditEntry>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasExecutionAuditEntry.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasExecutionAuditEntry>[];
    }
  }

  Future<void> _saveAll(
    List<AtlasExecutionAuditEntry> entries,
  ) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(
        entries.map((entry) => entry.toMap()).toList(),
      ),
    );
  }

  String _normalize(Object? value) {
    if (value == null) {
      return 'Não definido';
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    final text = value.toString().trim();
    return text.isEmpty ? 'Não definido' : text;
  }
}
