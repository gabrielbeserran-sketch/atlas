
import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasOperationsRepository {
  AtlasOperationsRepository({
    AtlasHttpClient? client,
  }) : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<List<Map<String, dynamic>>> timeline({
    required String farmId,
    String? animalId,
  }) async {
    final response = await _client.send(
      'GET',
      '/operations/timeline',
      queryParameters: {
        'farm_id': farmId,
        if (animalId != null) 'animal_id': animalId,
      },
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> alerts({
    String? farmId,
  }) async {
    final response = await _client.send(
      'GET',
      '/operations/alerts',
      queryParameters: {
        if (farmId != null) 'farm_id': farmId,
        'status': 'open',
      },
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> generateAlerts({
    String? farmId,
  }) async {
    final response = await _client.send(
      'POST',
      '/operations/alerts/generate',
      queryParameters: {
        if (farmId != null) 'farm_id': farmId,
      },
    );
    return response.asMapList();
  }

  Future<Map<String, dynamic>> alertToTask(
    String alertId,
  ) async {
    final response = await _client.send(
      'POST',
      '/operations/alerts/$alertId/task',
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> tasks({
    String? farmId,
  }) async {
    final response = await _client.send(
      'GET',
      '/operations/tasks',
      queryParameters: {
        if (farmId != null) 'farm_id': farmId,
        'status': 'open',
      },
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> generateIndicators({
    String? farmId,
  }) async {
    final response = await _client.send(
      'POST',
      '/operations/indicators/generate',
      queryParameters: {
        if (farmId != null) 'farm_id': farmId,
      },
    );
    return response.asMapList();
  }

  Future<Map<String, dynamic>> executiveReportData(
    String farmId,
  ) async {
    final response = await _client.send(
      'GET',
      '/operations/reports/executive',
      queryParameters: {'farm_id': farmId},
    );
    return response.asMap();
  }
}
