import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasSecurityEnterpriseRepository {
  AtlasSecurityEnterpriseRepository({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.send(
      'GET',
      '/security-enterprise/dashboard',
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> policies() async {
    final response = await _client.send('GET', '/security-enterprise/policies');
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> accessReviews() async {
    final response = await _client.send(
      'GET',
      '/security-enterprise/access-reviews',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> privacyRequests() async {
    final response = await _client.send(
      'GET',
      '/security-enterprise/privacy/requests',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> risks() async {
    final response = await _client.send('GET', '/security-enterprise/risks');
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> continuityPlans() async {
    final response = await _client.send(
      'GET',
      '/security-enterprise/continuity/plans',
    );
    return response.asMapList();
  }
}
