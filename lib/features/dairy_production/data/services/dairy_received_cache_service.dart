import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:projeto_atlas/core/offline/database/atlas_offline_database.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';

/// Exposes the last page received from the server without importing it into
/// the producer's local history or using it in indicators.
class DairyReceivedCacheService {
  DairyReceivedCacheService({Database? database}) : _database = database;

  final Database? _database;

  Future<List<DairyReceivedCacheRecord>> load({
    required String companyId,
    required String tenantId,
    required String farmId,
    Set<String> locallyPresentKeys = const <String>{},
  }) async {
    if (companyId.trim().isEmpty ||
        tenantId.trim().isEmpty ||
        farmId.trim().isEmpty) {
      throw StateError('Empresa, tenant e fazenda são obrigatórios.');
    }
    final db = _database ?? await AtlasOfflineDatabase.instance.database;
    final rows = await db.query(
      'entity_cache',
      where: 'company_id = ? AND farm_id = ? AND entity_type IN (?, ?)',
      whereArgs: <Object?>[
        companyId,
        farmId,
        'dairy_daily_production',
        'dairy_herd_snapshot',
      ],
      orderBy: 'updated_at DESC',
    );
    final received = <DairyReceivedCacheRecord>[];
    for (final row in rows) {
      final version = (row['version'] as num?)?.toInt();
      if (row['tenant_id'] != tenantId ||
          row['deleted'] != 0 ||
          version == null ||
          version <= 0) {
        continue;
      }
      final type = row['entity_type']?.toString() ?? '';
      final id = row['entity_id']?.toString() ?? '';
      final key = '$type:$id';
      if (locallyPresentKeys.contains(key)) continue;
      final payload = _decode(row['payload_json']);
      if (payload == null || payload['farm_id'] != farmId) continue;
      try {
        if (type == 'dairy_daily_production') {
          final data = DairyDailyProductionData.fromMap(payload);
          data.validateForSave();
          if (DairyOfflineStageService.entityId(farmId, data.date) != id) {
            continue;
          }
          received.add(
            DairyReceivedCacheRecord(
              entityType: type,
              entityId: id,
              version: version,
              receivedAt: _date(row['updated_at']),
              production: data,
            ),
          );
        } else if (type == 'dairy_herd_snapshot') {
          final data = DairyHerdSnapshotData.fromMap(payload);
          if (DairyOfflineStageService.entityId(farmId, data.date) != id) {
            continue;
          }
          received.add(
            DairyReceivedCacheRecord(
              entityType: type,
              entityId: id,
              version: version,
              receivedAt: _date(row['updated_at']),
              snapshot: data,
            ),
          );
        }
      } on FormatException {
        // Never turn malformed cache data into apparently valid farm history.
      }
    }
    return List.unmodifiable(received);
  }

  static Map<String, dynamic>? _decode(Object? value) {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(value?.toString() ?? '') as Map,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

class DairyReceivedCacheRecord {
  const DairyReceivedCacheRecord({
    required this.entityType,
    required this.entityId,
    required this.version,
    required this.receivedAt,
    this.production,
    this.snapshot,
  });

  final String entityType;
  final String entityId;
  final int version;
  final DateTime receivedAt;
  final DairyDailyProductionData? production;
  final DairyHerdSnapshotData? snapshot;

  DateTime get date => production?.date ?? snapshot!.date;
}
