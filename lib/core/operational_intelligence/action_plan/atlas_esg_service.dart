import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_esg_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasEsgService {
  AtlasEsgService._();

  static final AtlasEsgService instance = AtlasEsgService._();

  static const String _recordsKey = 'atlas_esg_records_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasEsgRecord>> loadRecords({String? farmName}) async {
    final raw = await _preferences.getString(_recordsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <AtlasEsgRecord>[];
    }

    try {
      final values = (jsonDecode(raw) as List)
          .map(
            (item) =>
                AtlasEsgRecord.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      final normalized = farmName?.trim().toLowerCase();
      final filtered = normalized == null || normalized.isEmpty
          ? values
          : values
                .where(
                  (item) => item.farmName?.trim().toLowerCase() == normalized,
                )
                .toList();
      filtered.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return filtered;
    } catch (_) {
      return <AtlasEsgRecord>[];
    }
  }

  Future<void> saveRecord(AtlasEsgRecord record) async {
    final raw = await _preferences.getString(_recordsKey);
    final values = raw == null || raw.trim().isEmpty
        ? <AtlasEsgRecord>[]
        : (jsonDecode(raw) as List)
              .map(
                (item) => AtlasEsgRecord.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();

    final index = values.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      values.add(record);
    } else {
      values[index] = record;
    }

    await _preferences.setString(
      _recordsKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }

  Future<AtlasEsgExecutiveSnapshot> buildSnapshot({String? farmName}) async {
    final records = await loadRecords(farmName: farmName);

    double total(AtlasEsgCategory category, String unit) {
      return records
          .where(
            (item) =>
                item.category == category &&
                item.unit.trim().toLowerCase() == unit.toLowerCase(),
          )
          .fold<double>(0, (sum, item) => sum + item.value);
    }

    final enteric = records
        .where(
          (item) =>
              item.category == AtlasEsgCategory.carbon &&
              item.title.toLowerCase().contains('entérico'),
        )
        .fold<double>(0, (sum, item) => sum + item.value);
    final manure = records
        .where(
          (item) =>
              item.category == AtlasEsgCategory.carbon &&
              item.title.toLowerCase().contains('dejeto'),
        )
        .fold<double>(0, (sum, item) => sum + item.value);
    final fuel = records
        .where(
          (item) =>
              item.category == AtlasEsgCategory.carbon &&
              item.title.toLowerCase().contains('combustível'),
        )
        .fold<double>(0, (sum, item) => sum + item.value);
    final electricity = records
        .where(
          (item) =>
              item.category == AtlasEsgCategory.carbon &&
              item.title.toLowerCase().contains('eletric'),
        )
        .fold<double>(0, (sum, item) => sum + item.value);
    final soil = records
        .where(
          (item) =>
              item.category == AtlasEsgCategory.carbon &&
              (item.title.toLowerCase().contains('solo') ||
                  item.title.toLowerCase().contains('fertilizante')),
        )
        .fold<double>(0, (sum, item) => sum + item.value);
    final sequestration = records
        .where(
          (item) =>
              item.category == AtlasEsgCategory.carbon &&
              item.title.toLowerCase().contains('sequestro'),
        )
        .fold<double>(0, (sum, item) => sum + item.value);

    final water = total(AtlasEsgCategory.water, 'm³');
    final energy = total(AtlasEsgCategory.energy, 'kWh');
    final renewableEnergy = records
        .where(
          (item) =>
              item.category == AtlasEsgCategory.energy &&
              item.title.toLowerCase().contains('renovável'),
        )
        .fold<double>(0, (sum, item) => sum + item.value);
    final preservedArea = total(AtlasEsgCategory.preservation, 'ha');
    final recoveredArea = records
        .where(
          (item) =>
              item.category == AtlasEsgCategory.preservation &&
              item.title.toLowerCase().contains('recuper'),
        )
        .fold<double>(0, (sum, item) => sum + item.value);

    final wasteRecords = records
        .where((item) => item.category == AtlasEsgCategory.waste)
        .toList();
    final wasteRecovered = wasteRecords.isEmpty
        ? 0.0
        : wasteRecords
                  .where(
                    (item) =>
                        item.title.toLowerCase().contains('recic') ||
                        item.title.toLowerCase().contains('reaprov'),
                  )
                  .fold<double>(0, (sum, item) => sum + item.value) /
              wasteRecords.fold<double>(0, (sum, item) => sum + item.value) *
              100;

    final socialRecords = records.where(
      (item) => item.category == AtlasEsgCategory.social,
    );
    final governanceRecords = records.where(
      (item) => item.category == AtlasEsgCategory.governance,
    );

    final socialScore = (50 + socialRecords.length * 8).clamp(0, 100);
    final governanceScore = (50 + governanceRecords.length * 8).clamp(0, 100);

    final carbonInventory = AtlasCarbonInventory(
      entericMethaneTco2e: enteric,
      manureTco2e: manure,
      fuelTco2e: fuel,
      electricityTco2e: electricity,
      soilAndFertilizerTco2e: soil,
      sequestrationTco2e: sequestration,
    );

    var score = 50.0;
    score += preservedArea > 0 ? 10 : 0;
    score += recoveredArea > 0 ? 10 : 0;
    score += wasteRecovered.clamp(0, 100) * 0.1;
    score += renewableEnergy > 0 ? 8 : 0;
    score += (socialScore - 50) * 0.15;
    score += (governanceScore - 50) * 0.15;
    if (carbonInventory.netEmissionsTco2e <= 0 &&
        carbonInventory.grossEmissionsTco2e > 0) {
      score += 12;
    }

    return AtlasEsgExecutiveSnapshot(
      carbonInventory: carbonInventory,
      waterConsumptionM3: water,
      energyConsumptionKwh: energy,
      renewableEnergyPercent: energy <= 0 ? 0 : renewableEnergy / energy * 100,
      preservedAreaHectares: preservedArea,
      recoveredAreaHectares: recoveredArea,
      wasteRecoveredPercent: wasteRecovered.isFinite ? wasteRecovered : 0,
      socialScore: socialScore.toDouble(),
      governanceScore: governanceScore.toDouble(),
      esgScore: score.clamp(0, 100),
    );
  }

  Future<List<String>> buildRecommendations({
    required String? farmName,
    required AtlasEsgExecutiveSnapshot snapshot,
  }) async {
    final recommendations = <String>[];

    if (snapshot.carbonInventory.netEmissionsTco2e > 0) {
      recommendations.add(
        'O inventário apresenta emissões líquidas positivas. Priorize eficiência alimentar, manejo de dejetos e sequestro de carbono.',
      );
    }
    if (snapshot.renewableEnergyPercent < 20 &&
        snapshot.energyConsumptionKwh > 0) {
      recommendations.add(
        'Participação de energia renovável abaixo de 20%. Avalie geração solar e eficiência energética.',
      );
    }
    if (snapshot.recoveredAreaHectares <= 0) {
      recommendations.add(
        'Nenhuma área em recuperação foi registrada. Cadastre ações ambientais e metas anuais.',
      );
    }
    if (snapshot.wasteRecoveredPercent < 50) {
      recommendations.add(
        'Recuperação de resíduos abaixo de 50%. Estruture segregação, reciclagem e destinação comprovada.',
      );
    }
    if (snapshot.governanceScore < 70) {
      recommendations.add(
        'Fortaleça governança com evidências, responsáveis, auditorias e indicadores periódicos.',
      );
    }
    if (recommendations.isEmpty) {
      recommendations.add(
        'Os indicadores ESG estão equilibrados. Continue registrando evidências e metas de melhoria.',
      );
    }

    return recommendations;
  }
}
