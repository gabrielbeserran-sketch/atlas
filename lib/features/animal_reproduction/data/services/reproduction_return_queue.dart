import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_return_resolution.dart';

class ReturnQueueScope {
  const ReturnQueueScope(
    this.tenantId,
    this.companyId,
    this.farmId,
    this.userId,
  );
  final String tenantId, companyId, farmId, userId;
  bool get isValid =>
      [tenantId, companyId, farmId, userId].every((id) => id.trim().isNotEmpty);
}

class PendingReturn {
  const PendingReturn({
    required this.animalId,
    required this.eventId,
    required this.occurredDate,
    required this.expectedDate,
    required this.audit,
    this.conflict = '',
  });
  final String animalId, eventId, occurredDate, expectedDate, conflict;
  final Map<String, dynamic> audit;
  String get status => '${audit['status'] ?? ''}';
  Map<String, dynamic> toMap() => {
    'animal_id': animalId,
    'event_id': eventId,
    'occurred_date': occurredDate,
    'expected_date': expectedDate,
    'audit': audit,
    'conflict': conflict,
  };
  factory PendingReturn.fromMap(Map<String, dynamic> map) => PendingReturn(
    animalId: '${map['animal_id'] ?? ''}',
    eventId: '${map['event_id'] ?? ''}',
    occurredDate: '${map['occurred_date'] ?? ''}',
    expectedDate: '${map['expected_date'] ?? ''}',
    audit: Map<String, dynamic>.from(map['audit'] as Map),
    conflict: '${map['conflict'] ?? ''}',
  );
  PendingReturn withConflict(String value) => PendingReturn(
    animalId: animalId,
    eventId: eventId,
    occurredDate: occurredDate,
    expectedDate: expectedDate,
    audit: audit,
    conflict: value,
  );
}

/// Fila somente de intenção: nunca marca o evento como resolvido no cache clínico.
class ReproductionReturnQueue {
  ReproductionReturnQueue({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  static const _prefix = 'atlas_reproduction_return_queue_v1_';
  static Future<void> _lastWrite = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) async {
    final previous = _lastWrite;
    final completed = Completer<void>();
    _lastWrite = completed.future;
    await previous;
    try {
      return await action();
    } finally {
      completed.complete();
    }
  }

  String _key(ReturnQueueScope scope) {
    if (!scope.isValid) {
      throw StateError('Conta ou fazenda indisponível para baixa offline.');
    }
    return _prefix +
        [
          scope.tenantId,
          scope.companyId,
          scope.farmId,
          scope.userId,
        ].map(Uri.encodeComponent).join('_');
  }

  Future<List<PendingReturn>> read(ReturnQueueScope scope) async {
    final raw = await _preferences.getString(_key(scope));
    if (raw == null || raw.isEmpty) return [];
    try {
      final rows = jsonDecode(raw) as List;
      return rows
          .map(
            (row) =>
                PendingReturn.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (_) {
      throw StateError(
        'Fila local de retornos ilegível. Nada foi apagado; recupere o armazenamento antes de sincronizar.',
      );
    }
  }

  Future<void> _write(ReturnQueueScope scope, List<PendingReturn> rows) =>
      _preferences.setString(
        _key(scope),
        jsonEncode(rows.map((row) => row.toMap()).toList()),
      );

  Future<PendingReturn> stage(
    ReturnQueueScope scope,
    AnimalReproductionData record, {
    required String status,
    required String responsible,
    String reason = '',
  }) => _serial(() async {
    if (!record.synced || record.animalId.isEmpty) {
      throw StateError(
        'Este evento precisa estar confirmado no servidor antes de receber baixa offline.',
      );
    }
    final rows = await read(scope);
    for (final previous in rows) {
      if (previous.eventId == record.id &&
          previous.animalId == record.animalId) {
        if (previous.status != status ||
            previous.occurredDate != record.date ||
            previous.expectedDate != record.expectedDate) {
          throw StateError(
            'Já existe uma baixa local diferente para este retorno. Resolva o conflito antes de substituir.',
          );
        }
        return previous; // Mesmo evento mantém timestamp e intenção originais.
      }
    }
    final draft = ReproductionReturnResolution.resolve(
      record,
      status: status,
      responsible: responsible,
      at: DateTime.now(),
      reason: reason,
    );
    final pending = PendingReturn(
      animalId: record.animalId,
      eventId: record.id,
      occurredDate: record.date,
      expectedDate: record.expectedDate,
      audit: Map<String, dynamic>.from(
        draft.metadata['atlas_return_resolution'] as Map,
      ),
    );
    rows.add(pending);
    await _write(scope, rows);
    return pending;
  });

  Future<void> replace(ReturnQueueScope scope, PendingReturn pending) =>
      _serial(() async {
        final rows = await read(scope);
        final index = rows.indexWhere(
          (row) =>
              row.animalId == pending.animalId &&
              row.eventId == pending.eventId,
        );
        if (index < 0) {
          throw StateError('Baixa local não encontrada; atualize a lista.');
        }
        rows[index] = pending;
        await _write(scope, rows);
      });

  Future<void> remove(ReturnQueueScope scope, PendingReturn pending) => _serial(
    () async {
      final rows = await read(scope);
      rows.removeWhere(
        (row) =>
            row.animalId == pending.animalId && row.eventId == pending.eventId,
      );
      await _write(scope, rows);
    },
  );
}
