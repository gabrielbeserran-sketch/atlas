import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasMeetingDecisionActionLinkService {
  AtlasMeetingDecisionActionLinkService._();

  static final AtlasMeetingDecisionActionLinkService instance =
      AtlasMeetingDecisionActionLinkService._();

  static const String _storageKey = 'atlas_meeting_decision_action_links_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasMeetingDecisionActionLink>> loadAll() async {
    final encoded = await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasMeetingDecisionActionLink>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasMeetingDecisionActionLink.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasMeetingDecisionActionLink>[];
    }
  }

  Future<AtlasMeetingDecisionActionLink?> findByDecision(
    String decisionId,
  ) async {
    final all = await loadAll();

    for (final link in all) {
      if (link.decisionId == decisionId) {
        return link;
      }
    }

    return null;
  }

  Future<void> save(AtlasMeetingDecisionActionLink link) async {
    final all = await loadAll()
      ..removeWhere((item) => item.decisionId == link.decisionId)
      ..add(link);

    await _preferences.setString(
      _storageKey,
      jsonEncode(all.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> removeByMeeting(String meetingId) async {
    final all = await loadAll()
      ..removeWhere((item) => item.meetingId == meetingId);

    await _preferences.setString(
      _storageKey,
      jsonEncode(all.map((item) => item.toMap()).toList()),
    );
  }
}
