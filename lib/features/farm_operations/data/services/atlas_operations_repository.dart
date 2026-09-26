import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_farm_operation.dart';

class AtlasOperationsRepository {
  static const _key = 'atlas_farm_operations_v1';

  /// Painéis não criam operações demonstrativas nem atribuem registros sem fazenda.
  Future<List<AtlasFarmOperation>> loadReadOnly({
    required String farmId,
  }) async {
    if (farmId.trim().isEmpty) return const [];
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List)
        .map(
          (e) =>
              AtlasFarmOperation.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .where((e) => e.farmId == farmId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<List<AtlasFarmOperation>> load({String? farmId}) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    List<AtlasFarmOperation> items;
    if (raw == null || raw.isEmpty) {
      // Consultar uma fazenda não deve criar tarefas ou custos fictícios.
      return const [];
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      items = decoded
          .map(
            (e) => AtlasFarmOperation.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return items
        .where((e) => farmId == null || e.farmId == null || e.farmId == farmId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<void> save(List<AtlasFarmOperation> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
