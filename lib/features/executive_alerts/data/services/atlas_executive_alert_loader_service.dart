import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/atlas_ai/data/services/atlas_ai_tracked_action_storage_service.dart';
import 'package:projeto_atlas/features/diagnostics/domain/services/atlas_diagnostic_service.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/services/atlas_executive_alert_service.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_storage_service.dart';

class AtlasExecutiveAlertLoaderService {
  AtlasExecutiveAlertLoaderService({
    FarmStorageService? farmStorage,
    HerdStorageService? herdStorage,
    AnimalStorageService? animalStorage,
    PaddockStorageService? paddockStorage,
    FarmFinanceStorageService? financeStorage,
    FarmInventoryStorageService? inventoryStorage,
    FarmAgendaStorageService? agendaStorage,
    AtlasAiTrackedActionStorageService?
        trackedActionStorage,
    AnimalHealthStorageService? healthStorage,
    AnimalReproductionStorageService? reproductionStorage,
    AtlasFarmIntelligenceService?
        farmIntelligenceService,
    AtlasDiagnosticService? diagnosticService,
  })  : farmStorage =
            farmStorage ?? FarmStorageService(),
        herdStorage =
            herdStorage ?? HerdStorageService(),
        animalStorage =
            animalStorage ?? AnimalStorageService(),
        paddockStorage =
            paddockStorage ?? PaddockStorageService(),
        financeStorage =
            financeStorage ??
                FarmFinanceStorageService(),
        inventoryStorage =
            inventoryStorage ??
                FarmInventoryStorageService(),
        agendaStorage =
            agendaStorage ??
                FarmAgendaStorageService(),
        trackedActionStorage =
            trackedActionStorage ??
                const AtlasAiTrackedActionStorageService(),
        healthStorage = healthStorage ?? AnimalHealthStorageService(),
        reproductionStorage =
            reproductionStorage ?? AnimalReproductionStorageService(),
        farmIntelligenceService =
            farmIntelligenceService ??
                const AtlasFarmIntelligenceService(),
        diagnosticService =
            diagnosticService ??
                const AtlasDiagnosticService();

  final FarmStorageService farmStorage;
  final HerdStorageService herdStorage;
  final AnimalStorageService animalStorage;
  final PaddockStorageService paddockStorage;
  final FarmFinanceStorageService financeStorage;
  final FarmInventoryStorageService inventoryStorage;
  final FarmAgendaStorageService agendaStorage;

  final AtlasAiTrackedActionStorageService trackedActionStorage;
  final AnimalHealthStorageService healthStorage;
  final AnimalReproductionStorageService reproductionStorage;

  final AtlasFarmIntelligenceService
      farmIntelligenceService;

  final AtlasDiagnosticService diagnosticService;

  Future<AtlasExecutiveAlertLoadResult>
      load() async {
    final farms = await farmStorage.loadFarms();

    final inputs = await Future.wait(
      farms.map(_loadFarmInput),
    );

    return AtlasExecutiveAlertLoadResult(
      farms: farms,
      inputs: inputs,
    );
  }

  Future<AtlasExecutiveFarmAlertInput>
      _loadFarmInput(
    FarmData farm,
  ) async {
    final groups =
        await herdStorage.loadGroups(
      farm.name,
    );

    final paddocks =
        await paddockStorage.loadPaddocks(
      farm.name,
    );

    final financeRecords =
        await financeStorage.loadRecords(
      farm.name,
    );

    final inventoryItems =
        await inventoryStorage.loadItems(
      farm.name,
    );

    final agendaTasks =
        await agendaStorage.loadTasks(
      farm.name,
    );

    final trackedActions =
        await trackedActionStorage.load(
      farmName: farm.name,
    );

    final animalLists = await Future.wait(
      groups.map((group) {
        return animalStorage.loadAnimals(
          farmName: farm.name,
          groupName: group.name,
        );
      }),
    );

    final animals = animalLists
        .expand((items) => items)
        .toList();

    final healthRecords = <AtlasExecutiveAnimalHealthContext>[];
    final reproductionRecords =
        <AtlasExecutiveAnimalReproductionContext>[];

    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];
      final groupAnimals = animalLists[groupIndex];

      for (final animal in groupAnimals) {
        final animalLabel = animal.displayName;

        final animalHealthRecords = await healthStorage.loadRecords(
          farmName: farm.name,
          groupName: group.name,
          animalId: animal.id,
        );
        healthRecords.addAll(
          animalHealthRecords.map(
            (record) => AtlasExecutiveAnimalHealthContext(
              groupName: group.name,
              animalId: animal.id,
              animalLabel: animalLabel,
              record: record,
            ),
          ),
        );

        final animalReproductionRecords =
            await reproductionStorage.loadRecords(
          farmName: farm.name,
          groupName: group.name,
          animalId: animal.id,
        );
        reproductionRecords.addAll(
          animalReproductionRecords.map(
            (record) => AtlasExecutiveAnimalReproductionContext(
              groupName: group.name,
              animalId: animal.id,
              animalLabel: animalLabel,
              record: record,
            ),
          ),
        );
      }
    }

    final intelligence =
        farmIntelligenceService.analyze(
      farm: farm,
      animals: animals,
      groups: groups,
      paddocks: paddocks,
      financeRecords: financeRecords,
      inventoryItems: inventoryItems,
      agendaTasks: agendaTasks,
    );

    final diagnostic =
        diagnosticService.buildFarmDiagnostic(
      farm: intelligence,
    );

    return AtlasExecutiveFarmAlertInput(
      farmName: farm.name,
      intelligence: intelligence,
      diagnostic: diagnostic,
      trackedActions: trackedActions,
      healthRecords: healthRecords,
      reproductionRecords: reproductionRecords,
    );
  }
}

class AtlasExecutiveAlertLoadResult {
  const AtlasExecutiveAlertLoadResult({
    required this.farms,
    required this.inputs,
  });

  final List<FarmData> farms;

  final List<AtlasExecutiveFarmAlertInput>
      inputs;
}
