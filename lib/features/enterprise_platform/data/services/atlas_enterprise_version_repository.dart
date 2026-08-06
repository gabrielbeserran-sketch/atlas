import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_enterprise_version_data.dart';

class AtlasEnterpriseVersionRepository {
  AtlasEnterpriseVersionRepository._();

  static final AtlasEnterpriseVersionRepository instance =
      AtlasEnterpriseVersionRepository._();

  static const String _storageKey =
      'atlas_enterprise_24c_versions_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasVersionedEntitySnapshot>> loadAll() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <AtlasVersionedEntitySnapshot>[];
    }

    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) =>
                AtlasVersionedEntitySnapshot.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasVersionedEntitySnapshot>[];
    }
  }

  Future<List<AtlasVersionedEntitySnapshot>> history({
    required String companyId,
    required String entityType,
    required String entityId,
  }) async {
    final values = await loadAll();
    return values
        .where(
          (item) =>
              item.companyId == companyId &&
              item.entityType == entityType &&
              item.entityId == entityId,
        )
        .toList()
      ..sort(
        (first, second) =>
            second.version.compareTo(first.version),
      );
  }

  Future<AtlasVersionedEntitySnapshot?> latest({
    required String companyId,
    required String entityType,
    required String entityId,
  }) async {
    final values = await history(
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
    );
    return values.isEmpty ? null : values.first;
  }

  Future<void> append(
    AtlasVersionedEntitySnapshot snapshot,
  ) async {
    final values = await loadAll();

    final duplicate = values.any(
      (item) =>
          item.companyId == snapshot.companyId &&
          item.entityType == snapshot.entityType &&
          item.entityId == snapshot.entityId &&
          item.version == snapshot.version,
    );

    if (duplicate) {
      throw StateError(
        'A versão ${snapshot.version} já existe para '
        '${snapshot.entityType}/${snapshot.entityId}.',
      );
    }

    values.add(snapshot);
    await _preferences.setString(
      _storageKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }
}
