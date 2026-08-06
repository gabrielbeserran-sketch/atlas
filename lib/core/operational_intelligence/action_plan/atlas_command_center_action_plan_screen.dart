import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_attention_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_analytics.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_filters.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_update.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_weekly_review_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_sync_card.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_monitoring_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_management_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_strategy_performance_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_results_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_executive_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_financial_management_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_management_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_inventory_management_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_asset_maintenance_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_strategy_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_strategy_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_strategy_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_strategy_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_agriculture_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_climate_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_esg_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_people_management_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_commercial_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_scenario_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_executive_360_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member_selector.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_audit_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';

class AtlasCommandCenterActionPlanScreen extends StatefulWidget {
  const AtlasCommandCenterActionPlanScreen({this.farmName, super.key});

  final String? farmName;

  @override
  State<AtlasCommandCenterActionPlanScreen> createState() =>
      _AtlasCommandCenterActionPlanScreenState();
}

class _AtlasCommandCenterActionPlanScreenState
    extends State<AtlasCommandCenterActionPlanScreen> {
  late final AtlasCommandCenterActionController controller;
  final TextEditingController searchController = TextEditingController();

  AtlasCommandCenterActionView selectedView = AtlasCommandCenterActionView.open;
  AtlasCanonicalPriority? selectedPriority;

  @override
  void initState() {
    super.initState();

    controller = AtlasCommandCenterActionController(farmName: widget.farmName)
      ..load();
  }

  @override
  void dispose() {
    searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Plano de ação'),
            actions: [
              IconButton(
                tooltip: 'Executivo 360°',
                onPressed: _openExecutive360,
                icon: const Icon(Icons.dashboard_customize_outlined),
              ),
              IconButton(
                tooltip: 'Cenários econômicos',
                onPressed: _openAdvancedEconomicScenarios,
                icon: const Icon(Icons.query_stats_outlined),
              ),
              IconButton(
                tooltip: 'Inteligência comercial',
                onPressed: _openCommercialIntelligence,
                icon: const Icon(Icons.handshake_outlined),
              ),
              IconButton(
                tooltip: 'Gestão de pessoas',
                onPressed: _openPeopleManagement,
                icon: const Icon(Icons.groups_outlined),
              ),
              IconButton(
                tooltip: 'ESG e sustentabilidade',
                onPressed: _openEsg,
                icon: const Icon(Icons.eco_outlined),
              ),
              IconButton(
                tooltip: 'Inteligência climática',
                onPressed: _openClimateIntelligence,
                icon: const Icon(Icons.cloud_outlined),
              ),
              IconButton(
                tooltip: 'Agricultura integrada',
                onPressed: _openAgriculture,
                icon: const Icon(Icons.agriculture_outlined),
              ),
              IconButton(
                tooltip: 'Estratégia de pastagens',
                onPressed: _openPastureStrategy,
                icon: const Icon(Icons.grass_outlined),
              ),
              IconButton(
                tooltip: 'Estratégia nutricional',
                onPressed: _openNutritionStrategy,
                icon: const Icon(Icons.energy_savings_leaf_outlined),
              ),
              IconButton(
                tooltip: 'Estratégia sanitária',
                onPressed: _openHealthStrategy,
                icon: const Icon(Icons.monitor_heart_outlined),
              ),
              IconButton(
                tooltip: 'Estratégia reprodutiva',
                onPressed: _openReproductiveStrategy,
                icon: const Icon(Icons.pregnant_woman_outlined),
              ),
              IconButton(
                tooltip: 'Inteligência econômica',
                onPressed: _openEconomicIntelligence,
                icon: const Icon(Icons.analytics_outlined),
              ),
              IconButton(
                tooltip: 'Máquinas e manutenção',
                onPressed: _openAssetMaintenance,
                icon: const Icon(Icons.precision_manufacturing_outlined),
              ),
              IconButton(
                tooltip: 'Gestão inteligente de estoque',
                onPressed: _openInventoryManagement,
                icon: const Icon(Icons.inventory_2_outlined),
              ),
              IconButton(
                tooltip: 'Gestão de pastagens',
                onPressed: _openPastureManagement,
                icon: const Icon(Icons.grass),
              ),
              IconButton(
                tooltip: 'Inteligência nutricional',
                onPressed: _openNutritionIntelligence,
                icon: const Icon(Icons.restaurant_menu),
              ),
              IconButton(
                tooltip: 'Inteligência sanitária',
                onPressed: _openHealthIntelligence,
                icon: const Icon(Icons.health_and_safety_outlined),
              ),
              IconButton(
                tooltip: 'Inteligência reprodutiva',
                onPressed: _openReproductiveIntelligence,
                icon: const Icon(Icons.biotech_outlined),
              ),
              IconButton(
                tooltip: 'Financeiro profissional',
                onPressed: _openFinancialManagement,
                icon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              IconButton(
                tooltip: 'Inteligência executiva 360°',
                onPressed: _openExecutiveIntelligence,
                icon: const Icon(Icons.dashboard_customize_outlined),
              ),
              IconButton(
                tooltip: 'Resultados e inteligência financeira',
                onPressed: _openResultsIntelligence,
                icon: const Icon(
                  Icons.insights_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Metas e desempenho',
                onPressed: _openStrategyPerformance,
                icon: const Icon(Icons.flag_outlined),
              ),
              IconButton(
                tooltip: 'Equipe e responsabilidades',
                onPressed: _openTeamManagement,
                icon: const Icon(Icons.groups_2_outlined),
              ),
              IconButton(
                tooltip: 'Auditoria',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AtlasExecutionAuditScreen(
                        farmName: controller.farmName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
              ),
              IconButton(
                tooltip: 'Central de decisões',
                onPressed: controller.actions.isEmpty
                    ? null
                    : _openDecisionMonitoring,
                icon: const Icon(
                  Icons.gavel_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Reuniões de execução',
                onPressed: controller.actions.isEmpty
                    ? null
                    : _openExecutionMeetings,
                icon: const Icon(
                  Icons.groups_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Revisão semanal',
                onPressed: controller.actions.isEmpty
                    ? null
                    : _openWeeklyReview,
                icon: const Icon(
                  Icons.calendar_view_week_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Central de atenção',
                onPressed: controller.actions.isEmpty
                    ? null
                    : _openAttentionCenter,
                icon: const Icon(
                  Icons.notification_important_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: controller.isLoading ? null : controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (controller.isLoading && controller.actions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.actions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar o plano de ação: '
            '${controller.errorMessage}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (controller.actions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma ação foi criada. Abra uma prioridade no '
            'Command Center e adicione-a ao plano de ação.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final visibleActions = filterCommandCenterActions(
      actions: controller.actions,
      view: selectedView,
      priority: selectedPriority,
      search: searchController.text,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: AtlasMeetingDecisionActionSyncCard(
            farmName: controller.farmName,
            onSynchronized: controller.load,
          ),
        ),
        _ActionAnalyticsHeader(analytics: controller.analytics),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Buscar ação',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<AtlasCommandCenterActionView>(
                  initialValue: selectedView,
                  decoration: const InputDecoration(
                    labelText: 'Visualização',
                    border: OutlineInputBorder(),
                  ),
                  items: AtlasCommandCenterActionView.values
                      .map(
                        (view) =>
                            DropdownMenuItem<AtlasCommandCenterActionView>(
                              value: view,
                              child: Text(
                                atlasCommandCenterActionViewLabel(view),
                              ),
                            ),
                      )
                      .toList(growable: false),
                  onChanged: (view) {
                    if (view != null) {
                      setState(() => selectedView = view);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<AtlasCanonicalPriority?>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<AtlasCanonicalPriority?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...AtlasCanonicalPriority.values.map(
                      (priority) => DropdownMenuItem<AtlasCanonicalPriority?>(
                        value: priority,
                        child: Text(atlasCanonicalPriorityLabel(priority)),
                      ),
                    ),
                  ],
                  onChanged: (priority) {
                    setState(() => selectedPriority = priority);
                  },
                ),
              ),
              Chip(label: Text('${visibleActions.length} exibida(s)')),
            ],
          ),
        ),
        Expanded(
          child: visibleActions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma ação corresponde aos filtros selecionados.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: visibleActions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final action = visibleActions[index];

                    return _ActionCard(
                      action: action,
                      onStatusChanged: (status) =>
                          controller.updateStatus(action, status),
                      lastUpdateAt:
                          controller.latestUpdateFor(action.id),
                      needsFollowUp:
                          controller.isWithoutRecentFollowUp(action),
                      onEditExecution: () => _editExecution(action),
                      onAddFollowUp: () => _addFollowUp(action),
                      onOpenHistory: () => _openHistory(action),
                      onDelete: () => controller.delete(action),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openAdvancedEconomicScenarios() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasEconomicScenarioScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openExecutive360() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasExecutive360Screen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openPeopleManagement() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasPeopleManagementScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openCommercialIntelligence() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasCommercialScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openClimateIntelligence() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasClimateScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openEsg() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasEsgScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openPastureStrategy() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasPastureStrategyScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openAgriculture() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasAgricultureScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openHealthStrategy() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasHealthStrategyScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openNutritionStrategy() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasNutritionStrategyScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openEconomicIntelligence() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasEconomicIntelligenceScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openReproductiveStrategy() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasReproductiveStrategyScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openAssetMaintenance() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasAssetMaintenanceScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openInventoryManagement() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasInventoryManagementScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openPastureManagement() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasPastureManagementScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openNutritionIntelligence() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasNutritionIntelligenceScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openHealthIntelligence() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasHealthIntelligenceScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openReproductiveIntelligence() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasReproductiveIntelligenceScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openFinancialManagement() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasFinancialManagementScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openExecutiveIntelligence() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasExecutiveIntelligenceScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openResultsIntelligence() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasResultsIntelligenceScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openStrategyPerformance() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasStrategyPerformanceScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openTeamManagement() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasTeamManagementScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openDecisionMonitoring() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasMeetingDecisionMonitoringScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openExecutionMeetings() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasExecutionMeetingScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openWeeklyReview() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasExecutionWeeklyReviewScreen(
          actionController: controller,
        ),
      ),
    );
  }

  Future<void> _openAttentionCenter() async {
    final actionId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => AtlasActionAttentionScreen(
          actionController: controller,
        ),
      ),
    );

    if (actionId == null || !mounted) {
      return;
    }

    setState(() {
      selectedView = AtlasCommandCenterActionView.all;
      selectedPriority = null;
      searchController.text = actionId;
    });

    searchController.clear();

    final action = controller.actions
        .where((item) => item.id == actionId)
        .cast<AtlasCommandCenterAction?>()
        .firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    if (action != null) {
      searchController.text = action.title;
    }
  }

  Future<void> _editExecution(AtlasCommandCenterAction action) async {
    var responsibleName = action.responsibleName;
    var responsibleId = action.responsibleId;
    final impact = TextEditingController(
      text: action.expectedFinancialImpact == 0
          ? ''
          : action.expectedFinancialImpact.toStringAsFixed(2),
    );
    final notes = TextEditingController(text: action.notes);
    var dueAt = action.dueAt;
    var progress = action.progressPercent.toDouble();

    final result = await showDialog<_ExecutionResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar execução'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Responsável'),
                    subtitle: Text(
                      responsibleName.trim().isEmpty
                          ? 'Nenhuma pessoa selecionada'
                          : responsibleName,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selected =
                          await Navigator.of(dialogContext)
                              .push<AtlasTeamMember?>(
                        MaterialPageRoute<AtlasTeamMember?>(
                          builder: (_) => AtlasTeamMemberSelector(
                            farmName: controller.farmName,
                            selectedMemberId: responsibleId,
                          ),
                        ),
                      );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      setDialogState(() {
                        responsibleId = selected?.id;
                        responsibleName = selected?.name ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: impact,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Impacto financeiro esperado (R\$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Prazo'),
                    subtitle: Text(
                      dueAt == null
                          ? 'Sem prazo'
                          : DateFormat('dd/MM/yyyy HH:mm').format(dueAt!),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () async {
                        final current = dueAt ?? DateTime.now();
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: current,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (date == null || !dialogContext.mounted) return;
                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(current),
                        );
                        if (time == null) return;
                        setDialogState(() {
                          dueAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                    ),
                  ),
                  Text('Progresso: ${progress.round()}%'),
                  Slider(
                    value: progress,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (value) {
                      setDialogState(() => progress = value);
                    },
                  ),
                  TextField(
                    controller: notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = impact.text
                    .trim()
                    .replaceAll('.', '')
                    .replaceAll(',', '.');
                Navigator.of(dialogContext).pop(
                  _ExecutionResult(
                    responsibleName: responsibleName,
                    responsibleId: responsibleId,
                    dueAt: dueAt,
                    progressPercent: progress.round(),
                    expectedFinancialImpact: double.tryParse(value) ?? 0,
                    notes: notes.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    impact.dispose();
    notes.dispose();

    if (result == null) return;

    await controller.updateExecution(
      action: action,
      responsibleName: result.responsibleName,
      responsibleId: result.responsibleId,
      dueAt: result.dueAt,
      progressPercent: result.progressPercent,
      expectedFinancialImpact: result.expectedFinancialImpact,
      notes: result.notes,
    );
  }
  Future<void> _addFollowUp(
    AtlasCommandCenterAction action,
  ) async {
    final noteController = TextEditingController();

    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Registrar acompanhamento'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: noteController,
              autofocus: true,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Atualização da execução',
                hintText:
                    'Descreva o que foi realizado, impedimentos '
                    'e o próximo passo.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                final value = noteController.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Registrar'),
            ),
          ],
        );
      },
    );

    noteController.dispose();

    if (note == null) {
      return;
    }

    await controller.addFollowUp(
      action: action,
      note: note,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Acompanhamento registrado com sucesso.',
        ),
      ),
    );
  }

  Future<void> _openHistory(
    AtlasCommandCenterAction action,
  ) async {
    final updates = await controller.loadUpdates(action);

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Histórico — ${action.title}'),
          content: SizedBox(
            width: 620,
            height: 460,
            child: updates.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum acompanhamento foi registrado.',
                    ),
                  )
                : ListView.separated(
                    itemCount: updates.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 24),
                    itemBuilder: (context, index) {
                      return _ActionUpdateTile(
                        update: updates[index],
                      );
                    },
                  ),
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

}


class _ActionUpdateTile extends StatelessWidget {
  const _ActionUpdateTile({
    required this.update,
  });

  final AtlasCommandCenterActionUpdate update;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text('${update.progressPercent}%'),
      ),
      title: Text(
        update.note,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${update.responsibleName.trim().isEmpty ? 'Sem responsável' : update.responsibleName} • '
          '${DateFormat('dd/MM/yyyy HH:mm').format(update.createdAt)}',
        ),
      ),
    );
  }
}

