import 'package:projeto_atlas/features/dashboard/domain/models/atlas_operational_intelligence_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AtlasOperationalIntelligenceService {
  AtlasOperationalIntelligenceService({AtlasEnterpriseApiClient? api})
      : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<AtlasOperationalIntelligenceData> load(String farmId) async {
    final responses = await Future.wait<Map<String, dynamic>>([
      _api.request(
        'GET',
        '/livestock/intelligence/operational-summary',
        queryParameters: {'farm_id': farmId},
      ),
      _api.request(
        'GET',
        '/livestock/intelligence/operational-alerts',
        queryParameters: {'farm_id': farmId},
      ),
    ]);

    return AtlasOperationalIntelligenceData.fromResponses(
      summary: responses[0],
      alertsResponse: responses[1],
    );
  }
}
