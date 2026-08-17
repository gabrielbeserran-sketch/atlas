import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasAutomationRepository {
  AtlasAutomationRepository({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.send('GET', '/automation/dashboard');
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> rules() async {
    final response = await _client.send('GET', '/automation/rules');
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> calendar() async {
    final response = await _client.send('GET', '/automation/calendar');
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> objectives() async {
    final response = await _client.send('GET', '/automation/objectives');
    return response.asMapList();
  }
}
