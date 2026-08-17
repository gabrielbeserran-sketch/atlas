class AtlasQualityCheck {
  const AtlasQualityCheck({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.completed,
    required this.critical,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final bool completed;
  final bool critical;
  final DateTime? completedAt;

  AtlasQualityCheck copyWith({bool? completed, DateTime? completedAt}) {
    return AtlasQualityCheck(
      id: id,
      title: title,
      description: description,
      category: category,
      completed: completed ?? this.completed,
      critical: critical,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'completed': completed,
    'critical': critical,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory AtlasQualityCheck.fromJson(Map<String, dynamic> json) {
    return AtlasQualityCheck(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      completed: json['completed'] as bool? ?? false,
      critical: json['critical'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'] as String),
    );
  }
}

class AtlasQualityIncident {
  const AtlasQualityIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.module,
    required this.severity,
    required this.createdAt,
    required this.resolved,
    this.resolvedAt,
  });

  final String id;
  final String title;
  final String description;
  final String module;
  final String severity;
  final DateTime createdAt;
  final bool resolved;
  final DateTime? resolvedAt;

  AtlasQualityIncident copyWith({bool? resolved, DateTime? resolvedAt}) {
    return AtlasQualityIncident(
      id: id,
      title: title,
      description: description,
      module: module,
      severity: severity,
      createdAt: createdAt,
      resolved: resolved ?? this.resolved,
      resolvedAt: resolvedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'module': module,
    'severity': severity,
    'createdAt': createdAt.toIso8601String(),
    'resolved': resolved,
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory AtlasQualityIncident.fromJson(Map<String, dynamic> json) {
    return AtlasQualityIncident(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      module: json['module'] as String,
      severity: json['severity'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolved: json['resolved'] as bool? ?? false,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.tryParse(json['resolvedAt'] as String),
    );
  }
}

class AtlasQualityState {
  const AtlasQualityState({
    required this.checks,
    required this.incidents,
    required this.lastReviewAt,
  });

  final List<AtlasQualityCheck> checks;
  final List<AtlasQualityIncident> incidents;
  final DateTime lastReviewAt;

  AtlasQualityState copyWith({
    List<AtlasQualityCheck>? checks,
    List<AtlasQualityIncident>? incidents,
    DateTime? lastReviewAt,
  }) {
    return AtlasQualityState(
      checks: checks ?? this.checks,
      incidents: incidents ?? this.incidents,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
    );
  }
}
