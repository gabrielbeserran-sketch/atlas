import 'package:uuid/uuid.dart';

import '../models/offline_operation.dart';
import 'offline_repository.dart';

class OfflineMutationService {
  OfflineMutationService({OfflineRepository? repository, Uuid? uuid})
    : _repository = repository ?? OfflineRepository(),
      _uuid = uuid ?? const Uuid();

  final OfflineRepository _repository;
  final Uuid _uuid;

  Future<OfflineOperation> enqueue({
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
    required int baseVersion,
    required String companyId,
    required String tenantId,
    required String deviceId,
    String? farmId,
  }) async {
    if (!const <String>{'create', 'update', 'delete'}.contains(operationType)) {
      throw ArgumentError.value(
        operationType,
        'operationType',
        'Use create, update ou delete.',
      );
    }
    final operationId = _uuid.v4();
    final operation = OfflineOperation(
      id: operationId,
      idempotencyKey: '${companyId}_$operationId',
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      payload: Map<String, dynamic>.unmodifiable(payload),
      baseVersion: baseVersion,
      companyId: companyId,
      tenantId: tenantId,
      farmId: farmId,
      deviceId: deviceId,
      createdAt: DateTime.now().toUtc(),
    );
    await _repository.enqueue(operation);
    return operation;
  }
}
