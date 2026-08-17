import 'dart:convert';

import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_enterprise_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local de lotes com leitura remote-first.
///
/// A API é a autoridade quando há conectividade. SharedPreferences existe
/// somente como contingência offline e nunca deve substituir a resposta do
/// backend durante uma sessão conectada.
class HerdStorageService {
  HerdStorageService({
    HerdEnterpriseService? enterprise,
    AtlasEnterpriseApiClient? api,
  }) : _enterprise = enterprise ?? HerdEnterpriseService(),
       _api = api ?? AtlasEnterpriseApiClient.instance;

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final HerdEnterpriseService _enterprise;
  final AtlasEnterpriseApiClient _api;

  String _createStorageKey({required String farmName, String farmId = ''}) {
    final source = farmId.trim().isNotEmpty ? farmId : farmName;
    final normalized = source.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return 'atlas_herd_groups_$normalized';
  }

  Future<List<HerdGroupData>> loadGroups(
    String farmName, {
    String farmId = '',
  }) async {
    final resolvedFarmId = farmId.trim().isNotEmpty
        ? farmId.trim()
        : await _resolveFarmId(farmName);

    if (resolvedFarmId.isNotEmpty) {
      try {
        final remote = await _enterprise.listGroups(resolvedFarmId);
        await saveGroups(
          farmName: farmName,
          farmId: resolvedFarmId,
          groups: remote,
        );
        return remote;
      } on AtlasEnterpriseApiException {
        // Abaixo usamos somente o último snapshot confirmado do servidor.
      } catch (_) {
        // Falhas de conectividade/parsing não transformam o cache em autoridade.
      }
    }

    return _loadLocal(farmName: farmName, farmId: resolvedFarmId);
  }

  Future<List<HerdGroupData>> _loadLocal({
    required String farmName,
    String farmId = '',
  }) async {
    final storageKey = _createStorageKey(farmName: farmName, farmId: farmId);
    var savedData = await _preferences.getString(storageKey);

    if ((savedData == null || savedData.isEmpty) && farmId.trim().isNotEmpty) {
      final legacyKey = _createStorageKey(farmName: farmName);
      savedData = await _preferences.getString(legacyKey);
    }

    if (savedData == null || savedData.isEmpty) {
      return <HerdGroupData>[];
    }

    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;
      return decodedData
          .map(
            (item) =>
                HerdGroupData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return <HerdGroupData>[];
    }
  }

  Future<void> saveGroups({
    required String farmName,
    required List<HerdGroupData> groups,
    String farmId = '',
  }) async {
    final storageKey = _createStorageKey(farmName: farmName, farmId: farmId);
    final encodedData = jsonEncode(
      groups.map((group) => group.toMap()).toList(),
    );
    await _preferences.setString(storageKey, encodedData);
  }

  Future<String> _resolveFarmId(String farmName) async {
    final normalized = farmName.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    try {
      final farms = await _api.requestList('GET', '/farms');
      for (final farm in farms) {
        if ((farm['name']?.toString().trim().toLowerCase() ?? '') ==
            normalized) {
          return farm['id']?.toString().trim() ?? '';
        }
      }
    } catch (_) {
      return '';
    }
    return '';
  }
}
