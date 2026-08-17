import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_os/domain/models/atlas_os_data.dart';
import 'package:projeto_atlas/features/mission_control/domain/models/atlas_mission_control_data.dart';

class AtlasOsService {
  const AtlasOsService();

  AtlasOsData build({
    required AtlasMissionControlData missionControl,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final modules = _buildModules(missionControl);

    final commands = _buildCommands(missionControl);

    final criticalItems = _buildCriticalItems(missionControl);

    final dailyCycle = _buildDailyCycle(currentTime);

    final healthScore = _healthScore(
      missionControl: missionControl,
      modules: modules,
    );

    final status = _statusFromMission(missionControl.status);

    return AtlasOsData(
      generatedAt: currentTime,
      title: 'Atlas OS',
      summary: _summary(
        missionControl: missionControl,
        modules: modules,
        commands: commands,
        criticalItems: criticalItems,
      ),
      healthScore: healthScore,
      executionPercent: missionControl.executionProbabilityPercent,
      goalProbabilityPercent: missionControl.goalProbabilityPercent,
      estimatedMonthlyImpact: missionControl.estimatedMonthlyImpact,
      status: status,
      modules: modules,
      commands: commands,
      dailyCycle: dailyCycle,
      criticalItems: criticalItems,
    );
  }

  List<AtlasOsModuleState> _buildModules(
    AtlasMissionControlData missionControl,
  ) {
    final criticalPriorities = missionControl.priorities.where((item) {
      return item.priority == AtlasMissionPriorityLevel.critical;
    }).length;

    final criticalAlerts = missionControl.alerts.where((item) {
      return item.severity == AtlasMissionSeverity.critical;
    }).length;

    final delayedWorkflows = missionControl.workflows.where((item) {
      return item.status == AtlasMissionWorkflowStatus.delayed;
    }).length;

    return [
      AtlasOsModuleState(
        id: 'mission_control',
        title: 'Mission Control',
        description: 'Coordenação executiva da operação.',
        status: _moduleStatus(
          criticalCount: criticalPriorities + criticalAlerts,
          attentionCount: missionControl.alerts.length,
        ),
        score: missionControl.globalScore,
        pendingItems: missionControl.priorities.length,
        criticalItems: criticalPriorities + criticalAlerts,
      ),
      AtlasOsModuleState(
        id: 'decision_engine',
        title: 'Decision Engine',
        description: 'Priorização e recomendação de decisões.',
        status: _moduleStatus(
          criticalCount: criticalPriorities,
          attentionCount: missionControl.decisions.length,
        ),
        score: missionControl.goalProbabilityPercent,
        pendingItems: missionControl.decisions.length,
        criticalItems: criticalPriorities,
      ),
      AtlasOsModuleState(
        id: 'workflow',
        title: 'Workflow Engine',
        description: 'Execução e acompanhamento dos planos.',
        status: _moduleStatus(
          criticalCount: delayedWorkflows,
          attentionCount: missionControl.workflows.length,
        ),
        score: missionControl.executionProbabilityPercent,
        pendingItems: missionControl.workflows.length,
        criticalItems: delayedWorkflows,
      ),
      AtlasOsModuleState(
        id: 'predictive',
        title: 'Predictive Analytics',
        description: 'Riscos futuros e projeções.',
        status: _moduleStatus(
          criticalCount: criticalAlerts,
          attentionCount: missionControl.alerts.length,
        ),
        score: missionControl.goalProbabilityPercent,
        pendingItems: missionControl.alerts.length,
        criticalItems: criticalAlerts,
      ),
    ];
  }

  List<AtlasOsCommand> _buildCommands(AtlasMissionControlData missionControl) {
    final result = <AtlasOsCommand>[];

    for (final item in missionControl.dailyPlan.take(8)) {
      result.add(
        AtlasOsCommand(
          position: result.length + 1,
          id: 'command_daily_${item.position}_${item.farmName}',
          title: item.title,
          description: item.description,
          farmName: item.farmName,
          priority: _priorityFromMission(item.priority),
          deadlineHours: item.deadlineHours,
          expectedImpact: item.expectedImpact,
          source: 'Plano diário',
          completed: item.completed,
        ),
      );
    }

    if (result.length < 8) {
      for (final item in missionControl.priorities) {
        final alreadyAdded = result.any((command) {
          return command.title == item.title &&
              command.farmName == item.farmName;
        });

        if (alreadyAdded) {
          continue;
        }

        result.add(
          AtlasOsCommand(
            position: result.length + 1,
            id: 'command_priority_${item.id}',
            title: item.title,
            description: item.description,
            farmName: item.farmName,
            priority: _priorityFromMission(item.priority),
            deadlineHours: math.max(4, item.deadlineDays * 24),
            expectedImpact: item.expectedFinancialImpact > 0
                ? 'Impacto estimado de '
                      'R\$ ${item.expectedFinancialImpact.toStringAsFixed(2)}.'
                : item.recommendation,
            source: atlasMissionSourceLabel(item.source),
            completed: false,
          ),
        );

        if (result.length >= 8) {
          break;
        }
      }
    }

    return result;
  }

  List<AtlasOsCriticalItem> _buildCriticalItems(
    AtlasMissionControlData missionControl,
  ) {
    return missionControl.alerts
        .where((item) {
          return item.severity == AtlasMissionSeverity.high ||
              item.severity == AtlasMissionSeverity.critical;
        })
        .take(10)
        .map((item) {
          return AtlasOsCriticalItem(
            id: 'critical_${item.id}',
            title: item.title,
            description: item.description,
            farmName: item.farmName,
            severity: _severityFromMission(item.severity),
            probabilityPercent: item.probabilityPercent,
            expectedFinancialImpact: item.expectedFinancialImpact,
            recommendation: item.recommendation,
          );
        })
        .toList();
  }

  List<AtlasOsDailyCycleItem> _buildDailyCycle(DateTime now) {
    final hour = now.hour;

    AtlasOsCycleStatus statusFor(AtlasOsDayPeriod period) {
      switch (period) {
        case AtlasOsDayPeriod.morning:
          if (hour >= 12) {
            return AtlasOsCycleStatus.completed;
          }

          if (hour >= 6) {
            return AtlasOsCycleStatus.inProgress;
          }

          return AtlasOsCycleStatus.pending;

        case AtlasOsDayPeriod.afternoon:
          if (hour >= 18) {
            return AtlasOsCycleStatus.completed;
          }

          if (hour >= 12) {
            return AtlasOsCycleStatus.inProgress;
          }

          return AtlasOsCycleStatus.pending;

        case AtlasOsDayPeriod.evening:
          if (hour >= 22) {
            return AtlasOsCycleStatus.completed;
          }

          if (hour >= 18) {
            return AtlasOsCycleStatus.inProgress;
          }

          return AtlasOsCycleStatus.pending;
      }
    }

    return [
      AtlasOsDailyCycleItem(
        position: 1,
        title: 'Planejar o dia',
        description: 'Revisar prioridades, riscos e responsáveis.',
        period: AtlasOsDayPeriod.morning,
        status: statusFor(AtlasOsDayPeriod.morning),
      ),
      AtlasOsDailyCycleItem(
        position: 2,
        title: 'Acompanhar execução',
        description: 'Confirmar progresso das tarefas e remover bloqueios.',
        period: AtlasOsDayPeriod.afternoon,
        status: statusFor(AtlasOsDayPeriod.afternoon),
      ),
      AtlasOsDailyCycleItem(
        position: 3,
        title: 'Fechar o dia',
        description:
            'Registrar resultados e preparar as prioridades seguintes.',
        period: AtlasOsDayPeriod.evening,
        status: statusFor(AtlasOsDayPeriod.evening),
      ),
    ];
  }

  double _healthScore({
    required AtlasMissionControlData missionControl,
    required List<AtlasOsModuleState> modules,
  }) {
    if (modules.isEmpty) {
      return missionControl.globalScore;
    }

    final moduleAverage =
        modules.fold<double>(0, (sum, item) => sum + item.score) /
        modules.length;

    return (missionControl.globalScore * 0.55 + moduleAverage * 0.45)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasOsStatus _statusFromMission(AtlasMissionControlStatus status) {
    switch (status) {
      case AtlasMissionControlStatus.stable:
        return AtlasOsStatus.stable;

      case AtlasMissionControlStatus.attention:
        return AtlasOsStatus.attention;

      case AtlasMissionControlStatus.highRisk:
        return AtlasOsStatus.highRisk;

      case AtlasMissionControlStatus.critical:
        return AtlasOsStatus.critical;
    }
  }

  AtlasOsModuleStatus _moduleStatus({
    required int criticalCount,
    required int attentionCount,
  }) {
    if (criticalCount >= 2) {
      return AtlasOsModuleStatus.critical;
    }

    if (criticalCount > 0 || attentionCount >= 5) {
      return AtlasOsModuleStatus.attention;
    }

    return AtlasOsModuleStatus.active;
  }

  AtlasOsPriority _priorityFromMission(AtlasMissionPriorityLevel priority) {
    switch (priority) {
      case AtlasMissionPriorityLevel.low:
        return AtlasOsPriority.low;

      case AtlasMissionPriorityLevel.medium:
        return AtlasOsPriority.medium;

      case AtlasMissionPriorityLevel.high:
        return AtlasOsPriority.high;

      case AtlasMissionPriorityLevel.critical:
        return AtlasOsPriority.critical;
    }
  }

  AtlasOsSeverity _severityFromMission(AtlasMissionSeverity severity) {
    switch (severity) {
      case AtlasMissionSeverity.low:
        return AtlasOsSeverity.low;

      case AtlasMissionSeverity.medium:
        return AtlasOsSeverity.medium;

      case AtlasMissionSeverity.high:
        return AtlasOsSeverity.high;

      case AtlasMissionSeverity.critical:
        return AtlasOsSeverity.critical;
    }
  }

  String _summary({
    required AtlasMissionControlData missionControl,
    required List<AtlasOsModuleState> modules,
    required List<AtlasOsCommand> commands,
    required List<AtlasOsCriticalItem> criticalItems,
  }) {
    final activeModules = modules.where((item) {
      return item.status == AtlasOsModuleStatus.active;
    }).length;

    return 'O Atlas OS coordena ${modules.length} módulos, '
        '$activeModules em situação normal, '
        '${commands.length} comandos operacionais, '
        '${criticalItems.length} itens críticos, '
        '${missionControl.executionProbabilityPercent.toStringAsFixed(0)}% '
        'de execução prevista e impacto mensal estimado de '
        'R\$ ${missionControl.estimatedMonthlyImpact.toStringAsFixed(2)}.';
  }
}
