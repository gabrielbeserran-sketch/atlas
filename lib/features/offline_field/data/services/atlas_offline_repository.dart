import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_offline_record.dart';

class AtlasOfflineRepository {
  static const String _recordsKey = 'atlas_offline_field_records_v1';
  static const String _onlineKey = 'atlas_offline_field_online_v1';
  static const String _autoSyncKey = 'atlas_offline_field_auto_sync_v1';

  Future<List<AtlasOfflineRecord>> loadRecords({String? farmId}) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_recordsKey);

    if (raw == null || raw.isEmpty) {
      final List<AtlasOfflineRecord> seed = _seed(farmId: farmId);
      await saveRecords(seed);
      return seed;
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final List<AtlasOfflineRecord> records = decoded.map(
        (dynamic item) {
          return AtlasOfflineRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        },
      ).toList();

      if (farmId == null) {
        return records;
      }

      return records.where((AtlasOfflineRecord record) {
        return record.farmId == null || record.farmId == farmId;
      }).toList();
    } catch (_) {
      return _seed(farmId: farmId);
    }
  }

  Future<void> saveRecords(List<AtlasOfflineRecord> records) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString(
      _recordsKey,
      jsonEncode(
        records.map((AtlasOfflineRecord record) => record.toJson()).toList(),
      ),
    );
  }

  Future<bool> loadOnlineState() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    return preferences.getBool(_onlineKey) ?? false;
  }

  Future<void> saveOnlineState(bool value) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setBool(_onlineKey, value);
  }

  Future<bool> loadAutoSync() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    return preferences.getBool(_autoSyncKey) ?? true;
  }

  Future<void> saveAutoSync(bool value) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setBool(_autoSyncKey, value);
  }

  List<AtlasOfflineRecord> _seed({String? farmId}) {
    final DateTime now = DateTime.now();

    return <AtlasOfflineRecord>[
      AtlasOfflineRecord(
        id: 'offline_weight_demo',
        title: 'Pesagem do lote 12',
        type: AtlasOfflineRecordType.weighing,
        status: AtlasOfflineRecordStatus.pending,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        payload: const <String, dynamic>{
          'animals': 24,
          'averageWeight': 387.4,
        },
        farmId: farmId,
      ),
      AtlasOfflineRecord(
        id: 'offline_health_demo',
        title: 'Vacinação contra clostridioses',
        type: AtlasOfflineRecordType.health,
        status: AtlasOfflineRecordStatus.synchronized,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 20)),
        payload: const <String, dynamic>{
          'animals': 86,
          'protocol': 'Clostridioses',
        },
        farmId: farmId,
      ),
    ];
  }
}
