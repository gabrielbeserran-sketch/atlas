
import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasReleaseEngineeringRepository {
  AtlasReleaseEngineeringRepository({
    AtlasHttpClient? client,
  }) : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.send(
      'GET',
      '/release-engineering/dashboard',
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> pipelines() async {
    final response = await _client.send(
      'GET',
      '/release-engineering/pipelines',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> builds() async {
    final response = await _client.send(
      'GET',
      '/release-engineering/builds',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> deployments() async {
    final response = await _client.send(
      'GET',
      '/release-engineering/deployments',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> environments() async {
    final response = await _client.send(
      'GET',
      '/release-engineering/environments',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> approvals() async {
    final response = await _client.send(
      'GET',
      '/release-engineering/change-approvals',
    );
    return response.asMapList();
  }
}
