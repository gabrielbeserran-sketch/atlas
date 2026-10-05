import 'dart:convert';

import 'package:projeto_atlas/core/offline/database/atlas_offline_database.dart';
import 'package:projeto_atlas/core/offline/models/offline_operation.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_lookup_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_reconciliation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class DairyPromotionResult {
  const DairyPromotionResult(this.operationId, {required this.alreadyQueued});
  final String operationId;
  final bool alreadyQueued;
}

/// The only bridge from the inert producer decision to the generic sync queue.
/// A fresh server lookup and local review precede a single atomic DB write.
class DairySyncPromotionService {
  DairySyncPromotionService({
    Database? database,
    DairyOfflineReviewService? reviewService,
    DairyRemoteLookupService? lookupService,
    Uuid? uuid,
  }) : _database = database,
       _review = reviewService ?? DairyOfflineReviewService(database: database),
       _lookup = lookupService ?? DairyRemoteLookupService(),
       _uuid = uuid ?? const Uuid();

  final Database? _database;
  final DairyOfflineReviewService _review;
  final DairyRemoteLookupService _lookup;
  final Uuid _uuid;

  Future<DairyPromotionResult> approve({
    required String companyId,
    required String tenantId,
    required String farmId,
    required String entityType,
    required String entityId,
    required bool Function() isScopeCurrent,
    required Future<String> Function() resolveDeviceId,
  }) async {
    void ensureScope() {
      if (companyId.trim().isEmpty ||
          tenantId.trim().isEmpty ||
          farmId.trim().isEmpty ||
          !isScopeCurrent()) {
        throw StateError('A conta ou fazenda mudou. Nada foi enfileirado.');
      }
    }

    ensureScope();
    if (!const {
          'dairy_daily_production',
          'dairy_herd_snapshot',
        }.contains(entityType) ||
        !entityId.startsWith('$farmId:')) {
      throw StateError('Identidade de Leite inválida.');
    }
    final db = _database ?? await AtlasOfflineDatabase.instance.database;
    const where =
        'company_id = ? AND tenant_id = ? AND farm_id = ? AND entity_type = ? AND entity_id = ?';
    final args = [companyId, tenantId, farmId, entityType, entityId];
    final decisionRows = await db.query(
      'dairy_sync_decision',
      where: where,
      whereArgs: args,
    );
    ensureScope();
    if (decisionRows.length != 1 ||
        decisionRows.single['choice'] != 'prefer_local') {
      throw StateError('Primeiro salve a preferência por este aparelho.');
    }
    final saved = decisionRows.single;
    final promotedId = saved['promoted_operation_id']?.toString();
    if (promotedId != null) {
      return DairyPromotionResult(promotedId, alreadyQueued: true);
    }
    final stagePayload = _decode(saved['stage_payload_json']);
    final previousRemotePayload = _decode(saved['remote_payload_json']);
    final previousVersion = (saved['remote_version'] as num).toInt();
    final previousDeleted = saved['remote_deleted'] == 1;
    if (stagePayload == null ||
        previousRemotePayload == null ||
        previousVersion < 0) {
      throw StateError('Preferência salva inválida. Revise o registro.');
    }
    final review = await _review.review(
      companyId: companyId,
      tenantId: tenantId,
      farmId: farmId,
    );
    ensureScope();
    final local = review.items
        .where(
          (item) => item.entityType == entityType && item.entityId == entityId,
        )
        .toList();
    if (local.length != 1 || !_safeLocal(local.single, stagePayload)) {
      throw StateError(
        'O registro local mudou. Revise a preferência antes de enviar.',
      );
    }
    if (!await _lookup.supportsLookup(isScopeCurrent: isScopeCurrent)) {
      throw StateError(
        'Este servidor ainda não oferece a conferência de Leite.',
      );
    }
    ensureScope();
    final remote = (await _lookup.lookup(
      farmId: farmId,
      keys: [DairyLookupKey(entityType: entityType, entityId: entityId)],
      isScopeCurrent: isScopeCurrent,
    )).single;
    ensureScope();
    if (remote.version != previousVersion ||
        remote.deleted != previousDeleted ||
        !DairyRemoteReconciliation.samePayload(
          remote.payload,
          previousRemotePayload,
        )) {
      throw StateError(
        'O servidor mudou desde a preferência. Confira a divergência novamente.',
      );
    }
    final deviceId = await resolveDeviceId();
    ensureScope();
    if (deviceId.trim().isEmpty) {
      throw StateError('Dispositivo sem identificação para envio.');
    }
    // Device registration may take a network roundtrip. Read the source again
    // after it so queue insertion follows the freshest available local check.
    final latest = await _review.review(
      companyId: companyId,
      tenantId: tenantId,
      farmId: farmId,
    );
    ensureScope();
    final latestLocal = latest.items
        .where(
          (item) => item.entityType == entityType && item.entityId == entityId,
        )
        .toList();
    if (latestLocal.length != 1 ||
        !_safeLocal(latestLocal.single, stagePayload)) {
      throw StateError('O registro local mudou durante a conferência.');
    }

    final operationId = _uuid.v4();
    final operation = OfflineOperation(
      id: operationId,
      idempotencyKey: '${companyId}_$operationId',
      entityType: entityType,
      entityId: entityId,
      operationType: remote.found ? 'update' : 'create',
      payload: Map.unmodifiable(stagePayload),
      baseVersion: remote.version,
      companyId: companyId,
      tenantId: tenantId,
      farmId: farmId,
      deviceId: deviceId,
      createdAt: DateTime.now().toUtc(),
    );
    var alreadyQueued = false;
    String resultId = operationId;
    await db.transaction((txn) async {
      ensureScope();
      final currentRows = await txn.query(
        'dairy_sync_decision',
        where: where,
        whereArgs: args,
      );
      if (currentRows.length != 1) {
        throw StateError('Preferência retirada durante a aprovação.');
      }
      final current = currentRows.single;
      final existingId = current['promoted_operation_id']?.toString();
      if (existingId != null) {
        alreadyQueued = true;
        resultId = existingId;
        return;
      }
      if (current['choice'] != 'prefer_local' ||
          current['decided_at'] != saved['decided_at'] ||
          !_matchesText(current['stage_payload_json'], stagePayload) ||
          current['remote_version'] != previousVersion ||
          current['remote_deleted'] != (previousDeleted ? 1 : 0) ||
          !_matchesText(
            current['remote_payload_json'],
            previousRemotePayload,
          )) {
        throw StateError('A preferência mudou durante a aprovação.');
      }
      final stage = await txn.query(
        'dairy_sync_stage',
        columns: ['payload_json'],
        where: where,
        whereArgs: args,
      );
      if (stage.length != 1 ||
          !_matchesText(stage.single['payload_json'], stagePayload)) {
        throw StateError('A cópia preparada mudou durante a aprovação.');
      }
      final queued = await txn.query(
        'operation_queue',
        columns: ['id'],
        where: where,
        whereArgs: args,
        limit: 1,
      );
      if (queued.isNotEmpty) {
        throw StateError('Este registro já possui operação na fila.');
      }
      ensureScope();
      await txn.insert('operation_queue', operation.toDatabase());
      final changed = await txn.update(
        'dairy_sync_decision',
        {
          'promoted_operation_id': operationId,
          'promoted_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: '$where AND promoted_operation_id IS NULL',
        whereArgs: args,
      );
      if (changed != 1) {
        throw StateError('A preferência mudou durante a aprovação.');
      }
      ensureScope();
    });
    ensureScope();
    return DairyPromotionResult(resultId, alreadyQueued: alreadyQueued);
  }

  static bool _safeLocal(DairyReviewItem item, Map<String, dynamic> payload) =>
      !const {
        DairyReviewStatus.localChanged,
        DairyReviewStatus.localMissing,
        DairyReviewStatus.invalidStage,
        DairyReviewStatus.scopeConflict,
      }.contains(item.status) &&
      DairyRemoteReconciliation.samePayload(item.stagedPayload, payload) &&
      DairyRemoteReconciliation.samePayload(item.localPayload, payload);

  static Map<String, dynamic>? _decode(Object? text) {
    try {
      return Map<String, dynamic>.from(jsonDecode(text.toString()) as Map);
    } catch (_) {
      return null;
    }
  }

  static bool _matchesText(Object? text, Map<String, dynamic> payload) =>
      DairyRemoteReconciliation.samePayload(_decode(text), payload);
}
