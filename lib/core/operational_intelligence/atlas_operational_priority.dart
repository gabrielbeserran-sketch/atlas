import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';

class AtlasOperationalPriority {
  const AtlasOperationalPriority({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.score,
    required this.recommendedAction,
    required this.sourceModule,
    required this.farmName,
    required this.entityId,
    required this.occurredAt,
    required this.event,
  });

  final String id;
  final String title;
  final String description;
  final AtlasCanonicalPriority priority;
  final double score;
  final String recommendedAction;
  final String sourceModule;
  final String? farmName;
  final String? entityId;
  final DateTime occurredAt;
  final AtlasOperationalMemoryEntry event;
}
