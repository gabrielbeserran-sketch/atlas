import 'atlas_canonical_types.dart';

class AtlasAlertContract {
  const AtlasAlertContract({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.area,
    required this.sourceModule,
    required this.priority,
    required this.risk,
    required this.status,
    required this.dueAt,
    required this.relatedEntityIds,
    required this.recommendedAction,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime createdAt;
  final String title;
  final String description;
  final String area;
  final String sourceModule;
  final AtlasCanonicalPriority priority;
  final AtlasCanonicalRisk risk;
  final AtlasCanonicalStatus status;
  final DateTime? dueAt;
  final List<String> relatedEntityIds;
  final String recommendedAction;

  bool get isOverdue {
    final deadline = dueAt;
    if (deadline == null || status == AtlasCanonicalStatus.completed) {
      return false;
    }
    return DateTime.now().isAfter(deadline);
  }
}
