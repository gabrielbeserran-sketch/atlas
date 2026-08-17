enum AtlasEnterpriseSyncOperationType { create, update, delete, restore }

enum AtlasEnterpriseSyncStatus {
  pending,
  syncing,
  synchronized,
  conflict,
  error,
}

String atlasEnterpriseSyncStatusLabel(AtlasEnterpriseSyncStatus value) {
  switch (value) {
    case AtlasEnterpriseSyncStatus.pending:
      return 'Pendente';
    case AtlasEnterpriseSyncStatus.syncing:
      return 'Sincronizando';
    case AtlasEnterpriseSyncStatus.synchronized:
      return 'Sincronizado';
    case AtlasEnterpriseSyncStatus.conflict:
      return 'Com conflito';
    case AtlasEnterpriseSyncStatus.error:
      return 'Com erro';
  }
}

enum AtlasEnterpriseConflictResolution {
  keepLocal,
  keepRemote,
  merge,
  unresolved,
}

class AtlasEnterpriseSyncOperation {
  const AtlasEnterpriseSyncOperation({
    required this.operationId,
    required this.tenantId,
    required this.companyId,
    required this.farmId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.baseVersion,
    required this.createdAt,
    required this.deviceId,
    required this.status,
    required this.retryCount,
    required this.lastError,
    required this.idempotencyKey,
    required this.lastAttemptAt,
  });

  final String operationId;
  final String tenantId;
  final String companyId;
  final String? farmId;
  final String entityType;
  final String entityId;
  final AtlasEnterpriseSyncOperationType operationType;
  final Map<String, dynamic> payload;
  final int baseVersion;
  final DateTime createdAt;
  final String deviceId;
  final AtlasEnterpriseSyncStatus status;
  final int retryCount;
  final String lastError;
  final String idempotencyKey;
  final DateTime? lastAttemptAt;

