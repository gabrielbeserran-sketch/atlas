import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AnimalWeightEnterpriseService {
  AnimalWeightEnterpriseService({AtlasEnterpriseApiClient? api})
      : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<AnimalWeightData>> listWeights({
    required String animalId,
  }) async {
    final response = await _api.requestList(
      'GET',
      '/livestock/animals/$animalId/weights',
    );
    return response
        .map(AnimalWeightData.fromRemoteMap)
        .toList(growable: false);
  }

  Future<AnimalWeightData> createWeight({
    required String animalId,
    required AnimalWeightData weight,
  }) async {
    final response = await _api.request(
      'POST',
      '/livestock/animals/$animalId/weights',
      body: weight.toRemoteBody(),
    );
    return AnimalWeightData.fromRemoteMap(response);
  }
}
