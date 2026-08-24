import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AtlasClientOnboardingService {
  AtlasClientOnboardingService({AtlasEnterpriseApiClient? api})
      : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<AtlasClientOnboardingProgress> load(String farmId) async {
    final response = await _api.request(
      'GET',
      '/saas-growth/onboarding',
      queryParameters: {'farm_id': farmId},
    );
    return AtlasClientOnboardingProgress.fromMap(response);
  }

  Future<AtlasClientOnboardingProgress> saveManualStep({
    required String farmId,
    required String stepId,
    required bool value,
  }) async {
    final response = await _api.request(
      'POST',
      '/saas-growth/onboarding',
      queryParameters: {'farm_id': farmId},
      body: {
        'data': {
          'steps': {stepId: value},
        },
      },
    );
    return AtlasClientOnboardingProgress.fromMap(response);
  }
}
