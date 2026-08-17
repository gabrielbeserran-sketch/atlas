import 'dart:convert';

import 'package:projeto_atlas/features/benefits_realization/domain/models/atlas_benefit_realization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasBenefitsRealizationRepository {
  AtlasBenefitsRealizationRepository._();

  static final AtlasBenefitsRealizationRepository instance =
      AtlasBenefitsRealizationRepository._();

  static const String _storageKey = 'atlas_benefits_realization_v1';

  Future<List<AtlasBenefitRealization>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return <AtlasBenefitRealization>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <AtlasBenefitRealization>[];
      }

      final results = decoded
          .whereType<Map>()
          .map(
            (item) => AtlasBenefitRealization.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      results.sort(
        (first, second) => second.measuredAt.compareTo(first.measuredAt),
      );

      return results;
    } catch (_) {
      return <AtlasBenefitRealization>[];
    }
  }

  Future<void> save(AtlasBenefitRealization result) async {
    final current = await loadAll();
    final index = current.indexWhere(
      (item) => item.strategyPlanId == result.strategyPlanId,
    );

    if (index >= 0) {
      current[index] = result;
    } else {
      current.insert(0, result);
    }

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(current.take(100).map((item) => item.toJson()).toList()),
    );
  }
}
