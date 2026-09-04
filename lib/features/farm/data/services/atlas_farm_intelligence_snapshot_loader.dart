import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_farm_context.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/services/atlas_ai_context_service.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/diagnostics/domain/services/atlas_diagnostic_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_storage_service.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';
import 'package:projeto_atlas/features/predictive/domain/services/atlas_predictive_service.dart';

typedef AtlasFarmSnapshotListLoader<T> =
    Future<List<T>> Function(FarmData farm);

/// Dados consistentes usados pelas experiências de Inteligência da fazenda.
///
/// O carregador é deliberadamente independente de widgets: uma mesma
/// fotografia dos dados pode ser consumida pelo detalhe da fazenda, pela
/// Central de Inteligência ou por uma exportação, sem cada tela reconstruir
/// diagnóstico e contexto conversacional à sua maneira.
class AtlasFarmIntelligenceSnapshot {
  const AtlasFarmIntelligenceSnapshot({
    required this.groups,
    required this.paddocks,
    required this.animals,
    required this.financeRecords,
    required this.inventoryItems,
    required this.agendaTasks,
    required this.warnings,
    this.intelligence,
    this.diagnostic,
    this.aiContext,
  });

  final List<HerdGroupData> groups;
  final List<PaddockData> paddocks;
  final List<AnimalData> animals;
  final List<FarmFinanceData> financeRecords;
  final List<FarmInventoryData> inventoryItems;
  final List<FarmAgendaData> agendaTasks;
  final List<String> warnings;
  final AtlasFarmIntelligenceData? intelligence;
  final AtlasDiagnosticData? diagnostic;
  final AtlasAiFarmContext? aiContext;
}

class AtlasFarmIntelligenceSnapshotLoader {
  AtlasFarmIntelligenceSnapshotLoader({
    AtlasFarmSnapshotListLoader<HerdGroupData>? loadGroups,
    AtlasFarmSnapshotListLoader<PaddockData>? loadPaddocks,
    AtlasFarmSnapshotListLoader<AnimalData>? loadAnimals,
    AtlasFarmSnapshotListLoader<FarmFinanceData>? loadFinanceRecords,
    AtlasFarmSnapshotListLoader<FarmInventoryData>? loadInventoryItems,
    AtlasFarmSnapshotListLoader<FarmAgendaData>? loadAgendaTasks,
    AtlasFarmIntelligenceService? intelligenceService,
    AtlasDiagnosticService? diagnosticService,
    AtlasPredictiveService? predictiveService,
    AtlasAiContextService? aiContextService,
  }) : _loadGroups = loadGroups ?? _loadGroupsFromStorage,
       _loadPaddocks = loadPaddocks ?? _loadPaddocksFromStorage,
       _loadAnimals = loadAnimals ?? _loadAnimalsFromStorage,
       _loadFinanceRecords = loadFinanceRecords ?? _loadFinanceFromStorage,
       _loadInventoryItems = loadInventoryItems ?? _loadInventoryFromStorage,
       _loadAgendaTasks = loadAgendaTasks ?? _loadAgendaFromStorage,
       _intelligenceService =
           intelligenceService ?? const AtlasFarmIntelligenceService(),
       _diagnosticService = diagnosticService ?? const AtlasDiagnosticService(),
       _predictiveService = predictiveService ?? const AtlasPredictiveService(),
       _aiContextService = aiContextService ?? const AtlasAiContextService();

  final AtlasFarmSnapshotListLoader<HerdGroupData> _loadGroups;
  final AtlasFarmSnapshotListLoader<PaddockData> _loadPaddocks;
  final AtlasFarmSnapshotListLoader<AnimalData> _loadAnimals;
  final AtlasFarmSnapshotListLoader<FarmFinanceData> _loadFinanceRecords;
  final AtlasFarmSnapshotListLoader<FarmInventoryData> _loadInventoryItems;
  final AtlasFarmSnapshotListLoader<FarmAgendaData> _loadAgendaTasks;
  final AtlasFarmIntelligenceService _intelligenceService;
  final AtlasDiagnosticService _diagnosticService;
  final AtlasPredictiveService _predictiveService;
  final AtlasAiContextService _aiContextService;

