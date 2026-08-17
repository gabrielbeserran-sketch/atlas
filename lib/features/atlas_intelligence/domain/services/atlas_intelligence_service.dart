import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_intelligence/domain/models/atlas_intelligence_data.dart';
import 'package:projeto_atlas/features/atlas_os/domain/models/atlas_os_data.dart';

class AtlasIntelligenceService {
  const AtlasIntelligenceService();

  AtlasIntelligenceData build({required AtlasOsData atlasOs, DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    final signals = _buildSignals(atlasOs);

    final patterns = _buildPatterns(signals: signals, atlasOs: atlasOs);

    final hypotheses = _buildHypotheses(signals: signals, patterns: patterns);

    final recommendations = _buildRecommendations(
      signals: signals,
      patterns: patterns,
      hypotheses: hypotheses,
    );

    final score = _intelligenceScore(
      atlasOs: atlasOs,
      signals: signals,
      patterns: patterns,
    );

    final confidence = _confidence(
      signals: signals,
      patterns: patterns,
      hypotheses: hypotheses,
    );

    final status = _status(score: score, signals: signals);

    return AtlasIntelligenceData(
      generatedAt: currentTime,
      summary: _summary(
        signals: signals,
        patterns: patterns,
        hypotheses: hypotheses,
        recommendations: recommendations,
        score: score,
        confidence: confidence,
      ),
      intelligenceScore: score,
      confidencePercent: confidence,
      status: status,
      signals: signals,
      patterns: patterns,
      hypotheses: hypotheses,
      recommendations: recommendations,
    );
  }

  List<AtlasIntelligenceSignal> _buildSignals(AtlasOsData atlasOs) {
    final result = <AtlasIntelligenceSignal>[];

    for (final item in atlasOs.commands) {
      result.add(
        AtlasIntelligenceSignal(
          id: 'command_${item.id}',
          title: item.title,
          description: item.description,
          source: item.source,
          type: AtlasIntelligenceSignalType.operational,
          severity: _severityFromPriority(item.priority),
          relevanceScore:
              _priorityWeight(item.priority) * 20 +
              math.min(
                item.deadlineHours <= 0 ? 20 : 100 / item.deadlineHours,
                20,
              ),
          confidencePercent: 90,
          financialImpact: _moneyFromText(item.expectedImpact),
          farmName: item.farmName,
        ),
      );
    }

    for (final item in atlasOs.criticalItems) {
      result.add(
        AtlasIntelligenceSignal(
          id: 'critical_${item.id}',
          title: item.title,
          description: item.description,
          source: 'Atlas OS',
          type: AtlasIntelligenceSignalType.predictive,
          severity: _severityFromOs(item.severity),
          relevanceScore:
              item.probabilityPercent * 0.55 +
              _severityWeight(_severityFromOs(item.severity)) * 12 +
              math.min(item.expectedFinancialImpact / 1000, 18),
          confidencePercent: (100 - item.probabilityPercent * 0.10)
              .clamp(45.0, 95.0)
              .toDouble(),
          financialImpact: item.expectedFinancialImpact,
          farmName: item.farmName,
        ),
      );
    }

    for (final module in atlasOs.modules) {
      result.add(
        AtlasIntelligenceSignal(
          id: 'module_${module.id}',
          title: 'Saúde do módulo ${module.title}',
          description: module.description,
          source: 'Atlas OS',
          type: module.id == 'workflow'
              ? AtlasIntelligenceSignalType.execution
              : AtlasIntelligenceSignalType.strategic,
          severity: _severityFromModuleStatus(module.status),
          relevanceScore:
              (100 - module.score) * 0.65 +
              module.criticalItems * 8 +
              module.pendingItems * 1.5,
          confidencePercent: 96,
          financialImpact: 0,
          farmName: 'Operação',
        ),
      );
    }

    result.sort(
      (first, second) => second.relevanceScore.compareTo(first.relevanceScore),
    );

    return result.take(30).toList();
  }

  List<AtlasIntelligencePattern> _buildPatterns({
    required List<AtlasIntelligenceSignal> signals,
    required AtlasOsData atlasOs,
  }) {
    final result = <AtlasIntelligencePattern>[];

    final groupedByFarm = <String, List<AtlasIntelligenceSignal>>{};

    for (final signal in signals) {
      groupedByFarm.putIfAbsent(signal.farmName, () => []).add(signal);
    }

    for (final entry in groupedByFarm.entries) {
      final highSignals = entry.value.where((item) {
        return item.severity == AtlasIntelligenceSeverity.high ||
            item.severity == AtlasIntelligenceSeverity.critical;
      }).toList();

      if (highSignals.length >= 2) {
        result.add(
          AtlasIntelligencePattern(
            id: 'cascade_${entry.key}_${highSignals.length}',
            title: 'Concentração de riscos em ${entry.key}',
            description:
                '${highSignals.length} sinais de alta severidade estão relacionados à mesma operação.',
            type: AtlasIntelligencePatternType.cascading,
            strengthScore: math
                .min(100, 55 + highSignals.length * 10)
                .toDouble(),
            confidencePercent: 88,
            relatedSignalIds: highSignals.map((item) => item.id).toList(),
            expectedConsequence:
                'Os riscos podem se reforçar e gerar efeito em cadeia.',
          ),
        );
      }
    }

    final executionSignals = signals.where((item) {
      return item.type == AtlasIntelligenceSignalType.execution;
    }).toList();

    final operationalSignals = signals.where((item) {
      return item.type == AtlasIntelligenceSignalType.operational;
    }).toList();

    if (executionSignals.any((item) {
          return item.severity == AtlasIntelligenceSeverity.high ||
              item.severity == AtlasIntelligenceSeverity.critical;
        }) &&
        operationalSignals.length >= 3) {
      result.add(
        AtlasIntelligencePattern(
          id: 'execution_bottleneck',
          title: 'Gargalo entre decisão e execução',
          description:
              'Há muitas ações operacionais enquanto o módulo de execução apresenta sinais de atenção.',
          type: AtlasIntelligencePatternType.bottleneck,
          strengthScore: 82,
          confidencePercent: 92,
          relatedSignalIds: [
            ...executionSignals.map((item) => item.id),
            ...operationalSignals.take(4).map((item) => item.id),
          ],
          expectedConsequence:
              'As decisões podem permanecer abertas sem produzir resultado.',
        ),
      );
    }

    final positiveImpact = signals.fold<double>(
      0,
      (sum, item) => sum + math.max(item.financialImpact, 0),
    );

    if (positiveImpact > 50000) {
      result.add(
        AtlasIntelligencePattern(
          id: 'financial_opportunity',
          title: 'Oportunidade financeira concentrada',
          description:
              'O conjunto de sinais aponta potencial financeiro relevante nas ações atuais.',
          type: AtlasIntelligencePatternType.opportunity,
          strengthScore: math.min(100, positiveImpact / 1000).toDouble(),
          confidencePercent: 84,
          relatedSignalIds: signals
              .where((item) => item.financialImpact > 0)
              .take(8)
              .map((item) => item.id)
              .toList(),
          expectedConsequence:
              'A execução coordenada pode capturar impacto financeiro adicional.',
        ),
      );
    }

    if (atlasOs.executionPercent < 60 && atlasOs.goalProbabilityPercent >= 75) {
      result.add(
        AtlasIntelligencePattern(
          id: 'execution_goal_contradiction',
          title: 'Contradição entre metas e execução',
          description:
              'A probabilidade de atingir metas está alta, mas a execução prevista permanece baixa.',
          type: AtlasIntelligencePatternType.contradiction,
          strengthScore: 79,
          confidencePercent: 91,
          relatedSignalIds: executionSignals.map((item) => item.id).toList(),
          expectedConsequence:
              'As metas podem estar superestimadas ou dependentes de execução ainda não confirmada.',
        ),
      );
    }

    result.sort(
      (first, second) => second.strengthScore.compareTo(first.strengthScore),
    );

    return result;
  }

  List<AtlasIntelligenceHypothesis> _buildHypotheses({
    required List<AtlasIntelligenceSignal> signals,
    required List<AtlasIntelligencePattern> patterns,
  }) {
    final result = <AtlasIntelligenceHypothesis>[];

    for (final pattern in patterns) {
      switch (pattern.type) {
        case AtlasIntelligencePatternType.bottleneck:
          result.add(
            AtlasIntelligenceHypothesis(
              id: 'hypothesis_${pattern.id}',
              title: 'Capacidade de execução insuficiente',
              description:
                  'O volume de ações pode estar acima da capacidade atual da equipe.',
              cause:
                  'Excesso de tarefas, dependências ou responsáveis indefinidos.',
              effect:
                  'Atrasos, perda de impacto e redução da confiança nas decisões.',
              probabilityPercent: pattern.confidencePercent,
              impactScore: pattern.strengthScore,
              validationSteps: const [
                'Revisar tarefas atrasadas.',
                'Confirmar responsáveis.',
                'Verificar dependências bloqueadas.',
                'Comparar capacidade da equipe com o volume de ações.',
              ],
            ),
          );

        case AtlasIntelligencePatternType.cascading:
          result.add(
            AtlasIntelligenceHypothesis(
              id: 'hypothesis_${pattern.id}',
              title: 'Riscos com causa comum',
              description:
                  'Os sinais podem estar sendo provocados pelo mesmo fator operacional.',
              cause: 'Uma restrição compartilhada entre os indicadores.',
              effect: pattern.expectedConsequence,
              probabilityPercent: pattern.confidencePercent,
              impactScore: pattern.strengthScore,
              validationSteps: const [
                'Validar os dados em campo.',
                'Identificar recursos compartilhados.',
                'Revisar eventos recentes.',
                'Testar a principal causa em pequena escala.',
              ],
            ),
          );

        case AtlasIntelligencePatternType.contradiction:
          result.add(
            AtlasIntelligenceHypothesis(
              id: 'hypothesis_${pattern.id}',
              title: 'Premissas de planejamento desalinhadas',
              description: pattern.description,
              cause:
                  'Metas e previsões podem estar usando premissas diferentes da execução real.',
              effect: pattern.expectedConsequence,
              probabilityPercent: pattern.confidencePercent,
              impactScore: pattern.strengthScore,
              validationSteps: const [
                'Revisar as premissas das metas.',
                'Atualizar o progresso real.',
                'Recalcular a probabilidade de execução.',
              ],
            ),
          );

        case AtlasIntelligencePatternType.opportunity:
          result.add(
            AtlasIntelligenceHypothesis(
              id: 'hypothesis_${pattern.id}',
              title: 'Potencial de ganho ainda não capturado',
              description: pattern.description,
              cause:
                  'Ações financeiras relevantes ainda não foram executadas ou coordenadas.',
              effect: pattern.expectedConsequence,
              probabilityPercent: pattern.confidencePercent,
              impactScore: pattern.strengthScore,
              validationSteps: const [
                'Confirmar investimentos necessários.',
                'Comparar retorno e risco.',
                'Priorizar ações de maior ROI.',
              ],
            ),
          );

        case AtlasIntelligencePatternType.recurring:
          break;
      }
    }

    if (result.isEmpty && signals.isNotEmpty) {
      final top = signals.first;

      result.add(
        AtlasIntelligenceHypothesis(
          id: 'hypothesis_primary_signal',
          title: 'Sinal principal exige validação',
          description: top.description,
          cause: 'O principal fator ainda não foi confirmado.',
          effect:
              'A recomendação pode perder precisão sem validação operacional.',
          probabilityPercent: top.confidencePercent,
          impactScore: top.relevanceScore,
          validationSteps: const [
            'Confirmar dados.',
            'Validar causa em campo.',
            'Registrar resultado.',
          ],
        ),
      );
    }

    return result.take(10).toList();
  }

  List<AtlasIntelligenceRecommendation> _buildRecommendations({
    required List<AtlasIntelligenceSignal> signals,
    required List<AtlasIntelligencePattern> patterns,
    required List<AtlasIntelligenceHypothesis> hypotheses,
  }) {
    final candidates = <_RecommendationCandidate>[];

    for (final hypothesis in hypotheses) {
      candidates.add(
        _RecommendationCandidate(
          id: 'recommendation_${hypothesis.id}',
          title: hypothesis.title,
          description: hypothesis.description,
          farmName: _farmFromHypothesis(
            hypothesis: hypothesis,
            signals: signals,
            patterns: patterns,
          ),
          score:
              hypothesis.impactScore * 0.55 +
              hypothesis.probabilityPercent * 0.45,
          confidencePercent: hypothesis.probabilityPercent,
          expectedFinancialImpact: _impactFromHypothesis(
            hypothesis: hypothesis,
            signals: signals,
            patterns: patterns,
          ),
          deadlineHours: hypothesis.impactScore >= 80 ? 8 : 24,
          reasoning: '${hypothesis.cause} ${hypothesis.effect}',
          actions: hypothesis.validationSteps,
        ),
      );
    }

    for (final signal in signals.take(8)) {
      candidates.add(
        _RecommendationCandidate(
          id: 'recommendation_signal_${signal.id}',
          title: signal.title,
          description: signal.description,
          farmName: signal.farmName,
          score: signal.relevanceScore * 0.60 + signal.confidencePercent * 0.40,
          confidencePercent: signal.confidencePercent,
          expectedFinancialImpact: signal.financialImpact,
          deadlineHours: signal.severity == AtlasIntelligenceSeverity.critical
              ? 4
              : signal.severity == AtlasIntelligenceSeverity.high
              ? 12
              : 48,
          reasoning: 'O sinal possui alta relevância e pode afetar a operação.',
          actions: const [
            'Validar o sinal.',
            'Definir responsável.',
            'Executar intervenção.',
            'Medir resultado.',
          ],
        ),
      );
    }

    candidates.sort((first, second) => second.score.compareTo(first.score));

    final selected = candidates.take(15).toList();

    return List.generate(selected.length, (index) {
      final item = selected[index];
      final score = item.score.clamp(0.0, 100.0);

      return AtlasIntelligenceRecommendation(
        position: index + 1,
        id: item.id,
        title: item.title,
        description: item.description,
        farmName: item.farmName,
        priority: _priorityFromScore(score),
        confidencePercent: item.confidencePercent,
        expectedFinancialImpact: item.expectedFinancialImpact,
        deadlineHours: item.deadlineHours,
        reasoning: item.reasoning,
        actions: item.actions,
      );
    });
  }

  double _intelligenceScore({
    required AtlasOsData atlasOs,
    required List<AtlasIntelligenceSignal> signals,
    required List<AtlasIntelligencePattern> patterns,
  }) {
    final severeSignals = signals.where((item) {
      return item.severity == AtlasIntelligenceSeverity.high ||
          item.severity == AtlasIntelligenceSeverity.critical;
    }).length;

    final patternPenalty = patterns.fold<double>(
      0,
      (sum, item) => sum + item.strengthScore * 0.05,
    );

    return (atlasOs.healthScore - severeSignals * 3 - patternPenalty)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _confidence({
    required List<AtlasIntelligenceSignal> signals,
    required List<AtlasIntelligencePattern> patterns,
    required List<AtlasIntelligenceHypothesis> hypotheses,
  }) {
    final values = <double>[
      ...signals.map((item) => item.confidencePercent),
      ...patterns.map((item) => item.confidencePercent),
      ...hypotheses.map((item) => item.probabilityPercent),
    ];

    if (values.isEmpty) {
      return 0;
    }

    return (values.fold<double>(0, (sum, value) => sum + value) / values.length)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasIntelligenceStatus _status({
    required double score,
    required List<AtlasIntelligenceSignal> signals,
  }) {
    final criticalCount = signals.where((item) {
      return item.severity == AtlasIntelligenceSeverity.critical;
    }).length;

    if (criticalCount >= 3 || score < 35) {
      return AtlasIntelligenceStatus.critical;
    }

    if (criticalCount > 0 || score < 55) {
      return AtlasIntelligenceStatus.highRisk;
    }

    if (score < 75) {
      return AtlasIntelligenceStatus.attention;
    }

    return AtlasIntelligenceStatus.stable;
  }

  AtlasIntelligenceSeverity _severityFromPriority(AtlasOsPriority priority) {
    switch (priority) {
      case AtlasOsPriority.low:
        return AtlasIntelligenceSeverity.low;

      case AtlasOsPriority.medium:
        return AtlasIntelligenceSeverity.medium;

      case AtlasOsPriority.high:
        return AtlasIntelligenceSeverity.high;

      case AtlasOsPriority.critical:
        return AtlasIntelligenceSeverity.critical;
    }
  }

  AtlasIntelligenceSeverity _severityFromOs(AtlasOsSeverity severity) {
    switch (severity) {
      case AtlasOsSeverity.low:
        return AtlasIntelligenceSeverity.low;

      case AtlasOsSeverity.medium:
        return AtlasIntelligenceSeverity.medium;

      case AtlasOsSeverity.high:
        return AtlasIntelligenceSeverity.high;

      case AtlasOsSeverity.critical:
        return AtlasIntelligenceSeverity.critical;
    }
  }

  AtlasIntelligenceSeverity _severityFromModuleStatus(
    AtlasOsModuleStatus status,
  ) {
    switch (status) {
      case AtlasOsModuleStatus.active:
        return AtlasIntelligenceSeverity.low;

      case AtlasOsModuleStatus.attention:
        return AtlasIntelligenceSeverity.medium;

      case AtlasOsModuleStatus.critical:
        return AtlasIntelligenceSeverity.critical;

      case AtlasOsModuleStatus.unavailable:
        return AtlasIntelligenceSeverity.high;
    }
  }

  int _priorityWeight(AtlasOsPriority priority) {
    switch (priority) {
      case AtlasOsPriority.low:
        return 1;

      case AtlasOsPriority.medium:
        return 2;

      case AtlasOsPriority.high:
        return 3;

      case AtlasOsPriority.critical:
        return 4;
    }
  }

  int _severityWeight(AtlasIntelligenceSeverity severity) {
    switch (severity) {
      case AtlasIntelligenceSeverity.low:
        return 1;

      case AtlasIntelligenceSeverity.medium:
        return 2;

      case AtlasIntelligenceSeverity.high:
        return 3;

      case AtlasIntelligenceSeverity.critical:
        return 4;
    }
  }

  AtlasIntelligencePriority _priorityFromScore(double score) {
    if (score >= 85) {
      return AtlasIntelligencePriority.critical;
    }

    if (score >= 70) {
      return AtlasIntelligencePriority.high;
    }

    if (score >= 50) {
      return AtlasIntelligencePriority.medium;
    }

    return AtlasIntelligencePriority.low;
  }

  double _moneyFromText(String value) {
    final match = RegExp(r'R\$\s*([0-9.,]+)').firstMatch(value);

    if (match == null) {
      return 0;
    }

    final raw = match.group(1);

    if (raw == null || raw.isEmpty) {
      return 0;
    }

    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(normalized) ?? 0;
  }

  String _farmFromHypothesis({
    required AtlasIntelligenceHypothesis hypothesis,
    required List<AtlasIntelligenceSignal> signals,
    required List<AtlasIntelligencePattern> patterns,
  }) {
    final pattern = patterns.cast<AtlasIntelligencePattern?>().firstWhere(
      (item) => item?.id == hypothesis.id.replaceFirst('hypothesis_', ''),
      orElse: () => null,
    );

    if (pattern != null) {
      for (final signalId in pattern.relatedSignalIds) {
        final signal = signals.cast<AtlasIntelligenceSignal?>().firstWhere(
          (item) => item?.id == signalId,
          orElse: () => null,
        );

        if (signal != null && signal.farmName != 'Operação') {
          return signal.farmName;
        }
      }
    }

    return 'Operação';
  }

  double _impactFromHypothesis({
    required AtlasIntelligenceHypothesis hypothesis,
    required List<AtlasIntelligenceSignal> signals,
    required List<AtlasIntelligencePattern> patterns,
  }) {
    final pattern = patterns.cast<AtlasIntelligencePattern?>().firstWhere(
      (item) => item?.id == hypothesis.id.replaceFirst('hypothesis_', ''),
      orElse: () => null,
    );

    if (pattern == null) {
      return 0;
    }

    return signals
        .where((item) => pattern.relatedSignalIds.contains(item.id))
        .fold<double>(
          0,
          (sum, item) => sum + math.max(item.financialImpact, 0),
        );
  }

  String _summary({
    required List<AtlasIntelligenceSignal> signals,
    required List<AtlasIntelligencePattern> patterns,
    required List<AtlasIntelligenceHypothesis> hypotheses,
    required List<AtlasIntelligenceRecommendation> recommendations,
    required double score,
    required double confidence,
  }) {
    return 'O Atlas Intelligence Engine consolidou '
        '${signals.length} sinais, identificou '
        '${patterns.length} padrões, gerou '
        '${hypotheses.length} hipóteses e '
        '${recommendations.length} recomendações, '
        'com score de ${score.toStringAsFixed(0)}/100 '
        'e ${confidence.toStringAsFixed(0)}% de confiança.';
  }
}

class _RecommendationCandidate {
  const _RecommendationCandidate({
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.score,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineHours,
    required this.reasoning,
    required this.actions,
  });

  final String id;
  final String title;
  final String description;
  final String farmName;

  final double score;
  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineHours;

  final String reasoning;
  final List<String> actions;
}
