import '../../data/services/atlas_enterprise_remote_auth_store.dart';
import '../models/atlas_enterprise_remote_session.dart';
import 'atlas_enterprise_api_client.dart';

class AtlasRemoteAuthorizationException implements Exception {
  const AtlasRemoteAuthorizationException({
    required this.permissionKey,
    required this.message,
  });

  final String permissionKey;
  final String message;

  @override
  String toString() => message;
}

class AtlasEnterpriseRemoteAuthorizationService {
  AtlasEnterpriseRemoteAuthorizationService._();

  static final AtlasEnterpriseRemoteAuthorizationService instance =
      AtlasEnterpriseRemoteAuthorizationService._();

  final AtlasEnterpriseRemoteAuthStore _store =
      AtlasEnterpriseRemoteAuthStore.instance;
  final AtlasEnterpriseApiClient _api =
      AtlasEnterpriseApiClient.instance;

  Future<AtlasRemoteSession?> session({
    bool refresh = false,
  }) async {
    if (refresh) {
      try {
        return await _api.me();
      } on AtlasEnterpriseApiException catch (error) {
        if (error.statusCode == 401) {
          await _store.clearSession();
          return null;
        }
      } catch (_) {
        // Sem rede: conserva a última política autenticada em cache.
      }
    }
    return _store.loadSession();
  }

  Future<bool> can(
    String permissionKey, {
    bool refresh = true,
  }) async {
    final current = await session(refresh: refresh);
    if (current == null) return false;
    return current.allows(permissionKey);
  }

  Future<void> require(
    String permissionKey, {
    bool refresh = true,
    String? reason,
  }) async {
    final allowed = await can(
      permissionKey,
      refresh: refresh,
    );
    if (!allowed) {
      throw AtlasRemoteAuthorizationException(
        permissionKey: permissionKey,
        message: reason ??
            'Operação bloqueada. Permissão necessária: $permissionKey.',
      );
    }
  }
}
