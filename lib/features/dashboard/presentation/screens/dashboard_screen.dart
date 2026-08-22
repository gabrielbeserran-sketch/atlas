import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/presentation/screens/executive_dashboard_screen.dart';
import 'package:projeto_atlas/features/dashboard/presentation/screens/operational_alert_center_screen.dart';
import 'package:projeto_atlas/features/dashboard/presentation/widgets/dashboard_action_summary_card.dart';
import 'package:projeto_atlas/features/dashboard/data/services/atlas_operational_intelligence_service.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/atlas_operational_intelligence_data.dart';
import 'package:projeto_atlas/features/dashboard/presentation/widgets/operational_intelligence_card.dart';
import 'package:projeto_atlas/features/dashboard/presentation/widgets/executive_indicators_card.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/farm_list_screen.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart';
import 'package:projeto_atlas/features/indicators/presentation/screens/indicators_screen.dart';
import 'package:projeto_atlas/features/herd/presentation/screens/herd_overview_screen.dart';
import 'package:projeto_atlas/features/animal_health/presentation/screens/health_overview_screen.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart';
import 'package:projeto_atlas/features/nutrition/presentation/screens/nutrition_overview_screen.dart';
import 'package:projeto_atlas/features/farm_finance/presentation/screens/finance_overview_screen.dart';
import 'package:projeto_atlas/features/farm_inventory/presentation/screens/inventory_overview_screen.dart';
import 'package:projeto_atlas/features/reports/presentation/screens/reports_screen.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_storage_service.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';
import 'package:projeto_atlas/features/reports/presentation/screens/report_action_list_screen.dart';
import 'package:projeto_atlas/features/technical_dashboard/presentation/screens/technical_dashboard_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onNavigateModule});

  /// Navegação fornecida pelo AtlasHomeShell para módulos que pertencem ao
  /// menu principal. Evita empilhar uma segunda tela sem a navegação oficial.
  final ValueChanged<String>? onNavigateModule;

  @override
  State<DashboardScreen> createState() {
    return _DashboardScreenState();
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color forestGreen = Color(0xFF1B5E20);

  final FarmStorageService farmStorage = FarmStorageService();

  final FarmAgendaStorageService agendaStorage = FarmAgendaStorageService();

  final ReportActionStorageService actionStorage = ReportActionStorageService();

  final AtlasOperationalIntelligenceService operationalIntelligence =
      AtlasOperationalIntelligenceService();

  final AtlasEnterpriseRemoteAuthStore remoteAuth =
      AtlasEnterpriseRemoteAuthStore.instance;

  List<FarmData> farms = [];
  List<DashboardAgendaContext> agendaContexts = [];
  List<ReportActionItemData> managementActions = [];
  AtlasOperationalIntelligenceData? operationalData;
  String? operationalFarmName;
  String? operationalWarning;

  bool isLoading = true;

  int dashboardRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  int get pendingCount {
    return agendaContexts.where((context) {
      final task = context.task;

      return task.status == 'Pendente' || task.status == 'Em andamento';
    }).length;
  }

  int get todayCount {
    return agendaContexts.where((context) {
      return isTaskToday(context.task);
    }).length;
  }

  int get overdueCount {
    return agendaContexts.where((context) {
      return isTaskOverdue(context.task);
    }).length;
  }

  int get urgentCount {
    return agendaContexts.where((context) {
      final task = context.task;

      return task.priority == 'Urgente' &&
          !task.isCompleted &&
          !task.isCancelled;
    }).length;
  }

  int get agendaAlertCount {
    final alertIds = <String>{};

    for (final context in agendaContexts) {
      final task = context.task;

      if (isTaskOverdue(task) ||
          (task.priority == 'Urgente' &&
              !task.isCompleted &&
              !task.isCancelled)) {
        alertIds.add('${context.farm.name}_${task.id}');
      }
    }

    return alertIds.length;
  }

  int get actionOverdueCount {
    return managementActions.where((action) {
      return action.isOverdue;
    }).length;
  }

  int get actionUrgentCount {
    return managementActions.where((action) {
      return action.isUrgent && action.isOpen;
    }).length;
  }

  int get actionOpenCount {
    return managementActions.where((action) {
      return action.isOpen;
    }).length;
  }

  int get actionAlertCount {
    final alertIds = <String>{};

    for (final action in managementActions) {
      if (action.isOverdue || (action.isUrgent && action.isOpen)) {
        alertIds.add(action.id);
      }
    }

    return alertIds.length;
  }

  int get alertCount {
    return agendaAlertCount + actionAlertCount;
  }

  List<DashboardAgendaContext> get todayActivities {
    final activities = agendaContexts.where((context) {
      final task = context.task;

      return isTaskToday(task) && !task.isCancelled;
    }).toList();

    activities.sort(compareAgendaContexts);

    return activities;
  }

  List<DashboardAgendaContext> get nextActivities {
    final activities = agendaContexts.where((context) {
      final task = context.task;

      return !task.isCompleted && !task.isCancelled;
    }).toList();

    activities.sort(compareDashboardActivities);

    return activities.take(5).toList();
  }

  Future<void> _loadOperationalIntelligence(List<FarmData> loadedFarms) async {
    if (loadedFarms.isEmpty) {
      operationalData = null;
      operationalFarmName = null;
      operationalWarning = null;
      return;
    }

    final savedFarmId = await remoteAuth.loadActiveFarm();
    FarmData? target;

    if (savedFarmId != null && savedFarmId.isNotEmpty) {
      for (final farm in loadedFarms) {
        if (farm.id == savedFarmId) {
          target = farm;
          break;
        }
      }
    }

    target ??= loadedFarms.first;
    final farmId = target.id ?? '';
    if (farmId.isEmpty) return;

    try {
      operationalData = await operationalIntelligence.load(farmId);
      operationalFarmName = target.name;
      operationalWarning = null;
    } catch (error) {
      operationalWarning = 'Inteligência operacional indisponível: $error';
    }
  }

  void openOperationalArea(String area) {
    final normalized = area.trim().toLowerCase();
    if (normalized.contains('sanidade')) {
      openHealth();
    } else if (normalized.contains('reprodução')) {
      openReproduction();
    } else if (normalized.contains('nutrição')) {
      openNutrition();
    } else if (normalized.contains('finance')) {
      openFinance();
    } else if (normalized.contains('estoque')) {
      openInventory();
    } else if (normalized.contains('agenda')) {
      chooseFarmAgenda();
    } else if (normalized.contains('rebanho') ||
        normalized.contains('pesagem')) {
      openHerd();
    } else if (normalized.contains('integridade')) {
      openTechnicalDashboard();
    } else {
      openIndicators();
    }
  }

  Future<void> openOperationalAlertCenter() async {
    final data = operationalData;
    if (data == null || data.farmId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione uma fazenda e atualize a inteligência operacional.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OperationalAlertCenterScreen(
          farmId: data.farmId,
          farmName: operationalFarmName ?? 'Fazenda ativa',
          onOpenArea: openOperationalArea,
        ),
      ),
    );

    if (mounted) {
      await loadDashboard();
    }
  }

  Future<void> loadDashboard() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final loadedFarms = await farmStorage.loadFarms();
      final loadedActions = await actionStorage.loadActions();
      await _loadOperationalIntelligence(loadedFarms);
      final loadedContexts = <DashboardAgendaContext>[];

      for (final farm in loadedFarms) {
        try {
          final farmId = farm.id ?? '';
          if (farmId.isNotEmpty) {
            try {
              await agendaStorage.reconcileSmartAgenda(farmId);
            } catch (_) {
              // A Agenda Inteligente não pode bloquear o Dashboard.
            }
          }
          final tasks = await agendaStorage.loadTasks(
            farm.name,
            farmId: farmId,
          );
          loadedContexts.addAll(
            tasks.map((task) => DashboardAgendaContext(farm: farm, task: task)),
          );
        } catch (_) {
          // Agenda não pode impedir o Dashboard inteiro de abrir.
        }
      }

      loadedContexts.sort(compareAgendaContexts);
      if (!mounted) return;
      setState(() {
        farms = loadedFarms;
        agendaContexts = loadedContexts;
        managementActions = loadedActions;
        dashboardRefreshVersion++;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar o Dashboard: $error')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _navigateThroughShell(String label) {
    final callback = widget.onNavigateModule;
    if (callback == null) return false;
    callback(label);
    return true;
  }

  Future<void> openFarms() async {
    if (_navigateThroughShell('Fazendas')) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const FarmListScreen();
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openExecutiveDashboard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const ExecutiveDashboardScreen();
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openTechnicalDashboard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const TechnicalDashboardScreen();
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openIndicators() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const IndicatorsScreen();
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openHerd() async {
    if (_navigateThroughShell('Rebanho')) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const HerdOverviewScreen();
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> _openDirectScreen(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    await loadDashboard();
  }

  Future<void> openHealth() async {
    if (_navigateThroughShell('Sanidade')) return;
    await _openDirectScreen(const HealthOverviewScreen());
  }

  Future<void> openReproduction() async {
    if (_navigateThroughShell('Reprodução')) return;
    await _openDirectScreen(const ReproductionOverviewScreen());
  }

  Future<void> openNutrition() async {
    if (_navigateThroughShell('Nutrição')) return;
    await _openDirectScreen(const NutritionOverviewScreen());
  }

  Future<void> openFinance() async {
    if (_navigateThroughShell('Financeiro')) return;
    await _openDirectScreen(const FinanceOverviewScreen());
  }

  Future<void> openInventory() async {
    if (_navigateThroughShell('Estoque')) return;
    await _openDirectScreen(const InventoryOverviewScreen());
  }

  Future<void> openReports() async {
    if (_navigateThroughShell('Relatórios')) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const ReportsScreen();
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openActions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const ReportActionListScreen();
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openFarmAgenda(FarmData farm) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return FarmAgendaListScreen(farm: farm);
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> chooseFarmAgenda() async {
    if (farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre uma fazenda antes de acessar a agenda.'),
        ),
      );

      return;
    }

    if (farms.length == 1) {
      await openFarmAgenda(farms.first);
      return;
    }

    final selectedFarm = await showDialog<FarmData>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Escolher fazenda'),
          content: SizedBox(
            width: 460,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: farms.length,
              separatorBuilder: (context, index) {
                return const Divider(height: 1);
              },
              itemBuilder: (context, index) {
                final farm = farms[index];

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(
                      Icons.home_work_outlined,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  title: Text(
                    farm.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${farm.city} - ${farm.state}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(dialogContext, farm);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (selectedFarm == null || !mounted) {
      return;
    }

    await openFarmAgenda(selectedFarm);
  }

  void showComingSoon(String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'O módulo $moduleName será implementado nas próximas etapas.',
        ),
      ),
    );
  }

  void showAlertSummary() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final screenHeight = MediaQuery.sizeOf(bottomSheetContext).height;

        return Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.06),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 30,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 16, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Alertas da operação',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agenda',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AlertSummaryTile(
                          icon: Icons.warning_amber_outlined,
                          title: 'Tarefas atrasadas',
                          value: overdueCount.toString(),
                          color: overdueCount > 0
                              ? Colors.red.shade700
                              : forestGreen,
                        ),
                        AlertSummaryTile(
                          icon: Icons.priority_high,
                          title: 'Prioridades urgentes',
                          value: urgentCount.toString(),
                          color: urgentCount > 0
                              ? Colors.red.shade700
                              : forestGreen,
                        ),
                        AlertSummaryTile(
                          icon: Icons.today_outlined,
                          title: 'Atividades de hoje',
                          value: todayCount.toString(),
                          color: const Color(0xFF1565C0),
                        ),
                        const Divider(height: 28),
                        const Text(
                          'Ações gerenciais',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AlertSummaryTile(
                          icon: Icons.event_busy_outlined,
                          title: 'Ações atrasadas',
                          value: actionOverdueCount.toString(),
                          color: actionOverdueCount > 0
                              ? Colors.red.shade700
                              : forestGreen,
                        ),
                        AlertSummaryTile(
                          icon: Icons.flag_outlined,
                          title: 'Ações urgentes',
                          value: actionUrgentCount.toString(),
                          color: actionUrgentCount > 0
                              ? const Color(0xFFEF6C00)
                              : forestGreen,
                        ),
                        AlertSummaryTile(
                          icon: Icons.assignment_outlined,
                          title: 'Ações abertas',
                          value: actionOpenCount.toString(),
                          color: const Color(0xFF1565C0),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 440;

                        final agendaButton = FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            chooseFarmAgenda();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: forestGreen,
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: const Text('Abrir agenda'),
                        );

                        final actionsButton = OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            openActions();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.assignment_turned_in_outlined),
                          label: const Text('Abrir ações'),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              agendaButton,
                              const SizedBox(height: 10),
                              actionsButton,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: agendaButton),
                            const SizedBox(width: 10),
                            Expanded(child: actionsButton),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F7F9),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WelcomeHeader(
                            todayCount: todayCount,
                            alertCount: alertCount,
                          ),
                          const SizedBox(height: 24),
                          DashboardIndicators(
                            farmCount: farms.length,
                            todayCount: todayCount,
                            pendingCount: pendingCount,
                            alertCount: alertCount,
                          ),
                          const SizedBox(height: 24),
                          OperationalIntelligenceCard(
                            data: operationalData,
                            farmName: operationalFarmName ?? 'Fazenda ativa',
                            warning: operationalWarning,
                            onRefresh: loadDashboard,
                            onOpenArea: openOperationalArea,
                            onOpenAlerts: openOperationalAlertCenter,
                          ),
                          const SizedBox(height: 16),
                          ExecutiveIndicatorsCard(
                            data: operationalData,
                            farmName: operationalFarmName ?? 'Fazenda ativa',
                          ),
                          const SizedBox(height: 24),
                          AdvancedAnalysisAccessCard(
                            actionCount: managementActions.length,
                            alertCount: actionAlertCount,
                            onOpenExecutive: openExecutiveDashboard,
                            onOpenTechnical: openTechnicalDashboard,
                          ),
                          const SizedBox(height: 24),
                          DashboardActionSummaryCard(
                            key: ValueKey(dashboardRefreshVersion),
                          ),
                          const SizedBox(height: 32),
                          const SectionTitle(
                            title: 'Acesso rápido',
                            subtitle: 'Principais áreas da operação',
                          ),
                          const SizedBox(height: 16),
                          ModulesGrid(
                            onOpenFarms: openFarms,
                            onOpenIndicators: openIndicators,
                            onOpenAgenda: chooseFarmAgenda,
                            onOpenReports: openReports,
                            onOpenHerd: openHerd,
                            onOpenReproduction: openReproduction,
                            onOpenHealth: openHealth,
                            onOpenNutrition: openNutrition,
                            onOpenFinance: openFinance,
                            onOpenInventory: openInventory,
                            onComingSoon: showComingSoon,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Expanded(
                                child: SectionTitle(
                                  title: 'Atividades de hoje',
                                  subtitle:
                                      'Compromissos reais de todas as fazendas',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: chooseFarmAgenda,
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: const Text('Abrir agenda'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TodayActivities(
                            activities: todayActivities,
                            onOpenAgenda: openFarmAgenda,
                          ),
                          const SizedBox(height: 32),
                          const SectionTitle(
                            title: 'Próximas atividades',
                            subtitle:
                                'Tarefas pendentes organizadas por prazo e prioridade',
                          ),
                          const SizedBox(height: 16),
                          NextActivitiesCard(
                            activities: nextActivities,
                            onOpenAgenda: openFarmAgenda,
                          ),
                          const SizedBox(height: 32),
                          DashboardAlertsCard(
                            overdueCount: overdueCount,
                            urgentCount: urgentCount,
                            todayCount: todayCount,
                            onOpenAgenda: chooseFarmAgenda,
                          ),
                          const SizedBox(height: 32),
                          AtlasInsightCard(
                            pendingCount: pendingCount,
                            overdueCount: overdueCount,
                            urgentCount: urgentCount,
                            onOpenIndicators: openIndicators,
                            onOpenReports: openReports,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class AdvancedAnalysisAccessCard extends StatelessWidget {
  const AdvancedAnalysisAccessCard({
    required this.actionCount,
    required this.alertCount,
    required this.onOpenExecutive,
    required this.onOpenTechnical,
    super.key,
  });

  final int actionCount;
  final int alertCount;
  final VoidCallback onOpenExecutive;
  final VoidCallback onOpenTechnical;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;

            final intro = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análises e decisões',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Ferramentas avançadas ficam agrupadas aqui para manter '
                  'o Dashboard focado no dia a dia.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            );

            final executive = OutlinedButton.icon(
              onPressed: onOpenExecutive,
              icon: const Icon(Icons.analytics_outlined),
              label: Text(
                'Executivo · $actionCount ações · $alertCount alertas',
              ),
            );

            final technical = OutlinedButton.icon(
              onPressed: onOpenTechnical,
              icon: const Icon(Icons.query_stats_outlined),
              label: const Text('Painel técnico'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  intro,
                  const SizedBox(height: 14),
                  executive,
                  const SizedBox(height: 8),
                  technical,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: intro),
                const SizedBox(width: 18),
                executive,
                const SizedBox(width: 8),
                technical,
              ],
            );
          },
        ),
      ),
    );
  }
}

