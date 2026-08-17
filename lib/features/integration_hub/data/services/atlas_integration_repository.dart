import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_integration_connection.dart';

class AtlasIntegrationRepository {
  static const _key = 'atlas_integration_hub_connections_v1';

  Future<List<AtlasIntegrationConnection>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <AtlasIntegrationConnection>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => AtlasIntegrationConnection.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasIntegrationConnection>[];
    }
  }

  Future<void> save(List<AtlasIntegrationConnection> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
