import 'dart:convert';

import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DairyProductionStorageService {
  DairyProductionStorageService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  String _key(String farmId) =>
      'atlas_dairy_daily_production_${farmId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

  Future<List<DairyDailyProductionData>> load(String farmId) async {
    final raw = await _preferences.getString(_key(farmId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final values = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map(
            (item) => DairyDailyProductionData.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      values.sort((a, b) => b.date.compareTo(a.date));
      return values;
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(String farmId, DairyDailyProductionData record) async {
    final records = await load(farmId);
    final day = DateTime(record.date.year, record.date.month, record.date.day);
    final next = [
      ...records.where(
        (item) =>
            item.date.year != day.year ||
            item.date.month != day.month ||
            item.date.day != day.day,
      ),
      record,
    ]..sort((a, b) => b.date.compareTo(a.date));
    await _save(farmId, next);
  }

  Future<void> delete(String farmId, DateTime date) async {
    final records = await load(farmId);
    await _save(
      farmId,
      records
          .where(
            (item) =>
                item.date.year != date.year ||
                item.date.month != date.month ||
                item.date.day != date.day,
          )
          .toList(),
    );
  }

  Future<void> _save(String farmId, List<DairyDailyProductionData> records) =>
      _preferences.setString(
        _key(farmId),
        jsonEncode(records.map((item) => item.toMap()).toList()),
      );
}