class TechnicalDashboardAccessCard extends StatelessWidget {
  const TechnicalDashboardAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFE8F5E9),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF1B5E20),
                child: Icon(Icons.analytics_outlined, color: Colors.white),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Painel Técnico Integrado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Rebanho, reprodução, sanidade, nutrição, financeiro e estoque em uma única visão por fazenda.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveDashboardAccessCard extends StatelessWidget {
  const ExecutiveDashboardAccessCard({
    required this.actionCount,
    required this.actionAlertCount,
    required this.onOpen,
    super.key,
  });

  final int actionCount;
  final int actionAlertCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF163F1A), Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;

              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Dashboard Executivo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Indicadores, rankings, tendências, alertas e parecer inteligente da operação.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 17),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      ExecutiveDashboardAccessChip(
                        icon: Icons.assignment_outlined,
                        text: '$actionCount ações',
                      ),
                      ExecutiveDashboardAccessChip(
                        icon: Icons.notifications_active_outlined,
                        text: '$actionAlertCount alertas',
                      ),
                      const ExecutiveDashboardAccessChip(
                        icon: Icons.psychology_alt_outlined,
                        text: 'Parecer inteligente',
                      ),
                    ],
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
                    vertical: 15,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'Abrir visão executiva',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    information,
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: button),
                  ],
                );
              }

              return Row(
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

class ExecutiveDashboardAccessChip extends StatelessWidget {
  const ExecutiveDashboardAccessChip({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({
    required this.todayCount,
    required this.alertCount,
    super.key,
  });

  final int todayCount;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visão geral da operação',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                todayCount == 0
                    ? 'Não há atividades programadas para hoje.'
                    : todayCount == 1
                    ? 'Você possui 1 atividade programada para hoje.'
                    : 'Você possui $todayCount atividades programadas para hoje.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              WelcomeMetric(
                value: todayCount.toString(),
                label: 'hoje',
                icon: Icons.today_outlined,
              ),
              WelcomeMetric(
                value: alertCount.toString(),
                label: 'alertas',
                icon: Icons.warning_amber_outlined,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 20), metrics],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              metrics,
            ],
          );
        },
      ),
    );
  }
}

