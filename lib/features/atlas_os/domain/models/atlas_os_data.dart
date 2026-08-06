class AtlasOsData {
  const AtlasOsData({
    required this.generatedAt,
    required this.title,
    required this.summary,
    required this.healthScore,
    required this.executionPercent,
    required this.goalProbabilityPercent,
    required this.estimatedMonthlyImpact,
    required this.status,
    required this.modules,
    required this.commands,
    required this.dailyCycle,
    required this.criticalItems,
  });

  final DateTime generatedAt;

  final String title;
  final String summary;

  final double healthScore;
  final double executionPercent;
  final double goalProbabilityPercent;
  final double estimatedMonthlyImpact;

  final AtlasOsStatus status;

  final List<AtlasOsModuleState> modules;
  final List<AtlasOsCommand> commands;
  final List<AtlasOsDailyCycleItem> dailyCycle;
  final List<AtlasOsCriticalItem> criticalItems;

  bool get hasData {
    return modules.isNotEmpty ||
        commands.isNotEmpty ||
        dailyCycle.isNotEmpty ||
        criticalItems.isNotEmpty;
  }

  AtlasOsCommand? get primaryCommand {
    if (commands.isEmpty) {
      return null;
    }

    return commands.first;
  }
}

class AtlasOsModuleState {
  const AtlasOsModuleState({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.score,
    required this.pendingItems,
    required this.criticalItems,
  });

  final String id;
  final String title;
  final String description;

  final AtlasOsModuleStatus status;

  final double score;

  final int pendingItems;
  final int criticalItems;
}

class AtlasOsCommand {
  const AtlasOsCommand({
    required this.position,
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.priority,
    required this.deadlineHours,
    required this.expectedImpact,
    required this.source,
    required this.completed,
  });

  final int position;
  final String id;

  final String title;
  final String description;
  final String farmName;

  final AtlasOsPriority priority;

  final int deadlineHours;

  final String expectedImpact;
  final String source;

  final bool completed;

  AtlasOsCommand copyWith({bool? completed}) {
    return AtlasOsCommand(
      position: position,
      id: id,
      title: title,
      description: description,
      farmName: farmName,
      priority: priority,
      deadlineHours: deadlineHours,
      expectedImpact: expectedImpact,
      source: source,
      completed: completed ?? this.completed,
    );
  }
}

class AtlasOsDailyCycleItem {
  const AtlasOsDailyCycleItem({
    required this.position,
    required this.title,
    required this.description,
    required this.period,
    required this.status,
  });

  final int position;

  final String title;
  final String description;
  final AtlasOsDayPeriod period;

  final AtlasOsCycleStatus status;
}

class AtlasOsCriticalItem {
  const AtlasOsCriticalItem({
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.severity,
    required this.probabilityPercent,
    required this.expectedFinancialImpact,
    required this.recommendation,
  });

  final String id;

  final String title;
  final String description;
  final String farmName;

  final AtlasOsSeverity severity;

  final double probabilityPercent;
  final double expectedFinancialImpact;

  final String recommendation;
}

enum AtlasOsStatus { stable, attention, highRisk, critical }

enum AtlasOsModuleStatus { active, attention, critical, unavailable }

enum AtlasOsPriority { low, medium, high, critical }

enum AtlasOsDayPeriod { morning, afternoon, evening }

enum AtlasOsCycleStatus { pending, inProgress, completed }

enum AtlasOsSeverity { low, medium, high, critical }

String atlasOsStatusLabel(AtlasOsStatus status) {
  switch (status) {
    case AtlasOsStatus.stable:
      return 'Estável';

    case AtlasOsStatus.attention:
      return 'Atenção';

    case AtlasOsStatus.highRisk:
      return 'Risco alto';

    case AtlasOsStatus.critical:
      return 'Crítico';
  }
}

String atlasOsModuleStatusLabel(AtlasOsModuleStatus status) {
  switch (status) {
    case AtlasOsModuleStatus.active:
      return 'Ativo';

    case AtlasOsModuleStatus.attention:
      return 'Atenção';

    case AtlasOsModuleStatus.critical:
      return 'Crítico';

    case AtlasOsModuleStatus.unavailable:
      return 'Indisponível';
  }
}

String atlasOsPriorityLabel(AtlasOsPriority priority) {
  switch (priority) {
    case AtlasOsPriority.low:
      return 'Baixa';

    case AtlasOsPriority.medium:
      return 'Média';

    case AtlasOsPriority.high:
      return 'Alta';

    case AtlasOsPriority.critical:
      return 'Crítica';
  }
}

String atlasOsDayPeriodLabel(AtlasOsDayPeriod period) {
  switch (period) {
    case AtlasOsDayPeriod.morning:
      return 'Manhã';

    case AtlasOsDayPeriod.afternoon:
      return 'Tarde';

    case AtlasOsDayPeriod.evening:
      return 'Noite';
  }
}

String atlasOsCycleStatusLabel(AtlasOsCycleStatus status) {
  switch (status) {
    case AtlasOsCycleStatus.pending:
      return 'Pendente';

    case AtlasOsCycleStatus.inProgress:
      return 'Em andamento';

    case AtlasOsCycleStatus.completed:
      return 'Concluído';
  }
}

String atlasOsSeverityLabel(AtlasOsSeverity severity) {
  switch (severity) {
    case AtlasOsSeverity.low:
      return 'Baixa';

    case AtlasOsSeverity.medium:
      return 'Média';

    case AtlasOsSeverity.high:
      return 'Alta';

    case AtlasOsSeverity.critical:
      return 'Crítica';
  }
}
