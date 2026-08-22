import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm_handling/domain/models/farm_handling_batch_result.dart';

class FarmHandlingEnterpriseService {
  FarmHandlingEnterpriseService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<FarmHandlingBatchResult> execute({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _api.request(
      'POST',
      '/livestock/handling/batch',
      body: payload,
    );
    return FarmHandlingBatchResult.fromMap(response);
  }
}
