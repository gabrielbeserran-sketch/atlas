import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_score_engine.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class DecisionHeatMapEngine {
  const DecisionHeatMapEngine();

  List<ExecutiveHeatMapItem> buildHeatMap({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    final items = <ExecutiveHeatMapItem>[];

    items.addAll(
      _buildFarmHeatMap(actions: actions, scoresByActionId: scoresByActionId),
    );

    items.addAll(
      _buildResponsibleHeatMap(
        actions: actions,
        scoresByActionId: scoresByActionId,
      ),
    );

    items.addAll(
      _buildCategoryHeatMap(
        actions: actions,
        scoresByActionId: scoresByActionId,
      ),
    );

    items.sort((first, second) {
      final levelComparison = _levelWeight(
        second.level,
      ).compareTo(_levelWeight(first.level));

      if (levelComparison != 0) {
        return levelComparison;
      }

      return second.score.compareTo(first.score);
    });

    return items;
  }

  List<ExecutiveDecisionRankingItem> buildFarmRiskRanking({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    return _buildRanking(
      group: 'Fazenda',
      heatMapItems: _buildFarmHeatMap(
        actions: actions,
        scoresByActionId: scoresByActionId,
      ),
    );
  }

  List<ExecutiveDecisionRankingItem> buildResponsibleRiskRanking({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    return _buildRanking(
      group: 'Responsável',
      heatMapItems: _buildResponsibleHeatMap(
        actions: actions,
        scoresByActionId: scoresByActionId,
      ),
    );
  }

  List<ExecutiveDecisionRankingItem> buildCategoryRiskRanking({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    return _buildRanking(
      group: 'Categoria',
      heatMapItems: _buildCategoryHeatMap(
        actions: actions,
        scoresByActionId: scoresByActionId,
      ),
    );
  }

  List<ExecutiveHeatMapItem> _buildFarmHeatMap({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    final groups = <String, List<_HeatMapActionData>>{};

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      final score = scoresByActionId[action.id];

      if (score == null) {
        continue;
      }

      final farm = action.farmName.trim().isEmpty
          ? 'Todas as fazendas'
          : action.farmName.trim();

      groups
          .putIfAbsent(farm, () => [])
          .add(_HeatMapActionData(action: action, score: score));
    }

    return groups.entries.map((entry) {
      final metrics = _calculateGroupMetrics(entry.value);

      return ExecutiveHeatMapItem(
        id: 'farm_${_normalizeId(entry.key)}',
        label: entry.key,
        group: 'Fazenda',
        score: metrics.heatScore,
        level: decisionLevelFromScore(metrics.heatScore),
        openCount: metrics.openCount,
        overdueCount: metrics.overdueCount,
        urgentCount: metrics.urgentCount,
        summary: _buildSummary(
          label: entry.key,
          group: 'fazenda',
          metrics: metrics,
        ),
      );
    }).toList();
  }

  List<ExecutiveHeatMapItem> _buildResponsibleHeatMap({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    final groups = <String, List<_HeatMapActionData>>{};

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      final score = scoresByActionId[action.id];

      if (score == null) {
        continue;
      }

      final responsible = action.responsible.trim().isEmpty
          ? 'Sem responsável'
          : action.responsible.trim();

      groups
          .putIfAbsent(responsible, () => [])
          .add(_HeatMapActionData(action: action, score: score));
    }

    return groups.entries.map((entry) {
      final metrics = _calculateGroupMetrics(entry.value);

      var heatScore = metrics.heatScore;

      if (entry.key == 'Sem responsável') {
        heatScore += 12;
      }

      heatScore = clampDecisionScore(heatScore);

      return ExecutiveHeatMapItem(
        id: 'responsible_${_normalizeId(entry.key)}',
        label: entry.key,
        group: 'Responsável',
        score: heatScore,
        level: decisionLevelFromScore(heatScore),
        openCount: metrics.openCount,
        overdueCount: metrics.overdueCount,
        urgentCount: metrics.urgentCount,
        summary: _buildSummary(
          label: entry.key,
          group: 'responsável',
          metrics: metrics,
        ),
      );
    }).toList();
  }

  List<ExecutiveHeatMapItem> _buildCategoryHeatMap({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    final groups = <String, List<_HeatMapActionData>>{};

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      final score = scoresByActionId[action.id];

      if (score == null) {
        continue;
      }

      final category = decisionActionCategory(action);

      groups
          .putIfAbsent(category, () => [])
          .add(_HeatMapActionData(action: action, score: score));
    }

    return groups.entries.map((entry) {
      final metrics = _calculateGroupMetrics(entry.value);

      final recurrenceBonus = (metrics.openCount / 8 * 12).clamp(0.0, 12.0);

      final heatScore = clampDecisionScore(metrics.heatScore + recurrenceBonus);

      return ExecutiveHeatMapItem(
        id: 'category_${_normalizeId(entry.key)}',
        label: entry.key,
        group: 'Categoria',
        score: heatScore,
        level: decisionLevelFromScore(heatScore),
        openCount: metrics.openCount,
        overdueCount: metrics.overdueCount,
        urgentCount: metrics.urgentCount,
        summary: _buildSummary(
          label: entry.key,
          group: 'categoria',
          metrics: metrics,
        ),
      );
    }).toList();
  }

  List<ExecutiveDecisionRankingItem> _buildRanking({
    required String group,
    required List<ExecutiveHeatMapItem> heatMapItems,
  }) {
    final ordered = List<ExecutiveHeatMapItem>.from(heatMapItems)
      ..sort((first, second) => second.score.compareTo(first.score));

    return List.generate(ordered.length, (index) {
      final item = ordered[index];

      return ExecutiveDecisionRankingItem(
        position: index + 1,
        label: item.label,
        riskScore: item.score,
        opportunityScore: _rankingOpportunityScore(item),
        openCount: item.openCount,
        overdueCount: item.overdueCount,
        urgentCount: item.urgentCount,
        level: item.level,
        explanation: '${item.summary} Grupo analisado: $group.',
      );
    });
  }

  _HeatMapMetrics _calculateGroupMetrics(List<_HeatMapActionData> data) {
    if (data.isEmpty) {
      return const _HeatMapMetrics(
        openCount: 0,
        overdueCount: 0,
        urgentCount: 0,
        highDelayCount: 0,
        averageRisk: 0,
        averagePriority: 0,
        averageOpportunity: 0,
        averageDelayProbability: 0,
        heatScore: 0,
      );
    }

    final openCount = data.length;

    final overdueCount = data.where((item) {
      return item.action.isOverdue;
    }).length;

    final urgentCount = data.where((item) {
      return item.action.isUrgent;
    }).length;

    final highDelayCount = data.where((item) {
      return item.score.delayProbability >= 0.70;
    }).length;

    final averageRisk = _average(
      data.map((item) {
        return item.score.riskScore;
      }),
    );

    final averagePriority = _average(
      data.map((item) {
        return item.score.priorityScore;
      }),
    );

    final averageOpportunity = _average(
      data.map((item) {
        return item.score.opportunityScore;
      }),
    );

    final averageDelayProbability = _average(
      data.map((item) {
        return item.score.delayProbability * 100;
      }),
    );

    final overdueRate = overdueCount / openCount;

    final urgentRate = urgentCount / openCount;

    final highDelayRate = highDelayCount / openCount;

    final volumeScore = (openCount / 10 * 100).clamp(0.0, 100.0);

    final heatScore =
        averageRisk * 0.28 +
        averagePriority * 0.18 +
        averageDelayProbability * 0.18 +
        overdueRate * 100 * 0.16 +
        urgentRate * 100 * 0.10 +
        highDelayRate * 100 * 0.06 +
        volumeScore * 0.04;

    return _HeatMapMetrics(
      openCount: openCount,
      overdueCount: overdueCount,
      urgentCount: urgentCount,
      highDelayCount: highDelayCount,
      averageRisk: averageRisk,
      averagePriority: averagePriority,
      averageOpportunity: averageOpportunity,
      averageDelayProbability: averageDelayProbability,
      heatScore: clampDecisionScore(heatScore),
    );
  }

  String _buildSummary({
    required String label,
    required String group,
    required _HeatMapMetrics metrics,
  }) {
    final level = decisionLevelFromScore(metrics.heatScore);

    final buffer = StringBuffer();

    buffer.write(
      '$label apresenta nível '
      '${decisionLevelLabel(level).toLowerCase()} '
      'no mapa de calor da $group. ',
    );

    buffer.write(
      'São ${metrics.openCount} '
      '${metrics.openCount == 1 ? 'ação aberta' : 'ações abertas'}, ',
    );

    buffer.write(
      '${metrics.overdueCount} '
      '${metrics.overdueCount == 1 ? 'atrasada' : 'atrasadas'} e ',
    );

    buffer.write(
      '${metrics.urgentCount} '
      '${metrics.urgentCount == 1 ? 'urgente' : 'urgentes'}. ',
    );

    buffer.write(
      'O risco médio é de '
      '${metrics.averageRisk.toStringAsFixed(1).replaceAll('.', ',')} pontos',
    );

    if (metrics.highDelayCount > 0) {
      buffer.write(
        ' e ${metrics.highDelayCount} '
        '${metrics.highDelayCount == 1 ? 'ação possui' : 'ações possuem'} '
        'alta chance de atraso',
      );
    }

    buffer.write('.');

    return buffer.toString();
  }

  double _rankingOpportunityScore(ExecutiveHeatMapItem item) {
    final criticalityOpportunity = item.score * 0.45;

    final overdueOpportunity = item.openCount == 0
        ? 0.0
        : item.overdueCount / item.openCount * 100 * 0.30;

    final urgentOpportunity = item.openCount == 0
        ? 0.0
        : item.urgentCount / item.openCount * 100 * 0.25;

    return clampDecisionScore(
      criticalityOpportunity + overdueOpportunity + urgentOpportunity,
    );
  }

  double _average(Iterable<double> values) {
    final list = values.toList();

    if (list.isEmpty) {
      return 0;
    }

    return list.reduce((first, second) => first + second) / list.length;
  }

  int _levelWeight(ExecutiveDecisionLevel level) {
    switch (level) {
      case ExecutiveDecisionLevel.critical:
        return 5;

      case ExecutiveDecisionLevel.attention:
        return 4;

      case ExecutiveDecisionLevel.normal:
        return 3;

      case ExecutiveDecisionLevel.good:
        return 2;

      case ExecutiveDecisionLevel.excellent:
        return 1;
    }
  }

  String _normalizeId(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}

class _HeatMapActionData {
  const _HeatMapActionData({required this.action, required this.score});

  final ReportActionItemData action;
  final DecisionActionScore score;
}

class _HeatMapMetrics {
  const _HeatMapMetrics({
    required this.openCount,
    required this.overdueCount,
    required this.urgentCount,
    required this.highDelayCount,
    required this.averageRisk,
    required this.averagePriority,
    required this.averageOpportunity,
    required this.averageDelayProbability,
    required this.heatScore,
  });

  final int openCount;
  final int overdueCount;
  final int urgentCount;
  final int highDelayCount;

  final double averageRisk;
  final double averagePriority;
  final double averageOpportunity;
  final double averageDelayProbability;
  final double heatScore;
}

String decisionLevelLabel(ExecutiveDecisionLevel level) {
  switch (level) {
    case ExecutiveDecisionLevel.excellent:
      return 'Excelente';

    case ExecutiveDecisionLevel.good:
      return 'Bom';

    case ExecutiveDecisionLevel.normal:
      return 'Normal';

    case ExecutiveDecisionLevel.attention:
      return 'Atenção';

    case ExecutiveDecisionLevel.critical:
      return 'Crítico';
  }
}
