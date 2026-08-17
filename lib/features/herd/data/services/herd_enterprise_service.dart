import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class HerdEnterpriseService {
  HerdEnterpriseService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<HerdGroupData>> listGroups(String farmId) async {
    final response = await _api.requestList(
      'GET',
      '/livestock/lots',
      queryParameters: {'farm_id': farmId, 'active_only': 'true'},
    );
    return response.map(HerdGroupData.fromRemoteMap).toList(growable: false);
  }

  Future<HerdGroupData> createGroup({
    required String farmId,
    required HerdGroupData group,
  }) async {
    final response = await _api.request(
      'POST',
      '/livestock/lots',
      body: group.toCreateBody(farmId),
    );
    return HerdGroupData.fromRemoteMap(response);
  }

  Future<HerdGroupData> updateGroup(HerdGroupData group) async {
    if (group.id.trim().isEmpty) {
      throw const AtlasEnterpriseApiException(
        'O lote ainda não possui ID remoto.',
      );
    }
    final response = await _api.request(
      'PATCH',
      '/livestock/lots/${group.id}',
      body: group.toUpdateBody(),
    );
    return HerdGroupData.fromRemoteMap(response);
  }

  Future<void> deleteGroup(String groupId) async {
    await _api.request('DELETE', '/livestock/lots/$groupId');
  }
}
