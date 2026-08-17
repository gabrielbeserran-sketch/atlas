import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasActionPlan {
  const AtlasActionPlan({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.auditId,
    required this.createdAt,
    required this.updatedAt,
    required this.missions,
  });

  final String id;
  final String farmId;
  final String farmName;
  final String auditId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AtlasActionMission> missions;

  int get totalMissions => missions.length;
  int get completedMissions =>
      missions.where((m) => m.status == AtlasMissionStatus.completed).length;
  int get inProgressMissions =>
      missions.where((m) => m.status == AtlasMissionStatus.inProgress).length;
  int get pendingMissions =>
      missions.where((m) => m.status == AtlasMissionStatus.pending).length;
  int get overdueMissions => missions.where((m) => m.isOverdue).length;
  double get progressPercent =>
      totalMissions == 0 ? 0 : completedMissions / totalMissions * 100;
  double get expectedImpact =>
      missions.fold(0, (sum, m) => sum + m.expectedImpact);
  double get realizedImpact => missions
      .where((m) => m.status == AtlasMissionStatus.completed)
      .fold(0, (sum, m) => sum + m.expectedImpact);

  AtlasActionPlan copyWith({
    List<AtlasActionMission>? missions,
    DateTime? updatedAt,
  }) {
    return AtlasActionPlan(
      id: id,
      farmId: farmId,
      farmName: farmName,
      auditId: auditId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      missions: missions ?? this.missions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmId': farmId,
    'farmName': farmName,
    'auditId': auditId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'missions': missions.map((m) => m.toJson()).toList(),
  };

  factory AtlasActionPlan.fromJson(
    Map<String, dynamic> json,
  ) => AtlasActionPlan(
    id: json['id'] as String? ?? '',
    farmId: json['farmId'] as String? ?? '',
    farmName: json['farmName'] as String? ?? 'Fazenda',
    auditId: json['auditId'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    missions: (json['missions'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => AtlasActionMission.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
  );
}

class AtlasActionMission {
  const AtlasActionMission({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.priority,
    required this.status,
    required this.responsible,
    required this.startDate,
    required this.dueDate,
    required this.expectedImpact,
    required this.checklist,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final AtlasFarmAuditArea area;
  final AtlasFarmAuditPriority priority;
  final AtlasMissionStatus status;
  final String responsible;
  final DateTime startDate;
  final DateTime dueDate;
  final double expectedImpact;
  final List<AtlasMissionChecklistItem> checklist;
  final DateTime? completedAt;

  bool get isOverdue =>
      status != AtlasMissionStatus.completed &&
      dueDate.isBefore(DateTime.now());
  int get completedChecklistItems => checklist.where((i) => i.completed).length;
  double get checklistProgress =>
      checklist.isEmpty ? 0 : completedChecklistItems / checklist.length;

  AtlasActionMission copyWith({
    AtlasMissionStatus? status,
    String? responsible,
    List<AtlasMissionChecklistItem>? checklist,
    DateTime? completedAt,
  }) => AtlasActionMission(
    id: id,
    title: title,
    description: description,
    area: area,
    priority: priority,
    status: status ?? this.status,
    responsible: responsible ?? this.responsible,
    startDate: startDate,
    dueDate: dueDate,
    expectedImpact: expectedImpact,
    checklist: checklist ?? this.checklist,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'area': area.name,
    'priority': priority.name,
    'status': status.name,
    'responsible': responsible,
    'startDate': startDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'expectedImpact': expectedImpact,
    'checklist': checklist.map((i) => i.toJson()).toList(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory AtlasActionMission.fromJson(
    Map<String, dynamic> json,
  ) => AtlasActionMission(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    area: AtlasFarmAuditArea.values.firstWhere(
      (e) => e.name == json['area'],
      orElse: () => AtlasFarmAuditArea.operational,
    ),
    priority: AtlasFarmAuditPriority.values.firstWhere(
      (e) => e.name == json['priority'],
      orElse: () => AtlasFarmAuditPriority.moderate,
    ),
    status: AtlasMissionStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => AtlasMissionStatus.pending,
    ),
    responsible: json['responsible'] as String? ?? 'Gestor da fazenda',
    startDate:
        DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
    dueDate:
        DateTime.tryParse(json['dueDate'] as String? ?? '') ??
        DateTime.now().add(const Duration(days: 30)),
    expectedImpact: (json['expectedImpact'] as num?)?.toDouble() ?? 0,
    checklist: (json['checklist'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (i) =>
              AtlasMissionChecklistItem.fromJson(Map<String, dynamic>.from(i)),
        )
        .toList(),
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
  );
}

class AtlasMissionChecklistItem {
  const AtlasMissionChecklistItem({
    required this.id,
    required this.title,
    required this.completed,
  });
  final String id;
  final String title;
  final bool completed;
  AtlasMissionChecklistItem copyWith({bool? completed}) =>
      AtlasMissionChecklistItem(
        id: id,
        title: title,
        completed: completed ?? this.completed,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };
  factory AtlasMissionChecklistItem.fromJson(Map<String, dynamic> json) =>
      AtlasMissionChecklistItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );
}

enum AtlasMissionStatus { pending, inProgress, completed, cancelled }

String atlasMissionStatusLabel(AtlasMissionStatus status) {
  switch (status) {
    case AtlasMissionStatus.pending:
      return 'Pendente';
    case AtlasMissionStatus.inProgress:
      return 'Em andamento';
    case AtlasMissionStatus.completed:
      return 'Concluída';
    case AtlasMissionStatus.cancelled:
      return 'Cancelada';
  }
}
