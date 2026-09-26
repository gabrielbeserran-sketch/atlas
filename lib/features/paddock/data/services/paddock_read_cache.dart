import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_field_paddock_snapshot.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';

/// Cache de leitura confirmado; não substitui a autoridade do backend para CRUD.
class PaddockReadCache {
  PaddockReadCache({SharedPreferencesAsync? preferences})
    : _prefs = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _prefs;
  String _key(AtlasRemoteFarm farm) {
    if ([farm.tenantId, farm.companyId, farm.id].any((s) => s.trim().isEmpty)) {
      throw ArgumentError('Escopo incompleto');
    }
    return 'atlas_paddocks_read_v1_${base64Url.encode(utf8.encode(jsonEncode([farm.tenantId, farm.companyId, farm.id])))}';
  }

  Future<void> save(
    AtlasRemoteFarm farm,
    List<PaddockData> paddocks,
    DateTime at,
  ) async {
    await _prefs.setString(
      _key(farm),
      jsonEncode({
        'tenant': farm.tenantId,
        'company': farm.companyId,
        'farm': farm.id,
        'at': at.toIso8601String(),
        'rows': paddocks.map((p) => p.toMap()).toList(),
      }),
    );
  }

  Future<AtlasFieldPaddockSnapshot?> load(
    AtlasRemoteFarm farm,
    DateTime now,
  ) async {
    final raw = await _prefs.getString(_key(farm));
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map;
      if (data['tenant'] != farm.tenantId ||
          data['company'] != farm.companyId ||
          data['farm'] != farm.id) {
        return null;
      }
      final at = DateTime.parse(data['at'] as String);
      if (at.isAfter(now)) return null;
      final rows = (data['rows'] as List)
          .map((p) => PaddockData.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList();
      return AtlasFieldPaddockSnapshot(
        farmId: farm.id,
        loadedAt: at,
        paddocks: rows,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> invalidate(AtlasRemoteFarm farm) => _prefs.remove(_key(farm));
}
