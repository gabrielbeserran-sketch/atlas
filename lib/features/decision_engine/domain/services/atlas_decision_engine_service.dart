import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_benchmark.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_forecast.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/models/atlas_bi_analytics_data.dart';
import 'package:projeto_atlas/features/decision_engine/domain/models/atlas_decision_engine_data.dart';
import 'package:projeto_atlas/features/executive_ai_advisor/domain/models/atlas_executive_ai_advisor_data.dart';
import 'package:projeto_atlas/features/executive_intelligence/domain/models/atlas_executive_intelligence_data.dart';

class AtlasDecisionEngineService {
  const AtlasDecisionEngineService();

  AtlasDecisionEngineData build({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    required AtlasExecutiveIntelligenceData intelligence,
    required AtlasExecutiveAiAdvisorData advisor,
    DateTime? now,
  }) {
    final candidates = <_DecisionCandidate>[];

    candidates.addAll(_fromAdvisor(advisor, bi));

    candidates.addAll(_fromIntelligence(intelligence, bi));

    candidates.addAll(_fromAnalytics(analytics, bi));

    candidates.addAll(_fromForecast(forecast, bi));

    candidates.addAll(_fromBenchmark(benchmark, bi));

    final merged = _mergeCandidates(candidates)
      ..sort((first, second) => second.score.compareTo(first.score));

    final decisions = List.generate(math.min(merged.length, 15), (index) {
      final item = merged[index];

      return AtlasDecisionRecommendation(
        position: index + 1,
        id: item.id,
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        priority: _priorityFromScore(item.score),
        urgency: _urgencyFromCandidate(item),
        risk: item.risk,
        confidencePercent: item.confidencePercent,
        expectedFinancialImpact: item.expectedFinancialImpact,
        investmentValue: item.investmentValue,
        expectedReturnValue: item.expectedReturnValue,
        roiPercent: item.roiPercent,
        paybackDays: item.paybackDays,
        deadlineDays: item.deadlineDays,
        expectedResult: item.expectedResult,
        reasoningSummary: item.reasoningSummary,
        executionPlan: _executionPlan(item),
        monitoringIndicators: _monitoringIndicators(
          item: item,
          indicators: bi.indicators,
        ),
        status: AtlasDecisionStatus.recommended,
      );
    });

    final score = _engineScore(decisions);

    final confidence = _engineConfidence(decisions);

    final status = _statusFromScore(score);

    return AtlasDecisionEngineData(
      generatedAt: now ?? DateTime.now(),
      summary: _buildSummary(
        decisions: decisions,
        score: score,
        confidence: confidence,
        status: status,
      ),
      engineScore: score,
      confidencePercent: confidence,
      status: status,
      decisions: decisions,
      mainDecision: decisions.isEmpty ? null : decisions.first,
    );
  }

