import 'dart:io';

import 'package:projeto_atlas/core/offline/services/offline_mutation_service.dart';
import 'package:projeto_atlas/core/session/atlas_session_controller.dart';
import 'package:projeto_atlas/features/field_operations/domain/models/atlas_field_operation.dart';
import 'package:uuid/uuid.dart';

class AtlasFieldOperationsService {
  AtlasFieldOperationsService({OfflineMutationService? mutationService})
    : _mutationService = mutationService ?? OfflineMutationService();

  final OfflineMutationService _mutationService;
  static const Uuid _uuid = Uuid();

  Future<int> enqueue(
    AtlasSessionController session,
    AtlasFieldOperation operation,
  ) async {
    final current = session.session;
    final farm = session.activeFarm;
    if (current == null || farm == null) {
      throw StateError('Selecione uma fazenda antes de registrar operações.');
    }
    var count = 0;
    for (final sourceId in operation.entityIds) {
      final entityId = sourceId.trim().isEmpty ? _uuid.v4() : sourceId.trim();
      await _mutationService.enqueue(
        entityType: operation.entityType,
        entityId: entityId,
        operationType: operation.operationType,
        payload: <String, dynamic>{
          ...operation.payload,
          'farm_id': farm.id,
          'captured_at': DateTime.now().toUtc().toIso8601String(),
          'captured_by': current.userId,
          'capture_device': Platform.localHostname,
        },
        baseVersion: 0,
        companyId: current.companyId,
        tenantId: current.tenantId,
        farmId: farm.id,
        deviceId: Platform.localHostname,
      );
      count += 1;
    }
    return count;
  }
}
