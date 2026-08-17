enum AtlasOfflineRecordType {
  animal,
  weighing,
  health,
  reproduction,
  operation,
  finance,
  inventory,
  note,
}

enum AtlasOfflineRecordStatus { pending, syncing, synchronized, failed }

class AtlasOfflineRecord {
  const AtlasOfflineRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.payload,
    this.farmId,
    this.attempts = 0,
    this.lastError = '',
  });

  final String id;
  final String title;
  final AtlasOfflineRecordType type;
  final AtlasOfflineRecordStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> payload;
  final String? farmId;
  final int attempts;
  final String lastError;

  AtlasOfflineRecord copyWith({
    String? title,
    AtlasOfflineRecordType? type,
    AtlasOfflineRecordStatus? status,
    DateTime? updatedAt,
    Map<String, dynamic>? payload,
    String? farmId,
    int? attempts,
    String? lastError,
  }) {
    return AtlasOfflineRecord(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payload: payload ?? this.payload,
      farmId: farmId ?? this.farmId,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'payload': payload,
      'farmId': farmId,
      'attempts': attempts,
      'lastError': lastError,
    };
  }

  factory AtlasOfflineRecord.fromJson(Map<String, dynamic> json) {
    return AtlasOfflineRecord(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: AtlasOfflineRecordType.values.firstWhere(
        (AtlasOfflineRecordType value) => value.name == json['type'],
        orElse: () => AtlasOfflineRecordType.note,
      ),
      status: AtlasOfflineRecordStatus.values.firstWhere(
        (AtlasOfflineRecordStatus value) => value.name == json['status'],
        orElse: () => AtlasOfflineRecordStatus.pending,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
      farmId: json['farmId'] as String?,
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['lastError'] as String? ?? '',
    );
  }
}