class _ExecutionResult {
  const _ExecutionResult({
    required this.responsibleName,
    required this.responsibleId,
    required this.dueAt,
    required this.progressPercent,
    required this.expectedFinancialImpact,
    required this.notes,
  });

  final String responsibleName;
  final String? responsibleId;
  final DateTime? dueAt;
  final int progressPercent;
  final double expectedFinancialImpact;
  final String notes;
}

class _ActionAnalyticsHeader extends StatelessWidget {
  const _ActionAnalyticsHeader({required this.analytics});

  final AtlasCommandCenterActionAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          Chip(
            avatar: const Icon(Icons.pending_actions, size: 17),
            label: Text('${analytics.open} aberta(s)'),
          ),
          Chip(
            avatar: const Icon(Icons.warning_amber_rounded, size: 17),
            label: Text('${analytics.overdue} atrasada(s)'),
          ),
          Chip(
            avatar: const Icon(Icons.task_alt, size: 17),
            label: Text('${analytics.completed} concluída(s)'),
          ),
          Chip(
            avatar: const Icon(Icons.percent, size: 17),
            label: Text(
              '${analytics.completionRatePercent.toStringAsFixed(0)}% concluído',
            ),
          ),
          Chip(
            avatar: const Icon(Icons.timer_outlined, size: 17),
            label: Text(
              'Média ${analytics.averageCompletionHours.toStringAsFixed(1)}h',
            ),
          ),
          Chip(
            avatar: const Icon(Icons.health_and_safety_outlined, size: 17),
            label: Text(
              'Saúde ${analytics.executionHealthPercent.toStringAsFixed(0)}%',
            ),
          ),
          Chip(
            avatar: const Icon(Icons.person_outline, size: 17),
            label: Text('${analytics.withResponsible} com responsável'),
          ),
          Chip(
            avatar: const Icon(Icons.trending_up, size: 17),
            label: Text(
              '${analytics.averageProgressPercent.toStringAsFixed(0)}% progresso',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.onStatusChanged,
    required this.lastUpdateAt,
    required this.needsFollowUp,
    required this.onEditExecution,
    required this.onAddFollowUp,
    required this.onOpenHistory,
    required this.onDelete,
  });

