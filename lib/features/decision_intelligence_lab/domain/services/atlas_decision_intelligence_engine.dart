import 'dart:math' as math;

import 'package:projeto_atlas/features/decision_intelligence_lab/domain/models/atlas_decision_scenario.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/domain/models/atlas_intelligent_recommendation.dart';

class AtlasDecisionIntelligenceEngine {
  const AtlasDecisionIntelligenceEngine();

  AtlasDecisionComparison compare({
    required AtlasFarmAudit audit,
    required AtlasRecommendationPortfolio recommendations,
    required List<AtlasDecisionScenarioInput> scenarios,
  }) {
    final results = scenarios
        .map(
          (scenario) => simulate(
            audit: audit,
            recommendations: recommendations,
            scenario: scenario,
          ),
        )
        .toList();

    return AtlasDecisionComparison(
      farmId: audit.farmId,
      farmName: audit.farmName,
      generatedAt: DateTime.now(),
      results: results,
    );
  }

  AtlasDecisionScenarioResult simulate({
    required AtlasFarmAudit audit,
    required AtlasRecommendationPortfolio recommendations,
    required AtlasDecisionScenarioInput scenario,
  }) {
    final areaResult = audit.areaResults
        .where((item) => item.area == scenario.area)
        .cast<AtlasFarmAuditAreaResult?>()
        .firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    final recommendation = recommendations.recommendations
        .where((item) => item.area == scenario.area)
        .cast<AtlasIntelligentRecommendation?>()
        .firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    final currentScore = areaResult?.score ?? audit.overallIndex;
    final monthlyNetGain =
        scenario.monthlyRevenueGain - scenario.monthlyCostChange;
    final grossGain = monthlyNetGain * scenario.horizonMonths;
    final expectedNetGain = grossGain - scenario.investment;

    final roi = scenario.investment <= 0
        ? monthlyNetGain > 0
            ? 100
            : 0
        : expectedNetGain / scenario.investment * 100;

    final payback = monthlyNetGain <= 0
        ? 999
        : scenario.investment / monthlyNetGain;

    final evidenceConfidence =
        recommendation?.confidence ?? 55;
    final historicSuccess =
        recommendation?.successRate ?? 68;

    final readinessFactor =
        scenario.executionReadiness.clamp(0.0, 100.0);
    final complexityPenalty =
        scenario.operationalComplexity.clamp(0.0, 100.0);

    final successProbability = (
      historicSuccess * 0.45 +
      evidenceConfidence * 0.25 +
      readinessFactor * 0.30 -
      complexityPenalty * 0.18
    ).clamp(5.0, 98.0).toDouble();

    final confidence = (
      evidenceConfidence * 0.60 +
      readinessFactor * 0.25 +
      (100 - complexityPenalty) * 0.15
    ).clamp(35.0, 98.0).toDouble();

    final riskScore = (
      complexityPenalty * 0.35 +
      (100 - readinessFactor) * 0.35 +
      (100 - successProbability) * 0.30
    ).clamp(0.0, 100.0).toDouble();

    final risk = _risk(riskScore);

    final projectedGain = (
      successProbability / 100 *
      (recommendation?.expectedScoreGain ?? 12)
    ).clamp(0.0, 30.0).toDouble();

    final projectedAreaScore =
        math.min(100, currentScore + projectedGain).toDouble();

    final expectedResultMonths = math.max(
      1,
      math.min(
        scenario.horizonMonths,
        ((recommendation?.averageResponseDays ?? 90) / 30)
            .ceil(),
      ),
    );

    final roiScore =
        ((roi + 20) / 2).clamp(0.0, 100.0).toDouble();
    final paybackScore = payback >= 999
        ? 0.0
        : (100 - payback * 5)
            .clamp(0.0, 100.0)
            .toDouble();

    final strategicScore = (
      roiScore * 0.25 +
      paybackScore * 0.15 +
      successProbability * 0.25 +
      confidence * 0.20 +
      (100 - riskScore) * 0.15
    ).clamp(0.0, 100.0).toDouble();

    return AtlasDecisionScenarioResult(
      id:
          'decision_${scenario.id}_${DateTime.now().microsecondsSinceEpoch}',
      farmId: audit.farmId,
      farmName: audit.farmName,
      generatedAt: DateTime.now(),
      input: scenario,
      expectedNetGain: expectedNetGain,
      roiPercent: roi.toDouble(),
      paybackMonths: payback.toDouble(),
      successProbability: successProbability,
      confidence: confidence,
      risk: risk,
      score: strategicScore,
      currentAreaScore: currentScore,
      projectedAreaScore: projectedAreaScore,
      expectedResultMonths: expectedResultMonths,
      advantages: _advantages(
        scenario: scenario,
        roi: roi.toDouble(),
        payback: payback.toDouble(),
        recommendation: recommendation,
      ),
      risks: _risks(
        scenario: scenario,
        risk: risk,
        monthlyNetGain: monthlyNetGain,
      ),
      implementationPlan: _implementationPlan(
        scenario.area,
      ),
      explanation: _explanation(
        scenario: scenario,
        recommendation: recommendation,
        confidence: confidence,
      ),
    );
  }

