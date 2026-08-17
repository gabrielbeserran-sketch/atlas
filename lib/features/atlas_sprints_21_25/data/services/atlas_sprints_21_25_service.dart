import '../../../../core/network/atlas_http_client.dart';
import '../../domain/models/atlas_sprints_21_25_data.dart';

class AtlasSprints2125Service {
  AtlasSprints2125Service({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();
  final AtlasHttpClient _client;

  Future<AtlasSprints2125DashboardData> loadDashboard(String farmId) async {
    final id = farmId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        farmId,
        'farmId',
        'Informe uma fazenda válida.',
      );
    }
    final responses = await Future.wait([
      _client.send('GET', '/precision-livestock/farms/$id/dashboard'),
      _client.send('GET', '/reproduction-advanced/farms/$id/dashboard'),
      _client.send('GET', '/health-intelligence/farms/$id/dashboard'),
      _client.send('GET', '/nutrition-intelligence/farms/$id/dashboard'),
      _client.send('GET', '/farm-operations/farms/$id/dashboard'),
    ]);
    return AtlasSprints2125DashboardData.fromJson({
      'precision': responses[0].asMap(),
      'reproduction': responses[1].asMap(),
      'health': responses[2].asMap(),
      'nutrition': responses[3].asMap(),
      'operations': responses[4].asMap(),
    });
  }
}
