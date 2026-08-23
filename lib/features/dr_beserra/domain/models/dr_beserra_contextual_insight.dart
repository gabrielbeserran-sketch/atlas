class DrBeserraContextualInsight {
  const DrBeserraContextualInsight({
    required this.title,
    required this.message,
    required this.sources,
    this.routeLabel,
    this.dataSufficient = true,
  });

  final String title;
  final String message;
  final List<String> sources;
  final String? routeLabel;
  final bool dataSufficient;
}