  List<_DecisionCandidate> _fromAdvisor(
    AtlasExecutiveAiAdvisorData advisor,
    AtlasBiData bi,
  ) {
    final result = <_DecisionCandidate>[];

    for (final item in advisor.weeklyPriorities) {
      final indicator = _findIndicator(
        farmName: item.farmName,
        category: item.category,
        indicators: bi.indicators,
      );

      result.add(
        _DecisionCandidate(
          id: 'advisor_week_${item.farmName}_${item.position}',
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          score:
              _priorityWeightFromAdvisor(item.priority) * 18 +
              item.confidencePercent * 0.40,
          confidencePercent: item.confidencePercent,
          expectedFinancialImpact: _financialImpactFromText(
            item.expectedImpact,
          ),
          investmentValue: 0,
          expectedReturnValue: _financialImpactFromText(item.expectedImpact),
          roiPercent: 0,
          paybackDays: null,
          deadlineDays: item.deadlineDays,
          risk: _riskFromAdvisorPriority(item.priority),
          expectedResult: item.expectedImpact,
          reasoningSummary:
              'A prioridade foi selecionada pelo Advisor para execução imediata.',
          indicator: indicator,
        ),
      );
    }

    for (final item in advisor.financialOpportunities) {
      final indicator = _findIndicator(
        farmName: item.farmName,
        category: item.category,
        indicators: bi.indicators,
      );

      result.add(
        _DecisionCandidate(
          id: 'advisor_finance_${item.farmName}_${item.position}',
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          score:
              item.roiPercent.clamp(0.0, 150.0) * 0.35 +
              item.confidencePercent * 0.35 +
              25,
          confidencePercent: item.confidencePercent,
          expectedFinancialImpact: item.expectedReturnValue,
          investmentValue: item.investmentValue,
          expectedReturnValue: item.expectedReturnValue,
          roiPercent: item.roiPercent,
          paybackDays: item.paybackDays,
          deadlineDays: 30,
          risk: item.confidencePercent >= 75
              ? AtlasDecisionRisk.medium
              : AtlasDecisionRisk.high,
          expectedResult:
              'Capturar retorno esperado de '
              'R\$ ${item.expectedReturnValue.toStringAsFixed(2)}.',
          reasoningSummary:
              'A decisão foi selecionada por apresentar potencial financeiro relevante.',
          indicator: indicator,
        ),
      );
    }

    return result;
  }

  List<_DecisionCandidate> _fromIntelligence(
    AtlasExecutiveIntelligenceData intelligence,
    AtlasBiData bi,
  ) {
    return intelligence.priorities.map((item) {
      final indicator = _findIndicator(
        farmName: item.farmName,
        category: item.category,
        indicators: bi.indicators,
      );

      return _DecisionCandidate(
        id: 'intelligence_${item.farmName}_${item.position}',
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        score: item.priorityScore * 0.60 + item.confidencePercent * 0.40,
        confidencePercent: item.confidencePercent,
        expectedFinancialImpact: item.expectedFinancialImpact,
        investmentValue: 0,
        expectedReturnValue: item.expectedFinancialImpact,
        roiPercent: 0,
        paybackDays: null,
        deadlineDays: item.deadlineDays,
        risk: _riskFromIntelligenceSeverity(item.severity),
        expectedResult:
            'Capturar impacto estimado de '
            'R\$ ${item.expectedFinancialImpact.toStringAsFixed(2)}.',
        reasoningSummary:
            'A decisão foi priorizada pelo Motor de Inteligência Executiva.',
        indicator: indicator,
      );
    }).toList();
  }

  List<_DecisionCandidate> _fromAnalytics(
    AtlasBiAnalyticsData analytics,
    AtlasBiData bi,
  ) {
    return analytics.investments.map((item) {
      final indicator = _findIndicator(
        farmName: item.farmName,
        category: item.category,
        indicators: bi.indicators,
      );

      return _DecisionCandidate(
        id: 'analytics_${item.id}',
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        score:
            item.impactScore * 0.55 +
            item.confidencePercent * 0.25 +
            item.roiPercent.clamp(0.0, 150.0) * 0.20,
        confidencePercent: item.confidencePercent,
        expectedFinancialImpact: item.expectedReturnValue,
        investmentValue: item.investmentValue,
        expectedReturnValue: item.expectedReturnValue,
        roiPercent: item.roiPercent,
        paybackDays: item.paybackDays,
        deadlineDays: item.effort == AtlasBiAnalyticsEffort.high
            ? 90
            : item.effort == AtlasBiAnalyticsEffort.medium
            ? 60
            : 30,
        risk: item.confidencePercent >= 80
            ? AtlasDecisionRisk.low
            : item.confidencePercent >= 60
            ? AtlasDecisionRisk.medium
            : AtlasDecisionRisk.high,
        expectedResult:
            'Gerar retorno esperado de '
            'R\$ ${item.expectedReturnValue.toStringAsFixed(2)}.',
        reasoningSummary:
            'A decisão foi classificada pelo Analytics com base em impacto, ROI e confiança.',
        indicator: indicator,
      );
    }).toList();
  }

