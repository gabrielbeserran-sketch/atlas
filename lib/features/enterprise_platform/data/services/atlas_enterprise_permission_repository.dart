import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_enterprise_permission_data.dart';

class AtlasEnterprisePermissionRepository {
  AtlasEnterprisePermissionRepository._();

  static final AtlasEnterprisePermissionRepository instance =
      AtlasEnterprisePermissionRepository._();

  static const String _rolesKey = 'atlas_enterprise_24b_custom_roles_v1';
  static const String _policiesKey = 'atlas_enterprise_24b_user_policies_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasCustomEnterpriseRole>> loadCustomRoles({
    String? companyId,
  }) async {
    final values = await _decodeList(
      _rolesKey,
      AtlasCustomEnterpriseRole.fromMap,
    );
    if (companyId == null || companyId.trim().isEmpty) {
      return values;
    }
    return values
        .where((item) => item.companyId == companyId && item.active)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveCustomRole(AtlasCustomEnterpriseRole role) async {
    final values = await _decodeList(
      _rolesKey,
      AtlasCustomEnterpriseRole.fromMap,
    );
    _upsert(values, role, (item) => item.id);
    await _saveList(_rolesKey, values.map((item) => item.toMap()).toList());
  }

  Future<List<AtlasUserPermissionPolicy>> loadPolicies({
    String? companyId,
  }) async {
    final values = await _decodeList(
      _policiesKey,
      AtlasUserPermissionPolicy.fromMap,
    );
    if (companyId == null || companyId.trim().isEmpty) {
      return values;
    }
    return values.where((item) => item.companyId == companyId).toList();
  }

  Future<AtlasUserPermissionPolicy?> findPolicy({
    required String companyId,
    required String userId,
  }) async {
    final values = await loadPolicies(companyId: companyId);
    for (final item in values) {
      if (item.userId == userId) return item;
    }
    return null;
  }

  Future<void> savePolicy(AtlasUserPermissionPolicy policy) async {
    final values = await _decodeList(
      _policiesKey,
      AtlasUserPermissionPolicy.fromMap,
    );
    final existingIndex = values.indexWhere(
      (item) =>
          item.companyId == policy.companyId && item.userId == policy.userId,
    );
    if (existingIndex == -1) {
      values.add(policy);
    } else {
      values[existingIndex] = policy;
    }
    await _saveList(_policiesKey, values.map((item) => item.toMap()).toList());
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

  Future<void> _saveList(String key, List<Map<String, dynamic>> values) {
    return _preferences.setString(key, jsonEncode(values));
  }

  void _upsert<T>(List<T> values, T value, String Function(T) readId) {
    final index = values.indexWhere((item) => readId(item) == readId(value));
    if (index == -1) {
      values.add(value);
    } else {
      values[index] = value;
    }
  }
}
