import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_strategy_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasReproductiveStrategyService {
  AtlasReproductiveStrategyService._();

  static final AtlasReproductiveStrategyService instance =
      AtlasReproductiveStrategyService._();

  static const String _plansKey =
      'atlas_reproductive_annual_plans_v1';
  static const String _simulationsKey =
      'atlas_reproductive_simulations_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasReproductiveAnnualPlan>> loadPlans({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _plansKey,
      AtlasReproductiveAnnualPlan.fromMap,
    );
    final filtered = _filterFarm(
      values,
      farmName,
      (item) => item.farmName,
    )..sort((a, b) => b.year.compareTo(a.year));
    return filtered;
  }

  Future<void> savePlan(
    AtlasReproductiveAnnualPlan plan,
  ) async {
    final values = await _decodeList(
      _plansKey,
      AtlasReproductiveAnnualPlan.fromMap,
    );
    _upsert(values, plan, (item) => item.id);
    await _saveList(
      _plansKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasReproductiveSimulation>>
      loadSimulations({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _simulationsKey,
      AtlasReproductiveSimulation.fromMap,
    );
    return _filterFarm(
      values,
      farmName,
      (item) => item.farmName,
    );
  }

  Future<void> saveSimulation(
    AtlasReproductiveSimulation simulation,
  ) async {
    final values = await _decodeList(
      _simulationsKey,
      AtlasReproductiveSimulation.fromMap,
    );
    _upsert(values, simulation, (item) => item.id);
    await _saveList(
      _simulationsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<AtlasReproductiveExecutiveSnapshot> buildSnapshot({
    String? farmName,
  }) async {
    final service = AtlasReproductiveService.instance;
    final events = await service.loadEvents(
      farmName: farmName,
    );

    final totalEvents = events.length;
    final inseminations = events.where((item) {
      return item.type == AtlasReproductiveEventType.fixedTimeAi ||
          item.type == AtlasReproductiveEventType.insemination;
    }).length;

    final diagnoses = events.where((item) {
      return item.type ==
          AtlasReproductiveEventType.pregnancyDiagnosis;
    }).toList();

    final positive = diagnoses.where((item) {
      final result = item.result.toLowerCase();
      return result.contains('posit') ||
          result.contains('prenhe');
    }).length;

    final negative = diagnoses.where((item) {
      final result = item.result.toLowerCase();
      return result.contains('negat') ||
          result.contains('vazia');
    }).length;

    final births = events.where((item) {
      return item.type == AtlasReproductiveEventType.calving;
    }).length;

    final abortions = events.where((item) {
      return item.type == AtlasReproductiveEventType.abortion;
    }).length;

    final pregnancyRate = diagnoses.isEmpty
        ? 0.0
        : positive / diagnoses.length * 100;

    final conceptionRate = inseminations <= 0
        ? 0.0
        : positive / inseminations * 100;

    final lossesBase = births + abortions;
    final lossRate = lossesBase <= 0
        ? 0.0
        : abortions / lossesBase * 100;

    final projectedBirths =
        (positive * (1 - lossRate / 100)).round();

    var score = 50.0;
    score += (pregnancyRate - 50) * 0.4;
    score += (conceptionRate - 40) * 0.3;
    score -= lossRate * 0.8;
    score += births > 0 ? 5 : 0;

    return AtlasReproductiveExecutiveSnapshot(
      totalEvents: totalEvents,
      inseminations: inseminations,
      pregnancyDiagnoses: diagnoses.length,
      positivePregnancies: positive,
      negativePregnancies: negative,
      births: births,
      abortions: abortions,
      pregnancyRatePercent: pregnancyRate,
      conceptionRatePercent: conceptionRate,
      lossRatePercent: lossRate,
      projectedBirths: projectedBirths,
      reproductiveScore: score.clamp(0, 100),
    );
  }

  Future<List<String>> buildIntelligence({
    required String? farmName,
    required AtlasReproductiveExecutiveSnapshot snapshot,
  }) async {
    final alerts = <String>[];

    if (snapshot.pregnancyRatePercent < 45) {
      alerts.add(
        'Taxa de prenhez abaixo de 45%. Revise condição corporal, protocolo e manejo.',
      );
    }
    if (snapshot.conceptionRatePercent < 35) {
      alerts.add(
        'Taxa de concepção baixa. Avalie sêmen, técnica, momento da IA e fertilidade das matrizes.',
      );
    }
    if (snapshot.lossRatePercent > 5) {
      alerts.add(
        'Perdas gestacionais acima de 5%. Investigue sanidade, nutrição e manejo.',
      );
    }
    if (snapshot.negativePregnancies > 0) {
      alerts.add(
        '${snapshot.negativePregnancies} diagnóstico(s) negativo(s) exigem decisão de ressincronização ou descarte.',
      );
    }

    final events = await AtlasReproductiveService.instance
        .loadEvents(farmName: farmName);
    final pendingDiagnosis = events.where((item) {
      final age = DateTime.now().difference(item.occurredAt).inDays;
      final isInsemination =
          item.type == AtlasReproductiveEventType.fixedTimeAi ||
          item.type == AtlasReproductiveEventType.insemination;
      return isInsemination && age >= 28 && age <= 60;
    }).length;

    if (pendingDiagnosis > 0) {
      alerts.add(
        '$pendingDiagnosis procedimento(s) podem estar na janela de diagnóstico de gestação.',
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        'Os principais indicadores reprodutivos estão dentro de uma faixa operacional adequada.',
      );
    }
    return alerts;
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final encoded = await _preferences.getString(key);
    if (encoded == null || encoded.trim().isEmpty) {
      return <T>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
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
