import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/platform_hubs/domain/models/atlas_hub_snapshot.dart';

class AtlasPlatformHubService {
  AtlasPlatformHubService({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<AtlasHubSnapshot> loadPrecision(String farmId) async {
    final response = await _client.send(
      'GET',
      '/precision-hub/farms/$farmId/dashboard',
    );
    return AtlasHubSnapshot.fromMap('Precision Hub', response.asMap());
  }

  Future<AtlasHubSnapshot> loadEnterprise() async {
    final response = await _client.send(
      'GET',
      '/enterprise-operations/dashboard',
    );
    return AtlasHubSnapshot.fromMap('Operações Enterprise', response.asMap());
  }

  Future<AtlasHubSnapshot> loadSaas({required bool admin}) async {
    final response = await _client.send(
      'GET',
      admin ? '/saas-growth/admin/dashboard' : '/saas-growth/client-portal',
    );
    return AtlasHubSnapshot.fromMap(
      admin ? 'Administração SaaS' : 'Portal do cliente',
      response.asMap(),
    );
  }

  Future<Map<String, dynamic>> create(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.send('POST', path, body: payload);
    return response.asMap();
  }

  Future<Map<String, dynamic>> effectiveFlags() async {
    final response = await _client.send(
      'GET',
      '/saas-growth/feature-flags/effective',
    );
    return response.asMap();
  }
}
