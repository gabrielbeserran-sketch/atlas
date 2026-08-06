import 'dart:convert';

enum AtlasSyncStatus { pending, syncing, synced, failed, conflict }

enum AtlasSyncPriority { low, normal, high, critical }

class AtlasSyncItem {
  const AtlasSyncItem({
    required this.id,
    required this.module,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.priority,
    required this.attempts,
    required this.payload,
    this.lastError,
  });

  final String id;
  final String module;
  final String entityType;
  final String entityId;
  final String operation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AtlasSyncStatus status;
  final AtlasSyncPriority priority;
  final int attempts;
  final Map<String, dynamic> payload;
  final String? lastError;

  AtlasSyncItem copyWith({
    AtlasSyncStatus? status,
    int? attempts,
    DateTime? updatedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return AtlasSyncItem(
      id: id,
      module: module,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      priority: priority,
      attempts: attempts ?? this.attempts,
      payload: payload,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'module': module,
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'status': status.name,
        'priority': priority.name,
        'attempts': attempts,
        'payload': payload,
        'lastError': lastError,
      };

  factory AtlasSyncItem.fromJson(Map<String, dynamic> json) {
    return AtlasSyncItem(
      id: json['id'] as String? ?? '',
      module: json['module'] as String? ?? 'Sistema',
      entityType: json['entityType'] as String? ?? 'registro',
      entityId: json['entityId'] as String? ?? '',
      operation: json['operation'] as String? ?? 'update',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      status: AtlasSyncStatus.values.firstWhere(
        (AtlasSyncStatus value) => value.name == json['status'],
        orElse: () => AtlasSyncStatus.pending,
      ),
      priority: AtlasSyncPriority.values.firstWhere(
        (AtlasSyncPriority value) => value.name == json['priority'],
        orElse: () => AtlasSyncPriority.normal,
      ),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? <String, dynamic>{}),
      lastError: json['lastError'] as String?,
    );
  }
}

class AtlasSyncSettings {
  const AtlasSyncSettings({
    required this.online,
    required this.automaticSync,
    required this.wifiOnly,
    required this.lastSyncAt,
  });

  final bool online;
  final bool automaticSync;
  final bool wifiOnly;
  final DateTime? lastSyncAt;

  AtlasSyncSettings copyWith({
    bool? online,
    bool? automaticSync,
    bool? wifiOnly,
    DateTime? lastSyncAt,
  }) {
    return AtlasSyncSettings(
      online: online ?? this.online,
      automaticSync: automaticSync ?? this.automaticSync,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'online': online,
        'automaticSync': automaticSync,
        'wifiOnly': wifiOnly,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
      };

  factory AtlasSyncSettings.fromJson(Map<String, dynamic> json) {
    return AtlasSyncSettings(
      online: json['online'] as bool? ?? true,
      automaticSync: json['automaticSync'] as bool? ?? true,
      wifiOnly: json['wifiOnly'] as bool? ?? false,
      lastSyncAt: DateTime.tryParse(json['lastSyncAt'] as String? ?? ''),
    );
  }
}

class AtlasSyncState {
  const AtlasSyncState({required this.items, required this.settings});

  final List<AtlasSyncItem> items;
  final AtlasSyncSettings settings;

  String encodeItems() => jsonEncode(items.map((AtlasSyncItem item) => item.toJson()).toList());
}

class AtlasSyncSummary {
  const AtlasSyncSummary({
    required this.total,
    required this.pending,
    required this.synced,
    required this.failed,
    required this.conflicts,
    required this.successRate,
    required this.modulesWithPendingItems,
  });

  final int total;
  final int pending;
  final int synced;
  final int failed;
  final int conflicts;
  final double successRate;
  final int modulesWithPendingItems;
}
