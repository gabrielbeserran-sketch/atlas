import 'dart:math' as math;

import 'package:projeto_atlas/features/decision_engine_v2/domain/models/atlas_decision_engine_v2_data.dart';
import 'package:projeto_atlas/features/mission_control/domain/models/atlas_mission_control_data.dart';
import 'package:projeto_atlas/features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/models/atlas_workflow_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasMissionControlService {
  const AtlasMissionControlService();

  AtlasMissionControlData build({
    required AtlasDecisionEngineV2Data decisionEngine,
    required AtlasPredictiveAnalyticsData predictive,
    required AtlasWorkflowData workflow,
    String userName = 'Gestor',
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final priorities = _buildPriorities(
      decisionEngine: decisionEngine,
      predictive: predictive,
      workflow: workflow,
    );

    final alerts = _buildAlerts(predictive: predictive, workflow: workflow);

    final workflowSummaries = _buildWorkflowSummaries(workflow);

    final decisionSummaries = _buildDecisionSummaries(decisionEngine);

    final dailyPlan = _buildDailyPlan(priorities);

    final globalScore = _globalScore(
      decisionEngine: decisionEngine,
      predictive: predictive,
      workflow: workflow,
    );

    final executionProbability = _executionProbability(workflow);

    final goalProbability = _goalProbability(
      decisionEngine: decisionEngine,
      predictive: predictive,
    );

    final monthlyImpact = _monthlyImpact(
      decisionEngine: decisionEngine,
      predictive: predictive,
    );

    final status = _status(
      priorities: priorities,
      alerts: alerts,
      globalScore: globalScore,
    );

    return AtlasMissionControlData(
      generatedAt: currentTime,
      greeting: _greeting(userName: userName, now: currentTime),
      summary: _summary(
        priorities: priorities,
        alerts: alerts,
        workflow: workflow,
        executionProbability: executionProbability,
        goalProbability: goalProbability,
        monthlyImpact: monthlyImpact,
      ),
      globalScore: globalScore,
      executionProbabilityPercent: executionProbability,
      goalProbabilityPercent: goalProbability,
      estimatedMonthlyImpact: monthlyImpact,
      status: status,
      priorities: priorities,
      alerts: alerts,
      workflows: workflowSummaries,
      decisions: decisionSummaries,
      dailyPlan: dailyPlan,
    );
  }

  List<AtlasMissionPriority> _buildPriorities({
    required AtlasDecisionEngineV2Data decisionEngine,
    required AtlasPredictiveAnalyticsData predictive,
    required AtlasWorkflowData workflow,
  }) {
    final candidates = <_MissionCandidate>[];

    for (final action in decisionEngine.rankedActions.take(12)) {
      candidates.add(
        _MissionCandidate(
          id: 'decision_${action.id}',
          farmName: action.farmName,
          title: action.title,
          description: action.description,
          category: action.category,
          score:
              action.decisionScore * 0.55 +
              action.impactScore * 0.20 +
              action.confidencePercent * 0.25,
          confidencePercent: action.confidencePercent,
          expectedFinancialImpact: action.expectedFinancialImpact,
          deadlineDays: action.deadlineDays,
          priority: _priorityFromDecision(action.priority),
          urgency: _urgencyFromDecision(action.urgency),
          source: AtlasMissionSource.decisionEngine,
          recommendation: action.expectedResult,
        ),
      );
    }

    for (final risk in predictive.risks.take(8)) {
      candidates.add(
        _MissionCandidate(
          id: 'risk_${risk.id}',
          farmName: risk.farmName,
          title: risk.title,
          description: risk.description,
          category: risk.category,
          score:
              risk.probabilityPercent * 0.55 +
              _severityWeight(_severityFromPredictive(risk.level)) * 10 +
              math.min(risk.financialImpactValue / 1000, 20) * 0.45,
          confidencePercent: (100 - risk.probabilityPercent * 0.15)
              .clamp(40.0, 95.0)
              .toDouble(),
          expectedFinancialImpact: risk.financialImpactValue,
          deadlineDays: risk.level == AtlasPredictiveAnalyticsRiskLevel.critical
              ? 1
              : 7,
          priority: risk.level == AtlasPredictiveAnalyticsRiskLevel.critical
              ? AtlasMissionPriorityLevel.critical
              : AtlasMissionPriorityLevel.high,
          urgency: risk.level == AtlasPredictiveAnalyticsRiskLevel.critical
              ? AtlasMissionUrgency.immediate
              : AtlasMissionUrgency.high,
          source: AtlasMissionSource.predictiveAnalytics,
          recommendation: risk.recommendation,
        ),
      );
    }

    for (final task in workflow.delayedTaskList.take(8)) {
      candidates.add(
        _MissionCandidate(
          id: 'workflow_${task.id}',
          farmName: _farmForTask(task: task, workflows: workflow.workflows),
          title: 'Resolver atraso em ${task.title}',
          description:
              'A tarefa está atrasada e pode comprometer o plano de execução.',
          category: _categoryForTask(task: task, workflows: workflow.workflows),
          score:
              78 +
              math.min(
                DateTime.now().difference(task.deadline).inDays.abs() * 2,
                20,
              ),
          confidencePercent: 96,
          expectedFinancialImpact: 0,
          deadlineDays: 1,
          priority: AtlasMissionPriorityLevel.critical,
          urgency: AtlasMissionUrgency.immediate,
          source: AtlasMissionSource.workflow,
          recommendation:
              'Revisar responsável, dependências e recursos imediatamente.',
        ),
      );
    }

    candidates.sort((first, second) => second.score.compareTo(first.score));

    return List.generate(math.min(candidates.length, 15), (index) {
      final item = candidates[index];

      return AtlasMissionPriority(
        position: index + 1,
        id: item.id,
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        priority: item.priority,
        urgency: item.urgency,
        impactScore: item.score.clamp(0.0, 100.0).toDouble(),
        confidencePercent: item.confidencePercent,
        expectedFinancialImpact: item.expectedFinancialImpact,
        deadlineDays: item.deadlineDays,
        source: item.source,
        recommendation: item.recommendation,
      );
    });
  }

  List<AtlasMissionAlert> _buildAlerts({
    required AtlasPredictiveAnalyticsData predictive,
    required AtlasWorkflowData workflow,
  }) {
    final result = <AtlasMissionAlert>[];

    for (final risk in predictive.risks.take(10)) {
      result.add(
        AtlasMissionAlert(
          id: 'alert_${risk.id}',
          farmName: risk.farmName,
          title: risk.title,
          description: risk.description,
          category: risk.category,
          severity: _severityFromPredictive(risk.level),
          probabilityPercent: risk.probabilityPercent,
          expectedFinancialImpact: risk.financialImpactValue,
          source: AtlasMissionSource.predictiveAnalytics,
          recommendation: risk.recommendation,
        ),
      );
    }

    for (final task in workflow.delayedTaskList.take(8)) {
      result.add(
        AtlasMissionAlert(
          id: 'alert_workflow_${task.id}',
          farmName: _farmForTask(task: task, workflows: workflow.workflows),
          title: 'Tarefa atrasada — ${task.title}',
          description: 'O atraso pode comprometer o cronograma geral.',
          category: _categoryForTask(task: task, workflows: workflow.workflows),
          severity: AtlasMissionSeverity.high,
          probabilityPercent: 95,
          expectedFinancialImpact: 0,
          source: AtlasMissionSource.workflow,
          recommendation: 'Replanejar prazo e confirmar o responsável.',
        ),
      );
    }

    result.sort((first, second) {
      final severityComparison = _severityWeight(
        second.severity,
      ).compareTo(_severityWeight(first.severity));

      if (severityComparison != 0) {
        return severityComparison;
      }

      return second.probabilityPercent.compareTo(first.probabilityPercent);
    });

    return result.take(15).toList();
  }

  List<AtlasMissionWorkflowSummary> _buildWorkflowSummaries(
    AtlasWorkflowData workflow,
  ) {
    return workflow.workflows.map((item) {
      final completed = item.tasks.where((task) {
        return task.status == AtlasWorkflowTaskStatus.completed;
      }).length;

      final delayed = item.tasks.where((task) {
        return task.status == AtlasWorkflowTaskStatus.delayed;
      }).length;

      return AtlasMissionWorkflowSummary(
        id: item.id,
        farmName: item.farmName,
        title: item.title,
        status: _workflowStatus(item.status),
        progressPercent: item.progressPercent,
        totalTasks: item.tasks.length,
        completedTasks: completed,
        delayedTasks: delayed,
        deadline: item.deadline,
      );
    }).toList();
  }

  List<AtlasMissionDecisionSummary> _buildDecisionSummaries(
    AtlasDecisionEngineV2Data decisionEngine,
  ) {
    return decisionEngine.rankedActions.take(10).map((item) {
      return AtlasMissionDecisionSummary(
        position: item.position,
        id: item.id,
        farmName: item.farmName,
        title: item.title,
        priority: _priorityFromDecision(item.priority),
        urgency: _urgencyFromDecision(item.urgency),
        confidencePercent: item.confidencePercent,
        expectedFinancialImpact: item.expectedFinancialImpact,
        deadlineDays: item.deadlineDays,
      );
    }).toList();
  }

  List<AtlasMissionDailyAction> _buildDailyPlan(
    List<AtlasMissionPriority> priorities,
  ) {
    final urgent = priorities
        .where((item) {
          return item.urgency == AtlasMissionUrgency.immediate ||
              item.deadlineDays <= 1;
        })
        .take(6);

    return List.generate(urgent.length, (index) {
      final item = urgent.elementAt(index);

      return AtlasMissionDailyAction(
        position: index + 1,
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        priority: item.priority,
        deadlineHours: item.urgency == AtlasMissionUrgency.immediate ? 4 : 12,
        expectedImpact: item.expectedFinancialImpact > 0
            ? 'Impacto estimado de '
                  'R\$ ${item.expectedFinancialImpact.toStringAsFixed(2)}.'
            : item.recommendation,
        completed: false,
      );
    });
  }

  double _globalScore({
    required AtlasDecisionEngineV2Data decisionEngine,
    required AtlasPredictiveAnalyticsData predictive,
    required AtlasWorkflowData workflow,
  }) {
    return (decisionEngine.score * 0.40 +
            predictive.score * 0.30 +
            workflow.executionScore * 0.30)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _executionProbability(AtlasWorkflowData workflow) {
    if (!workflow.hasData) {
      return 0;
    }

    return (workflow.progressPercent * 0.55 +
            workflow.executionScore * 0.35 +
            (100 - workflow.delayedTasks * 8) * 0.10)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _goalProbability({
    required AtlasDecisionEngineV2Data decisionEngine,
    required AtlasPredictiveAnalyticsData predictive,
  }) {
    return (decisionEngine.confidencePercent * 0.55 +
            predictive.confidencePercent * 0.45)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _monthlyImpact({
    required AtlasDecisionEngineV2Data decisionEngine,
    required AtlasPredictiveAnalyticsData predictive,
  }) {
    final decisionImpact = decisionEngine.monthlyPlan.fold<double>(
      0,
      (sum, item) => sum + item.expectedFinancialImpact,
    );

    final predictiveImpact = predictive.scenarios
        .where((item) {
          return item.type == AtlasPredictiveScenarioType.expected;
        })
        .take(10)
        .fold<double>(0, (sum, item) => sum + item.projectedFinancialImpact);

    return decisionImpact + predictiveImpact;
  }

  AtlasMissionControlStatus _status({
    required List<AtlasMissionPriority> priorities,
    required List<AtlasMissionAlert> alerts,
    required double globalScore,
  }) {
    final criticalCount = priorities.where((item) {
      return item.priority == AtlasMissionPriorityLevel.critical;
    }).length;

    final criticalAlerts = alerts.where((item) {
      return item.severity == AtlasMissionSeverity.critical;
    }).length;

    if (criticalCount >= 3 || criticalAlerts >= 2 || globalScore < 40) {
      return AtlasMissionControlStatus.critical;
    }

    if (criticalCount > 0 || alerts.length >= 6 || globalScore < 60) {
      return AtlasMissionControlStatus.highRisk;
    }

    if (alerts.isNotEmpty || globalScore < 75) {
      return AtlasMissionControlStatus.attention;
    }

    return AtlasMissionControlStatus.stable;
  }

  String _greeting({required String userName, required DateTime now}) {
    final period = now.hour < 12
        ? 'Bom dia'
        : now.hour < 18
        ? 'Boa tarde'
        : 'Boa noite';

    return '$period, $userName.';
  }

  String _summary({
    required List<AtlasMissionPriority> priorities,
    required List<AtlasMissionAlert> alerts,
    required AtlasWorkflowData workflow,
    required double executionProbability,
    required double goalProbability,
    required double monthlyImpact,
  }) {
    final critical = priorities.where((item) {
      return item.priority == AtlasMissionPriorityLevel.critical;
    }).length;

    return 'Hoje existem $critical prioridades críticas, '
        '${alerts.length} alertas ativos, '
        '${workflow.totalTasks} tarefas monitoradas, '
        '${executionProbability.toStringAsFixed(0)}% de probabilidade de execução, '
        '${goalProbability.toStringAsFixed(0)}% de probabilidade de atingir as metas e '
        'impacto mensal estimado de R\$ ${monthlyImpact.toStringAsFixed(2)}.';
  }

  AtlasMissionPriorityLevel _priorityFromDecision(
    AtlasDecisionV2Priority priority,
  ) {
    switch (priority) {
      case AtlasDecisionV2Priority.low:
        return AtlasMissionPriorityLevel.low;

      case AtlasDecisionV2Priority.medium:
        return AtlasMissionPriorityLevel.medium;

      case AtlasDecisionV2Priority.high:
        return AtlasMissionPriorityLevel.high;

      case AtlasDecisionV2Priority.critical:
        return AtlasMissionPriorityLevel.critical;
    }
  }

  AtlasMissionUrgency _urgencyFromDecision(AtlasDecisionV2Urgency urgency) {
    switch (urgency) {
      case AtlasDecisionV2Urgency.low:
        return AtlasMissionUrgency.low;

      case AtlasDecisionV2Urgency.medium:
        return AtlasMissionUrgency.medium;

      case AtlasDecisionV2Urgency.high:
        return AtlasMissionUrgency.high;

      case AtlasDecisionV2Urgency.immediate:
        return AtlasMissionUrgency.immediate;
    }
  }

  AtlasMissionSeverity _severityFromPredictive(
    AtlasPredictiveAnalyticsRiskLevel level,
  ) {
    switch (level) {
      case AtlasPredictiveAnalyticsRiskLevel.low:
        return AtlasMissionSeverity.low;

      case AtlasPredictiveAnalyticsRiskLevel.medium:
        return AtlasMissionSeverity.medium;

      case AtlasPredictiveAnalyticsRiskLevel.high:
        return AtlasMissionSeverity.high;

      case AtlasPredictiveAnalyticsRiskLevel.critical:
        return AtlasMissionSeverity.critical;
    }
  }

  AtlasMissionWorkflowStatus _workflowStatus(AtlasWorkflowStatus status) {
    switch (status) {
      case AtlasWorkflowStatus.planned:
        return AtlasMissionWorkflowStatus.planned;

      case AtlasWorkflowStatus.inProgress:
        return AtlasMissionWorkflowStatus.inProgress;

      case AtlasWorkflowStatus.delayed:
        return AtlasMissionWorkflowStatus.delayed;

      case AtlasWorkflowStatus.completed:
        return AtlasMissionWorkflowStatus.completed;

      case AtlasWorkflowStatus.cancelled:
        return AtlasMissionWorkflowStatus.cancelled;
    }
  }

  int _severityWeight(AtlasMissionSeverity severity) {
    switch (severity) {
      case AtlasMissionSeverity.low:
        return 1;

      case AtlasMissionSeverity.medium:
        return 2;

      case AtlasMissionSeverity.high:
        return 3;

      case AtlasMissionSeverity.critical:
        return 4;
    }
  }

  String _farmForTask({
    required AtlasWorkflowTask task,
    required List<AtlasWorkflow> workflows,
  }) {
    for (final workflow in workflows) {
      if (workflow.id == task.workflowId) {
        return workflow.farmName;
      }
    }

    return 'Operação';
  }

  AtlasBiCategory _categoryForTask({
    required AtlasWorkflowTask task,
    required List<AtlasWorkflow> workflows,
  }) {
    for (final workflow in workflows) {
      if (workflow.id == task.workflowId) {
        return workflow.category;
      }
    }

    return AtlasBiCategory.management;
  }
}

class _MissionCandidate {
  const _MissionCandidate({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.score,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineDays,
    required this.priority,
    required this.urgency,
    required this.source,
    required this.recommendation,
  });

  final String id;
  final String farmName;
  final String title;
  final String description;
  final AtlasBiCategory category;

  final double score;
  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineDays;

  final AtlasMissionPriorityLevel priority;
  final AtlasMissionUrgency urgency;
  final AtlasMissionSource source;

  final String recommendation;
}