class WelcomeMetric extends StatelessWidget {
  const WelcomeMetric({
    required this.value,
    required this.label,
    required this.icon,
    super.key,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardIndicators extends StatelessWidget {
  const DashboardIndicators({
    required this.farmCount,
    required this.todayCount,
    required this.pendingCount,
    required this.alertCount,
    super.key,
  });

  final int farmCount;
  final int todayCount;
  final int pendingCount;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 48) / 4
            : constraints.maxWidth >= 560
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            IndicatorCard(
              width: cardWidth,
              title: 'Fazendas',
              value: farmCount.toString(),
              subtitle: 'Propriedades cadastradas',
              icon: Icons.home_work_outlined,
              color: const Color(0xFF1B5E20),
            ),
            IndicatorCard(
              width: cardWidth,
              title: 'Atividades de hoje',
              value: todayCount.toString(),
              subtitle: 'Compromissos programados',
              icon: Icons.today_outlined,
              color: const Color(0xFF1565C0),
            ),
            IndicatorCard(
              width: cardWidth,
              title: 'Pendentes',
              value: pendingCount.toString(),
              subtitle: 'Tarefas ainda abertas',
              icon: Icons.schedule_outlined,
              color: pendingCount > 0
                  ? const Color(0xFFEF6C00)
                  : const Color(0xFF1B5E20),
            ),
            IndicatorCard(
              width: cardWidth,
              title: 'Alertas',
              value: alertCount.toString(),
              subtitle: 'Atrasos e urgências',
              icon: Icons.warning_amber_rounded,
              color: alertCount > 0
                  ? Colors.red.shade700
                  : const Color(0xFF1B5E20),
            ),
          ],
        );
      },
    );
  }
}

