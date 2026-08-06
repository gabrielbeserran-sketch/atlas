import 'dart:convert';

enum AtlasHealthStatus { healthy, warning, critical }

enum AtlasLogLevel { info, warning, error }

class AtlasHealthCheck {
  const AtlasHealthCheck({
    required this.id,
    required this.module,
    required this.description,
    required this.status,
    required this.responseTimeMs,
    required this.checkedAt,
  });

  final String id;
  final String module;
  final String description;
  final AtlasHealthStatus status;
  final int responseTimeMs;
  final DateTime checkedAt;

  AtlasHealthCheck copyWith({
    AtlasHealthStatus? status,
    int? responseTimeMs,
    DateTime? checkedAt,
  }) {
    return AtlasHealthCheck(
      id: id,
      module: module,
      description: description,
      status: status ?? this.status,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'module': module,
        'description': description,
        'status': status.name,
        'responseTimeMs': responseTimeMs,
        'checkedAt': checkedAt.toIso8601String(),
      };

  factory AtlasHealthCheck.fromMap(Map<String, dynamic> map) {
    return AtlasHealthCheck(
      id: map['id'] as String? ?? '',
      module: map['module'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: AtlasHealthStatus.values.firstWhere(
        (AtlasHealthStatus item) => item.name == map['status'],
        orElse: () => AtlasHealthStatus.warning,
      ),
      responseTimeMs: map['responseTimeMs'] as int? ?? 0,
      checkedAt: DateTime.tryParse(map['checkedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AtlasSystemLog {
  const AtlasSystemLog({
    required this.id,
    required this.module,
    required this.message,
    required this.level,
    required this.createdAt,
    this.resolved = false,
  });

  final String id;
  final String module;
  final String message;
  final AtlasLogLevel level;
  final DateTime createdAt;
  final bool resolved;

  AtlasSystemLog copyWith({bool? resolved}) {
    return AtlasSystemLog(
      id: id,
      module: module,
      message: message,
      level: level,
      createdAt: createdAt,
      resolved: resolved ?? this.resolved,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'module': module,
        'message': message,
        'level': level.name,
        'createdAt': createdAt.toIso8601String(),
        'resolved': resolved,
      };

  factory AtlasSystemLog.fromMap(Map<String, dynamic> map) {
    return AtlasSystemLog(
      id: map['id'] as String? ?? '',
      module: map['module'] as String? ?? '',
      message: map['message'] as String? ?? '',
      level: AtlasLogLevel.values.firstWhere(
        (AtlasLogLevel item) => item.name == map['level'],
        orElse: () => AtlasLogLevel.info,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      resolved: map['resolved'] as bool? ?? false,
    );
  }
}

class AtlasObservabilityData {
  const AtlasObservabilityData({
    required this.healthChecks,
    required this.logs,
    required this.lastDiagnosticAt,
  });

  final List<AtlasHealthCheck> healthChecks;
  final List<AtlasSystemLog> logs;
  final DateTime? lastDiagnosticAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'healthChecks': healthChecks
            .map((AtlasHealthCheck item) => item.toMap())
            .toList(),
        'logs': logs.map((AtlasSystemLog item) => item.toMap()).toList(),
        'lastDiagnosticAt': lastDiagnosticAt?.toIso8601String(),
      };

  String toJson() => jsonEncode(toMap());

  factory AtlasObservabilityData.fromJson(String source) {
    final Map<String, dynamic> map =
        jsonDecode(source) as Map<String, dynamic>;
    return AtlasObservabilityData(
      healthChecks: (map['healthChecks'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => AtlasHealthCheck.fromMap(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
              ))
          .toList(),
      logs: (map['logs'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => AtlasSystemLog.fromMap(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
              ))
          .toList(),
      lastDiagnosticAt:
          DateTime.tryParse(map['lastDiagnosticAt'] as String? ?? ''),
    );
  }
}