  final AtlasCommandCenterAction action;
  final Future<void> Function(AtlasCanonicalStatus status) onStatusChanged;
  final DateTime? lastUpdateAt;
  final bool needsFollowUp;
  final VoidCallback onEditExecution;
  final VoidCallback onAddFollowUp;
  final VoidCallback onOpenHistory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    action.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'execution') {
                      onEditExecution();
                    } else if (value == 'follow_up') {
                      onAddFollowUp();
                    } else if (value == 'history') {
                      onOpenHistory();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'execution',
                      child: Text('Editar execução'),
                    ),
                    PopupMenuItem(
                      value: 'follow_up',
                      child: Text('Registrar acompanhamento'),
                    ),
                    PopupMenuItem(
                      value: 'history',
                      child: Text('Abrir histórico'),
                    ),
                    PopupMenuItem(value: 'delete', child: Text('Excluir ação')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(action.description),
            const SizedBox(height: 8),
            Text(
              action.recommendedAction,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: action.progressPercent / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Text(
              'Progresso: ${action.progressPercent}%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (action.hasResponsible) ...[
              const SizedBox(height: 6),
              Text('Responsável: ${action.responsibleName}'),
            ],
            if (action.expectedFinancialImpact != 0) ...[
              const SizedBox(height: 6),
              Text(
                'Impacto esperado: R\$ '
                '${action.expectedFinancialImpact.toStringAsFixed(2)}',
              ),
            ],
            if (action.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Observações: ${action.notes}'),
            ],
            if (needsFollowUp) ...[
              const SizedBox(height: 10),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.notification_important_outlined),
                title: Text(
                  'Ação sem acompanhamento recente',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Registre uma atualização para manter a execução acompanhada.',
                ),
              ),
            ],
            if (lastUpdateAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Último acompanhamento: '
                '${DateFormat('dd/MM/yyyy HH:mm').format(lastUpdateAt!)}',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Histórico'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAddFollowUp,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Acompanhamento'),
                ),
                OutlinedButton.icon(
                  onPressed: onEditExecution,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Editar execução'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text(atlasCanonicalPriorityLabel(action.priority))),
                Chip(
                  label: Text(
                    action.dueAt == null
                        ? 'Sem prazo'
                        : 'Prazo: ${DateFormat('dd/MM/yyyy HH:mm').format(action.dueAt!)}',
                  ),
                ),
                if (action.isOverdue)
                  const Chip(
                    avatar: Icon(Icons.warning_amber_rounded, size: 17),
                    label: Text('Atrasada'),
                  ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<AtlasCanonicalStatus>(
                    initialValue: action.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: AtlasCanonicalStatus.values
                        .map(
                          (status) => DropdownMenuItem<AtlasCanonicalStatus>(
                            value: status,
                            child: Text(atlasCanonicalStatusLabel(status)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (status) {
                      if (status != null) {
                        onStatusChanged(status);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
