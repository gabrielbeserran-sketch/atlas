import 'package:projeto_atlas/core/network/atlas_connected_repository.dart';

class AtlasRemoteAnimalRepository extends AtlasConnectedRepository {
  AtlasRemoteAnimalRepository()
      : super(
          entityType: 'livestock_animal',
          baseEndpoint: '/livestock/animals',
        );
}
