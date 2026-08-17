import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasMlRepository {
  AtlasMlRepository({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.send('GET', '/ml/dashboard');
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> datasets() async {
    final response = await _client.send('GET', '/ml/datasets');
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> models() async {
    final response = await _client.send('GET', '/ml/models');
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> deployments() async {
    final response = await _client.send('GET', '/ml/deployments');
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> predictions({String? deploymentId}) async {
    final response = await _client.send(
      'GET',
      '/ml/predictions',
      queryParameters: {
        if (deploymentId != null) 'deployment_id': deploymentId,
      },
    );
    return response.asMapList();
  }
}