  List<_DecisionCandidate> _fromForecast(
    AtlasBiForecastDashboardData forecast,
    AtlasBiData bi,
  ) {
    return forecast.forecasts
        .where((item) {
          return item.risk == AtlasBiForecastRisk.critical ||
              item.risk == AtlasBiForecastRisk.high;
        })
        .map((item) {
          final indicator = _findIndicatorById(
            farmName: item.farmName,
            indicatorId: item.indicatorId,
            indicators: bi.indicators,
          );

          final impact = item.projectedVariationPercent.abs() * 1000;

          return _DecisionCandidate(
            id: 'forecast_${item.farmName}_${item.indicatorId}',
            farmName: item.farmName,
            title: 'Intervir em ${item.title}',
            description: item.recommendation,
            category: item.category,
            score:
                (100 - item.targetProbabilityPercent) * 0.50 +
                item.confidencePercent * 0.25 +
                _forecastRiskWeight(item.risk) * 6.25,
            confidencePercent: item.confidencePercent,
            expectedFinancialImpact: impact,
            investmentValue: 0,
            expectedReturnValue: impact,
            roiPercent: 0,
            paybackDays: null,
            deadlineDays: item.risk == AtlasBiForecastRisk.critical ? 7 : 14,
            risk: _riskFromForecast(item.risk),
            expectedResult:
                'Elevar a probabilidade de atingir a meta acima de 70%.',
            reasoningSummary:
                'A decisão foi gerada para evitar uma consequência negativa prevista.',
            indicator: indicator,
          );
        })
        .toList();
  }

  List<_DecisionCandidate> _fromBenchmark(
    AtlasBiBenchmarkData benchmark,
    AtlasBiData bi,
  ) {
    if (benchmark.farms.length <= 1) {
      return [];
    }

    return benchmark.farms.skip(1).map((farm) {
      final indicator = _findIndicator(
        farmName: farm.farmName,
        category: AtlasBiCategory.management,
        indicators: bi.indicators,
      );

      final impact = farm.distanceFromLeader * 1500;

      return _DecisionCandidate(
        id: 'benchmark_${farm.farmName}',
        farmName: farm.farmName,
        title:
            'Reduzir distância para ${benchmark.leadingFarmName ?? 'a fazenda líder'}',
        description:
            'A fazenda está ${farm.distanceFromLeader.toStringAsFixed(1)} pontos abaixo da referência interna.',
        category: AtlasBiCategory.management,
        score: farm.distanceFromLeader * 2.2 + 25,
        confidencePercent: 82,
        expectedFinancialImpact: impact,
        investmentValue: 0,
        expectedReturnValue: impact,
        roiPercent: 0,
        paybackDays: null,
        deadlineDays: 60,
        risk: farm.distanceFromLeader >= 25
            ? AtlasDecisionRisk.high
            : AtlasDecisionRisk.medium,
        expectedResult:
            'Melhorar o score comparativo e reduzir a diferença para a líder.',
        reasoningSummary:
            'A decisão foi gerada a partir da comparação com a melhor referência interna.',
        indicator: indicator,
      );
    }).toList();
  }

  List<_DecisionCandidate> _mergeCandidates(
    List<_DecisionCandidate> candidates,
  ) {
    final merged = <String, _DecisionCandidate>{};

    for (final item in candidates) {
      final key =
          '${item.farmName}::${item.category.name}::${_normalizedTitle(item.title)}';

      final existing = merged[key];

      if (existing == null) {
        merged[key] = item;
        continue;
      }

      merged[key] = existing.copyWith(
        score: math.max(existing.score, item.score),
        confidencePercent: math.max(
          existing.confidencePercent,
          item.confidencePercent,
        ),
        expectedFinancialImpact: math.max(
          existing.expectedFinancialImpact,
          item.expectedFinancialImpact,
        ),
        investmentValue: existing.investmentValue > 0
            ? existing.investmentValue
            : item.investmentValue,
        expectedReturnValue: math.max(
          existing.expectedReturnValue,
          item.expectedReturnValue,
        ),
        roiPercent: math.max(existing.roiPercent, item.roiPercent),
        paybackDays: existing.paybackDays ?? item.paybackDays,
        deadlineDays: math.min(existing.deadlineDays, item.deadlineDays),
        risk: _higherRisk(existing.risk, item.risk),
        reasoningSummary:
            '${existing.reasoningSummary} '
            '${item.reasoningSummary}',
        indicator: existing.indicator ?? item.indicator,
      );
    }

    return merged.values.toList();
  }

