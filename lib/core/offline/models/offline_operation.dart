import 'dart:convert';

class OfflineOperation {
  const OfflineOperation({required this.id, required this.idempotencyKey, required this.entityType, required this.entityId, required this.operationType, required this.payload, required this.baseVersion, required this.companyId, required this.tenantId, this.farmId, required this.deviceId, required this.createdAt, this.attempts = 0, this.status = 'pending', this.lastError = ''});
  final String id, idempotencyKey, entityType, entityId, operationType, companyId, tenantId, deviceId, status, lastError;
  final String? farmId;
  final Map<String, dynamic> payload;
  final int baseVersion, attempts;
  final DateTime createdAt;
  Map<String, dynamic> toDatabase() => {'id': id, 'idempotency_key': idempotencyKey, 'entity_type': entityType, 'entity_id': entityId, 'operation_type': operationType, 'payload_json': jsonEncode(payload), 'base_version': baseVersion, 'company_id': companyId, 'tenant_id': tenantId, 'farm_id': farmId, 'device_id': deviceId, 'created_at': createdAt.toUtc().toIso8601String(), 'attempts': attempts, 'status': status, 'last_error': lastError};
  Map<String, dynamic> toApi() => {'operation_id': id, 'idempotency_key': idempotencyKey, 'entity_type': entityType, 'entity_id': entityId, 'operation_type': operationType, 'payload': payload, 'base_version': baseVersion, 'company_id': companyId, 'tenant_id': tenantId, 'farm_id': farmId, 'device_id': deviceId};
  factory OfflineOperation.fromDatabase(Map<String, Object?> row) => OfflineOperation(id: row['id']! as String, idempotencyKey: row['idempotency_key']! as String, entityType: row['entity_type']! as String, entityId: row['entity_id']! as String, operationType: row['operation_type']! as String, payload: Map<String, dynamic>.from(jsonDecode(row['payload_json']! as String) as Map), baseVersion: row['base_version']! as int, companyId: row['company_id']! as String, tenantId: row['tenant_id']! as String, farmId: row['farm_id'] as String?, deviceId: row['device_id']! as String, createdAt: DateTime.parse(row['created_at']! as String), attempts: row['attempts']! as int, status: row['status']! as String, lastError: row['last_error']! as String);
}
