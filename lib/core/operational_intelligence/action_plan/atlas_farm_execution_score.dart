class AtlasFarmExecutionScore {
  const AtlasFarmExecutionScore({
    required this.score,
    required this.completionComponent,
    required this.progressComponent,
    required this.deadlineComponent,
    required this.responsibilityComponent,
    required this.goalComponent,
    required this.statusLabel,
  });

  final double score;
  final double completionComponent;
  final double progressComponent;
  final double deadlineComponent;
  final double responsibilityComponent;
  final double goalComponent;
  final String statusLabel;
}