  List<AtlasDecisionExecutionStep> _executionPlan(_DecisionCandidate item) {
    final deadline = item.deadlineDays;

    return [
      AtlasDecisionExecutionStep(
        position: 1,
        title: 'Validar diagnóstico',
        description:
            'Confirmar em campo os dados, causas e restrições relacionadas à decisão.',
        deadlineDays: math.max(1, math.min(3, deadline)),
        expectedResult: 'Hipótese validada e escopo definido.',
      ),
      AtlasDecisionExecutionStep(
        position: 2,
        title: 'Definir responsável e recursos',
        description:
            'Nomear responsável, recursos necessários e critérios de sucesso.',
        deadlineDays: math.max(2, math.min(7, deadline)),
        expectedResult: 'Plano autorizado e equipe alinhada.',
      ),
      AtlasDecisionExecutionStep(
        position: 3,
        title: 'Executar intervenção',
        description: item.description,
        deadlineDays: deadline,
        expectedResult: item.expectedResult,
      ),
      AtlasDecisionExecutionStep(
        position: 4,
        title: 'Medir resultado',
        description:
            'Comparar o indicador após a intervenção com o valor inicial e a meta.',
        deadlineDays: deadline + 7,
        expectedResult: 'Resultado mensurado e decisão reavaliada.',
      ),
    ];
  }

  List<AtlasDecisionMonitoringIndicator> _monitoringIndicators({
    required _DecisionCandidate item,
    required List<AtlasBiIndicator> indicators,
  }) {
    final result = <AtlasDecisionMonitoringIndicator>[];

    if (item.indicator != null) {
      result.add(
        AtlasDecisionMonitoringIndicator(
          title: item.indicator!.title,
          currentValue: item.indicator!.currentValue,
          targetValue: item.indicator!.targetValue,
          unit: item.indicator!.unit,
          measurementFrequencyDays: item.deadlineDays <= 14 ? 7 : 30,
        ),
      );
    }

    final related = indicators
        .where((indicator) {
          return indicator.farmName == item.farmName &&
              indicator.category == item.category &&
              indicator.id != item.indicator?.id;
        })
        .take(2);

    for (final indicator in related) {
      result.add(
        AtlasDecisionMonitoringIndicator(
          title: indicator.title,
          currentValue: indicator.currentValue,
          targetValue: indicator.targetValue,
          unit: indicator.unit,
          measurementFrequencyDays: item.deadlineDays <= 14 ? 7 : 30,
        ),
      );
    }

    return result;
  }

  AtlasBiIndicator? _findIndicator({
    required String farmName,
    required AtlasBiCategory category,
    required List<AtlasBiIndicator> indicators,
  }) {
    for (final indicator in indicators) {
      if (indicator.farmName == farmName && indicator.category == category) {
        return indicator;
      }
    }

    return null;
  }

  AtlasBiIndicator? _findIndicatorById({
    required String farmName,
    required String indicatorId,
    required List<AtlasBiIndicator> indicators,
  }) {
    for (final indicator in indicators) {
      if (indicator.farmName == farmName && indicator.id == indicatorId) {
        return indicator;
      }
    }

    return null;
  }

  AtlasDecisionPriority _priorityFromScore(double score) {
    if (score >= 85) {
      return AtlasDecisionPriority.critical;
    }

    if (score >= 70) {
      return AtlasDecisionPriority.high;
    }

    if (score >= 50) {
      return AtlasDecisionPriority.medium;
    }

    return AtlasDecisionPriority.low;
  }

