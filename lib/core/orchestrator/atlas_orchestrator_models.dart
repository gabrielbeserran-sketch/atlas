enum AtlasPipelineStatus { idle, running, success, warning, failed }

class AtlasOrchestratorTask {
  const AtlasOrchestratorTask({
    required this.id,
    required this.name,
    required this.module,
    required this.order,
    required this.enabled,
    required this.status,
    required this.durationMs,
    this.message,
  });

  final String id;
  final String name;
  final String module;
  final int order;
  final bool enabled;
  final AtlasPipelineStatus status;
  final int durationMs;
  final String? message;

  AtlasOrchestratorTask copyWith({
    bool? enabled,
    AtlasPipelineStatus? status,
    int? durationMs,
    String? message,
  }) {
    return AtlasOrchestratorTask(
      id: id,
      name: name,
      module: module,
      order: order,
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      durationMs: durationMs ?? this.durationMs,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'module': module,
    'order': order,
    'enabled': enabled,
    'status': status.name,
    'durationMs': durationMs,
    'message': message,
  };

  factory AtlasOrchestratorTask.fromJson(Map<String, dynamic> json) {
    return AtlasOrchestratorTask(
      id: json['id'] as String,
      name: json['name'] as String,
      module: json['module'] as String,
      order: json['order'] as int,
      enabled: json['enabled'] as bool? ?? true,
      status: AtlasPipelineStatus.values.firstWhere(
        (AtlasPipelineStatus value) => value.name == json['status'],
        orElse: () => AtlasPipelineStatus.idle,
      ),
      durationMs: json['durationMs'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}

class AtlasOrchestratorRun {
  const AtlasOrchestratorRun({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.status,
    required this.successfulTasks,
    required this.totalTasks,
    required this.durationMs,
  });

  final String id;
  final DateTime startedAt;
  final DateTime finishedAt;
  final AtlasPipelineStatus status;
  final int successfulTasks;
  final int totalTasks;
  final int durationMs;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'status': status.name,
    'successfulTasks': successfulTasks,
    'totalTasks': totalTasks,
    'durationMs': durationMs,
  };

  factory AtlasOrchestratorRun.fromJson(Map<String, dynamic> json) {
    return AtlasOrchestratorRun(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: DateTime.parse(json['finishedAt'] as String),
      status: AtlasPipelineStatus.values.firstWhere(
        (AtlasPipelineStatus value) => value.name == json['status'],
        orElse: () => AtlasPipelineStatus.failed,
      ),
      successfulTasks: json['successfulTasks'] as int? ?? 0,
      totalTasks: json['totalTasks'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 0,
    );
  }
}
