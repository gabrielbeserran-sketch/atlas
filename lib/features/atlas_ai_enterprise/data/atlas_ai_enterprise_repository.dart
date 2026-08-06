
import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasAiEnterpriseRepository {
  AtlasAiEnterpriseRepository({
    AtlasHttpClient? client,
  }) : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.send(
      'GET',
      '/atlas-ai/dashboard',
    );
    return response.asMap();
  }

  Future<Map<String, dynamic>> chat({
    String? sessionId,
    String? farmId,
    required String message,
    String? specialty,
  }) async {
    final response = await _client.send(
      'POST',
      '/atlas-ai/chat',
      body: {
        if (sessionId != null) 'session_id': sessionId,
        if (farmId != null) 'farm_id': farmId,
        'message': message,
        if (specialty != null)
          'requested_specialty': specialty,
      },
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> recommendations({
    String? farmId,
  }) async {
    final response = await _client.send(
      'GET',
      '/atlas-ai/recommendations',
      queryParameters: {
        if (farmId != null) 'farm_id': farmId,
      },
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> plans({
    String? farmId,
  }) async {
    final response = await _client.send(
      'GET',
      '/atlas-ai/plans',
      queryParameters: {
        if (farmId != null) 'farm_id': farmId,
      },
    );
    return response.asMapList();
  }

  Future<Map<String, dynamic>> createPlan({
    String? farmId,
    required String horizon,
  }) async {
    final response = await _client.send(
      'POST',
      '/atlas-ai/plans',
      body: {
        if (farmId != null) 'farm_id': farmId,
        'horizon': horizon,
      },
    );
    return response.asMap();
  }
}
