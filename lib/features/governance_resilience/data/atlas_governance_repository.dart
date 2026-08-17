import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasGovernanceRepository {
  AtlasGovernanceRepository({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.send('GET', '/governance/dashboard');
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> assets() async {
    final response = await _client.send('GET', '/governance/catalog/assets');
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> incidents() async {
    final response = await _client.send('GET', '/governance/incidents');
    return response.asMapList();
  }

  Future<Map<String, dynamic>> complianceScore() async {
    final response = await _client.send('GET', '/governance/compliance/score');
    return response.asMap();
  }

  Future<Map<String, dynamic>> healthSummary() async {
    final response = await _client.send('GET', '/governance/health/summary');
    return response.asMap();
  }
}
