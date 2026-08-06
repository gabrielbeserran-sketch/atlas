
import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasAiRepository {
  AtlasAiRepository({
    AtlasHttpClient? client,
  }) : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> createConversation({
    String? farmId,
    required String specialistArea,
    String title = 'Nova conversa',
  }) async {
    final response = await _client.send(
      'POST',
      '/ai/conversations',
      body: {
        'farm_id': farmId,
        'title': title,
        'specialist_area': specialistArea,
      },
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> sendMessage({
    required String conversationId,
    required String content,
    Map<String, dynamic> context = const {},
  }) async {
    final response = await _client.send(
      'POST',
      '/ai/conversations/$conversationId/messages',
      body: {
        'content': content,
        'context': context,
      },
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> messages(
    String conversationId,
  ) async {
    final response = await _client.send(
      'GET',
      '/ai/conversations/$conversationId/messages',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> analyze({
    required String area,
    String? farmId,
    String? animalId,
    Map<String, dynamic> context = const {},
  }) async {
    final response = await _client.send(
      'POST',
      '/ai/analyze/$area',
      body: {
        'farm_id': farmId,
        'animal_id': animalId,
        'context': context,
      },
    );
    return response.asMapList();
  }

  Future<Map<String, dynamic>> executive({
    String? farmId,
    Map<String, dynamic> context = const {},
  }) async {
    final response = await _client.send(
      'POST',
      '/ai/executive',
      body: {
        'farm_id': farmId,
        'animal_id': null,
        'context': context,
      },
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> recommendations({
    String? farmId,
    String? area,
  }) async {
    final response = await _client.send(
      'GET',
      '/ai/recommendations',
      queryParameters: {
        if (farmId != null) 'farm_id': farmId,
        if (area != null) 'area': area,
        'status': 'open',
      },
    );
    return response.asMapList();
  }
}
