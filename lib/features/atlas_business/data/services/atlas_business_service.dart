import '../../../../core/network/atlas_http_client.dart';
import '../../domain/models/atlas_business_dashboard_data.dart';

class AtlasBusinessService {
  AtlasBusinessService({AtlasHttpClient? client})
      : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<AtlasBusinessDashboardData> dashboard({String? farmId}) async {
    final normalizedFarmId = farmId?.trim() ?? '';

    final response = await _client.send(
      'GET',
      '/business/dashboard',
      queryParameters: {
        if (normalizedFarmId.isNotEmpty) 'farm_id': normalizedFarmId,
      },
    );

    return AtlasBusinessDashboardData.fromJson(response.asMap());
  }

  Future<List<Map<String, dynamic>>> parties({String? partyType}) async {
    final normalizedPartyType = partyType?.trim() ?? '';

    final response = await _client.send(
      'GET',
      '/business/parties',
      queryParameters: {
        if (normalizedPartyType.isNotEmpty) 'party_type': normalizedPartyType,
      },
    );

    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> commercialDocuments({
    String? farmId,
    String? documentType,
  }) async {
    final normalizedFarmId = farmId?.trim() ?? '';
    final normalizedDocumentType = documentType?.trim() ?? '';

    final response = await _client.send(
      'GET',
      '/business/commercial-documents',
      queryParameters: {
        if (normalizedFarmId.isNotEmpty) 'farm_id': normalizedFarmId,
        if (normalizedDocumentType.isNotEmpty)
          'document_type': normalizedDocumentType,
      },
    );

    return response.asMapList();
  }

  Future<Map<String, dynamic>> bi({
    String? farmId,
    int days = 365,
  }) async {
    final normalizedFarmId = farmId?.trim() ?? '';

    final response = await _client.send(
      'GET',
      '/business/bi/dashboard',
      queryParameters: {
        'days': days.toString(),
        if (normalizedFarmId.isNotEmpty) 'farm_id': normalizedFarmId,
      },
    );

    return response.asMap();
  }

  Future<Map<String, dynamic>> productReadiness() async {
    final response = await _client.send(
      'GET',
      '/business/product/readiness',
    );

    return response.asMap();
  }
}
