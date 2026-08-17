import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/data_intelligence/domain/models/atlas_data_intelligence_snapshot.dart';

class AtlasDataIntelligenceService {
  AtlasDataIntelligenceService({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<AtlasDataIntelligenceSnapshot> load() async {
    final analytics = await _client.send('GET', '/analytics/dashboard');
    final platform = await _client.send('GET', '/data-platform/dashboard');
    final realtime = await _client.send(
      'GET',
      '/data-platform/realtime/metrics',
    );
    return AtlasDataIntelligenceSnapshot.fromResponses(
      analytics: analytics.asMap(),
      platform: platform.asMap(),
      realtime: realtime.asMapList(),
    );
  }

  Future<Map<String, dynamic>> createKpi({
    required String key,
    required String name,
    required String unit,
  }) async {
    final response = await _client.send(
      'POST',
      '/data-platform/kpis/definitions',
      body: {
        'code': key,
        'data': {'name': name, 'unit': unit, 'active': true},
      },
    );
    return response.asMap();
  }

  Future<Map<String, dynamic>> requestReport(String name) async {
    final response = await _client.send(
      'POST',
      '/data-platform/reports',
      body: {
        'code': name,
        'data': {'format': 'pdf', 'status': 'queued'},
      },
    );
    return response.asMap();
  }

  Future<Map<String, dynamic>> generateBenchmark(String farmId) async {
    final response = await _client.send(
      'POST',
      '/data-platform/benchmarks/generate',
      body: {
        'code': 'farm-benchmark',
        'data': {'farm_id': farmId, 'anonymous': true},
      },
    );
    return response.asMap();
  }
}