  AtlasDecisionUrgency _urgencyFromCandidate(_DecisionCandidate item) {
    if (item.deadlineDays <= 7 || item.risk == AtlasDecisionRisk.critical) {
      return AtlasDecisionUrgency.immediate;
    }

    if (item.deadlineDays <= 14 || item.risk == AtlasDecisionRisk.high) {
      return AtlasDecisionUrgency.high;
    }

    if (item.deadlineDays <= 30) {
      return AtlasDecisionUrgency.medium;
    }

    return AtlasDecisionUrgency.low;
  }

  AtlasDecisionRisk _riskFromAdvisorPriority(
    AtlasExecutiveAdvisorPriorityLevel priority,
  ) {
    switch (priority) {
      case AtlasExecutiveAdvisorPriorityLevel.low:
        return AtlasDecisionRisk.low;

      case AtlasExecutiveAdvisorPriorityLevel.medium:
        return AtlasDecisionRisk.medium;

      case AtlasExecutiveAdvisorPriorityLevel.high:
        return AtlasDecisionRisk.high;

      case AtlasExecutiveAdvisorPriorityLevel.critical:
        return AtlasDecisionRisk.critical;
    }
  }

  AtlasDecisionRisk _riskFromIntelligenceSeverity(
    AtlasExecutiveIntelligenceSeverity severity,
  ) {
    switch (severity) {
      case AtlasExecutiveIntelligenceSeverity.low:
        return AtlasDecisionRisk.low;

      case AtlasExecutiveIntelligenceSeverity.medium:
        return AtlasDecisionRisk.medium;

      case AtlasExecutiveIntelligenceSeverity.high:
        return AtlasDecisionRisk.high;

      case AtlasExecutiveIntelligenceSeverity.critical:
        return AtlasDecisionRisk.critical;
    }
  }

  AtlasDecisionRisk _riskFromForecast(AtlasBiForecastRisk risk) {
    switch (risk) {
      case AtlasBiForecastRisk.low:
        return AtlasDecisionRisk.low;

      case AtlasBiForecastRisk.medium:
        return AtlasDecisionRisk.medium;

      case AtlasBiForecastRisk.high:
        return AtlasDecisionRisk.high;

      case AtlasBiForecastRisk.critical:
        return AtlasDecisionRisk.critical;
    }
  }

  AtlasDecisionRisk _higherRisk(
    AtlasDecisionRisk first,
    AtlasDecisionRisk second,
  ) {
    return _riskWeight(first) >= _riskWeight(second) ? first : second;
  }

  int _riskWeight(AtlasDecisionRisk risk) {
    switch (risk) {
      case AtlasDecisionRisk.low:
        return 1;

      case AtlasDecisionRisk.medium:
        return 2;

      case AtlasDecisionRisk.high:
        return 3;

      case AtlasDecisionRisk.critical:
        return 4;
    }
  }

  int _forecastRiskWeight(AtlasBiForecastRisk risk) {
    switch (risk) {
      case AtlasBiForecastRisk.low:
        return 1;

      case AtlasBiForecastRisk.medium:
        return 2;

      case AtlasBiForecastRisk.high:
        return 3;

      case AtlasBiForecastRisk.critical:
        return 4;
    }
  }

  int _priorityWeightFromAdvisor(AtlasExecutiveAdvisorPriorityLevel priority) {
    switch (priority) {
      case AtlasExecutiveAdvisorPriorityLevel.low:
        return 1;

      case AtlasExecutiveAdvisorPriorityLevel.medium:
        return 2;

      case AtlasExecutiveAdvisorPriorityLevel.high:
        return 3;

      case AtlasExecutiveAdvisorPriorityLevel.critical:
        return 4;
    }
  }

