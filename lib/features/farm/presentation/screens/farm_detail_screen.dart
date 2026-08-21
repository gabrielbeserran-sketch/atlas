import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/diagnostics/domain/services/atlas_diagnostic_service.dart';
import 'package:projeto_atlas/features/diagnostics/presentation/screens/atlas_diagnostic_screen.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_farm_context.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/services/atlas_ai_context_service.dart';
import 'package:projeto_atlas/features/atlas_ai/presentation/screens/atlas_ai_screen.dart';
import 'package:projeto_atlas/features/predictive/domain/services/atlas_predictive_service.dart';
import 'package:projeto_atlas/features/predictive/presentation/screens/atlas_predictive_screen.dart';
import 'package:projeto_atlas/features/copilot/presentation/screens/atlas_copilot_screen.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/atlas_farm_intelligence_screen.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/herd/presentation/screens/herd_overview_screen.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_storage_service.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';
import 'package:projeto_atlas/features/paddock/presentation/screens/paddock_list_screen.dart';
import 'package:projeto_atlas/features/livestock_operations/domain/models/atlas_livestock_module_snapshot.dart';
import 'package:projeto_atlas/features/livestock_operations/presentation/screens/atlas_livestock_module_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class FarmDetailScreen extends StatefulWidget {
  const FarmDetailScreen({required this.farm, super.key});

  final FarmData farm;

  @override
  State<FarmDetailScreen> createState() {
    return _FarmDetailScreenState();
  }
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  final HerdStorageService herdStorage = HerdStorageService();

  final AnimalEnterpriseService animalService = AnimalEnterpriseService();

  final PaddockStorageService paddockStorage = PaddockStorageService();

  final FarmFinanceStorageService financeStorage = FarmFinanceStorageService();

  final FarmInventoryStorageService inventoryStorage =
      FarmInventoryStorageService();

  final FarmAgendaStorageService agendaStorage = FarmAgendaStorageService();

  final AtlasFarmIntelligenceService intelligenceService =
      const AtlasFarmIntelligenceService();

  final AtlasDiagnosticService diagnosticService =
      const AtlasDiagnosticService();

  final AtlasPredictiveService predictiveService =
      const AtlasPredictiveService();

  final AtlasAiContextService aiContextService = const AtlasAiContextService();

  List<HerdGroupData> groups = [];
  List<PaddockData> paddocks = [];
  List<AnimalData> animals = [];
  List<FarmFinanceData> financeRecords = [];
  List<FarmInventoryData> inventoryItems = [];
  List<FarmAgendaData> agendaTasks = [];

  AtlasFarmIntelligenceData? intelligenceData;
  AtlasDiagnosticData? diagnosticData;
  AtlasAiFarmContext? aiContextData;

  bool isLoading = true;
  String? dashboardWarning;

  FarmData get farm => widget.farm;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  int get totalAnimals => animals.length;

  int get activeAnimals {
    return animals.where((animal) {
      return animal.status == 'Ativo';
    }).length;
  }

  int get females {
    return animals.where((animal) {
      return animal.sex == 'Fêmea';
    }).length;
  }

  int get males {
    return animals.where((animal) {
      return animal.sex == 'Macho';
    }).length;
  }

  double get averageWeight {
    final animalsWithWeight = animals.where((animal) {
      return animal.weight > 0;
    }).toList();

    if (animalsWithWeight.isEmpty) {
      return 0;
    }

    final totalWeight = animalsWithWeight.fold<double>(0, (total, animal) {
      return total + animal.weight;
    });

    return totalWeight / animalsWithWeight.length;
  }

  double get animalsPerHectare {
    if (farm.area <= 0) {
      return 0;
    }

    return totalAnimals / farm.area;
  }

  double get paddockArea {
    return paddocks.fold<double>(0, (total, paddock) {
      return total + paddock.area;
    });
  }

  int get paddocksInUse {
    return paddocks.where((paddock) {
      return paddock.animals > 0 || paddock.status == 'Em pastejo';
    }).length;
  }

  int get paddocksResting {
    return paddocks.where((paddock) {
      return paddock.status == 'Descanso';
    }).length;
  }

  double get totalIncome {
    return financeRecords.where((record) => record.isIncome).fold<double>(0, (
      total,
      record,
    ) {
      return total + record.amount;
    });
  }

  double get totalExpenses {
    return financeRecords.where((record) => record.isExpense).fold<double>(0, (
      total,
      record,
    ) {
      return total + record.amount;
    });
  }

  double get financialBalance {
    return totalIncome - totalExpenses;
  }

  double get expensePerAnimal {
    if (totalAnimals == 0) {
      return 0;
    }

    return totalExpenses / totalAnimals;
  }

  double get incomePerHectare {
    if (farm.area <= 0) {
      return 0;
    }

    return totalIncome / farm.area;
  }

  double get totalInventoryValue {
    return inventoryItems.fold<double>(0, (total, item) {
      return total + item.totalValue;
    });
  }

  int get lowStockCount {
    return inventoryItems.where((item) {
      return item.hasLowStock;
    }).length;
  }

  int get expiredInventoryCount {
    return inventoryItems.where((item) {
      return getExpirationStatus(item) == InventoryStatus.expired;
    }).length;
  }

  int get nearExpirationCount {
    return inventoryItems.where((item) {
      return getExpirationStatus(item) == InventoryStatus.nearExpiration;
    }).length;
  }

  int get inventoryAlertCount {
    final alertIds = <String>{};

    for (final item in inventoryItems) {
      final status = getExpirationStatus(item);

      if (item.hasLowStock ||
          status == InventoryStatus.expired ||
          status == InventoryStatus.nearExpiration) {
        alertIds.add(item.id);
      }
    }

    return alertIds.length;
  }

  int get agendaPendingCount {
    return agendaTasks.where((task) {
      return task.status == 'Pendente' || task.status == 'Em andamento';
    }).length;
  }

  int get agendaCompletedCount {
    return agendaTasks.where((task) {
      return task.status == 'Concluída';
    }).length;
  }

  int get agendaTodayCount {
    return agendaTasks.where(isAgendaToday).length;
  }

  int get agendaOverdueCount {
    return agendaTasks.where(isAgendaOverdue).length;
  }

  int get agendaUrgentCount {
    return agendaTasks.where((task) {
      return task.priority == 'Urgente' &&
          !task.isCompleted &&
          !task.isCancelled;
    }).length;
  }

  int get agendaAlertCount {
    final alertIds = <String>{};

    for (final task in agendaTasks) {
      if (isAgendaOverdue(task) ||
          (task.priority == 'Urgente' &&
              !task.isCompleted &&
              !task.isCancelled)) {
        alertIds.add(task.id);
      }
    }

    return alertIds.length;
  }

  int get totalDashboardAlerts {
    return inventoryAlertCount + agendaAlertCount;
  }

  List<FarmAgendaData> get nextAgendaTasks {
    final availableTasks = agendaTasks.where((task) {
      return !task.isCompleted && !task.isCancelled;
    }).toList();

    availableTasks.sort(compareAgendaTasks);

    return availableTasks.take(3).toList();
  }

  Future<List<T>> _loadSafely<T>({
    required String label,
    required Future<List<T>> Function() loader,
    required List<String> warnings,
  }) async {
    try {
      return await loader();
    } catch (_) {
      warnings.add(label);
      return <T>[];
    }
  }

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        dashboardWarning = null;
      });
    }

    final warnings = <String>[];

    try {
      final results = await Future.wait<dynamic>([
        _loadSafely<HerdGroupData>(
          label: 'lotes',
          loader: () => herdStorage.loadGroups(farm.name, farmId: farm.id ?? ''),
          warnings: warnings,
        ),
        _loadSafely<PaddockData>(
          label: 'piquetes',
          loader: () => paddockStorage.loadPaddocks(farm.id ?? ''),
          warnings: warnings,
        ),
        _loadSafely<FarmFinanceData>(
          label: 'financeiro',
          loader: () => financeStorage.loadRecords(farm.name, farmId: farm.id ?? ''),
          warnings: warnings,
        ),
        _loadSafely<FarmInventoryData>(
          label: 'estoque',
          loader: () => inventoryStorage.loadItems(farm.name, farmId: farm.id ?? ''),
          warnings: warnings,
        ),
        _loadSafely<FarmAgendaData>(
          label: 'agenda',
          loader: () => agendaStorage.loadTasks(farm.name, farmId: farm.id ?? ''),
          warnings: warnings,
        ),
      ]);

      final loadedGroups = results[0] as List<HerdGroupData>;
      final loadedPaddocks = results[1] as List<PaddockData>;
      final loadedFinanceRecords = results[2] as List<FarmFinanceData>;
      final loadedInventoryItems = results[3] as List<FarmInventoryData>;
      final loadedAgendaTasks = results[4] as List<FarmAgendaData>;

      loadedAgendaTasks.sort(compareAgendaTasks);

      List<AnimalData> loadedAnimals;
      try {
        final farmId = farm.id ?? '';
        loadedAnimals = farmId.isEmpty
            ? <AnimalData>[]
            : await animalService.listAnimals(farmId: farmId, lotId: '');
      } catch (_) {
        warnings.add('animais');
        loadedAnimals = <AnimalData>[];
      }

      AtlasFarmIntelligenceData? farmIntelligence;
      AtlasDiagnosticData? farmDiagnostic;
      AtlasAiFarmContext? farmAiContext;

      try {
        farmIntelligence = intelligenceService.analyze(
          farm: farm,
          animals: loadedAnimals,
          groups: loadedGroups,
          paddocks: loadedPaddocks,
          financeRecords: loadedFinanceRecords,
          inventoryItems: loadedInventoryItems,
          agendaTasks: loadedAgendaTasks,
        );

        farmDiagnostic = diagnosticService.buildFarmDiagnostic(
          farm: farmIntelligence,
        );

        final recommendedPredictiveScenarios = predictiveService
            .buildRecommendedScenarios(
              diagnostic: farmDiagnostic,
              farm: farmIntelligence,
            );

        final predictiveRanking = predictiveService.compareScenarios(
          diagnostic: farmDiagnostic,
          farm: farmIntelligence,
          requests: recommendedPredictiveScenarios,
        );

        farmAiContext = aiContextService.buildFarmContext(
          intelligence: farmIntelligence,
          diagnostic: farmDiagnostic,
          predictiveRanking: predictiveRanking,
        );
      } catch (_) {
        warnings.add('inteligência da fazenda');
      }

      if (!mounted) return;

      setState(() {
        groups = loadedGroups;
        paddocks = loadedPaddocks;
        animals = loadedAnimals;
        financeRecords = loadedFinanceRecords;
        inventoryItems = loadedInventoryItems;
        agendaTasks = loadedAgendaTasks;
        intelligenceData = farmIntelligence;
        diagnosticData = farmDiagnostic;
        aiContextData = farmAiContext;
        dashboardWarning = warnings.isEmpty
            ? null
            : 'A fazenda foi aberta, mas alguns dados não responderam: '
                  '${warnings.toSet().join(', ')}. Use Atualizar para tentar novamente.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        dashboardWarning =
            'A fazenda foi aberta com dados parciais. Falha ao atualizar o painel: $error';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openPaddocks() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return PaddockListScreen(farm: farm);
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openHerd() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HerdOverviewScreen()),
    );
    await loadDashboard();
  }

  Future<void> openFinance() =>
      _openOfficialLivestockModule(AtlasLivestockModule.finance);

  Future<void> openInventory() =>
      _openOfficialLivestockModule(AtlasLivestockModule.inventory);

  Future<void> _openOfficialLivestockModule(AtlasLivestockModule module) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AtlasLivestockModuleScreen(module: module),
      ),
    );
    await loadDashboard();
  }

  Future<void> openAgenda() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return FarmAgendaListScreen(farm: farm);
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openReproduction() =>
      _openOfficialLivestockModule(AtlasLivestockModule.reproduction);

  Future<void> openHealth() =>
      _openOfficialLivestockModule(AtlasLivestockModule.health);

  Future<void> openNutrition() =>
      _openOfficialLivestockModule(AtlasLivestockModule.nutrition);

  Future<void> openAtlasAi() async {
    final aiContext = aiContextData;

    if (aiContext == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O contexto do Atlas IA ainda está sendo preparado.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          void closeAndOpen(Future<void> Function() openModule) {
            Navigator.of(screenContext).pop();
            openModule();
          }

          return AtlasAiScreen(
            contextData: aiContext,
            onOpenDiagnostic: () {
              closeAndOpen(openDiagnostic);
            },
            onOpenPredictive: () {
              closeAndOpen(openPredictiveIntelligence);
            },
            onOpenFinance: () {
              closeAndOpen(openFinance);
            },
            onOpenHerd: () {
              closeAndOpen(openHerd);
            },
            onOpenPaddocks: () {
              closeAndOpen(openPaddocks);
            },
            onOpenInventory: () {
              closeAndOpen(openInventory);
            },
            onOpenAgenda: () {
              closeAndOpen(openAgenda);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openPredictiveIntelligence() async {
    final intelligence = intelligenceData;

    final diagnostic = diagnosticData;

    if (intelligence == null || diagnostic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A Inteligência Preditiva ainda está sendo preparada.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasPredictiveScreen(
            diagnostic: diagnostic,
            farmIntelligence: intelligence,
            onOpenArea: (area) {
              Navigator.of(screenContext).pop();

              switch (area) {
                case AtlasFarmAnalysisArea.finance:
                  openFinance();
                  break;

                case AtlasFarmAnalysisArea.herd:
                  openHerd();
                  break;

                case AtlasFarmAnalysisArea.paddock:
                  openPaddocks();
                  break;

                case AtlasFarmAnalysisArea.inventory:
                  openInventory();
                  break;

                case AtlasFarmAnalysisArea.agenda:
                  openAgenda();
                  break;

                case AtlasFarmAnalysisArea.general:
                  break;
              }
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openDiagnostic() async {
    final data = diagnosticData;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O Diagnóstico Inteligente ainda está sendo preparado.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasDiagnosticScreen(
            data: data,
            onOpenArea: (area) {
              Navigator.of(screenContext).pop();

              switch (area) {
                case AtlasFarmAnalysisArea.finance:
                  openFinance();
                  break;

                case AtlasFarmAnalysisArea.herd:
                  openHerd();
                  break;

                case AtlasFarmAnalysisArea.paddock:
                  openPaddocks();
                  break;

                case AtlasFarmAnalysisArea.inventory:
                  openInventory();
                  break;

                case AtlasFarmAnalysisArea.agenda:
                  openAgenda();
                  break;

                case AtlasFarmAnalysisArea.general:
                  break;
              }
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openFarmIntelligence() async {
    final data = intelligenceData;

    if (data == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasFarmIntelligenceScreen(
            data: data,
            onOpenCopilot: () {
              Navigator.of(screenContext).push(
                MaterialPageRoute<void>(
                  builder: (copilotContext) {
                    return AtlasCopilotScreen(
                      farmIntelligence: data,
                      consultantName: 'Gabriel',
                      onOpenFarmIntelligence: () {
                        Navigator.of(copilotContext).pop();
                      },
                      onOpenFarm: () {
                        Navigator.of(copilotContext).pop();
                      },
                      onOpenFinance: () {
                        Navigator.of(copilotContext).pop();
                        Navigator.of(screenContext).pop();
                        openFinance();
                      },
                      onOpenHerd: () {
                        Navigator.of(copilotContext).pop();
                        Navigator.of(screenContext).pop();
                        openHerd();
                      },
                      onOpenPaddocks: () {
                        Navigator.of(copilotContext).pop();
                        Navigator.of(screenContext).pop();
                        openPaddocks();
                      },
                      onOpenInventory: () {
                        Navigator.of(copilotContext).pop();
                        Navigator.of(screenContext).pop();
                        openInventory();
                      },
                      onOpenAgenda: () {
                        Navigator.of(copilotContext).pop();
                        Navigator.of(screenContext).pop();
                        openAgenda();
                      },
                    );
                  },
                ),
              );
            },
            onOpenFinance: () {
              Navigator.of(screenContext).pop();
              openFinance();
            },
            onOpenHerd: () {
              Navigator.of(screenContext).pop();
              openHerd();
            },
            onOpenPaddocks: () {
              Navigator.of(screenContext).pop();
              openPaddocks();
            },
            onOpenInventory: () {
              Navigator.of(screenContext).pop();
              openInventory();
            },
            onOpenAgenda: () {
              Navigator.of(screenContext).pop();
              openAgenda();
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openFarmCopilot() async {
    final data = intelligenceData;

    if (data == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasCopilotScreen(
            farmIntelligence: data,
            consultantName: 'Gabriel',
            onOpenFarmIntelligence: () {
              Navigator.of(screenContext).pop();
              openFarmIntelligence();
            },
            onOpenFarm: () {
              Navigator.of(screenContext).pop();
            },
            onOpenFinance: () {
              Navigator.of(screenContext).pop();
              openFinance();
            },
            onOpenHerd: () {
              Navigator.of(screenContext).pop();
              openHerd();
            },
            onOpenPaddocks: () {
              Navigator.of(screenContext).pop();
              openPaddocks();
            },
            onOpenInventory: () {
              Navigator.of(screenContext).pop();
              openInventory();
            },
            onOpenAgenda: () {
              Navigator.of(screenContext).pop();
              openAgenda();
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  void showComingSoon(String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'O módulo $moduleName será desenvolvido '
          'nas próximas etapas.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(farm.name),
        actions: [
          IconButton(
            tooltip: 'Conversar com Atlas IA',
            onPressed: isLoading || aiContextData == null ? null : openAtlasAi,
            icon: const Icon(Icons.psychology_outlined),
          ),
          IconButton(
            tooltip: 'Simular Decisões',
            onPressed:
                isLoading || intelligenceData == null || diagnosticData == null
                ? null
                : openPredictiveIntelligence,
            icon: const Icon(Icons.auto_graph_outlined),
          ),
          IconButton(
            tooltip: 'Diagnóstico Inteligente',
            onPressed: isLoading || diagnosticData == null
                ? null
                : openDiagnostic,
            icon: const Icon(Icons.health_and_safety_outlined),
          ),
          IconButton(
            tooltip: 'Copiloto Atlas',
            onPressed: isLoading || intelligenceData == null
                ? null
                : openFarmCopilot,
            icon: const Icon(Icons.smart_toy_outlined),
          ),
          IconButton(
            tooltip: 'Inteligência da Fazenda',
            onPressed: isLoading || intelligenceData == null
                ? null
                : openFarmIntelligence,
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: isLoading ? null : loadDashboard,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadDashboard,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        if (dashboardWarning != null) ...[
                          Card(
                            color: const Color(0xFFFFF8E1),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF8A6D1D),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      dashboardWarning!,
                                      style: const TextStyle(
                                        color: Color(0xFF5D4A12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        FarmDashboardHeader(
                          farm: farm,
                          totalAnimals: totalAnimals,
                          totalGroups: groups.length,
                          financialBalance: financialBalance,
                          totalAlerts: totalDashboardAlerts,
                          todayTasks: agendaTodayCount,
                        ),
                        const SizedBox(height: 24),
                        if (aiContextData != null)
                          FarmAtlasAiAccessCard(
                            contextData: aiContextData!,
                            onOpen: openAtlasAi,
                          ),
                        if (aiContextData != null) const SizedBox(height: 16),
                        if (intelligenceData != null && diagnosticData != null)
                          FarmPredictiveAccessCard(
                            diagnostic: diagnosticData!,
                            intelligence: intelligenceData!,
                            onOpen: openPredictiveIntelligence,
                          ),
                        if (intelligenceData != null && diagnosticData != null)
                          const SizedBox(height: 16),
                        if (diagnosticData != null)
                          FarmDiagnosticAccessCard(
                            data: diagnosticData!,
                            onOpen: openDiagnostic,
                          ),
                        if (diagnosticData != null) const SizedBox(height: 16),
                        if (intelligenceData != null)
                          FarmIntelligenceAccessCard(
                            data: intelligenceData!,
                            onOpenIntelligence: openFarmIntelligence,
                            onOpenCopilot: openFarmCopilot,
                          ),
                        if (intelligenceData != null)
                          const SizedBox(height: 28),
                        const SectionTitle(
                          title: 'Indicadores da propriedade',
                          subtitle:
                              'Dados calculados com base nos cadastros realizados no Atlas.',
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            DashboardMetricCard(
                              title: 'Animais cadastrados',
                              value: totalAnimals.toString(),
                              subtitle: totalAnimals == 0
                                  ? 'Nenhum animal individual'
                                  : 'Distribuídos em '
                                        '${groups.length} lotes',
                              icon: AtlasLivestockIcons.cow,
                            ),
                            DashboardMetricCard(
                              title: 'Animais ativos',
                              value: activeAnimals.toString(),
                              subtitle: totalAnimals == 0
                                  ? 'Nenhum animal cadastrado'
                                  : '${calculatePercentage(activeAnimals, totalAnimals)}% do rebanho',
                              icon: Icons.check_circle_outline,
                            ),
                            DashboardMetricCard(
                              title: 'Peso médio',
                              value: totalAnimals == 0
                                  ? '—'
                                  : '${formatNumber(averageWeight)} kg',
                              subtitle: 'Média dos animais individuais',
                              icon: Icons.monitor_weight_outlined,
                            ),
                            DashboardMetricCard(
                              title: 'Animais por hectare',
                              value: totalAnimals == 0
                                  ? '0'
                                  : formatNumber(animalsPerHectare),
                              subtitle:
                                  '${formatNumber(farm.area.toDouble())} ha de área total',
                              icon: Icons.landscape_outlined,
                            ),
                            DashboardMetricCard(
                              title: 'Lotes',
                              value: groups.length.toString(),
                              subtitle: groups.isEmpty
                                  ? 'Nenhum lote cadastrado'
                                  : 'Grupos de manejo',
                              icon: Icons.groups_outlined,
                            ),
                            DashboardMetricCard(
                              title: 'Piquetes',
                              value: paddocks.length.toString(),
                              subtitle: paddocks.isEmpty
                                  ? 'Nenhum piquete cadastrado'
                                  : '${formatNumber(paddockArea)} ha cadastrados',
                              icon: Icons.grid_view_outlined,
                            ),
                            DashboardMetricCard(
                              title: 'Fêmeas',
                              value: females.toString(),
                              subtitle: totalAnimals == 0
                                  ? 'Nenhum animal cadastrado'
                                  : '${calculatePercentage(females, totalAnimals)}% do rebanho',
                              icon: Icons.female_outlined,
                            ),
                            DashboardMetricCard(
                              title: 'Machos',
                              value: males.toString(),
                              subtitle: totalAnimals == 0
                                  ? 'Nenhum animal cadastrado'
                                  : '${calculatePercentage(males, totalAnimals)}% do rebanho',
                              icon: Icons.male_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const SectionTitle(
                          title: 'Indicadores financeiros',
                          subtitle:
                              'Receitas, despesas e resultado da propriedade.',
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ColoredMetricCard(
                              title: 'Receitas',
                              value: formatCurrency(totalIncome),
                              subtitle: 'Entradas financeiras',
                              icon: Icons.trending_up_outlined,
                              color: const Color(0xFF1B5E20),
                            ),
                            ColoredMetricCard(
                              title: 'Despesas',
                              value: formatCurrency(totalExpenses),
                              subtitle: 'Saídas financeiras',
                              icon: Icons.trending_down_outlined,
                              color: Colors.red.shade700,
                            ),
                            ColoredMetricCard(
                              title: 'Saldo',
                              value: formatCurrency(financialBalance),
                              subtitle: financialBalance >= 0
                                  ? 'Resultado positivo'
                                  : 'Resultado negativo',
                              icon: Icons.account_balance_wallet_outlined,
                              color: financialBalance >= 0
                                  ? const Color(0xFF1B5E20)
                                  : Colors.red.shade700,
                            ),
                            ColoredMetricCard(
                              title: 'Despesa por animal',
                              value: totalAnimals == 0
                                  ? '—'
                                  : formatCurrency(expensePerAnimal),
                              subtitle: 'Custo médio cadastrado',
                              icon: AtlasLivestockIcons.cow,
                              color: const Color(0xFFEF6C00),
                            ),
                            ColoredMetricCard(
                              title: 'Receita por hectare',
                              value: farm.area <= 0
                                  ? '—'
                                  : formatCurrency(incomePerHectare),
                              subtitle: 'Receita sobre a área total',
                              icon: Icons.landscape_outlined,
                              color: const Color(0xFF6A1B9A),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const SectionTitle(
                          title: 'Indicadores de estoque',
                          subtitle: 'Produtos, valores, quantidades e alertas.',
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ColoredMetricCard(
                              title: 'Produtos',
                              value: inventoryItems.length.toString(),
                              subtitle: 'Itens cadastrados',
                              icon: Icons.inventory_2_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            ColoredMetricCard(
                              title: 'Valor do estoque',
                              value: formatCurrency(totalInventoryValue),
                              subtitle: 'Valor estimado atual',
                              icon: Icons.account_balance_wallet_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            ColoredMetricCard(
                              title: 'Estoque baixo',
                              value: lowStockCount.toString(),
                              subtitle: 'Produtos no mínimo ou abaixo',
                              icon: Icons.warning_amber_outlined,
                              color: lowStockCount > 0
                                  ? const Color(0xFFEF6C00)
                                  : const Color(0xFF1B5E20),
                            ),
                            ColoredMetricCard(
                              title: 'Vencidos',
                              value: expiredInventoryCount.toString(),
                              subtitle: 'Produtos fora da validade',
                              icon: Icons.event_busy_outlined,
                              color: expiredInventoryCount > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                            ColoredMetricCard(
                              title: 'Vencimento próximo',
                              value: nearExpirationCount.toString(),
                              subtitle: 'Validade em até 30 dias',
                              icon: Icons.schedule_outlined,
                              color: nearExpirationCount > 0
                                  ? const Color(0xFFEF6C00)
                                  : const Color(0xFF1B5E20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const SectionTitle(
                          title: 'Indicadores da agenda',
                          subtitle:
                              'Compromissos, tarefas e atividades da propriedade.',
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ColoredMetricCard(
                              title: 'Compromissos',
                              value: agendaTasks.length.toString(),
                              subtitle: 'Atividades cadastradas',
                              icon: Icons.calendar_month_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            ColoredMetricCard(
                              title: 'Hoje',
                              value: agendaTodayCount.toString(),
                              subtitle: 'Atividades programadas para hoje',
                              icon: Icons.today_outlined,
                              color: agendaTodayCount > 0
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFF1B5E20),
                            ),
                            ColoredMetricCard(
                              title: 'Pendentes',
                              value: agendaPendingCount.toString(),
                              subtitle: 'Tarefas ainda não concluídas',
                              icon: Icons.schedule_outlined,
                              color: agendaPendingCount > 0
                                  ? const Color(0xFFEF6C00)
                                  : const Color(0xFF1B5E20),
                            ),
                            ColoredMetricCard(
                              title: 'Atrasadas',
                              value: agendaOverdueCount.toString(),
                              subtitle: 'Compromissos fora do prazo',
                              icon: Icons.warning_amber_outlined,
                              color: agendaOverdueCount > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                            ColoredMetricCard(
                              title: 'Urgentes',
                              value: agendaUrgentCount.toString(),
                              subtitle: 'Prioridades urgentes abertas',
                              icon: Icons.priority_high,
                              color: agendaUrgentCount > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                            ColoredMetricCard(
                              title: 'Concluídas',
                              value: agendaCompletedCount.toString(),
                              subtitle: 'Tarefas finalizadas',
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF1B5E20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        FarmAlertsCard(
                          totalAnimals: totalAnimals,
                          farmRegisteredAnimals: farm.animals,
                          inventoryAlerts: inventoryAlertCount,
                          lowStockCount: lowStockCount,
                          expiredCount: expiredInventoryCount,
                          nearExpirationCount: nearExpirationCount,
                          agendaAlerts: agendaAlertCount,
                          overdueTasks: agendaOverdueCount,
                          urgentTasks: agendaUrgentCount,
                          todayTasks: agendaTodayCount,
                        ),
                        const SizedBox(height: 32),
                        const SectionTitle(
                          title: 'Próximas atividades',
                          subtitle:
                              'Compromissos pendentes organizados por data.',
                        ),
                        const SizedBox(height: 18),
                        AgendaPreviewCard(
                          tasks: nextAgendaTasks,
                          onOpen: openAgenda,
                        ),
                        const SizedBox(height: 32),
                        const SectionTitle(
                          title: 'Gestão da propriedade',
                          subtitle:
                              'Acesse os módulos operacionais e gerenciais.',
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 850
                                ? 3
                                : constraints.maxWidth >= 550
                                ? 2
                                : 1;

                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: columns == 1 ? 3.4 : 1.8,
                              children: [
                                FarmModuleCard(
                                  title: 'Piquetes',
                                  subtitle: '${paddocks.length} cadastrados',
                                  icon: Icons.grid_view_outlined,
                                  onTap: openPaddocks,
                                ),
                                FarmModuleCard(
                                  title: 'Rebanho',
                                  subtitle:
                                      '$totalAnimals animais em '
                                      '${groups.length} lotes',
                                  icon: AtlasLivestockIcons.cow,
                                  onTap: openHerd,
                                ),
                                FarmModuleCard(
                                  title: 'Financeiro',
                                  subtitle:
                                      '${financeRecords.length} '
                                      'lançamentos · '
                                      '${formatCompactCurrency(financialBalance)}',
                                  icon: Icons.account_balance_wallet_outlined,
                                  onTap: openFinance,
                                ),
                                FarmModuleCard(
                                  title: 'Estoque',
                                  subtitle:
                                      '${inventoryItems.length} produtos · '
                                      '$inventoryAlertCount alertas',
                                  icon: Icons.inventory_2_outlined,
                                  onTap: openInventory,
                                ),
                                FarmModuleCard(
                                  title: 'Agenda',
                                  subtitle:
                                      '${agendaTasks.length} compromissos · '
                                      '$agendaAlertCount alertas',
                                  icon: Icons.calendar_month_outlined,
                                  onTap: openAgenda,
                                ),
                                FarmModuleCard(
                                  title: 'Reprodução',
                                  subtitle:
                                      'Histórico, IATF, diagnósticos e indicadores',
                                  icon: Icons.favorite_outline,
                                  onTap: openReproduction,
                                ),
                                FarmModuleCard(
                                  title: 'Sanidade',
                                  subtitle:
                                      'Histórico clínico, tratamentos e alertas',
                                  icon: Icons.medical_services_outlined,
                                  onTap: openHealth,
                                ),
                                FarmModuleCard(
                                  title: 'Nutrição',
                                  subtitle:
                                      'Dietas, consumo, desempenho e custos',
                                  icon: Icons.grass_outlined,
                                  onTap: openNutrition,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        OverviewCard(
                          title: 'Visão dos piquetes',
                          subtitle: 'Resumo das áreas de manejo cadastradas.',
                          icon: Icons.grid_view_outlined,
                          onTap: openPaddocks,
                          metrics: [
                            OverviewData(
                              label: 'Total',
                              value: paddocks.length.toString(),
                            ),
                            OverviewData(
                              label: 'Em uso',
                              value: paddocksInUse.toString(),
                            ),
                            OverviewData(
                              label: 'Descanso',
                              value: paddocksResting.toString(),
                            ),
                            OverviewData(
                              label: 'Área',
                              value: '${formatNumber(paddockArea)} ha',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        OverviewCard(
                          title: 'Visão financeira',
                          subtitle: 'Resumo das receitas e despesas.',
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: openFinance,
                          metrics: [
                            OverviewData(
                              label: 'Receitas',
                              value: formatCompactCurrency(totalIncome),
                            ),
                            OverviewData(
                              label: 'Despesas',
                              value: formatCompactCurrency(totalExpenses),
                            ),
                            OverviewData(
                              label: 'Saldo',
                              value: formatCompactCurrency(financialBalance),
                            ),
                            OverviewData(
                              label: 'Registros',
                              value: financeRecords.length.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        OverviewCard(
                          title: 'Visão do estoque',
                          subtitle: 'Resumo dos produtos e alertas.',
                          icon: Icons.inventory_2_outlined,
                          onTap: openInventory,
                          metrics: [
                            OverviewData(
                              label: 'Produtos',
                              value: inventoryItems.length.toString(),
                            ),
                            OverviewData(
                              label: 'Valor',
                              value: formatCompactCurrency(totalInventoryValue),
                            ),
                            OverviewData(
                              label: 'Estoque baixo',
                              value: lowStockCount.toString(),
                            ),
                            OverviewData(
                              label: 'Alertas',
                              value: inventoryAlertCount.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        OverviewCard(
                          title: 'Visão da agenda',
                          subtitle: 'Resumo das tarefas e compromissos.',
                          icon: Icons.calendar_month_outlined,
                          onTap: openAgenda,
                          metrics: [
                            OverviewData(
                              label: 'Hoje',
                              value: agendaTodayCount.toString(),
                            ),
                            OverviewData(
                              label: 'Pendentes',
                              value: agendaPendingCount.toString(),
                            ),
                            OverviewData(
                              label: 'Atrasadas',
                              value: agendaOverdueCount.toString(),
                            ),
                            OverviewData(
                              label: 'Urgentes',
                              value: agendaUrgentCount.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class FarmAtlasAiAccessCard extends StatelessWidget {
  const FarmAtlasAiAccessCard({
    required this.contextData,
    required this.onOpen,
    super.key,
  });

  final AtlasAiFarmContext contextData;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _farmAtlasAiLevelColor(contextData.level);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A173D), Color(0xFF3E2457), Color(0xFF51336D)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          color: color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atlas IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Consultor inteligente da propriedade',
                              style: TextStyle(
                                color: Color(0xFFD7C1E8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    contextData.simpleSummary,
                    maxLines: compact ? 7 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.48),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      'Pergunte: "${contextData.suggestedQuestions.isEmpty ? 'Qual é a prioridade da fazenda?' : contextData.suggestedQuestions.first}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE4C86A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FarmAtlasAiChip(
                        label: 'Score',
                        value: contextData.score.toStringAsFixed(0),
                      ),
                      _FarmAtlasAiChip(
                        label: 'Riscos',
                        value: contextData.risks.length,
                      ),
                      _FarmAtlasAiChip(
                        label: 'Cenários',
                        value: contextData.predictiveScenarios.length,
                      ),
                      _FarmAtlasAiChip(
                        label: 'Perguntas',
                        value: contextData.suggestedQuestions.length,
                      ),
                    ],
                  ),
                ],
              );

              final button = FilledButton.icon(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE4C86A),
                  foregroundColor: const Color(0xFF2A173D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.chat_outlined),
                label: const Text(
                  'Conversar com Atlas IA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), button],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FarmAtlasAiChip extends StatelessWidget {
  const _FarmAtlasAiChip({required this.label, required this.value});

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _farmAtlasAiLevelColor(AtlasDiagnosticLevel level) {
  switch (level) {
    case AtlasDiagnosticLevel.excellent:
      return const Color(0xFF81C784);

    case AtlasDiagnosticLevel.stable:
      return const Color(0xFFA5D6A7);

    case AtlasDiagnosticLevel.attention:
      return const Color(0xFFFFCC80);

    case AtlasDiagnosticLevel.critical:
      return const Color(0xFFEF9A9A);
  }
}

class FarmPredictiveAccessCard extends StatelessWidget {
  const FarmPredictiveAccessCard({
    required this.diagnostic,
    required this.intelligence,
    required this.onOpen,
    super.key,
  });

  final AtlasDiagnosticData diagnostic;

  final AtlasFarmIntelligenceData intelligence;

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final recommendedCount = _recommendedScenarioCount(intelligence);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF102A43), Color(0xFF243B53), Color(0xFF334E68)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_graph_outlined,
                        color: Color(0xFFC8A951),
                        size: 31,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Inteligência Preditiva',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  const Text(
                    'Simule decisões antes de executá-las e compare impacto, risco, esforço e retorno financeiro.',
                    style: TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      _FarmPredictiveChip(
                        label: 'Cenários',
                        value: recommendedCount,
                        icon: Icons.tune_outlined,
                      ),
                      _FarmPredictiveChip(
                        label: 'Score atual',
                        value: diagnostic.score.toStringAsFixed(0),
                        icon: Icons.speed_outlined,
                      ),
                      _FarmPredictiveChip(
                        label: 'Riscos',
                        value: diagnostic.risks.length,
                        icon: Icons.warning_amber_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      recommendedCount == 0
                          ? 'Cadastre mais dados para gerar cenários automáticos.'
                          : '$recommendedCount cenários podem ser comparados para encontrar a melhor decisão.',
                      style: const TextStyle(
                        color: Color(0xFFC8A951),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );

              final button = FilledButton.icon(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC8A951),
                  foregroundColor: const Color(0xFF263238),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text(
                  'Simular decisões',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), button],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  int _recommendedScenarioCount(AtlasFarmIntelligenceData data) {
    var count = 0;

    if (data.finance.totalExpenses > 0) {
      count++;
    }

    if (data.finance.totalIncome > 0) {
      count++;
    }

    if (data.agenda.overdueCount > 0) {
      count++;
    }

    if (data.inventory.expiredCount > 0 ||
        data.inventory.nearExpirationCount > 0) {
      count++;
    }

    if (data.herd.registrationCoverage < 95) {
      count++;
    }

    if (data.paddocks.score < 85) {
      count++;
    }

    return count;
  }
}

class _FarmPredictiveChip extends StatelessWidget {
  const _FarmPredictiveChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final Object value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class FarmDiagnosticAccessCard extends StatelessWidget {
  const FarmDiagnosticAccessCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasDiagnosticData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _farmDiagnosticAccessColor(data.level);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF455A64)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 51,
                        height: 51,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.health_and_safety_outlined,
                          color: color,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diagnóstico Inteligente Atlas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.title,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.mainDiagnosis,
                    maxLines: compact ? 7 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      'Prioridade nº 1: ${data.mainPriority.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC8A951),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FarmDiagnosticChip(
                        label: 'Riscos',
                        value: data.risks.length,
                        color: const Color(0xFFEF5350),
                      ),
                      _FarmDiagnosticChip(
                        label: 'Gargalos',
                        value: data.bottlenecks.length,
                        color: const Color(0xFFFFB74D),
                      ),
                      _FarmDiagnosticChip(
                        label: 'Ações 7 dias',
                        value: data.plan7Days.length,
                        color: const Color(0xFF64B5F6),
                      ),
                    ],
                  ),
                ],
              );

              final side = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.score.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Score diagnóstico',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC8A951),
                      foregroundColor: const Color(0xFF263238),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(
                      'Abrir diagnóstico',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [information, const SizedBox(height: 20), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 25),
                  side,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FarmDiagnosticChip extends StatelessWidget {
  const _FarmDiagnosticChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _farmDiagnosticAccessColor(AtlasDiagnosticLevel level) {
  switch (level) {
    case AtlasDiagnosticLevel.excellent:
      return const Color(0xFF66BB6A);

    case AtlasDiagnosticLevel.stable:
      return const Color(0xFF81C784);

    case AtlasDiagnosticLevel.attention:
      return const Color(0xFFFFB74D);

    case AtlasDiagnosticLevel.critical:
      return const Color(0xFFEF5350);
  }
}

class FarmIntelligenceAccessCard extends StatelessWidget {
  const FarmIntelligenceAccessCard({
    required this.data,
    required this.onOpenIntelligence,
    required this.onOpenCopilot,
    super.key,
  });

  final AtlasFarmIntelligenceData data;
  final VoidCallback onOpenIntelligence;
  final VoidCallback onOpenCopilot;

  @override
  Widget build(BuildContext context) {
    final color = _farmIntelligenceAccessColor(data.level);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(21),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E2F24), Color(0xFF174B37)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: color, size: 29),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.situationTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      data.score.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data.executiveSummary,
                  maxLines: compact ? 6 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 13),
                Text(
                  'Prioridade nº 1: ${data.mainPriority.title}',
                  style: const TextStyle(
                    color: Color(0xFFC8A951),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );

            final buttons = Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                FilledButton.icon(
                  onPressed: onOpenIntelligence,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC8A951),
                    foregroundColor: const Color(0xFF263238),
                  ),
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('Ver inteligência'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenCopilot,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Perguntar'),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [information, const SizedBox(height: 17), buttons],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 20),
                buttons,
              ],
            );
          },
        ),
      ),
    );
  }
}

Color _farmIntelligenceAccessColor(AtlasFarmIntelligenceLevel level) {
  switch (level) {
    case AtlasFarmIntelligenceLevel.excellent:
      return const Color(0xFF66BB6A);
    case AtlasFarmIntelligenceLevel.stable:
      return const Color(0xFF81C784);
    case AtlasFarmIntelligenceLevel.attention:
      return const Color(0xFFFFB74D);
    case AtlasFarmIntelligenceLevel.critical:
      return const Color(0xFFEF5350);
  }
}

class FarmDashboardHeader extends StatelessWidget {
  const FarmDashboardHeader({
    required this.farm,
    required this.totalAnimals,
    required this.totalGroups,
    required this.financialBalance,
    required this.totalAlerts,
    required this.todayTasks,
    super.key,
  });

  final FarmData farm;
  final int totalAnimals;
  final int totalGroups;
  final double financialBalance;
  final int totalAlerts;
  final int todayTasks;

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      HeaderMetric(value: totalAnimals.toString(), label: 'animais'),
      HeaderMetric(value: totalGroups.toString(), label: 'lotes'),
      HeaderMetric(
        value: formatCompactCurrency(financialBalance),
        label: 'saldo',
      ),
      HeaderMetric(value: todayTasks.toString(), label: 'hoje'),
      HeaderMetric(value: totalAlerts.toString(), label: 'alertas'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final identity = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 58 : 78,
              height: compact ? 58 : 78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(compact ? 16 : 20),
              ),
              child: Icon(
                Icons.home_work_outlined,
                color: Colors.white,
                size: compact ? 32 : 42,
              ),
            ),
            SizedBox(width: compact ? 14 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 22 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${farm.city} - ${farm.state}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: compact ? 14 : 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${formatNumber(farm.area.toDouble())} hectares',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 18 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: metrics
                          .map(
                            (metric) => SizedBox(
                              width: (constraints.maxWidth - 56) / 2,
                              child: metric,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 24),
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 12,
                        children: metrics,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class HeaderMetric extends StatelessWidget {
  const HeaderMetric({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredMetricCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: const Color(0xFF1B5E20),
    );
  }
}

class ColoredMetricCard extends StatelessWidget {
  const ColoredMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 255,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FarmAlertsCard extends StatelessWidget {
  const FarmAlertsCard({
    required this.totalAnimals,
    required this.farmRegisteredAnimals,
    required this.inventoryAlerts,
    required this.lowStockCount,
    required this.expiredCount,
    required this.nearExpirationCount,
    required this.agendaAlerts,
    required this.overdueTasks,
    required this.urgentTasks,
    required this.todayTasks,
    super.key,
  });

  final int totalAnimals;
  final int farmRegisteredAnimals;
  final int inventoryAlerts;
  final int lowStockCount;
  final int expiredCount;
  final int nearExpirationCount;
  final int agendaAlerts;
  final int overdueTasks;
  final int urgentTasks;
  final int todayTasks;

  @override
  Widget build(BuildContext context) {
    final hasAnimalWarning = totalAnimals == 0;

    final hasAlerts =
        hasAnimalWarning || inventoryAlerts > 0 || agendaAlerts > 0;

    final color = hasAlerts ? const Color(0xFFEF6C00) : const Color(0xFF1B5E20);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasAlerts
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAlerts
                      ? 'Pontos que precisam de atenção'
                      : 'Nenhuma pendência identificada',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                if (!hasAlerts)
                  Text(
                    todayTasks > 0
                        ? 'Não há pendências críticas. Existem '
                              '$todayTasks atividades programadas para hoje.'
                        : 'Os indicadores disponíveis não apresentam alertas.',
                  ),
                if (hasAnimalWarning)
                  AlertLine(
                    text:
                        'A fazenda informa $farmRegisteredAnimals animais '
                        'no cadastro geral, mas ainda não possui animais '
                        'individuais cadastrados nos lotes.',
                  ),
                if (lowStockCount > 0)
                  AlertLine(
                    text: '$lowStockCount produtos estão com estoque baixo.',
                  ),
                if (expiredCount > 0)
                  AlertLine(text: '$expiredCount produtos estão vencidos.'),
                if (nearExpirationCount > 0)
                  AlertLine(
                    text:
                        '$nearExpirationCount produtos vencem nos próximos 30 dias.',
                  ),
                if (overdueTasks > 0)
                  AlertLine(
                    text:
                        '$overdueTasks compromissos da agenda estão atrasados.',
                  ),
                if (urgentTasks > 0)
                  AlertLine(
                    text: '$urgentTasks tarefas urgentes ainda estão abertas.',
                  ),
                if (todayTasks > 0)
                  AlertLine(
                    text: '$todayTasks atividades estão programadas para hoje.',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlertLine extends StatelessWidget {
  const AlertLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: Color(0xFFEF6C00)),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class AgendaPreviewCard extends StatelessWidget {
  const AgendaPreviewCard({
    required this.tasks,
    required this.onOpen,
    super.key,
  });

  final List<FarmAgendaData> tasks;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Card(
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(28),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF1B5E20),
                  size: 42,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nenhuma atividade pendente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Abra a agenda para cadastrar o próximo compromisso.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Próximos compromissos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: const Text('Abrir agenda'),
                ),
              ],
            ),
          ),
          ...List.generate(tasks.length, (index) {
            final task = tasks[index];

            return Column(
              children: [
                if (index > 0) const Divider(height: 1),
                AgendaPreviewTile(task: task, onTap: onOpen),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class AgendaPreviewTile extends StatelessWidget {
  const AgendaPreviewTile({required this.task, required this.onTap, super.key});

  final FarmAgendaData task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = isAgendaOverdue(task);

    final color = overdue
        ? Colors.red.shade700
        : task.priority == 'Urgente'
        ? Colors.red.shade700
        : task.priority == 'Alta'
        ? const Color(0xFFEF6C00)
        : const Color(0xFF1B5E20);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(agendaCategoryIcon(task.category), color: color),
      ),
      title: Text(
        task.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${task.date}'
        '${task.time.isEmpty ? '' : ' · ${task.time}'}'
        '${task.responsible.isEmpty ? '' : ' · ${task.responsible}'}',
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          overdue ? 'Atrasada' : task.priority,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class FarmModuleCard extends StatelessWidget {
  const FarmModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.metrics,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final List<OverviewData> metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: const Color(0xFF1B5E20), size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: metrics.map((metric) {
                  return OverviewMetric(data: metric);
                }).toList(),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class OverviewMetric extends StatelessWidget {
  const OverviewMetric({required this.data, super.key});

  final OverviewData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          Text(
            data.label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class OverviewData {
  const OverviewData({required this.label, required this.value});

  final String label;
  final String value;
}

enum InventoryStatus { noExpiration, valid, nearExpiration, expired }

InventoryStatus getExpirationStatus(FarmInventoryData item) {
  if (item.expirationDate.trim().isEmpty) {
    return InventoryStatus.noExpiration;
  }

  final expirationDate = tryParseDate(item.expirationDate);

  if (expirationDate == null) {
    return InventoryStatus.noExpiration;
  }

  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final difference = expirationDate.difference(today).inDays;

  if (difference < 0) {
    return InventoryStatus.expired;
  }

  if (difference <= 30) {
    return InventoryStatus.nearExpiration;
  }

  return InventoryStatus.valid;
}

bool isAgendaToday(FarmAgendaData task) {
  final date = tryParseDate(task.date);

  if (date == null) {
    return false;
  }

  final now = DateTime.now();

  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

bool isAgendaOverdue(FarmAgendaData task) {
  if (task.isCompleted || task.isCancelled) {
    return false;
  }

  final date = tryParseDate(task.date);

  if (date == null) {
    return false;
  }

  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  return date.isBefore(today);
}

int compareAgendaTasks(FarmAgendaData first, FarmAgendaData second) {
  final firstDate = tryParseDate(first.date) ?? DateTime(2100);

  final secondDate = tryParseDate(second.date) ?? DateTime(2100);

  final dateComparison = firstDate.compareTo(secondDate);

  if (dateComparison != 0) {
    return dateComparison;
  }

  return agendaTimeInMinutes(
    first.time,
  ).compareTo(agendaTimeInMinutes(second.time));
}

int agendaTimeInMinutes(String value) {
  final parts = value.trim().split(':');

  if (parts.length != 2) {
    return 24 * 60;
  }

  final hour = int.tryParse(parts[0]) ?? 24;

  final minute = int.tryParse(parts[1]) ?? 0;

  return hour * 60 + minute;
}

IconData agendaCategoryIcon(String category) {
  switch (category) {
    case 'Vacinação':
      return Icons.vaccines_outlined;
    case 'Pesagem':
      return Icons.monitor_weight_outlined;
    case 'Reprodução':
      return Icons.favorite_outline;
    case 'Sanidade':
      return Icons.medical_services_outlined;
    case 'Movimentação':
      return Icons.swap_horiz_outlined;
    case 'Manutenção':
      return Icons.handyman_outlined;
    case 'Compra ou entrega':
      return Icons.local_shipping_outlined;
    case 'Visita técnica':
      return Icons.badge_outlined;
    case 'Administrativo':
      return Icons.business_center_outlined;
    default:
      return Icons.task_alt_outlined;
  }
}

DateTime? tryParseDate(String value) {
  final parts = value.trim().split('/');

  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return null;
  }

  final date = DateTime(year, month, day);

  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}

int calculatePercentage(int value, int total) {
  if (total == 0) {
    return 0;
  }

  return ((value / total) * 100).round();
}

String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String formatCurrency(double value) {
  final isNegative = value < 0;
  final absoluteValue = value.abs();

  final parts = absoluteValue.toStringAsFixed(2).split('.');

  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();

  for (var index = 0; index < integerPart.length; index++) {
    final positionFromEnd = integerPart.length - index;

    buffer.write(integerPart[index]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  final formatted = 'R\$ ${buffer.toString()},$decimalPart';

  return isNegative ? '-$formatted' : formatted;
}

String formatCompactCurrency(double value) {
  final isNegative = value < 0;
  final absoluteValue = value.abs();

  String formatted;

  if (absoluteValue >= 1000000) {
    formatted =
        'R\$ ${(absoluteValue / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi';
  } else if (absoluteValue >= 1000) {
    formatted =
        'R\$ ${(absoluteValue / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil';
  } else {
    formatted = 'R\$ ${absoluteValue.toStringAsFixed(0)}';
  }

  return isNegative ? '-$formatted' : formatted;
}
