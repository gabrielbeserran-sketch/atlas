import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_intelligence/domain/models/atlas_intelligence_data.dart';
import 'package:projeto_atlas/features/atlas_os/domain/models/atlas_os_data.dart';
import 'package:projeto_atlas/features/executive_core/domain/models/atlas_executive_core_data.dart';

class AtlasExecutiveCoreService {
  const AtlasExecutiveCoreService();

  AtlasExecutiveCoreData build({
    required AtlasOsData atlasOs,
    required AtlasIntelligenceData intelligence,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final priorities = _buildPriorities(
      atlasOs: atlasOs,
      intelligence: intelligence,
    );

    final risks = _buildRisks(
      atlasOs,
    );

    final opportunities = _buildOpportunities(
      intelligence,
    );

    final bestDecision = _buildBestDecision(
      intelligence,
    );

    final nextMission = _buildNextMission(
      bestDecision: bestDecision,
      priorities: priorities,
    );

    final memoryRecords = _buildMemoryRecords(
      now: currentTime,
      intelligence: intelligence,
      risks: risks,
      opportunities: opportunities,
      bestDecision: bestDecision,
      nextMission: nextMission,
    );

    final financialIndex = _financialIndex(
      atlasOs: atlasOs,
      intelligence: intelligence,
      opportunities: opportunities,
      risks: risks,
    );

    final operationalIndex = _operationalIndex(
      atlasOs,
    );

    final strategicIndex = _strategicIndex(
      atlasOs: atlasOs,
      priorities: priorities,
    );

    final predictiveIndex = _predictiveIndex(
      intelligence,
    );

    final healthIndex = _healthIndex(
      atlasOs: atlasOs,
      intelligence: intelligence,
    );

    final executiveScore = _executiveScore(
      financialIndex: financialIndex,
      operationalIndex: operationalIndex,
      strategicIndex: strategicIndex,
      predictiveIndex: predictiveIndex,
      healthIndex: healthIndex,
    );

    final confidence = _confidence(
      intelligence: intelligence,
      priorities: priorities,
    );

    final status = _status(
      executiveScore,
    );

    return AtlasExecutiveCoreData(
      generatedAt: currentTime,
      summary: _summary(
        priorities: priorities,
        risks: risks,
        opportunities: opportunities,
        executiveScore: executiveScore,
        confidence: confidence,
        bestDecision: bestDecision,
        nextMission: nextMission,
      ),
      executiveScore: executiveScore,
      financialIndex: financialIndex,
      operationalIndex: operationalIndex,
      strategicIndex: strategicIndex,
      predictiveIndex: predictiveIndex,
      healthIndex: healthIndex,
      confidencePercent: confidence,
      status: status,
      priorities: priorities,
      risks: risks,
      opportunities: opportunities,
      bestDecisionOfWeek: bestDecision,
      nextMission: nextMission,
      memoryRecords: memoryRecords,
    );
  }

  List<AtlasExecutiveCorePriority> _buildPriorities({
    required AtlasOsData atlasOs,
    required AtlasIntelligenceData intelligence,
  }) {
    final candidates = <_PriorityCandidate>[];

    for (final item in intelligence.recommendations) {
      candidates.add(
        _PriorityCandidate(
          id: 'intelligence_${item.id}',
          title: item.title,
          description: item.description,
          farmName: item.farmName,
          score:
              _priorityWeightFromIntelligence(
                    item.priority,
                  ) *
                  18 +
              item.confidencePercent * 0.35 +
              math.min(
                    item.expectedFinancialImpact.abs() /
                        1000,
                    25,
                  ),
          confidencePercent:
              item.confidencePercent,
          expectedFinancialImpact:
              item.expectedFinancialImpact,
          deadlineHours:
              item.deadlineHours,
          priority:
              _priorityFromIntelligence(
            item.priority,
          ),
          source:
              'Atlas Intelligence Engine',
        ),
      );
    }

    for (final item in atlasOs.commands) {
      candidates.add(
        _PriorityCandidate(
          id: 'os_${item.id}',
          title: item.title,
          description: item.description,
          farmName: item.farmName,
          score:
              _priorityWeightFromOs(
                    item.priority,
                  ) *
                  17 +
              math.min(
                item.deadlineHours <= 0
                    ? 20
                    : 140 / item.deadlineHours,
                20,
              ) +
              math.min(
                _moneyFromText(
                      item.expectedImpact,
                    ) /
                    1000,
                20,
              ),
          confidencePercent: 92,
          expectedFinancialImpact:
              _moneyFromText(
            item.expectedImpact,
          ),
          deadlineHours:
              item.deadlineHours,
          priority:
              _priorityFromOs(
            item.priority,
          ),
          source: item.source,
        ),
      );
    }

    candidates.sort(
      (first, second) =>
          second.score.compareTo(
        first.score,
      ),
    );

    final selected =
        candidates.take(20).toList();

    return List.generate(
      selected.length,
      (index) {
        final item = selected[index];

        return AtlasExecutiveCorePriority(
          position: index + 1,
          id: item.id,
          title: item.title,
          description: item.description,
          farmName: item.farmName,
          priority: item.priority,
          confidencePercent:
              item.confidencePercent,
          expectedFinancialImpact:
              item.expectedFinancialImpact,
          deadlineHours:
              item.deadlineHours,
          source: item.source,
        );
      },
    );
  }

  List<AtlasExecutiveCoreRisk> _buildRisks(
    AtlasOsData atlasOs,
  ) {
    final items =
        atlasOs.criticalItems.toList()
          ..sort(
            (first, second) {
              final severityComparison =
                  _severityWeightFromOs(
                    second.severity,
                  ).compareTo(
                    _severityWeightFromOs(
                      first.severity,
                    ),
                  );

              if (severityComparison != 0) {
                return severityComparison;
              }

              return second.probabilityPercent
                  .compareTo(
                first.probabilityPercent,
              );
            },
          );

    return List.generate(
      math.min(items.length, 15),
      (index) {
        final item = items[index];

        return AtlasExecutiveCoreRisk(
          position: index + 1,
          id: item.id,
          title: item.title,
          description: item.description,
          farmName: item.farmName,
          severity:
              _severityFromOs(
            item.severity,
          ),
          probabilityPercent:
              item.probabilityPercent,
          expectedFinancialImpact:
              item.expectedFinancialImpact,
          recommendation:
              item.recommendation,
        );
      },
    );
  }

  List<AtlasExecutiveCoreOpportunity>
      _buildOpportunities(
    AtlasIntelligenceData intelligence,
  ) {
    final items = intelligence.recommendations
        .where((item) {
          return item.expectedFinancialImpact > 0;
        })
        .toList()
      ..sort(
        (first, second) =>
            second.expectedFinancialImpact.compareTo(
          first.expectedFinancialImpact,
        ),
      );

    return List.generate(
      math.min(items.length, 12),
      (index) {
        final item = items[index];

        final investment =
            item.expectedFinancialImpact * 0.25;

        final expectedReturn =
            item.expectedFinancialImpact;

        final roi = investment <= 0
            ? 0.0
            : expectedReturn /
                investment *
                100;

        return AtlasExecutiveCoreOpportunity(
          position: index + 1,
          id: 'opportunity_${item.id}',
          title: item.title,
          description: item.description,
          farmName: item.farmName,
          expectedReturn:
              expectedReturn,
          investmentValue: investment,
          roiPercent:
              roi.clamp(0.0, 500.0).toDouble(),
          confidencePercent:
              item.confidencePercent,
          recommendation:
              item.reasoning,
        );
      },
    );
  }

  AtlasExecutiveCoreDecision? _buildBestDecision(
    AtlasIntelligenceData intelligence,
  ) {
    final item =
        intelligence.primaryRecommendation;

    if (item == null) {
      return null;
    }

    final score =
        _priorityWeightFromIntelligence(
              item.priority,
            ) *
            20 +
        item.confidencePercent * 0.40 +
        math.min(
          item.expectedFinancialImpact.abs() /
              1000,
          20,
        );

    return AtlasExecutiveCoreDecision(
      id: 'decision_${item.id}',
      title: item.title,
      description: item.description,
      farmName: item.farmName,
      score:
          score.clamp(0.0, 100.0).toDouble(),
      confidencePercent:
          item.confidencePercent,
      expectedFinancialImpact:
          item.expectedFinancialImpact,
      deadlineHours:
          item.deadlineHours,
      reasoning: item.reasoning,
      actions: item.actions,
    );
  }

  AtlasExecutiveCoreMission? _buildNextMission({
    required AtlasExecutiveCoreDecision?
        bestDecision,
    required List<AtlasExecutiveCorePriority>
        priorities,
  }) {
    if (bestDecision == null &&
        priorities.isEmpty) {
      return null;
    }

    final title =
        bestDecision?.title ??
            priorities.first.title;

    final description =
        bestDecision?.description ??
            priorities.first.description;

    final farmName =
        bestDecision?.farmName ??
            priorities.first.farmName;

    final impact =
        bestDecision?.expectedFinancialImpact ??
            priorities.first.expectedFinancialImpact;

    final confidence =
        bestDecision?.confidencePercent ??
            priorities.first.confidencePercent;

    final deadlineHours =
        bestDecision?.deadlineHours ??
            priorities.first.deadlineHours;

    final steps = bestDecision?.actions ??
        const [
          'Validar a prioridade em campo.',
          'Definir responsável.',
          'Executar a primeira ação.',
          'Medir o resultado.',
        ];

    return AtlasExecutiveCoreMission(
      id:
          'mission_${title.hashCode}_${farmName.hashCode}',
      title: 'Missão executiva: $title',
      description: description,
      farmName: farmName,
      objective:
          'Transformar a recomendação prioritária em resultado mensurável.',
      deadlineDays:
          math.max(
        1,
        (deadlineHours / 24).ceil(),
      ),
      expectedImpact:
          impact > 0
              ? 'Impacto financeiro esperado de '
                  'R\$ ${impact.toStringAsFixed(2)}.'
              : 'Redução de risco e melhoria da execução.',
      successProbabilityPercent:
          confidence.clamp(0.0, 100.0).toDouble(),
      steps: steps,
    );
  }

  List<AtlasExecutiveMemoryRecord>
      _buildMemoryRecords({
    required DateTime now,
    required AtlasIntelligenceData intelligence,
    required List<AtlasExecutiveCoreRisk> risks,
    required List<AtlasExecutiveCoreOpportunity>
        opportunities,
    required AtlasExecutiveCoreDecision? bestDecision,
    required AtlasExecutiveCoreMission? nextMission,
  }) {
    final result =
        <AtlasExecutiveMemoryRecord>[];

    for (final pattern
        in intelligence.patterns.take(8)) {
      result.add(
        AtlasExecutiveMemoryRecord(
          id: 'memory_pattern_${pattern.id}',
          recordedAt: now,
          title: pattern.title,
          description:
              pattern.description,
          type:
              AtlasExecutiveMemoryType.pattern,
          farmName: 'Operação',
          relevanceScore:
              pattern.strengthScore,
          relatedEntityIds:
              pattern.relatedSignalIds,
        ),
      );
    }

    for (final risk in risks.take(6)) {
      result.add(
        AtlasExecutiveMemoryRecord(
          id: 'memory_risk_${risk.id}',
          recordedAt: now,
          title: risk.title,
          description:
              risk.description,
          type:
              AtlasExecutiveMemoryType.risk,
          farmName: risk.farmName,
          relevanceScore:
              risk.probabilityPercent,
          relatedEntityIds: [
            risk.id,
          ],
        ),
      );
    }

    for (final opportunity
        in opportunities.take(5)) {
      result.add(
        AtlasExecutiveMemoryRecord(
          id:
              'memory_opportunity_${opportunity.id}',
          recordedAt: now,
          title: opportunity.title,
          description:
              opportunity.description,
          type:
              AtlasExecutiveMemoryType.opportunity,
          farmName:
              opportunity.farmName,
          relevanceScore:
              opportunity.confidencePercent,
          relatedEntityIds: [
            opportunity.id,
          ],
        ),
      );
    }

    if (bestDecision != null) {
      result.add(
        AtlasExecutiveMemoryRecord(
          id:
              'memory_decision_${bestDecision.id}',
          recordedAt: now,
          title: bestDecision.title,
          description:
              bestDecision.description,
          type:
              AtlasExecutiveMemoryType.decision,
          farmName:
              bestDecision.farmName,
          relevanceScore:
              bestDecision.score,
          relatedEntityIds: [
            bestDecision.id,
          ],
        ),
      );
    }

    if (nextMission != null) {
      result.add(
        AtlasExecutiveMemoryRecord(
          id:
              'memory_mission_${nextMission.id}',
          recordedAt: now,
          title: nextMission.title,
          description:
              nextMission.description,
          type:
              AtlasExecutiveMemoryType.mission,
          farmName:
              nextMission.farmName,
          relevanceScore:
              nextMission.successProbabilityPercent,
          relatedEntityIds: [
            nextMission.id,
          ],
        ),
      );
    }

    result.sort(
      (first, second) =>
          second.relevanceScore.compareTo(
        first.relevanceScore,
      ),
    );

    return result.take(25).toList();
  }

  double _financialIndex({
    required AtlasOsData atlasOs,
    required AtlasIntelligenceData intelligence,
    required List<AtlasExecutiveCoreOpportunity>
        opportunities,
    required List<AtlasExecutiveCoreRisk> risks,
  }) {
    final opportunityValue =
        opportunities.fold<double>(
      0,
      (sum, item) =>
          sum + item.expectedReturn,
    );

    final riskValue =
        risks.fold<double>(
      0,
      (sum, item) =>
          sum + item.expectedFinancialImpact,
    );

    final opportunityComponent =
        math.min(
      opportunityValue / 1000,
      100,
    );

    final riskPenalty =
        math.min(
      riskValue / 1500,
      50,
    );

    return (atlasOs.healthScore * 0.35 +
            intelligence.intelligenceScore * 0.25 +
            opportunityComponent * 0.50 -
            riskPenalty * 0.30)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _operationalIndex(
    AtlasOsData atlasOs,
  ) {
    final moduleAverage =
        atlasOs.modules.isEmpty
            ? atlasOs.executionPercent
            : atlasOs.modules.fold<double>(
                      0,
                      (sum, item) =>
                          sum + item.score,
                    ) /
                    atlasOs.modules.length;

    return (atlasOs.executionPercent * 0.60 +
            moduleAverage * 0.40)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _strategicIndex({
    required AtlasOsData atlasOs,
    required List<AtlasExecutiveCorePriority>
        priorities,
  }) {
    final criticalCount =
        priorities.where((item) {
      return item.priority ==
          AtlasExecutiveCorePriorityLevel
              .critical;
    }).length;

    return (atlasOs.goalProbabilityPercent *
                0.75 +
            atlasOs.healthScore * 0.25 -
            criticalCount * 4)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _predictiveIndex(
    AtlasIntelligenceData intelligence,
  ) {
    final patternAverage =
        intelligence.patterns.isEmpty
            ? intelligence.confidencePercent
            : intelligence.patterns.fold<double>(
                      0,
                      (sum, item) =>
                          sum +
                          item.confidencePercent,
                    ) /
                    intelligence.patterns.length;

    return (intelligence.confidencePercent *
                0.55 +
            patternAverage * 0.25 +
            intelligence.intelligenceScore *
                0.20)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _healthIndex({
    required AtlasOsData atlasOs,
    required AtlasIntelligenceData intelligence,
  }) {
    return (atlasOs.healthScore * 0.60 +
            intelligence.intelligenceScore *
                0.40)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _executiveScore({
    required double financialIndex,
    required double operationalIndex,
    required double strategicIndex,
    required double predictiveIndex,
    required double healthIndex,
  }) {
    return (financialIndex * 0.20 +
            operationalIndex * 0.25 +
            strategicIndex * 0.20 +
            predictiveIndex * 0.15 +
            healthIndex * 0.20)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _confidence({
    required AtlasIntelligenceData intelligence,
    required List<AtlasExecutiveCorePriority>
        priorities,
  }) {
    if (priorities.isEmpty) {
      return intelligence.confidencePercent;
    }

    final priorityAverage =
        priorities.fold<double>(
              0,
              (sum, item) =>
                  sum + item.confidencePercent,
            ) /
            priorities.length;

    return (intelligence.confidencePercent *
                0.55 +
            priorityAverage * 0.45)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasExecutiveCoreStatus _status(
    double score,
  ) {
    if (score >= 80) {
      return AtlasExecutiveCoreStatus.excellent;
    }

    if (score >= 65) {
      return AtlasExecutiveCoreStatus.adequate;
    }

    if (score >= 45) {
      return AtlasExecutiveCoreStatus.attention;
    }

    return AtlasExecutiveCoreStatus.critical;
  }

  AtlasExecutiveCorePriorityLevel
      _priorityFromIntelligence(
    AtlasIntelligencePriority priority,
  ) {
    switch (priority) {
      case AtlasIntelligencePriority.low:
        return AtlasExecutiveCorePriorityLevel.low;

      case AtlasIntelligencePriority.medium:
        return AtlasExecutiveCorePriorityLevel.medium;

      case AtlasIntelligencePriority.high:
        return AtlasExecutiveCorePriorityLevel.high;

      case AtlasIntelligencePriority.critical:
        return AtlasExecutiveCorePriorityLevel
            .critical;
    }
  }

  AtlasExecutiveCorePriorityLevel
      _priorityFromOs(
    AtlasOsPriority priority,
  ) {
    switch (priority) {
      case AtlasOsPriority.low:
        return AtlasExecutiveCorePriorityLevel.low;

      case AtlasOsPriority.medium:
        return AtlasExecutiveCorePriorityLevel.medium;

      case AtlasOsPriority.high:
        return AtlasExecutiveCorePriorityLevel.high;

      case AtlasOsPriority.critical:
        return AtlasExecutiveCorePriorityLevel
            .critical;
    }
  }

  AtlasExecutiveCoreSeverity _severityFromOs(
    AtlasOsSeverity severity,
  ) {
    switch (severity) {
      case AtlasOsSeverity.low:
        return AtlasExecutiveCoreSeverity.low;

      case AtlasOsSeverity.medium:
        return AtlasExecutiveCoreSeverity.medium;

      case AtlasOsSeverity.high:
        return AtlasExecutiveCoreSeverity.high;

      case AtlasOsSeverity.critical:
        return AtlasExecutiveCoreSeverity.critical;
    }
  }

  int _priorityWeightFromIntelligence(
    AtlasIntelligencePriority priority,
  ) {
    switch (priority) {
      case AtlasIntelligencePriority.low:
        return 1;

      case AtlasIntelligencePriority.medium:
        return 2;

      case AtlasIntelligencePriority.high:
        return 3;

      case AtlasIntelligencePriority.critical:
        return 4;
    }
  }

  int _priorityWeightFromOs(
    AtlasOsPriority priority,
  ) {
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

  int _severityWeightFromOs(
    AtlasOsSeverity severity,
  ) {
    switch (severity) {
      case AtlasOsSeverity.low:
        return 1;

      case AtlasOsSeverity.medium:
        return 2;

      case AtlasOsSeverity.high:
        return 3;

      case AtlasOsSeverity.critical:
        return 4;
    }
  }

  double _moneyFromText(
    String value,
  ) {
    final match = RegExp(
      r'R\$\s*([0-9.,]+)',
    ).firstMatch(value);

    if (match == null) {
      return 0;
    }

    final raw = match.group(1);

    if (raw == null || raw.isEmpty) {
      return 0;
    }

    final normalized = raw
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized) ?? 0;
  }

  String _summary({
    required List<AtlasExecutiveCorePriority>
        priorities,
    required List<AtlasExecutiveCoreRisk> risks,
    required List<AtlasExecutiveCoreOpportunity>
        opportunities,
    required double executiveScore,
    required double confidence,
    required AtlasExecutiveCoreDecision? bestDecision,
    required AtlasExecutiveCoreMission? nextMission,
  }) {
    final decisionTitle =
        bestDecision?.title ??
            'nenhuma decisão principal';

    final missionTitle =
        nextMission?.title ??
            'nenhuma missão recomendada';

    return 'O Executive Core consolidou '
        '${priorities.length} prioridades, '
        '${risks.length} riscos, '
        '${opportunities.length} oportunidades, '
        'score executivo de '
        '${executiveScore.toStringAsFixed(0)}/100, '
        '${confidence.toStringAsFixed(0)}% de confiança, '
        '$decisionTitle como melhor decisão da semana '
        'e $missionTitle como próxima missão.';
  }
}

class _PriorityCandidate {
  const _PriorityCandidate({
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.score,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineHours,
    required this.priority,
    required this.source,
  });

  final String id;
  final String title;
  final String description;
  final String farmName;

  final double score;
  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineHours;

  final AtlasExecutiveCorePriorityLevel priority;
  final String source;
}
