import 'dart:convert';

import 'package:projeto_atlas/core/offline/database/atlas_offline_database.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_reconciliation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

enum DairyDecisionChoice { preferLocal, keepServer }

class DairySavedDecision {
  const DairySavedDecision({
    required this.entityType,
    required this.entityId,
    required this.choice,
    required this.stagedPayload,
    required this.remoteVersion,
    required this.remoteDeleted,
    required this.remotePayload,
    required this.decidedAt,
  });

  final String entityType;
  final String entityId;
  final DairyDecisionChoice choice;
  final Map<String, dynamic> stagedPayload;
  final int remoteVersion;
  final bool remoteDeleted;
  final Map<String, dynamic> remotePayload;
  final DateTime decidedAt;

  String get key => '$entityType:$entityId';

  /// The server snapshot still needs a fresh lookup before any future send.
  bool matchesLocal(DairyReviewItem item) =>
      item.entityType == entityType &&
      item.entityId == entityId &&
      !const {
        DairyReviewStatus.localChanged,
        DairyReviewStatus.localMissing,
        DairyReviewStatus.invalidStage,
        DairyReviewStatus.scopeConflict,
      }.contains(item.status) &&
      DairyRemoteReconciliation.samePayload(
        stagedPayload,
        item.stagedPayload,
      ) &&
      DairyRemoteReconciliation.samePayload(stagedPayload, item.localPayload);
}

/// Stores a producer's preference, not a sync operation. No method here
/// touches the operation queue, cache or legacy dairy source.
class DairySyncDecisionService {
  DairySyncDecisionService({
    Database? database,
    DairyOfflineReviewService? reviewService,
  }) : _database = database,
       _reviewService =
           reviewService ?? DairyOfflineReviewService(database: database);

  final Database? _database;
  final DairyOfflineReviewService _reviewService;

