enum AtlasCanonicalPriority {
  low,
  medium,
  high,
  critical,
}

enum AtlasCanonicalStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  blocked,
}

enum AtlasCanonicalHorizon {
  today,
  week,
  month,
  quarter,
  longTerm,
}

enum AtlasCanonicalRisk {
  low,
  medium,
  high,
  critical,
}

enum AtlasCanonicalConfidenceLevel {
  low,
  medium,
  high,
  veryHigh,
}

String atlasCanonicalPriorityLabel(AtlasCanonicalPriority value) {
  switch (value) {
    case AtlasCanonicalPriority.low:
      return 'Baixa';
    case AtlasCanonicalPriority.medium:
      return 'Média';
    case AtlasCanonicalPriority.high:
      return 'Alta';
    case AtlasCanonicalPriority.critical:
      return 'Crítica';
  }
}

String atlasCanonicalStatusLabel(AtlasCanonicalStatus value) {
  switch (value) {
    case AtlasCanonicalStatus.pending:
      return 'Pendente';
    case AtlasCanonicalStatus.inProgress:
      return 'Em andamento';
    case AtlasCanonicalStatus.completed:
      return 'Concluído';
    case AtlasCanonicalStatus.cancelled:
      return 'Cancelado';
    case AtlasCanonicalStatus.blocked:
      return 'Bloqueado';
  }
}

String atlasCanonicalHorizonLabel(AtlasCanonicalHorizon value) {
  switch (value) {
    case AtlasCanonicalHorizon.today:
      return 'Hoje';
    case AtlasCanonicalHorizon.week:
      return 'Esta semana';
    case AtlasCanonicalHorizon.month:
      return 'Este mês';
    case AtlasCanonicalHorizon.quarter:
      return 'Este trimestre';
    case AtlasCanonicalHorizon.longTerm:
      return 'Longo prazo';
  }
}
