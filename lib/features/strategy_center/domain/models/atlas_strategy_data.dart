class AtlasStrategyData {
  const AtlasStrategyData({
    required this.generatedAt,
    required this.title,
    required this.mission,
    required this.summary,
    required this.score,
    required this.status,
    required this.objectives,
    required this.priorities,
    required this.initiatives,
    required this.risks,
    required this.opportunities,
  });

  final DateTime generatedAt;
  final String title;
  final String mission;
  final String summary;
  final double score;
  final AtlasStrategyStatus status;
  final List<AtlasStrategyObjective> objectives;
  final List<AtlasStrategyPriority> priorities;
  final List<AtlasStrategyInitiative> initiatives;
  final List<AtlasStrategyRisk> risks;
  final List<AtlasStrategyOpportunity> opportunities;

  bool get hasData =>
      objectives.isNotEmpty ||
      priorities.isNotEmpty ||
      initiatives.isNotEmpty ||
      risks.isNotEmpty ||
      opportunities.isNotEmpty;
}

class AtlasStrategyObjective {
  const AtlasStrategyObjective({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.progressPercent,
    required this.deadline,
    required this.status,
    required this.priority,
    this.responsibleName = '',
  });

  final String id;
  final String farmName;
  final String title;
  final String description;
  final AtlasStrategyCategory category;
  final double progressPercent;
  final DateTime deadline;
  final AtlasStrategyItemStatus status;
  final AtlasStrategyPriorityLevel priority;
  final String responsibleName;
}

class AtlasStrategyPriority {
  const AtlasStrategyPriority({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.deadline,
    required this.progressPercent,
  });

  final String id;
  final String farmName;
  final String title;
  final String description;
  final AtlasStrategyCategory category;
  final AtlasStrategyPriorityLevel priority;
  final AtlasStrategyItemStatus status;
  final DateTime deadline;
  final double progressPercent;
}

class AtlasStrategyInitiative {
  const AtlasStrategyInitiative({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.progressPercent,
    required this.deadline,
    required this.expectedImpact,
  });

  final String id;
  final String farmName;
  final String title;
  final String description;
  final AtlasStrategyCategory category;
  final AtlasStrategyItemStatus status;
  final double progressPercent;
  final DateTime deadline;
  final String expectedImpact;
}

class AtlasStrategyRisk {
  const AtlasStrategyRisk({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.probability,
    required this.impact,
    required this.mitigation,
  });

  final String id;
  final String farmName;
  final String title;
  final String description;
  final AtlasStrategyCategory category;
  final AtlasStrategyRiskLevel probability;
  final AtlasStrategyRiskLevel impact;
  final String mitigation;

  double get priorityScore => _weight(probability) * _weight(impact).toDouble();

  int _weight(AtlasStrategyRiskLevel level) {
    switch (level) {
      case AtlasStrategyRiskLevel.low:
        return 1;
      case AtlasStrategyRiskLevel.medium:
        return 2;
      case AtlasStrategyRiskLevel.high:
        return 3;
      case AtlasStrategyRiskLevel.critical:
        return 4;
    }
  }
}

class AtlasStrategyOpportunity {
  const AtlasStrategyOpportunity({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.impactValue,
    required this.impactUnit,
    required this.confidencePercent,
    required this.recommendation,
  });

  final String id;
  final String farmName;
  final String title;
  final String description;
  final AtlasStrategyCategory category;
  final double impactValue;
  final String impactUnit;
  final double confidencePercent;
  final String recommendation;
}

class AtlasStrategyInput {
  const AtlasStrategyInput({
    required this.title,
    required this.mission,
    required this.objectives,
    required this.priorities,
    required this.initiatives,
    required this.risks,
    required this.opportunities,
  });

  final String title;
  final String mission;
  final List<AtlasStrategyObjective> objectives;
  final List<AtlasStrategyPriority> priorities;
  final List<AtlasStrategyInitiative> initiatives;
  final List<AtlasStrategyRisk> risks;
  final List<AtlasStrategyOpportunity> opportunities;
}

enum AtlasStrategyCategory {
  production,
  reproduction,
  health,
  finance,
  management,
  people,
  technology,
  sustainability,
  intelligence,
}

enum AtlasStrategyStatus { excellent, adequate, attention, critical }

enum AtlasStrategyItemStatus {
  planned,
  active,
  atRisk,
  overdue,
  completed,
  cancelled,
}

enum AtlasStrategyPriorityLevel { low, medium, high, critical }

enum AtlasStrategyRiskLevel { low, medium, high, critical }

String atlasStrategyCategoryLabel(AtlasStrategyCategory category) {
  switch (category) {
    case AtlasStrategyCategory.production:
      return 'Produção';
    case AtlasStrategyCategory.reproduction:
      return 'Reprodução';
    case AtlasStrategyCategory.health:
      return 'Saúde';
    case AtlasStrategyCategory.finance:
      return 'Financeiro';
    case AtlasStrategyCategory.management:
      return 'Gestão';
    case AtlasStrategyCategory.people:
      return 'Pessoas';
    case AtlasStrategyCategory.technology:
      return 'Tecnologia';
    case AtlasStrategyCategory.sustainability:
      return 'Sustentabilidade';
    case AtlasStrategyCategory.intelligence:
      return 'Inteligência';
  }
}

String atlasStrategyStatusLabel(AtlasStrategyStatus status) {
  switch (status) {
    case AtlasStrategyStatus.excellent:
      return 'Excelente';
    case AtlasStrategyStatus.adequate:
      return 'Adequada';
    case AtlasStrategyStatus.attention:
      return 'Atenção';
    case AtlasStrategyStatus.critical:
      return 'Crítica';
  }
}

String atlasStrategyItemStatusLabel(AtlasStrategyItemStatus status) {
  switch (status) {
    case AtlasStrategyItemStatus.planned:
      return 'Planejado';
    case AtlasStrategyItemStatus.active:
      return 'Em execução';
    case AtlasStrategyItemStatus.atRisk:
      return 'Em risco';
    case AtlasStrategyItemStatus.overdue:
      return 'Atrasado';
    case AtlasStrategyItemStatus.completed:
      return 'Concluído';
    case AtlasStrategyItemStatus.cancelled:
      return 'Cancelado';
  }
}

String atlasStrategyPriorityLabel(AtlasStrategyPriorityLevel priority) {
  switch (priority) {
    case AtlasStrategyPriorityLevel.low:
      return 'Baixa';
    case AtlasStrategyPriorityLevel.medium:
      return 'Média';
    case AtlasStrategyPriorityLevel.high:
      return 'Alta';
    case AtlasStrategyPriorityLevel.critical:
      return 'Crítica';
  }
}

String atlasStrategyRiskLabel(AtlasStrategyRiskLevel level) {
  switch (level) {
    case AtlasStrategyRiskLevel.low:
      return 'Baixo';
    case AtlasStrategyRiskLevel.medium:
      return 'Médio';
    case AtlasStrategyRiskLevel.high:
      return 'Alto';
    case AtlasStrategyRiskLevel.critical:
      return 'Crítico';
  }
}
