import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_agriculture_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasAgricultureService {
  AtlasAgricultureService._();

  static final AtlasAgricultureService instance =
      AtlasAgricultureService._();

  static const String _fieldsKey =
      'atlas_agriculture_fields_v1';
  static const String _soilSamplesKey =
      'atlas_agriculture_soil_samples_v1';
  static const String _operationsKey =
      'atlas_agriculture_operations_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasCropField>> loadFields({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _fieldsKey,
      AtlasCropField.fromMap,
    );
    return _filterFarm(
      values,
      farmName,
      (item) => item.farmName,
    )..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveField(AtlasCropField field) async {
    final values = await _decodeList(
      _fieldsKey,
      AtlasCropField.fromMap,
    );
    _upsert(values, field, (item) => item.id);
    await _saveList(
      _fieldsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasSoilSample>> loadSoilSamples({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _soilSamplesKey,
      AtlasSoilSample.fromMap,
    );
    return _filterFarm(
      values,
      farmName,
      (item) => item.farmName,
    )..sort((a, b) => b.sampledAt.compareTo(a.sampledAt));
  }

  Future<void> saveSoilSample(
    AtlasSoilSample sample,
  ) async {
    final values = await _decodeList(
      _soilSamplesKey,
      AtlasSoilSample.fromMap,
    );
    _upsert(values, sample, (item) => item.id);
    await _saveList(
      _soilSamplesKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasAgriculturalOperation>> loadOperations({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _operationsKey,
      AtlasAgriculturalOperation.fromMap,
    );
    return _filterFarm(
      values,
      farmName,
      (item) => item.farmName,
    )..sort(
        (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
      );
  }

  Future<void> saveOperation(
    AtlasAgriculturalOperation operation,
  ) async {
    final values = await _decodeList(
      _operationsKey,
      AtlasAgriculturalOperation.fromMap,
    );
    _upsert(values, operation, (item) => item.id);
    await _saveList(
      _operationsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<AtlasAgricultureExecutiveSnapshot> buildSnapshot({
    String? farmName,
  }) async {
    final fields = await loadFields(farmName: farmName);
    final samples =
        await loadSoilSamples(farmName: farmName);
    final operations =
        await loadOperations(farmName: farmName);

    final totalArea = fields.fold<double>(
      0,
      (total, item) => total + item.areaHectares,
    );
    final plantedArea = fields
        .where(
          (item) =>
              item.status == AtlasCropStatus.planted ||
              item.status == AtlasCropStatus.developing ||
              item.status == AtlasCropStatus.harvesting,
        )
        .fold<double>(
          0,
          (total, item) => total + item.areaHectares,
        );
    final integratedArea = fields
        .where((item) => item.integratedLivestock)
        .fold<double>(
          0,
          (total, item) => total + item.areaHectares,
        );

    double averageField(
      double Function(AtlasCropField item) value,
    ) {
      if (fields.isEmpty) {
        return 0;
      }
      return fields.fold<double>(
            0,
            (total, item) => total + value(item),
          ) /
          fields.length;
    }

    final averageSoil = samples.isEmpty
        ? 0.0
        : samples.fold<double>(
              0,
              (total, item) => total + item.soilScore,
            ) /
            samples.length;

    final overdue =
        operations.where((item) => item.isOverdue).length;
    final cost = operations.fold<double>(
      0,
      (total, item) => total + item.cost,
    );

    final target =
        averageField((item) => item.targetProductivityKgHa);
    final actual =
        averageField((item) => item.actualProductivityKgHa);

    var score = 75.0;
    score += (averageSoil - 60) * 0.25;
    score -= overdue * 5;
    if (target > 0 && actual > 0) {
      score += ((actual / target * 100) - 80) * 0.2;
    }
    if (fields.isEmpty) {
      score = 0;
    }

    return AtlasAgricultureExecutiveSnapshot(
      totalFields: fields.length,
      totalAreaHectares: totalArea,
      plantedAreaHectares: plantedArea,
      integratedAreaHectares: integratedArea,
      averageTargetProductivityKgHa: target,
      averageActualProductivityKgHa: actual,
      totalOperatingCost: cost,
      overdueOperations: overdue,
      averageSoilScore: averageSoil,
      agricultureScore: score.clamp(0, 100),
    );
  }

  Future<List<String>> buildRecommendations({
    required String? farmName,
    required AtlasAgricultureExecutiveSnapshot snapshot,
  }) async {
    final recommendations = <String>[];
    final fields = await loadFields(farmName: farmName);
    final samples =
        await loadSoilSamples(farmName: farmName);

    if (snapshot.averageSoilScore > 0 &&
        snapshot.averageSoilScore < 60) {
      recommendations.add(
        'Fertilidade média do solo abaixo da meta. Priorize correção, matéria orgânica e adubação baseada em análise.',
      );
    }
    if (snapshot.overdueOperations > 0) {
      recommendations.add(
        '${snapshot.overdueOperations} operação(ões) agrícolas estão atrasadas.',
      );
    }
    if (snapshot.averageTargetProductivityKgHa > 0 &&
        snapshot.averageActualProductivityKgHa > 0 &&
        snapshot.averageActualProductivityKgHa <
            snapshot.averageTargetProductivityKgHa * 0.8) {
      recommendations.add(
        'Produtividade realizada abaixo de 80% da meta. Revise solo, clima, sementes e manejo.',
      );
    }
    if (snapshot.integratedAreaHectares == 0 &&
        snapshot.totalAreaHectares > 0) {
      recommendations.add(
        'Nenhuma área está marcada como integração lavoura-pecuária. Avalie sinergias com pastagens e alimentação.',
      );
    }

    final lowPh =
        samples.where((item) => item.ph < 5.2).length;
    if (lowPh > 0) {
      recommendations.add(
        '$lowPh amostra(s) apresentam pH abaixo de 5,2.',
      );
    }

    final harvestingSoon = fields.where((item) {
      final date = item.expectedHarvestAt;
      if (date == null) return false;
      final days = date.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 30;
    }).length;
    if (harvestingSoon > 0) {
      recommendations.add(
        '$harvestingSoon lavoura(s) têm colheita prevista nos próximos 30 dias.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'A operação agrícola está equilibrada. Continue acompanhando solo, cronograma, custos e produtividade.',
      );
    }
    return recommendations;
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return <T>[];
    }
    try {
      return (jsonDecode(raw) as List)
          .map(
            (item) => fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> values,
  ) {
    return _preferences.setString(key, jsonEncode(values));
  }

  void _upsert<T>(
    List<T> values,
    T value,
    String Function(T) readId,
  ) {
    final index = values.indexWhere(
      (item) => readId(item) == readId(value),
    );
    if (index == -1) {
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  List<T> _filterFarm<T>(
    List<T> values,
    String? farmName,
    String? Function(T) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return values;
    }
    return values.where((value) {
      return readFarm(value)?.trim().toLowerCase() ==
          normalized;
    }).toList();
  }
}
