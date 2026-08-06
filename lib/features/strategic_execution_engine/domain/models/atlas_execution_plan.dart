enum AtlasExecutionTaskStatus { planned, inProgress, blocked, completed, delayed }
enum AtlasExecutionPriority { low, medium, high, critical }

typedef AtlasDate = DateTime;

class AtlasExecutionTask {
  const AtlasExecutionTask({
    required this.id,
    required this.title,
    required this.description,
    required this.owner,
    required this.startDate,
    required this.dueDate,
    required this.plannedCost,
    required this.actualCost,
    required this.progress,
    required this.priority,
    required this.status,
    this.dependencyIds = const <String>[],
    this.resourceNames = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final String owner;
  final AtlasDate startDate;
  final AtlasDate dueDate;
  final double plannedCost;
  final double actualCost;
  final double progress;
  final AtlasExecutionPriority priority;
  final AtlasExecutionTaskStatus status;
  final List<String> dependencyIds;
  final List<String> resourceNames;

  AtlasExecutionTask copyWith({
    String? id, String? title, String? description, String? owner,
    AtlasDate? startDate, AtlasDate? dueDate, double? plannedCost,
    double? actualCost, double? progress, AtlasExecutionPriority? priority,
    AtlasExecutionTaskStatus? status, List<String>? dependencyIds,
    List<String>? resourceNames,
  }) => AtlasExecutionTask(
    id: id ?? this.id, title: title ?? this.title,
    description: description ?? this.description, owner: owner ?? this.owner,
    startDate: startDate ?? this.startDate, dueDate: dueDate ?? this.dueDate,
    plannedCost: plannedCost ?? this.plannedCost,
    actualCost: actualCost ?? this.actualCost, progress: progress ?? this.progress,
    priority: priority ?? this.priority, status: status ?? this.status,
    dependencyIds: dependencyIds ?? this.dependencyIds,
    resourceNames: resourceNames ?? this.resourceNames,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id, 'title': title, 'description': description, 'owner': owner,
    'startDate': startDate.toIso8601String(), 'dueDate': dueDate.toIso8601String(),
    'plannedCost': plannedCost, 'actualCost': actualCost, 'progress': progress,
    'priority': priority.name, 'status': status.name,
    'dependencyIds': dependencyIds, 'resourceNames': resourceNames,
  };

  factory AtlasExecutionTask.fromJson(Map<String, dynamic> json) => AtlasExecutionTask(
    id: json['id'] as String, title: json['title'] as String,
    description: (json['description'] as String?) ?? '',
    owner: (json['owner'] as String?) ?? 'Equipe',
    startDate: DateTime.parse(json['startDate'] as String),
    dueDate: DateTime.parse(json['dueDate'] as String),
    plannedCost: (json['plannedCost'] as num?)?.toDouble() ?? 0,
    actualCost: (json['actualCost'] as num?)?.toDouble() ?? 0,
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    priority: AtlasExecutionPriority.values.byName((json['priority'] as String?) ?? 'medium'),
    status: AtlasExecutionTaskStatus.values.byName((json['status'] as String?) ?? 'planned'),
    dependencyIds: List<String>.from((json['dependencyIds'] as List?) ?? const []),
    resourceNames: List<String>.from((json['resourceNames'] as List?) ?? const []),
  );
}

class AtlasExecutionPlan {
  const AtlasExecutionPlan({required this.id, required this.farmId, required this.title, required this.objective, required this.createdAt, required this.tasks});
  final String id;
  final String farmId;
  final String title;
  final String objective;
  final DateTime createdAt;
  final List<AtlasExecutionTask> tasks;

  AtlasExecutionPlan copyWith({String? id, String? farmId, String? title, String? objective, DateTime? createdAt, List<AtlasExecutionTask>? tasks}) => AtlasExecutionPlan(
    id: id ?? this.id, farmId: farmId ?? this.farmId, title: title ?? this.title,
    objective: objective ?? this.objective, createdAt: createdAt ?? this.createdAt,
    tasks: tasks ?? this.tasks,
  );
  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'farmId': farmId, 'title': title, 'objective': objective, 'createdAt': createdAt.toIso8601String(), 'tasks': tasks.map((e) => e.toJson()).toList()};
  factory AtlasExecutionPlan.fromJson(Map<String, dynamic> json) => AtlasExecutionPlan(
    id: json['id'] as String, farmId: (json['farmId'] as String?) ?? '', title: json['title'] as String,
    objective: (json['objective'] as String?) ?? '', createdAt: DateTime.parse(json['createdAt'] as String),
    tasks: ((json['tasks'] as List?) ?? const []).map((e) => AtlasExecutionTask.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );
}
