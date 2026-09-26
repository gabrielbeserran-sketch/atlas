import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_farm_operation.dart';

class AtlasOperationsRepository {
  static const _key = 'atlas_farm_operations_v1';
  static Future<void> _writes = Future<void>.value();

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
    return items.where((e) => farmId == null || e.farmId == farmId).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<void> save(List<AtlasFarmOperation> items, {String? farmId}) {
    final records = items.map((e) => e.toJson()).toList();
    final write = _writes.then((_) async {
      if (farmId != null &&
          (farmId.trim().isEmpty || items.any((e) => e.farmId != farmId))) {
        throw ArgumentError('Operações devem pertencer à fazenda informada.');
      }
      final ids = items.map((e) => e.id).toSet();
      if (ids.length != items.length || ids.any((id) => id.trim().isEmpty)) {
        throw ArgumentError(
          'Identificadores de operação inválidos ou repetidos.',
        );
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final merged = <Map<String, dynamic>>[];
      if (farmId != null) {
        final raw = preferences.getString(_key);
        final existing = raw == null || raw.isEmpty
            ? <dynamic>[]
            : jsonDecode(raw) as List;
        for (final entry in existing) {
          final record = Map<String, dynamic>.from(entry as Map);
          if (record['farmId'] != farmId) {
            if (ids.contains(record['id'])) {
              throw StateError('Identificador já pertence a outra operação.');
            }
            merged.add(record);
          }
        }
      }
      merged.addAll(records);
      final saved = await preferences.setString(_key, jsonEncode(merged));
      if (!saved) throw StateError('Não foi possível persistir as operações.');
    });
    // Uma gravação recusada não bloqueia as próximas gravações.
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }
}
