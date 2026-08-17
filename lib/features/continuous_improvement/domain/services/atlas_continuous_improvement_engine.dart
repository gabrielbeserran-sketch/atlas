import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/continuous_improvement/domain/models/atlas_improvement_cycle.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/performance_center/domain/models/atlas_performance_snapshot.dart';

class AtlasContinuousImprovementEngine {
  const AtlasContinuousImprovementEngine();

  AtlasImprovementCycle generate({
    required AtlasPerformanceSnapshot performance,
    required AtlasFarmAudit audit,
    required AtlasActionPlan plan,
  }) {
    final decisions =
        performance.kpis
            .map((kpi) => _decisionFor(kpi: kpi, plan: plan))
            .toList()
          ..sort(
            (first, second) => _priorityWeight(
              second.priority,
            ).compareTo(_priorityWeight(first.priority)),
          );

    final classification = _classification(
      executionScore: performance.executionScore,
      auditIndex: audit.overallIndex,
      criticalDecisions: decisions
          .where((item) => item.priority == AtlasFarmAuditPriority.critical)
          .length,
    );

    final nextReviewDays = _nextReviewDays(classification);

    return AtlasImprovementCycle(
      id: 'improvement_${DateTime.now().microsecondsSinceEpoch}',
      farmId: audit.farmId,
      farmName: audit.farmName,
      generatedAt: DateTime.now(),
      executionScore: performance.executionScore,
      auditIndex: audit.overallIndex,
      classification: classification,
      summary: _summary(
        performance: performance,
        audit: audit,
        decisions: decisions,
      ),
      decisions: decisions,
      nextReviewDate: DateTime.now().add(Duration(days: nextReviewDays)),
    );
  }

  AtlasImprovementDecision _decisionFor({
    required AtlasPerformanceKpi kpi,
    required AtlasActionPlan plan,
  }) {
    final relatedMissions = plan.missions
        .where((mission) => mission.area == kpi.area)
        .toList();

    final hasOverdue = relatedMissions.any((mission) => mission.isOverdue);

    final completed = relatedMissions.where(
      (mission) => mission.status == AtlasMissionStatus.completed,
    );

    final completedCount = completed.length;
    final variation = kpi.currentValue - kpi.beforeValue;
    final gap = kpi.targetValue - kpi.currentValue;

    AtlasImprovementDecisionType type;
    AtlasFarmAuditPriority priority;
    String explanation;

    if (kpi.currentValue < 45 || hasOverdue && kpi.currentValue < 60) {
      type = AtlasImprovementDecisionType.recalibrate;
      priority = AtlasFarmAuditPriority.critical;
      explanation =
          'O indicador permanece em nível crítico e existem sinais de que o plano atual não está produzindo resposta suficiente.';
    } else if (kpi.trend == AtlasPerformanceTrend.worsening ||
        kpi.currentValue < 60) {
      type = AtlasImprovementDecisionType.correct;
      priority = AtlasFarmAuditPriority.high;
      explanation =
          'O indicador está abaixo da faixa adequada ou apresenta piora, exigindo correção do plano de execução.';
    } else if (kpi.currentValue >= kpi.targetValue &&
        kpi.trend != AtlasPerformanceTrend.worsening) {
      type = AtlasImprovementDecisionType.maintain;
      priority = AtlasFarmAuditPriority.low;
      explanation =
          'O indicador alcançou a meta e deve permanecer sob controle para evitar regressão.';
    } else {
      type = AtlasImprovementDecisionType.monitor;
      priority = gap > 15
          ? AtlasFarmAuditPriority.moderate
          : AtlasFarmAuditPriority.low;
      explanation =
          'O indicador está evoluindo, mas ainda precisa de acompanhamento até alcançar a meta.';
    }

    if (completedCount > 0 &&
        variation <= 0 &&
        type != AtlasImprovementDecisionType.maintain) {
      type = AtlasImprovementDecisionType.recalibrate;
      priority = AtlasFarmAuditPriority.high;
      explanation =
          'Já existem missões concluídas, porém o indicador ainda não apresentou ganho mensurável. O protocolo deve ser recalibrado.';
    }

    return AtlasImprovementDecision(
      id: 'decision_${kpi.area.name}',
      area: kpi.area,
      title: '${atlasImprovementDecisionTypeLabel(type)} ${kpi.title}',
      explanation: explanation,
      type: type,
      priority: priority,
      currentValue: kpi.currentValue,
      targetValue: kpi.targetValue,
      deadlineDays: _deadline(priority),
      expectedGain: gap.clamp(0.0, 40.0).toDouble(),
    );
  }

  AtlasImprovementCycleClassification _classification({
    required double executionScore,
    required double auditIndex,
    required int criticalDecisions,
  }) {
    if (criticalDecisions > 0 || executionScore < 45 || auditIndex < 45) {
      return AtlasImprovementCycleClassification.critical;
    }

    if (executionScore < 65 || auditIndex < 65) {
      return AtlasImprovementCycleClassification.attention;
    }

    if (executionScore >= 85 && auditIndex >= 85) {
      return AtlasImprovementCycleClassification.excellent;
    }

    return AtlasImprovementCycleClassification.controlled;
  }

  String _summary({
    required AtlasPerformanceSnapshot performance,
    required AtlasFarmAudit audit,
    required List<AtlasImprovementDecision> decisions,
  }) {
    final recalibrations = decisions
        .where((item) => item.type == AtlasImprovementDecisionType.recalibrate)
        .length;

    final corrections = decisions
        .where((item) => item.type == AtlasImprovementDecisionType.correct)
        .length;

    final maintained = decisions
        .where((item) => item.type == AtlasImprovementDecisionType.maintain)
        .length;

    return 'A fazenda apresenta Atlas Execution Score de '
        '${performance.executionScore.toStringAsFixed(1)} pontos '
        'e Atlas Farm Audit Index de '
        '${audit.overallIndex.toStringAsFixed(1)} pontos. '
        'O novo ciclo recomenda $recalibrations recalibração(ões), '
        '$corrections correção(ões) e a manutenção de '
        '$maintained indicador(es) que já atingiram desempenho adequado.';
  }

  int _deadline(AtlasFarmAuditPriority priority) {
    switch (priority) {
      case AtlasFarmAuditPriority.critical:
        return 7;
      case AtlasFarmAuditPriority.high:
        return 15;
      case AtlasFarmAuditPriority.moderate:
        return 30;
      case AtlasFarmAuditPriority.low:
        return 45;
    }
  }

  int _priorityWeight(AtlasFarmAuditPriority priority) {
    switch (priority) {
      case AtlasFarmAuditPriority.critical:
        return 4;
      case AtlasFarmAuditPriority.high:
        return 3;
      case AtlasFarmAuditPriority.moderate:
        return 2;
      case AtlasFarmAuditPriority.low:
        return 1;
    }
  }

  int _nextReviewDays(AtlasImprovementCycleClassification classification) {
    switch (classification) {
      case AtlasImprovementCycleClassification.critical:
        return 7;
      case AtlasImprovementCycleClassification.attention:
        return 15;
      case AtlasImprovementCycleClassification.controlled:
        return 30;
      case AtlasImprovementCycleClassification.excellent:
        return 45;
    }
  }
}
