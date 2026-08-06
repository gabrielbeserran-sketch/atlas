import 'atlas_canonical_types.dart';

class AtlasActionContract {
  const AtlasActionContract({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.description,
    required this.area,
    required this.sourceModule,
    required this.sourceReferenceId,
    required this.priority,
    required this.horizon,
    required this.status,
    required this.responsible,
    required this.startDate,
    required this.dueDate,
    required this.expectedImpact,
    required this.expectedFinancialImpact,
    required this.checklist,
    this.completedAt,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String description;
  final String area;
  final String sourceModule;
  final String sourceReferenceId;
  final AtlasCanonicalPriority priority;
  final AtlasCanonicalHorizon horizon;
  final AtlasCanonicalStatus status;
  final String responsible;
  final DateTime startDate;
  final DateTime dueDate;
  final double expectedImpact;
  final double expectedFinancialImpact;
  final List<AtlasActionChecklistContract> checklist;
  final DateTime? completedAt;

  bool get isOverdue {
    return status != AtlasCanonicalStatus.completed &&
        DateTime.now().isAfter(dueDate);
  }

  double get checklistProgress {
    if (checklist.isEmpty) {
      return 0;
    }
    final completed = checklist.where((item) => item.completed).length;
    return completed / checklist.length;
  }
}

class AtlasActionChecklistContract {
  const AtlasActionChecklistContract({
    required this.id,
    required this.title,
    required this.completed,
  });

  final String id;
  final String title;
  final bool completed;
}
