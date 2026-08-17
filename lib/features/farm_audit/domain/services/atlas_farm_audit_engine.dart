import 'dart:math' as math;

import 'package:projeto_atlas/features/autonomous_consultant/domain/models/atlas_consultant_report.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasFarmAuditEngine {
  const AtlasFarmAuditEngine();

  AtlasFarmAudit execute({
    required AtlasDigitalTwin twin,
    required AtlasConsultantReport consultantReport,
  }) {
    final results = _buildAreaResults(
      twin: twin,
      consultantReport: consultantReport,
    );

    final totalWeight = results.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );

    final weightedTotal = results.fold<double>(
      0,
      (sum, item) => sum + item.score * item.weight,
    );

    final overallIndex = totalWeight == 0 ? 0.0 : weightedTotal / totalWeight;

    final problems = _buildProblems(results);
    final opportunities = _buildOpportunities(
      results: results,
      consultantReport: consultantReport,
    );

    return AtlasFarmAudit(
      id: 'farm_audit_${DateTime.now().microsecondsSinceEpoch}',
      farmId: twin.farmId,
      farmName: twin.farmName,
      generatedAt: DateTime.now(),
      overallIndex: overallIndex,
      classification: _classification(overallIndex),
      diagnosis: _buildDiagnosis(
        twin: twin,
        results: results,
        problems: problems,
      ),
      areaResults: results,
      problems: problems,
      opportunities: opportunities,
      digitalTwinScore: twin.overallScore,
      trend: twin.trend,
    );
  }

  List<AtlasFarmAuditAreaResult> _buildAreaResults({
    required AtlasDigitalTwin twin,
    required AtlasConsultantReport consultantReport,
  }) {
    final health = twin.health;
    final eventConfidence = (twin.totalProcessedEvents / 40)
        .clamp(0.0, 1.0)
        .toDouble();

    final riskPenalty = twin.risks.fold<double>(
      0,
      (sum, risk) => sum + _riskWeight(risk.level),
    );

    final actionPressure = consultantReport.actions.fold<double>(
      0,
      (sum, action) => sum + _consultantPriorityWeight(action.priority),
    );

    double adjusted(double base, {double bonus = 0, double penalty = 0}) {
      return (base +
              bonus +
              eventConfidence * 3 -
              penalty -
              riskPenalty * 0.18 -
              actionPressure * 0.08)
          .clamp(0.0, 100.0)
          .toDouble();
    }

    final results = <AtlasFarmAuditAreaResult>[
      _result(
        area: AtlasFarmAuditArea.nutrition,
        score: adjusted(
          health.animal * 0.58 +
              health.operational * 0.22 +
              health.inventory * 0.20,
        ),
        weight: 1.15,
      ),
      _result(
        area: AtlasFarmAuditArea.sanitary,
        score: adjusted(
          health.sanitary,
          penalty: _areaRiskPenalty(twin, AtlasDigitalTwinArea.sanitary),
        ),
        weight: 1.25,
      ),
      _result(
        area: AtlasFarmAuditArea.reproduction,
        score: adjusted(
          health.reproductive,
          penalty: _areaRiskPenalty(twin, AtlasDigitalTwinArea.reproductive),
        ),
        weight: 1.25,
      ),
      _result(
        area: AtlasFarmAuditArea.animalWelfare,
        score: adjusted(health.animal * 0.70 + health.sanitary * 0.30),
        weight: 1.00,
      ),
      _result(
        area: AtlasFarmAuditArea.genetics,
        score: adjusted(
          health.reproductive * 0.55 + health.animal * 0.45,
          penalty: eventConfidence < 0.25 ? 6 : 0,
        ),
        weight: 0.80,
      ),
      _result(
        area: AtlasFarmAuditArea.pastures,
        score: adjusted(
          health.animal * 0.45 +
              health.operational * 0.35 +
              health.inventory * 0.20,
          penalty: eventConfidence < 0.30 ? 5 : 0,
        ),
        weight: 1.00,
      ),
      _result(
        area: AtlasFarmAuditArea.financial,
        score: adjusted(
          health.financial,
          penalty: _areaRiskPenalty(twin, AtlasDigitalTwinArea.financial),
        ),
        weight: 1.25,
      ),
      _result(
        area: AtlasFarmAuditArea.inventory,
        score: adjusted(
          health.inventory,
          penalty: _areaRiskPenalty(twin, AtlasDigitalTwinArea.inventory),
        ),
        weight: 0.85,
      ),
      _result(
        area: AtlasFarmAuditArea.operational,
        score: adjusted(
          health.operational,
          penalty: _areaRiskPenalty(twin, AtlasDigitalTwinArea.operational),
        ),
        weight: 1.10,
      ),
      _result(
        area: AtlasFarmAuditArea.people,
        score: adjusted(
          health.operational * 0.72 +
              health.sanitary * 0.14 +
              health.inventory * 0.14,
          penalty: eventConfidence < 0.35 ? 4 : 0,
        ),
        weight: 0.85,
      ),
      _result(
        area: AtlasFarmAuditArea.biosecurity,
        score: adjusted(
          health.sanitary * 0.75 + health.operational * 0.25,
          penalty: _areaRiskPenalty(twin, AtlasDigitalTwinArea.sanitary),
        ),
        weight: 1.10,
      ),
      _result(
        area: AtlasFarmAuditArea.sustainability,
        score: adjusted(
          health.animal * 0.20 +
              health.sanitary * 0.15 +
              health.financial * 0.25 +
              health.inventory * 0.15 +
              health.operational * 0.25,
          penalty: eventConfidence < 0.30 ? 4 : 0,
        ),
        weight: 0.90,
      ),
    ];

    results.sort((first, second) => first.score.compareTo(second.score));

    return results;
  }

  AtlasFarmAuditAreaResult _result({
    required AtlasFarmAuditArea area,
    required double score,
    required double weight,
  }) {
    return AtlasFarmAuditAreaResult(
      area: area,
      score: score,
      weight: weight,
      status: _status(score),
      summary: _summaryForArea(area, score),
    );
  }

  List<AtlasFarmAuditProblem> _buildProblems(
    List<AtlasFarmAuditAreaResult> results,
  ) {
    final problems = <AtlasFarmAuditProblem>[];

    for (final result in results) {
      if (result.score >= 75) {
        continue;
      }

      final gap = 80 - result.score;
      final priority = _priorityFromScore(result.score);

      problems.add(
        AtlasFarmAuditProblem(
          id: 'audit_problem_${result.area.name}_${DateTime.now().microsecondsSinceEpoch}',
          area: result.area,
          title:
              'Desempenho insuficiente em ${atlasFarmAuditAreaLabel(result.area)}',
          description:
              '${result.summary} A diferença estimada até a faixa desejável é de ${gap.toStringAsFixed(1)} pontos.',
          priority: priority,
          estimatedAnnualImpact:
              math.max(0, gap) * _economicFactor(result.area),
          recommendedDeadlineDays: _deadlineForPriority(priority),
        ),
      );
    }

    problems.sort(
      (first, second) => _priorityWeight(
        second.priority,
      ).compareTo(_priorityWeight(first.priority)),
    );

    return problems;
  }

  List<AtlasFarmAuditOpportunity> _buildOpportunities({
    required List<AtlasFarmAuditAreaResult> results,
    required AtlasConsultantReport consultantReport,
  }) {
    final opportunities = <AtlasFarmAuditOpportunity>[];

    for (final result in results.take(5)) {
      final gap = (85 - result.score).clamp(0.0, 60.0).toDouble();

      if (gap <= 4) {
        continue;
      }

      final investment = (gap * _investmentFactor(result.area))
          .clamp(3000.0, 120000.0)
          .toDouble();

      final returnValue =
          investment * _returnMultiplier(result.area, result.score);

      final roi = investment <= 0
          ? 0.0
          : ((returnValue - investment) / investment) * 100;

      opportunities.add(
        AtlasFarmAuditOpportunity(
          id: 'audit_opportunity_${result.area.name}_${DateTime.now().microsecondsSinceEpoch}',
          area: result.area,
          title: 'Elevar ${atlasFarmAuditAreaLabel(result.area)}',
          description:
              'Intervenção orientada para reduzir o gargalo e aproximar a área da faixa de excelência.',
          estimatedInvestment: investment,
          estimatedReturn: returnValue,
          roiPercent: roi,
          priority: _priorityFromScore(result.score),
        ),
      );
    }

    final best = consultantReport.optimizationResult.bestCandidate;

    opportunities.add(
      AtlasFarmAuditOpportunity(
        id: 'audit_optimized_${DateTime.now().microsecondsSinceEpoch}',
        area: AtlasFarmAuditArea.operational,
        title: best.name,
        description:
            'Estratégia selecionada automaticamente pelo Optimization Engine.',
        estimatedInvestment: best.result.simulation.changes.initialInvestment,
        estimatedReturn:
            best.result.projectedNetResult +
            best.result.simulation.changes.initialInvestment,
        roiPercent: best.result.roiPercent,
        priority: best.isEligible
            ? AtlasFarmAuditPriority.high
            : AtlasFarmAuditPriority.moderate,
      ),
    );

    opportunities.sort(
      (first, second) => second.roiPercent.compareTo(first.roiPercent),
    );

    return opportunities.take(6).toList();
  }

  double _areaRiskPenalty(AtlasDigitalTwin twin, AtlasDigitalTwinArea area) {
    return twin.risks
        .where((risk) => risk.area == area)
        .fold<double>(0, (sum, risk) => sum + _riskWeight(risk.level) * 1.5);
  }

  double _riskWeight(AtlasFarmRiskLevel level) {
    switch (level) {
      case AtlasFarmRiskLevel.low:
        return 1;
      case AtlasFarmRiskLevel.moderate:
        return 3;
      case AtlasFarmRiskLevel.high:
        return 6;
      case AtlasFarmRiskLevel.critical:
        return 10;
    }
  }

  double _consultantPriorityWeight(AtlasConsultantPriority priority) {
    switch (priority) {
      case AtlasConsultantPriority.low:
        return 1;
      case AtlasConsultantPriority.moderate:
        return 2;
      case AtlasConsultantPriority.high:
        return 4;
      case AtlasConsultantPriority.critical:
        return 7;
    }
  }

  AtlasFarmAuditClassification _classification(double score) {
    if (score >= 85) {
      return AtlasFarmAuditClassification.excellent;
    }

    if (score >= 70) {
      return AtlasFarmAuditClassification.good;
    }

    if (score >= 50) {
      return AtlasFarmAuditClassification.attention;
    }

    return AtlasFarmAuditClassification.critical;
  }

  AtlasFarmAuditAreaStatus _status(double score) {
    if (score >= 85) {
      return AtlasFarmAuditAreaStatus.excellent;
    }

    if (score >= 70) {
      return AtlasFarmAuditAreaStatus.good;
    }

    if (score >= 50) {
      return AtlasFarmAuditAreaStatus.attention;
    }

    return AtlasFarmAuditAreaStatus.critical;
  }

  AtlasFarmAuditPriority _priorityFromScore(double score) {
    if (score < 45) {
      return AtlasFarmAuditPriority.critical;
    }

    if (score < 60) {
      return AtlasFarmAuditPriority.high;
    }

    if (score < 75) {
      return AtlasFarmAuditPriority.moderate;
    }

    return AtlasFarmAuditPriority.low;
  }

  int _priorityWeight(AtlasFarmAuditPriority priority) {
    switch (priority) {
      case AtlasFarmAuditPriority.low:
        return 1;
      case AtlasFarmAuditPriority.moderate:
        return 2;
      case AtlasFarmAuditPriority.high:
        return 3;
      case AtlasFarmAuditPriority.critical:
        return 4;
    }
  }

  int _deadlineForPriority(AtlasFarmAuditPriority priority) {
    switch (priority) {
      case AtlasFarmAuditPriority.critical:
        return 7;
      case AtlasFarmAuditPriority.high:
        return 15;
      case AtlasFarmAuditPriority.moderate:
        return 30;
      case AtlasFarmAuditPriority.low:
        return 60;
    }
  }

  double _economicFactor(AtlasFarmAuditArea area) {
    switch (area) {
      case AtlasFarmAuditArea.reproduction:
        return 6500;
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.biosecurity:
        return 5200;
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.pastures:
        return 4800;
      case AtlasFarmAuditArea.financial:
        return 6000;
      case AtlasFarmAuditArea.operational:
      case AtlasFarmAuditArea.people:
        return 4000;
      case AtlasFarmAuditArea.genetics:
        return 3500;
      case AtlasFarmAuditArea.inventory:
        return 2800;
      case AtlasFarmAuditArea.animalWelfare:
        return 3200;
      case AtlasFarmAuditArea.sustainability:
        return 2600;
    }
  }

  double _investmentFactor(AtlasFarmAuditArea area) {
    switch (area) {
      case AtlasFarmAuditArea.reproduction:
        return 1800;
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.biosecurity:
        return 1300;
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.pastures:
        return 1700;
      case AtlasFarmAuditArea.financial:
        return 900;
      case AtlasFarmAuditArea.operational:
      case AtlasFarmAuditArea.people:
        return 1100;
      case AtlasFarmAuditArea.genetics:
        return 2000;
      case AtlasFarmAuditArea.inventory:
        return 800;
      case AtlasFarmAuditArea.animalWelfare:
        return 1000;
      case AtlasFarmAuditArea.sustainability:
        return 1400;
    }
  }

  double _returnMultiplier(AtlasFarmAuditArea area, double score) {
    final urgencyBonus = ((75 - score) / 100).clamp(0.0, 0.35);

    switch (area) {
      case AtlasFarmAuditArea.reproduction:
        return 4.2 + urgencyBonus;
      case AtlasFarmAuditArea.financial:
        return 3.8 + urgencyBonus;
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.pastures:
        return 3.4 + urgencyBonus;
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.biosecurity:
        return 3.1 + urgencyBonus;
      case AtlasFarmAuditArea.operational:
      case AtlasFarmAuditArea.people:
        return 2.8 + urgencyBonus;
      case AtlasFarmAuditArea.genetics:
        return 2.7 + urgencyBonus;
      case AtlasFarmAuditArea.inventory:
        return 2.5 + urgencyBonus;
      case AtlasFarmAuditArea.animalWelfare:
        return 2.6 + urgencyBonus;
      case AtlasFarmAuditArea.sustainability:
        return 2.3 + urgencyBonus;
    }
  }

  String _summaryForArea(AtlasFarmAuditArea area, double score) {
    final status = atlasFarmAuditAreaStatusLabel(_status(score)).toLowerCase();

    return '${atlasFarmAuditAreaLabel(area)} apresenta condição $status, com ${score.toStringAsFixed(1)} pontos.';
  }

  String _buildDiagnosis({
    required AtlasDigitalTwin twin,
    required List<AtlasFarmAuditAreaResult> results,
    required List<AtlasFarmAuditProblem> problems,
  }) {
    final weakest = results.first;
    final strongest = results.last;

    final trendText = atlasDigitalTwinTrendLabel(twin.trend).toLowerCase();

    final urgencyText =
        problems.any((item) => item.priority == AtlasFarmAuditPriority.critical)
        ? 'Existem pontos críticos que exigem intervenção imediata.'
        : problems.any((item) => item.priority == AtlasFarmAuditPriority.high)
        ? 'Existem gargalos de alta prioridade que devem ser tratados antes de novas expansões.'
        : 'A fazenda não apresenta criticidades graves, mas ainda possui oportunidades de melhoria.';

    return 'A propriedade apresenta tendência $trendText. '
        'O principal ponto forte é ${atlasFarmAuditAreaLabel(strongest.area)}, '
        'com ${strongest.score.toStringAsFixed(1)} pontos. '
        'O maior gargalo é ${atlasFarmAuditAreaLabel(weakest.area)}, '
        'com ${weakest.score.toStringAsFixed(1)} pontos. '
        '$urgencyText';
  }
}
