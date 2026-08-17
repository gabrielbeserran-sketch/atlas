import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/diagnostics/domain/services/atlas_diagnostic_service.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_storage_service.dart';

class AtlasComparativeDiagnosticLoaderService {
  AtlasComparativeDiagnosticLoaderService({
    FarmStorageService? farmStorage,
    HerdStorageService? herdStorage,
    AnimalStorageService? animalStorage,
    PaddockStorageService? paddockStorage,
    FarmFinanceStorageService? financeStorage,
    FarmInventoryStorageService? inventoryStorage,
    FarmAgendaStorageService? agendaStorage,
    AtlasFarmIntelligenceService? farmIntelligenceService,
    AtlasDiagnosticService? diagnosticService,
  }) : farmStorage = farmStorage ?? FarmStorageService(),
       herdStorage = herdStorage ?? HerdStorageService(),
       animalStorage = animalStorage ?? AnimalStorageService(),
       paddockStorage = paddockStorage ?? PaddockStorageService(),
       financeStorage = financeStorage ?? FarmFinanceStorageService(),
       inventoryStorage = inventoryStorage ?? FarmInventoryStorageService(),
       agendaStorage = agendaStorage ?? FarmAgendaStorageService(),
       farmIntelligenceService =
           farmIntelligenceService ?? const AtlasFarmIntelligenceService(),
       diagnosticService = diagnosticService ?? const AtlasDiagnosticService();

  final FarmStorageService farmStorage;
  final HerdStorageService herdStorage;
  final AnimalStorageService animalStorage;
  final PaddockStorageService paddockStorage;
  final FarmFinanceStorageService financeStorage;
  final FarmInventoryStorageService inventoryStorage;
  final FarmAgendaStorageService agendaStorage;

  final AtlasFarmIntelligenceService farmIntelligenceService;

  final AtlasDiagnosticService diagnosticService;

  Future<AtlasComparativeDiagnosticLoadResult> load() async {
    final farms = await farmStorage.loadFarms();

    final diagnostics = await Future.wait(farms.map(_loadFarmDiagnostic));

    return AtlasComparativeDiagnosticLoadResult(
      farms: farms,
      diagnostics: diagnostics,
    );
  }

  Future<AtlasDiagnosticData> _loadFarmDiagnostic(FarmData farm) async {
    final groups = await herdStorage.loadGroups(farm.name);

    final paddocks = await paddockStorage.loadPaddocks(farm.id ?? '');

    final financeRecords = await financeStorage.loadRecords(farm.name);

    final inventoryItems = await inventoryStorage.loadItems(farm.name);

    final agendaTasks = await agendaStorage.loadTasks(farm.name);

    final animalLists = await Future.wait(
      groups.map((group) {
        return animalStorage.loadAnimals(
          farmName: farm.name,
          groupName: group.name,
        );
      }),
    );

    final animals = animalLists.expand((items) => items).toList();

    final intelligence = farmIntelligenceService.analyze(
      farm: farm,
      animals: animals,
      groups: groups,
      paddocks: paddocks,
      financeRecords: financeRecords,
      inventoryItems: inventoryItems,
      agendaTasks: agendaTasks,
    );

    return diagnosticService.buildFarmDiagnostic(farm: intelligence);
  }
}

class AtlasComparativeDiagnosticLoadResult {
  const AtlasComparativeDiagnosticLoadResult({
    required this.farms,
    required this.diagnostics,
  });

  final List<FarmData> farms;
  final List<AtlasDiagnosticData> diagnostics;
}
