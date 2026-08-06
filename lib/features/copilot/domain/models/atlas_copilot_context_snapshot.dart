class AtlasCopilotContextSnapshot {
  const AtlasCopilotContextSnapshot({
    required this.contextLabel,
    required this.modeLabel,
    required this.contextScore,
    required this.confidencePercent,
    required this.connectedSources,
    required this.activeSignals,
    required this.recommendedPrompts,
    required this.generatedAt,
  });

  final String contextLabel;
  final String modeLabel;
  final double contextScore;
  final double confidencePercent;
  final List<String> connectedSources;
  final List<String> activeSignals;
  final List<String> recommendedPrompts;
  final DateTime generatedAt;

  bool get hasConnectedData => connectedSources.isNotEmpty;

  String get qualityLabel {
    if (contextScore >= 85) {
      return 'Contexto excelente';
    }
    if (contextScore >= 70) {
      return 'Contexto consistente';
    }
    if (contextScore >= 50) {
      return 'Contexto parcial';
    }
    return 'Contexto limitado';
  }
}
