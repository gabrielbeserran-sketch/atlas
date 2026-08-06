import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';

class DecisionScenarioSimulator {
  const DecisionScenarioSimulator();

  DecisionScenarioResult simulate({
    required ExecutiveDecisionData currentData,
    required Set<String> completedActionIds,
    String scenarioName = 'Cenário simulado',
  }) {
    final selectedActions = currentData.priorityActions.where((action) {
      return completedActionIds.contains(action.actionId);
    }).toList();

    final remainingActions = currentData.priorityActions.where((action) {
      return !completedActionIds.contains(action.actionId);
    }).toList();

    final currentSummary = currentData.summary;

    final removedCriticalCount = selectedActions.where((action) {
      return action.priorityLevel == ExecutiveDecisionLevel.critical;
    }).length;

    final removedPredictedDelayCount = selectedActions.where((action) {
      return action.delayProbability >= 0.70;
    }).length;

    final resolvedRisk = selectedActions.fold<double>(
      0,
      (sum, action) => sum + action.riskScore,
    );

    final resolvedPriority = selectedActions.fold<double>(
      0,
      (sum, action) => sum + action.priorityScore,
    );

    final capturedOpportunity = selectedActions.fold<double>(
      0,
      (sum, action) => sum + action.opportunityScore,
    );

    final capturedImpact = selectedActions.fold<double>(
      0,
      (sum, action) => sum + action.estimatedImpact,
    );

    final remainingAverageRisk = _average(
      remainingActions.map((action) {
        return action.riskScore;
      }),
    );

    final remainingAveragePriority = _average(
      remainingActions.map((action) {
        return action.priorityScore;
      }),
    );

    final remainingAverageOpportunity = _average(
      remainingActions.map((action) {
        return action.opportunityScore;
      }),
    );

    final estimatedConsultantGain = _calculateConsultantScoreGain(
      selectedActions: selectedActions,
      currentData: currentData,
    );

    final projectedConsultantScore =
        (currentData.consultantScore.value + estimatedConsultantGain).clamp(
          0.0,
          100.0,
        );

    final projectedCriticalCount =
        (currentSummary.criticalActionCount - removedCriticalCount).clamp(
          0,
          999,
        );

    final projectedPredictedDelayCount =
        (currentSummary.predictedDelayCount - removedPredictedDelayCount).clamp(
          0,
          999,
        );

    final projectedAverageRisk = remainingActions.isEmpty
        ? 0.0
        : remainingAverageRisk;

    final riskReduction =
        (currentSummary.averageRiskScore - projectedAverageRisk).clamp(
          0.0,
          100.0,
        );

    final performanceGain = _calculatePerformanceGain(
      selectedActions: selectedActions,
      capturedImpact: capturedImpact,
      capturedOpportunity: capturedOpportunity,
      removedCriticalCount: removedCriticalCount,
      removedPredictedDelayCount: removedPredictedDelayCount,
    );

    final projectedPerformanceIndex =
        _estimateCurrentPerformanceIndex(currentData) + performanceGain;

    final recommendation = _buildScenarioRecommendation(
      selectedActions: selectedActions,
      removedCriticalCount: removedCriticalCount,
      removedPredictedDelayCount: removedPredictedDelayCount,
      riskReduction: riskReduction,
      consultantGain: estimatedConsultantGain,
      performanceGain: performanceGain,
    );

    return DecisionScenarioResult(
      scenarioName: scenarioName,
      generatedAt: DateTime.now(),
      selectedActionIds: completedActionIds.toList(),
      selectedActions: selectedActions,
      currentConsultantScore: currentData.consultantScore.value,
      projectedConsultantScore: projectedConsultantScore,
      consultantScoreGain: estimatedConsultantGain,
      currentPerformanceIndex: _estimateCurrentPerformanceIndex(currentData),
      projectedPerformanceIndex: projectedPerformanceIndex.clamp(0.0, 100.0),
      performanceIndexGain: performanceGain,
      currentCriticalCount: currentSummary.criticalActionCount,
      projectedCriticalCount: projectedCriticalCount,
      removedCriticalCount: removedCriticalCount,
      currentPredictedDelayCount: currentSummary.predictedDelayCount,
      projectedPredictedDelayCount: projectedPredictedDelayCount,
      removedPredictedDelayCount: removedPredictedDelayCount,
      currentAverageRisk: currentSummary.averageRiskScore,
      projectedAverageRisk: projectedAverageRisk,
      riskReduction: riskReduction,
      remainingAveragePriority: remainingAveragePriority,
      remainingAverageOpportunity: remainingAverageOpportunity,
      resolvedRisk: resolvedRisk,
      resolvedPriority: resolvedPriority,
      capturedOpportunity: capturedOpportunity,
      capturedImpact: capturedImpact,
      recommendation: recommendation,
      level: _scenarioLevel(
        performanceGain: performanceGain,
        riskReduction: riskReduction,
        removedCriticalCount: removedCriticalCount,
      ),
    );
  }

