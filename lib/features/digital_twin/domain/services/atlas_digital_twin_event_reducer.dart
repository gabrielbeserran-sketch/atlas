import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_score_service.dart';

class AtlasDigitalTwinEventReducer {
  const AtlasDigitalTwinEventReducer({
    this.scoreService =
        const AtlasDigitalTwinScoreService(),
  });

  final AtlasDigitalTwinScoreService scoreService;

  AtlasDigitalTwin reduce({
    required AtlasDigitalTwin current,
    required AtlasEvent event,
  }) {
    if (current.lastEventId == event.id) {
      return current;
    }

    final rule = _ruleFor(event);
    final previousScore = current.overallScore;

    final health = _applyVariation(
      current.health,
      area: rule.area,
      variation: rule.variation,
    );

    final overallScore =
        scoreService.calculateOverall(health);

    final risks = _updateRisks(
      current: current.risks,
      event: event,
      rule: rule,
    );

    final timeline = <AtlasFarmTimelineEvent>[
      AtlasFarmTimelineEvent(
        id:
            'twin_timeline_${DateTime.now().microsecondsSinceEpoch}',
        eventId: event.id,
        title: event.title,
        description: event.description,
        area: rule.area,
        impact: rule.impact,
        occurredAt: event.occurredAt,
        scoreBefore: previousScore,
        scoreAfter: overallScore,
      ),
      ...current.timeline,
    ].take(200).toList();

    return current.copyWith(
      farmName:
          event.farmName ?? current.farmName,
      updatedAt: DateTime.now(),
      health: health,
      overallScore: overallScore,
      trend: scoreService.calculateTrend(
        previousScore: previousScore,
        currentScore: overallScore,
      ),
      risks: risks,
      timeline: timeline,
      totalProcessedEvents:
          current.totalProcessedEvents + 1,
      lastEventId: event.id,
    );
  }

  AtlasFarmHealth _applyVariation(
    AtlasFarmHealth current, {
    required AtlasDigitalTwinArea area,
    required double variation,
  }) {
    switch (area) {
      case AtlasDigitalTwinArea.animal:
        return current.copyWith(
          animal: scoreService.apply(
            current.animal,
            variation,
          ),
        );
      case AtlasDigitalTwinArea.sanitary:
        return current.copyWith(
          sanitary: scoreService.apply(
            current.sanitary,
            variation,
          ),
        );
      case AtlasDigitalTwinArea.reproductive:
        return current.copyWith(
          reproductive: scoreService.apply(
            current.reproductive,
            variation,
          ),
        );
      case AtlasDigitalTwinArea.financial:
        return current.copyWith(
          financial: scoreService.apply(
            current.financial,
            variation,
          ),
        );
      case AtlasDigitalTwinArea.inventory:
        return current.copyWith(
          inventory: scoreService.apply(
            current.inventory,
            variation,
          ),
        );
      case AtlasDigitalTwinArea.operational:
        return current.copyWith(
          operational: scoreService.apply(
            current.operational,
            variation,
          ),
        );
    }
  }

  List<AtlasFarmRisk> _updateRisks({
    required List<AtlasFarmRisk> current,
    required AtlasEvent event,
    required _DigitalTwinEventRule rule,
  }) {
    final result = List<AtlasFarmRisk>.from(
      current,
    );

    final riskId =
        'risk_${rule.area.name}_${event.type.name}';

    if (rule.riskScore <= 0) {
      result.removeWhere(
        (item) =>
            item.area == rule.area &&
            item.score <= 45,
      );

      return result.take(25).toList();
    }

    final risk = AtlasFarmRisk(
      id: riskId,
      area: rule.area,
      title: rule.riskTitle,
      description: event.description,
      score: rule.riskScore,
      level: _riskLevel(rule.riskScore),
      updatedAt: event.occurredAt,
      sourceEventType: event.type.name,
    );

    final index = result.indexWhere(
      (item) => item.id == riskId,
    );

    if (index >= 0) {
      result[index] = risk;
    } else {
      result.insert(0, risk);
    }

    result.sort(
      (first, second) =>
          second.score.compareTo(first.score),
    );

    return result.take(25).toList();
  }

  AtlasFarmRiskLevel _riskLevel(
    double score,
  ) {
    if (score >= 80) {
      return AtlasFarmRiskLevel.critical;
    }

    if (score >= 60) {
      return AtlasFarmRiskLevel.high;
    }

    if (score >= 35) {
      return AtlasFarmRiskLevel.moderate;
    }

    return AtlasFarmRiskLevel.low;
  }

