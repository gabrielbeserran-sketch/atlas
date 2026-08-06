import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasAiResponse {
  const AtlasAiResponse({
    required this.generatedAt,
    required this.question,
    required this.intent,
    required this.directAnswer,
    required this.justification,
    required this.evidences,
    required this.actionPlan,
    required this.nextStep,
    required this.confidence,
    required this.level,
    required this.actions,
  });

  final DateTime generatedAt;
  final String question;

  final AtlasAiIntent intent;

  final String directAnswer;
  final String justification;

  final List<AtlasAiEvidence> evidences;
  final List<AtlasAiResponseActionStep> actionPlan;

  final String nextStep;

  final double confidence;
  final AtlasDiagnosticLevel level;

  final List<AtlasAiNavigationAction> actions;

  bool get hasEvidence {
    return evidences.isNotEmpty;
  }

  bool get hasActionPlan {
    return actionPlan.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'question': question,
      'intent': intent.name,
      'directAnswer': directAnswer,
      'justification': justification,
      'evidences': evidences.map((item) {
        return item.toJson();
      }).toList(),
      'actionPlan': actionPlan.map((item) {
        return item.toJson();
      }).toList(),
      'nextStep': nextStep,
      'confidence': confidence,
      'level': level.name,
      'actions': actions.map((item) {
        return item.toJson();
      }).toList(),
    };
  }

  String toPlainText() {
    final buffer = StringBuffer();

    buffer.writeln(directAnswer);
    buffer.writeln();
    buffer.writeln('Por quê?');
    buffer.writeln(justification);

    if (evidences.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Evidências');

      for (final evidence in evidences) {
        buffer.writeln(
          '- ${evidence.label}: ${evidence.value}',
        );
      }
    }

    if (actionPlan.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Plano de ação');

      for (final step in actionPlan) {
        buffer.writeln(
          '${step.position}. ${step.title}: '
          '${step.description}',
        );
      }
    }

    buffer.writeln();
    buffer.writeln('Próximo passo');
    buffer.writeln(nextStep);

    return buffer.toString().trim();
  }
}

class AtlasAiEvidence {
  const AtlasAiEvidence({
    required this.label,
    required this.value,
    required this.description,
    required this.area,
    required this.weight,
  });

  final String label;
  final String value;
  final String description;

  final AtlasFarmAnalysisArea area;

  final double weight;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'description': description,
      'area': area.name,
      'weight': weight,
    };
  }
}

class AtlasAiResponseActionStep {
  const AtlasAiResponseActionStep({
    required this.position,
    required this.title,
    required this.description,
    required this.expectedResult,
    required this.area,
    required this.deadlineDays,
  });

  final int position;

  final String title;
  final String description;
  final String expectedResult;

  final AtlasFarmAnalysisArea area;

  final int deadlineDays;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'title': title,
      'description': description,
      'expectedResult': expectedResult,
      'area': area.name,
      'deadlineDays': deadlineDays,
    };
  }
}

class AtlasAiNavigationAction {
  const AtlasAiNavigationAction({
    required this.id,
    required this.label,
    required this.type,
  });

  final String id;
  final String label;

  final AtlasAiNavigationActionType type;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
    };
  }
}

enum AtlasAiIntent {
  generalSituation,
  mainProblem,
  priority,
  risks,
  opportunities,
  strengths,
  finance,
  herd,
  paddocks,
  inventory,
  agenda,
  shortTermPlan,
  mediumTermPlan,
  longTermPlan,
  predictiveDecision,
  simpleExplanation,
  improveScore,
  actionProgress,
  pendingActions,
  overdueActions,
  completedActions,
  inProgressActions,
  unknown,
}

enum AtlasAiNavigationActionType {
  openDiagnostic,
  openPredictive,
  openFinance,
  openHerd,
  openPaddocks,
  openInventory,
  openAgenda,
}

String atlasAiIntentLabel(
  AtlasAiIntent intent,
) {
  switch (intent) {
    case AtlasAiIntent.generalSituation:
      return 'Situação geral';

    case AtlasAiIntent.mainProblem:
      return 'Problema principal';

    case AtlasAiIntent.priority:
      return 'Prioridade';

    case AtlasAiIntent.risks:
      return 'Riscos';

    case AtlasAiIntent.opportunities:
      return 'Oportunidades';

    case AtlasAiIntent.strengths:
      return 'Pontos fortes';

    case AtlasAiIntent.finance:
      return 'Financeiro';

    case AtlasAiIntent.herd:
      return 'Rebanho';

    case AtlasAiIntent.paddocks:
      return 'Piquetes';

    case AtlasAiIntent.inventory:
      return 'Estoque';

    case AtlasAiIntent.agenda:
      return 'Agenda';

    case AtlasAiIntent.shortTermPlan:
      return 'Plano de 7 dias';

    case AtlasAiIntent.mediumTermPlan:
      return 'Plano de 30 dias';

    case AtlasAiIntent.longTermPlan:
      return 'Plano de 90 dias';

    case AtlasAiIntent.predictiveDecision:
      return 'Decisão preditiva';

    case AtlasAiIntent.simpleExplanation:
      return 'Explicação simples';

    case AtlasAiIntent.improveScore:
      return 'Melhoria do score';

    case AtlasAiIntent.actionProgress:
      return 'Progresso das ações';

    case AtlasAiIntent.pendingActions:
      return 'Ações pendentes';

    case AtlasAiIntent.overdueActions:
      return 'Ações atrasadas';

    case AtlasAiIntent.completedActions:
      return 'Ações concluídas';

    case AtlasAiIntent.inProgressActions:
      return 'Ações em andamento';

    case AtlasAiIntent.unknown:
      return 'Assunto não identificado';
  }
}