  List<DecisionScenarioCombination> findBestCombinations({
    required ExecutiveDecisionData currentData,
    int maximumActions = 5,
    int resultLimit = 10,
  }) {
    final candidates = currentData.priorityActions.take(12).toList();

    if (candidates.isEmpty || maximumActions <= 0 || resultLimit <= 0) {
      return [];
    }

    final combinations = <DecisionScenarioCombination>[];

    final safeMaximum = maximumActions.clamp(1, candidates.length);

    for (var size = 1; size <= safeMaximum; size++) {
      final generated = _generateCombinations(candidates, size);

      for (final combination in generated) {
        final ids = combination.map((action) {
          return action.actionId;
        }).toSet();

        final result = simulate(
          currentData: currentData,
          completedActionIds: ids,
          scenarioName: 'Conclusão de $size ${size == 1 ? 'ação' : 'ações'}',
        );

        final efficiency = _calculateCombinationEfficiency(result);

        combinations.add(
          DecisionScenarioCombination(
            actionIds: ids.toList(),
            actionTitles: combination.map((action) {
              return action.title;
            }).toList(),
            actionCount: size,
            projectedConsultantScore: result.projectedConsultantScore,
            consultantScoreGain: result.consultantScoreGain,
            performanceIndexGain: result.performanceIndexGain,
            riskReduction: result.riskReduction,
            removedCriticalCount: result.removedCriticalCount,
            removedPredictedDelayCount: result.removedPredictedDelayCount,
            capturedImpact: result.capturedImpact,
            efficiencyScore: efficiency,
          ),
        );
      }
    }

    combinations.sort((first, second) {
      final efficiencyComparison = second.efficiencyScore.compareTo(
        first.efficiencyScore,
      );

      if (efficiencyComparison != 0) {
        return efficiencyComparison;
      }

      final impactComparison = second.capturedImpact.compareTo(
        first.capturedImpact,
      );

      if (impactComparison != 0) {
        return impactComparison;
      }

      return first.actionCount.compareTo(second.actionCount);
    });

    return combinations.take(resultLimit).toList();
  }

  DecisionScenarioResult simulateTopActions({
    required ExecutiveDecisionData currentData,
    int actionCount = 3,
  }) {
    final selected = currentData.priorityActions
        .take(actionCount.clamp(0, currentData.priorityActions.length))
        .map((action) {
          return action.actionId;
        })
        .toSet();

    return simulate(
      currentData: currentData,
      completedActionIds: selected,
      scenarioName: 'Conclusão das $actionCount principais ações',
    );
  }

  double _calculateConsultantScoreGain({
    required List<ExecutivePriorityAction> selectedActions,
    required ExecutiveDecisionData currentData,
  }) {
    if (selectedActions.isEmpty) {
      return 0;
    }

    final criticalCount = selectedActions.where((action) {
      return action.priorityLevel == ExecutiveDecisionLevel.critical;
    }).length;

    final overdueRiskCount = selectedActions.where((action) {
      return action.delayProbability >= 0.70;
    }).length;

    final averageImpact = _average(
      selectedActions.map((action) {
        return action.estimatedImpact;
      }),
    );

    final averageRisk = _average(
      selectedActions.map((action) {
        return action.riskScore;
      }),
    );

    var gain =
        selectedActions.length * 0.65 +
        criticalCount * 1.15 +
        overdueRiskCount * 0.75 +
        averageImpact / 100 * 2.2 +
        averageRisk / 100 * 1.6;

    final currentScore = currentData.consultantScore.value;

    final remainingCapacity = (100 - currentScore).clamp(0.0, 100.0);

    gain = gain.clamp(0.0, remainingCapacity);

    return gain;
  }

  double _calculatePerformanceGain({
    required List<ExecutivePriorityAction> selectedActions,
    required double capturedImpact,
    required double capturedOpportunity,
    required int removedCriticalCount,
    required int removedPredictedDelayCount,
  }) {
    if (selectedActions.isEmpty) {
      return 0;
    }

    final averageImpact = capturedImpact / selectedActions.length;

    final averageOpportunity = capturedOpportunity / selectedActions.length;

    final gain =
        selectedActions.length * 0.55 +
        averageImpact / 100 * 2.4 +
        averageOpportunity / 100 * 1.8 +
        removedCriticalCount * 0.95 +
        removedPredictedDelayCount * 0.55;

    return gain.clamp(0.0, 15.0);
  }

