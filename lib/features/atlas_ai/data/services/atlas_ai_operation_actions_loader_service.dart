import 'package:projeto_atlas/features/atlas_ai/data/services/atlas_ai_tracked_action_storage_service.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';

class AtlasAiOperationActionsLoaderService {
  AtlasAiOperationActionsLoaderService({
    FarmStorageService? farmStorage,
    AtlasAiTrackedActionStorageService?
        actionStorage,
  })  : farmStorage =
            farmStorage ?? FarmStorageService(),
        actionStorage =
            actionStorage ??
                const AtlasAiTrackedActionStorageService();

  final FarmStorageService farmStorage;

  final AtlasAiTrackedActionStorageService
      actionStorage;

  Future<AtlasAiOperationActionsLoadResult>
      load() async {
    final farms = await farmStorage.loadFarms();

    final actionLists = await Future.wait(
      farms.map((farm) {
        return actionStorage.load(
          farmName: farm.name,
        );
      }),
    );

    final actions = actionLists
        .expand((items) => items)
        .toList();

    return AtlasAiOperationActionsLoadResult(
      farms: farms,
      actions: actions,
    );
  }
}

class AtlasAiOperationActionsLoadResult {
  const AtlasAiOperationActionsLoadResult({
    required this.farms,
    required this.actions,
  });

  final List<FarmData> farms;

  final List<AtlasAiTrackedAction> actions;
}
