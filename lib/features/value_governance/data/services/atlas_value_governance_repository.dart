import 'dart:convert';

import 'package:projeto_atlas/features/value_governance/domain/models/atlas_value_governance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasValueGovernanceRepository {
  AtlasValueGovernanceRepository._();

  static final AtlasValueGovernanceRepository instance =
      AtlasValueGovernanceRepository._();

  static const String _key = 'atlas_value_governance_decisions_v1';

  Future<List<AtlasValueGovernanceDecision>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);

    if (raw == null || raw.isEmpty) {
      return <AtlasValueGovernanceDecision>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <AtlasValueGovernanceDecision>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => AtlasValueGovernanceDecision.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasValueGovernanceDecision>[];
    }
  }

  Future<void> save(AtlasValueGovernanceDecision decision) async {
    final current = await loadAll();
    final index = current.indexWhere(
      (item) => item.strategyPlanId == decision.strategyPlanId,
    );

    if (index >= 0) {
      current[index] = decision;
    } else {
      current.insert(0, decision);
    }

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _key,
      jsonEncode(current.map((item) => item.toJson()).toList()),
    );
  }
}
