import 'dart:convert';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NutritionStorageService {
  NutritionStorageService({AtlasHttpClient? httpClient})
    : _http = httpClient ?? AtlasHttpClient();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasHttpClient _http;

  static const String _allFarmsStorageKey = 'atlas_nutrition_plans_all';

  String _farmStorageKey(String farmId) =>
      'atlas_nutrition_plans_${farmId.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')}';

  Future<List<NutritionPlanData>> loadPlans({
    String farmId = '',
    String farmName = '',
  }) async {
    final id = farmId.trim();
    if (id.isEmpty) {
      try {
        final farmsResponse = await _http.send('GET', '/farms');
        final all = <NutritionPlanData>[];
        for (final farm in farmsResponse.asMapList()) {
          final currentFarmId = farm['id']?.toString() ?? '';
          if (currentFarmId.isEmpty || farm['active'] == false) {
            continue;
          }
          all.addAll(
            await loadPlans(
              farmId: currentFarmId,
              farmName: farm['name']?.toString() ?? '',
            ),
          );
        }
        await _saveLocal(_allFarmsStorageKey, all);
        return all;
      } catch (_) {
        return _loadLocal(_allFarmsStorageKey);
      }
    }

    try {
      final plans = await _loadRemotePlans(farmId: id, farmName: farmName);
      await _saveLocal(_farmStorageKey(id), plans);
      return plans;
    } catch (_) {
      return _loadLocal(_farmStorageKey(id));
    }
  }

  Future<NutritionPlanData> savePlan({
    required String farmId,
    required NutritionPlanData plan,
    required bool isNew,
  }) async {
    final id = farmId.trim();
    if (id.isEmpty) {
      throw StateError(
        'A fazenda ativa é obrigatória para salvar a dieta no backend.',
      );
    }
    final lotId = await _resolveLotId(id, plan.groupName);
    final payload = _toApi(plan, farmId: id, lotId: lotId);
    final response = await _http.send(
      isNew ? 'POST' : 'PATCH',
      isNew
          ? '/livestock/nutrition/plans'
          : '/livestock/nutrition/plans/${plan.id}',
      body: payload,
    );
    final immediate = _fromApi(
      response.asMap(),
      lotNames: {lotId: plan.groupName},
      fallback: plan,
      farmName: plan.farmName,
    );

    // Persistência verificada: só devolve sucesso depois de reler do servidor.
    final remotePlans = await _loadRemotePlans(
      farmId: id,
      farmName: plan.farmName,
    );
    NutritionPlanData? verified;
    for (final item in remotePlans) {
      if (item.id == immediate.id) {
        verified = item;
        break;
      }
    }
    if (verified == null) {
      throw StateError(
        'A dieta não foi confirmada após nova leitura do servidor.',
      );
    }
    await _saveLocal(_farmStorageKey(id), remotePlans);
    return verified;
  }

  Future<void> deletePlan({
    required String farmId,
    required NutritionPlanData plan,
  }) async {
    final id = farmId.trim();
    await _http.send('DELETE', '/livestock/nutrition/plans/${plan.id}');
    if (id.isNotEmpty) {
      final remotePlans = await _loadRemotePlans(
        farmId: id,
        farmName: plan.farmName,
      );
      if (remotePlans.any((item) => item.id == plan.id)) {
        throw StateError(
          'A exclusão da dieta não foi confirmada pelo servidor.',
        );
      }
      await _saveLocal(_farmStorageKey(id), remotePlans);
    }
  }

  Future<void> savePlans(List<NutritionPlanData> plans) =>
      _saveLocal(_allFarmsStorageKey, plans);

  Future<List<NutritionPlanData>> _loadRemotePlans({
    required String farmId,
    required String farmName,
  }) async {
    final lotsResponse = await _http.send(
      'GET',
      '/livestock/lots',
      queryParameters: {'farm_id': farmId},
    );
    final lotNames = <String, String>{
      for (final item in lotsResponse.asMapList())
        item['id']?.toString() ?? '': item['name']?.toString() ?? '',
    };
    final response = await _http.send(
      'GET',
      '/livestock/nutrition/plans',
      queryParameters: {'farm_id': farmId},
    );
    final plans = <NutritionPlanData>[];
    for (final map in response.asMapList()) {
      final lotId = map['lot_id']?.toString() ?? '';
      var plan = _fromApi(map, lotNames: lotNames, farmName: farmName);
      if (lotId.isNotEmpty) {
        plan = await _enrichPerformance(plan, farmId: farmId, lotId: lotId);
      }
      plans.add(plan);
    }
    return plans;
  }

  Future<NutritionPlanData> _enrichPerformance(
    NutritionPlanData plan, {
    required String farmId,
    required String lotId,
  }) async {
    try {
      final animalsResponse = await _http.send(
        'GET',
        '/livestock/animals',
        queryParameters: {'farm_id': farmId, 'lot_id': lotId},
      );
      final animals = animalsResponse.asMapList();
      if (animals.isEmpty) {
        return plan.copyWith(
          animalCount: 0,
          averageBodyWeightKg: 0,
          observedDailyGainKg: 0,
          feedConversion: 0,
        );
      }

      final currentWeights = animals
          .map((item) => (item['current_weight'] as num?)?.toDouble() ?? 0)
          .where((value) => value > 0)
          .toList(growable: false);
      final averageWeight = currentWeights.isEmpty
          ? plan.averageBodyWeightKg
          : currentWeights.reduce((a, b) => a + b) / currentWeights.length;

      final gains = <double>[];
      for (final animal in animals) {
        final animalId = animal['id']?.toString() ?? '';
        if (animalId.isEmpty) continue;
        try {
          final response = await _http.send(
            'GET',
            '/livestock/animals/$animalId/weights',
          );
          final weights = response.asMapList()
            ..sort((a, b) {
              final first = DateTime.tryParse(
                a['measured_at']?.toString() ?? '',
              );
              final second = DateTime.tryParse(
                b['measured_at']?.toString() ?? '',
              );
              if (first == null && second == null) return 0;
              if (first == null) return -1;
              if (second == null) return 1;
              return first.compareTo(second);
            });
          if (weights.length < 2) continue;
          final previous = weights[weights.length - 2];
          final latest = weights.last;
          final previousAt = DateTime.tryParse(
            previous['measured_at']?.toString() ?? '',
          );
          final latestAt = DateTime.tryParse(
            latest['measured_at']?.toString() ?? '',
          );
          final previousWeight = (previous['weight'] as num?)?.toDouble() ?? 0;
          final latestWeight = (latest['weight'] as num?)?.toDouble() ?? 0;
          if (previousAt == null || latestAt == null) continue;
          final days = latestAt.difference(previousAt).inMinutes / 1440;
          if (days <= 0 || previousWeight <= 0 || latestWeight <= 0) continue;
          gains.add((latestWeight - previousWeight) / days);
        } catch (_) {
          // Uma pesagem individual indisponível não derruba o módulo inteiro.
        }
      }

      final observedGain = gains.isEmpty
          ? 0.0
          : gains.reduce((a, b) => a + b) / gains.length;
      final dryMatterIntake = plan.dailyAmountKg * plan.dryMatterPercent / 100;
      final conversion = observedGain > 0
          ? dryMatterIntake / observedGain
          : 0.0;

      return plan.copyWith(
        animalCount: animals.length,
        averageBodyWeightKg: averageWeight,
        observedDailyGainKg: observedGain,
        feedConversion: conversion,
      );
    } catch (_) {
      return plan;
    }
  }

  Future<List<NutritionPlanData>> _loadLocal(String key) async {
    final savedData = await _preferences.getString(key);
    if (savedData == null || savedData.isEmpty) {
      return [];
    }
    try {
      final decoded =
          AtlasTextNormalizer.normalize(jsonDecode(savedData)) as List<dynamic>;
      return decoded
          .map(
            (item) => NutritionPlanData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal(String key, List<NutritionPlanData> plans) =>
      _preferences.setString(
        key,
        jsonEncode(plans.map((plan) => plan.toMap()).toList()),
      );

  Future<String> _resolveLotId(String farmId, String groupName) async {
    final response = await _http.send(
      'GET',
      '/livestock/lots',
      queryParameters: {'farm_id': farmId},
    );
    final normalized = groupName.trim().toLowerCase();
    for (final item in response.asMapList()) {
      final id = item['id']?.toString() ?? '';
      final name = item['name']?.toString().trim().toLowerCase() ?? '';
      if (id == groupName || name == normalized) {
        return id;
      }
    }
    throw StateError(
      'Lote ou grupo "$groupName" não encontrado na fazenda ativa.',
    );
  }

  Map<String, dynamic> _toApi(
    NutritionPlanData plan, {
    required String farmId,
    required String lotId,
  }) => {
    'farm_id': farmId,
    'lot_id': lotId,
    'name': plan.dietName,
    'category': plan.category,
    'start_date': _dateToIso(plan.startDate),
    'daily_amount_per_animal_kg': plan.dailyAmountKg,
    'animal_count': plan.animalCount,
    'average_body_weight_kg': plan.averageBodyWeightKg,
    'target_daily_gain_kg': plan.targetDailyGainKg,
    'dry_matter_percent': plan.dryMatterPercent,
    'crude_protein_percent': plan.crudeProteinPercent,
    'ndf_percent': plan.ndfPercent,
    'tdn_percent': plan.tdnPercent,
    'cost_per_kg': plan.effectiveCostPerKg,
    'ingredients_json': plan.ingredients.map((item) => item.toMap()).toList(),
    'stock_integration_enabled': plan.stockIntegrationEnabled,
    'inventory_deducted': plan.inventoryDeducted,
    'inventory_deduction_cost': plan.inventoryDeductionCost,
    'notes': plan.notes,
  };

  NutritionPlanData _fromApi(
    Map<String, dynamic> map, {
    required Map<String, String> lotNames,
    String farmName = '',
    NutritionPlanData? fallback,
  }) {
    final lotId = map['lot_id']?.toString() ?? '';
    final rawIngredients = map['ingredients_json'];
    final dailyAmountKg =
        (map['daily_amount_per_animal_kg'] as num?)?.toDouble() ??
        fallback?.dailyAmountKg ??
        0;
    final ingredients = rawIngredients is List
        ? rawIngredients.whereType<Map>().map((item) {
            final raw = Map<String, dynamic>.from(item);
            // Compatibilidade com cargas/API que armazenaram participação em
            // percentual em vez de inclusionKg.
            if (!raw.containsKey('inclusionKg') && raw['percentage'] is num) {
              raw['inclusionKg'] =
                  dailyAmountKg * (raw['percentage'] as num).toDouble() / 100;
            }
            return NutritionIngredientData.fromMap(raw);
          }).toList()
        : (fallback?.ingredients ?? const <NutritionIngredientData>[]);
    return NutritionPlanData(
      id: map['id']?.toString() ?? fallback?.id ?? '',
      farmName: fallback?.farmName ?? farmName,
      groupName: lotNames[lotId] ?? fallback?.groupName ?? lotId,
      dietName: map['name']?.toString() ?? fallback?.dietName ?? '',
      category: map['category']?.toString() ?? fallback?.category ?? 'Outro',
      dailyAmountKg: dailyAmountKg,
      animalCount:
          (map['animal_count'] as num?)?.toInt() ?? fallback?.animalCount ?? 0,
      costPerKg:
          (map['cost_per_kg'] as num?)?.toDouble() ?? fallback?.costPerKg ?? 0,
      startDate: _isoToDate(map['start_date']),
      notes: map['notes']?.toString() ?? fallback?.notes ?? '',
      averageBodyWeightKg:
          (map['average_body_weight_kg'] as num?)?.toDouble() ??
          fallback?.averageBodyWeightKg ??
          0,
      targetDailyGainKg:
          (map['target_daily_gain_kg'] as num?)?.toDouble() ??
          fallback?.targetDailyGainKg ??
          0,
      observedDailyGainKg: fallback?.observedDailyGainKg ?? 0,
      feedConversion: fallback?.feedConversion ?? 0,
      pastureType: fallback?.pastureType ?? '',
      silageType: fallback?.silageType ?? '',
      concentrateType: fallback?.concentrateType ?? '',
      mineralSupplement: fallback?.mineralSupplement ?? '',
      dryMatterPercent:
          (map['dry_matter_percent'] as num?)?.toDouble() ??
          fallback?.dryMatterPercent ??
          0,
      crudeProteinPercent:
          (map['crude_protein_percent'] as num?)?.toDouble() ??
          fallback?.crudeProteinPercent ??
          0,
      ndfPercent:
          (map['ndf_percent'] as num?)?.toDouble() ?? fallback?.ndfPercent ?? 0,
      adfPercent: fallback?.adfPercent ?? 0,
      tdnPercent:
          (map['tdn_percent'] as num?)?.toDouble() ?? fallback?.tdnPercent ?? 0,
      stockIntegrationEnabled:
          map['stock_integration_enabled'] as bool? ??
          fallback?.stockIntegrationEnabled ??
          false,
      inventoryDeducted:
          map['inventory_deducted'] as bool? ??
          fallback?.inventoryDeducted ??
          false,
      inventoryDeductionCost:
          (map['inventory_deduction_cost'] as num?)?.toDouble() ??
          fallback?.inventoryDeductionCost ??
          0,
      ingredients: ingredients,
    );
  }

  String? _dateToIso(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) {
      return DateTime.tryParse(value)?.toUtc().toIso8601String();
    }
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    ).toUtc().toIso8601String();
  }

  String _isoToDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) {
      return '';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
