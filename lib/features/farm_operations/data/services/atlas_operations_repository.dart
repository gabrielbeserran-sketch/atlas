import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_farm_operation.dart';

class AtlasOperationsRepository {
  static const _key = 'atlas_farm_operations_v1';
  static Future<void> _writes = Future<void>.value();
  AtlasOperationsRepository() : _storageKey = _key, _scopedFarmId = null;
  AtlasOperationsRepository.scoped({
    required String tenantId,
    required String companyId,
    required String farmId,
  }) : _storageKey = scopedKey(tenantId, companyId, farmId),
       _scopedFarmId = farmId;
  final String _storageKey;
  final String? _scopedFarmId;

  static String scopedKey(String tenantId, String companyId, String farmId) {
    if ([tenantId, companyId, farmId].any((id) => id.trim().isEmpty)) {
      throw ArgumentError('Contexto de operações incompleto.');
    }
    return 'atlas_farm_operations_v2_${base64Url.encode(utf8.encode(jsonEncode([tenantId, companyId, farmId])))}';
  }

  String? _resolveFarm(String? farmId) {
    if (_scopedFarmId != null && farmId != null && farmId != _scopedFarmId) {
      throw ArgumentError('Fazenda divergente do armazenamento.');
    }
    return _scopedFarmId ?? farmId;
  }

  Future<bool> hasLegacyData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key)?.trim();
    return raw != null && raw.isNotEmpty && raw != '[]';
  }

  Future<List<Map<String, dynamic>>> reviewLegacy({
    required bool Function() isAuthorized,
  }) async {
    if (_scopedFarmId == null || !isAuthorized()) {
      throw StateError('Revisão não autorizada.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(_key);
    final records = raw == null || raw.isEmpty
        ? <dynamic>[]
        : jsonDecode(raw) as List;
    if (!isAuthorized()) throw StateError('Contexto alterado.');
    return records.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<int> recoverLegacy({
    required List<Map<String, dynamic>> reviewed,
    required String actorId,
    required bool confirmedOwnership,
    required bool Function() isAuthorized,
  }) {
    final snapshot = jsonDecode(jsonEncode(reviewed)) as List;
    final write = _writes.then((_) async {
      if (_scopedFarmId == null ||
          !confirmedOwnership ||
          actorId.trim().isEmpty ||
          !isAuthorized()) {
        throw StateError(
          'Recuperação exige confirmação e contexto autorizado.',
        );
      }
      if (snapshot.isEmpty) {
        throw ArgumentError('Selecione ao menos uma operação.');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final source = jsonDecode(prefs.getString(_key) ?? '[]') as List;
      final target = jsonDecode(prefs.getString(_storageKey) ?? '[]') as List;
      final ids = <String>{};
      var imported = 0;
      for (final item in snapshot) {
        final record = Map<String, dynamic>.from(item as Map);
        final operation = AtlasFarmOperation.fromJson(record);
        if (operation.id.trim().isEmpty || !ids.add(operation.id)) {
          throw StateError('Seleção ambígua.');
        }
        final matches = source
            .where((e) => (e as Map)['id'] == operation.id)
            .toList();
        if (matches.length != 1 ||
            jsonEncode(matches.single) != jsonEncode(record)) {
          throw StateError(
            'Registro antigo mudou ou é ambíguo. Revise novamente.',
          );
        }
        final recoveredId =
            'legacy_${base64Url.encode(utf8.encode(operation.id))}';
        final existing = target
            .where((e) => (e as Map)['id'] == recoveredId)
            .toList();
        if (existing.isNotEmpty) {
          if (existing.length != 1 ||
              (existing.single as Map)['_atlasLegacyRecovery'] is! Map ||
              ((existing.single as Map)['_atlasLegacyRecovery']
                      as Map)['sourceJson'] !=
                  jsonEncode(record)) {
            throw StateError(
              'Recuperação em conflito; nenhum registro foi substituído.',
            );
          }
          continue;
        }
        target.add({
          ...record,
          'id': recoveredId,
          'farmId': _scopedFarmId,
          '_atlasLegacyRecovery': {
            'actorId': actorId,
            'at': DateTime.now().toUtc().toIso8601String(),
            'sourceId': operation.id,
            'sourceFarmId': operation.farmId,
            'targetFarmId': _scopedFarmId,
            'scopeKey': _storageKey,
            'confirmedOwnership': true,
            'sourceJson': jsonEncode(record),
          },
        });
        imported++;
      }
      if (!isAuthorized()) throw StateError('Contexto alterado.');
      if (imported > 0 &&
          !await prefs.setString(_storageKey, jsonEncode(target))) {
        throw StateError('Não foi possível recuperar as operações.');
      }
      return imported;
    });
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }

  /// Painéis não criam operações demonstrativas nem atribuem registros sem fazenda.
  Future<List<AtlasFarmOperation>> loadReadOnly({
    required String farmId,
  }) async {
    farmId = _resolveFarm(farmId)!;
    if (farmId.trim().isEmpty) return const [];
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
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
    farmId = _resolveFarm(farmId);
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
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

  Future<void> save(
    List<AtlasFarmOperation> items, {
    String? farmId,
    bool Function()? isAuthorized,
  }) {
    farmId = _resolveFarm(farmId);
    final records = items.map((e) => e.toJson()).toList();
    final write = _writes.then((_) async {
      if (isAuthorized != null && !isAuthorized()) {
        throw StateError('Contexto de operações alterado.');
      }
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
        final raw = preferences.getString(_storageKey);
        final existing = raw == null || raw.isEmpty
            ? <dynamic>[]
            : jsonDecode(raw) as List;
        for (final entry in existing) {
          final record = Map<String, dynamic>.from(entry as Map);
          if (record['farmId'] == farmId &&
              record['_atlasLegacyRecovery'] != null) {
            for (final replacement in records.where(
              (e) => e['id'] == record['id'],
            )) {
              replacement['_atlasLegacyRecovery'] =
                  record['_atlasLegacyRecovery'];
            }
          }
          if (record['farmId'] != farmId) {
            if (ids.contains(record['id'])) {
              throw StateError('Identificador já pertence a outra operação.');
            }
            merged.add(record);
          }
        }
      }
      merged.addAll(records);
      if (isAuthorized != null && !isAuthorized()) {
        throw StateError('Contexto de operações alterado.');
      }
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode(merged),
      );
      if (!saved) throw StateError('Não foi possível persistir as operações.');
    });
    // Uma gravação recusada não bloqueia as próximas gravações.
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }
}