  AtlasEnterpriseSyncOperation copyWith({
    AtlasEnterpriseSyncStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? lastAttemptAt,
    Map<String, dynamic>? payload,
    int? baseVersion,
  }) {
    return AtlasEnterpriseSyncOperation(
      operationId: operationId,
      tenantId: tenantId,
      companyId: companyId,
      farmId: farmId,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      payload: payload ?? this.payload,
      baseVersion: baseVersion ?? this.baseVersion,
      createdAt: createdAt,
      deviceId: deviceId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      idempotencyKey: idempotencyKey,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'operationId': operationId,
    'tenantId': tenantId,
    'companyId': companyId,
    'farmId': farmId,
    'entityType': entityType,
    'entityId': entityId,
    'operationType': operationType.name,
    'payload': payload,
    'baseVersion': baseVersion,
    'createdAt': createdAt.toIso8601String(),
    'deviceId': deviceId,
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
    'idempotencyKey': idempotencyKey,
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
  };

  factory AtlasEnterpriseSyncOperation.fromMap(Map<String, dynamic> map) {
    return AtlasEnterpriseSyncOperation(
      operationId: map['operationId']?.toString() ?? '',
      tenantId: map['tenantId']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      farmId: map['farmId']?.toString(),
      entityType: map['entityType']?.toString() ?? '',
      entityId: map['entityId']?.toString() ?? '',
      operationType: AtlasEnterpriseSyncOperationType.values.firstWhere(
        (item) => item.name == map['operationType']?.toString(),
        orElse: () => AtlasEnterpriseSyncOperationType.update,
      ),
      payload: Map<String, dynamic>.from(
        (map['payload'] as Map?) ?? const <String, dynamic>{},
      ),
      baseVersion: (map['baseVersion'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      deviceId: map['deviceId']?.toString() ?? 'local_device',
      status: AtlasEnterpriseSyncStatus.values.firstWhere(
        (item) => item.name == map['status']?.toString(),
        orElse: () => AtlasEnterpriseSyncStatus.pending,
      ),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      lastError: map['lastError']?.toString() ?? '',
      idempotencyKey: map['idempotencyKey']?.toString() ?? '',
      lastAttemptAt: DateTime.tryParse(map['lastAttemptAt']?.toString() ?? ''),
    );
  }
}

class AtlasEnterpriseSyncConflict {
  const AtlasEnterpriseSyncConflict({
    required this.id,
    required this.operationId,
    required this.companyId,
    required this.farmId,
    required this.entityType,
    required this.entityId,
    required this.localVersion,
    required this.remoteVersion,
    required this.localPayload,
    required this.remotePayload,
    required this.detectedAt,
    required this.resolution,
    required this.resolvedAt,
    required this.resolvedBy,
  });

  final String id;
  final String operationId;
  final String companyId;
  final String? farmId;
  final String entityType;
  final String entityId;
  final int localVersion;
  final int remoteVersion;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> remotePayload;
  final DateTime detectedAt;
  final AtlasEnterpriseConflictResolution resolution;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  AtlasEnterpriseSyncConflict copyWith({
    AtlasEnterpriseConflictResolution? resolution,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return AtlasEnterpriseSyncConflict(
      id: id,
      operationId: operationId,
      companyId: companyId,
      farmId: farmId,
      entityType: entityType,
      entityId: entityId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      localPayload: localPayload,
      remotePayload: remotePayload,
      detectedAt: detectedAt,
      resolution: resolution ?? this.resolution,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'operationId': operationId,
    'companyId': companyId,
    'farmId': farmId,
    'entityType': entityType,
    'entityId': entityId,
    'localVersion': localVersion,
    'remoteVersion': remoteVersion,
    'localPayload': localPayload,
    'remotePayload': remotePayload,
    'detectedAt': detectedAt.toIso8601String(),
    'resolution': resolution.name,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolvedBy': resolvedBy,
  };

  factory AtlasEnterpriseSyncConflict.fromMap(Map<String, dynamic> map) {
    return AtlasEnterpriseSyncConflict(
      id: map['id']?.toString() ?? '',
      operationId: map['operationId']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      farmId: map['farmId']?.toString(),
      entityType: map['entityType']?.toString() ?? '',
      entityId: map['entityId']?.toString() ?? '',
      localVersion: (map['localVersion'] as num?)?.toInt() ?? 0,
      remoteVersion: (map['remoteVersion'] as num?)?.toInt() ?? 0,
      localPayload: Map<String, dynamic>.from(
        (map['localPayload'] as Map?) ?? const <String, dynamic>{},
      ),
      remotePayload: Map<String, dynamic>.from(
        (map['remotePayload'] as Map?) ?? const <String, dynamic>{},
      ),
      detectedAt:
          DateTime.tryParse(map['detectedAt']?.toString() ?? '') ??
          DateTime.now(),
      resolution: AtlasEnterpriseConflictResolution.values.firstWhere(
        (item) => item.name == map['resolution']?.toString(),
        orElse: () => AtlasEnterpriseConflictResolution.unresolved,
      ),
      resolvedAt: DateTime.tryParse(map['resolvedAt']?.toString() ?? ''),
      resolvedBy: map['resolvedBy']?.toString(),
    );
  }
}

class AtlasEnterpriseSyncCheckpoint {
  const AtlasEnterpriseSyncCheckpoint({
    required this.companyId,
    required this.cursor,
    required this.lastPulledAt,
    required this.lastPushedAt,
  });

  final String companyId;
  final String cursor;
  final DateTime? lastPulledAt;
  final DateTime? lastPushedAt;

  AtlasEnterpriseSyncCheckpoint copyWith({
    String? cursor,
    DateTime? lastPulledAt,
    DateTime? lastPushedAt,
  }) {
    return AtlasEnterpriseSyncCheckpoint(
      companyId: companyId,
      cursor: cursor ?? this.cursor,
      lastPulledAt: lastPulledAt ?? this.lastPulledAt,
      lastPushedAt: lastPushedAt ?? this.lastPushedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'companyId': companyId,
    'cursor': cursor,
    'lastPulledAt': lastPulledAt?.toIso8601String(),
    'lastPushedAt': lastPushedAt?.toIso8601String(),
  };

  factory AtlasEnterpriseSyncCheckpoint.fromMap(Map<String, dynamic> map) {
    return AtlasEnterpriseSyncCheckpoint(
      companyId: map['companyId']?.toString() ?? '',
      cursor: map['cursor']?.toString() ?? '',
      lastPulledAt: DateTime.tryParse(map['lastPulledAt']?.toString() ?? ''),
      lastPushedAt: DateTime.tryParse(map['lastPushedAt']?.toString() ?? ''),
    );
  }
}

class AtlasEnterpriseSyncSummary {
  const AtlasEnterpriseSyncSummary({
    required this.total,
    required this.pending,
    required this.syncing,
    required this.synchronized,
    required this.conflicts,
    required this.errors,
  });

  final int total;
  final int pending;
  final int syncing;
  final int synchronized;
  final int conflicts;
  final int errors;
}
