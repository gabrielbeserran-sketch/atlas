import 'dart:convert';

import 'package:projeto_atlas/features/data_governance/domain/models/atlas_data_governance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasDataGovernanceRepository {
  static const String _backupsKey = 'atlas_data_governance_backups_v1';
  static const int _maxBackups = 5;

  Future<List<AtlasBackupSnapshot>> loadBackups() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_backupsKey);
    if (raw == null || raw.isEmpty) {
      return <AtlasBackupSnapshot>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) =>
                AtlasBackupSnapshot.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return <AtlasBackupSnapshot>[];
    }
  }

  Future<AtlasBackupSnapshot> createBackup({String? label}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> payload = <String, dynamic>{};

    for (final String key in prefs.getKeys()) {
      if (key == _backupsKey) {
        continue;
      }
      final Object? value = prefs.get(key);
      if (value is String || value is bool || value is int || value is double) {
        payload[key] = value;
      } else if (value is List<String>) {
        payload[key] = value;
      }
    }

    final DateTime now = DateTime.now();
    final String encodedPayload = jsonEncode(payload);
    final AtlasBackupSnapshot snapshot = AtlasBackupSnapshot(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      itemCount: payload.length,
      sizeBytes: utf8.encode(encodedPayload).length,
      payload: payload,
      label: (label == null || label.trim().isEmpty)
          ? 'Backup ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}'
          : label.trim(),
    );

    final List<AtlasBackupSnapshot> backups = await loadBackups();
    backups.insert(0, snapshot);
    if (backups.length > _maxBackups) {
      backups.removeRange(_maxBackups, backups.length);
    }
    await _saveBackups(prefs, backups);
    return snapshot;
  }

  Future<void> restoreBackup(AtlasBackupSnapshot snapshot) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final MapEntry<String, dynamic> entry in snapshot.payload.entries) {
      final dynamic value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(entry.key, value.map((e) => '$e').toList());
      }
    }
  }

  Future<void> deleteBackup(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<AtlasBackupSnapshot> backups = await loadBackups();
    backups.removeWhere((item) => item.id == id);
    await _saveBackups(prefs, backups);
  }

  Future<void> _saveBackups(
    SharedPreferences prefs,
    List<AtlasBackupSnapshot> backups,
  ) async {
    await prefs.setString(
      _backupsKey,
      jsonEncode(backups.map((item) => item.toJson()).toList()),
    );
  }
}