  Future<DairySavedDecision> save({
    required String companyId,
    required String tenantId,
    required String farmId,
    required String userId,
    required DairyRemoteReviewEntry entry,
    required DairyDecisionChoice choice,
    required bool Function() isScopeCurrent,
  }) async {
    _scope(companyId, tenantId, farmId, isScopeCurrent);
    if (userId.trim().isEmpty ||
        !entry.local.entityId.startsWith('$farmId:') ||
        entry.local.entityType != entry.remote.key.entityType ||
        entry.local.entityId != entry.remote.key.entityId ||
        !const {
          DairyRemoteReviewStatus.absentOnServer,
          DairyRemoteReviewStatus.differsOnServer,
          DairyRemoteReviewStatus.deletedOnServer,
        }.contains(entry.status)) {
      throw StateError('Este registro de Leite não admite decisão agora.');
    }
    final remote = entry.remote;
    if ((remote.found && remote.version <= 0) ||
        (!remote.found &&
            (remote.version != 0 ||
                remote.deleted ||
                remote.payload.isNotEmpty))) {
      throw StateError('Estado remoto de Leite inválido.');
    }
    final report = await _reviewService.review(
      companyId: companyId,
      tenantId: tenantId,
      farmId: farmId,
    );
    _scope(companyId, tenantId, farmId, isScopeCurrent);
    final current = report.items
        .where(
          (item) =>
              item.entityType == entry.local.entityType &&
              item.entityId == entry.local.entityId,
        )
        .toList();
    if (current.length != 1 ||
        !DairyRemoteReconciliation.samePayload(
          current.single.stagedPayload,
          entry.local.stagedPayload,
        ) ||
        !DairyRemoteReconciliation.samePayload(
          current.single.localPayload,
          entry.local.stagedPayload,
        )) {
      throw StateError(
        'O registro local mudou. Faça nova conferência antes de decidir.',
      );
    }
    final currentStatus = DairyRemoteReconciliation.compare(
      before: DairyReviewReport([entry.local]),
      after: DairyReviewReport(current),
      remote: [remote],
    ).entries.single.status;
    if (currentStatus != entry.status) {
      throw StateError(
        'A classificação mudou. Faça nova conferência antes de decidir.',
      );
    }
    final db = _database ?? await AtlasOfflineDatabase.instance.database;
    final stageJson = jsonEncode(entry.local.stagedPayload);
    final remoteJson = jsonEncode(remote.payload);
    final now = DateTime.now().toUtc().toIso8601String();
    final choiceValue = choice == DairyDecisionChoice.preferLocal
        ? 'prefer_local'
        : 'keep_server';
    await db.transaction((txn) async {
      _scope(companyId, tenantId, farmId, isScopeCurrent);
      final stage = await txn.query(
        'dairy_sync_stage',
        columns: ['payload_json'],
        where:
            'company_id = ? AND tenant_id = ? AND farm_id = ? AND entity_type = ? AND entity_id = ?',
        whereArgs: [
          companyId,
          tenantId,
          farmId,
          entry.local.entityType,
          entry.local.entityId,
        ],
      );
      if (stage.length != 1 ||
          !_sameJsonText(
            stage.single['payload_json'],
            entry.local.stagedPayload,
          )) {
        throw StateError('A cópia preparada mudou. Faça nova conferência.');
      }
      final queued = await txn.query(
        'operation_queue',
        columns: ['id'],
        where:
            'company_id = ? AND tenant_id = ? AND farm_id = ? AND entity_type = ? AND entity_id = ? AND status IN (?, ?, ?)',
        whereArgs: [
          companyId,
          tenantId,
          farmId,
          entry.local.entityType,
          entry.local.entityId,
          'pending',
          'retry',
          'conflict',
        ],
        limit: 1,
      );
      if (queued.isNotEmpty) {
        throw StateError('Este registro já tem uma operação pendente na fila.');
      }
      final previous = await txn.query(
        'dairy_sync_decision',
        where:
            'company_id = ? AND tenant_id = ? AND farm_id = ? AND entity_type = ? AND entity_id = ?',
        whereArgs: [
          companyId,
          tenantId,
          farmId,
          entry.local.entityType,
          entry.local.entityId,
        ],
      );
      if (previous.isNotEmpty &&
          previous.single['choice'] == choiceValue &&
          _sameJsonText(
            previous.single['stage_payload_json'],
            entry.local.stagedPayload,
          ) &&
          previous.single['remote_version'] == remote.version &&
          previous.single['remote_deleted'] == (remote.deleted ? 1 : 0) &&
          _sameJsonText(
            previous.single['remote_payload_json'],
            remote.payload,
          )) {
        return;
      }
      _scope(companyId, tenantId, farmId, isScopeCurrent);
      await txn.insert('dairy_sync_decision', {
        'company_id': companyId,
        'tenant_id': tenantId,
        'farm_id': farmId,
        'entity_type': entry.local.entityType,
        'entity_id': entry.local.entityId,
        'choice': choiceValue,
        'stage_payload_json': stageJson,
        'remote_version': remote.version,
        'remote_deleted': remote.deleted ? 1 : 0,
        'remote_payload_json': remoteJson,
        'decided_at': now,
        'decided_by': userId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _scope(companyId, tenantId, farmId, isScopeCurrent);
    });
    _scope(companyId, tenantId, farmId, isScopeCurrent);
    final decisions = await list(
      companyId: companyId,
      tenantId: tenantId,
      farmId: farmId,
    );
    return decisions.singleWhere(
      (item) => item.key == '${entry.local.entityType}:${entry.local.entityId}',
    );
  }

  Future<List<DairySavedDecision>> list({
    required String companyId,
    required String tenantId,
    required String farmId,
  }) async {
    final db = _database ?? await AtlasOfflineDatabase.instance.database;
    final rows = await db.query(
      'dairy_sync_decision',
      where: 'company_id = ? AND tenant_id = ? AND farm_id = ?',
      whereArgs: [companyId, tenantId, farmId],
      orderBy: 'entity_type, entity_id',
    );
    return List.unmodifiable(
      rows.map(
        (row) => DairySavedDecision(
          entityType: row['entity_type'].toString(),
          entityId: row['entity_id'].toString(),
          choice: row['choice'] == 'prefer_local'
              ? DairyDecisionChoice.preferLocal
              : DairyDecisionChoice.keepServer,
          stagedPayload: _map(row['stage_payload_json']),
          remoteVersion: (row['remote_version'] as num).toInt(),
          remoteDeleted: row['remote_deleted'] == 1,
          remotePayload: _map(row['remote_payload_json']),
          decidedAt: DateTime.parse(row['decided_at'].toString()),
        ),
      ),
    );
  }

  Future<void> remove({
    required String companyId,
    required String tenantId,
    required String farmId,
    required String entityType,
    required String entityId,
  }) async {
    final db = _database ?? await AtlasOfflineDatabase.instance.database;
    await db.delete(
      'dairy_sync_decision',
      where:
          'company_id = ? AND tenant_id = ? AND farm_id = ? AND entity_type = ? AND entity_id = ?',
      whereArgs: [companyId, tenantId, farmId, entityType, entityId],
    );
  }

  static Map<String, dynamic> _map(Object? json) =>
      Map<String, dynamic>.from(jsonDecode(json.toString()) as Map);

  static bool _sameJsonText(Object? text, Map<String, dynamic>? expected) {
    try {
      return DairyRemoteReconciliation.samePayload(_map(text), expected);
    } catch (_) {
      return false;
    }
  }

  static void _scope(
    String companyId,
    String tenantId,
    String farmId,
    bool Function() isScopeCurrent,
  ) {
    if (companyId.trim().isEmpty ||
        tenantId.trim().isEmpty ||
        farmId.trim().isEmpty ||
        !isScopeCurrent()) {
      throw StateError('Conta ou fazenda mudou; nenhuma decisão foi salva.');
    }
  }
}
