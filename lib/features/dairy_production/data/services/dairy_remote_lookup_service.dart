import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';

class DairyLookupKey {
  const DairyLookupKey({required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;

  String get composite => '$entityType:$entityId';

  Map<String, String> toMap() => <String, String>{
    'entity_type': entityType,
    'entity_id': entityId,
  };
}

class DairyRemoteState {
  const DairyRemoteState({
    required this.key,
    required this.found,
    required this.version,
    required this.deleted,
    required this.payload,
    required this.readAt,
  });

  final DairyLookupKey key;
  final bool found;
  final int version;
  final bool deleted;
  final Map<String, dynamic> payload;

  /// Each batch has its own server read instant, not one global snapshot.
  final DateTime readAt;
}

/// Opt-in lookup. It never edits the local cache, legacy data or sync queue.
class DairyRemoteLookupService {
  DairyRemoteLookupService({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<List<DairyRemoteState>> lookup({
    required String farmId,
    required List<DairyLookupKey> keys,
    required bool Function() isScopeCurrent,
  }) async {
    if (farmId.trim().isEmpty || keys.isEmpty) {
      throw StateError('Fazenda e registros de Leite são obrigatórios.');
    }
    final seen = <String>{};
    for (final key in keys) {
      _validateKey(farmId, key);
      if (!seen.add(key.composite)) {
        throw StateError('Consulta de Leite contém ID duplicado.');
      }
    }

    void ensureScope() {
      if (!isScopeCurrent()) {
        throw StateError(
          'A sessão ou fazenda mudou durante a consulta de Leite.',
        );
      }
    }

    final results = <DairyRemoteState>[];
    for (var start = 0; start < keys.length; start += 200) {
      ensureScope();
      final chunk = keys.skip(start).take(200).toList(growable: false);
      final response = await _client.send(
        'POST',
        '/offline/dairy/lookup',
        body: <String, dynamic>{
          'farm_id': farmId,
          'items': chunk.map((key) => key.toMap()).toList(growable: false),
        },
      );
      ensureScope();
      results.addAll(_validatedChunk(farmId, chunk, response.asMap()));
    }
    ensureScope();
    return List.unmodifiable(results);
  }

  static List<DairyRemoteState> _validatedChunk(
    String farmId,
    List<DairyLookupKey> requested,
    Map<String, dynamic> body,
  ) {
    if (body['farm_id'] != farmId || body['items'] is! List) {
      throw StateError('Resposta de Leite fora da fazenda solicitada.');
    }
    final rawReadAt = body['read_at'];
    if (rawReadAt is! String ||
        !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(rawReadAt)) {
      throw StateError('Resposta de Leite sem horário autenticável.');
    }
    final readAt = DateTime.tryParse(rawReadAt);
    if (readAt == null) {
      throw StateError('Horário da consulta de Leite inválido.');
    }
    final rawItems = body['items'] as List;
    if (rawItems.length != requested.length) {
      throw StateError(
        'Resposta de Leite incompleta; nenhuma decisão aplicada.',
      );
    }
    final expected = {for (final key in requested) key.composite: key};
    final found = <String, DairyRemoteState>{};
    for (final raw in rawItems) {
      if (raw is! Map) {
        throw StateError('Item da consulta de Leite inválido.');
      }
      final type = raw['entity_type'];
      final id = raw['entity_id'];
      if (type is! String || id is! String) {
        throw StateError('Identidade da consulta de Leite inválida.');
      }
      final composite = '$type:$id';
      final key = expected[composite];
      if (key == null || found.containsKey(composite)) {
        throw StateError('Resposta de Leite duplicada ou não solicitada.');
      }
      final exists = raw['found'];
      final version = raw['version'];
      final deleted = raw['deleted'];
      final rawPayload = raw['payload'];
      if (exists is! bool ||
          version is! int ||
          deleted is! bool ||
          rawPayload is! Map) {
        throw StateError('Versão ou payload de Leite inválido.');
      }
      final payload = Map<String, dynamic>.from(rawPayload);
      if (exists) {
        if (version <= 0) {
          throw StateError('Versão remota de Leite inválida.');
        }
        if (!deleted) _validatePayload(farmId, key, payload);
      } else if (version != 0 || deleted || payload.isNotEmpty) {
        throw StateError('Ausência remota de Leite inconsistente.');
      }
      found[composite] = DairyRemoteState(
        key: key,
        found: exists,
        version: version,
        deleted: deleted,
        payload: Map.unmodifiable(payload),
        readAt: readAt,
      );
    }
    return [for (final key in requested) found[key.composite]!];
  }

  static void _validateKey(String farmId, DairyLookupKey key) {
    if (!const {
      'dairy_daily_production',
      'dairy_herd_snapshot',
    }.contains(key.entityType)) {
      throw StateError('Tipo de registro de Leite inválido.');
    }
    final prefix = '$farmId:';
    if (!key.entityId.startsWith(prefix)) {
      throw StateError('Registro de Leite fora da fazenda selecionada.');
    }
    final day = key.entityId.substring(prefix.length);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
      throw StateError('Data do registro de Leite inválida.');
    }
    final parsed = DateTime.tryParse(day);
    if (parsed == null ||
        '${parsed.year.toString().padLeft(4, '0')}-'
                '${parsed.month.toString().padLeft(2, '0')}-'
                '${parsed.day.toString().padLeft(2, '0')}' !=
            day ||
        parsed.year < 1900) {
      throw StateError('Data do registro de Leite impossível.');
    }
  }

  static void _validatePayload(
    String farmId,
    DairyLookupKey key,
    Map<String, dynamic> payload,
  ) {
    if (payload.containsKey('farm_id') && payload['farm_id'] != farmId) {
      throw StateError('Payload de Leite pertence a outra fazenda.');
    }
    final day = key.entityId.substring(farmId.length + 1);
    final rawDate = payload['date'];
    if (rawDate is! String ||
        rawDate.length < 10 ||
        rawDate.substring(0, 10) != day) {
      throw StateError('Data do payload de Leite difere do ID.');
    }
    try {
      if (key.entityType == 'dairy_daily_production') {
        if (!payload.containsKey('morning_liters') ||
            !payload.containsKey('afternoon_liters') ||
            !payload.containsKey('cows_milked')) {
          throw const FormatException('Campos da ordenha ausentes.');
        }
        DairyDailyProductionData.fromMap(payload).validateForSave();
      } else {
        DairyHerdSnapshotData.fromMap(payload).validate();
      }
    } catch (_) {
      throw StateError('Payload remoto de Leite exige revisão.');
    }
  }
}
