import 'dart:convert';

import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasFarmAuditHistoryService {
  AtlasFarmAuditHistoryService._();

  static final AtlasFarmAuditHistoryService instance =
      AtlasFarmAuditHistoryService._();

  static const String _storageKey =
      'atlas_farm_audit_history_v1';

  Future<List<AtlasFarmAudit>> loadAll() async {
    final preferences =
        await SharedPreferences.getInstance();

    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return <AtlasFarmAudit>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <AtlasFarmAudit>[];
      }

      final audits = decoded
          .whereType<Map>()
          .map(
            (item) => AtlasFarmAudit.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      audits.sort(
        (first, second) =>
            second.generatedAt.compareTo(first.generatedAt),
      );

      return audits;
    } catch (_) {
      return <AtlasFarmAudit>[];
    }
  }

  Future<List<AtlasFarmAudit>> byFarmId(
    String farmId,
  ) async {
    final all = await loadAll();

    return all
        .where((item) => item.farmId == farmId)
        .toList();
  }

  Future<void> save(AtlasFarmAudit audit) async {
    final preferences =
        await SharedPreferences.getInstance();

    final current = await loadAll();

    current.removeWhere((item) => item.id == audit.id);
    current.insert(0, audit);

    final limited = current.take(100).toList();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        limited.map((item) => item.toJson()).toList(),
      ),
    );
  }

  Future<void> delete(String auditId) async {
    final preferences =
        await SharedPreferences.getInstance();

    final current = await loadAll();

    current.removeWhere((item) => item.id == auditId);

    await preferences.setString(
      _storageKey,
      jsonEncode(
        current.map((item) => item.toJson()).toList(),
      ),
    );
  }
}
