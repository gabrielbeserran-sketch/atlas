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

    final summary = responses[0];
    final alerts = responses[1];
    final summaryFarmId = summary['farm_id']?.toString() ?? '';
    final alertsFarmId = alerts['farm_id']?.toString() ?? '';
    final summaryContract = summary['contract_version']?.toString() ?? '';
    final alertsContract = alerts['contract_version']?.toString() ?? '';

    if (summaryFarmId != farmId || alertsFarmId != farmId) {
      throw StateError(
        'Inteligência operacional retornou contexto de fazenda divergente.',
      );
    }
    if (summaryContract.isNotEmpty &&
        alertsContract.isNotEmpty &&
        summaryContract != alertsContract) {
      throw StateError(
        'Contratos de inteligência operacional estão fora de sincronia.',
      );
    }

    return AtlasOperationalIntelligenceData.fromResponses(
      summary: summary,
      alertsResponse: alerts,
    );
  }
}
