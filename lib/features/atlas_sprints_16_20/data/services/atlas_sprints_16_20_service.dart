import '../../../../core/network/atlas_http_client.dart';
import '../../domain/models/atlas_sprints_16_20_data.dart';

class AtlasSprints1620Service {
  AtlasSprints1620Service({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();
  final AtlasHttpClient _client;

  Future<AtlasSprints1620DashboardData> loadDashboard() async {
    final response = await _client.send('GET', '/sprints-16-20/dashboard');
    return AtlasSprints1620DashboardData.fromJson(response.asMap());
  }

  Future<Map<String, dynamic>> loadReadiness() async {
    final response = await _client.send(
      'GET',
      '/sprints-16-20/enterprise/readiness',
    );
    return response.asMap();
  }

  Future<Map<String, dynamic>> loadKpis({String? datasetId}) async {
    final response = await _client.send(
      'GET',
      '/sprints-16-20/analytics/kpis',
      queryParameters: {
        if ((datasetId ?? '').trim().isNotEmpty)
          'dataset_id': datasetId!.trim(),
      },
    );
    return response.asMap();
  }
}
