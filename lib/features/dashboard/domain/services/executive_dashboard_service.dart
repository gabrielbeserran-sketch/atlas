import 'package:projeto_atlas/features/dashboard/domain/models/executive_dashboard_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class ExecutiveDashboardService {
  const ExecutiveDashboardService();

  ExecutiveDashboardData buildDashboard({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    String scopeLabel = 'Visão consolidada',
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();

    final orderedActions = List<ReportActionItemData>.from(actions)
      ..sort(compareReportActions);

    final analytics = _ExecutiveDashboardAnalytics.fromData(
      actions: orderedActions,
      historyByActionId: historyByActionId,
      now: now,
    );

    return ExecutiveDashboardData(
      generatedAt: formatExecutiveDateTime(now),
      scopeLabel: scopeLabel,
      kpis: _buildKpis(analytics),
      alerts: _buildAlerts(analytics),
      recommendations: _buildRecommendations(analytics),
      responsibleRanking: _buildResponsibleRanking(analytics),
      farmRanking: _buildFarmRanking(analytics),
      priorityRanking: _buildPriorityRanking(analytics),
      statusDistribution: _buildStatusDistribution(analytics),
      monthlyEvolution: _buildMonthlyEvolution(
        actions: orderedActions,
        historyByActionId: historyByActionId,
        now: now,
      ),
      weeklyEvolution: _buildWeeklyEvolution(
        actions: orderedActions,
        historyByActionId: historyByActionId,
        now: now,
      ),
      generalPerformanceIndex: _calculatePerformanceIndex(analytics),
      productivityTrend: _buildProductivityTrend(
        actions: orderedActions,
        historyByActionId: historyByActionId,
        now: now,
      ),
      delayTrend: _buildDelayTrend(actions: orderedActions, now: now),
    );
  }

  List<ExecutiveKpiData> _buildKpis(_ExecutiveDashboardAnalytics analytics) {
    return [
      ExecutiveKpiData(
        id: 'total_actions',
        title: 'Total de ações',
        value: analytics.totalCount.toString(),
        numericValue: analytics.totalCount.toDouble(),
        subtitle: 'Ações cadastradas no plano',
        type: ExecutiveKpiType.number,
        status: ExecutiveIndicatorStatus.normal,
        change: analytics.createdChange,
        changeLabel: 'Novas ações no período',
      ),
      ExecutiveKpiData(
        id: 'open_actions',
        title: 'Ações abertas',
        value: analytics.openCount.toString(),
        numericValue: analytics.openCount.toDouble(),
        subtitle: 'Pendentes e em andamento',
        type: ExecutiveKpiType.number,
        status: analytics.openCount == 0
            ? ExecutiveIndicatorStatus.positive
            : ExecutiveIndicatorStatus.normal,
        change: 0,
        changeLabel: '',
      ),
      ExecutiveKpiData(
        id: 'completed_actions',
        title: 'Ações concluídas',
        value: analytics.completedCount.toString(),
        numericValue: analytics.completedCount.toDouble(),
        subtitle: 'Ações finalizadas',
        type: ExecutiveKpiType.number,
        status: ExecutiveIndicatorStatus.positive,
        change: analytics.completedChange,
        changeLabel: 'Conclusões no período',
      ),
      ExecutiveKpiData(
        id: 'completion_rate',
        title: 'Taxa de conclusão',
        value: formatExecutivePercentage(analytics.completionRate),
        numericValue: analytics.completionRate,
        subtitle: 'Desconsiderando canceladas',
        type: ExecutiveKpiType.percentage,
        status: _completionStatus(analytics.completionRate),
        change: analytics.completionRateChange,
        changeLabel: 'Comparação com período anterior',
      ),
      ExecutiveKpiData(
        id: 'overdue_actions',
        title: 'Ações atrasadas',
        value: analytics.overdueCount.toString(),
        numericValue: analytics.overdueCount.toDouble(),
        subtitle: 'Ações abertas fora do prazo',
        type: ExecutiveKpiType.number,
        status: analytics.overdueCount == 0
            ? ExecutiveIndicatorStatus.positive
            : analytics.overdueRate >= 0.25
            ? ExecutiveIndicatorStatus.critical
            : ExecutiveIndicatorStatus.attention,
        change: analytics.overdueChange,
        changeLabel: 'Variação no atraso',
      ),
      ExecutiveKpiData(
        id: 'overdue_rate',
        title: 'Taxa de atraso',
        value: formatExecutivePercentage(analytics.overdueRate),
        numericValue: analytics.overdueRate,
        subtitle: 'Proporção de ações atrasadas',
        type: ExecutiveKpiType.percentage,
        status: _overdueStatus(analytics.overdueRate),
        change: analytics.overdueRateChange,
        changeLabel: 'Comparação com período anterior',
      ),
      ExecutiveKpiData(
        id: 'urgent_actions',
        title: 'Ações urgentes',
        value: analytics.urgentCount.toString(),
        numericValue: analytics.urgentCount.toDouble(),
        subtitle: 'Prioridades imediatas abertas',
        type: ExecutiveKpiType.number,
        status: analytics.urgentCount == 0
            ? ExecutiveIndicatorStatus.positive
            : ExecutiveIndicatorStatus.critical,
        change: 0,
        changeLabel: '',
      ),
      ExecutiveKpiData(
        id: 'average_completion_time',
        title: 'Prazo médio',
        value: analytics.averageCompletionDaysLabel,
        numericValue: analytics.averageCompletionDays ?? 0,
        subtitle: 'Tempo médio até a conclusão',
        type: ExecutiveKpiType.duration,
        status: ExecutiveIndicatorStatus.normal,
        change: 0,
        changeLabel: '',
      ),
      ExecutiveKpiData(
        id: 'performance_index',
        title: 'Índice geral',
        value: _calculatePerformanceIndex(analytics).toStringAsFixed(0),
        numericValue: _calculatePerformanceIndex(analytics),
        subtitle: 'Desempenho consolidado de 0 a 100',
        type: ExecutiveKpiType.score,
        status: _performanceStatus(_calculatePerformanceIndex(analytics)),
        change: 0,
        changeLabel: '',
      ),
    ];
  }

  List<ExecutiveAlertData> _buildAlerts(
    _ExecutiveDashboardAnalytics analytics,
  ) {
    final alerts = <ExecutiveAlertData>[];

    if (analytics.overdueCount > 0) {
      alerts.add(
        ExecutiveAlertData(
          id: 'overdue_actions',
          title: 'Ações atrasadas',
          message:
              '${analytics.overdueCount} '
              '${analytics.overdueCount == 1 ? 'ação está' : 'ações estão'} '
              'fora do prazo.',
          category: 'Prazo',
          severity: analytics.overdueRate >= 0.25
              ? ExecutiveAlertSeverity.critical
              : ExecutiveAlertSeverity.warning,
          count: analytics.overdueCount,
          actionLabel: 'Revisar ações atrasadas',
          route: '/report-actions',
        ),
      );
    }

    if (analytics.urgentCount > 0) {
      alerts.add(
        ExecutiveAlertData(
          id: 'urgent_actions',
          title: 'Prioridades urgentes',
          message:
              '${analytics.urgentCount} '
              '${analytics.urgentCount == 1 ? 'ação urgente permanece aberta' : 'ações urgentes permanecem abertas'}.',
          category: 'Prioridade',
          severity: ExecutiveAlertSeverity.critical,
          count: analytics.urgentCount,
          actionLabel: 'Abrir ações urgentes',
          route: '/report-actions',
        ),
      );
    }

    if (analytics.withoutResponsibleCount > 0) {
      alerts.add(
        ExecutiveAlertData(
          id: 'without_responsible',
          title: 'Ações sem responsável',
          message:
              '${analytics.withoutResponsibleCount} '
              '${analytics.withoutResponsibleCount == 1 ? 'ação aberta está' : 'ações abertas estão'} '
              'sem responsável definido.',
          category: 'Responsabilidade',
          severity: ExecutiveAlertSeverity.warning,
          count: analytics.withoutResponsibleCount,
          actionLabel: 'Definir responsáveis',
          route: '/report-actions',
        ),
      );
    }

    if (analytics.topResponsibleOpenCount >= 5) {
      alerts.add(
        ExecutiveAlertData(
          id: 'responsible_overload',
          title: 'Possível sobrecarga',
          message:
              '${analytics.topResponsible} concentra '
              '${analytics.topResponsibleOpenCount} ações abertas.',
          category: 'Equipe',
          severity: ExecutiveAlertSeverity.warning,
          count: analytics.topResponsibleOpenCount,
          actionLabel: 'Revisar distribuição',
          route: '/report-actions',
        ),
      );
    }

    if (analytics.dueTodayCount > 0) {
      alerts.add(
        ExecutiveAlertData(
          id: 'due_today',
          title: 'Vencimentos de hoje',
          message:
              '${analytics.dueTodayCount} '
              '${analytics.dueTodayCount == 1 ? 'ação vence' : 'ações vencem'} hoje.',
          category: 'Prazo',
          severity: ExecutiveAlertSeverity.warning,
          count: analytics.dueTodayCount,
          actionLabel: 'Abrir vencimentos',
          route: '/report-actions',
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        const ExecutiveAlertData(
          id: 'operation_normal',
          title: 'Operação sem alertas críticos',
          message: 'Nenhuma pendência crítica foi identificada no momento.',
          category: 'Operação',
          severity: ExecutiveAlertSeverity.information,
          count: 0,
          actionLabel: '',
          route: '',
        ),
      );
    }

    alerts.sort((first, second) {
      return _alertSeverityWeight(
        second.severity,
      ).compareTo(_alertSeverityWeight(first.severity));
    });

    return alerts;
  }

  List<ExecutiveRecommendationData> _buildRecommendations(
    _ExecutiveDashboardAnalytics analytics,
  ) {
    final recommendations = <ExecutiveRecommendationData>[];

    if (analytics.overdueRate >= 0.25) {
      recommendations.add(
        ExecutiveRecommendationData(
          id: 'reduce_overdue',
          title: 'Reduzir o volume de atrasos',
          message: 'A taxa de atraso está acima do nível recomendado.',
          recommendedAction:
              'Revisar prazos, redistribuir responsáveis e priorizar as ações vencidas.',
          priority: ExecutiveRecommendationPriority.critical,
          category: 'Prazo',
          confidence: 0.95,
        ),
      );
    }

    if (analytics.withoutResponsibleCount > 0) {
      recommendations.add(
        ExecutiveRecommendationData(
          id: 'assign_responsibles',
          title: 'Definir responsáveis',
          message:
              'Existem ações abertas sem um responsável claramente definido.',
          recommendedAction:
              'Designar um responsável e confirmar o prazo de cada pendência.',
          priority: ExecutiveRecommendationPriority.high,
          category: 'Responsabilidade',
          confidence: 0.92,
        ),
      );
    }

    if (analytics.topResponsibleOpenCount >= 5) {
      recommendations.add(
        ExecutiveRecommendationData(
          id: 'redistribute_workload',
          title: 'Redistribuir a carga de trabalho',
          message:
              '${analytics.topResponsible} concentra uma quantidade elevada de ações abertas.',
          recommendedAction:
              'Avaliar a transferência de parte das atividades para outros responsáveis.',
          priority: ExecutiveRecommendationPriority.high,
          category: 'Equipe',
          confidence: 0.88,
        ),
      );
    }

    if (analytics.completionRate < 0.40 && analytics.openCount > 0) {
      recommendations.add(
        const ExecutiveRecommendationData(
          id: 'accelerate_execution',
          title: 'Acelerar a execução do plano',
          message:
              'A taxa de conclusão ainda está baixa em relação ao volume de ações.',
          recommendedAction:
              'Selecionar as cinco ações de maior impacto e acompanhar a execução semanalmente.',
          priority: ExecutiveRecommendationPriority.high,
          category: 'Execução',
          confidence: 0.90,
        ),
      );
    }

    if (analytics.completionRate >= 0.75 && analytics.overdueCount == 0) {
      recommendations.add(
        const ExecutiveRecommendationData(
          id: 'maintain_performance',
          title: 'Manter o ritmo de execução',
          message: 'O plano apresenta bom avanço e não possui ações atrasadas.',
          recommendedAction:
              'Manter a revisão periódica e registrar os resultados alcançados.',
          priority: ExecutiveRecommendationPriority.low,
          category: 'Desempenho',
          confidence: 0.93,
        ),
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const ExecutiveRecommendationData(
          id: 'weekly_review',
          title: 'Realizar revisão semanal',
          message: 'O plano está em evolução e requer acompanhamento contínuo.',
          recommendedAction:
              'Revisar o Kanban, atualizar prazos e confirmar responsáveis uma vez por semana.',
          priority: ExecutiveRecommendationPriority.medium,
          category: 'Gestão',
          confidence: 0.82,
        ),
      );
    }

    recommendations.sort((first, second) {
      return _recommendationPriorityWeight(
        second.priority,
      ).compareTo(_recommendationPriorityWeight(first.priority));
    });

    return recommendations;
  }

  List<ExecutiveRankingItem> _buildResponsibleRanking(
    _ExecutiveDashboardAnalytics analytics,
  ) {
    final items =
        analytics.responsibleStats.entries.map((entry) {
          final value = entry.value;

          final performance = value.totalCount == 0
              ? 0.0
              : value.completedCount / value.totalCount;

          return ExecutiveRankingItem(
            position: 0,
            label: entry.key,
            value: value.openCount.toDouble(),
            secondaryValue: value.completedCount.toDouble(),
            percentage: performance,
            status: _rankingStatus(performance, value.overdueCount),
          );
        }).toList()..sort((first, second) {
          final performanceComparison = second.percentage.compareTo(
            first.percentage,
          );

          if (performanceComparison != 0) {
            return performanceComparison;
          }

          return first.value.compareTo(second.value);
        });

    return List.generate(items.length > 10 ? 10 : items.length, (index) {
      final item = items[index];

      return ExecutiveRankingItem(
        position: index + 1,
        label: item.label,
        value: item.value,
        secondaryValue: item.secondaryValue,
        percentage: item.percentage,
        status: item.status,
      );
    });
  }

  List<ExecutiveRankingItem> _buildFarmRanking(
    _ExecutiveDashboardAnalytics analytics,
  ) {
    final items =
        analytics.farmStats.entries.map((entry) {
          final value = entry.value;

          final performance = value.totalCount == 0
              ? 0.0
              : value.completedCount / value.totalCount;

          return ExecutiveRankingItem(
            position: 0,
            label: entry.key,
            value: value.openCount.toDouble(),
            secondaryValue: value.completedCount.toDouble(),
            percentage: performance,
            status: _rankingStatus(performance, value.overdueCount),
          );
        }).toList()..sort((first, second) {
          final performanceComparison = second.percentage.compareTo(
            first.percentage,
          );

          if (performanceComparison != 0) {
            return performanceComparison;
          }

          return first.value.compareTo(second.value);
        });

    return List.generate(items.length > 10 ? 10 : items.length, (index) {
      final item = items[index];

      return ExecutiveRankingItem(
        position: index + 1,
        label: item.label,
        value: item.value,
        secondaryValue: item.secondaryValue,
        percentage: item.percentage,
        status: item.status,
      );
    });
  }

  List<ExecutiveRankingItem> _buildPriorityRanking(
    _ExecutiveDashboardAnalytics analytics,
  ) {
    final entries = analytics.priorityCounts.entries.toList()
      ..sort((first, second) {
        return second.value.compareTo(first.value);
      });

    final total = analytics.totalCount;

    return List.generate(entries.length, (index) {
      final entry = entries[index];

      return ExecutiveRankingItem(
        position: index + 1,
        label: entry.key,
        value: entry.value.toDouble(),
        secondaryValue: 0,
        percentage: total == 0 ? 0 : entry.value / total,
        status: _priorityStatus(entry.key),
      );
    });
  }

  List<ExecutiveDistributionItemData> _buildStatusDistribution(
    _ExecutiveDashboardAnalytics analytics,
  ) {
    final entries = [
      MapEntry('Pendente', analytics.pendingCount),
      MapEntry('Em andamento', analytics.inProgressCount),
      MapEntry('Concluída', analytics.completedCount),
      MapEntry('Cancelada', analytics.cancelledCount),
    ];

    return entries.map((entry) {
      return ExecutiveDistributionItemData(
        label: entry.key,
        value: entry.value.toDouble(),
        percentage: analytics.totalCount == 0
            ? 0
            : entry.value / analytics.totalCount,
        category: 'Status',
        status: _statusIndicator(entry.key),
      );
    }).toList();
  }

  List<ExecutiveEvolutionPoint> _buildMonthlyEvolution({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    required DateTime now,
  }) {
    final points = <ExecutiveEvolutionPoint>[];

    for (var offset = 11; offset >= 0; offset--) {
      final month = DateTime(now.year, now.month - offset, 1);

      final nextMonth = DateTime(month.year, month.month + 1, 1);

      final createdCount = actions.where((action) {
        final date = tryParseExecutiveDate(action.createdAt);

        return date != null &&
            !date.isBefore(month) &&
            date.isBefore(nextMonth);
      }).length;

      final completedCount = _countCompletionsInRange(
        actions: actions,
        historyByActionId: historyByActionId,
        start: month,
        end: nextMonth,
      );

      final overdueCount = actions.where((action) {
        final deadline = tryParseExecutiveDate(action.deadline);

        return deadline != null &&
            deadline.isBefore(nextMonth) &&
            action.isOpen;
      }).length;

      final considered = createdCount + completedCount;

      points.add(
        ExecutiveEvolutionPoint(
          date: '${month.year}-${month.month.toString().padLeft(2, '0')}',
          label: executiveMonthLabel(month.month),
          createdCount: createdCount,
          completedCount: completedCount,
          overdueCount: overdueCount,
          completionRate: considered == 0 ? 0 : completedCount / considered,
        ),
      );
    }

    return points;
  }

  List<ExecutiveEvolutionPoint> _buildWeeklyEvolution({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    required DateTime now,
  }) {
    final currentMonday = startOfExecutiveWeek(now);

    final points = <ExecutiveEvolutionPoint>[];

    for (var offset = 7; offset >= 0; offset--) {
      final start = currentMonday.subtract(Duration(days: offset * 7));

      final end = start.add(const Duration(days: 7));

      final createdCount = actions.where((action) {
        final date = tryParseExecutiveDate(action.createdAt);

        return date != null && !date.isBefore(start) && date.isBefore(end);
      }).length;

      final completedCount = _countCompletionsInRange(
        actions: actions,
        historyByActionId: historyByActionId,
        start: start,
        end: end,
      );

      final overdueCount = actions.where((action) {
        final deadline = tryParseExecutiveDate(action.deadline);

        return deadline != null &&
            !deadline.isBefore(start) &&
            deadline.isBefore(end) &&
            action.isOpen;
      }).length;

      final considered = createdCount + completedCount;

      points.add(
        ExecutiveEvolutionPoint(
          date: formatExecutiveDate(start),
          label:
              '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}',
          createdCount: createdCount,
          completedCount: completedCount,
          overdueCount: overdueCount,
          completionRate: considered == 0 ? 0 : completedCount / considered,
        ),
      );
    }

    return points;
  }

  ExecutiveTrendData _buildProductivityTrend({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    required DateTime now,
  }) {
    final currentStart = now.subtract(const Duration(days: 30));

    final previousStart = currentStart.subtract(const Duration(days: 30));

    final currentCompleted = _countCompletionsInRange(
      actions: actions,
      historyByActionId: historyByActionId,
      start: currentStart,
      end: now.add(const Duration(days: 1)),
    );

    final previousCompleted = _countCompletionsInRange(
      actions: actions,
      historyByActionId: historyByActionId,
      start: previousStart,
      end: currentStart,
    );

    return _buildTrend(
      currentValue: currentCompleted.toDouble(),
      previousValue: previousCompleted.toDouble(),
      label: 'Produtividade',
      increasingIsPositive: true,
    );
  }

  ExecutiveTrendData _buildDelayTrend({
    required List<ReportActionItemData> actions,
    required DateTime now,
  }) {
    final currentStart = now.subtract(const Duration(days: 30));

    final previousStart = currentStart.subtract(const Duration(days: 30));

    final currentOverdue = actions.where((action) {
      final deadline = tryParseExecutiveDate(action.deadline);

      return deadline != null &&
          !deadline.isBefore(currentStart) &&
          deadline.isBefore(now.add(const Duration(days: 1))) &&
          action.isOverdue;
    }).length;

    final previousOverdue = actions.where((action) {
      final deadline = tryParseExecutiveDate(action.deadline);

      return deadline != null &&
          !deadline.isBefore(previousStart) &&
          deadline.isBefore(currentStart);
    }).length;

    return _buildTrend(
      currentValue: currentOverdue.toDouble(),
      previousValue: previousOverdue.toDouble(),
      label: 'Atrasos',
      increasingIsPositive: false,
    );
  }

  ExecutiveTrendData _buildTrend({
    required double currentValue,
    required double previousValue,
    required String label,
    required bool increasingIsPositive,
  }) {
    if (previousValue == 0 && currentValue == 0) {
      return ExecutiveTrendData(
        direction: ExecutiveTrendDirection.stable,
        percentage: 0,
        currentValue: currentValue,
        previousValue: previousValue,
        label: label,
        interpretation: 'Sem variação no período.',
      );
    }

    final percentage = previousValue == 0
        ? 1.0
        : (currentValue - previousValue) / previousValue;

    final direction = percentage > 0.05
        ? ExecutiveTrendDirection.increasing
        : percentage < -0.05
        ? ExecutiveTrendDirection.decreasing
        : ExecutiveTrendDirection.stable;

    String interpretation;

    if (direction == ExecutiveTrendDirection.stable) {
      interpretation = '$label permaneceu estável.';
    } else if (direction == ExecutiveTrendDirection.increasing) {
      interpretation = increasingIsPositive
          ? '$label apresentou melhora.'
          : '$label aumentou e exige atenção.';
    } else {
      interpretation = increasingIsPositive
          ? '$label apresentou redução.'
          : '$label apresentou melhora.';
    }

    return ExecutiveTrendData(
      direction: direction,
      percentage: percentage,
      currentValue: currentValue,
      previousValue: previousValue,
      label: label,
      interpretation: interpretation,
    );
  }

  int _countCompletionsInRange({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    required DateTime start,
    required DateTime end,
  }) {
    var count = 0;

    for (final action in actions) {
      final completedDate = tryParseExecutiveDate(action.completedAt);

      if (completedDate != null &&
          !completedDate.isBefore(start) &&
          completedDate.isBefore(end)) {
        count++;
        continue;
      }

      final history = historyByActionId[action.id] ?? const [];

      final completionFound = history.any((item) {
        if (!item.isCompletion) {
          return false;
        }

        final date = tryParseReportActionHistoryDateTime(item.createdAt);

        return date != null && !date.isBefore(start) && date.isBefore(end);
      });

      if (completionFound) {
        count++;
      }
    }

    return count;
  }

  double _calculatePerformanceIndex(_ExecutiveDashboardAnalytics analytics) {
    final completionScore = analytics.completionRate * 45;

    final delayScore = (1 - analytics.overdueRate).clamp(0.0, 1.0) * 25;

    final responsibilityScore = analytics.openCount == 0
        ? 15
        : (1 - analytics.withoutResponsibleCount / analytics.openCount).clamp(
                0.0,
                1.0,
              ) *
              15;

    final urgencyScore = analytics.openCount == 0
        ? 15
        : (1 - analytics.urgentCount / analytics.openCount).clamp(0.0, 1.0) *
              15;

    return (completionScore + delayScore + responsibilityScore + urgencyScore)
        .clamp(0.0, 100.0);
  }

  ExecutiveIndicatorStatus _completionStatus(double rate) {
    if (rate >= 0.75) {
      return ExecutiveIndicatorStatus.positive;
    }

    if (rate >= 0.40) {
      return ExecutiveIndicatorStatus.normal;
    }

    if (rate > 0) {
      return ExecutiveIndicatorStatus.attention;
    }

    return ExecutiveIndicatorStatus.critical;
  }

  ExecutiveIndicatorStatus _overdueStatus(double rate) {
    if (rate == 0) {
      return ExecutiveIndicatorStatus.positive;
    }

    if (rate < 0.10) {
      return ExecutiveIndicatorStatus.normal;
    }

    if (rate < 0.25) {
      return ExecutiveIndicatorStatus.attention;
    }

    return ExecutiveIndicatorStatus.critical;
  }

  ExecutiveIndicatorStatus _performanceStatus(double score) {
    if (score >= 80) {
      return ExecutiveIndicatorStatus.positive;
    }

    if (score >= 60) {
      return ExecutiveIndicatorStatus.normal;
    }

    if (score >= 40) {
      return ExecutiveIndicatorStatus.attention;
    }

    return ExecutiveIndicatorStatus.critical;
  }

  ExecutiveIndicatorStatus _rankingStatus(
    double completionRate,
    int overdueCount,
  ) {
    if (overdueCount > 0 && completionRate < 0.50) {
      return ExecutiveIndicatorStatus.critical;
    }

    if (completionRate >= 0.75) {
      return ExecutiveIndicatorStatus.positive;
    }

    if (completionRate >= 0.40) {
      return ExecutiveIndicatorStatus.normal;
    }

    return ExecutiveIndicatorStatus.attention;
  }

  ExecutiveIndicatorStatus _priorityStatus(String priority) {
    switch (priority) {
      case 'Muito alta':
      case 'Urgente':
        return ExecutiveIndicatorStatus.critical;
      case 'Alta':
        return ExecutiveIndicatorStatus.attention;
      case 'Média':
      case 'Normal':
        return ExecutiveIndicatorStatus.normal;
      default:
        return ExecutiveIndicatorStatus.positive;
    }
  }

  ExecutiveIndicatorStatus _statusIndicator(String status) {
    switch (status) {
      case 'Concluída':
        return ExecutiveIndicatorStatus.positive;
      case 'Em andamento':
        return ExecutiveIndicatorStatus.normal;
      case 'Pendente':
        return ExecutiveIndicatorStatus.attention;
      case 'Cancelada':
        return ExecutiveIndicatorStatus.normal;
      default:
        return ExecutiveIndicatorStatus.normal;
    }
  }

  int _alertSeverityWeight(ExecutiveAlertSeverity severity) {
    switch (severity) {
      case ExecutiveAlertSeverity.critical:
        return 3;
      case ExecutiveAlertSeverity.warning:
        return 2;
      case ExecutiveAlertSeverity.information:
        return 1;
    }
  }

  int _recommendationPriorityWeight(ExecutiveRecommendationPriority priority) {
    switch (priority) {
      case ExecutiveRecommendationPriority.critical:
        return 4;
      case ExecutiveRecommendationPriority.high:
        return 3;
      case ExecutiveRecommendationPriority.medium:
        return 2;
      case ExecutiveRecommendationPriority.low:
        return 1;
    }
  }
}

class _ExecutiveDashboardAnalytics {
  const _ExecutiveDashboardAnalytics({
    required this.totalCount,
    required this.openCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.overdueCount,
    required this.urgentCount,
    required this.withoutResponsibleCount,
    required this.dueTodayCount,
    required this.completionRate,
    required this.overdueRate,
    required this.averageCompletionDays,
    required this.topResponsible,
    required this.topResponsibleOpenCount,
    required this.responsibleStats,
    required this.farmStats,
    required this.priorityCounts,
    required this.createdChange,
    required this.completedChange,
    required this.overdueChange,
    required this.completionRateChange,
    required this.overdueRateChange,
  });

  factory _ExecutiveDashboardAnalytics.fromData({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    required DateTime now,
  }) {
    final openActions = actions.where((action) {
      return action.isOpen;
    }).toList();

    final considered = actions.where((action) {
      return !action.isCancelled;
    }).toList();

    final completed = actions.where((action) {
      return action.isCompleted;
    }).toList();

    final overdue = actions.where((action) {
      return action.isOverdue;
    }).toList();

    final urgent = actions.where((action) {
      return action.isUrgent && action.isOpen;
    }).toList();

    final withoutResponsible = openActions.where((action) {
      return action.responsible.trim().isEmpty;
    }).length;

    final today = DateTime(now.year, now.month, now.day);

    final dueToday = openActions.where((action) {
      final deadline = tryParseExecutiveDate(action.deadline);

      if (deadline == null) {
        return false;
      }

      return deadline.year == today.year &&
          deadline.month == today.month &&
          deadline.day == today.day;
    }).length;

    final completionDays = <int>[];

    for (final action in completed) {
      final created = tryParseExecutiveDate(action.createdAt);

      final completedAt = tryParseExecutiveDate(action.completedAt);

      if (created != null && completedAt != null) {
        completionDays.add(completedAt.difference(created).inDays.abs());
        continue;
      }

      final history = historyByActionId[action.id] ?? const [];

      final creationEvents = history.where((item) {
        return item.isCreation;
      }).toList()..sort(compareReportActionHistory);

      final completionEvents = history.where((item) {
        return item.isCompletion;
      }).toList()..sort(compareReportActionHistory);

      if (creationEvents.isNotEmpty && completionEvents.isNotEmpty) {
        final start = tryParseReportActionHistoryDateTime(
          creationEvents.last.createdAt,
        );

        final end = tryParseReportActionHistoryDateTime(
          completionEvents.first.createdAt,
        );

        if (start != null && end != null) {
          completionDays.add(end.difference(start).inDays.abs());
        }
      }
    }

    final responsibleStats = <String, _ExecutiveGroupStats>{};

    final farmStats = <String, _ExecutiveGroupStats>{};

    final priorityCounts = <String, int>{};

    for (final action in actions) {
      final responsible = action.responsible.trim();

      if (responsible.isNotEmpty) {
        responsibleStats.update(
          responsible,
          (value) => value.addAction(action),
          ifAbsent: () => _ExecutiveGroupStats.fromAction(action),
        );
      }

      final farm = action.farmName.trim().isEmpty
          ? 'Todas as fazendas'
          : action.farmName.trim();

      farmStats.update(
        farm,
        (value) => value.addAction(action),
        ifAbsent: () => _ExecutiveGroupStats.fromAction(action),
      );

      priorityCounts.update(
        action.priority,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    String topResponsible = 'Não definido';

    var topResponsibleOpenCount = 0;

    for (final entry in responsibleStats.entries) {
      if (entry.value.openCount > topResponsibleOpenCount) {
        topResponsible = entry.key;
        topResponsibleOpenCount = entry.value.openCount;
      }
    }

    final currentPeriodStart = now.subtract(const Duration(days: 30));

    final previousPeriodStart = currentPeriodStart.subtract(
      const Duration(days: 30),
    );

    final createdCurrent = actions.where((action) {
      final date = tryParseExecutiveDate(action.createdAt);

      return date != null && !date.isBefore(currentPeriodStart);
    }).length;

    final createdPrevious = actions.where((action) {
      final date = tryParseExecutiveDate(action.createdAt);

      return date != null &&
          !date.isBefore(previousPeriodStart) &&
          date.isBefore(currentPeriodStart);
    }).length;

    final completedCurrent = completed.where((action) {
      final date = tryParseExecutiveDate(action.completedAt);

      return date != null && !date.isBefore(currentPeriodStart);
    }).length;

    final completedPrevious = completed.where((action) {
      final date = tryParseExecutiveDate(action.completedAt);

      return date != null &&
          !date.isBefore(previousPeriodStart) &&
          date.isBefore(currentPeriodStart);
    }).length;

    final overdueCurrent = overdue.where((action) {
      final deadline = tryParseExecutiveDate(action.deadline);

      return deadline != null && !deadline.isBefore(currentPeriodStart);
    }).length;

    final overduePrevious = actions.where((action) {
      final deadline = tryParseExecutiveDate(action.deadline);

      return deadline != null &&
          !deadline.isBefore(previousPeriodStart) &&
          deadline.isBefore(currentPeriodStart);
    }).length;

    final currentCompletionRate = considered.isEmpty
        ? 0.0
        : completed.length / considered.length;

    final previousConsidered = actions.where((action) {
      final created = tryParseExecutiveDate(action.createdAt);

      return created != null &&
          created.isBefore(currentPeriodStart) &&
          !action.isCancelled;
    }).toList();

    final previousCompleted = previousConsidered.where((action) {
      final completedAt = tryParseExecutiveDate(action.completedAt);

      return completedAt != null && completedAt.isBefore(currentPeriodStart);
    }).length;

    final previousCompletionRate = previousConsidered.isEmpty
        ? 0.0
        : previousCompleted / previousConsidered.length;

    final currentOverdueRate = considered.isEmpty
        ? 0.0
        : overdue.length / considered.length;

    final previousOverdueRate = previousConsidered.isEmpty
        ? 0.0
        : overduePrevious / previousConsidered.length;

    return _ExecutiveDashboardAnalytics(
      totalCount: actions.length,
      openCount: openActions.length,
      pendingCount: actions.where((action) {
        return action.isPending;
      }).length,
      inProgressCount: actions.where((action) {
        return action.isInProgress;
      }).length,
      completedCount: completed.length,
      cancelledCount: actions.where((action) {
        return action.isCancelled;
      }).length,
      overdueCount: overdue.length,
      urgentCount: urgent.length,
      withoutResponsibleCount: withoutResponsible,
      dueTodayCount: dueToday,
      completionRate: currentCompletionRate,
      overdueRate: currentOverdueRate,
      averageCompletionDays: completionDays.isEmpty
          ? null
          : completionDays.reduce((first, second) => first + second) /
                completionDays.length,
      topResponsible: topResponsible,
      topResponsibleOpenCount: topResponsibleOpenCount,
      responsibleStats: responsibleStats,
      farmStats: farmStats,
      priorityCounts: priorityCounts,
      createdChange: calculateExecutiveChange(
        current: createdCurrent.toDouble(),
        previous: createdPrevious.toDouble(),
      ),
      completedChange: calculateExecutiveChange(
        current: completedCurrent.toDouble(),
        previous: completedPrevious.toDouble(),
      ),
      overdueChange: calculateExecutiveChange(
        current: overdueCurrent.toDouble(),
        previous: overduePrevious.toDouble(),
      ),
      completionRateChange: currentCompletionRate - previousCompletionRate,
      overdueRateChange: currentOverdueRate - previousOverdueRate,
    );
  }

  final int totalCount;
  final int openCount;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final int cancelledCount;
  final int overdueCount;
  final int urgentCount;
  final int withoutResponsibleCount;
  final int dueTodayCount;

  final double completionRate;
  final double overdueRate;
  final double? averageCompletionDays;

  final String topResponsible;
  final int topResponsibleOpenCount;

  final Map<String, _ExecutiveGroupStats> responsibleStats;

  final Map<String, _ExecutiveGroupStats> farmStats;

  final Map<String, int> priorityCounts;

  final double createdChange;
  final double completedChange;
  final double overdueChange;
  final double completionRateChange;
  final double overdueRateChange;

  String get averageCompletionDaysLabel {
    final value = averageCompletionDays;

    if (value == null) {
      return 'Sem dados';
    }

    if (value < 1) {
      return 'Menos de 1 dia';
    }

    if (value == 1) {
      return '1 dia';
    }

    return '${value.toStringAsFixed(1).replaceAll('.', ',')} dias';
  }
}

class _ExecutiveGroupStats {
  const _ExecutiveGroupStats({
    required this.totalCount,
    required this.openCount,
    required this.completedCount,
    required this.overdueCount,
  });

  factory _ExecutiveGroupStats.fromAction(ReportActionItemData action) {
    return _ExecutiveGroupStats(
      totalCount: 1,
      openCount: action.isOpen ? 1 : 0,
      completedCount: action.isCompleted ? 1 : 0,
      overdueCount: action.isOverdue ? 1 : 0,
    );
  }

  final int totalCount;
  final int openCount;
  final int completedCount;
  final int overdueCount;

  _ExecutiveGroupStats addAction(ReportActionItemData action) {
    return _ExecutiveGroupStats(
      totalCount: totalCount + 1,
      openCount: openCount + (action.isOpen ? 1 : 0),
      completedCount: completedCount + (action.isCompleted ? 1 : 0),
      overdueCount: overdueCount + (action.isOverdue ? 1 : 0),
    );
  }
}

DateTime startOfExecutiveWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);

  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

DateTime? tryParseExecutiveDate(String value) {
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

String formatExecutiveDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String formatExecutiveDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '${formatExecutiveDate(date)} '
      '$hour:$minute';
}

String formatExecutivePercentage(double value) {
  return '${(value * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
}

String executiveMonthLabel(int month) {
  const labels = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  if (month < 1 || month > 12) {
    return '';
  }

  return labels[month - 1];
}

double calculateExecutiveChange({
  required double current,
  required double previous,
}) {
  if (previous == 0) {
    if (current == 0) {
      return 0;
    }

    return 1;
  }

  return (current - previous) / previous;
}
