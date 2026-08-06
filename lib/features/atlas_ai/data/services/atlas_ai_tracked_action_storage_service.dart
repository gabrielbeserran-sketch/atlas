import 'dart:convert';

import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasAiTrackedActionStorageService {
  const AtlasAiTrackedActionStorageService();

  static const String _keyPrefix =
      'atlas_ai_tracked_actions_v1';

  static const int maximumActionsPerFarm = 150;

  Future<List<AtlasAiTrackedAction>> load({
    required String farmName,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    final value = preferences.getString(
      _storageKey(farmName),
    );

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      final actions = decoded
          .whereType<Map>()
          .map((item) {
            return AtlasAiTrackedAction.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .where((item) {
            return item.id.trim().isNotEmpty &&
                item.title.trim().isNotEmpty;
          })
          .take(maximumActionsPerFarm)
          .toList();

      actions.sort(
        (first, second) =>
            second.updatedAt.compareTo(
          first.updatedAt,
        ),
      );

      return actions;
    } catch (_) {
      return [];
    }
  }

  Future<void> save({
    required String farmName,
    required List<AtlasAiTrackedAction>
        actions,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    final ordered = [...actions]
      ..sort(
        (first, second) =>
            second.updatedAt.compareTo(
          first.updatedAt,
        ),
      );

    final limited = ordered
        .take(maximumActionsPerFarm)
        .toList();

    await preferences.setString(
      _storageKey(farmName),
      jsonEncode(
        limited.map((item) {
          return item.toJson();
        }).toList(),
      ),
    );
  }

  Future<void> clear({
    required String farmName,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(
      _storageKey(farmName),
    );
  }

  String _storageKey(
    String farmName,
  ) {
    return '${_keyPrefix}_${_normalize(farmName)}';
  }

  String _normalize(
    String value,
  ) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        )
        .replaceAll(
          RegExp(r'_+'),
          '_',
        );

    return normalized.isEmpty
        ? 'farm'
        : normalized;
  }
}
