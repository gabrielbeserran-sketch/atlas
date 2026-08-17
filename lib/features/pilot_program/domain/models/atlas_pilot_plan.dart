enum AtlasPilotStage {
  selection,
  dataPreparation,
  assistedOperation,
  measurement,
  correction,
  completed,
}

class AtlasPilotMetric {
  const AtlasPilotMetric({
    required this.name,
    required this.baseline,
    required this.target,
    this.current,
  });
  final String name;
  final double baseline;
  final double target;
  final double? current;
  double get progress {
    final span = target - baseline;
    if (span == 0) return current == target ? 1 : 0;
    return (((current ?? baseline) - baseline) / span).clamp(0, 1);
  }
}

class AtlasPilotPlan {
  const AtlasPilotPlan({
    required this.farmName,
    required this.stage,
    required this.metrics,
    required this.risks,
  });
  final String farmName;
  final AtlasPilotStage stage;
  final List<AtlasPilotMetric> metrics;
  final List<String> risks;
  double get averageProgress => metrics.isEmpty
      ? 0
      : metrics.map((e) => e.progress).reduce((a, b) => a + b) / metrics.length;
  bool get readyToClose =>
      stage == AtlasPilotStage.completed &&
      risks.isEmpty &&
      averageProgress >= 1;
  factory AtlasPilotPlan.standard() => const AtlasPilotPlan(
    farmName: 'Fazenda piloto a selecionar',
    stage: AtlasPilotStage.selection,
    metrics: [
      AtlasPilotMetric(
        name: 'Animais identificados (%)',
        baseline: 0,
        target: 100,
        current: 0,
      ),
      AtlasPilotMetric(
        name: 'Registros sincronizados (%)',
        baseline: 0,
        target: 100,
        current: 0,
      ),
      AtlasPilotMetric(
        name: 'Usuários treinados (%)',
        baseline: 0,
        target: 100,
        current: 0,
      ),
    ],
    risks: ['Selecionar fazenda e responsável técnico'],
  );
}
