import 'dart:convert';

import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DairyHerdSnapshotStorageService {
  DairyHerdSnapshotStorageService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  String _key(String farmId) =>
      'atlas_dairy_herd_snapshot_${farmId.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}';

  Future<List<DairyHerdSnapshotData>> load(String farmId) async {
    final raw = await _preferences.getString(_key(farmId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final values = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map(
            (item) =>
                DairyHerdSnapshotData.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
      values.sort((a, b) => b.date.compareTo(a.date));
      return values;
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(String farmId, DairyHerdSnapshotData snapshot) async {
    final current = await load(farmId);
    final values = [
      ...current.where(
        (item) =>
            item.date.year != snapshot.date.year ||
            item.date.month != snapshot.date.month ||
            item.date.day != snapshot.date.day,
      ),
      snapshot,
    ]..sort((a, b) => b.date.compareTo(a.date));
    await _preferences.setString(
      _key(farmId),
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> delete(String farmId, DateTime date) async {
    final values = await load(farmId);
    final filtered = values
        .where(
          (item) =>
              item.date.year != date.year ||
              item.date.month != date.month ||
              item.date.day != date.day,
        )
        .toList();
    await _preferences.setString(
      _key(farmId),
      jsonEncode(filtered.map((item) => item.toMap()).toList()),
    );
  }
}
