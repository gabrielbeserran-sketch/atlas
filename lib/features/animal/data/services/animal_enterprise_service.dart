import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AnimalEnterpriseService {
  AnimalEnterpriseService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<AnimalData>> listAnimals({
    required String farmId,
    required String lotId,
  }) async {
    final uri = Uri(
      path: '/livestock/animals',
      queryParameters: <String, String>{
        'farm_id': farmId,
        if (lotId.trim().isNotEmpty) 'lot_id': lotId.trim(),
      },
    );

    final response = await _api.requestList('GET', uri.toString());
    return response.map(AnimalData.fromLivestockMap).toList(growable: false);
  }

  Future<AnimalData> createAnimal({
    required String farmId,
    required String lotId,
    required AnimalData animal,
  }) async {
    final response = await _api.request(
      'POST',
      '/livestock/animals',
      body: animal.toLivestockCreateBody(farmId: farmId, lotId: lotId),
    );
    return AnimalData.fromLivestockMap(response);
  }

  Future<AnimalData> updateAnimal({
    required String lotId,
    required AnimalData animal,
  }) async {
    final response = await _api.request(
      'PATCH',
      '/livestock/animals/${animal.id}',
      body: animal.toLivestockUpdateBody(lotId: lotId),
    );
    return AnimalData.fromLivestockMap(response);
  }

  Future<void> deleteAnimal(String animalId) async {
    await _api.request('DELETE', '/livestock/animals/$animalId');
  }
}
