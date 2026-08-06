import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/services/atlas_canonical_operations_service.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_context_snapshot.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';

class AtlasCopilotContextService {
  const AtlasCopilotContextService();

  AtlasCopilotContextSnapshot build({
    required String contextLabel,
    required bool hasFarmContext,
    required bool hasOperationBrief,
    required List<String> suggestedQuestions,
    AtlasExecutiveBrainData? executiveBrainData,
    AtlasCanonicalOperationsData? canonicalOperations,
  }) {
    final connectedSources = <String>[];
    final activeSignals = <String>[];

    if (hasFarmContext) {
      connectedSources.add('Inteligência da propriedade');
      activeSignals.add('Análise individual da fazenda ativa');
    }

    if (hasOperationBrief) {
      connectedSources.add('Inteligência consolidada');
      activeSignals.add('Resumo executivo da operação disponível');
    }

    if (canonicalOperations != null) {
      connectedSources.add('Operações canônicas');

      final pendingActions = canonicalOperations.actions.where((action) {
        return action.status != AtlasCanonicalStatus.completed &&
            action.status != AtlasCanonicalStatus.cancelled;
      }).toList();
      final criticalActions = pendingActions.where((action) {
        return action.priority == AtlasCanonicalPriority.critical;
      }).length;
      final overdueActions = pendingActions.where((action) {
        return action.isOverdue;
      }).length;
      final activeAlerts = canonicalOperations.alerts.where((alert) {
        return alert.status != AtlasCanonicalStatus.completed &&
            alert.status != AtlasCanonicalStatus.cancelled;
      }).toList();
      final criticalAlerts = activeAlerts.where((alert) {
        return alert.risk == AtlasCanonicalRisk.critical ||
            alert.priority == AtlasCanonicalPriority.critical;
      }).length;

      activeSignals.add(
        '${pendingActions.length} ação(ões) canônica(s) pendente(s)',
      );

      if (criticalActions > 0) {
        activeSignals.add('$criticalActions ação(ões) crítica(s)');
      }
      if (overdueActions > 0) {
        activeSignals.add('$overdueActions ação(ões) vencida(s)');
      }
      if (activeAlerts.isNotEmpty) {
        activeSignals.add('${activeAlerts.length} alerta(s) ativo(s)');
      }
      if (criticalAlerts > 0) {
        activeSignals.add('$criticalAlerts alerta(s) crítico(s)');
      }
    }

    if (executiveBrainData != null) {
      connectedSources.add('Executive Brain');

      if (executiveBrainData.officialDecision != null) {
        activeSignals.add(
          'Decisão oficial: ${executiveBrainData.officialDecision!.title}',
        );
      }

      if (executiveBrainData.conflicts.isNotEmpty) {
        activeSignals.add(
          '${executiveBrainData.conflicts.length} conflito(s) estratégico(s)',
        );
      }

      if (executiveBrainData.dailyPlan.isNotEmpty) {
        activeSignals.add(
          '${executiveBrainData.dailyPlan.length} ação(ões) no plano diário',
        );
      }
    }

    final sourceScore = connectedSources.length * 22.0;
    final signalScore = activeSignals.length * 6.0;
    final brainScore = executiveBrainData == null
        ? 0.0
        : executiveBrainData.brainScore * 0.25;

    final contextScore = (20.0 + sourceScore + signalScore + brainScore)
        .clamp(0.0, 100.0)
        .toDouble();

    final confidence = executiveBrainData?.confidencePercent ??
        (hasFarmContext || hasOperationBrief ? 78.0 : 42.0);

    return AtlasCopilotContextSnapshot(
      contextLabel: contextLabel,
      modeLabel: hasFarmContext
          ? 'Consultoria por propriedade'
          : hasOperationBrief
              ? 'Consultoria consolidada'
              : 'Modo exploratório',
      contextScore: contextScore,
      confidencePercent: confidence.clamp(0.0, 100.0).toDouble(),
      connectedSources: connectedSources,
      activeSignals: activeSignals,
      recommendedPrompts: suggestedQuestions.take(4).toList(),
      generatedAt: DateTime.now(),
    );
  }
}
