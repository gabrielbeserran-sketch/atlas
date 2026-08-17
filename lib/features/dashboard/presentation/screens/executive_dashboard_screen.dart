import 'package:projeto_atlas/core/operational_intelligence/widgets/atlas_command_center_module_card.dart';
import 'package:projeto_atlas/core/release_candidate/atlas_release_candidate_screen.dart';
import 'package:projeto_atlas/core/services/atlas_canonical_operations_service.dart';
import 'package:projeto_atlas/features/consultancy_workflow/presentation/screens/atlas_consultancy_workflow_screen.dart';
import 'package:projeto_atlas/core/system_center/atlas_system_center_screen.dart';
import 'package:projeto_atlas/core/foundation/atlas_foundation_center_screen.dart';
import 'package:projeto_atlas/core/orchestrator/atlas_orchestrator_dashboard.dart';
import 'package:projeto_atlas/features/observability/presentation/screens/atlas_observability_dashboard.dart';
import 'package:projeto_atlas/core/integration/atlas_integration_core_screen.dart';
import 'package:projeto_atlas/features/sync_platform/presentation/screens/atlas_sync_dashboard_screen.dart';
import 'package:projeto_atlas/features/command_center/presentation/screens/atlas_command_center_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/presentation/screens/atlas_enterprise_24a_screen.dart';
import 'package:projeto_atlas/features/quality_center/presentation/screens/atlas_quality_center_screen.dart';
import 'package:projeto_atlas/features/data_governance/presentation/screens/atlas_data_governance_screen.dart';
import 'package:projeto_atlas/features/reporting/presentation/screens/atlas_reports_dashboard.dart';
import 'package:projeto_atlas/features/offline_field/presentation/screens/atlas_offline_field_screen.dart';
import 'package:projeto_atlas/features/consultancy_hub/presentation/screens/atlas_consultancy_dashboard.dart';
import 'package:projeto_atlas/features/integration_hub/presentation/screens/atlas_integration_center_screen.dart';
import 'package:projeto_atlas/features/unified_workflow/presentation/screens/atlas_unified_workflow_screen.dart';
import 'package:projeto_atlas/features/farm_operations/presentation/screens/atlas_operations_center_screen.dart';
import 'package:projeto_atlas/features/performance_intelligence/presentation/screens/atlas_performance_dashboard_screen.dart';
import 'package:projeto_atlas/features/predictive_ai/presentation/screens/atlas_predictive_ai_screen.dart';
import 'package:projeto_atlas/features/strategic_execution_engine/presentation/screens/atlas_execution_engine_screen.dart';
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/investment_capital_allocation/presentation/screens/atlas_investment_capital_screen.dart';
import 'package:projeto_atlas/features/strategic_scenario_planning/presentation/screens/atlas_strategic_scenario_planning_screen.dart';
import 'package:projeto_atlas/features/strategic_alignment/presentation/screens/atlas_strategic_alignment_screen.dart';
import 'package:projeto_atlas/features/strategic_capacity/presentation/screens/atlas_strategic_capacity_screen.dart';
import 'package:projeto_atlas/features/portfolio_management/presentation/screens/atlas_portfolio_management_screen.dart';
import 'package:projeto_atlas/features/value_governance/presentation/screens/atlas_value_governance_screen.dart';
import 'package:projeto_atlas/features/benefits_realization/presentation/screens/atlas_benefits_realization_screen.dart';
import 'package:projeto_atlas/features/strategy_execution/presentation/screens/atlas_strategy_execution_screen.dart';
import 'package:projeto_atlas/features/decision_intelligence_lab/presentation/screens/atlas_decision_intelligence_lab_screen.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/presentation/screens/atlas_recommendation_intelligence_screen.dart';
import 'package:projeto_atlas/features/knowledge_learning/presentation/screens/atlas_knowledge_learning_screen.dart';
import 'package:projeto_atlas/features/continuous_improvement/presentation/screens/atlas_continuous_improvement_screen.dart';
import 'package:projeto_atlas/features/performance_center/presentation/screens/atlas_performance_center_screen.dart';
import 'package:projeto_atlas/features/action_plan/presentation/screens/atlas_action_plan_screen.dart';
import 'package:projeto_atlas/features/farm_audit/presentation/screens/atlas_farm_audit_screen.dart';
import 'package:projeto_atlas/features/autonomous_consultant/presentation/screens/atlas_autonomous_consultant_screen.dart';
import 'package:projeto_atlas/features/digital_twin/presentation/screens/atlas_digital_twin_screen.dart';
import 'package:projeto_atlas/features/scenario_simulator/presentation/screens/atlas_scenario_simulator_screen.dart';
import 'package:projeto_atlas/features/optimization_engine/presentation/screens/atlas_optimization_screen.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_analytics_service.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_service.dart';
import 'package:projeto_atlas/features/executive_brain/domain/services/atlas_event_analytics_brain_bridge.dart';
import 'package:projeto_atlas/features/executive_brain/domain/services/atlas_executive_brain_canonical_service.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_center_screen.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/atlas_bi/data/services/atlas_bi_loader_service.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/services/atlas_bi_service.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_forecast.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/services/atlas_bi_forecast_service.dart';
import 'package:projeto_atlas/features/atlas_bi/presentation/screens/atlas_bi_hub_screen.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_benchmark.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/services/atlas_bi_benchmark_service.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/models/atlas_bi_analytics_data.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/services/atlas_bi_analytics_service.dart';
import 'package:projeto_atlas/features/executive_intelligence/domain/models/atlas_executive_intelligence_data.dart';
import 'package:projeto_atlas/features/executive_intelligence/domain/services/atlas_executive_intelligence_service.dart';
import 'package:projeto_atlas/features/executive_ai_advisor/domain/models/atlas_executive_ai_advisor_data.dart';
import 'package:projeto_atlas/features/executive_ai_advisor/domain/services/atlas_executive_ai_advisor_service.dart';
import 'package:projeto_atlas/features/decision_engine/domain/models/atlas_decision_engine_data.dart';
import 'package:projeto_atlas/features/decision_engine/domain/services/atlas_decision_engine_service.dart';
import 'package:projeto_atlas/features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart';
import 'package:projeto_atlas/features/predictive_analytics/domain/services/atlas_predictive_analytics_service.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/models/atlas_workflow_data.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/services/atlas_workflow_service.dart';
import 'package:projeto_atlas/features/decision_engine_v2/domain/models/atlas_decision_engine_v2_data.dart';
import 'package:projeto_atlas/features/decision_engine_v2/domain/services/atlas_decision_engine_v2_service.dart';
import 'package:projeto_atlas/features/decision_engine_v2/domain/adapters/atlas_decision_engine_v2_contract_adapter.dart';
import 'package:projeto_atlas/features/mission_control/domain/models/atlas_mission_control_data.dart';
import 'package:projeto_atlas/features/mission_control/domain/services/atlas_mission_control_service.dart';
import 'package:projeto_atlas/features/mission_control/presentation/screens/atlas_mission_control_screen.dart';
import 'package:projeto_atlas/features/atlas_os/domain/models/atlas_os_data.dart';
import 'package:projeto_atlas/features/atlas_os/domain/services/atlas_os_service.dart';
import 'package:projeto_atlas/features/atlas_os/presentation/screens/atlas_os_screen.dart';
import 'package:projeto_atlas/features/atlas_intelligence/domain/models/atlas_intelligence_data.dart';
import 'package:projeto_atlas/features/atlas_intelligence/domain/services/atlas_intelligence_service.dart'
    as intelligence;
import 'package:projeto_atlas/features/executive_core/domain/models/atlas_executive_core_data.dart';
import 'package:projeto_atlas/features/executive_core/domain/services/atlas_executive_core_service.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';
import 'package:projeto_atlas/features/executive_brain/presentation/screens/atlas_executive_brain_screen.dart';
import 'package:projeto_atlas/features/strategy_center/data/services/atlas_strategy_loader_service.dart';
import 'package:projeto_atlas/features/strategy_center/domain/models/atlas_strategy_data.dart';
import 'package:projeto_atlas/features/strategy_center/domain/services/atlas_strategy_service.dart';
import 'package:projeto_atlas/features/strategy_center/presentation/screens/atlas_strategy_center_screen.dart';
import 'package:projeto_atlas/features/executive_goals/data/services/atlas_executive_goal_history_storage_service.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal_history.dart';
import 'package:projeto_atlas/features/executive_goals/domain/services/atlas_executive_goal_history_service.dart';
import 'package:projeto_atlas/features/executive_goals/presentation/screens/atlas_executive_goal_history_screen.dart';
import 'package:projeto_atlas/features/executive_goals/data/services/atlas_executive_goal_storage_service.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';
import 'package:projeto_atlas/features/executive_goals/domain/services/atlas_executive_goal_service.dart';
import 'package:projeto_atlas/features/executive_goals/presentation/screens/atlas_executive_goals_screen.dart';
import 'package:projeto_atlas/features/executive_kpis/data/services/atlas_executive_kpi_history_storage_service.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi_history.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/services/atlas_executive_kpi_history_service.dart';
import 'package:projeto_atlas/features/executive_kpis/data/services/atlas_executive_kpi_loader_service.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/services/atlas_executive_kpi_service.dart';
import 'package:projeto_atlas/features/executive_kpis/presentation/screens/atlas_executive_kpis_screen.dart';
import 'package:projeto_atlas/features/executive_alerts/data/services/atlas_executive_alert_loader_service.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/services/atlas_executive_alert_service.dart';
import 'package:projeto_atlas/features/executive_alerts/presentation/screens/atlas_executive_alerts_screen.dart';
import 'package:projeto_atlas/features/atlas_ai/data/services/atlas_ai_operation_actions_loader_service.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_operation_actions.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/services/atlas_ai_operation_actions_service.dart';
import 'package:projeto_atlas/features/atlas_ai/presentation/screens/atlas_ai_operation_actions_screen.dart';
import 'package:projeto_atlas/features/diagnostics/data/services/atlas_comparative_diagnostic_loader_service.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_comparative_diagnostic_data.dart';
import 'package:projeto_atlas/features/diagnostics/domain/services/atlas_comparative_diagnostic_service.dart';
import 'package:projeto_atlas/features/diagnostics/presentation/screens/atlas_comparative_diagnostic_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm/presentation/screens/farm_detail_screen.dart';
import 'package:projeto_atlas/features/copilot/presentation/screens/atlas_copilot_screen.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_operations_intelligence_service.dart'
    as dashboard_intelligence;
import 'package:projeto_atlas/features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/executive_decision_service.dart';
import 'package:projeto_atlas/features/dashboard/presentation/screens/executive_decision_center_screen.dart';
import 'package:projeto_atlas/features/dashboard/data/services/executive_dashboard_excel_service.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/executive_opinion_service.dart';
import 'package:projeto_atlas/features/dashboard/presentation/widgets/executive_opinion_card.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/executive_dashboard_data.dart'
    as intelligence;
