import 'dart:convert';

import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutiveKpiHistoryStorageService {
  const AtlasExecutiveKpiHistoryStorageService();

  static const String _storageKey =
      'atlas_executive_kpi_history_v1';

  static const int maximumPointsPerKpi = 365;

  Future<List<AtlasExecutiveKpiHistoryPoint>>
      load() async {
    final preferences =
        await SharedPreferences.getInstance();

    final value =
        preferences.getString(_storageKey);

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      final points = decoded
          .whereType<Map>()
          .map((item) {
            return AtlasExecutiveKpiHistoryPoint
                .fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .where((item) {
            return item.kpiId.trim().isNotEmpty &&
                item.farmName.trim().isNotEmpty;
          })
          .toList();

      points.sort(
        (first, second) =>
            first.recordedAt.compareTo(
          second.recordedAt,
        ),
      );

      return _limitPoints(points);
    } catch (_) {
      return [];
    }
  }

  Future<void> save(
    List<AtlasExecutiveKpiHistoryPoint> points,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final limited =
        _limitPoints(points);

    await preferences.setString(
      _storageKey,
      jsonEncode(
        limited.map((item) {
          return item.toJson();
        }).toList(),
      ),
    );
  }

  Future<void> clear() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }

  List<AtlasExecutiveKpiHistoryPoint>
      _limitPoints(
    List<AtlasExecutiveKpiHistoryPoint> points,
  ) {
    final grouped = <
        String,
        List<AtlasExecutiveKpiHistoryPoint>>{};

    for (final point in points) {
      final key =
          '${point.farmName}::${point.kpiId}';

      grouped.putIfAbsent(
        key,
        () => [],
      );

      grouped[key]!.add(point);
    }

    final result =
        <AtlasExecutiveKpiHistoryPoint>[];

    for (final items in grouped.values) {
      items.sort(
        (first, second) =>
            first.recordedAt.compareTo(
          second.recordedAt,
        ),
      );

      final limited =
          items.length > maximumPointsPerKpi
              ? items.sublist(
                  items.length -
                      maximumPointsPerKpi,
                )
              : items;

      result.addAll(limited);
    }

    result.sort(
      (first, second) =>
          first.recordedAt.compareTo(
        second.recordedAt,
      ),
    );

    return result;
  }
}
