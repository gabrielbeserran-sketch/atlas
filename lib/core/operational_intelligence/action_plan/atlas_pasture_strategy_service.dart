import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_strategy_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasPastureStrategyService {
  AtlasPastureStrategyService._();

  static final AtlasPastureStrategyService instance =
      AtlasPastureStrategyService._();

  static const String _recoveryPlansKey =
      'atlas_pasture_recovery_plans_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasPastureRecoveryPlan>> loadRecoveryPlans({
    String? farmName,
  }) async {
    final raw =
        await _preferences.getString(_recoveryPlansKey);
    if (raw == null || raw.trim().isEmpty) {
      return <AtlasPastureRecoveryPlan>[];
    }

    try {
      final values = (jsonDecode(raw) as List)
          .map(
            (item) => AtlasPastureRecoveryPlan.fromMap(
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
      return <AtlasPastureRecoveryPlan>[];
    }
  }

  Future<void> saveRecoveryPlan(
    AtlasPastureRecoveryPlan plan,
  ) async {
    final raw =
        await _preferences.getString(_recoveryPlansKey);
    final values = raw == null || raw.trim().isEmpty
        ? <AtlasPastureRecoveryPlan>[]
        : (jsonDecode(raw) as List)
            .map(
              (item) => AtlasPastureRecoveryPlan.fromMap(
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
      _recoveryPlansKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }

  Future<AtlasPastureExecutiveSnapshot> buildSnapshot({
    String? farmName,
  }) async {
    final pastureService = AtlasPastureService.instance;
    final paddocks =
        await pastureService.loadPaddocks(farmName: farmName);
    final operations =
        await pastureService.loadOperations(farmName: farmName);

    final totalArea = paddocks.fold<double>(
      0,
      (total, item) => total + item.areaHectares,
    );

    double average(
      double Function(AtlasPaddock item) value,
    ) {
      if (paddocks.isEmpty) {
        return 0;
      }
      return paddocks.fold<double>(
            0,
            (total, item) => total + value(item),
          ) /
          paddocks.length;
    }

    final averageHeight =
        average((item) => item.currentHeightCm);
    final averageDryMatter =
        average((item) => item.dryMatterKgHa);
    final averageSupport =
        average((item) => item.supportCapacityAuHa);
    final totalSupportedAu = paddocks.fold<double>(
      0,
      (total, item) =>
          total +
          item.supportCapacityAuHa * item.areaHectares,
    );

    final overdue =
        operations.where((item) => item.isOverdue).length;
    final lowHeight =
        paddocks.where((item) => item.belowTargetHeight).length;
    final lowDryMatter =
        paddocks.where((item) => item.dryMatterKgHa < 1000).length;

    var score = 85.0;
    score -= lowHeight * 7;
    score -= lowDryMatter * 6;
    score -= overdue * 4;
    if (averageSupport < 1) {
      score -= 10;
    }
    if (paddocks.isEmpty) {
      score = 0;
    }

    return AtlasPastureExecutiveSnapshot(
      totalPaddocks: paddocks.length,
      totalAreaHectares: totalArea,
      availablePaddocks: paddocks
          .where(
            (item) =>
                item.status == AtlasPaddockStatus.available,
          )
          .length,
      occupiedPaddocks: paddocks
          .where(
            (item) =>
                item.status == AtlasPaddockStatus.occupied,
          )
          .length,
      restingPaddocks: paddocks
          .where(
            (item) =>
                item.status == AtlasPaddockStatus.resting,
          )
          .length,
      averageHeightCm: averageHeight,
      averageDryMatterKgHa: averageDryMatter,
      averageSupportCapacityAuHa: averageSupport,
      totalSupportedAu: totalSupportedAu,
      overdueOperations: overdue,
      pastureScore: score.clamp(0, 100),
    );
  }

  Future<List<AtlasPastureOccupationRecommendation>>
      buildOccupationRecommendations({
    String? farmName,
  }) async {
    final pastureService = AtlasPastureService.instance;
    final paddocks =
        await pastureService.loadPaddocks(farmName: farmName);

    return paddocks.map((item) {
      final supportedAu =
          item.supportCapacityAuHa * item.areaHectares;
      final recommendedAnimals =
          (supportedAu * 1.5).floor().clamp(0, 100000);
      final occupationDays = item.currentHeightCm >=
              item.targetHeightCm
          ? 4
          : item.currentHeightCm >=
                  item.targetHeightCm * 0.8
              ? 3
              : 0;
      final restDays = item.irrigated ? 22 : 30;
      final risk = item.dryMatterKgHa < 1000 ||
              item.belowTargetHeight
          ? 'Alto'
          : item.dryMatterKgHa < 1800
              ? 'Moderado'
              : 'Baixo';

      final reason = occupationDays == 0
          ? 'Não ocupar até recuperar altura e disponibilidade.'
          : 'Ocupação sugerida conforme área, suporte e altura atual.';

      return AtlasPastureOccupationRecommendation(
        paddockId: item.id,
        paddockName: item.name,
        recommendedAnimalCount: recommendedAnimals,
        recommendedOccupationDays: occupationDays,
        recommendedRestDays: restDays,
        riskLevel: risk,
        reason: reason,
      );
    }).toList()
      ..sort(
        (a, b) => a.riskLevel.compareTo(b.riskLevel),
      );
  }

  Future<List<String>> buildRecommendations({
    required String? farmName,
    required AtlasPastureExecutiveSnapshot snapshot,
  }) async {
    final recommendations = <String>[];

    if (snapshot.averageDryMatterKgHa < 1200) {
      recommendations.add(
        'Disponibilidade média de matéria seca baixa. Reduza lotação temporariamente e priorize recuperação.',
      );
    }
    if (snapshot.averageHeightCm < 20) {
      recommendations.add(
        'Altura média baixa. Revise período de descanso e momento de entrada dos lotes.',
      );
    }
    if (snapshot.overdueOperations > 0) {
      recommendations.add(
        '${snapshot.overdueOperations} operação(ões) de pastagem estão atrasadas.',
      );
    }
    if (snapshot.availablePaddocks == 0 &&
        snapshot.totalPaddocks > 0) {
      recommendations.add(
        'Nenhum piquete está disponível. Replaneje a rotação e avalie suplementação estratégica.',
      );
    }
    if (snapshot.averageSupportCapacityAuHa < 1) {
      recommendations.add(
        'Capacidade de suporte média inferior a 1 UA/ha. Avalie fertilidade, manejo e reforma.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'A estrutura de pastagens está equilibrada. Mantenha medições periódicas e rotação planejada.',
      );
    }
    return recommendations;
  }
}
