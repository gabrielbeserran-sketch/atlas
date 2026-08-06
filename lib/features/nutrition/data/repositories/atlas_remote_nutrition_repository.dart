import 'package:projeto_atlas/core/network/atlas_connected_repository.dart';

class AtlasRemoteNutritionRepository extends AtlasConnectedRepository {
  AtlasRemoteNutritionRepository()
      : super(
          entityType: 'nutrition_event',
          baseEndpoint: '/livestock/nutrition',
        );
}
