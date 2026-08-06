class AtlasSyncOperation {
  const AtlasSyncOperation({
    required this.id,
    required this.companyId,
    required this.method,
    required this.endpoint,
    required this.idempotencyKey,
    required this.entityType,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    required this.updatedAt,
    this.farmId,
    this.payload,
    this.entityId,
    this.localVersion,
    this.lastError,
  });

  final String id;
  final String companyId;
  final String? farmId;
  final String method;
  final String endpoint;
  final Map<String, dynamic>? payload;
  final String idempotencyKey;
  final String entityType;
  final String? entityId;
  final String? localVersion;
  final String status;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
}
