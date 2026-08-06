enum AtlasCommandPriority { critical, high, medium, low }

enum AtlasCommandItemStatus { newItem, inProgress, completed, dismissed }

enum AtlasCommandCategory {
  sanitary,
  financial,
  operational,
  reproductive,
  strategic,
  agenda,
  system,
}

class AtlasCommandItem {
  const AtlasCommandItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.sourceModule,
    required this.createdAt,
    this.dueAt,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String description;
  final AtlasCommandCategory category;
  final AtlasCommandPriority priority;
  final AtlasCommandItemStatus status;
  final String sourceModule;
  final DateTime createdAt;
  final DateTime? dueAt;
  final String? actionLabel;

  bool get isOpen =>
      status != AtlasCommandItemStatus.completed &&
      status != AtlasCommandItemStatus.dismissed;

  bool get isOverdue =>
      isOpen && dueAt != null && dueAt!.isBefore(DateTime.now());

  AtlasCommandItem copyWith({
    AtlasCommandItemStatus? status,
  }) {
    return AtlasCommandItem(
      id: id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: status ?? this.status,
      sourceModule: sourceModule,
      createdAt: createdAt,
      dueAt: dueAt,
      actionLabel: actionLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'sourceModule': sourceModule,
      'createdAt': createdAt.toIso8601String(),
      'dueAt': dueAt?.toIso8601String(),
      'actionLabel': actionLabel,
    };
  }

  factory AtlasCommandItem.fromJson(Map<String, dynamic> json) {
    return AtlasCommandItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: AtlasCommandCategory.values.firstWhere(
        (AtlasCommandCategory item) => item.name == json['category'],
        orElse: () => AtlasCommandCategory.system,
      ),
      priority: AtlasCommandPriority.values.firstWhere(
        (AtlasCommandPriority item) => item.name == json['priority'],
        orElse: () => AtlasCommandPriority.medium,
      ),
      status: AtlasCommandItemStatus.values.firstWhere(
        (AtlasCommandItemStatus item) => item.name == json['status'],
        orElse: () => AtlasCommandItemStatus.newItem,
      ),
      sourceModule: json['sourceModule']?.toString() ?? 'Atlas',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      dueAt: DateTime.tryParse(json['dueAt']?.toString() ?? ''),
      actionLabel: json['actionLabel']?.toString(),
    );
  }
}

class AtlasCommandCenterState {
  const AtlasCommandCenterState({
    required this.items,
    required this.lastUpdatedAt,
  });

  final List<AtlasCommandItem> items;
  final DateTime lastUpdatedAt;

  AtlasCommandCenterState copyWith({
    List<AtlasCommandItem>? items,
    DateTime? lastUpdatedAt,
  }) {
    return AtlasCommandCenterState(
      items: items ?? this.items,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

class AtlasDailyBrief {
  const AtlasDailyBrief({
    required this.message,
    required this.criticalCount,
    required this.openCount,
    required this.overdueCount,
    required this.completedCount,
    required this.attentionScore,
  });

  final String message;
  final int criticalCount;
  final int openCount;
  final int overdueCount;
  final int completedCount;
  final int attentionScore;
}
