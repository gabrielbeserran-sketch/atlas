enum AtlasIntegrationType {
  csv,
  excel,
  scale,
  rfid,
  weather,
  financial,
  erp,
  api,
}

enum AtlasConnectionStatus { connected, attention, disconnected }

class AtlasIntegrationConnection {
  const AtlasIntegrationConnection({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.lastSyncAt,
    required this.autoSync,
    required this.recordsProcessed,
    this.notes = '',
  });
  final String id;
  final String name;
  final AtlasIntegrationType type;
  final AtlasConnectionStatus status;
  final DateTime? lastSyncAt;
  final bool autoSync;
  final int recordsProcessed;
  final String notes;

  AtlasIntegrationConnection copyWith({
    String? name,
    AtlasIntegrationType? type,
    AtlasConnectionStatus? status,
    DateTime? lastSyncAt,
    bool? autoSync,
    int? recordsProcessed,
    String? notes,
  }) => AtlasIntegrationConnection(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    status: status ?? this.status,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    autoSync: autoSync ?? this.autoSync,
    recordsProcessed: recordsProcessed ?? this.recordsProcessed,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'status': status.name,
    'lastSyncAt': lastSyncAt?.toIso8601String(),
    'autoSync': autoSync,
    'recordsProcessed': recordsProcessed,
    'notes': notes,
  };
  factory AtlasIntegrationConnection.fromJson(Map<String, dynamic> json) =>
      AtlasIntegrationConnection(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        type: AtlasIntegrationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AtlasIntegrationType.api,
        ),
        status: AtlasConnectionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AtlasConnectionStatus.disconnected,
        ),
        lastSyncAt: json['lastSyncAt'] == null
            ? null
            : DateTime.tryParse(json['lastSyncAt'] as String),
        autoSync: json['autoSync'] as bool? ?? false,
        recordsProcessed: json['recordsProcessed'] as int? ?? 0,
        notes: json['notes'] as String? ?? '',
      );
}
