import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AtlasClientOnboardingService {
  AtlasClientOnboardingService({AtlasEnterpriseApiClient? api})
      : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<AtlasClientOnboardingProgress> load() async {
    final response = await _api.request('GET', '/saas-growth/onboarding');
    return AtlasClientOnboardingProgress.fromMap(response);
  }

  Future<AtlasClientOnboardingProgress> save(
    AtlasClientOnboardingProgress progress,
  ) async {
    final response = await _api.request(
      'POST',
      '/saas-growth/onboarding',
      body: {
        'data': {
          'steps': progress.steps,
        },
      },
    );
    return AtlasClientOnboardingProgress.fromMap(response);
  }
}
