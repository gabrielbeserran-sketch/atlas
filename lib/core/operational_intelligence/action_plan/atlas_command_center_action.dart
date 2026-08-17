import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';

class AtlasCommandCenterAction {
  const AtlasCommandCenterAction({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendedAction,
    required this.priority,
    required this.status,
    required this.farmName,
    required this.sourceModule,
    required this.sourceEventId,
    required this.createdAt,
    required this.updatedAt,
    required this.dueAt,
    required this.completedAt,
    required this.notes,
    required this.responsibleName,
    this.responsibleId,
    required this.progressPercent,
    required this.expectedFinancialImpact,
  });

  final String id;
  final String title;
  final String description;
  final String recommendedAction;
  final AtlasCanonicalPriority priority;
  final AtlasCanonicalStatus status;
  final String? farmName;
  final String sourceModule;
  final String? sourceEventId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String notes;
  final String responsibleName;
  final String? responsibleId;
  final int progressPercent;
  final double expectedFinancialImpact;

  bool get hasResponsible => responsibleName.trim().isNotEmpty;

  bool get isCompleted => status == AtlasCanonicalStatus.completed;

  bool get isOpen =>
      status == AtlasCanonicalStatus.pending ||
      status == AtlasCanonicalStatus.inProgress ||
      status == AtlasCanonicalStatus.blocked;

  bool get isCancelled => status == AtlasCanonicalStatus.cancelled;

  Duration? get remainingTime {
    final dueDate = dueAt;

    if (dueDate == null || isCompleted || isCancelled) {
      return null;
    }

    return dueDate.difference(DateTime.now());
  }

  bool get isOverdue {
    final dueDate = dueAt;

    if (dueDate == null || isCompleted) {
      return false;
    }

    return dueDate.isBefore(DateTime.now());
  }

  AtlasCommandCenterAction copyWith({
    String? title,
    String? description,
    String? recommendedAction,
    AtlasCanonicalPriority? priority,
    AtlasCanonicalStatus? status,
    String? farmName,
    bool replaceFarmName = false,
    String? sourceModule,
    String? sourceEventId,
    bool replaceSourceEventId = false,
    DateTime? updatedAt,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? notes,
    String? responsibleName,
    String? responsibleId,
    bool clearResponsibleId = false,
    int? progressPercent,
    double? expectedFinancialImpact,
  }) {
    return AtlasCommandCenterAction(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      farmName: replaceFarmName ? farmName : this.farmName,
      sourceModule: sourceModule ?? this.sourceModule,
      sourceEventId: replaceSourceEventId ? sourceEventId : this.sourceEventId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      responsibleName: responsibleName ?? this.responsibleName,
      responsibleId: clearResponsibleId
          ? null
          : responsibleId ?? this.responsibleId,
      progressPercent: (progressPercent ?? this.progressPercent).clamp(0, 100),
      expectedFinancialImpact:
          expectedFinancialImpact ?? this.expectedFinancialImpact,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'recommendedAction': recommendedAction,
      'priority': priority.name,
      'status': status.name,
      'farmName': farmName,
      'sourceModule': sourceModule,
      'sourceEventId': sourceEventId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueAt': dueAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'responsibleName': responsibleName,
      'responsibleId': responsibleId,
      'progressPercent': progressPercent,
      'expectedFinancialImpact': expectedFinancialImpact,
    };
  }

  factory AtlasCommandCenterAction.fromMap(Map<String, dynamic> map) {
    return AtlasCommandCenterAction(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      recommendedAction: map['recommendedAction']?.toString() ?? '',
      priority: _priorityFromName(map['priority']?.toString()),
      status: _statusFromName(map['status']?.toString()),
      farmName: map['farmName']?.toString(),
      sourceModule: map['sourceModule']?.toString() ?? 'command_center',
      sourceEventId: map['sourceEventId']?.toString(),
      createdAt: _dateFromValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFromValue(map['updatedAt']) ?? DateTime.now(),
      dueAt: _dateFromValue(map['dueAt']),
      completedAt: _dateFromValue(map['completedAt']),
      notes: map['notes']?.toString() ?? '',
      responsibleName: map['responsibleName']?.toString() ?? '',
      responsibleId: map['responsibleId']?.toString(),
      progressPercent: _intFromValue(map['progressPercent']).clamp(0, 100),
      expectedFinancialImpact: _doubleFromValue(map['expectedFinancialImpact']),
    );
  }

  static AtlasCanonicalPriority _priorityFromName(String? name) {
    return AtlasCanonicalPriority.values.firstWhere(
      (value) => value.name == name,
      orElse: () => AtlasCanonicalPriority.medium,
    );
  }

  static AtlasCanonicalStatus _statusFromName(String? name) {
    return AtlasCanonicalStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => AtlasCanonicalStatus.pending,
    );
  }

  static int _intFromValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleFromValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _dateFromValue(dynamic value) {
    final text = value?.toString();

    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
