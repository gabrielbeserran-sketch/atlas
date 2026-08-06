import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/atlas_advanced/domain/models/atlas_advanced_data.dart';

class AtlasAdvancedService {
  AtlasAdvancedService({AtlasHttpClient? httpClient})
      : _httpClient = httpClient ?? AtlasHttpClient();

  final AtlasHttpClient _httpClient;

  Future<AtlasAdvancedDashboardData> dashboard(String farmId) async {
    final response = await _httpClient.send(
      'GET',
      '/advanced/farms/$farmId/advanced-dashboard',
    );

    return AtlasAdvancedDashboardData.fromMap(response.asMap());
  }

  Future<AtlasAiForecastData> forecast(
    String farmId, {
    required String type,
    String? animalId,
    String? lotId,
    int horizonDays = 30,
    Map<String, dynamic> climate = const <String, dynamic>{},
  }) async {
    final response = await _httpClient.send(
      'POST',
      '/advanced/farms/$farmId/ai/forecast',
      body: <String, dynamic>{
        'forecast_type': type,
        'animal_id': animalId,
        'lot_id': lotId,
        'horizon_days': horizonDays,
        'climate': climate,
      },
    );

    return AtlasAiForecastData.fromMap(response.asMap());
  }

  Future<List<Map<String, dynamic>>> geoAssets(
    String farmId, {
    String? type,
  }) async {
    final response = await _httpClient.send(
      'GET',
      '/advanced/farms/$farmId/geo-assets',
      queryParameters: type == null || type.trim().isEmpty
          ? null
          : <String, String>{
              'asset_type': type.trim(),
            },
    );

    return response.asMapList();
  }

  Future<Map<String, dynamic>> pastureDashboard(String farmId) async {
    final response = await _httpClient.send(
      'GET',
      '/advanced/farms/$farmId/pasture/dashboard',
    );

    return response.asMap();
  }

  Future<Map<String, dynamic>> agricultureDashboard(String farmId) async {
    final response = await _httpClient.send(
      'GET',
      '/advanced/farms/$farmId/agriculture/dashboard',
    );

    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> geneticsRanking(String farmId) async {
    final response = await _httpClient.send(
      'GET',
      '/advanced/farms/$farmId/genetics/ranking',
    );

    return response.asMapList();
  }
}
