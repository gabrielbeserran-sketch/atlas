import '../models/atlas_enterprise_sync_data.dart';
import 'atlas_enterprise_api_client.dart';
import 'atlas_enterprise_sync_transport.dart';

class AtlasHttpSyncTransport
    implements AtlasEnterpriseSyncTransport {
  AtlasHttpSyncTransport._();

  static final AtlasHttpSyncTransport instance =
      AtlasHttpSyncTransport._();

  final AtlasEnterpriseApiClient _api =
      AtlasEnterpriseApiClient.instance;

  @override
  Future<AtlasPushOperationResult> push(
    AtlasEnterpriseSyncOperation operation,
  ) async {
    final response = await _api.request(
      'POST',
      '/sync/push',
      body: <String, dynamic>{
        'operation_id': operation.operationId,
        'idempotency_key': operation.idempotencyKey,
        'tenant_id': operation.tenantId,
        'company_id': operation.companyId,
        'farm_id': operation.farmId,
        'entity_type': operation.entityType,
        'entity_id': operation.entityId,
        'operation_type': operation.operationType.name,
        'payload': operation.payload,
        'base_version': operation.baseVersion,
        'device_id': operation.deviceId,
      },
    );

    return AtlasPushOperationResult(
      accepted: response['accepted'] == true,
      conflict: response['conflict'] == true,
      remoteVersion:
          (response['remote_version'] as num?)?.toInt() ?? 0,
      remotePayload: Map<String, dynamic>.from(
        (response['remote_payload'] as Map?) ??
            const <String, dynamic>{},
      ),
      error: response['error']?.toString() ?? '',
    );
  }

  @override
  Future<List<AtlasRemoteEntityState>> pull({
    required String companyId,
    required String cursor,
  }) async {
    final values = await _api.requestList(
      'GET',
      '/sync/pull?cursor=${Uri.encodeQueryComponent(cursor)}',
    );

    return values
        .map(
          (item) => AtlasRemoteEntityState(
            entityType:
                item['entity_type']?.toString() ?? '',
            entityId:
                item['entity_id']?.toString() ?? '',
            version:
                (item['version'] as num?)?.toInt() ?? 0,
            payload: Map<String, dynamic>.from(
              (item['payload'] as Map?) ??
                  const <String, dynamic>{},
            ),
            deleted: item['deleted'] == true,
            cursor: item['cursor']?.toString() ?? '',
          ),
        )
        .toList();
  }
}
