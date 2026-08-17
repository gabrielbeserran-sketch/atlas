import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasAnalyticsRepository {
  AtlasAnalyticsRepository({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard({String? farmId}) async {
    final response = await _client.send(
      'GET',
      '/analytics/dashboard',
      queryParameters: {if (farmId != null) 'farm_id': farmId},
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> refreshWarehouse({String? farmId}) async {
    final response = await _client.send(
      'POST',
      '/analytics/warehouse/refresh',
      queryParameters: {if (farmId != null) 'farm_id': farmId},
    );
    return response.asMapList();
  }

  Future<Map<String, dynamic>> generateFarmScore(String farmId) async {
    final response = await _client.send(
      'POST',
      '/analytics/farm-score/$farmId',
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> goals({String? farmId}) async {
    final response = await _client.send(
      'GET',
      '/analytics/goals',
      queryParameters: {if (farmId != null) 'farm_id': farmId},
    );
    return response.asMapList();
  }
}