  double _estimateCurrentPerformanceIndex(ExecutiveDecisionData currentData) {
    final consultantScore = currentData.consultantScore.value;

    final riskPenalty = currentData.summary.averageRiskScore * 0.18;

    final criticalPenalty = currentData.summary.criticalActionCount * 1.4;

    final delayPenalty = currentData.summary.predictedDelayCount * 0.8;

    return (consultantScore - riskPenalty - criticalPenalty - delayPenalty)
        .clamp(0.0, 100.0);
  }

  String _buildScenarioRecommendation({
    required List<ExecutivePriorityAction> selectedActions,
    required int removedCriticalCount,
    required int removedPredictedDelayCount,
    required double riskReduction,
    required double consultantGain,
    required double performanceGain,
  }) {
    if (selectedActions.isEmpty) {
      return 'Selecione uma ou mais ações para simular o impacto na operação.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A conclusão de ${selectedActions.length} '
      '${selectedActions.length == 1 ? 'ação selecionada' : 'ações selecionadas'} ',
    );

    if (removedCriticalCount > 0) {
      buffer.write(
        'pode retirar $removedCriticalCount '
        '${removedCriticalCount == 1 ? 'prioridade crítica' : 'prioridades críticas'} da fila, ',
      );
    }

    if (removedPredictedDelayCount > 0) {
      buffer.write(
        'reduzir $removedPredictedDelayCount '
        '${removedPredictedDelayCount == 1 ? 'atraso previsto' : 'atrasos previstos'}, ',
      );
    }

    buffer.write(
      'diminuir o risco médio em aproximadamente '
      '${riskReduction.toStringAsFixed(1).replaceAll('.', ',')} pontos ',
    );

    buffer.write(
      'e elevar o score do consultor em cerca de '
      '${consultantGain.toStringAsFixed(1).replaceAll('.', ',')} pontos. ',
    );

    buffer.write(
      'O ganho estimado no desempenho geral é de '
      '${performanceGain.toStringAsFixed(1).replaceAll('.', ',')} pontos.',
    );

    return buffer.toString();
  }

  ExecutiveDecisionLevel _scenarioLevel({
    required double performanceGain,
    required double riskReduction,
    required int removedCriticalCount,
  }) {
    final score =
        performanceGain * 4 + riskReduction * 2 + removedCriticalCount * 12;

    if (score >= 70) {
      return ExecutiveDecisionLevel.excellent;
    }

    if (score >= 50) {
      return ExecutiveDecisionLevel.good;
    }

    if (score >= 30) {
      return ExecutiveDecisionLevel.normal;
    }

    if (score >= 15) {
      return ExecutiveDecisionLevel.attention;
    }

    return ExecutiveDecisionLevel.critical;
  }

  double _calculateCombinationEfficiency(DecisionScenarioResult result) {
    if (result.selectedActions.isEmpty) {
      return 0;
    }

    final benefit =
        result.performanceIndexGain * 3.0 +
        result.consultantScoreGain * 2.0 +
        result.riskReduction * 1.8 +
        result.removedCriticalCount * 8.0 +
        result.removedPredictedDelayCount * 4.0 +
        result.capturedImpact * 0.25;

    final effort = result.selectedActions.length * 10.0;

    return (benefit / effort * 100).clamp(0.0, 100.0);
  }

  List<List<ExecutivePriorityAction>> _generateCombinations(
    List<ExecutivePriorityAction> source,
    int size,
  ) {
    final result = <List<ExecutivePriorityAction>>[];

    void generate(int start, List<ExecutivePriorityAction> current) {
      if (current.length == size) {
        result.add(List<ExecutivePriorityAction>.from(current));
        return;
      }

      final remaining = size - current.length;

      for (var index = start; index <= source.length - remaining; index++) {
        current.add(source[index]);

        generate(index + 1, current);

        current.removeLast();
      }
    }

    generate(0, <ExecutivePriorityAction>[]);

    return result;
  }

  double _average(Iterable<double> values) {
    final list = values.toList();

    if (list.isEmpty) {
      return 0;
    }

    return list.reduce((first, second) => first + second) / list.length;
  }
}

