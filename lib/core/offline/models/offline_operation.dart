import 'dart:convert';

class OfflineOperation {
  const OfflineOperation({
    required this.id,
    required this.idempotencyKey,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.baseVersion,
    required this.companyId,
    required this.tenantId,
    required this.deviceId,
    required this.createdAt,
    this.farmId,
    this.attempts = 0,
    this.status = 'pending',
    this.lastError = '',
    this.nextAttemptAt,
  });

  final String id;
  final String idempotencyKey;
  final String entityType;
  final String entityId;
  final String operationType;
  final Map<String, dynamic> payload;
  final int baseVersion;
  final String companyId;
  final String tenantId;
  final String? farmId;
  final String deviceId;
  final DateTime createdAt;
  final int attempts;
  final String status;
  final String lastError;
  final DateTime? nextAttemptAt;

  bool get canRetry => status == 'pending' || status == 'retry';

  Map<String, Object?> toDatabase() => <String, Object?>{
    'id': id,
    'idempotency_key': idempotencyKey,
    'entity_type': entityType,
    'entity_id': entityId,
    'operation_type': operationType,
    'payload_json': jsonEncode(payload),
    'base_version': baseVersion,
    'company_id': companyId,
    'tenant_id': tenantId,
    'farm_id': farmId,
    'device_id': deviceId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'attempts': attempts,
    'status': status,
    'last_error': lastError,
    'next_attempt_at': nextAttemptAt?.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toApi() => <String, dynamic>{
    'operation_id': id,
    'idempotency_key': idempotencyKey,
    'entity_type': entityType,
    'entity_id': entityId,
    'operation_type': operationType,
    'payload': payload,
    'base_version': baseVersion,
    'company_id': companyId,
    'tenant_id': tenantId,
    'farm_id': farmId,
    'device_id': deviceId,
  };

  factory OfflineOperation.fromDatabase(Map<String, Object?> row) {
    return OfflineOperation(
      id: row['id']?.toString() ?? '',
      idempotencyKey: row['idempotency_key']?.toString() ?? '',
      entityType: row['entity_type']?.toString() ?? '',
      entityId: row['entity_id']?.toString() ?? '',
      operationType: row['operation_type']?.toString() ?? '',
      payload: Map<String, dynamic>.from(
        jsonDecode(row['payload_json']?.toString() ?? '{}') as Map,
      ),
      baseVersion: (row['base_version'] as num?)?.toInt() ?? 0,
      companyId: row['company_id']?.toString() ?? '',
      tenantId: row['tenant_id']?.toString() ?? '',
      farmId: row['farm_id']?.toString(),
      deviceId: row['device_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      attempts: (row['attempts'] as num?)?.toInt() ?? 0,
      status: row['status']?.toString() ?? 'pending',
      lastError: row['last_error']?.toString() ?? '',
      nextAttemptAt: DateTime.tryParse(
        row['next_attempt_at']?.toString() ?? '',
      ),
    );
  }
}