  Future<AtlasFarmIntelligenceSnapshot> load(FarmData farm) async {
    final warnings = <String>[];
    final results = await Future.wait<dynamic>([
      _loadSafely('lotes', () => _loadGroups(farm), warnings),
      _loadSafely('piquetes', () => _loadPaddocks(farm), warnings),
      _loadSafely('financeiro', () => _loadFinanceRecords(farm), warnings),
      _loadSafely('estoque', () => _loadInventoryItems(farm), warnings),
      _loadSafely('agenda', () => _loadAgendaTasks(farm), warnings),
    ]);

    final groups = results[0] as List<HerdGroupData>;
    final paddocks = results[1] as List<PaddockData>;
    final financeRecords = results[2] as List<FarmFinanceData>;
    final inventoryItems = results[3] as List<FarmInventoryData>;
    final agendaTasks = results[4] as List<FarmAgendaData>
      ..sort(_compareAgendaTasks);
    final animals = await _loadSafely(
      'animais',
      () => _loadAnimals(farm),
      warnings,
    );

    AtlasFarmIntelligenceData? intelligence;
    AtlasDiagnosticData? diagnostic;
    AtlasAiFarmContext? aiContext;
    try {
      intelligence = _intelligenceService.analyze(
        farm: farm,
        animals: animals,
        groups: groups,
        paddocks: paddocks,
        financeRecords: financeRecords,
        inventoryItems: inventoryItems,
        agendaTasks: agendaTasks,
      );
      diagnostic = _diagnosticService.buildFarmDiagnostic(farm: intelligence);
      final scenarios = _predictiveService.buildRecommendedScenarios(
        diagnostic: diagnostic,
        farm: intelligence,
      );
      final ranking = _predictiveService.compareScenarios(
        diagnostic: diagnostic,
        farm: intelligence,
        requests: scenarios,
      );
      aiContext = _aiContextService.buildFarmContext(
        intelligence: intelligence,
        diagnostic: diagnostic,
        predictiveRanking: ranking,
      );
    } catch (_) {
      warnings.add('inteligência da fazenda');
    }

    return AtlasFarmIntelligenceSnapshot(
      groups: groups,
      paddocks: paddocks,
      animals: animals,
      financeRecords: financeRecords,
      inventoryItems: inventoryItems,
      agendaTasks: agendaTasks,
      warnings: List.unmodifiable(warnings.toSet()),
      intelligence: intelligence,
      diagnostic: diagnostic,
      aiContext: aiContext,
    );
  }

  static Future<List<T>> _loadSafely<T>(
    String label,
    Future<List<T>> Function() loader,
    List<String> warnings,
  ) async {
    try {
      return await loader();
    } catch (_) {
      warnings.add(label);
      return <T>[];
    }
  }

  static final HerdStorageService _herdStorage = HerdStorageService();
  static final PaddockStorageService _paddockStorage = PaddockStorageService();
  static final AnimalEnterpriseService _animalService =
      AnimalEnterpriseService();
  static final FarmFinanceStorageService _financeStorage =
      FarmFinanceStorageService();
  static final FarmInventoryStorageService _inventoryStorage =
      FarmInventoryStorageService();
  static final FarmAgendaStorageService _agendaStorage =
      FarmAgendaStorageService();

  static Future<List<HerdGroupData>> _loadGroupsFromStorage(FarmData farm) =>
      _herdStorage.loadGroups(farm.name, farmId: farm.id ?? '');

  static Future<List<PaddockData>> _loadPaddocksFromStorage(FarmData farm) =>
      _paddockStorage.loadPaddocks(farm.id ?? '');

  static Future<List<AnimalData>> _loadAnimalsFromStorage(FarmData farm) {
    final farmId = farm.id ?? '';
    return farmId.isEmpty
        ? Future<List<AnimalData>>.value(const [])
        : _animalService.listAnimals(farmId: farmId, lotId: '');
  }

  static Future<List<FarmFinanceData>> _loadFinanceFromStorage(FarmData farm) =>
      _financeStorage.loadRecords(farm.name, farmId: farm.id ?? '');

  static Future<List<FarmInventoryData>> _loadInventoryFromStorage(
    FarmData farm,
  ) => _inventoryStorage.loadItems(farm.name, farmId: farm.id ?? '');

  static Future<List<FarmAgendaData>> _loadAgendaFromStorage(FarmData farm) =>
      _agendaStorage.loadTasks(farm.name, farmId: farm.id ?? '');

  static int _compareAgendaTasks(FarmAgendaData first, FarmAgendaData second) {
    final firstDate = _parseDate(first.date) ?? DateTime(2100);
    final secondDate = _parseDate(second.date) ?? DateTime(2100);
    final dateComparison = firstDate.compareTo(secondDate);
    if (dateComparison != 0) return dateComparison;
    return _agendaTimeInMinutes(
      first.time,
    ).compareTo(_agendaTimeInMinutes(second.time));
  }

  static DateTime? _parseDate(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) return DateTime.tryParse(value.trim());
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  static int _agendaTimeInMinutes(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return 24 * 60;
    final hour = int.tryParse(parts[0]) ?? 24;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }
}
