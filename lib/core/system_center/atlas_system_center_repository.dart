import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/core/settings/atlas_system_settings.dart';
import 'package:projeto_atlas/core/system_center/atlas_system_center_models.dart';

class AtlasSystemCenterRepository {
  static const String _automaticSyncKey = 'atlas_system_automatic_sync';
  static const String _wifiOnlyKey = 'atlas_system_wifi_only';
  static const String _notificationsKey = 'atlas_system_notifications';
  static const String _diagnosticsKey = 'atlas_system_diagnostics';
  static const String _compactModeKey = 'atlas_system_compact_mode';
  static const String _lastInspectionKey = 'atlas_system_last_inspection';

  Future<AtlasSystemSnapshot> load() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final Set<String> keys = preferences.getKeys();

    return AtlasSystemSnapshot(
      version: 'Enterprise 2.0',
      architectureScore: _calculateArchitectureScore(keys.length),
      modules: _defaultModules,
      registeredServices: 42,
      registeredRepositories: 28,
      storageKeys: keys.length,
      settings: AtlasSystemSettings(
        automaticSync: preferences.getBool(_automaticSyncKey) ?? true,
        wifiOnly: preferences.getBool(_wifiOnlyKey) ?? false,
        notificationsEnabled: preferences.getBool(_notificationsKey) ?? true,
        diagnosticsEnabled: preferences.getBool(_diagnosticsKey) ?? true,
        compactMode: preferences.getBool(_compactModeKey) ?? false,
      ),
      lastInspection: _readDate(preferences.getString(_lastInspectionKey)),
    );
  }

  Future<void> saveSettings(AtlasSystemSettings settings) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setBool(_automaticSyncKey, settings.automaticSync);
    await preferences.setBool(_wifiOnlyKey, settings.wifiOnly);
    await preferences.setBool(
      _notificationsKey,
      settings.notificationsEnabled,
    );
    await preferences.setBool(
      _diagnosticsKey,
      settings.diagnosticsEnabled,
    );
    await preferences.setBool(_compactModeKey, settings.compactMode);
  }

  Future<DateTime> registerInspection() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final DateTime now = DateTime.now();
    await preferences.setString(_lastInspectionKey, now.toIso8601String());
    return now;
  }

  int _calculateArchitectureScore(int storageKeys) {
    final int storageBonus = storageKeys > 20 ? 8 : 4;
    return 78 + storageBonus;
  }

  DateTime? _readDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  List<AtlasSystemModule> get _defaultModules {
    return const <AtlasSystemModule>[
      AtlasSystemModule(
        name: 'Integration Core',
        category: 'Arquitetura',
        status: 'Ativo',
      ),
      AtlasSystemModule(
        name: 'Orchestrator Engine',
        category: 'Inteligência',
        status: 'Ativo',
      ),
      AtlasSystemModule(
        name: 'Sync & Cloud',
        category: 'Sincronização',
        status: 'Preparado',
      ),
      AtlasSystemModule(
        name: 'Data Governance',
        category: 'Segurança',
        status: 'Ativo',
      ),
      AtlasSystemModule(
        name: 'Observability',
        category: 'Diagnóstico',
        status: 'Ativo',
      ),
      AtlasSystemModule(
        name: 'Enterprise Platform',
        category: 'Gestão',
        status: 'Ativo',
      ),
      AtlasSystemModule(
        name: 'AI Copilot',
        category: 'Inteligência',
        status: 'Ativo',
      ),
      AtlasSystemModule(
        name: 'Reporting',
        category: 'Documentos',
        status: 'Ativo',
      ),
    ];
  }
}
