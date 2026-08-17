import 'dart:convert';

import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_24a_repository.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_session_service.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_version_service.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_sync_engine_24c.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_version_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_sync_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_audit_service.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_authorization_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmStorageService {
  static const String _farmsKey = 'atlas_farms';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasEnterpriseRemoteAuthStore _remoteAuth =
      AtlasEnterpriseRemoteAuthStore.instance;
  final AtlasEnterpriseApiClient _api = AtlasEnterpriseApiClient.instance;

  Future<List<FarmData>> loadFarms() async {
    final local = await loadFarmsUnscoped();
    final remoteSession = await _remoteAuth.loadSession();

    if (remoteSession != null && remoteSession.accessToken.isNotEmpty) {
      List<Map<String, dynamic>> remote;
      try {
        remote = await _api.requestList('GET', '/farms');
      } on AtlasEnterpriseApiException {
        if (local.isNotEmpty) return local;
        rethrow;
      }
      // A API é a autoridade quando existe sessão remota. Não misturamos
      // valores antigos do cache com a resposta atual do servidor, pois isso
      // fazia animais/área reaparecerem com números obsoletos na interface.
      final values = remote
          .map(FarmData.fromMap)
          .where((item) => item.id != null && item.id!.isNotEmpty)
          .toList(growable: false);

      await saveLocalCache(values);
      return values;
    }

    final enterprise = AtlasEnterpriseSessionService.instance;
    await enterprise.ensureInitialized();

    final companyId = enterprise.currentCompanyId;
    final userId = enterprise.currentUserId;

    if (companyId == null || userId == null) {
      return local;
    }

    await AtlasEnterpriseAuthorizationService.instance.require(
      'farms.read',
      companyId: companyId,
      userId: userId,
    );

    final allowed = await AtlasEnterprise24ARepository.instance
        .farmsAllowedForUser(companyId: companyId, userId: userId);

    final snapshot = await AtlasEnterprise24ARepository.instance.load();
    final companyHasCanonicalFarms = snapshot.farms.any(
      (item) => item.scope.companyId == companyId,
    );
    if (!companyHasCanonicalFarms) {
      return local;
    }

    final allowedNames = allowed
        .map((item) => item.name.trim().toLowerCase())
        .toSet();

    return local.where((farm) {
      return allowedNames.contains(farm.name.trim().toLowerCase());
    }).toList();
  }

  Future<List<FarmData>> loadFarmsUnscoped() async {
    final savedData = await _preferences.getString(_farmsKey);

    if (savedData == null || savedData.isEmpty) {
      return <FarmData>[];
    }

    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;

      return decodedData
          .map(
            (item) => FarmData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return <FarmData>[];
    }
  }

  Future<void> saveLocalCache(List<FarmData> farms) async {
    final encodedData = jsonEncode(farms.map((farm) => farm.toMap()).toList());
    await _preferences.setString(_farmsKey, encodedData);
  }

  Future<void> saveFarms(List<FarmData> farms) async {
    await saveLocalCache(farms);

    final remoteSession = await _remoteAuth.loadSession();
    if (remoteSession != null && remoteSession.accessToken.isNotEmpty) {
      // No modo Enterprise remoto, a API é a autoridade.
      // O cache local guarda apenas metadados de UI já aceitos pelo servidor.
      return;
    }

    final enterprise = AtlasEnterpriseSessionService.instance;
    await enterprise.ensureInitialized();

    final companyId = enterprise.currentCompanyId;
    final userId = enterprise.currentUserId;

    if (companyId == null || userId == null) {
      return;
    }

    await AtlasEnterpriseAuthorizationService.instance.require(
      'farms.update',
      companyId: companyId,
      userId: userId,
    );

    for (final farm in farms) {
      final canonicalFarm = await AtlasEnterprise24ARepository.instance
          .ensureFarm(
            companyId: companyId,
            name: farm.name,
            city: farm.city,
            state: farm.state,
            userId: userId,
          );

      final history = await AtlasEnterpriseVersionService.instance.history(
        companyId: companyId,
        entityType: 'farm',
        entityId: canonicalFarm.id,
      );
      final baseVersion = history.isEmpty ? 0 : history.first.version;

      final version = await AtlasEnterpriseVersionService.instance.commit(
        tenantId: companyId,
        companyId: companyId,
        farmId: canonicalFarm.id,
        entityType: 'farm',
        entityId: canonicalFarm.id,
        payload: farm.toMap(),
        baseVersion: baseVersion,
        mutationType: baseVersion == 0
            ? AtlasVersionMutationType.create
            : AtlasVersionMutationType.update,
        reason: 'Persistência de fazenda pelo FarmStorageService.',
      );

      await AtlasEnterpriseSyncEngine24C().enqueue(
        tenantId: companyId,
        companyId: companyId,
        farmId: canonicalFarm.id,
        entityType: 'farm',
        entityId: canonicalFarm.id,
        operationType: baseVersion == 0
            ? AtlasEnterpriseSyncOperationType.create
            : AtlasEnterpriseSyncOperationType.update,
        payload: version.payload,
        baseVersion: baseVersion,
      );
    }

    await AtlasEnterpriseAuditService.instance.record(
      action: 'update',
      module: 'farms',
      entityType: 'farm_collection',
      entityId: companyId,
      description: 'Cadastro de fazendas persistido.',
      companyId: companyId,
      userId: userId,
      after: <String, dynamic>{
        'farmCount': farms.length,
        'farmNames': farms.map((item) => item.name).toList(),
      },
    );

    await enterprise.reload();
  }
}
