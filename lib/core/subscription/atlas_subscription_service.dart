import 'package:projeto_atlas/core/subscription/atlas_subscription_profile.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AtlasSubscriptionService {
  AtlasSubscriptionService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  static final AtlasSubscriptionService instance = AtlasSubscriptionService();

  final AtlasEnterpriseApiClient _api;

  Future<AtlasSubscriptionProfile> loadCurrent() async {
    final response = await _api.request(
      'GET',
      '/saas-growth/subscriptions/current',
    );
    return AtlasSubscriptionProfile.fromMap(response);
  }
}
