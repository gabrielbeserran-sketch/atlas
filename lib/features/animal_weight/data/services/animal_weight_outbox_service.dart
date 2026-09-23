import 'dart:convert';

import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingAnimalWeight {
  const PendingAnimalWeight({required this.record, this.needsReview = false});

  final AnimalWeightData record;
  final bool needsReview;

  Map<String, dynamic> toMap() => {
    'record': record.toMap(),
    'needsReview': needsReview,
  };

  factory PendingAnimalWeight.fromMap(Map<String, dynamic> map) {
    return PendingAnimalWeight(
      record: AnimalWeightData.fromMap(
        Map<String, dynamic>.from(map['record'] as Map),
      ),
      needsReview: map['needsReview'] == true,
    );
  }
}

/// Isolada por empresa, fazenda e animal: um login de outra empresa jamais
/// carrega ou envia a fila anterior. Não apaga dados se o JSON estiver inválido.
class AnimalWeightOutboxService {
  AnimalWeightOutboxService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  Future<void> _lastMutation = Future<void>.value();

  Future<void> _serialize(Future<void> Function() action) {
    final current = _lastMutation.then((_) => action());
    _lastMutation = current.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return current;
  }

  String _key({
    required String companyId,
    required String farmId,
    required String animalId,
  }) {
    if (companyId.trim().isEmpty ||
        farmId.trim().isEmpty ||
        animalId.trim().isEmpty) {
      throw ArgumentError('Contexto da pesagem incompleto.');
    }
    final scope = [
      companyId,
      farmId,
      animalId,
    ].map((value) => base64Url.encode(utf8.encode(value.trim()))).join('_');
    return 'atlas_weight_outbox_v1_$scope';
  }

  Future<List<PendingAnimalWeight>> load({
    required String companyId,
    required String farmId,
    required String animalId,
  }) async {
    await _lastMutation;
    return _read(companyId: companyId, farmId: farmId, animalId: animalId);
  }

  Future<List<PendingAnimalWeight>> _read({
    required String companyId,
    required String farmId,
    required String animalId,
  }) async {
    final raw = await _preferences.getString(
      _key(companyId: companyId, farmId: farmId, animalId: animalId),
    );
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => PendingAnimalWeight.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> upsert({
    required String companyId,
    required String farmId,
    required String animalId,
    required PendingAnimalWeight entry,
  }) async {
    final operationId = entry.record.clientOperationId.trim();
    if (operationId.isEmpty) {
      throw ArgumentError('Pesagem sem identificador de operação.');
    }
    await _serialize(() async {
      final entries = await _read(
        companyId: companyId,
        farmId: farmId,
        animalId: animalId,
      );
      final index = entries.indexWhere(
        (item) => item.record.clientOperationId == operationId,
      );
      if (index >= 0) {
        entries[index] = entry;
      } else {
        entries.add(entry);
      }
      await _write(companyId, farmId, animalId, entries);
    });
  }

  Future<void> remove({
    required String companyId,
    required String farmId,
    required String animalId,
    required String operationId,
  }) async {
    await _serialize(() async {
      final entries = await _read(
        companyId: companyId,
        farmId: farmId,
        animalId: animalId,
      );
      entries.removeWhere(
        (item) => item.record.clientOperationId == operationId,
      );
      await _write(companyId, farmId, animalId, entries);
    });
  }

  Future<void> _write(
    String companyId,
    String farmId,
    String animalId,
    List<PendingAnimalWeight> entries,
  ) async {
    await _preferences.setString(
      _key(companyId: companyId, farmId: farmId, animalId: animalId),
      jsonEncode(entries.map((item) => item.toMap()).toList()),
    );
  }
}
