import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasCommercialRepository {
  AtlasCommercialRepository({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _client.send('GET', '/commercial/dashboard');
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> customers({
    String? status,
    String? search,
  }) async {
    final response = await _client.send(
      'GET',
      '/commercial/customers',
      queryParameters: {
        if (status != null) 'status': status,
        if (search != null) 'search': search,
      },
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> opportunities({String? stage}) async {
    final response = await _client.send(
      'GET',
      '/commercial/opportunities',
      queryParameters: {if (stage != null) 'stage': stage},
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> invoices({String? status}) async {
    final response = await _client.send(
      'GET',
      '/commercial/invoices',
      queryParameters: {if (status != null) 'status': status},
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> plans() async {
    final response = await _client.send('GET', '/commercial/plans');
    return response.asMapList();
  }
}
