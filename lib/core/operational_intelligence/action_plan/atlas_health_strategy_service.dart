import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_intelligence_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_strategy_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasHealthStrategyService {
  AtlasHealthStrategyService._();

  static final AtlasHealthStrategyService instance =
      AtlasHealthStrategyService._();

  static const String _plansKey =
      'atlas_health_annual_plans_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasHealthAnnualPlan>> loadPlans({
    String? farmName,
  }) async {
    final raw = await _preferences.getString(_plansKey);
    if (raw == null || raw.trim().isEmpty) {
      return <AtlasHealthAnnualPlan>[];
    }
    try {
      final values = (jsonDecode(raw) as List)
          .map(
            (item) => AtlasHealthAnnualPlan.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final normalized = farmName?.trim().toLowerCase();
      if (normalized == null || normalized.isEmpty) {
        return values;
      }
      return values
          .where(
            (item) =>
                item.farmName?.trim().toLowerCase() ==
                normalized,
          )
          .toList();
    } catch (_) {
      return <AtlasHealthAnnualPlan>[];
    }
  }

  Future<void> savePlan(AtlasHealthAnnualPlan plan) async {
    final raw = await _preferences.getString(_plansKey);
    final values = raw == null || raw.trim().isEmpty
        ? <AtlasHealthAnnualPlan>[]
        : (jsonDecode(raw) as List)
            .map(
              (item) => AtlasHealthAnnualPlan.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

    final index =
        values.indexWhere((item) => item.id == plan.id);
    if (index == -1) {
      values.add(plan);
    } else {
      values[index] = plan;
    }

    await _preferences.setString(
      _plansKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }

  Future<AtlasHealthExecutiveSnapshot> buildSnapshot({
    String? farmName,
  }) async {
    final service = AtlasHealthIntelligenceService.instance;
    final events = await service.loadEvents(farmName: farmName);
    final protocols =
        await service.loadProtocols(farmName: farmName);

    final animals = events
        .map((item) => item.animalId)
        .where((item) => item.trim().isNotEmpty)
        .toSet();
    final denominator =
        animals.isEmpty ? events.length : animals.length;

    int count(AtlasHealthEventType type) =>
        events.where((item) => item.type == type).length;

    final vaccinations =
        count(AtlasHealthEventType.vaccination);
    final dewormings =
        count(AtlasHealthEventType.deworming);
    final treatments =
        count(AtlasHealthEventType.treatment);
    final morbidity =
        count(AtlasHealthEventType.morbidity);
    final mortality =
        count(AtlasHealthEventType.mortality);
    final quarantine =
        count(AtlasHealthEventType.quarantine);

    final protocolCoverage = protocols.isEmpty
        ? 0.0
        : protocols
                .where((item) => item.active)
                .length /
            protocols.length *
            100;

    final morbidityRate =
        denominator <= 0 ? 0.0 : morbidity / denominator * 100;
    final mortalityRate =
        denominator <= 0 ? 0.0 : mortality / denominator * 100;

    var score = 100.0;
    score -= morbidityRate * 2;
    score -= mortalityRate * 5;
    score -= quarantine * 2;
    score += protocolCoverage * 0.15;
    score += vaccinations > 0 ? 5 : 0;

    return AtlasHealthExecutiveSnapshot(
      totalEvents: events.length,
      vaccinations: vaccinations,
      dewormings: dewormings,
      treatments: treatments,
      morbidityCases: morbidity,
      mortalityCases: mortality,
      quarantineCases: quarantine,
      totalCost: events.fold<double>(
        0,
        (total, item) => total + item.cost,
      ),
      morbidityRatePercent: morbidityRate,
      mortalityRatePercent: mortalityRate,
      protocolCoveragePercent: protocolCoverage,
      healthScore: score.clamp(0, 100),
    );
  }

  Future<List<AtlasEpidemiologicalCluster>> buildClusters({
    String? farmName,
  }) async {
    final events = await AtlasHealthIntelligenceService.instance
        .loadEvents(farmName: farmName);

    final grouped = <String, List<AtlasHealthEvent>>{};
    for (final event in events) {
      final key = event.lotName.trim().isNotEmpty
          ? 'lote:${event.lotName}'
          : event.paddockName.trim().isNotEmpty
              ? 'piquete:${event.paddockName}'
              : 'geral';
      grouped.putIfAbsent(key, () => []).add(event);
    }

    final result = grouped.entries.map((entry) {
      final values = entry.value;
      final morbidity = values
          .where(
            (item) =>
                item.type == AtlasHealthEventType.morbidity,
          )
          .length;
      final mortality = values
          .where(
            (item) =>
                item.type == AtlasHealthEventType.mortality,
          )
          .length;
      final cost = values.fold<double>(
        0,
        (total, item) => total + item.cost,
      );

      return AtlasEpidemiologicalCluster(
        key: entry.key,
        label: entry.key == 'geral'
            ? 'Sem lote/piquete'
            : entry.key.split(':').last,
        caseCount: morbidity,
        mortalityCount: mortality,
        totalCost: cost,
        riskScore:
            (morbidity * 8 + mortality * 20 + cost / 100)
                .clamp(0, 100),
      );
    }).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return result;
  }

  Future<List<String>> buildRecommendations({
    required String? farmName,
    required AtlasHealthExecutiveSnapshot snapshot,
  }) async {
    final recommendations = <String>[];

    if (snapshot.morbidityRatePercent > 5) {
      recommendations.add(
        'Morbidade acima de 5%. Reforce diagnóstico, isolamento e investigação epidemiológica.',
      );
    }
    if (snapshot.mortalityRatePercent > 1) {
      recommendations.add(
        'Mortalidade acima de 1%. Abra auditoria clínica e revise protocolos de atendimento.',
      );
    }
    if (snapshot.protocolCoveragePercent < 80) {
      recommendations.add(
        'Cobertura de protocolos abaixo de 80%. Atualize o calendário sanitário e os responsáveis.',
      );
    }
    if (snapshot.quarantineCases > 0) {
      recommendations.add(
        '${snapshot.quarantineCases} evento(s) de quarentena exigem acompanhamento e critérios de liberação.',
      );
    }

    final medications =
        await AtlasHealthIntelligenceService.instance
            .loadMedications(farmName: farmName);
    final expiring = medications
        .where((item) => item.isExpired || item.expiresSoon)
        .length;
    if (expiring > 0) {
      recommendations.add(
        '$expiring medicamento(s) estão vencidos ou próximos do vencimento.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'A situação sanitária está equilibrada. Preserve vigilância, calendário e rastreabilidade.',
      );
    }
    return recommendations;
  }
}
