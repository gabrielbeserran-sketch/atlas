import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Retrato confirmado pelo produtor; não é inferido dos piquetes cadastrados.
class AtlasPastureGrazingBasis {
  AtlasPastureGrazingBasis({
    String? operationId,
    required this.tenantId,
    required this.companyId,
    required this.farmId,
    required this.effectiveAreaHa,
    required this.grazingAnimals,
    required this.uniqueAreaConfirmed,
    required this.recordedAt,
  }) : operationId = operationId ?? const Uuid().v4();

  final String operationId;

  final String tenantId;
  final String companyId;
  final String farmId;
  final double effectiveAreaHa;
  final int grazingAnimals;
  final bool uniqueAreaConfirmed;
  final DateTime recordedAt;

  double get animalsPerHectare => grazingAnimals / effectiveAreaHa;

  bool isCurrentAt(DateTime now) {
    final age = now.difference(recordedAt);
    return !age.isNegative && age <= const Duration(days: 7);
  }

  Map<String, dynamic> toMap() => {
    'operationId': operationId,
    'tenantId': tenantId,
    'companyId': companyId,
    'farmId': farmId,
    'effectiveAreaHa': effectiveAreaHa,
    'grazingAnimals': grazingAnimals,
    'uniqueAreaConfirmed': uniqueAreaConfirmed,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory AtlasPastureGrazingBasis.fromMap(Map<String, dynamic> map) {
    final recordedAt = DateTime.tryParse(map['recordedAt']?.toString() ?? '');
    if (recordedAt == null) throw const FormatException('Data ausente.');
    return AtlasPastureGrazingBasis(
      operationId:
          map['operationId']?.toString() ??
          const Uuid().v5(
            Uuid.NAMESPACE_URL,
            jsonEncode([
              map['tenantId'],
              map['companyId'],
              map['farmId'],
              map['recordedAt'],
              map['effectiveAreaHa'],
              map['grazingAnimals'],
            ]),
          ),
      tenantId: map['tenantId']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      farmId: map['farmId']?.toString() ?? '',
      effectiveAreaHa: (map['effectiveAreaHa'] as num?)?.toDouble() ?? 0,
      grazingAnimals: (map['grazingAnimals'] as num?)?.toInt() ?? 0,
      uniqueAreaConfirmed: map['uniqueAreaConfirmed'] == true,
      recordedAt: recordedAt,
    );
  }

  void validate({double? farmTotalAreaHa}) {
    if (operationId.trim().isEmpty) {
      throw ArgumentError('Identificador do registro ausente.');
    }
    if (tenantId.trim().isEmpty ||
        companyId.trim().isEmpty ||
        farmId.trim().isEmpty) {
      throw ArgumentError('Selecione uma fazenda autorizada.');
    }
    if (!uniqueAreaConfirmed) {
      throw ArgumentError('Confirme que a área não contém sobreposição.');
    }
    if (!effectiveAreaHa.isFinite || effectiveAreaHa <= 0) {
      throw ArgumentError('Informe uma área efetiva positiva em hectares.');
    }
    if (farmTotalAreaHa != null &&
        farmTotalAreaHa.isFinite &&
        farmTotalAreaHa > 0 &&
        effectiveAreaHa > farmTotalAreaHa) {
      throw ArgumentError('A área de pasto supera a área total da fazenda.');
    }
    if (grazingAnimals <= 0) {
      throw ArgumentError('Informe quantos animais estão em pastejo.');
    }
    if (recordedAt.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      throw ArgumentError('A data da confirmação está no futuro.');
    }
  }
}

class AtlasPastureGrazingBasisService {
  AtlasPastureGrazingBasisService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  static const _keyPrefix = 'atlas_pasture_grazing_basis_v1_';
  static final Map<String, Future<void>> _writes = {};

  String _key(String tenantId, String companyId, String farmId) {
    if (tenantId.trim().isEmpty ||
        companyId.trim().isEmpty ||
        farmId.trim().isEmpty) {
      throw ArgumentError('Identidade da fazenda incompleta.');
    }
    final scope = base64Url.encode(
      utf8.encode(jsonEncode([tenantId, companyId, farmId])),
    );
    return '$_keyPrefix$scope';
  }

  Future<List<AtlasPastureGrazingBasis>> loadHistory({
    required String tenantId,
    required String companyId,
    required String farmId,
    bool strict = false,
  }) async {
    final raw = await _preferences.getString(_key(tenantId, companyId, farmId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final records = <AtlasPastureGrazingBasis>[];
      for (final item in decoded) {
        if (item is! Map) {
          if (strict) throw const FormatException('Registro ilegível.');
          continue;
        }
        try {
          final basis = AtlasPastureGrazingBasis.fromMap(
            Map<String, dynamic>.from(item),
          );
          basis.validate();
          if (basis.tenantId == tenantId &&
              basis.companyId == companyId &&
              basis.farmId == farmId) {
            records.add(basis);
          } else if (strict) {
            throw const FormatException('Registro de outra fazenda.');
          }
        } catch (_) {
          if (strict) rethrow;
          // Registro ilegível ou de outro escopo nunca vira indicador.
        }
      }
      records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return records;
    } catch (_) {
      if (strict) rethrow;
      return const [];
    }
  }

  Future<AtlasPastureGrazingBasis?> loadLatest({
    required String tenantId,
    required String companyId,
    required String farmId,
  }) async {
    final history = await loadHistory(
      tenantId: tenantId,
      companyId: companyId,
      farmId: farmId,
    );
    return history.isEmpty ? null : history.first;
  }

  Future<void> save(
    AtlasPastureGrazingBasis basis, {
    double? farmTotalAreaHa,
  }) async {
    basis.validate(farmTotalAreaHa: farmTotalAreaHa);
    final key = _key(basis.tenantId, basis.companyId, basis.farmId);
    final previous = _writes[key] ?? Future<void>.value();
    final write = previous.then((_) async {
      final history = await loadHistory(
        tenantId: basis.tenantId,
        companyId: basis.companyId,
        farmId: basis.farmId,
        strict: true,
      );
      final existing = history.where(
        (item) => item.operationId == basis.operationId,
      );
      if (existing.isNotEmpty) {
        if (jsonEncode(existing.first.toMap()) != jsonEncode(basis.toMap())) {
          throw StateError('A mesma operação contém dados diferentes.');
        }
        return;
      }
      await _preferences.setString(
        key,
        jsonEncode([basis.toMap(), ...history.map((item) => item.toMap())]),
      );
    });
    final tail = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _writes[key] = tail;
    try {
      await write;
    } finally {
      if (identical(_writes[key], tail)) _writes.remove(key);
    }
  }
}
