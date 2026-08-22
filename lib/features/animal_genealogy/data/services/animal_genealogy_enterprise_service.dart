import 'package:projeto_atlas/features/animal_genealogy/domain/models/animal_genealogy_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AnimalGenealogyEnterpriseService {
  AnimalGenealogyEnterpriseService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<AnimalGenealogyData> loadGenealogy(String animalId) async {
    final response = await _api.request(
      'GET',
      '/livestock/animals/$animalId/genealogy',
    );

    return AnimalGenealogyData.fromMap(response);
  }
}
