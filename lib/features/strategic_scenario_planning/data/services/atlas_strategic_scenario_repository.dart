import 'dart:convert';

import 'package:projeto_atlas/features/strategic_scenario_planning/domain/models/atlas_strategic_scenario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasStrategicScenarioRepository {
  AtlasStrategicScenarioRepository._();

  static final AtlasStrategicScenarioRepository instance =
      AtlasStrategicScenarioRepository._();

  static const String _storageKey =
      'atlas_strategic_scenarios_v1';

  Future<List<AtlasStrategicScenario>> loadAll() async {
    final preferences =
        await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return _seedScenarios();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return _seedScenarios();
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                AtlasStrategicScenario.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort(
          (first, second) =>
              second.createdAt.compareTo(
            first.createdAt,
          ),
        );
    } catch (_) {
      return _seedScenarios();
    }
  }

  Future<void> save(
    AtlasStrategicScenario scenario,
  ) async {
    final scenarios = await loadAll();
    final index = scenarios.indexWhere(
      (item) => item.id == scenario.id,
    );

    if (index >= 0) {
      scenarios[index] = scenario;
    } else {
      scenarios.insert(0, scenario);
    }

    await _write(scenarios);
  }

  Future<void> delete(String id) async {
    final scenarios = await loadAll()
      ..removeWhere((item) => item.id == id);

    await _write(scenarios);
  }

  Future<void> _write(
    List<AtlasStrategicScenario> scenarios,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        scenarios
            .take(100)
            .map((item) => item.toJson())
            .toList(),
      ),
    );
  }

  List<AtlasStrategicScenario> _seedScenarios() {
    final now = DateTime.now();

    return <AtlasStrategicScenario>[
      AtlasStrategicScenario(
        id: 'scenario_pasture_${now.millisecondsSinceEpoch}',
        farmId: '',
        farmName: 'Todas as fazendas',
        title: 'Intensificação de pastagens',
        description:
            'Recuperação, adubação e manejo rotacionado para elevar lotação e produção por hectare.',
        type:
            AtlasStrategicScenarioType.pastureIntensification,
        createdAt: now,
        horizonYears: 5,
        initialInvestment: 320000,
        workingCapital: 50000,
        annualAdditionalRevenue: 190000,
        annualAdditionalCost: 72000,
        residualValue: 80000,
        discountRatePercent: 12,
        priceSensitivityPercent: 12,
        costSensitivityPercent: 15,
        productiveImpacts: const AtlasProductiveImpacts(
          pregnancyRateChange: 3,
          weaningRateChange: 4,
          dailyGainChange: 0.12,
          stockingRateChange: 0.8,
          arrobasPerYearChange: 850,
          productivityPerHectareChange: 32,
          mortalityReduction: 0.4,
        ),
        risks: const AtlasScenarioRisks(
          climate: 58,
          sanitary: 28,
          financial: 48,
          operational: 50,
          market: 45,
        ),
      ),
      AtlasStrategicScenario(
        id: 'scenario_iatf_${now.millisecondsSinceEpoch + 1}',
        farmId: '',
        farmName: 'Todas as fazendas',
        title: 'Programa de IATF e genética',
        description:
            'Ampliação da taxa de serviço, concentração de partos e avanço genético do rebanho.',
        type: AtlasStrategicScenarioType.iatf,
        createdAt: now.subtract(
          const Duration(minutes: 1),
        ),
        horizonYears: 5,
        initialInvestment: 180000,
        workingCapital: 35000,
        annualAdditionalRevenue: 125000,
        annualAdditionalCost: 52000,
        residualValue: 40000,
        discountRatePercent: 12,
        priceSensitivityPercent: 10,
        costSensitivityPercent: 12,
        productiveImpacts: const AtlasProductiveImpacts(
          pregnancyRateChange: 10,
          weaningRateChange: 8,
          dailyGainChange: 0.04,
          stockingRateChange: 0.1,
          arrobasPerYearChange: 310,
          productivityPerHectareChange: 9,
          mortalityReduction: 0.3,
        ),
        risks: const AtlasScenarioRisks(
          climate: 30,
          sanitary: 38,
          financial: 35,
          operational: 55,
          market: 38,
        ),
      ),
      AtlasStrategicScenario(
        id: 'scenario_feedlot_${now.millisecondsSinceEpoch + 2}',
        farmId: '',
        farmName: 'Todas as fazendas',
        title: 'Confinamento modular',
        description:
            'Estrutura modular para terminação intensiva e aumento do giro do capital.',
        type: AtlasStrategicScenarioType.feedlot,
        createdAt: now.subtract(
          const Duration(minutes: 2),
        ),
        horizonYears: 6,
        initialInvestment: 980000,
        workingCapital: 300000,
        annualAdditionalRevenue: 760000,
        annualAdditionalCost: 510000,
        residualValue: 330000,
        discountRatePercent: 13,
        priceSensitivityPercent: 18,
        costSensitivityPercent: 20,
        productiveImpacts: const AtlasProductiveImpacts(
          pregnancyRateChange: 0,
          weaningRateChange: 0,
          dailyGainChange: 0.65,
          stockingRateChange: 1.2,
          arrobasPerYearChange: 2100,
          productivityPerHectareChange: 70,
          mortalityReduction: 0.2,
        ),
        risks: const AtlasScenarioRisks(
          climate: 32,
          sanitary: 52,
          financial: 76,
          operational: 72,
          market: 78,
        ),
      ),
    ];
  }
}
