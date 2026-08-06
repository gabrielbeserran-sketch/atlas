import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_integration_connection.dart';

class AtlasIntegrationRepository {
  static const _key = 'atlas_integration_hub_connections_v1';

  Future<List<AtlasIntegrationConnection>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return _seed();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e)=>AtlasIntegrationConnection.fromJson(Map<String,dynamic>.from(e as Map))).toList();
    } catch (_) { return _seed(); }
  }

  Future<void> save(List<AtlasIntegrationConnection> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e)=>e.toJson()).toList()));
  }

  List<AtlasIntegrationConnection> _seed() => <AtlasIntegrationConnection>[
    AtlasIntegrationConnection(id:'csv_animals', name:'Importação de animais por CSV', type:AtlasIntegrationType.csv, status:AtlasConnectionStatus.connected, lastSyncAt:DateTime.now().subtract(const Duration(days:2)), autoSync:false, recordsProcessed:248),
    const AtlasIntegrationConnection(id:'scale_future', name:'Balança eletrônica', type:AtlasIntegrationType.scale, status:AtlasConnectionStatus.disconnected, lastSyncAt:null, autoSync:true, recordsProcessed:0, notes:'Estrutura preparada para conexão futura.'),
    AtlasIntegrationConnection(id:'weather_demo', name:'Dados meteorológicos', type:AtlasIntegrationType.weather, status:AtlasConnectionStatus.attention, lastSyncAt:DateTime.now().subtract(const Duration(days:7)), autoSync:true, recordsProcessed:31),
  ];
}