  AtlasDecisionRisk _risk(double value) {
    if (value < 25) {
      return AtlasDecisionRisk.low;
    }

    if (value < 50) {
      return AtlasDecisionRisk.moderate;
    }

    if (value < 75) {
      return AtlasDecisionRisk.high;
    }

    return AtlasDecisionRisk.critical;
  }

  List<String> _advantages({
    required AtlasDecisionScenarioInput scenario,
    required double roi,
    required double payback,
    required AtlasIntelligentRecommendation? recommendation,
  }) {
    return <String>[
      if (roi > 0)
        'Potencial de ROI de ${roi.toStringAsFixed(1)}% no horizonte analisado.',
      if (payback < 999)
        'Retorno estimado do investimento em ${payback.toStringAsFixed(1)} meses.',
      'Impacto direto na área de ${atlasFarmAuditAreaLabel(scenario.area)}.',
      if (recommendation != null)
        'Cenário alinhado a uma recomendação do Atlas com ${recommendation.confidence.toStringAsFixed(1)}% de confiança.',
    ];
  }

  List<String> _risks({
    required AtlasDecisionScenarioInput scenario,
    required AtlasDecisionRisk risk,
    required double monthlyNetGain,
  }) {
    return <String>[
      if (monthlyNetGain <= 0)
        'O cenário não apresenta ganho mensal líquido positivo.',
      if (scenario.operationalComplexity >= 70)
        'A complexidade operacional pode atrasar ou reduzir o resultado.',
      if (scenario.executionReadiness < 60)
        'A prontidão atual da equipe e da estrutura é insuficiente.',
      'Risco geral classificado como ${atlasDecisionRiskLabel(risk)}.',
      'Os valores são projeções e precisam ser confirmados pela execução real.',
    ];
  }

  List<String> _implementationPlan(
    AtlasFarmAuditArea area,
  ) {
    return <String>[
      'Validar premissas, orçamento e responsável pelo cenário.',
      'Definir indicadores de linha de base para ${atlasFarmAuditAreaLabel(area)}.',
      'Executar primeiro em escala controlada ou lote piloto.',
      'Revisar os resultados após 30 dias.',
      'Expandir, corrigir ou interromper com base nos indicadores.',
    ];
  }

  String _explanation({
    required AtlasDecisionScenarioInput scenario,
    required AtlasIntelligentRecommendation? recommendation,
    required double confidence,
  }) {
    if (recommendation == null) {
      return 'A simulação utilizou os dados da auditoria e as premissas financeiras informadas. Ainda não há recomendação histórica específica para esta área.';
    }

    return 'A simulação combinou as premissas do cenário com ${recommendation.similarCases} caso(s) semelhante(s), taxa histórica de sucesso de ${recommendation.successRate.toStringAsFixed(1)}% e confiança final de ${confidence.toStringAsFixed(1)}%.';
  }
}