class IndicatorCard extends StatelessWidget {
  const IndicatorCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    super.key,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
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
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class ModulesGrid extends StatelessWidget {
  const ModulesGrid({
    required this.onOpenFarms,
    required this.onOpenIndicators,
    required this.onOpenAgenda,
    required this.onOpenReports,
    required this.onOpenHerd,
    required this.onOpenReproduction,
    required this.onOpenHealth,
    required this.onOpenNutrition,
    required this.onOpenFinance,
    required this.onOpenInventory,
    required this.onComingSoon,
    super.key,
  });

  final VoidCallback onOpenFarms;
  final VoidCallback onOpenIndicators;
  final VoidCallback onOpenAgenda;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenHerd;
  final VoidCallback onOpenReproduction;
  final VoidCallback onOpenHealth;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenFinance;
  final VoidCallback onOpenInventory;
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    const modules = [
      ModuleData('Fazendas', Icons.landscape_outlined),
      ModuleData('Indicadores', Icons.analytics_outlined),
      ModuleData('Agenda', Icons.calendar_month_outlined),
      ModuleData('Relatórios', Icons.bar_chart_outlined),
      ModuleData('Rebanho', AtlasLivestockIcons.cow),
      ModuleData('Reprodução', Icons.favorite_outline),
      ModuleData('Sanidade', Icons.medical_services_outlined),
      ModuleData('Nutrição', Icons.grass_outlined),
      ModuleData('Financeiro', Icons.account_balance_wallet_outlined),
      ModuleData('Estoque', Icons.inventory_2_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 2;

        if (constraints.maxWidth >= 1000) {
          columns = 4;
        } else if (constraints.maxWidth >= 650) {
          columns = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                if (module.title == 'Fazendas') {
                  onOpenFarms();
                  return;
                }

                if (module.title == 'Indicadores') {
                  onOpenIndicators();
                  return;
                }

                if (module.title == 'Agenda') {
                  onOpenAgenda();
                  return;
                }

                if (module.title == 'Relatórios') {
                  onOpenReports();
                  return;
                }

                if (module.title == 'Rebanho') {
                  onOpenHerd();
                  return;
                }

                if (module.title == 'Reprodução') {
                  onOpenReproduction();
                  return;
                }

                if (module.title == 'Sanidade') {
                  onOpenHealth();
                  return;
                }

                if (module.title == 'Nutrição') {
                  onOpenNutrition();
                  return;
                }

                if (module.title == 'Financeiro') {
                  onOpenFinance();
                  return;
                }

                if (module.title == 'Estoque') {
                  onOpenInventory();
                  return;
                }

                onComingSoon(module.title);
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        module.icon,
                        size: 38,
                        color: const Color(0xFF1B5E20),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        module.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ModuleData {
  const ModuleData(this.title, this.icon);

  final String title;
  final IconData icon;
}

class TodayActivities extends StatelessWidget {
  const TodayActivities({
    required this.activities,
    required this.onOpenAgenda,
    super.key,
  });

  final List<DashboardAgendaContext> activities;
  final ValueChanged<FarmData> onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const EmptyActivitiesCard(
        title: 'Nenhuma atividade para hoje',
        message: 'Os compromissos cadastrados para hoje aparecerão aqui.',
      );
    }

    return Card(
      child: Column(
        children: List.generate(activities.length, (index) {
          final activity = activities[index];

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ActivityTile(
                contextData: activity,
                onTap: () {
                  onOpenAgenda(activity.farm);
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    required this.contextData,
    required this.onTap,
    super.key,
  });

  final DashboardAgendaContext contextData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final task = contextData.task;

    final color = agendaPriorityColor(task);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(agendaCategoryIcon(task.category), color: color),
      ),
      title: Text(
        task.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${contextData.farm.name}'
        '${task.responsible.isEmpty ? '' : ' · ${task.responsible}'}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            task.time.isEmpty ? 'Sem horário' : task.time,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            task.priority,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class NextActivitiesCard extends StatelessWidget {
  const NextActivitiesCard({
    required this.activities,
    required this.onOpenAgenda,
    super.key,
  });

  final List<DashboardAgendaContext> activities;
  final ValueChanged<FarmData> onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const EmptyActivitiesCard(
        title: 'Nenhuma atividade pendente',
        message:
            'Cadastre tarefas nas agendas das fazendas para acompanhar os próximos manejos.',
      );
    }

    return Card(
      child: Column(
        children: List.generate(activities.length, (index) {
          final contextData = activities[index];

          final task = contextData.task;

          final overdue = isTaskOverdue(task);

          final color = overdue
              ? Colors.red.shade700
              : agendaPriorityColor(task);

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                onTap: () {
                  onOpenAgenda(contextData.farm);
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 9,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
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
                  '${contextData.farm.name} · ${task.date}'
                  '${task.time.isEmpty ? '' : ' · ${task.time}'}'
                  '${task.responsible.isEmpty ? '' : ' · ${task.responsible}'}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
              ),
            ],
          );
        }),
      ),
    );
  }
}

class EmptyActivitiesCard extends StatelessWidget {
  const EmptyActivitiesCard({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF1B5E20),
                size: 30,
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(message, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardAlertsCard extends StatelessWidget {
  const DashboardAlertsCard({
    required this.overdueCount,
    required this.urgentCount,
    required this.todayCount,
    required this.onOpenAgenda,
    super.key,
  });

  final int overdueCount;
  final int urgentCount;
  final int todayCount;
  final VoidCallback onOpenAgenda;

  bool get hasAlerts {
    return overdueCount > 0 || urgentCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    final color = hasAlerts ? const Color(0xFFEF6C00) : const Color(0xFF1B5E20);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              hasAlerts
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAlerts
                      ? 'Pontos que precisam de atenção'
                      : 'Agenda sem pendências críticas',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (!hasAlerts)
                  Text(
                    todayCount > 0
                        ? 'Existem $todayCount atividades programadas para hoje, mas nenhuma está atrasada ou marcada como urgente.'
                        : 'Não existem tarefas atrasadas ou prioridades urgentes.',
                  ),
                if (overdueCount > 0)
                  DashboardAlertLine(
                    text: '$overdueCount compromissos estão atrasados.',
                  ),
                if (urgentCount > 0)
                  DashboardAlertLine(
                    text: '$urgentCount tarefas urgentes ainda estão abertas.',
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onOpenAgenda,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Ver agendas'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardAlertLine extends StatelessWidget {
  const DashboardAlertLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
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

class AtlasInsightCard extends StatelessWidget {
  const AtlasInsightCard({
    required this.pendingCount,
    required this.overdueCount,
    required this.urgentCount,
    required this.onOpenIndicators,
    required this.onOpenReports,
    super.key,
  });

  final int pendingCount;
  final int overdueCount;
  final int urgentCount;
  final VoidCallback onOpenIndicators;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    String insight;

    if (overdueCount > 0) {
      insight =
          'Existem $overdueCount atividades atrasadas. Priorize a revisão da agenda para evitar impacto nos manejos.';
    } else if (urgentCount > 0) {
      insight =
          'Existem $urgentCount tarefas urgentes abertas. Verifique os responsáveis e os prazos.';
    } else if (pendingCount > 0) {
      insight =
          'A operação possui $pendingCount atividades pendentes, sem atrasos críticos identificados.';
    } else {
      insight =
          'Não existem tarefas pendentes. Consulte os relatórios e indicadores para acompanhar o desempenho das fazendas.';
    }

    return Card(
      color: const Color(0xFF263238),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFFC8A951),
              size: 34,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Insight Atlas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: onOpenIndicators,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC8A951),
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Ver indicadores'),
                      ),
                      TextButton.icon(
                        onPressed: onOpenReports,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC8A951),
                        ),
                        icon: const Icon(Icons.bar_chart_outlined),
                        label: const Text('Ver relatórios'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertSummaryTile extends StatelessWidget {
  const AlertSummaryTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class DashboardAgendaContext {
  const DashboardAgendaContext({required this.farm, required this.task});

  final FarmData farm;
  final FarmAgendaData task;
}

bool isTaskToday(FarmAgendaData task) {
  final date = parseDashboardDate(task.date);

  if (date == null) {
    return false;
  }

  final now = DateTime.now();

  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

bool isTaskOverdue(FarmAgendaData task) {
  if (task.isCompleted || task.isCancelled) {
    return false;
  }

  final date = parseDashboardDate(task.date);

  if (date == null) {
    return false;
  }

  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  return date.isBefore(today);
}

int compareAgendaContexts(
  DashboardAgendaContext first,
  DashboardAgendaContext second,
) {
  final firstDate = parseDashboardDate(first.task.date) ?? DateTime(2100);

  final secondDate = parseDashboardDate(second.task.date) ?? DateTime(2100);

  final dateComparison = firstDate.compareTo(secondDate);

  if (dateComparison != 0) {
    return dateComparison;
  }

  return parseDashboardMinutes(
    first.task.time,
  ).compareTo(parseDashboardMinutes(second.task.time));
}

int compareDashboardActivities(
  DashboardAgendaContext first,
  DashboardAgendaContext second,
) {
  final firstOverdue = isTaskOverdue(first.task);

  final secondOverdue = isTaskOverdue(second.task);

  if (firstOverdue != secondOverdue) {
    return firstOverdue ? -1 : 1;
  }

  final firstPriority = priorityWeight(first.task.priority);

  final secondPriority = priorityWeight(second.task.priority);

  if (firstPriority != secondPriority) {
    return secondPriority.compareTo(firstPriority);
  }

  return compareAgendaContexts(first, second);
}

int priorityWeight(String priority) {
  switch (priority) {
    case 'Urgente':
      return 4;
    case 'Alta':
      return 3;
    case 'Normal':
      return 2;
    case 'Baixa':
      return 1;
    default:
      return 0;
  }
}

DateTime? parseDashboardDate(String value) {
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

int parseDashboardMinutes(String value) {
  final parts = value.trim().split(':');

  if (parts.length != 2) {
    return 24 * 60;
  }

  final hour = int.tryParse(parts[0]) ?? 24;

  final minute = int.tryParse(parts[1]) ?? 0;

  return hour * 60 + minute;
}

Color agendaPriorityColor(FarmAgendaData task) {
  if (isTaskOverdue(task)) {
    return Colors.red.shade700;
  }

  switch (task.priority) {
    case 'Urgente':
      return Colors.red.shade700;
    case 'Alta':
      return const Color(0xFFEF6C00);
    case 'Baixa':
      return const Color(0xFF1565C0);
    default:
      return const Color(0xFF1B5E20);
  }
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