  double _financialImpactFromText(String value) {
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

  String _normalizedTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áàâãéêíóôõúç ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _engineScore(List<AtlasDecisionRecommendation> decisions) {
    if (decisions.isEmpty) {
      return 0;
    }

    final top = decisions.take(math.min(decisions.length, 5));

    final average =
        top.fold<double>(
          0,
          (sum, item) => sum + _priorityScore(item.priority),
        ) /
        top.length;

    return average.clamp(0.0, 100.0).toDouble();
  }

  double _engineConfidence(List<AtlasDecisionRecommendation> decisions) {
    if (decisions.isEmpty) {
      return 0;
    }

    final top = decisions.take(math.min(decisions.length, 8));

    final average =
        top.fold<double>(0, (sum, item) => sum + item.confidencePercent) /
        top.length;

    return average.clamp(0.0, 100.0).toDouble();
  }

  double _priorityScore(AtlasDecisionPriority priority) {
    switch (priority) {
      case AtlasDecisionPriority.low:
        return 35;

      case AtlasDecisionPriority.medium:
        return 55;

      case AtlasDecisionPriority.high:
        return 75;

      case AtlasDecisionPriority.critical:
        return 95;
    }
  }

  AtlasDecisionEngineStatus _statusFromScore(double score) {
    if (score >= 85) {
      return AtlasDecisionEngineStatus.critical;
    }

    if (score >= 65) {
      return AtlasDecisionEngineStatus.attention;
    }

    if (score >= 45) {
      return AtlasDecisionEngineStatus.adequate;
    }

    return AtlasDecisionEngineStatus.excellent;
  }

  String _buildSummary({
    required List<AtlasDecisionRecommendation> decisions,
    required double score,
    required double confidence,
    required AtlasDecisionEngineStatus status,
  }) {
    final mainDecision = decisions.isEmpty
        ? 'nenhuma decisão principal'
        : decisions.first.title;

    return 'O Motor de Decisão gerou '
        '${decisions.length} recomendações, com score de '
        '${score.toStringAsFixed(0)}/100, situação '
        '${atlasDecisionEngineStatusLabel(status).toLowerCase()}, '
        '${confidence.toStringAsFixed(0)}% de confiança e '
        '$mainDecision como decisão prioritária.';
  }
}

class _DecisionCandidate {
  const _DecisionCandidate({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.score,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.investmentValue,
    required this.expectedReturnValue,
    required this.roiPercent,
    required this.paybackDays,
    required this.deadlineDays,
    required this.risk,
    required this.expectedResult,
    required this.reasoningSummary,
    required this.indicator,
  });

  final String id;
  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;

  final double score;
  final double confidencePercent;

  final double expectedFinancialImpact;
  final double investmentValue;
  final double expectedReturnValue;
  final double roiPercent;

  final int? paybackDays;
  final int deadlineDays;

  final AtlasDecisionRisk risk;

  final String expectedResult;
  final String reasoningSummary;

  final AtlasBiIndicator? indicator;

  _DecisionCandidate copyWith({
    double? score,
    double? confidencePercent,
    double? expectedFinancialImpact,
    double? investmentValue,
    double? expectedReturnValue,
    double? roiPercent,
    int? paybackDays,
    int? deadlineDays,
    AtlasDecisionRisk? risk,
    String? reasoningSummary,
    AtlasBiIndicator? indicator,
  }) {
    return _DecisionCandidate(
      id: id,
      farmName: farmName,
      title: title,
      description: description,
      category: category,
      score: score ?? this.score,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      expectedFinancialImpact:
          expectedFinancialImpact ?? this.expectedFinancialImpact,
      investmentValue: investmentValue ?? this.investmentValue,
      expectedReturnValue: expectedReturnValue ?? this.expectedReturnValue,
      roiPercent: roiPercent ?? this.roiPercent,
      paybackDays: paybackDays ?? this.paybackDays,
      deadlineDays: deadlineDays ?? this.deadlineDays,
      risk: risk ?? this.risk,
      expectedResult: expectedResult,
      reasoningSummary: reasoningSummary ?? this.reasoningSummary,
      indicator: indicator ?? this.indicator,
    );
  }
}
