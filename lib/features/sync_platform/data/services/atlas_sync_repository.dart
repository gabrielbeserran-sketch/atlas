import 'dart:convert';

import 'package:projeto_atlas/features/sync_platform/domain/models/atlas_sync_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasSyncRepository {
  static const String _itemsKey = 'atlas_sync_platform_items_v1';
  static const String _settingsKey = 'atlas_sync_platform_settings_v1';

  Future<AtlasSyncState> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? rawItems = preferences.getString(_itemsKey);
    final String? rawSettings = preferences.getString(_settingsKey);

    final List<AtlasSyncItem> items;
    if (rawItems == null) {
      items = _seedItems();
      await saveItems(items);
    } else {
      final List<dynamic> decoded = jsonDecode(rawItems) as List<dynamic>;
      items = decoded
          .map((dynamic value) => AtlasSyncItem.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList();
    }

    final AtlasSyncSettings settings = rawSettings == null
        ? const AtlasSyncSettings(
            online: true,
            automaticSync: true,
            wifiOnly: false,
            lastSyncAt: null,
          )
        : AtlasSyncSettings.fromJson(
            Map<String, dynamic>.from(jsonDecode(rawSettings) as Map),
          );
    return AtlasSyncState(items: items, settings: settings);
  }

  Future<void> saveItems(List<AtlasSyncItem> items) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _itemsKey,
      jsonEncode(items.map((AtlasSyncItem item) => item.toJson()).toList()),
    );
  }

  Future<void> saveSettings(AtlasSyncSettings settings) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  List<AtlasSyncItem> _seedItems() {
    final DateTime now = DateTime.now();
    return <AtlasSyncItem>[
      AtlasSyncItem(
        id: 'sync_${now.microsecondsSinceEpoch}_1',
        module: 'Campo Offline',
        entityType: 'pesagem',
        entityId: 'animal_1042',
        operation: 'create',
        createdAt: now.subtract(const Duration(minutes: 42)),
        updatedAt: now.subtract(const Duration(minutes: 42)),
        status: AtlasSyncStatus.pending,
        priority: AtlasSyncPriority.high,
        attempts: 0,
        payload: const <String, dynamic>{'peso': 428.5},
      ),
      AtlasSyncItem(
        id: 'sync_${now.microsecondsSinceEpoch}_2',
        module: 'Farm Operations',
        entityType: 'manejo',
        entityId: 'manejo_87',
        operation: 'update',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        status: AtlasSyncStatus.pending,
        priority: AtlasSyncPriority.normal,
        attempts: 0,
        payload: const <String, dynamic>{'status': 'concluido'},
      ),
      AtlasSyncItem(
        id: 'sync_${now.microsecondsSinceEpoch}_3',
        module: 'Relatórios',
        entityType: 'relatorio',
        entityId: 'report_12',
        operation: 'update',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        status: AtlasSyncStatus.synced,
        priority: AtlasSyncPriority.low,
        attempts: 1,
        payload: const <String, dynamic>{'status': 'pronto'},
      ),
    ];
  }
}
