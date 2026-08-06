import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_enterprise_audit_data.dart';

class AtlasEnterpriseAuditRepository {
  AtlasEnterpriseAuditRepository._();

  static final AtlasEnterpriseAuditRepository instance =
      AtlasEnterpriseAuditRepository._();

  static const String _storageKey =
      'atlas_enterprise_24b_audit_log_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasEnterpriseAuditRecord>> loadAll() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <AtlasEnterpriseAuditRecord>[];
    }

    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) => AtlasEnterpriseAuditRecord.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasEnterpriseAuditRecord>[];
    }
  }

  Future<void> append(
    AtlasEnterpriseAuditRecord record,
  ) async {
    final values = await loadAll();
    values.add(record);

    // Append-only: não existe método público de delete/update.
    await _preferences.setString(
      _storageKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }
}