import 'package:projeto_atlas/features/dashboard/domain/services/executive_dashboard_service.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_history_storage_service.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_storage_service.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';
import 'package:projeto_atlas/features/reports/presentation/screens/report_action_list_screen.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_action_analytics_card.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  State<ExecutiveDashboardScreen> createState() {
    return _ExecutiveDashboardScreenState();
  }
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen> {
  final ReportActionStorageService actionStorage = ReportActionStorageService();

  final ReportActionHistoryStorageService historyStorage =
      ReportActionHistoryStorageService();

  final ExecutiveDashboardService intelligenceService =
      const ExecutiveDashboardService();

  final ExecutiveOpinionService opinionService =
      const ExecutiveOpinionService();

  final ExecutiveDashboardExcelService excelService =
      ExecutiveDashboardExcelService();

  final ExecutiveDecisionService decisionService =
      const ExecutiveDecisionService();

  final dashboard_intelligence.AtlasOperationsIntelligenceService
  atlasIntelligenceService =
      const dashboard_intelligence.AtlasOperationsIntelligenceService();

  final AtlasComparativeDiagnosticLoaderService comparativeLoaderService =
      AtlasComparativeDiagnosticLoaderService();

  final AtlasComparativeDiagnosticService comparativeDiagnosticService =
      const AtlasComparativeDiagnosticService();

  final AtlasAiOperationActionsLoaderService operationActionsLoaderService =
      AtlasAiOperationActionsLoaderService();

  final AtlasAiOperationActionsService operationActionsService =
      const AtlasAiOperationActionsService();

  final AtlasExecutiveAlertLoaderService executiveAlertLoaderService =
      AtlasExecutiveAlertLoaderService();

  final AtlasExecutiveAlertService executiveAlertService =
      const AtlasExecutiveAlertService();

  final AtlasExecutiveKpiLoaderService executiveKpiLoaderService =
      AtlasExecutiveKpiLoaderService();

  final AtlasExecutiveKpiService executiveKpiService =
      const AtlasExecutiveKpiService();

  final AtlasExecutiveKpiHistoryStorageService executiveKpiHistoryStorage =
      const AtlasExecutiveKpiHistoryStorageService();

  final AtlasExecutiveKpiHistoryService executiveKpiHistoryService =
      const AtlasExecutiveKpiHistoryService();

  final AtlasExecutiveGoalStorageService executiveGoalStorageService =
      const AtlasExecutiveGoalStorageService();

  final AtlasExecutiveGoalService executiveGoalService =
      const AtlasExecutiveGoalService();

  final AtlasExecutiveGoalHistoryStorageService
  executiveGoalHistoryStorageService =
      const AtlasExecutiveGoalHistoryStorageService();

  final AtlasExecutiveGoalHistoryService executiveGoalHistoryService =
      const AtlasExecutiveGoalHistoryService();

  final AtlasStrategyLoaderService strategyLoaderService =
      const AtlasStrategyLoaderService();

  final AtlasStrategyService strategyService = const AtlasStrategyService();

  final AtlasBiLoaderService biLoaderService = const AtlasBiLoaderService();

  final AtlasBiService biService = const AtlasBiService();

  final AtlasBiForecastService biForecastService =
      const AtlasBiForecastService();

  final AtlasBiBenchmarkService biBenchmarkService =
      const AtlasBiBenchmarkService();

  final AtlasBiAnalyticsService biAnalyticsService =
      const AtlasBiAnalyticsService();

  final AtlasExecutiveIntelligenceService executiveIntelligenceEngine =
      const AtlasExecutiveIntelligenceService();

  final AtlasExecutiveAiAdvisorService executiveAdvisorEngine =
      const AtlasExecutiveAiAdvisorService();

  final AtlasDecisionEngineService decisionEngine =
      const AtlasDecisionEngineService();

  final AtlasPredictiveAnalyticsService predictiveAnalyticsService =
      const AtlasPredictiveAnalyticsService();

  final AtlasWorkflowService workflowService = const AtlasWorkflowService();

  final AtlasDecisionEngineV2Service decisionEngineV2Service =
      const AtlasDecisionEngineV2Service();

  final AtlasMissionControlService missionControlService =
      const AtlasMissionControlService();

  final AtlasOsService atlasOsService = const AtlasOsService();

  final intelligence.AtlasIntelligenceService atlasIntelligenceEngineService =
      const intelligence.AtlasIntelligenceService();

  final AtlasExecutiveCoreService executiveCoreService =
      const AtlasExecutiveCoreService();

  final AtlasExecutiveBrainCanonicalService executiveBrainService =
      const AtlasExecutiveBrainCanonicalService();

  final AtlasCanonicalOperationsService canonicalOperationsService =
      const AtlasCanonicalOperationsService();

  final AtlasEventAnalyticsService eventAnalyticsService =
      const AtlasEventAnalyticsService();

  final AtlasEventAnalyticsBrainBridge eventAnalyticsBrainBridge =
      const AtlasEventAnalyticsBrainBridge();

  List<ReportActionItemData> actions = [];

  Map<String, List<ReportActionHistoryData>> historyByActionId = {};

  intelligence.ExecutiveDashboardData? intelligenceData;

  ExecutiveOpinionData? executiveOpinion;
  ExecutiveDecisionData? decisionData;
  dashboard_intelligence.AtlasIntelligenceBrief? atlasIntelligenceBrief;

  AtlasComparativeDiagnosticData? comparativeDiagnosticData;

  AtlasAiOperationActions? operationActionsData;

  AtlasExecutiveAlertSummary? executiveAlertData;

  AtlasExecutiveKpiDashboardData? executiveKpiData;

  AtlasExecutiveKpiHistorySummary? executiveKpiHistoryData;

  AtlasExecutiveGoalDashboardData? executiveGoalData;

  AtlasExecutiveGoalHistorySummary? executiveGoalHistoryData;

  AtlasStrategyData? strategyData;

  AtlasBiData? atlasBiData;

  AtlasBiForecastDashboardData? atlasBiForecastData;

  AtlasBiBenchmarkData? atlasBiBenchmarkData;
  AtlasBiAnalyticsData? atlasBiAnalyticsData;
  AtlasExecutiveIntelligenceData? executiveIntelligenceData;
  AtlasExecutiveAiAdvisorData? executiveAdvisorData;
  AtlasDecisionEngineData? atlasDecisionEngineData;
  AtlasPredictiveAnalyticsData? predictiveAnalyticsData;
  AtlasWorkflowData? workflowData;
  AtlasDecisionEngineV2Data? decisionEngineV2Data;
  AtlasMissionControlData? missionControlData;
  AtlasOsData? atlasOsData;
  AtlasIntelligenceData? atlasIntelligenceEngineData;
  AtlasExecutiveCoreData? executiveCoreData;
  AtlasExecutiveBrainData? executiveBrainData;
  AtlasCanonicalOperationsData? canonicalOperationsData;

  List<FarmData> comparativeFarms = [];

  bool isLoading = true;
  bool isExportingExcel = false;

  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;

  @override
  void initState() {
    super.initState();

    AtlasReactiveRuntime.instance.start();

    reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.executiveDashboard,
      handler: _handleReactiveDashboardUpdate,
    );

    loadDashboard();
  }

  @override
  void dispose() {
    reactiveCoordinator.unregisterHandler(
      AtlasReactiveTarget.executiveDashboard,
    );
    super.dispose();
  }

  Future<void> _handleReactiveDashboardUpdate(
    AtlasReactiveUpdate update,
  ) async {
    if (!mounted ||
        !update.targets.contains(AtlasReactiveTarget.executiveDashboard)) {
      return;
    }

    await _refreshExecutiveChain(update);
  }

  Future<void> _refreshExecutiveChain(AtlasReactiveUpdate update) async {
    if (!mounted || isLoading || isExportingExcel) {
      return;
    }

    await loadDashboard();
  }

  List<ReportActionItemData> get openActions {
    final result = actions.where((action) {
      return action.isOpen;
    }).toList();

    result.sort(compareReportActions);

    return result;
  }

  intelligence.ExecutiveKpiData? findKpi(String id) {
    return intelligenceData?.findKpi(id);
  }

  int kpiInt(String id) {
    return findKpi(id)?.numericValue.round() ?? 0;
  }

  double kpiDouble(String id) {
    return findKpi(id)?.numericValue ?? 0;
  }

  int get pendingCount {
    return actions.where((action) {
      return action.isPending;
    }).length;
  }

  int get inProgressCount {
    return actions.where((action) {
      return action.isInProgress;
    }).length;
  }

  int get completedCount {
    return kpiInt('completed_actions');
  }

  int get overdueCount {
    return kpiInt('overdue_actions');
  }

  int get urgentCount {
    return kpiInt('urgent_actions');
  }

  int get withoutResponsibleCount {
    final alerts = intelligenceData?.alerts ?? const [];

    for (final alert in alerts) {
      if (alert.id == 'without_responsible') {
        return alert.count;
      }
    }

    return 0;
  }

  double get completionRate {
    return kpiDouble('completion_rate');
  }

  double get overdueRate {
    return kpiDouble('overdue_rate');
  }

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final loadedActions = await actionStorage.loadActions();

    final historyEntries = await Future.wait(
      loadedActions.map((action) async {
        final history = await historyStorage.loadActionHistory(action.id);

        return MapEntry(action.id, history);
      }),
    );

    if (!mounted) {
      return;
    }

    final loadedHistory = {
      for (final entry in historyEntries) entry.key: entry.value,
    };

    final dashboardData = intelligenceService.buildDashboard(
      actions: loadedActions,
      historyByActionId: loadedHistory,
      scopeLabel: 'Visão consolidada',
    );

    final opinion = opinionService.buildOpinion(dashboard: dashboardData);

    final decisionCenter = decisionService.buildDecisionCenter(
      actions: loadedActions,
      historyByActionId: loadedHistory,
      scopeLabel: 'Visão consolidada',
      consultantName: 'Gabriel',
    );

    final intelligenceBrief = atlasIntelligenceService.buildBrief(
      decisionData: decisionCenter,
      consultantName: 'Gabriel',
    );

    final comparativeLoad = await comparativeLoaderService.load();

    final comparativeData = comparativeDiagnosticService.buildComparison(
      diagnostics: comparativeLoad.diagnostics,
    );

    final operationActionsLoad = await operationActionsLoaderService.load();

    final operationActions = operationActionsService.build(
      actions: operationActionsLoad.actions,
    );

    final alertLoad = await executiveAlertLoaderService.load();

    final executiveAlerts = executiveAlertService.build(
      farms: alertLoad.inputs,
    );

    final kpiLoad = await executiveKpiLoaderService.load();

    final executiveKpis = executiveKpiService.build(farms: kpiLoad.farms);

    final existingKpiHistory = await executiveKpiHistoryStorage.load();

    final currentKpiSnapshot = executiveKpiHistoryService.createSnapshot(
      kpis: executiveKpis.kpis,
    );

    final mergedKpiHistory = executiveKpiHistoryService.mergeSnapshot(
      existingPoints: existingKpiHistory,
      snapshot: currentKpiSnapshot,
    );

    await executiveKpiHistoryStorage.save(mergedKpiHistory);

    final kpiHistorySummary = executiveKpiHistoryService.buildSummary(
      points: mergedKpiHistory,
    );

    final storedGoals = await executiveGoalStorageService.load();

    final synchronizedGoals = executiveGoalService.synchronizeWithKpis(
      goals: storedGoals,
      kpis: executiveKpis.kpis,
    );

    await executiveGoalStorageService.save(synchronizedGoals);

    final executiveGoals = executiveGoalService.buildDashboard(
      goals: synchronizedGoals,
    );

    final storedGoalHistory = await executiveGoalHistoryStorageService.load();

    final goalHistorySummary = executiveGoalHistoryService.buildSummary(
      events: storedGoalHistory,
      goals: synchronizedGoals,
    );

    final strategyInput = strategyLoaderService.buildInput(
      kpis: executiveKpis,
      goals: executiveGoals,
      goalHistory: goalHistorySummary,
    );

    final strategy = strategyService.build(input: strategyInput);

    final biInput = biLoaderService.buildInput(
      kpis: executiveKpis,
      kpiHistory: kpiHistorySummary,
      goals: executiveGoals,
      goalHistory: goalHistorySummary,
      strategy: strategy,
    );

    final biData = biService.build(input: biInput);

    final biForecastData = biForecastService.buildDashboard(
      indicators: biData.indicators,
      horizonDays: 90,
    );

    final biBenchmarkData = biBenchmarkService.build(data: biData);

    final biAnalyticsData = biAnalyticsService.build(
      input: AtlasBiAnalyticsInput(
        indicators: biData.indicators,
        defaultInvestmentValue: 10000.0,
      ),
    );

    final executiveIntelligence = executiveIntelligenceEngine.build(
      bi: biData,
      forecast: biForecastData,
      benchmark: biBenchmarkData,
      analytics: biAnalyticsData,
    );

    final executiveAdvisor = executiveAdvisorEngine.build(
      bi: biData,
      forecast: biForecastData,
      benchmark: biBenchmarkData,
      analytics: biAnalyticsData,
      intelligence: executiveIntelligence,
    );

    final decisionEngineData = decisionEngine.build(
      bi: biData,
      forecast: biForecastData,
      benchmark: biBenchmarkData,
      analytics: biAnalyticsData,
      intelligence: executiveIntelligence,
      advisor: executiveAdvisor,
    );

    final predictiveData = predictiveAnalyticsService.build(
      indicators: biData.indicators,
      horizonDays: 90,
    );

    final currentWorkflowData = workflowService.buildDashboard(
      workflows: const <AtlasWorkflow>[],
    );

    final decisionV2Data = decisionEngineV2Service.build(
      decisionEngine: decisionEngineData,
      predictive: predictiveData,
      workflow: currentWorkflowData,
    );

    final missionData = missionControlService.build(
      decisionEngine: decisionV2Data,
      predictive: predictiveData,
      workflow: currentWorkflowData,
      userName: 'Gabriel',
    );

    final currentAtlasOsData = atlasOsService.build(
      missionControl: missionData,
    );

    final currentIntelligenceEngineData = atlasIntelligenceEngineService.build(
      atlasOs: currentAtlasOsData,
    );

    final currentExecutiveCoreData = executiveCoreService.build(
      atlasOs: currentAtlasOsData,
      intelligence: currentIntelligenceEngineData,
    );

    final canonicalDecisions = decisionV2Data.toCanonicalDecisions();

    final baseExecutiveBrainData = executiveBrainService.build(
      executiveCore: currentExecutiveCoreData,
      canonicalDecisions: canonicalDecisions,
    );

    await AtlasEventLogService.instance.load();

    final currentEventAnalyticsData = eventAnalyticsService.build(
      entries: AtlasEventLogService.instance.entries,
    );

    final currentExecutiveBrainData = eventAnalyticsBrainBridge.enrich(
      brain: baseExecutiveBrainData,
      analytics: currentEventAnalyticsData,
    );

    final currentCanonicalOperations = canonicalOperationsService.build(
      decisions: canonicalDecisions,
      executiveAlerts: executiveAlerts,
      farmId: 'operation_consolidated',
      farmName: 'Operação consolidada',
      generatedAt: DateTime.now(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      actions = loadedActions;
      historyByActionId = loadedHistory;
      intelligenceData = dashboardData;
      executiveOpinion = opinion;
      decisionData = decisionCenter;
      atlasIntelligenceBrief = intelligenceBrief;
      comparativeDiagnosticData = comparativeData;
      operationActionsData = operationActions;
      executiveAlertData = executiveAlerts;
      executiveKpiData = executiveKpis;
      executiveKpiHistoryData = kpiHistorySummary;
      executiveGoalData = executiveGoals;
      executiveGoalHistoryData = goalHistorySummary;
      strategyData = strategy;
      atlasBiData = biData;
      atlasBiForecastData = biForecastData;
      atlasBiBenchmarkData = biBenchmarkData;
      atlasBiAnalyticsData = biAnalyticsData;
      executiveIntelligenceData = executiveIntelligence;
      executiveAdvisorData = executiveAdvisor;
      atlasDecisionEngineData = decisionEngineData;
      predictiveAnalyticsData = predictiveData;
      workflowData = currentWorkflowData;
      decisionEngineV2Data = decisionV2Data;
      missionControlData = missionData;
      atlasOsData = currentAtlasOsData;
      atlasIntelligenceEngineData = currentIntelligenceEngineData;
      executiveCoreData = currentExecutiveCoreData;
      executiveBrainData = currentExecutiveBrainData;
      canonicalOperationsData = currentCanonicalOperations;
      comparativeFarms = comparativeLoad.farms;
      isLoading = false;
    });
  }

  Future<void> openCommandCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasCommandCenterScreen();
        },
      ),
    );
  }

  Future<void> openEnterprisePlatform() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasEnterprise24AScreen();
        },
      ),
    );
  }

  Future<void> openQualityCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasQualityCenterScreen();
        },
      ),
    );
  }

  Future<void> openDataGovernance() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasDataGovernanceScreen();
        },
      ),
    );
  }

  Future<void> openReleaseCandidate() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AtlasReleaseCandidateScreen(),
      ),
    );
  }

  Future<void> openConsultancyWorkflow() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AtlasConsultancyWorkflowScreen(),
      ),
    );
  }

  Future<void> openSystemCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasSystemCenterScreen();
        },
      ),
    );
  }

  Future<void> openFoundationCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasFoundationCenterScreen();
        },
      ),
    );
  }

  Future<void> openOrchestrator() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasOrchestratorDashboard();
        },
      ),
    );
  }

  Future<void> openObservabilityCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasObservabilityDashboard();
        },
      ),
    );
  }

  Future<void> openIntegrationCore() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasIntegrationCoreScreen();
        },
      ),
    );
  }

  Future<void> openSyncPlatform() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AtlasSyncDashboardScreen();
        },
      ),
    );
  }

  Future<void> openOfflineField() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AtlasOfflineFieldScreen(),
      ),
    );
  }

  Future<void> openConsultancyHub() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AtlasConsultancyDashboard(),
      ),
    );
  }

  Future<void> openReportingCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasReportsDashboard();
        },
      ),
    );
  }

  Future<void> openIntegrationHub() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AtlasIntegrationCenterScreen(),
      ),
    );
  }

  Future<void> openUnifiedWorkflow() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AtlasUnifiedWorkflowScreen(),
      ),
    );
  }

  Future<void> openFarmOperationsCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AtlasOperationsCenterScreen(),
      ),
    );
  }

  Future<void> openPredictiveAi() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AtlasPredictiveAiScreen()),
    );
  }

  Future<void> openPerformanceIntelligence() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasPerformanceDashboardScreen();
        },
      ),
    );
  }

  Future<void> openStrategicExecutionEngine() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasExecutionEngineScreen();
        },
      ),
    );
  }

  Future<void> openInvestmentCapitalAllocation() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasInvestmentCapitalScreen();
        },
      ),
    );
  }

  Future<void> openStrategicScenarioPlanning() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasStrategicScenarioPlanningScreen();
        },
      ),
    );
  }

  Future<void> openStrategicAlignment() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasStrategicAlignmentScreen();
        },
      ),
    );
  }

  Future<void> openStrategicCapacity() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasStrategicCapacityScreen();
        },
      ),
    );
  }

  Future<void> openPortfolioManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasPortfolioManagementScreen();
        },
      ),
    );
  }

  Future<void> openValueGovernance() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasValueGovernanceScreen();
        },
      ),
    );
  }

  Future<void> openBenefitsRealization() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasBenefitsRealizationScreen();
        },
      ),
    );
  }

  Future<void> openStrategyExecution() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasStrategyExecutionScreen();
        },
      ),
    );
  }

  Future<void> openDecisionIntelligenceLab() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasDecisionIntelligenceLabScreen();
        },
      ),
    );
  }

  Future<void> openRecommendationIntelligence() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasRecommendationIntelligenceScreen();
        },
      ),
    );
  }

  Future<void> openKnowledgeLearning() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasKnowledgeLearningScreen();
        },
      ),
    );
  }

  Future<void> openContinuousImprovement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasContinuousImprovementScreen();
        },
      ),
    );
  }

  Future<void> openPerformanceCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasPerformanceCenterScreen();
        },
      ),
    );
  }

  Future<void> openActionPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasActionPlanScreen();
        },
      ),
    );
  }

  Future<void> openFarmAudit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasFarmAuditScreen();
        },
      ),
    );
  }

  Future<void> openAutonomousConsultant() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasAutonomousConsultantScreen();
        },
      ),
    );
  }

  Future<void> openOptimizationEngine() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasOptimizationScreen();
        },
      ),
    );
  }

  Future<void> openScenarioSimulator() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasScenarioSimulatorScreen();
        },
      ),
    );
  }

  Future<void> openDigitalTwin() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasDigitalTwinScreen();
        },
      ),
    );
  }

  Future<void> openEventCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasEventCenterScreen();
        },
      ),
    );
  }

  Future<void> openAtlasOs() async {
    final data = atlasOsData;

    if (data == null || !data.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O Atlas OS ainda está preparando a visão operacional.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasOsScreen(
            data: data,
            executiveBrainData: executiveBrainData,
            onReactiveRefresh: _refreshExecutiveChain,
            onOpenExecutiveBrain: openExecutiveBrain,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openExecutiveBrain() async {
    final data = executiveBrainData;

    if (data == null || !data.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O Executive Brain ainda está consolidando a decisão oficial.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasExecutiveBrainScreen(
            data: data,
            onReactiveRefresh: (update) async {
              await loadDashboard();
              return executiveBrainData;
            },
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openMissionControl() async {
    final data = missionControlData;

    if (data == null || !data.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O Mission Control ainda está preparando o plano executivo.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasMissionControlScreen(
            data: data,
            executiveBrainData: executiveBrainData,
            onReactiveRefresh: _refreshExecutiveChain,
            onOpenExecutiveBrain: openExecutiveBrain,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openAtlasBi() async {
    final data = atlasBiData;

    if (data == null || !data.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ainda não existem dados suficientes para formar a Central Atlas BI.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasBiHubScreen(
            data: data,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openStrategyCenter() async {
    final data = strategyData;

    if (data == null || !data.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ainda não existem dados suficientes para formar a Central Estratégica.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasStrategyCenterScreen(
            data: data,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openExecutiveGoalHistory() async {
    final data = executiveGoalHistoryData;

    if (data == null || !data.hasHistory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ainda não existe histórico suficiente das metas.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasExecutiveGoalHistoryScreen(data: data);
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openExecutiveGoals() async {
    final data = executiveGoalData;

    if (data == null || !data.hasGoals) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ainda não existem metas. Crie uma meta na Central de KPIs.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasExecutiveGoalsScreen(
            data: data,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openExecutiveKpis() async {
    final data = executiveKpiData;

    if (data == null || !data.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ainda não existem indicadores suficientes para formar a Central de KPIs.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasExecutiveKpisScreen(
            data: data,
            history: executiveKpiHistoryData,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openExecutiveAlerts() async {
    final data = executiveAlertData;

    if (data == null || !data.hasAlerts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum alerta executivo foi identificado.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasExecutiveAlertsScreen(
            data: data,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
            onOpenArea: (farmName, area) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openOperationActions() async {
    final data = operationActionsData;

    if (data == null || !data.hasActions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ainda não existem ações do Atlas IA acompanhadas nas fazendas.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasAiOperationActionsScreen(
            data: data,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
            onOpenArea: (farmName, area) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openComparativeDiagnostic() async {
    final data = comparativeDiagnosticData;

    if (data == null || data.ranking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre fazendas e aguarde a geração dos diagnósticos para realizar a comparação.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasComparativeDiagnosticScreen(
            data: data,
            onOpenFarm: (farmName) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
            onOpenArea: (farmName, area) {
              Navigator.of(screenContext).pop();
              openFarmByName(farmName);
            },
          );
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openFarmByName(String farmName) async {
    FarmData? selectedFarm;

    for (final farm in comparativeFarms) {
      if (farm.name == farmName) {
        selectedFarm = farm;
        break;
      }
    }

    if (selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A fazenda "$farmName" não foi encontrada.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return FarmDetailScreen(farm: selectedFarm!);
        },
      ),
    );

    await loadDashboard();
  }

  Future<void> openCopilot() async {
    final brief = atlasIntelligenceBrief;

    if (brief == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O Copiloto Atlas ainda está preparando o contexto da operação.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasCopilotScreen(
            operationBrief: brief,
            executiveBrainData: executiveBrainData,
            onReactiveRefresh: _refreshExecutiveChain,
            onOpenExecutiveBrain: openExecutiveBrain,
            consultantName: 'Gabriel',
            onOpenIntelligence: () {
              Navigator.of(screenContext).pop();
              openAtlasIntelligence();
            },
            onOpenActions: () {
              Navigator.of(screenContext).pop();
              openActionListScreen();
            },
          );
        },
      ),
    );
  }

  Future<void> openAtlasIntelligence() async {
    final brief = atlasIntelligenceBrief;

    if (brief == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A Inteligência Atlas ainda está sendo preparada.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) {
          return AtlasOperationsIntelligenceScreen(
            brief: brief,
            onOpenCopilot: () {
              Navigator.of(screenContext).push(
                MaterialPageRoute<void>(
                  builder: (copilotContext) {
                    return AtlasCopilotScreen(
                      operationBrief: brief,
                      executiveBrainData: executiveBrainData,
                      onReactiveRefresh: _refreshExecutiveChain,
                      onOpenExecutiveBrain: openExecutiveBrain,
                      consultantName: 'Gabriel',
                      onOpenIntelligence: () {
                        Navigator.of(copilotContext).pop();
                      },
                      onOpenActions: () {
                        Navigator.of(copilotContext).pop();
                        Navigator.of(screenContext).pop();
                        openActionListScreen();
                      },
                    );
                  },
                ),
              );
            },
            onOpenDecisionCenter: () {
              Navigator.of(screenContext).pop();
              openDecisionCenter();
            },
            onOpenActions: () {
              Navigator.of(screenContext).pop();
              openActionListScreen();
            },
          );
        },
      ),
    );
  }

  Future<void> openDecisionCenter() async {
    final data = decisionData;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A Central de Decisão ainda está sendo preparada.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ExecutiveDecisionCenterScreen(
            data: data,
            onOpenActions: () {
              Navigator.of(context).pop();
              openActionListScreen();
            },
          );
        },
      ),
    );
  }

  Future<void> exportExecutiveDashboardExcel() async {
    final dashboard = intelligenceData;
    final opinion = executiveOpinion;

    if (dashboard == null || opinion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Os dados executivos ainda não estão disponíveis.'),
        ),
      );
      return;
    }

    if (isExportingExcel) {
      return;
    }

    setState(() {
      isExportingExcel = true;
    });

    try {
      await excelService.exportDashboard(
        dashboard: dashboard,
        opinion: opinion,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard Executivo exportado em Excel com sucesso.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o Excel: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExportingExcel = false;
        });
      }
    }
  }

  Future<void> openActionListScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const ReportActionListScreen();
        },
      ),
    );

    await loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Dashboard Executivo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Performance Center',
            onPressed: isLoading ? null : openPerformanceCenter,
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: 'Plano de Ação & Missões',
            onPressed: isLoading ? null : openActionPlan,
            icon: const Icon(Icons.flag_outlined),
          ),
          IconButton(
            tooltip: 'Auditoria Inteligente',
            onPressed: isLoading ? null : openFarmAudit,
            icon: const Icon(Icons.assignment_outlined),
          ),
          IconButton(
            tooltip: 'Consultor Autônomo',
            onPressed: isLoading ? null : openAutonomousConsultant,
            icon: const Icon(Icons.support_agent_outlined),
          ),
          IconButton(
            tooltip: 'Motor de Otimização',
            onPressed: isLoading ? null : openOptimizationEngine,
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          IconButton(
            tooltip: 'Simulador de Cenários',
            onPressed: isLoading ? null : openScenarioSimulator,
            icon: const Icon(Icons.science_outlined),
          ),
          IconButton(
            tooltip: 'Gêmeo Digital',
            onPressed: isLoading ? null : openDigitalTwin,
            icon: const Icon(Icons.hub_outlined),
          ),
          IconButton(
            tooltip: 'Central de Eventos',
            onPressed: isLoading ? null : openEventCenter,
            icon: const Icon(Icons.event_note_outlined),
          ),
          IconButton(
            tooltip: 'Executive Brain',
            onPressed:
                isLoading ||
                    executiveBrainData == null ||
                    !executiveBrainData!.hasData
                ? null
                : openExecutiveBrain,
            icon: const Icon(Icons.hub_outlined),
          ),
          IconButton(
            tooltip: 'Atlas OS',
            onPressed: isLoading || atlasOsData == null || !atlasOsData!.hasData
                ? null
                : openAtlasOs,
            icon: const Icon(Icons.memory_outlined),
          ),
          IconButton(
            tooltip: 'Mission Control',
            onPressed:
                isLoading ||
                    missionControlData == null ||
                    !missionControlData!.hasData
                ? null
                : openMissionControl,
            icon: const Icon(Icons.radar_outlined),
          ),
          IconButton(
            tooltip: 'Central Atlas BI',
            onPressed: isLoading || atlasBiData == null || !atlasBiData!.hasData
                ? null
                : openAtlasBi,
            icon: const Icon(Icons.hub_outlined),
          ),
          IconButton(
            tooltip: 'Central Estratégica',
            onPressed:
                isLoading || strategyData == null || !strategyData!.hasData
                ? null
                : openStrategyCenter,
            icon: const Icon(Icons.account_tree_outlined),
          ),
          IconButton(
            tooltip: 'Histórico das Metas',
            onPressed:
                isLoading ||
                    executiveGoalHistoryData == null ||
                    !executiveGoalHistoryData!.hasHistory
                ? null
                : openExecutiveGoalHistory,
            icon: const Icon(Icons.timeline_outlined),
          ),
          IconButton(
            tooltip: 'Metas Inteligentes',
            onPressed:
                isLoading ||
                    executiveGoalData == null ||
                    !executiveGoalData!.hasGoals
                ? null
                : openExecutiveGoals,
            icon: const Icon(Icons.flag_outlined),
          ),
          IconButton(
            tooltip: 'Indicadores Inteligentes',
            onPressed:
                isLoading ||
                    executiveKpiData == null ||
                    !executiveKpiData!.hasData
                ? null
                : openExecutiveKpis,
            icon: const Icon(Icons.monitor_heart_outlined),
          ),
          IconButton(
            tooltip: 'Alertas Inteligentes',
            onPressed:
                isLoading ||
                    executiveAlertData == null ||
                    !executiveAlertData!.hasAlerts
                ? null
                : openExecutiveAlerts,
            icon: const Icon(Icons.notification_important_outlined),
          ),
          IconButton(
            tooltip: 'Ações da Consultoria',
            onPressed:
                isLoading ||
                    operationActionsData == null ||
                    !operationActionsData!.hasActions
                ? null
                : openOperationActions,
            icon: const Icon(Icons.assignment_turned_in_outlined),
          ),
          IconButton(
            tooltip: 'Comparar Fazendas',
            onPressed:
                isLoading ||
                    comparativeDiagnosticData == null ||
                    comparativeDiagnosticData!.ranking.isEmpty
                ? null
                : openComparativeDiagnostic,
            icon: const Icon(Icons.compare_arrows_outlined),
          ),
          IconButton(
            tooltip: 'Copiloto Atlas',
            onPressed: isLoading || atlasIntelligenceBrief == null
                ? null
                : openCopilot,
            icon: const Icon(Icons.smart_toy_outlined),
          ),
          IconButton(
            tooltip: 'Inteligência Atlas',
            onPressed: isLoading || atlasIntelligenceBrief == null
                ? null
                : openAtlasIntelligence,
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          IconButton(
            tooltip: 'Central de Decisão',
            onPressed: isLoading || decisionData == null
                ? null
                : openDecisionCenter,
            icon: const Icon(Icons.psychology_outlined),
          ),
          if (isExportingExcel)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2.3),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Exportar Excel',
              onPressed: isLoading ? null : exportExecutiveDashboardExcel,
              icon: const Icon(Icons.table_view_outlined),
            ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading || isExportingExcel ? null : loadDashboard,
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            tooltip: 'Abrir ações gerenciais',
            onPressed: isExportingExcel ? null : openActionListScreen,
            icon: const Icon(Icons.assignment_turned_in_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExecutiveWelcomeHeader(
                              totalCount: actions.length,
                              completionRate: completionRate,
                              overdueCount: overdueCount,
                              isExportingExcel: isExportingExcel,
                              onExportExcel: exportExecutiveDashboardExcel,
                            ),
                            const SizedBox(height: 18),
                            const AtlasCommandCenterModuleCard(
                              module:
                                  AtlasCommandCenterModule.executiveDashboard,
                            ),
                            const SizedBox(height: 24),
                            ExecutiveKpiGrid(
                              totalCount: actions.length,
                              pendingCount: pendingCount,
                              inProgressCount: inProgressCount,
                              completedCount: completedCount,
                              overdueCount: overdueCount,
                              urgentCount: urgentCount,
                              completionRate: completionRate,
                              overdueRate: overdueRate,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Alertas executivos',
                              subtitle: 'Pontos que exigem atenção imediata.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveIntelligenceAlertsPanel(
                              alerts: intelligenceData?.alerts ?? const [],
                              onOpenActions: openActionListScreen,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Próximos vencimentos',
                              subtitle:
                                  'Ações abertas organizadas por prazo e prioridade.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveUpcomingActionsCard(
                              actions: buildUpcomingActions(openActions),
                              onOpenActions: openActionListScreen,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Desempenho operacional',
                              subtitle:
                                  'Distribuição por status, prioridade, responsável e fazenda.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveIntelligenceDistributionGrid(
                              data: intelligenceData!,
                            ),
                            const SizedBox(height: 28),
                            ReportActionAnalyticsCard(
                              actions: actions,
                              historyByActionId: historyByActionId,
                            ),
                            const SizedBox(height: 28),

                            ExecutiveSectionTitle(
                              title: 'Central de Comando',
                              subtitle:
                                  'Reúna briefing diário, prioridades, tarefas vencidas, alertas e ações recomendadas em um único painel.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveCommandCenterAccessCard(
                              onOpen: openCommandCenter,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Plataforma Enterprise',
                              subtitle:
                                  'Gerencie empresas, usuários, perfis de acesso, planos, segurança e auditoria administrativa.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveEnterprisePlatformAccessCard(
                              onOpen: openEnterprisePlatform,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Qualidade e Estabilidade',
                              subtitle:
                                  'Centralize o checklist técnico, as ocorrências e o índice de estabilidade do aplicativo.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveQualityCenterAccessCard(
                              onOpen: openQualityCenter,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Governança e Backup de Dados',
                              subtitle:
                                  'Proteja os dados locais, crie versões de recuperação e acompanhe a integridade das informações do Atlas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveDataGovernanceAccessCard(
                              onOpen: openDataGovernance,
                            ),
                            const SizedBox(height: 28),

                            ExecutiveSectionTitle(
                              title: 'Release Candidate 1.0',
                              subtitle:
                                  'Valide os critérios críticos, acompanhe o progresso e prepare a primeira versão estável do Atlas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveReleaseCandidateAccessCard(
                              onOpen: openReleaseCandidate,
                            ),
                            const SizedBox(height: 28),

                            ExecutiveSectionTitle(
                              title: 'Fluxo de Consultoria Veterinária',
                              subtitle:
                                  'Conduza clientes e propriedades do diagnóstico inicial até a entrega dos resultados.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveConsultancyWorkflowAccessCard(
                              onOpen: openConsultancyWorkflow,
                            ),
                            const SizedBox(height: 28),

                            ExecutiveSectionTitle(
                              title: 'Sistema e Configuração',
                              subtitle:
                                  'Centralize configurações globais, inventário técnico, arquitetura e integridade da plataforma.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveSystemCenterAccessCard(
                              onOpen: openSystemCenter,
                            ),
                            const SizedBox(height: 28),

                            ExecutiveSectionTitle(
                              title: 'Sprint Enterprise 1',
                              subtitle:
                                  'Consolide persistência, navegação, estado, componentes e testes em uma arquitetura progressiva.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveFoundationCenterAccessCard(
                              onOpen: openFoundationCenter,
                            ),
                            const SizedBox(height: 28),

                            ExecutiveSectionTitle(
                              title: 'Orquestração Central',
                              subtitle:
                                  'Coordene o pipeline de coleta, análise, decisão, automação e auditoria dos motores do Atlas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveOrchestratorAccessCard(
                              onOpen: openOrchestrator,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Observabilidade e Diagnósticos',
                              subtitle:
                                  'Monitore a saúde dos módulos, tempos de resposta, falhas e registros técnicos do Atlas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveObservabilityAccessCard(
                              onOpen: openObservabilityCenter,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Núcleo de Integração',
                              subtitle:
                                  'Centralize eventos, saúde dos módulos e comunicação entre todas as áreas do Atlas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveIntegrationCoreAccessCard(
                              onOpen: openIntegrationCore,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Sincronização e Nuvem',
                              subtitle:
                                  'Centralize a fila de sincronização, acompanhe pendências e prepare o Atlas para integração com a nuvem.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveSyncPlatformAccessCard(
                              onOpen: openSyncPlatform,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Aplicativo de Campo Offline',
                              subtitle:
                                  'Registre manejos e dados no campo sem internet e sincronize automaticamente quando a conexão voltar.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveOfflineFieldAccessCard(
                              onOpen: openOfflineField,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Relatórios e Documentos',
                              subtitle:
                                  'Crie relatórios técnicos, executivos, produtivos, reprodutivos e financeiros com a identidade da consultoria.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveReportingAccessCard(
                              onOpen: openReportingCenter,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Central da Consultoria',
                              subtitle:
                                  'Gerencie produtores, propriedades, visitas, mensalidades, planos de ação e a evolução da carteira de clientes.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveConsultancyHubAccessCard(
                              onOpen: openConsultancyHub,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Central de Integrações',
                              subtitle:
                                  'Importe, exporte e sincronize dados com planilhas, equipamentos, APIs e serviços externos.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveIntegrationHubAccessCard(
                              onOpen: openIntegrationHub,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Eventos e Automações',
                              subtitle:
                                  'Conecte os módulos do Atlas com regras automáticas, gatilhos, ações e histórico de execução.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveUnifiedWorkflowAccessCard(
                              onOpen: openUnifiedWorkflow,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Centro de Operações da Fazenda',
                              subtitle:
                                  'Planeje manejos, distribua responsáveis, acompanhe equipes, equipamentos, custos, prazos e execução diária.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveFarmOperationsAccessCard(
                              onOpen: openFarmOperationsCenter,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Performance Intelligence & KPI',
                              subtitle:
                                  'Consolide indicadores produtivos, financeiros, operacionais e estratégicos, compare metas e receba alertas de tendência.',
                            ),
                            const SizedBox(height: 14),
                            ExecutivePerformanceIntelligenceAccessCard(
                              onOpen: openPerformanceIntelligence,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Predictive Analytics & AI',
                              subtitle:
                                  'Simule mudanças produtivas, financeiras e operacionais antes de executá-las, com projeções, risco, confiança, ROI e payback.',
                            ),
                            const SizedBox(height: 14),
                            ExecutivePredictiveAiAccessCard(
                              onOpen: openPredictiveAi,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Strategic Execution Engine',
                              subtitle:
                                  'Transforme decisões e investimentos em atividades, responsáveis, recursos, prazos, custos, caminho crítico e alertas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveStrategicExecutionAccessCard(
                              onOpen: openStrategicExecutionEngine,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Investment & Capital Allocation',
                              subtitle:
                                  'Defina o orçamento, simule financiamentos e descubra a melhor combinação de investimentos para maximizar valor com risco controlado.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveInvestmentCapitalAccessCard(
                              onOpen: openInvestmentCapitalAllocation,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Planejamento de Cenários Estratégicos',
                              subtitle:
                                  'Simule investimentos, compare ROI, VPL, TIR, payback, riscos e impactos produtivos antes de decidir.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveStrategicScenarioPlanningAccessCard(
                              onOpen: openStrategicScenarioPlanning,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Alinhamento Estratégico & OKRs',
                              subtitle:
                                  'Conecte cada estratégia aos objetivos da fazenda e acompanhe contribuição, metas e resultados-chave.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveStrategicAlignmentAccessCard(
                              onOpen: openStrategicAlignment,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Capacidade & Dependências',
                              subtitle:
                                  'Detecte sobrecarga, dependências, conflitos de recursos e gargalos entre estratégias.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveStrategicCapacityAccessCard(
                              onOpen: openStrategicCapacity,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Portfolio Management Office',
                              subtitle:
                                  'Consolide estratégias, investimentos, capacidade, valor realizado e valor em risco em um único portfólio executivo.',
                            ),
                            const SizedBox(height: 14),
                            ExecutivePortfolioManagementAccessCard(
                              onOpen: openPortfolioManagement,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Governança de Valor',
                              subtitle:
                                  'Delibere sobre aprovação, correção, pausa ou encerramento dos investimentos estratégicos.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveValueGovernanceAccessCard(
                              onOpen: openValueGovernance,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Realização de Benefícios',
                              subtitle:
                                  'Compare promessa e resultado real em orçamento, ROI, progresso, indicadores e ganho econômico.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveBenefitsRealizationAccessCard(
                              onOpen: openBenefitsRealization,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Execução Estratégica',
                              subtitle:
                                  'Acompanhe os cenários aprovados por fases, marcos, orçamento, responsáveis e gates de decisão.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveStrategyExecutionAccessCard(
                              onOpen: openStrategyExecution,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Decision Intelligence Lab',
                              subtitle:
                                  'Compare investimentos, retorno, payback, risco, confiança e probabilidade de sucesso antes da execução.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveDecisionIntelligenceLabAccessCard(
                              onOpen: openDecisionIntelligenceLab,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Inteligência de Recomendações',
                              subtitle:
                                  'Gere recomendações explicáveis usando a auditoria, os protocolos e os casos já aprendidos pelo Atlas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveRecommendationIntelligenceAccessCard(
                              onOpen: openRecommendationIntelligence,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Conhecimento & Aprendizado',
                              subtitle:
                                  'Transforme missões concluídas em casos, protocolos, lições aprendidas e recomendações com confiança calculada.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveKnowledgeLearningAccessCard(
                              onOpen: openKnowledgeLearning,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Melhoria Contínua',
                              subtitle:
                                  'Reavalie resultados, detecte desvios e gere um novo ciclo de correções e recalibrações.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveContinuousImprovementAccessCard(
                              onOpen: openContinuousImprovement,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Atlas Performance Center',
                              subtitle:
                                  'Acompanhe KPIs, tendências, alertas, impacto realizado e o Atlas Execution Score.',
                            ),
                            const SizedBox(height: 14),
                            ExecutivePerformanceCenterAccessCard(
                              onOpen: openPerformanceCenter,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Plano de Ação & Missões',
                              subtitle:
                                  'Transforme a auditoria em missões executáveis, acompanhe prazos, responsáveis e progresso.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveActionPlanAccessCard(
                              onOpen: openActionPlan,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Auditoria Inteligente',
                              subtitle:
                                  'Avalie 12 áreas da fazenda, identifique gargalos, oportunidades e acompanhe o Atlas Farm Audit Index.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveFarmAuditAccessCard(onOpen: openFarmAudit),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Consultor Autônomo',
                              subtitle:
                                  'Receba diagnóstico executivo, ações priorizadas e uma estratégia recomendada a partir do estado vivo da fazenda.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveAutonomousConsultantAccessCard(
                              onOpen: openAutonomousConsultant,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Motor de Otimização',
                              subtitle:
                                  'Defina um objetivo e deixe o Atlas gerar, comparar e classificar estratégias automaticamente.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveOptimizationAccessCard(
                              onOpen: openOptimizationEngine,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Simulador de Cenários',
                              subtitle:
                                  'Teste decisões estratégicas sobre uma cópia do Digital Twin sem alterar os dados reais da fazenda.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveScenarioSimulatorAccessCard(
                              onOpen: openScenarioSimulator,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Gêmeo Digital da Fazenda',
                              subtitle:
                                  'Estado vivo e consolidado da operação, atualizado automaticamente pelos eventos do Atlas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveDigitalTwinAccessCard(
                              onOpen: openDigitalTwin,
                            ),
                            const SizedBox(height: 28),
                            ExecutiveSectionTitle(
                              title: 'Central de Eventos',
                              subtitle:
                                  'Histórico persistente de todas as mudanças operacionais e executivas do Atlas.',
                            ),
                            const SizedBox(height: 14),
                            ExecutiveEventCenterAccessCard(
                              onOpen: openEventCenter,
                            ),
                            const SizedBox(height: 28),
                            if (executiveBrainData != null &&
                                executiveBrainData!.hasData) ...[
                              ExecutiveSectionTitle(
                                title: 'Executive Brain',
                                subtitle:
                                    'Decisão oficial, estratégia central e planos unificados do Atlas.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveBrainAccessCard(
                                data: executiveBrainData!,
                                onOpen: openExecutiveBrain,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (atlasOsData != null &&
                                atlasOsData!.hasData) ...[
                              ExecutiveSectionTitle(
                                title: 'Atlas OS',
                                subtitle:
                                    'Saúde dos módulos, comandos operacionais e ciclo diário.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveAtlasOsAccessCard(
                                data: atlasOsData!,
                                onOpen: openAtlasOs,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (missionControlData != null &&
                                missionControlData!.hasData) ...[
                              ExecutiveSectionTitle(
                                title: 'Mission Control',
                                subtitle:
                                    'Prioridades globais, plano do dia, riscos, execução e impacto financeiro consolidado.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveMissionControlCard(
                                data: missionControlData!,
                                onOpen: openMissionControl,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (atlasBiData != null &&
                                atlasBiData!.hasData) ...[
                              ExecutiveSectionTitle(
                                title: 'Business Intelligence',
                                subtitle:
                                    'Indicadores, tendências, ranking e insights consolidados da operação.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveAtlasBiCard(
                                data: atlasBiData!,
                                onOpen: openAtlasBi,
                              ),
                              if (atlasBiForecastData != null &&
                                  atlasBiForecastData!.hasData) ...[
                                const SizedBox(height: 14),
                                ExecutiveAtlasBiForecastCard(
                                  data: atlasBiForecastData!,
                                  onOpen: openAtlasBi,
                                ),
                              ],
                              const SizedBox(height: 28),
                            ],
                            if (strategyData != null &&
                                strategyData!.hasData) ...[
                              ExecutiveSectionTitle(
                                title: 'Central Estratégica',
                                subtitle:
                                    'Objetivos, prioridades, iniciativas, riscos e oportunidades da operação.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveStrategyCard(
                                data: strategyData!,
                                onOpen: openStrategyCenter,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (executiveGoalHistoryData != null &&
                                executiveGoalHistoryData!.hasHistory) ...[
                              ExecutiveSectionTitle(
                                title: 'Evolução Estratégica',
                                subtitle:
                                    'Ritmo, risco e previsão de conclusão das metas da operação.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveGoalStrategyCard(
                                data: executiveGoalHistoryData!,
                                onOpen: openExecutiveGoalHistory,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (executiveGoalData != null &&
                                executiveGoalData!.hasGoals) ...[
                              ExecutiveSectionTitle(
                                title: 'Metas Inteligentes',
                                subtitle:
                                    'Objetivos, prazos e progresso das fazendas acompanhados automaticamente.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveGoalsCard(
                                data: executiveGoalData!,
                                onOpen: openExecutiveGoals,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (executiveKpiData != null &&
                                executiveKpiData!.hasData) ...[
                              ExecutiveSectionTitle(
                                title: 'Indicadores Inteligentes',
                                subtitle:
                                    'Metas, tendências e desempenho consolidado de todas as fazendas.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveKpisCard(
                                data: executiveKpiData!,
                                onOpen: openExecutiveKpis,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (executiveAlertData != null &&
                                executiveAlertData!.hasAlerts) ...[
                              ExecutiveSectionTitle(
                                title: 'Alertas Inteligentes',
                                subtitle:
                                    'Riscos, atrasos e situações que exigem resposta em todas as fazendas.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveAlertsCard(
                                data: executiveAlertData!,
                                onOpen: openExecutiveAlerts,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (operationActionsData != null &&
                                operationActionsData!.hasActions) ...[
                              ExecutiveSectionTitle(
                                title: 'Ações da Consultoria',
                                subtitle:
                                    'Acompanhe a execução das recomendações do Atlas IA em todas as fazendas.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveOperationActionsCard(
                                data: operationActionsData!,
                                onOpen: openOperationActions,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (comparativeDiagnosticData != null &&
                                comparativeDiagnosticData!
                                    .ranking
                                    .isNotEmpty) ...[
                              ExecutiveSectionTitle(
                                title: 'Diagnóstico Comparativo',
                                subtitle:
                                    'Compare o desempenho das fazendas e identifique onde atuar primeiro.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveComparativeDiagnosticCard(
                                data: comparativeDiagnosticData!,
                                onOpen: openComparativeDiagnostic,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (atlasIntelligenceBrief != null) ...[
                              ExecutiveSectionTitle(
                                title: 'Copiloto Atlas',
                                subtitle:
                                    'Converse com os dados da operação e receba respostas objetivas sobre prioridades, riscos e oportunidades.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveCopilotAccessCard(
                                brief: atlasIntelligenceBrief!,
                                onOpen: openCopilot,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (atlasIntelligenceBrief != null) ...[
                              ExecutiveSectionTitle(
                                title: 'Inteligência Atlas',
                                subtitle:
                                    'Situação geral, orientação do dia, riscos, oportunidades e análises estratégicas.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveAtlasIntelligenceAccessCard(
                                brief: atlasIntelligenceBrief!,
                                onOpen: openAtlasIntelligence,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (decisionData != null) ...[
                              ExecutiveSectionTitle(
                                title: 'Central de decisão inteligente',
                                subtitle:
                                    'Prioridades do dia, previsões, mapa de calor e orientação executiva.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveDecisionAccessCard(
                                data: decisionData!,
                                onOpen: openDecisionCenter,
                              ),
                              const SizedBox(height: 28),
                            ],
                            if (executiveOpinion != null) ...[
                              ExecutiveSectionTitle(
                                title: 'Parecer executivo inteligente',
                                subtitle:
                                    'Diagnóstico automático, riscos, oportunidades e prioridades da operação.',
                              ),
                              const SizedBox(height: 14),
                              ExecutiveOpinionCard(opinion: executiveOpinion!),
                              const SizedBox(height: 28),
                            ],
                            ExecutiveIntelligenceRecommendationCard(
                              data: intelligenceData!,
                              onOpenActions: openActionListScreen,
                            ),
                            const SizedBox(height: 34),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class ExecutiveCommandCenterAccessCard extends StatelessWidget {
  const ExecutiveCommandCenterAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF123B5D).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: Color(0xFF123B5D),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Command Center',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Veja o briefing executivo do dia, prioridades críticas, tarefas vencidas e a fila inteligente de ações.',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveQualityCenterAccessCard extends StatelessWidget {
  const ExecutiveQualityCenterAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Color(0xFF00695C),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Quality & Stability Center',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Acompanhe checklist de validação, ocorrências técnicas, itens críticos e a evolução da estabilidade do Atlas.',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveDataGovernanceAccessCard extends StatelessWidget {
  const ExecutiveDataGovernanceAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF455A64).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.backup_outlined,
                  color: Color(0xFF455A64),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Data Governance & Backup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Crie backups locais, restaure versões anteriores e acompanhe verificações de integridade dos dados.',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveEnterprisePlatformAccessCard extends StatelessWidget {
  const ExecutiveEnterprisePlatformAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF3949AB).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: Color(0xFF3949AB),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Enterprise Platform',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Administre empresas, usuários, planos, autenticação em duas etapas e rastreabilidade das alterações.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveReportingAccessCard extends StatelessWidget {
  const ExecutiveReportingAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF8A5A21).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF8A5A21),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Reporting & Document Intelligence',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Organize relatórios, pré-visualize documentos e prepare conteúdos técnicos da Beserra Consultoria Veterinária.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir relatórios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveOfflineFieldAccessCard extends StatelessWidget {
  const ExecutiveOfflineFieldAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E5F8A).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phonelink_lock_outlined,
                  color: Color(0xFF3E5F8A),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Aplicativo de Campo Offline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Registre pesagens, manejos, ocorrências e observações mesmo sem sinal, mantendo uma fila local pronta para sincronização.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir campo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveConsultancyHubAccessCard extends StatelessWidget {
  const ExecutiveConsultancyHubAccessCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: Color(0xFF6A1B9A),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Producer Relationship & Consultancy Hub',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Carteira de clientes, propriedades, visitas, indicadores, mensalidades e pendências da consultoria.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveIntegrationHubAccessCard extends StatelessWidget {
  const ExecutiveIntegrationHubAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF176B87).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Color(0xFF176B87),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Integration Hub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Centralize importações, exportações, sincronizações e futuras conexões com equipamentos de campo.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Integrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveUnifiedWorkflowAccessCard extends StatelessWidget {
  const ExecutiveUnifiedWorkflowAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B3F8C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: Color(0xFF5B3F8C),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Unified Event & Workflow Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Automatize respostas a eventos, conecte módulos e acompanhe cada ação executada pelo Atlas.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Automatizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveFarmOperationsAccessCard extends StatelessWidget {
  const ExecutiveFarmOperationsAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF175F55).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.agriculture_outlined,
                  color: Color(0xFF175F55),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centro de Operações da Fazenda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Organize a rotina de campo, acompanhe operações, equipes, equipamentos, custos e atrasos em uma agenda única.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Operar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutivePredictiveAiAccessCard extends StatelessWidget {
  const ExecutivePredictiveAiAccessCard({required this.onOpen, super.key});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF173E55).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.psychology_alt_outlined,
                color: Color(0xFF173E55),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predictive Analytics & AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Antecipe resultados, compare premissas e avalie retorno, risco e confiança antes de comprometer recursos.',
                    style: TextStyle(color: Colors.black54, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Simular'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ExecutivePerformanceIntelligenceAccessCard extends StatelessWidget {
  const ExecutivePerformanceIntelligenceAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF175F55).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: Color(0xFF175F55),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Intelligence & KPI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Acompanhe metas, resultados, tendências, scorecards e alertas inteligentes em uma visão consolidada.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Analisar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveStrategicExecutionAccessCard extends StatelessWidget {
  const ExecutiveStrategicExecutionAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF175F55).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: Color(0xFF175F55),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategic Execution Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Converta a estratégia em cronogramas, tarefas, responsáveis, recursos, indicadores SPI/CPI e alertas operacionais.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Executar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveInvestmentCapitalAccessCard extends StatelessWidget {
  const ExecutiveInvestmentCapitalAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A4C10).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF6A4C10),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment & Capital Allocation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Otimize orçamento, financiamento, retorno, risco e ordem de execução dos projetos.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Otimizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveStrategicScenarioPlanningAccessCard extends StatelessWidget {
  const ExecutiveStrategicScenarioPlanningAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_graph_outlined,
                  color: Color(0xFF00695C),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategic Scenario Planning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Compare futuros possíveis com simulações econômicas, produtivas, riscos e análise de sensibilidade.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Simular'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveStrategicAlignmentAccessCard extends StatelessWidget {
  const ExecutiveStrategicAlignmentAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF283593).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFF283593),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategic Alignment & OKR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Conecte iniciativas aos objetivos estratégicos e acompanhe metas, resultados-chave e contribuição real.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Alinhar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveStrategicCapacityAccessCard extends StatelessWidget {
  const ExecutiveStrategicCapacityAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF4527A0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Color(0xFF4527A0),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategic Capacity & Dependency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Analise capacidade da equipe, conflitos, dependências, prazos e concorrência por recursos.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Analisar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutivePortfolioManagementAccessCard extends StatelessWidget {
  const ExecutivePortfolioManagementAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspaces_outlined,
                  color: Color(0xFF0D47A1),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Management Office',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Visão consolidada de estratégias, investimentos, capacidade, valor capturado e valor em risco.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir PMO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveValueGovernanceAccessCard extends StatelessWidget {
  const ExecutiveValueGovernanceAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: const CircleAvatar(
          child: Icon(Icons.account_balance_outlined),
        ),
        title: const Text(
          'Value Governance Engine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Governança executiva para proteger valor e controlar desvios.',
        ),
        trailing: FilledButton(
          onPressed: onOpen,
          child: const Text('Governar'),
        ),
      ),
    );
  }
}

class ExecutiveBenefitsRealizationAccessCard extends StatelessWidget {
  const ExecutiveBenefitsRealizationAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: Color(0xFF00695C),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benefits Realization Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Meça se as estratégias estão entregando o orçamento, ROI, progresso e benefícios prometidos.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Medir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveStrategyExecutionAccessCard extends StatelessWidget {
  const ExecutiveStrategyExecutionAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.rocket_launch_outlined,
                  color: Color(0xFF1B5E20),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategy Execution Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Converta decisões aprovadas em fases, marcos, orçamento, responsáveis e gates de avanço.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Executar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveDecisionIntelligenceLabAccessCard extends StatelessWidget {
  const ExecutiveDecisionIntelligenceLabAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF6A1B9A),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decision Intelligence Lab',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Laboratório para testar cenários e comparar ROI, payback, risco, confiança e probabilidade de sucesso.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Simular'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveRecommendationIntelligenceAccessCard extends StatelessWidget {
  const ExecutiveRecommendationIntelligenceAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00838F).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF00838F),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommendation Intelligence',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Recomendações priorizadas com confiança, casos semelhantes, taxa de sucesso, prazo e impacto esperado.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Recomendar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveKnowledgeLearningAccessCard extends StatelessWidget {
  const ExecutiveKnowledgeLearningAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF5E35B1).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF5E35B1),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Knowledge & Learning Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Memória técnica com casos, protocolos, lições aprendidas, taxa de sucesso e confiança das recomendações.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Aprender'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveContinuousImprovementAccessCard extends StatelessWidget {
  const ExecutiveContinuousImprovementAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.autorenew,
                  color: Color(0xFF00897B),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continuous Improvement Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Compara execução e desempenho, identifica desvios e define o próximo ciclo de melhoria da fazenda.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutivePerformanceCenterAccessCard extends StatelessWidget {
  const ExecutivePerformanceCenterAccessCard({required this.onOpen, super.key});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00838F).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: Color(0xFF00838F),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Performance Center',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'KPIs, tendências, alertas, comparação antes × depois e score de execução.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Analisar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveActionPlanAccessCard extends StatelessWidget {
  const ExecutiveActionPlanAccessCard({required this.onOpen, super.key});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFF1565C0),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Action Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Plano mestre, missões, responsáveis, prazos, checklist e acompanhamento da execução.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Executar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveFarmAuditAccessCard extends StatelessWidget {
  const ExecutiveFarmAuditAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF6A1B9A),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Farm Audit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Auditoria técnica de 12 áreas, índice geral, ranking de problemas, oportunidades e evolução histórica.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Auditar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveAutonomousConsultantAccessCard extends StatelessWidget {
  const ExecutiveAutonomousConsultantAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.support_agent_outlined,
                  color: Color(0xFF00695C),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Autonomous Consultant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Analisa riscos, identifica gargalos, prioriza ações e associa a melhor estratégia otimizada para a fazenda.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Consultar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveOptimizationAccessCard extends StatelessWidget {
  const ExecutiveOptimizationAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF283593).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: Color(0xFF283593),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Optimization Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Escolha um objetivo, defina limites e receba a estratégia com melhor combinação de retorno, risco e equilíbrio.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Otimizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveScenarioSimulatorAccessCard extends StatelessWidget {
  const ExecutiveScenarioSimulatorAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF6A1B9A),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Scenario Simulator',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Crie hipóteses, projete resultados, compare scores, calcule ROI e identifique riscos antes de executar uma decisão real.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Simular'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveDigitalTwinAccessCard extends StatelessWidget {
  const ExecutiveDigitalTwinAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Color(0xFF00695C),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Digital Twin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Acompanhe o índice geral, scores por área, riscos consolidados, tendências e a timeline inteligente da fazenda.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir gêmeo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveEventCenterAccessCard extends StatelessWidget {
  const ExecutiveEventCenterAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_note_outlined,
                  color: Color(0xFF1565C0),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atlas Event Center',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Consulte pesagens, sanidade, reprodução, finanças, estoque, workflows, decisões e erros do sistema.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir eventos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveBrainAccessCard extends StatelessWidget {
  const ExecutiveBrainAccessCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasExecutiveBrainData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final decision = data.officialDecision;
    final color = switch (data.status) {
      AtlasExecutiveBrainStatus.excellent => const Color(0xFF80CBC4),
      AtlasExecutiveBrainStatus.adequate => const Color(0xFFA5D6A7),
      AtlasExecutiveBrainStatus.attention => const Color(0xFFFFCC80),
      AtlasExecutiveBrainStatus.critical => const Color(0xFFEF9A9A),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF02040A), Color(0xFF0E1B2B), Color(0xFF1A3B52)],
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
                      Icon(Icons.hub_outlined, color: color, size: 32),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Text(
                          'Atlas Executive Brain',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  if (decision != null) ...[
                    const SizedBox(height: 13),
                    Text(
                      'Decisão oficial: ${decision.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveBrainChip(
                        label: 'Hoje',
                        value: data.dailyPlan.length,
                      ),
                      _ExecutiveBrainChip(
                        label: 'Semana',
                        value: data.weeklyPlan.length,
                      ),
                      _ExecutiveBrainChip(
                        label: 'Conflitos',
                        value: data.conflicts.length,
                      ),
                    ],
                  ),
                ],
              );

              final side = Container(
                width: 230,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.brainScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      atlasExecutiveBrainStatusLabel(data.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data.confidencePercent.toStringAsFixed(0)}% de confiança',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB3E5FC),
                        foregroundColor: const Color(0xFF02040A),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir cérebro',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveBrainChip extends StatelessWidget {
  const _ExecutiveBrainChip({required this.label, required this.value});

  final String label;
  final int value;

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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExecutiveAtlasOsAccessCard extends StatelessWidget {
  const ExecutiveAtlasOsAccessCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasOsData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = switch (data.status) {
      AtlasOsStatus.stable => const Color(0xFF80CBC4),
      AtlasOsStatus.attention => const Color(0xFFFFCC80),
      AtlasOsStatus.highRisk => const Color(0xFFEF9A9A),
      AtlasOsStatus.critical => const Color(0xFFFF8A80),
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.memory_outlined, color: color),
        ),
        title: const Text(
          'Sistema Operacional Atlas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${data.modules.length} módulos · '
          '${data.commands.length} comandos · '
          '${data.criticalItems.length} itens críticos\n'
          '${data.summary}',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Text(
          data.healthScore.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onOpen,
      ),
    );
  }
}

class ExecutiveMissionControlCard extends StatelessWidget {
  const ExecutiveMissionControlCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasMissionControlData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = switch (data.status) {
      AtlasMissionControlStatus.stable => const Color(0xFF80CBC4),
      AtlasMissionControlStatus.attention => const Color(0xFFFFCC80),
      AtlasMissionControlStatus.highRisk => const Color(0xFFEF9A9A),
      AtlasMissionControlStatus.critical => const Color(0xFFFF8A80),
    };

    final priority = data.topPriority;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(23),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF07111F), Color(0xFF132A3A), Color(0xFF254B62)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;

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
                          Icons.radar_outlined,
                          color: color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Atlas Mission Control',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.greeting,
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
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.47),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveMissionChip(
                        label: 'Prioridades',
                        value: data.priorities.length,
                        color: const Color(0xFFFFCC80),
                      ),
                      _ExecutiveMissionChip(
                        label: 'Alertas',
                        value: data.alerts.length,
                        color: const Color(0xFFEF9A9A),
                      ),
                      _ExecutiveMissionChip(
                        label: 'Plano de hoje',
                        value: data.dailyPlan.length,
                        color: const Color(0xFF90CAF9),
                      ),
                      _ExecutiveMissionChip(
                        label: 'Workflows',
                        value: data.workflows.length,
                        color: const Color(0xFFA5D6A7),
                      ),
                    ],
                  ),
                  if (priority != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Prioridade nº 1: ${priority.title} · ${priority.farmName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 235,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.globalScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      atlasMissionControlStatusLabel(data.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'Execução: '
                      '${data.executionProbabilityPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Metas: '
                      '${data.goalProbabilityPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'R\$ ${data.estimatedMonthlyImpact.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFA5D6A7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Impacto mensal estimado',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB3E5FC),
                        foregroundColor: const Color(0xFF07111F),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir controle',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveMissionChip extends StatelessWidget {
  const _ExecutiveMissionChip({
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExecutiveWelcomeHeader extends StatelessWidget {
  const ExecutiveWelcomeHeader({
    required this.totalCount,
    required this.completionRate,
    required this.overdueCount,
    required this.isExportingExcel,
    required this.onExportExcel,
    super.key,
  });

  final int totalCount;
  final double completionRate;
  final int overdueCount;
  final bool isExportingExcel;
  final VoidCallback onExportExcel;

  @override
  Widget build(BuildContext context) {
    final percentage = completionRate * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163F1A), Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visão executiva da operação',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Acompanhamento consolidado das ações gerenciais e do ritmo de execução.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ExecutiveHeaderChip(
                    icon: Icons.assignment_outlined,
                    text: '$totalCount ações cadastradas',
                  ),
                  ExecutiveHeaderChip(
                    icon: Icons.check_circle_outline,
                    text:
                        '${percentage.toStringAsFixed(1).replaceAll('.', ',')}% concluído',
                  ),
                  ExecutiveHeaderChip(
                    icon: Icons.event_busy_outlined,
                    text: '$overdueCount atrasadas',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: isExportingExcel ? null : onExportExcel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
                ),
                icon: isExportingExcel
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.table_view_outlined),
                label: Text(
                  isExportingExcel
                      ? 'Gerando Excel...'
                      : 'Exportar Dashboard em Excel',
                ),
              ),
            ],
          );

          final gauge = ExecutiveCompletionGauge(
            completionRate: completionRate,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 22), gauge],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              const SizedBox(width: 30),
              gauge,
            ],
          );
        },
      ),
    );
  }
}

class ExecutiveCompletionGauge extends StatelessWidget {
  const ExecutiveCompletionGauge({required this.completionRate, super.key});

  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final value = completionRate.clamp(0.0, 1.0);

    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Conclusão geral',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 16,
              value: value,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC8A951),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExecutiveHeaderChip extends StatelessWidget {
  const ExecutiveHeaderChip({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 17),
          const SizedBox(width: 7),
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

class ExecutiveKpiGrid extends StatelessWidget {
  const ExecutiveKpiGrid({
    required this.totalCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.overdueCount,
    required this.urgentCount,
    required this.completionRate,
    required this.overdueRate,
    super.key,
  });

  final int totalCount;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final int overdueCount;
  final int urgentCount;
  final double completionRate;
  final double overdueRate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1050
            ? (constraints.maxWidth - 48) / 4
            : constraints.maxWidth >= 620
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ExecutiveKpiCard(
              width: width,
              title: 'Total de ações',
              value: totalCount.toString(),
              subtitle: 'Ações cadastradas',
              icon: Icons.assignment_outlined,
              color: const Color(0xFF1565C0),
            ),
            ExecutiveKpiCard(
              width: width,
              title: 'Em execução',
              value: inProgressCount.toString(),
              subtitle: '$pendingCount pendentes',
              icon: Icons.play_circle_outline,
              color: const Color(0xFFEF6C00),
            ),
            ExecutiveKpiCard(
              width: width,
              title: 'Concluídas',
              value: completedCount.toString(),
              subtitle:
                  '${(completionRate * 100).toStringAsFixed(1).replaceAll('.', ',')}% do plano',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF1B5E20),
            ),
            ExecutiveKpiCard(
              width: width,
              title: 'Atrasadas',
              value: overdueCount.toString(),
              subtitle:
                  '${(overdueRate * 100).toStringAsFixed(1).replaceAll('.', ',')}% de atraso',
              icon: Icons.event_busy_outlined,
              color: overdueCount > 0
                  ? const Color(0xFFC62828)
                  : const Color(0xFF1B5E20),
            ),
            ExecutiveKpiCard(
              width: width,
              title: 'Urgentes',
              value: urgentCount.toString(),
              subtitle: 'Prioridade imediata',
              icon: Icons.priority_high,
              color: urgentCount > 0
                  ? const Color(0xFFC62828)
                  : const Color(0xFF1B5E20),
            ),
          ],
        );
      },
    );
  }
}

class ExecutiveKpiCard extends StatelessWidget {
  const ExecutiveKpiCard({
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
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
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
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
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

class ExecutiveSectionTitle extends StatelessWidget {
  const ExecutiveSectionTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

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
            color: Color(0xFF263238),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class ExecutiveAtlasBiForecastCard extends StatelessWidget {
  const ExecutiveAtlasBiForecastCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasBiForecastDashboardData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final priority = data.priorityForecast;

    final color = data.highRiskCount > 0
        ? const Color(0xFFEF9A9A)
        : data.negativeCount > 0
        ? const Color(0xFFFFCC80)
        : const Color(0xFF80CBC4);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF161A30), Color(0xFF31304D), Color(0xFF54507A)],
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
                          Icons.auto_graph_outlined,
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
                              'Forecast Atlas BI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Projeção consolidada para 90 dias',
                              style: TextStyle(
                                color: Colors.white70,
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
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.47),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveForecastChip(
                        label: 'Positivos',
                        value: data.positiveCount,
                        color: const Color(0xFFA5D6A7),
                      ),
                      _ExecutiveForecastChip(
                        label: 'Estáveis',
                        value: data.stableCount,
                        color: const Color(0xFF90CAF9),
                      ),
                      _ExecutiveForecastChip(
                        label: 'Negativos',
                        value: data.negativeCount,
                        color: const Color(0xFFFFCC80),
                      ),
                      _ExecutiveForecastChip(
                        label: 'Alto risco',
                        value: data.highRiskCount,
                        color: const Color(0xFFEF9A9A),
                      ),
                    ],
                  ),
                  if (priority != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Prioridade preditiva: '
                        '${priority.title} · '
                        '${priority.farmName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 230,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priority == null
                          ? '—'
                          : '${priority.targetProbabilityPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Chance da meta prioritária',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    if (priority != null) ...[
                      const SizedBox(height: 11),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: priority.targetProbabilityPercent / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Risco: '
                        '${atlasBiForecastRiskLabel(priority.risk)} · '
                        'Confiança: '
                        '${priority.confidencePercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB2EBF2),
                        foregroundColor: const Color(0xFF161A30),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir previsões',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveForecastChip extends StatelessWidget {
  const _ExecutiveForecastChip({
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExecutiveAtlasBiCard extends StatelessWidget {
  const ExecutiveAtlasBiCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasBiData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = switch (data.status) {
      AtlasBiStatus.excellent => const Color(0xFF80CBC4),
      AtlasBiStatus.adequate => const Color(0xFFA5D6A7),
      AtlasBiStatus.attention => const Color(0xFFFFCC80),
      AtlasBiStatus.critical => const Color(0xFFEF9A9A),
    };

    final leader = data.leadingFarm;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1F33), Color(0xFF123A5A), Color(0xFF1E5F8A)],
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
                        Icons.analytics_outlined,
                        color: Color(0xFF80DEEA),
                        size: 31,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Atlas BI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveBiChip(
                        label: 'Indicadores',
                        value: data.indicators.length,
                      ),
                      _ExecutiveBiChip(
                        label: 'Fazendas',
                        value: data.rankings.length,
                      ),
                      _ExecutiveBiChip(
                        label: 'Críticos',
                        value: data.criticalIndicators.length,
                      ),
                      _ExecutiveBiChip(
                        label: 'Insights',
                        value: data.insights.length,
                      ),
                    ],
                  ),
                  if (leader != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Líder do ranking: '
                        '${leader.farmName} · '
                        '${leader.score.toStringAsFixed(0)}/100',
                        style: const TextStyle(
                          color: Color(0xFF80DEEA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 220,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.score.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      atlasBiStatusLabel(data.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 9,
                        value: data.score / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF80DEEA),
                        foregroundColor: const Color(0xFF0B1F33),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir BI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveBiChip extends StatelessWidget {
  const _ExecutiveBiChip({required this.label, required this.value});

  final String label;
  final int value;

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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExecutiveStrategyCard extends StatelessWidget {
  const ExecutiveStrategyCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasStrategyData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = switch (data.status) {
      AtlasStrategyStatus.excellent => const Color(0xFF81C784),
      AtlasStrategyStatus.adequate => const Color(0xFFA5D6A7),
      AtlasStrategyStatus.attention => const Color(0xFFFFCC80),
      AtlasStrategyStatus.critical => const Color(0xFFEF9A9A),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF102A43), Color(0xFF1E4976), Color(0xFF2F6F9F)],
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
                        Icons.account_tree_outlined,
                        color: Color(0xFFFFD180),
                        size: 31,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Strategy Center',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.mission,
                    style: const TextStyle(
                      color: Color(0xFFFFD180),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveStrategyChip(
                        label: 'Objetivos',
                        value: data.objectives.length,
                      ),
                      _ExecutiveStrategyChip(
                        label: 'Prioridades',
                        value: data.priorities.length,
                      ),
                      _ExecutiveStrategyChip(
                        label: 'Iniciativas',
                        value: data.initiatives.length,
                      ),
                      _ExecutiveStrategyChip(
                        label: 'Riscos',
                        value: data.risks.length,
                      ),
                      _ExecutiveStrategyChip(
                        label: 'Oportunidades',
                        value: data.opportunities.length,
                      ),
                    ],
                  ),
                ],
              );

              final side = Container(
                width: 220,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.score.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      atlasStrategyStatusLabel(data.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 9,
                        value: data.score / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD180),
                        foregroundColor: const Color(0xFF102A43),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir estratégia',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveStrategyChip extends StatelessWidget {
  const _ExecutiveStrategyChip({required this.label, required this.value});

  final String label;
  final int value;

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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExecutiveGoalStrategyCard extends StatelessWidget {
  const ExecutiveGoalStrategyCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasExecutiveGoalHistorySummary data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final priority = data.series.isEmpty ? null : data.series.first;

    final color = data.highRisk > 0
        ? const Color(0xFFEF9A9A)
        : data.atRisk > 0
        ? const Color(0xFFFFCC80)
        : const Color(0xFFA5D6A7);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A1B3D), Color(0xFF4A2C6D), Color(0xFF68428C)],
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
                          Icons.timeline_outlined,
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
                              'Painel Estratégico',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Evolução e risco das metas',
                              style: TextStyle(
                                color: Colors.white70,
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
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.47),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveGoalStrategyChip(
                        label: 'No ritmo',
                        value: data.onTrack,
                        color: const Color(0xFFA5D6A7),
                      ),
                      _ExecutiveGoalStrategyChip(
                        label: 'Atenção',
                        value: data.atRisk,
                        color: const Color(0xFFFFCC80),
                      ),
                      _ExecutiveGoalStrategyChip(
                        label: 'Alto risco',
                        value: data.highRisk,
                        color: const Color(0xFFEF9A9A),
                      ),
                      _ExecutiveGoalStrategyChip(
                        label: 'Concluídas',
                        value: data.completed,
                        color: const Color(0xFF90CAF9),
                      ),
                    ],
                  ),
                  if (priority != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Prioridade estratégica: '
                        '${priority.kpiTitle} · '
                        '${priority.farmName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE1BEE7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 230,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priority == null
                          ? '—'
                          : '${priority.currentProgressPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Progresso da prioridade',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    if (priority != null) ...[
                      const SizedBox(height: 11),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: priority.currentProgressPercent / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        priority.projectedCompletionDate == null
                            ? 'Sem previsão confiável de conclusão.'
                            : 'Previsão: '
                                  '${_executiveGoalDate(priority.projectedCompletionDate!)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE1BEE7),
                        foregroundColor: const Color(0xFF2A1B3D),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir evolução',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveGoalStrategyChip extends StatelessWidget {
  const _ExecutiveGoalStrategyChip({
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _executiveGoalDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

class ExecutiveGoalsCard extends StatelessWidget {
  const ExecutiveGoalsCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasExecutiveGoalDashboardData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = data.progress;

    final color = progress.overdue > 0
        ? const Color(0xFFEF9A9A)
        : progress.atRisk > 0
        ? const Color(0xFFFFCC80)
        : const Color(0xFFA5D6A7);

    final priority = data.priorityGoals.isEmpty
        ? null
        : data.priorityGoals.first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3D2A00), Color(0xFF6D4C00), Color(0xFF8D6E00)],
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
                          Icons.flag_outlined,
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
                              'Central de Metas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Objetivos e progresso da operação',
                              style: TextStyle(
                                color: Colors.white70,
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
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.47),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveGoalChip(
                        label: 'Total',
                        value: progress.total,
                        color: Colors.white70,
                      ),
                      _ExecutiveGoalChip(
                        label: 'No prazo',
                        value: progress.active,
                        color: const Color(0xFFA5D6A7),
                      ),
                      _ExecutiveGoalChip(
                        label: 'Em risco',
                        value: progress.atRisk,
                        color: const Color(0xFFFFCC80),
                      ),
                      _ExecutiveGoalChip(
                        label: 'Atrasadas',
                        value: progress.overdue,
                        color: const Color(0xFFEF9A9A),
                      ),
                      _ExecutiveGoalChip(
                        label: 'Concluídas',
                        value: progress.completed,
                        color: const Color(0xFF90CAF9),
                      ),
                    ],
                  ),
                  if (priority != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Prioridade: ${priority.kpiTitle} · ${priority.farmName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 215,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progress.averageProgressPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Progresso médio',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 9,
                        value: progress.averageProgressPercent / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE082),
                        foregroundColor: const Color(0xFF3D2A00),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir metas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveGoalChip extends StatelessWidget {
  const _ExecutiveGoalChip({
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExecutiveKpisCard extends StatelessWidget {
  const ExecutiveKpisCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasExecutiveKpiDashboardData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _executiveKpiStatusColor(data.operationStatus);

    final leadingFarm = data.leadingFarm;

    final critical = data.criticalKpis.isEmpty ? null : data.criticalKpis.first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F3D2E), Color(0xFF165C45), Color(0xFF1D7356)],
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
                          Icons.monitor_heart_outlined,
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
                              'Central de KPIs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Metas e desempenho da operação',
                              style: TextStyle(
                                color: Colors.white70,
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
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.47),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveKpiChip(
                        label: 'Fazendas',
                        value: data.farms.length,
                        color: Colors.white70,
                      ),
                      _ExecutiveKpiChip(
                        label: 'Indicadores',
                        value: data.kpis.length,
                        color: const Color(0xFF64B5F6),
                      ),
                      _ExecutiveKpiChip(
                        label: 'Críticos',
                        value: data.criticalKpis.length,
                        color: const Color(0xFFEF5350),
                      ),
                      _ExecutiveKpiChip(
                        label: 'Metas superadas',
                        value: data.positiveHighlights.length,
                        color: const Color(0xFF81C784),
                      ),
                    ],
                  ),
                  if (leadingFarm != null || critical != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        '${leadingFarm == null ? '' : 'Melhor desempenho: ${leadingFarm.farmName}'}'
                        '${leadingFarm != null && critical != null ? ' · ' : ''}'
                        '${critical == null ? '' : 'Prioridade: ${critical.title}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE4C86A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 215,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.operationScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      atlasExecutiveKpiStatusLabel(data.operationStatus),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 9,
                        value: data.operationScore / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE4C86A),
                        foregroundColor: const Color(0xFF0F3D2E),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir indicadores',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveKpiChip extends StatelessWidget {
  const _ExecutiveKpiChip({
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _executiveKpiStatusColor(AtlasExecutiveKpiStatus status) {
  switch (status) {
    case AtlasExecutiveKpiStatus.excellent:
      return const Color(0xFF81C784);

    case AtlasExecutiveKpiStatus.adequate:
      return const Color(0xFFA5D6A7);

    case AtlasExecutiveKpiStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasExecutiveKpiStatus.critical:
      return const Color(0xFFEF9A9A);
  }
}

class ExecutiveAlertsCard extends StatelessWidget {
  const ExecutiveAlertsCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasExecutiveAlertSummary data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final mainAlert = data.mainAlert;

    final criticalFarm = data.mostCriticalFarm;

    final color = data.critical > 0
        ? const Color(0xFFEF5350)
        : data.high > 0
        ? const Color(0xFFFF8A65)
        : const Color(0xFFFFCC80);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3E0A0A), Color(0xFF6A1515), Color(0xFF8E2424)],
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
                          Icons.notification_important_outlined,
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
                              'Central de Alertas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Riscos e urgências da operação',
                              style: TextStyle(
                                color: Colors.white70,
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
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.47),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveAlertChip(
                        label: 'Total',
                        value: data.total,
                        color: Colors.white70,
                      ),
                      _ExecutiveAlertChip(
                        label: 'Críticos',
                        value: data.critical,
                        color: const Color(0xFFEF5350),
                      ),
                      _ExecutiveAlertChip(
                        label: 'Altos',
                        value: data.high,
                        color: const Color(0xFFFF8A65),
                      ),
                      _ExecutiveAlertChip(
                        label: 'Atenção',
                        value: data.attention,
                        color: const Color(0xFFFFCC80),
                      ),
                    ],
                  ),
                  if (criticalFarm != null || mainAlert != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        '${criticalFarm == null ? '' : 'Maior atenção: ${criticalFarm.farmName}'}'
                        '${criticalFarm != null && mainAlert != null ? ' · ' : ''}'
                        '${mainAlert == null ? '' : 'Prioridade: ${mainAlert.title}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFCC80),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 215,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.critical}',
                      style: TextStyle(
                        color: color,
                        fontSize: 39,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Alertas críticos',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    if (mainAlert != null)
                      Text(
                        'Responder em até '
                        '${mainAlert.responseDeadlineDays} '
                        '${mainAlert.responseDeadlineDays == 1 ? 'dia' : 'dias'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC80),
                        foregroundColor: const Color(0xFF3E0A0A),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir alertas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveAlertChip extends StatelessWidget {
  const _ExecutiveAlertChip({
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExecutiveOperationActionsCard extends StatelessWidget {
  const ExecutiveOperationActionsCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasAiOperationActions data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = data.progress;

    final criticalFarm = data.mostCriticalFarm;

    final priority = data.priorityActions.isEmpty
        ? null
        : data.priorityActions.first;

    final color = progress.overdue > 0
        ? const Color(0xFFEF5350)
        : progress.completionPercent >= 80
        ? const Color(0xFF81C784)
        : const Color(0xFF64B5F6);

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
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.assignment_turned_in_outlined,
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
                              'Central de Ações',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Execução consolidada da consultoria',
                              style: TextStyle(
                                color: Colors.white70,
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
                    data.summary,
                    maxLines: compact ? 8 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.47),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExecutiveOperationActionChip(
                        label: 'Total',
                        value: progress.total,
                        color: Colors.white70,
                      ),
                      _ExecutiveOperationActionChip(
                        label: 'Pendentes',
                        value: progress.pending,
                        color: const Color(0xFFFFB74D),
                      ),
                      _ExecutiveOperationActionChip(
                        label: 'Em andamento',
                        value: progress.inProgress,
                        color: const Color(0xFF64B5F6),
                      ),
                      _ExecutiveOperationActionChip(
                        label: 'Concluídas',
                        value: progress.completed,
                        color: const Color(0xFF81C784),
                      ),
                      _ExecutiveOperationActionChip(
                        label: 'Atrasadas',
                        value: progress.overdue,
                        color: const Color(0xFFEF5350),
                      ),
                    ],
                  ),
                  if (criticalFarm != null || priority != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        '${criticalFarm == null ? '' : 'Maior atenção: ${criticalFarm.farmName}'}'
                        '${criticalFarm != null && priority != null ? ' · ' : ''}'
                        '${priority == null ? '' : 'Próxima ação: ${priority.action.title}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC8A951),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              final side = Container(
                width: 215,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progress.completionPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Progresso geral',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 9,
                        value: progress.completionPercent / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC8A951),
                        foregroundColor: const Color(0xFF263238),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Abrir central',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [information, const SizedBox(height: 18), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class _ExecutiveOperationActionChip extends StatelessWidget {
  const _ExecutiveOperationActionChip({
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExecutiveComparativeDiagnosticCard extends StatelessWidget {
  const ExecutiveComparativeDiagnosticCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final AtlasComparativeDiagnosticData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final best = data.bestFarm;
    final critical = data.mostCriticalFarm;

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
                        Icons.compare_arrows_outlined,
                        color: Color(0xFFC8A951),
                        size: 31,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Comparar Fazendas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.summary,
                    maxLines: compact ? 7 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      _ExecutiveComparisonChip(
                        label: 'Fazendas',
                        value: data.farmCount.toString(),
                      ),
                      _ExecutiveComparisonChip(
                        label: 'Média',
                        value: data.operationAverageScore.toStringAsFixed(0),
                      ),
                      _ExecutiveComparisonChip(
                        label: 'Prioridades',
                        value: data.priorities.length.toString(),
                      ),
                    ],
                  ),
                  if (best != null || critical != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        '${best == null ? '' : 'Líder: ${best.farmName} (${best.score.toStringAsFixed(0)})'}'
                        '${best != null && critical != null ? ' · ' : ''}'
                        '${critical == null ? '' : 'Maior atenção: ${critical.farmName} (${critical.score.toStringAsFixed(0)})'}',
                        style: const TextStyle(
                          color: Color(0xFFC8A951),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
                icon: const Icon(Icons.leaderboard_outlined),
                label: const Text(
                  'Abrir comparação',
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

class _ExecutiveComparisonChip extends StatelessWidget {
  const _ExecutiveComparisonChip({required this.label, required this.value});

  final String label;
  final String value;

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

class ExecutiveCopilotAccessCard extends StatelessWidget {
  const ExecutiveCopilotAccessCard({
    required this.brief,
    required this.onOpen,
    super.key,
  });

  final dashboard_intelligence.AtlasIntelligenceBrief brief;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final priority = brief.mainPriority;

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
                  const Row(
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        color: Color(0xFFC8A951),
                        size: 31,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Converse com a operação',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pergunte ao Copiloto sobre prioridades, riscos, fazendas, responsáveis, categorias e oportunidades.',
                    style: TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  if (priority != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Experimente perguntar: “Por que ${priority.title} é a prioridade número 1?”',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC8A951),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ExecutiveCopilotQuestionChip(
                        text: 'Qual é o maior risco?',
                      ),
                      ExecutiveCopilotQuestionChip(
                        text: 'O que fazer primeiro?',
                      ),
                      ExecutiveCopilotQuestionChip(
                        text: 'Qual fazenda exige atenção?',
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
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.chat_outlined),
                label: const Text(
                  'Abrir Copiloto',
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

class ExecutiveCopilotQuestionChip extends StatelessWidget {
  const ExecutiveCopilotQuestionChip({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ExecutiveAtlasIntelligenceAccessCard extends StatelessWidget {
  const ExecutiveAtlasIntelligenceAccessCard({
    required this.brief,
    required this.onOpen,
    super.key,
  });

  final dashboard_intelligence.AtlasIntelligenceBrief brief;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = executiveAtlasIntelligenceColor(brief.operationLevel);

    final mainPriority = brief.mainPriority;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(23),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0E2F24), Color(0xFF174B37), Color(0xFF1B5E20)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;

              final information = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.auto_awesome_outlined,
                          color: color,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Central de Inteligência Atlas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              brief.situationTitle,
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
                    brief.executiveSummary,
                    maxLines: compact ? 7 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  if (mainPriority != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Prioridade nº 1: ${mainPriority.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC8A951),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      ExecutiveAtlasIntelligenceChip(
                        label: 'Prioridades',
                        value: brief.topPriorities.length.toString(),
                        color: const Color(0xFF64B5F6),
                      ),
                      ExecutiveAtlasIntelligenceChip(
                        label: 'Riscos',
                        value: brief.risks.length.toString(),
                        color: const Color(0xFFEF5350),
                      ),
                      ExecutiveAtlasIntelligenceChip(
                        label: 'Oportunidades',
                        value: brief.opportunities.length.toString(),
                        color: const Color(0xFF81C784),
                      ),
                    ],
                  ),
                ],
              );

              final side = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    brief.operationScore.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Score geral',
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
                      'Abrir Inteligência',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    information,
                    const SizedBox(height: 20),
                    Align(alignment: Alignment.centerLeft, child: side),
                  ],
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

class ExecutiveAtlasIntelligenceChip extends StatelessWidget {
  const ExecutiveAtlasIntelligenceChip({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
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

Color executiveAtlasIntelligenceColor(
  dashboard_intelligence.AtlasIntelligenceLevel level,
) {
  switch (level) {
    case dashboard_intelligence.AtlasIntelligenceLevel.excellent:
      return const Color(0xFF66BB6A);

    case dashboard_intelligence.AtlasIntelligenceLevel.stable:
      return const Color(0xFF81C784);

    case dashboard_intelligence.AtlasIntelligenceLevel.attention:
      return const Color(0xFFFFB74D);

    case dashboard_intelligence.AtlasIntelligenceLevel.critical:
      return const Color(0xFFEF5350);
  }
}

class ExecutiveDecisionAccessCard extends StatelessWidget {
  const ExecutiveDecisionAccessCard({
    required this.data,
    required this.onOpen,
    super.key,
  });

  final ExecutiveDecisionData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final assistant = data.executiveAssistant;

    final score = data.consultantScore;

    final color = executiveDecisionLevelColor(score.level);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(23),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF263238), Color(0xFF37474F)],
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
                        width: 49,
                        height: 49,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Central de Decisão Inteligente',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              assistant.headline,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    assistant.message,
                    maxLines: compact ? 6 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      ExecutiveDecisionAccessChip(
                        label: 'Críticas',
                        value: data.summary.criticalActionCount.toString(),
                        color: const Color(0xFFC62828),
                      ),
                      ExecutiveDecisionAccessChip(
                        label: 'Atrasos previstos',
                        value: data.summary.predictedDelayCount.toString(),
                        color: const Color(0xFFEF6C00),
                      ),
                      ExecutiveDecisionAccessChip(
                        label: 'Fazendas em risco',
                        value: data.summary.highRiskFarmCount.toString(),
                        color: const Color(0xFF1565C0),
                      ),
                    ],
                  ),
                ],
              );

              final side = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.value.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Score do consultor',
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
                      'Abrir Central',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    information,
                    const SizedBox(height: 20),
                    Align(alignment: Alignment.centerLeft, child: side),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: information),
                  const SizedBox(width: 24),
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

class ExecutiveDecisionAccessChip extends StatelessWidget {
  const ExecutiveDecisionAccessChip({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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

Color executiveDecisionLevelColor(ExecutiveDecisionLevel level) {
  switch (level) {
    case ExecutiveDecisionLevel.excellent:
      return const Color(0xFF66BB6A);

    case ExecutiveDecisionLevel.good:
      return const Color(0xFF81C784);

    case ExecutiveDecisionLevel.normal:
      return const Color(0xFF64B5F6);

    case ExecutiveDecisionLevel.attention:
      return const Color(0xFFFFB74D);

    case ExecutiveDecisionLevel.critical:
      return const Color(0xFFEF5350);
  }
}

class ExecutiveIntelligenceAlertsPanel extends StatelessWidget {
  const ExecutiveIntelligenceAlertsPanel({
    required this.alerts,
    required this.onOpenActions,
    super.key,
  });

  final List<intelligence.ExecutiveAlertData> alerts;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...List.generate(alerts.length, (index) {
              final alert = alerts[index];
              final color = intelligenceAlertColor(alert.severity);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == alerts.length - 1 ? 0 : 12,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(intelligenceAlertIcon(alert), color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              alert.message,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      if (alert.count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            alert.count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenActions,
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('Abrir ações gerenciais'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExecutiveIntelligenceDistributionGrid extends StatelessWidget {
  const ExecutiveIntelligenceDistributionGrid({required this.data, super.key});

  final intelligence.ExecutiveDashboardData data;

  @override
  Widget build(BuildContext context) {
    final statusItems = data.statusDistribution.map((item) {
      return ExecutiveDistributionItem(
        label: item.label,
        value: item.value.round(),
        color: intelligenceStatusColor(item.status),
      );
    }).toList();

    final priorityItems = data.priorityRanking.map((item) {
      return ExecutiveDistributionItem(
        label: item.label,
        value: item.value.round(),
        color: intelligenceStatusColor(item.status),
      );
    }).toList();

    final responsibleItems = data.responsibleRanking.map((item) {
      return ExecutiveDistributionItem(
        label: item.label,
        value: item.value.round(),
        color: intelligenceStatusColor(item.status),
      );
    }).toList();

    final farmItems = data.farmRanking.map((item) {
      return ExecutiveDistributionItem(
        label: item.label,
        value: item.value.round(),
        color: intelligenceStatusColor(item.status),
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 920;

        final cards = [
          ExecutiveDistributionCard(
            title: 'Por status',
            icon: Icons.donut_large_outlined,
            items: statusItems,
          ),
          ExecutiveDistributionCard(
            title: 'Por prioridade',
            icon: Icons.flag_outlined,
            items: priorityItems,
          ),
          ExecutiveDistributionCard(
            title: 'Ranking por responsável',
            icon: Icons.groups_outlined,
            items: responsibleItems,
          ),
          ExecutiveDistributionCard(
            title: 'Ranking por fazenda',
            icon: Icons.home_work_outlined,
            items: farmItems,
          ),
        ];

        if (!useRow) {
          return Column(
            children: List.generate(cards.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == cards.length - 1 ? 0 : 14,
                ),
                child: cards[index],
              );
            }),
          );
        }

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards.map((card) {
            return SizedBox(
              width: (constraints.maxWidth - 14) / 2,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }
}

class ExecutiveIntelligenceRecommendationCard extends StatelessWidget {
  const ExecutiveIntelligenceRecommendationCard({
    required this.data,
    required this.onOpenActions,
    super.key,
  });

  final intelligence.ExecutiveDashboardData data;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final recommendation = data.recommendations.isEmpty
        ? null
        : data.recommendations.first;

    if (recommendation == null) {
      return const SizedBox.shrink();
    }

    final color = intelligenceRecommendationColor(recommendation.priority);

    return Card(
      color: const Color(0xFF263238),
      child: Padding(
        padding: const EdgeInsets.all(23),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.auto_awesome_outlined, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recomendação executiva',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    recommendation.title,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    recommendation.message,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recommendation.recommendedAction,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onOpenActions,
                    style: TextButton.styleFrom(foregroundColor: color),
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Abrir plano de ação'),
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

Color intelligenceAlertColor(intelligence.ExecutiveAlertSeverity severity) {
  switch (severity) {
    case intelligence.ExecutiveAlertSeverity.critical:
      return const Color(0xFFC62828);
    case intelligence.ExecutiveAlertSeverity.warning:
      return const Color(0xFFEF6C00);
    case intelligence.ExecutiveAlertSeverity.information:
      return const Color(0xFF1B5E20);
  }
}

IconData intelligenceAlertIcon(intelligence.ExecutiveAlertData alert) {
  switch (alert.category) {
    case 'Prazo':
      return Icons.event_busy_outlined;
    case 'Prioridade':
      return Icons.priority_high;
    case 'Responsabilidade':
      return Icons.person_off_outlined;
    case 'Equipe':
      return Icons.groups_outlined;
    default:
      return Icons.info_outline;
  }
}

Color intelligenceStatusColor(intelligence.ExecutiveIndicatorStatus status) {
  switch (status) {
    case intelligence.ExecutiveIndicatorStatus.positive:
      return const Color(0xFF1B5E20);
    case intelligence.ExecutiveIndicatorStatus.normal:
      return const Color(0xFF1565C0);
    case intelligence.ExecutiveIndicatorStatus.attention:
      return const Color(0xFFEF6C00);
    case intelligence.ExecutiveIndicatorStatus.critical:
      return const Color(0xFFC62828);
  }
}

Color intelligenceRecommendationColor(
  intelligence.ExecutiveRecommendationPriority priority,
) {
  switch (priority) {
    case intelligence.ExecutiveRecommendationPriority.low:
      return const Color(0xFF1B5E20);
    case intelligence.ExecutiveRecommendationPriority.medium:
      return const Color(0xFF1565C0);
    case intelligence.ExecutiveRecommendationPriority.high:
      return const Color(0xFFEF6C00);
    case intelligence.ExecutiveRecommendationPriority.critical:
      return const Color(0xFFC62828);
  }
}

class ExecutiveAlertsPanel extends StatelessWidget {
  const ExecutiveAlertsPanel({
    required this.overdueCount,
    required this.urgentCount,
    required this.withoutResponsibleCount,
    required this.openCount,
    required this.onOpenActions,
    super.key,
  });

  final int overdueCount;
  final int urgentCount;
  final int withoutResponsibleCount;
  final int openCount;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final alerts = <ExecutiveAlertData>[
      if (overdueCount > 0)
        ExecutiveAlertData(
          title: 'Ações atrasadas',
          message:
              '$overdueCount ${overdueCount == 1 ? 'ação está' : 'ações estão'} fora do prazo.',
          icon: Icons.event_busy_outlined,
          color: const Color(0xFFC62828),
        ),
      if (urgentCount > 0)
        ExecutiveAlertData(
          title: 'Prioridades urgentes',
          message:
              '$urgentCount ${urgentCount == 1 ? 'ação urgente permanece aberta' : 'ações urgentes permanecem abertas'}.',
          icon: Icons.priority_high,
          color: const Color(0xFFEF6C00),
        ),
      if (withoutResponsibleCount > 0)
        ExecutiveAlertData(
          title: 'Responsáveis não definidos',
          message:
              '$withoutResponsibleCount ${withoutResponsibleCount == 1 ? 'ação aberta está' : 'ações abertas estão'} sem responsável.',
          icon: Icons.person_off_outlined,
          color: const Color(0xFF6A1B9A),
        ),
      if (openCount == 0)
        const ExecutiveAlertData(
          title: 'Nenhuma pendência aberta',
          message: 'O plano de ação não possui pendências em aberto.',
          icon: Icons.check_circle_outline,
          color: Color(0xFF1B5E20),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...List.generate(alerts.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == alerts.length - 1 ? 0 : 12,
                ),
                child: ExecutiveAlertTile(data: alerts[index]),
              );
            }),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenActions,
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('Abrir ações gerenciais'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExecutiveAlertTile extends StatelessWidget {
  const ExecutiveAlertTile({required this.data, super.key});

  final ExecutiveAlertData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: data.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: data.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: data.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.message,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExecutiveAlertData {
  const ExecutiveAlertData({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}

class ExecutiveUpcomingActionsCard extends StatelessWidget {
  const ExecutiveUpcomingActionsCard({
    required this.actions,
    required this.onOpenActions,
    super.key,
  });

  final List<ReportActionItemData> actions;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: Color(0xFF1B5E20),
                size: 34,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Nenhuma ação aberta com prazo definido.',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ...List.generate(actions.length, (index) {
            final action = actions[index];

            return Column(
              children: [
                if (index > 0) const Divider(height: 1),
                ExecutiveUpcomingActionTile(
                  action: action,
                  onTap: onOpenActions,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class ExecutiveUpcomingActionTile extends StatelessWidget {
  const ExecutiveUpcomingActionTile({
    required this.action,
    required this.onTap,
    super.key,
  });

  final ReportActionItemData action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.isOverdue
        ? const Color(0xFFC62828)
        : action.isUrgent
        ? const Color(0xFFEF6C00)
        : const Color(0xFF1565C0);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          action.isOverdue
              ? Icons.event_busy_outlined
              : Icons.schedule_outlined,
          color: color,
        ),
      ),
      title: Text(
        action.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          if (action.farmName.isNotEmpty) action.farmName,
          if (action.responsible.isNotEmpty) action.responsible,
        ].join(' · '),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          action.isOverdue ? 'Atrasada' : action.deadline,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ExecutiveDistributionGrid extends StatelessWidget {
  const ExecutiveDistributionGrid({required this.actions, super.key});

  final List<ReportActionItemData> actions;

  @override
  Widget build(BuildContext context) {
    final statusItems = buildStatusDistribution(actions);

    final priorityItems = buildPriorityDistribution(actions);

    final responsibleItems = buildResponsibleRanking(actions);

    final farmItems = buildFarmRanking(actions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 920;

        final cards = [
          ExecutiveDistributionCard(
            title: 'Por status',
            icon: Icons.donut_large_outlined,
            items: statusItems,
          ),
          ExecutiveDistributionCard(
            title: 'Por prioridade',
            icon: Icons.flag_outlined,
            items: priorityItems,
          ),
          ExecutiveDistributionCard(
            title: 'Ranking por responsável',
            icon: Icons.groups_outlined,
            items: responsibleItems,
          ),
          ExecutiveDistributionCard(
            title: 'Ranking por fazenda',
            icon: Icons.home_work_outlined,
            items: farmItems,
          ),
        ];

        if (!useRow) {
          return Column(
            children: List.generate(cards.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == cards.length - 1 ? 0 : 14,
                ),
                child: cards[index],
              );
            }),
          );
        }

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards.map((card) {
            return SizedBox(
              width: (constraints.maxWidth - 14) / 2,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }
}

class ExecutiveDistributionCard extends StatelessWidget {
  const ExecutiveDistributionCard({
    required this.title,
    required this.icon,
    required this.items,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<ExecutiveDistributionItem> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.isEmpty
        ? 1
        : items
              .map((item) => item.value)
              .reduce((first, second) => first > second ? first : second);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1B5E20)),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            if (items.isEmpty)
              const Text(
                'Sem dados para exibir.',
                style: TextStyle(color: Colors.black54),
              )
            else
              ...List.generate(items.length, (index) {
                final item = items[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 13,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            item.value.toString(),
                            style: TextStyle(
                              color: item.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: item.value / maxValue,
                          backgroundColor: item.color.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(item.color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class ExecutiveDistributionItem {
  const ExecutiveDistributionItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class ExecutiveRecommendationCard extends StatelessWidget {
  const ExecutiveRecommendationCard({
    required this.actions,
    required this.historyByActionId,
    required this.onOpenActions,
    super.key,
  });

  final List<ReportActionItemData> actions;

  final Map<String, List<ReportActionHistoryData>> historyByActionId;

  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final analytics = ReportActionAnalytics.fromData(
      actions: actions,
      historyByActionId: historyByActionId,
    );

    final recommendation = buildAnalyticsRecommendation(analytics);

    return Card(
      color: const Color(0xFF263238),
      child: Padding(
        padding: const EdgeInsets.all(23),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: recommendation.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                recommendation.icon,
                color: recommendation.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recomendação executiva',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    recommendation.title,
                    style: TextStyle(
                      color: recommendation.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    recommendation.message,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recommendation.action,
                    style: TextStyle(
                      color: recommendation.color,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onOpenActions,
                    style: TextButton.styleFrom(
                      foregroundColor: recommendation.color,
                    ),
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Abrir plano de ação'),
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

List<ReportActionItemData> buildUpcomingActions(
  List<ReportActionItemData> actions,
) {
  final result = actions.where((action) {
    return action.hasDeadline;
  }).toList();

  result.sort(compareReportActions);

  return result.take(6).toList();
}

List<ExecutiveDistributionItem> buildStatusDistribution(
  List<ReportActionItemData> actions,
) {
  final values = <String, int>{
    'Pendente': 0,
    'Em andamento': 0,
    'Concluída': 0,
    'Cancelada': 0,
  };

  for (final action in actions) {
    values.update(action.status, (value) => value + 1, ifAbsent: () => 1);
  }

  return values.entries.map((entry) {
    return ExecutiveDistributionItem(
      label: entry.key,
      value: entry.value,
      color: executiveStatusColor(entry.key),
    );
  }).toList();
}

List<ExecutiveDistributionItem> buildPriorityDistribution(
  List<ReportActionItemData> actions,
) {
  final values = <String, int>{};

  for (final action in actions) {
    values.update(action.priority, (value) => value + 1, ifAbsent: () => 1);
  }

  final entries = values.entries.toList()
    ..sort((first, second) => second.value.compareTo(first.value));

  return entries.take(6).map((entry) {
    return ExecutiveDistributionItem(
      label: entry.key,
      value: entry.value,
      color: analyticsPriorityColor(entry.key),
    );
  }).toList();
}

List<ExecutiveDistributionItem> buildResponsibleRanking(
  List<ReportActionItemData> actions,
) {
  final values = <String, int>{};

  for (final action in actions) {
    if (!action.isOpen) {
      continue;
    }

    final responsible = action.responsible.trim();

    if (responsible.isEmpty) {
      continue;
    }

    values.update(responsible, (value) => value + 1, ifAbsent: () => 1);
  }

  final entries = values.entries.toList()
    ..sort((first, second) => second.value.compareTo(first.value));

  return entries.take(6).map((entry) {
    return ExecutiveDistributionItem(
      label: entry.key,
      value: entry.value,
      color: const Color(0xFF1565C0),
    );
  }).toList();
}

List<ExecutiveDistributionItem> buildFarmRanking(
  List<ReportActionItemData> actions,
) {
  final values = <String, int>{};

  for (final action in actions) {
    if (!action.isOpen) {
      continue;
    }

    final farm = action.farmName.trim();

    final label = farm.isEmpty ? 'Todas as fazendas' : farm;

    values.update(label, (value) => value + 1, ifAbsent: () => 1);
  }

  final entries = values.entries.toList()
    ..sort((first, second) => second.value.compareTo(first.value));

  return entries.take(6).map((entry) {
    return ExecutiveDistributionItem(
      label: entry.key,
      value: entry.value,
      color: const Color(0xFF1B5E20),
    );
  }).toList();
}

Color executiveStatusColor(String status) {
  switch (status) {
    case 'Em andamento':
      return const Color(0xFF1565C0);

    case 'Concluída':
      return const Color(0xFF1B5E20);

    case 'Cancelada':
      return const Color(0xFF607D8B);

    default:
      return const Color(0xFFEF6C00);
  }
}

class ExecutiveReleaseCandidateAccessCard extends StatelessWidget {
  const ExecutiveReleaseCandidateAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF1565C0),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Release Candidate 1.0',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Execute o checklist técnico e acompanhe a preparação da primeira versão estável.',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveConsultancyWorkflowAccessCard extends StatelessWidget {
  const ExecutiveConsultancyWorkflowAccessCard({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: Color(0xFF2E7D32),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Consultancy Workflow',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Gerencie casos, etapas, visitas e planos de ação da consultoria veterinária.',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveSystemCenterAccessCard extends StatelessWidget {
  const ExecutiveSystemCenterAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.settings_suggest_outlined,
                  color: Color(0xFF00695C),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas System Center',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Gerencie configurações globais e acompanhe o inventário técnico da plataforma.',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveFoundationCenterAccessCard extends StatelessWidget {
  const ExecutiveFoundationCenterAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.foundation_outlined,
                  color: Color(0xFF5D4037),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Architecture Foundation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Acompanhe a consolidação técnica e a migração progressiva da base do Atlas.',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveOrchestratorAccessCard extends StatelessWidget {
  const ExecutiveOrchestratorAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF3949AB).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: Color(0xFF3949AB),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Orchestrator Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Execute e acompanhe o pipeline central que coordena os principais motores da plataforma.',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveObservabilityAccessCard extends StatelessWidget {
  const ExecutiveObservabilityAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00838F).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: Color(0xFF00838F),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Observability & Diagnostics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Acompanhe a saúde da plataforma, falhas, alertas e desempenho dos módulos.',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveIntegrationCoreAccessCard extends StatelessWidget {
  const ExecutiveIntegrationCoreAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF5E35B1).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Color(0xFF5E35B1),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Integration Core',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Monitore módulos conectados, eventos compartilhados e a saúde da arquitetura unificada.',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExecutiveSyncPlatformAccessCard extends StatelessWidget {
  const ExecutiveSyncPlatformAccessCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.cloud_sync_outlined,
                  color: Color(0xFF1565C0),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atlas Sync & Cloud Platform',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Gerencie a fila centralizada, sincronização automática, falhas, conflitos e o estado da conexão.',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
