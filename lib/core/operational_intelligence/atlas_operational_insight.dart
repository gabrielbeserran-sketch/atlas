import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';

class AtlasOperationalInsight {
  const AtlasOperationalInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.priority,
    required this.confidencePercent,
    required this.farmName,
    required this.modules,
    required this.relatedEventIds,
    required this.generatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String recommendation;
  final AtlasCanonicalPriority priority;
  final double confidencePercent;
  final String? farmName;
  final Set<String> modules;
  final List<String> relatedEventIds;
  final DateTime generatedAt;
}
