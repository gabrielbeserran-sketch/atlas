import 'dart:convert';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmFinanceStorageService {
  FarmFinanceStorageService({AtlasHttpClient? httpClient})
    : _http = httpClient ?? AtlasHttpClient();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasHttpClient _http;

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _createStorageKey(String farmName) =>
      'atlas_farm_finance_${_normalize(farmName)}';

  Future<List<FarmFinanceData>> loadRecords(
    String farmName, {
    String farmId = '',
  }) async {
    final storageKey = _createStorageKey(farmName);
    final resolvedFarmId = farmId.trim().isNotEmpty
        ? farmId.trim()
        : await _resolveFarmId(farmName);
    if (resolvedFarmId.isNotEmpty) {
      try {
        final records = await _loadRemoteRecords(
          farmId: resolvedFarmId,
          farmName: farmName,
        );
        await _saveLocal(storageKey, records);
        return records;
      } catch (_) {
        // Cache local é apenas contingência offline.
      }
    }
    return _loadLocal(storageKey);
  }

  Future<FarmFinanceData> createRecord({
    required String farmName,
    required String farmId,
    required FarmFinanceData record,
    String referenceType = '',
    String referenceId = '',
  }) async {
    final refs = await _resolveReferences(farmId, record);
    final response = await _http.send(
      'POST',
      '/livestock/finance/v2',
      body: _toApi(
        record,
        farmId,
        lotId: refs.lotId,
        animalId: refs.animalId,
        referenceType: referenceType,
        referenceId: referenceId,
      ),
    );
    final immediate = _fromApi(response.asMap(), fallback: record);
    final verified = await _verifyRecord(
      farmId: farmId,
      farmName: farmName,
      entryId: immediate.id,
      fallback: record,
    );
    await _upsertLocal(farmName, verified);
    return verified;
  }

  Future<FarmFinanceData> updateRecord({
    required String farmName,
    required String farmId,
    required FarmFinanceData record,
  }) async {
    final refs = await _resolveReferences(farmId, record);
    final response = await _http.send(
      'PATCH',
      '/livestock/finance/v2/${record.id}',
      body: _toApi(record, farmId, lotId: refs.lotId, animalId: refs.animalId),
    );
    final immediate = _fromApi(response.asMap(), fallback: record);
    final verified = await _verifyRecord(
      farmId: farmId,
      farmName: farmName,
      entryId: immediate.id,
      fallback: record,
    );
    await _upsertLocal(farmName, verified);
    return verified;
  }

  Future<bool> hasReference({
    required String farmId,
    required String referenceType,
    required String referenceId,
  }) async {
    if (farmId.trim().isEmpty || referenceId.trim().isEmpty) {
      return false;
    }
    final response = await _http.send(
      'GET',
      '/livestock/finance/v2',
      queryParameters: {'farm_id': farmId.trim()},
    );
    return response.asMapList().any(
      (item) =>
          item['reference_type']?.toString() == referenceType &&
          item['reference_id']?.toString() == referenceId,
    );
  }

  Future<void> deleteRecord({
    required String farmName,
    required String entryId,
  }) async {
    await _http.send('DELETE', '/livestock/finance/v2/$entryId');
    final records = await _loadLocal(_createStorageKey(farmName));
    records.removeWhere((item) => item.id == entryId);
    await saveRecords(farmName: farmName, records: records);
  }

  Future<void> saveRecords({
    required String farmName,
    required List<FarmFinanceData> records,
  }) async {
    await _saveLocal(_createStorageKey(farmName), records);
  }

  Future<List<FarmFinanceData>> _loadRemoteRecords({
    required String farmId,
    required String farmName,
  }) async {
    final maps = await _loadReferenceMaps(farmId);
    final response = await _http.send(
      'GET',
      '/livestock/finance/v2',
      queryParameters: {'farm_id': farmId},
    );
    return response
        .asMapList()
        .map(
          (map) => _fromApi(
            map,
            lotNames: maps.lotNames,
            animalLabels: maps.animalLabels,
          ),
        )
        .toList();
  }

  Future<FarmFinanceData> _verifyRecord({
    required String farmId,
    required String farmName,
    required String entryId,
    required FarmFinanceData fallback,
  }) async {
    final records = await _loadRemoteRecords(
      farmId: farmId,
      farmName: farmName,
    );
    for (final record in records) {
      if (record.id == entryId) {
        return record;
      }
    }
    throw StateError(
      'O lançamento não foi confirmado após nova leitura do servidor.',
    );
  }

  Future<List<FarmFinanceData>> _loadLocal(String storageKey) async {
    final savedData = await _preferences.getString(storageKey);
    if (savedData == null || savedData.isEmpty) {
      return [];
    }
    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;
      return decodedData
          .map(
            (item) =>
                FarmFinanceData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal(String key, List<FarmFinanceData> records) =>
      _preferences.setString(
        key,
        jsonEncode(records.map((record) => record.toMap()).toList()),
      );

  Future<void> _upsertLocal(String farmName, FarmFinanceData record) async {
    final key = _createStorageKey(farmName);
    final records = await _loadLocal(key);
    final index = records.indexWhere((item) => item.id == record.id);
    if (index < 0) {
      records.add(record);
    } else {
      records[index] = record;
    }
    await _saveLocal(key, records);
  }

  Future<String> _resolveFarmId(String farmName) async {
    try {
      final response = await _http.send('GET', '/farms');
      final normalized = farmName.trim().toLowerCase();
      for (final item in response.asMapList()) {
        if ((item['name']?.toString().trim().toLowerCase() ?? '') ==
            normalized) {
          return item['id']?.toString() ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  Future<_FinanceReferenceMaps> _loadReferenceMaps(String farmId) async {
    final lots = await _http.send(
      'GET',
      '/livestock/lots',
      queryParameters: {'farm_id': farmId},
    );
    final animals = await _http.send(
      'GET',
      '/livestock/animals',
      queryParameters: {'farm_id': farmId},
    );
    final lotNames = <String, String>{};
    final lotIdsByLabel = <String, String>{};
    for (final item in lots.asMapList()) {
      final id = item['id']?.toString() ?? '';
      final name = item['name']?.toString() ?? '';
      if (id.isEmpty) {
        continue;
      }
      lotNames[id] = name;
      lotIdsByLabel[id.toLowerCase()] = id;
      if (name.trim().isNotEmpty) {
        lotIdsByLabel[name.trim().toLowerCase()] = id;
      }
    }

    final animalLabels = <String, String>{};
    final animalIdsByLabel = <String, String>{};
    for (final item in animals.asMapList()) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) {
        continue;
      }
      final tag = item['tag']?.toString().trim() ?? '';
      final sisbov = item['sisbov']?.toString().trim() ?? '';
      final name = item['name']?.toString().trim() ?? '';
      final label = name.isNotEmpty
          ? name
          : (tag.isNotEmpty ? tag : (sisbov.isNotEmpty ? sisbov : id));
      animalLabels[id] = label;
      for (final candidate in [id, tag, sisbov, name]) {
        if (candidate.trim().isNotEmpty) {
          animalIdsByLabel[candidate.trim().toLowerCase()] = id;
        }
      }
    }
    return _FinanceReferenceMaps(
      lotNames: lotNames,
      lotIdsByLabel: lotIdsByLabel,
      animalLabels: animalLabels,
      animalIdsByLabel: animalIdsByLabel,
    );
  }

  Future<_ResolvedFinanceReferences> _resolveReferences(
    String farmId,
    FarmFinanceData record,
  ) async {
    if (record.lotName.trim().isEmpty &&
        record.animalIdentification.trim().isEmpty) {
      return const _ResolvedFinanceReferences();
    }
    final maps = await _loadReferenceMaps(farmId);
    String? lotId;
    String? animalId;
    if (record.lotName.trim().isNotEmpty) {
      lotId = maps.lotIdsByLabel[record.lotName.trim().toLowerCase()];
      if (lotId == null) {
        throw StateError(
          'Lote "${record.lotName}" não encontrado na fazenda ativa.',
        );
      }
    }
    if (record.animalIdentification.trim().isNotEmpty) {
      animalId = maps
          .animalIdsByLabel[record.animalIdentification.trim().toLowerCase()];
      if (animalId == null) {
        throw StateError(
          'Animal "${record.animalIdentification}" não encontrado na fazenda ativa.',
        );
      }
    }
    return _ResolvedFinanceReferences(lotId: lotId, animalId: animalId);
  }

  Map<String, dynamic> _toApi(
    FarmFinanceData record,
    String farmId, {
    String? lotId,
    String? animalId,
    String referenceType = '',
    String referenceId = '',
  }) => {
    'farm_id': farmId,
    'animal_id': animalId,
    'lot_id': lotId,
    'entry_type': record.isIncome ? 'income' : 'expense',
    'category': record.category,
    'cost_center': record.costCenter,
    'description': record.description,
    'amount': record.amount,
    'status': _statusToApi(record.status),
    'competence_date': _dateToIso(record.competence),
    'due_date': _dateToIso(
      record.dueDate.isEmpty ? record.date : record.dueDate,
    ),
    'paid_at': record.isPaid
        ? _dateToIso(
            record.paymentDate.isEmpty ? record.date : record.paymentDate,
          )
        : null,
    'payment_method': record.paymentMethod,
    'counterparty': record.counterparty,
    'document_number': record.documentNumber,
    'recurring': record.isRecurring,
    'reference_type': referenceType.isNotEmpty
        ? referenceType
        : (lotId != null ? 'lot' : (animalId != null ? 'animal' : '')),
    'reference_id': referenceId.isNotEmpty
        ? referenceId
        : (lotId ?? animalId ?? ''),
    'notes': record.notes,
  };

  FarmFinanceData _fromApi(
    Map<String, dynamic> map, {
    Map<String, String> lotNames = const {},
    Map<String, String> animalLabels = const {},
    FarmFinanceData? fallback,
  }) {
    final entryType = map['entry_type']?.toString().toLowerCase() ?? 'expense';
    final isIncome = entryType == 'income' || entryType == 'receita';
    final lotId = map['lot_id']?.toString() ?? '';
    final animalId = map['animal_id']?.toString() ?? '';
    return FarmFinanceData(
      id: map['id']?.toString() ?? fallback?.id ?? '',
      type: isIncome ? 'Receita' : 'Despesa',
      category: map['category']?.toString() ?? fallback?.category ?? 'Outros',
      date: _isoToDate(
        map['competence_date'] ?? map['created_at'] ?? map['due_date'],
      ),
      description:
          map['description']?.toString() ??
          fallback?.description ??
          'Lançamento financeiro',
      amount: (map['amount'] as num?)?.toDouble() ?? fallback?.amount ?? 0,
      paymentMethod:
          map['payment_method']?.toString() ??
          fallback?.paymentMethod ??
          'Não informado',
      notes: map['notes']?.toString() ?? fallback?.notes ?? '',
      status: _statusFromApi(map['status']?.toString() ?? '', isIncome),
      dueDate: _isoToDate(map['due_date']),
      paymentDate: _isoToDate(map['paid_at']),
      competence: _isoToMonthYear(map['competence_date']),
      costCenter:
          map['cost_center']?.toString() ?? fallback?.costCenter ?? 'Geral',
      counterparty:
          map['counterparty']?.toString() ?? fallback?.counterparty ?? '',
      documentNumber:
          map['document_number']?.toString() ?? fallback?.documentNumber ?? '',
      lotName: lotNames[lotId] ?? fallback?.lotName ?? lotId,
      animalIdentification:
          animalLabels[animalId] ?? fallback?.animalIdentification ?? animalId,
      isRecurring: map['recurring'] as bool? ?? fallback?.isRecurring ?? false,
    );
  }

  String _statusToApi(String value) {
    final v = value.toLowerCase();
    if (v.contains('pago') || v.contains('recebido')) {
      return 'paid';
    }
    if (v.contains('cancel')) {
      return 'cancelled';
    }
    return 'pending';
  }

  String _statusFromApi(String value, bool income) {
    final v = value.toLowerCase();
    if (v == 'paid' || v == 'settled') {
      return income ? 'Recebido' : 'Pago';
    }
    if (v == 'cancelled' || v == 'canceled') {
      return 'Cancelado';
    }
    return 'Pendente';
  }

  String? _dateToIso(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }
    final br = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (br != null) {
      return DateTime(
        int.parse(br.group(3)!),
        int.parse(br.group(2)!),
        int.parse(br.group(1)!),
      ).toUtc().toIso8601String();
    }
    final month = RegExp(r'^(\d{2})/(\d{4})$').firstMatch(text);
    if (month != null) {
      return DateTime(
        int.parse(month.group(2)!),
        int.parse(month.group(1)!),
        1,
      ).toUtc().toIso8601String();
    }
    return DateTime.tryParse(text)?.toUtc().toIso8601String();
  }

  String _isoToDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) {
      return '';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _isoToMonthYear(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) {
      return '';
    }
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _FinanceReferenceMaps {
  const _FinanceReferenceMaps({
    required this.lotNames,
    required this.lotIdsByLabel,
    required this.animalLabels,
    required this.animalIdsByLabel,
  });

  final Map<String, String> lotNames;
  final Map<String, String> lotIdsByLabel;
  final Map<String, String> animalLabels;
  final Map<String, String> animalIdsByLabel;
}

class _ResolvedFinanceReferences {
  const _ResolvedFinanceReferences({this.lotId, this.animalId});

  final String? lotId;
  final String? animalId;
}