class DecisionScenarioResult {
  const DecisionScenarioResult({
    required this.scenarioName,
    required this.generatedAt,
    required this.selectedActionIds,
    required this.selectedActions,
    required this.currentConsultantScore,
    required this.projectedConsultantScore,
    required this.consultantScoreGain,
    required this.currentPerformanceIndex,
    required this.projectedPerformanceIndex,
    required this.performanceIndexGain,
    required this.currentCriticalCount,
    required this.projectedCriticalCount,
    required this.removedCriticalCount,
    required this.currentPredictedDelayCount,
    required this.projectedPredictedDelayCount,
    required this.removedPredictedDelayCount,
    required this.currentAverageRisk,
    required this.projectedAverageRisk,
    required this.riskReduction,
    required this.remainingAveragePriority,
    required this.remainingAverageOpportunity,
    required this.resolvedRisk,
    required this.resolvedPriority,
    required this.capturedOpportunity,
    required this.capturedImpact,
    required this.recommendation,
    required this.level,
  });

  final String scenarioName;
  final DateTime generatedAt;

  final List<String> selectedActionIds;

  final List<ExecutivePriorityAction> selectedActions;

  final double currentConsultantScore;
  final double projectedConsultantScore;
  final double consultantScoreGain;

  final double currentPerformanceIndex;
  final double projectedPerformanceIndex;
  final double performanceIndexGain;

  final int currentCriticalCount;
  final int projectedCriticalCount;
  final int removedCriticalCount;

  final int currentPredictedDelayCount;
  final int projectedPredictedDelayCount;
  final int removedPredictedDelayCount;

  final double currentAverageRisk;
  final double projectedAverageRisk;
  final double riskReduction;

  final double remainingAveragePriority;
  final double remainingAverageOpportunity;

  final double resolvedRisk;
  final double resolvedPriority;
  final double capturedOpportunity;
  final double capturedImpact;

  final String recommendation;

  final ExecutiveDecisionLevel level;

  bool get hasSelection {
    return selectedActions.isNotEmpty;
  }

  bool get improvesConsultantScore {
    return consultantScoreGain > 0;
  }

  bool get reducesRisk {
    return riskReduction > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'scenarioName': scenarioName,
      'generatedAt': generatedAt.toIso8601String(),
      'selectedActionIds': selectedActionIds,
      'selectedActions': selectedActions.map((action) {
        return action.toJson();
      }).toList(),
      'currentConsultantScore': currentConsultantScore,
      'projectedConsultantScore': projectedConsultantScore,
      'consultantScoreGain': consultantScoreGain,
      'currentPerformanceIndex': currentPerformanceIndex,
      'projectedPerformanceIndex': projectedPerformanceIndex,
      'performanceIndexGain': performanceIndexGain,
      'currentCriticalCount': currentCriticalCount,
      'projectedCriticalCount': projectedCriticalCount,
      'removedCriticalCount': removedCriticalCount,
      'currentPredictedDelayCount': currentPredictedDelayCount,
      'projectedPredictedDelayCount': projectedPredictedDelayCount,
      'removedPredictedDelayCount': removedPredictedDelayCount,
      'currentAverageRisk': currentAverageRisk,
      'projectedAverageRisk': projectedAverageRisk,
      'riskReduction': riskReduction,
      'remainingAveragePriority': remainingAveragePriority,
      'remainingAverageOpportunity': remainingAverageOpportunity,
      'resolvedRisk': resolvedRisk,
      'resolvedPriority': resolvedPriority,
      'capturedOpportunity': capturedOpportunity,
      'capturedImpact': capturedImpact,
      'recommendation': recommendation,
      'level': level.name,
    };
  }
}

class DecisionScenarioCombination {
  const DecisionScenarioCombination({
    required this.actionIds,
    required this.actionTitles,
    required this.actionCount,
    required this.projectedConsultantScore,
    required this.consultantScoreGain,
    required this.performanceIndexGain,
    required this.riskReduction,
    required this.removedCriticalCount,
    required this.removedPredictedDelayCount,
    required this.capturedImpact,
    required this.efficiencyScore,
  });

  final List<String> actionIds;
  final List<String> actionTitles;

  final int actionCount;

  final double projectedConsultantScore;
  final double consultantScoreGain;
  final double performanceIndexGain;
  final double riskReduction;

  final int removedCriticalCount;
  final int removedPredictedDelayCount;

  final double capturedImpact;
  final double efficiencyScore;

  Map<String, dynamic> toJson() {
    return {
      'actionIds': actionIds,
      'actionTitles': actionTitles,
      'actionCount': actionCount,
      'projectedConsultantScore': projectedConsultantScore,
      'consultantScoreGain': consultantScoreGain,
      'performanceIndexGain': performanceIndexGain,
      'riskReduction': riskReduction,
      'removedCriticalCount': removedCriticalCount,
      'removedPredictedDelayCount': removedPredictedDelayCount,
      'capturedImpact': capturedImpact,
      'efficiencyScore': efficiencyScore,
    };
  }
}
