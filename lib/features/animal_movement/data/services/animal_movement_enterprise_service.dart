import 'package:projeto_atlas/features/animal_movement/domain/models/animal_movement_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalMovementEnterpriseService {
  AnimalMovementEnterpriseService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<AnimalMovementData>> listMovements({
    required String animalId,
    required List<HerdGroupData> groups,
  }) async {
    final response = await _api.requestList(
      'GET',
      '/livestock/animals/$animalId/movements',
    );
    String lotName(String? id) {
      if (id == null || id.trim().isEmpty) return '';
      for (final group in groups) {
        if (group.id == id) return group.name;
      }
      return id;
    }

    return response
        .map(
          (item) => AnimalMovementData.fromRemoteMap(
            item,
            originName: lotName(item['from_lot_id']?.toString()),
            destinationName: lotName(item['to_lot_id']?.toString()),
          ),
        )
        .toList(growable: false);
  }

  Future<AnimalMovementData> createMovement({
    required String animalId,
    required AnimalMovementData movement,
    required List<HerdGroupData> groups,
  }) async {
    final response = await _api.request(
      'POST',
      '/livestock/animals/$animalId/movements',
      body: movement.toRemoteBody(),
    );
    String lotName(String? id) {
      if (id == null || id.trim().isEmpty) return '';
      for (final group in groups) {
        if (group.id == id) return group.name;
      }
      return id;
    }

    return AnimalMovementData.fromRemoteMap(
      response,
      originName: lotName(response['from_lot_id']?.toString()),
      destinationName: lotName(response['to_lot_id']?.toString()),
    );
  }
}
