import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasTeamMemberService {
  AtlasTeamMemberService._();

  static final AtlasTeamMemberService instance =
      AtlasTeamMemberService._();

  static const String _storageKey =
      'atlas_team_members_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasTeamMember>> load({
    String? farmName,
    bool includeInactive = false,
  }) async {
    final all = await _loadAll();
    final normalizedFarm =
        farmName?.trim().toLowerCase();

    final filtered = all.where((member) {
      final matchesFarm = normalizedFarm == null ||
          normalizedFarm.isEmpty ||
          member.farmName?.trim().toLowerCase() ==
              normalizedFarm;
      final matchesActive =
          includeInactive || member.active;

      return matchesFarm && matchesActive;
    }).toList()
      ..sort(
        (first, second) =>
            first.name.compareTo(second.name),
      );

    return filtered;
  }

  Future<AtlasTeamMember> save(
    AtlasTeamMember member,
  ) async {
    final all = await _loadAll();
    final index = all.indexWhere(
      (item) => item.id == member.id,
    );

    final updated = member.copyWith(
      updatedAt: DateTime.now(),
    );

    if (index == -1) {
      all.add(updated);
    } else {
      all[index] = updated;
    }

    await _saveAll(all);
    return updated;
  }

  Future<AtlasTeamMember> create({
    required String name,
    required AtlasTeamMemberRole role,
    required String phone,
    required String email,
    String? farmName,
  }) async {
    final now = DateTime.now();

    return save(
      AtlasTeamMember(
        id: 'team_member_${now.microsecondsSinceEpoch}',
        name: name.trim(),
        role: role,
        phone: phone.trim(),
        email: email.trim(),
        farmName: farmName,
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> setActive({
    required AtlasTeamMember member,
    required bool active,
  }) async {
    await save(
      member.copyWith(active: active),
    );
  }

  Future<void> delete(String id) async {
    final all = await _loadAll()
      ..removeWhere((member) => member.id == id);

    await _saveAll(all);
  }

  Future<List<AtlasTeamMember>> _loadAll() async {
    final encoded =
        await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasTeamMember>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasTeamMember.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasTeamMember>[];
    }
  }

  Future<void> _saveAll(
    List<AtlasTeamMember> members,
  ) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(
        members.map((member) => member.toMap()).toList(),
      ),
    );
  }
}
