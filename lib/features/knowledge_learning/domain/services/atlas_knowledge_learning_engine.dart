import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/continuous_improvement/domain/models/atlas_improvement_cycle.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/knowledge_learning/domain/models/atlas_knowledge_case.dart';

class AtlasKnowledgeLearningEngine {
  const AtlasKnowledgeLearningEngine();

  List<AtlasKnowledgeCase> learn({
    required AtlasImprovementCycle cycle,
    required AtlasActionPlan plan,
  }) {
    final completed = plan.missions.where(
      (mission) => mission.status == AtlasMissionStatus.completed,
    );

    return completed.map((mission) {
      AtlasImprovementDecision? decision;
      for (final item in cycle.decisions) {
        if (item.area == mission.area) {
          decision = item;
          break;
        }
      }

      final before = decision?.currentValue ?? 0;
      final expected = decision?.expectedGain ?? 0;
      final after = before + expected;
      final success = expected > 0 ||
          decision?.type == AtlasImprovementDecisionType.maintain;
      final responseDays = mission.completedAt == null
          ? mission.dueDate.difference(mission.startDate).inDays.abs()
          : mission.completedAt!.difference(mission.startDate).inDays.abs();

      return AtlasKnowledgeCase(
        id: 'knowledge_${cycle.id}_${mission.id}',
        farmId: cycle.farmId,
        farmName: cycle.farmName,
        createdAt: DateTime.now(),
        area: mission.area,
        problem: decision?.title ?? mission.title,
        intervention: mission.description,
        outcome: success
            ? 'Intervenção concluída com resposta favorável estimada.'
            : 'Intervenção concluída sem ganho mensurável; protocolo requer revisão.',
        beforeValue: before,
        afterValue: after,
        predictedValue: before + expected,
        responseDays: responseDays,
        economicGain: success ? mission.expectedImpact : 0,
        predictedEconomicGain: mission.expectedImpact,
        success: success,
        source: AtlasKnowledgeSource.executionCycle,
        status: success
            ? AtlasKnowledgeStatus.validated
            : AtlasKnowledgeStatus.needsReview,
        recommendationImplemented: true,
        lessons: <String>[
          decision?.explanation ??
              'Acompanhar o indicador após a conclusão da missão.',
          success
              ? 'Manter o protocolo sob monitoramento para confirmar a estabilidade do resultado.'
              : 'Reavaliar diagnóstico, execução, prazo e aderência da equipe.',
        ],
      );
    }).toList();
  }

  AtlasKnowledgeOverview buildOverview(List<AtlasKnowledgeCase> cases) {
    final protocols = <AtlasKnowledgeProtocol>[];

    for (final area in AtlasFarmAuditArea.values) {
      final related = cases.where((item) => item.area == area).toList();
      if (related.isEmpty) continue;

      final successes = related.where((item) => item.success).length;
      final successRate = successes / related.length * 100;
      final response = related.fold<double>(
            0,
            (sum, item) => sum + item.responseDays,
          ) /
          related.length;
      final gain = related.fold<double>(
            0,
            (sum, item) => sum + item.economicGain,
          ) /
          related.length;
      final confidence =
          (45 + related.length * 7 + successRate * 0.35)
              .clamp(45.0, 98.0)
              .toDouble();

      protocols.add(
        AtlasKnowledgeProtocol(
          id: 'protocol_${area.name}',
          area: area,
          title: 'Protocolo de ${atlasFarmAuditAreaLabel(area)}',
          description:
              'Protocolo consolidado a partir de ${related.length} caso(s), com recomendações baseadas nos resultados registrados.',
          caseCount: related.length,
          successRate: successRate,
          averageResponseDays: response,
          averageEconomicGain: gain,
          confidence: confidence,
          lastUpdatedAt: related
              .map((item) => item.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        ),
      );
    }

    protocols.sort((a, b) => b.confidence.compareTo(a.confidence));
    final sortedCases = List<AtlasKnowledgeCase>.from(cases)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AtlasKnowledgeOverview(cases: sortedCases, protocols: protocols);
  }
}
