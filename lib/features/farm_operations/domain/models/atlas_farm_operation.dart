enum AtlasOperationType {
  reproduction,
  health,
  weighing,
  nutrition,
  pasture,
  infrastructure,
  herd,
  other,
}

enum AtlasOperationStatus { planned, inProgress, paused, completed, cancelled }

enum AtlasOperationPriority { low, medium, high, critical }

class AtlasFarmOperation {
  const AtlasFarmOperation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.priority,
    required this.responsible,
    required this.team,
    required this.equipment,
    required this.scheduledAt,
    required this.estimatedHours,
    required this.actualHours,
    required this.plannedCost,
    required this.actualCost,
    required this.progress,
    required this.notes,
    this.farmId,
  });

  final String id;
  final String? farmId;
  final String title;
  final String description;
  final AtlasOperationType type;
  final AtlasOperationStatus status;
  final AtlasOperationPriority priority;
  final String responsible;
  final List<String> team;
  final List<String> equipment;
  final DateTime scheduledAt;
  final double estimatedHours;
  final double actualHours;
  final double plannedCost;
  final double actualCost;
  final double progress;
  final String notes;

  bool get isOverdue =>
      status != AtlasOperationStatus.completed &&
      status != AtlasOperationStatus.cancelled &&
      scheduledAt.isBefore(DateTime.now());

  AtlasFarmOperation copyWith({
    String? title,
    String? description,
    AtlasOperationType? type,
    AtlasOperationStatus? status,
    AtlasOperationPriority? priority,
    String? responsible,
    List<String>? team,
    List<String>? equipment,
    DateTime? scheduledAt,
    double? estimatedHours,
    double? actualHours,
    double? plannedCost,
    double? actualCost,
    double? progress,
    String? notes,
  }) => AtlasFarmOperation(
    id: id,
    farmId: farmId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    responsible: responsible ?? this.responsible,
    team: team ?? this.team,
    equipment: equipment ?? this.equipment,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    estimatedHours: estimatedHours ?? this.estimatedHours,
    actualHours: actualHours ?? this.actualHours,
    plannedCost: plannedCost ?? this.plannedCost,
    actualCost: actualCost ?? this.actualCost,
    progress: progress ?? this.progress,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmId': farmId,
    'title': title,
    'description': description,
    'type': type.name,
    'status': status.name,
    'priority': priority.name,
    'responsible': responsible,
    'team': team,
    'equipment': equipment,
    'scheduledAt': scheduledAt.toIso8601String(),
    'estimatedHours': estimatedHours,
    'actualHours': actualHours,
    'plannedCost': plannedCost,
    'actualCost': actualCost,
    'progress': progress,
    'notes': notes,
  };

  factory AtlasFarmOperation.fromJson(Map<String, dynamic> json) =>
      AtlasFarmOperation(
        id: json['id'] as String,
        farmId: json['farmId'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        type: AtlasOperationType.values.byName(
          json['type'] as String? ?? 'other',
        ),
        status: AtlasOperationStatus.values.byName(
          json['status'] as String? ?? 'planned',
        ),
        priority: AtlasOperationPriority.values.byName(
          json['priority'] as String? ?? 'medium',
        ),
        responsible: json['responsible'] as String? ?? '',
        team: List<String>.from(json['team'] as List? ?? const []),
        equipment: List<String>.from(json['equipment'] as List? ?? const []),
        scheduledAt:
            DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
            DateTime.now(),
        estimatedHours: (json['estimatedHours'] as num? ?? 0).toDouble(),
        actualHours: (json['actualHours'] as num? ?? 0).toDouble(),
        plannedCost: (json['plannedCost'] as num? ?? 0).toDouble(),
        actualCost: (json['actualCost'] as num? ?? 0).toDouble(),
        progress: (json['progress'] as num? ?? 0).toDouble(),
        notes: json['notes'] as String? ?? '',
      );
}
