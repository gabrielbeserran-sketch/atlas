import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_insight.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';

class AtlasCopilotCommandCenterView {
  const AtlasCopilotCommandCenterView({
    required this.generatedAt,
    required this.farmName,
    required this.contextSummary,
    required this.suggestedQuestions,
    required this.priorities,
    required this.insights,
  });

  factory AtlasCopilotCommandCenterView.fromSnapshot(
    AtlasCommandCenterSnapshot snapshot,
  ) {
    final metrics = snapshot.metrics;
    final topPriority = snapshot.topPriority;
    final topInsight = snapshot.topInsight;

    final summaryParts = <String>[
      '${metrics.totalEvents} evento(s) registrados',
      '${metrics.activeModules} módulo(s) ativos',
      '${metrics.criticalEvents} ocorrência(s) crítica(s)',
      '${metrics.highPriorityEvents} ocorrência(s) de alta prioridade',
    ];

    final suggestedQuestions = <String>[
      if (topPriority != null)
        'Como devo agir sobre "${topPriority.title}"?',
      if (topInsight != null)
        'Explique o insight "${topInsight.title}".',
      'Quais são as prioridades da fazenda hoje?',
      'Quais módulos precisam de atenção?',
      'Resuma os acontecimentos dos últimos sete dias.',
    ];

    return AtlasCopilotCommandCenterView(
      generatedAt: snapshot.generatedAt,
      farmName: snapshot.farmName,
      contextSummary: summaryParts.join('. '),
      suggestedQuestions:
          List<String>.unmodifiable(suggestedQuestions),
      priorities:
          List<AtlasOperationalPriority>.unmodifiable(
        snapshot.priorities,
      ),
      insights:
          List<AtlasOperationalInsight>.unmodifiable(
        snapshot.insights,
      ),
    );
  }

  final DateTime generatedAt;
  final String? farmName;
  final String contextSummary;
  final List<String> suggestedQuestions;
  final List<AtlasOperationalPriority> priorities;
  final List<AtlasOperationalInsight> insights;

  String buildPromptContext() {
    final buffer = StringBuffer()
      ..writeln('Contexto operacional do Projeto Atlas:')
      ..writeln('Fazenda: ${farmName ?? 'Operação global'}')
      ..writeln(contextSummary);

    if (priorities.isNotEmpty) {
      buffer.writeln('Principais prioridades:');

      for (final priority in priorities.take(5)) {
        buffer.writeln(
          '- ${priority.title}: ${priority.recommendedAction}',
        );
      }
    }

    if (insights.isNotEmpty) {
      buffer.writeln('Principais insights:');

      for (final insight in insights.take(5)) {
        buffer.writeln(
          '- ${insight.title}: ${insight.description}',
        );
      }
    }

    return buffer.toString().trim();
  }
}
