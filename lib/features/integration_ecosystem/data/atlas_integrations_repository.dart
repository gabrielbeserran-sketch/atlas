
import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasIntegrationsRepository {
  AtlasIntegrationsRepository({
    AtlasHttpClient? client,
  }) : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.send(
      'GET',
      '/integrations/dashboard',
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> providers() async {
    final response = await _client.send(
      'GET',
      '/integrations/providers',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> connections() async {
    final response = await _client.send(
      'GET',
      '/integrations/connections',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> syncJobs() async {
    final response = await _client.send(
      'GET',
      '/integrations/sync-jobs',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> webhookDeliveries() async {
    final response = await _client.send(
      'GET',
      '/integrations/webhooks/deliveries',
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> partnerApplications() async {
    final response = await _client.send(
      'GET',
      '/integrations/partners/applications',
    );
    return response.asMapList();
  }
}