  _DigitalTwinEventRule _ruleFor(
    AtlasEvent event,
  ) {
    final type = event.type.name;
    final priority = event.priority.name;

    if (type == 'animalWeightRecorded') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.animal,
        variation: 0.8,
        impact: AtlasDigitalTwinImpact.positive,
        riskScore: 0,
        riskTitle: 'Desempenho animal',
      );
    }

    if (type == 'vaccinationRecorded') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.sanitary,
        variation: 1.4,
        impact: AtlasDigitalTwinImpact.positive,
        riskScore: 0,
        riskTitle: 'Proteção sanitária',
      );
    }

    if (type == 'treatmentRecorded') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.sanitary,
        variation: 0.5,
        impact: AtlasDigitalTwinImpact.positive,
        riskScore: 28,
        riskTitle: 'Tratamento sanitário em acompanhamento',
      );
    }

    if (type == 'healthEventCreated') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.sanitary,
        variation: -1.2,
        impact: AtlasDigitalTwinImpact.negative,
        riskScore: 48,
        riskTitle: 'Ocorrência sanitária',
      );
    }

    if (type == 'diseaseAlertCreated') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.sanitary,
        variation: -4.5,
        impact: AtlasDigitalTwinImpact.critical,
        riskScore: 90,
        riskTitle: 'Alerta de doença',
      );
    }

    if (type == 'pregnancyConfirmed' ||
        type == 'calvingRecorded') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.reproductive,
        variation: 1.6,
        impact: AtlasDigitalTwinImpact.positive,
        riskScore: 0,
        riskTitle: 'Evolução reprodutiva',
      );
    }

    if (type == 'inseminationRecorded' ||
        type == 'reproductionEventCreated') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.reproductive,
        variation: 0.6,
        impact: AtlasDigitalTwinImpact.positive,
        riskScore: 0,
        riskTitle: 'Atividade reprodutiva',
      );
    }

    if (type == 'financialEntryCreated' ||
        type == 'financialEntryUpdated' ||
        type == 'cashFlowUpdated') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.financial,
        variation: 0.3,
        impact: AtlasDigitalTwinImpact.neutral,
        riskScore: 0,
        riskTitle: 'Movimentação financeira',
      );
    }

    if (type == 'expenseLimitReached') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.financial,
        variation: -3.8,
        impact: AtlasDigitalTwinImpact.critical,
        riskScore: 86,
        riskTitle: 'Limite de despesas atingido',
      );
    }

    if (type == 'inventoryLowStock') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.inventory,
        variation: -2.3,
        impact: AtlasDigitalTwinImpact.negative,
        riskScore: 67,
        riskTitle: 'Estoque baixo',
      );
    }

    if (type == 'inventoryOutOfStock') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.inventory,
        variation: -4.8,
        impact: AtlasDigitalTwinImpact.critical,
        riskScore: 92,
        riskTitle: 'Item sem estoque',
      );
    }

    if (type == 'inventoryItemCreated' ||
        type == 'inventoryItemUpdated') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.inventory,
        variation: 0.7,
        impact: AtlasDigitalTwinImpact.positive,
        riskScore: 0,
        riskTitle: 'Estoque atualizado',
      );
    }

    if (type == 'taskCompleted' ||
        type == 'workflowCompleted') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.operational,
        variation: 1.2,
        impact: AtlasDigitalTwinImpact.positive,
        riskScore: 0,
        riskTitle: 'Execução concluída',
      );
    }

    if (type == 'taskDelayed' ||
        type == 'workflowDelayed') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.operational,
        variation: -2.7,
        impact: AtlasDigitalTwinImpact.negative,
        riskScore: 72,
        riskTitle: 'Atraso operacional',
      );
    }

    if (type == 'systemError') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.operational,
        variation: -3.5,
        impact: AtlasDigitalTwinImpact.critical,
        riskScore: 84,
        riskTitle: 'Erro do sistema',
      );
    }

    if (priority == 'critical') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.operational,
        variation: -3,
        impact: AtlasDigitalTwinImpact.critical,
        riskScore: 82,
        riskTitle: 'Evento crítico',
      );
    }

    if (priority == 'high') {
      return const _DigitalTwinEventRule(
        area: AtlasDigitalTwinArea.operational,
        variation: -1.5,
        impact: AtlasDigitalTwinImpact.negative,
        riskScore: 62,
        riskTitle: 'Evento de alta prioridade',
      );
    }

    return const _DigitalTwinEventRule(
      area: AtlasDigitalTwinArea.operational,
      variation: 0.1,
      impact: AtlasDigitalTwinImpact.neutral,
      riskScore: 0,
      riskTitle: 'Atualização operacional',
    );
  }
}

class _DigitalTwinEventRule {
  const _DigitalTwinEventRule({
    required this.area,
    required this.variation,
    required this.impact,
    required this.riskScore,
    required this.riskTitle,
  });

  final AtlasDigitalTwinArea area;
  final double variation;
  final AtlasDigitalTwinImpact impact;
  final double riskScore;
  final String riskTitle;
}
