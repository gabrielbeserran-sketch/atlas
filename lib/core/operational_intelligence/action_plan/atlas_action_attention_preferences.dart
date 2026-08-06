import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AtlasActionAttentionPreferences {
  AtlasActionAttentionPreferences._();

  static final AtlasActionAttentionPreferences instance =
      AtlasActionAttentionPreferences._();

  static const String _storageKey =
      'atlas_action_attention_snoozed_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<Map<String, DateTime>> loadSnoozedUntil() async {
    final encoded =
        await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <String, DateTime>{};
    }

    try {
      final decoded = Map<String, dynamic>.from(
        jsonDecode(encoded) as Map,
      );

      return decoded.map(
        (key, value) => MapEntry(
          key,
          DateTime.parse(value.toString()),
        ),
      );
    } catch (_) {
      return <String, DateTime>{};
    }
  }

  Future<void> snooze({
    required String attentionId,
    required Duration duration,
  }) async {
    final values = await loadSnoozedUntil();
    values[attentionId] = DateTime.now().add(duration);
    await _save(values);
  }

  Future<void> clearExpired() async {
    final now = DateTime.now();
    final values = await loadSnoozedUntil()
      ..removeWhere(
        (_, date) => !date.isAfter(now),
      );

    await _save(values);
  }

  Future<void> _save(
    Map<String, DateTime> values,
  ) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(
        values.map(
          (key, value) =>
              MapEntry(key, value.toIso8601String()),
        ),
      ),
    );
  }
}
