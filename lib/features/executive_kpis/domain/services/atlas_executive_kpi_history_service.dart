import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi_history.dart';

class AtlasExecutiveKpiHistoryService {
  const AtlasExecutiveKpiHistoryService();

  List<AtlasExecutiveKpiHistoryPoint> createSnapshot({
    required List<AtlasExecutiveKpi> kpis,
    DateTime? recordedAt,
  }) {
    final currentTime = recordedAt ?? DateTime.now();

    return kpis.map((kpi) {
      return AtlasExecutiveKpiHistoryPoint(
        kpiId: kpi.id,
        farmName: kpi.farmName,
        title: kpi.title,
        category: kpi.category,
        value: kpi.value,
        targetValue: kpi.targetValue,
        unit: kpi.unit,
        status: kpi.status,
        recordedAt: currentTime,
      );
    }).toList();
  }

  List<AtlasExecutiveKpiHistoryPoint> mergeSnapshot({
    required List<AtlasExecutiveKpiHistoryPoint> existingPoints,
    required List<AtlasExecutiveKpiHistoryPoint> snapshot,
  }) {
    final result = [...existingPoints];

    for (final newPoint in snapshot) {
      final sameDayIndex = result.indexWhere((existing) {
        return existing.kpiId == newPoint.kpiId &&
            existing.farmName == newPoint.farmName &&
            _isSameDay(existing.recordedAt, newPoint.recordedAt);
      });

      if (sameDayIndex >= 0) {
        result[sameDayIndex] = newPoint;
      } else {
        result.add(newPoint);
      }
    }

    result.sort(
      (first, second) => first.recordedAt.compareTo(second.recordedAt),
    );

    return result;
  }

  AtlasExecutiveKpiHistorySummary buildSummary({
    required List<AtlasExecutiveKpiHistoryPoint> points,
    DateTime? now,
  }) {
    final grouped = <String, List<AtlasExecutiveKpiHistoryPoint>>{};

    for (final point in points) {
      final key = '${point.farmName}::${point.kpiId}';

      grouped.putIfAbsent(key, () => []);

      grouped[key]!.add(point);
    }

    final series = <AtlasExecutiveKpiHistorySeries>[];

    for (final entry in grouped.entries) {
      final items = entry.value
        ..sort(
          (first, second) => first.recordedAt.compareTo(second.recordedAt),
        );

      if (items.isEmpty) {
        continue;
      }

      final current = items.last;

      final previous = items.length >= 2 ? items[items.length - 2] : null;

      final variationPercent = _variationPercent(
        currentValue: current.value,
        previousValue: previous?.value,
      );

      series.add(
        AtlasExecutiveKpiHistorySeries(
          kpiId: current.kpiId,
          farmName: current.farmName,
          title: current.title,
          category: current.category,
          unit: current.unit,
          points: List.unmodifiable(items),
          currentValue: current.value,
          previousValue: previous?.value,
          variationPercent: variationPercent,
          trend: _trend(
            variationPercent: variationPercent,
            hasPrevious: previous != null,
          ),
        ),
      );
    }

    series.sort((first, second) {
      final firstAbsolute = first.variationPercent.abs();

      final secondAbsolute = second.variationPercent.abs();

      return secondAbsolute.compareTo(firstAbsolute);
    });

    final improvingCount = series.where((item) {
      return item.trend == AtlasExecutiveKpiTrend.up ||
          item.trend == AtlasExecutiveKpiTrend.strongUp;
    }).length;

    final stableCount = series.where((item) {
      return item.trend == AtlasExecutiveKpiTrend.stable;
    }).length;

    final worseningCount = series.where((item) {
      return item.trend == AtlasExecutiveKpiTrend.down ||
          item.trend == AtlasExecutiveKpiTrend.strongDown;
    }).length;

    return AtlasExecutiveKpiHistorySummary(
      generatedAt: now ?? DateTime.now(),
      series: series,
      improvingCount: improvingCount,
      stableCount: stableCount,
      worseningCount: worseningCount,
      summary: _buildSummaryText(
        totalSeries: series.length,
        improvingCount: improvingCount,
        stableCount: stableCount,
        worseningCount: worseningCount,
      ),
    );
  }

  List<AtlasExecutiveKpiHistorySeries> filterSeries({
    required AtlasExecutiveKpiHistorySummary summary,
    String? farmName,
    AtlasExecutiveKpiCategory? category,
  }) {
    return summary.series.where((series) {
      if (farmName != null && series.farmName != farmName) {
        return false;
      }

      if (category != null && series.category != category) {
        return false;
      }

      return true;
    }).toList();
  }

  double _variationPercent({
    required double currentValue,
    required double? previousValue,
  }) {
    if (previousValue == null || previousValue == 0) {
      return 0;
    }

    return ((currentValue - previousValue) / previousValue.abs() * 100)
        .toDouble();
  }

  AtlasExecutiveKpiTrend _trend({
    required double variationPercent,
    required bool hasPrevious,
  }) {
    if (!hasPrevious) {
      return AtlasExecutiveKpiTrend.unavailable;
    }

    if (variationPercent >= 10) {
      return AtlasExecutiveKpiTrend.strongUp;
    }

    if (variationPercent >= 2) {
      return AtlasExecutiveKpiTrend.up;
    }

    if (variationPercent <= -10) {
      return AtlasExecutiveKpiTrend.strongDown;
    }

    if (variationPercent <= -2) {
      return AtlasExecutiveKpiTrend.down;
    }

    return AtlasExecutiveKpiTrend.stable;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _buildSummaryText({
    required int totalSeries,
    required int improvingCount,
    required int stableCount,
    required int worseningCount,
  }) {
    if (totalSeries == 0) {
      return 'Ainda não existem registros históricos de KPIs.';
    }

    return 'O histórico acompanha $totalSeries '
        '${totalSeries == 1 ? 'indicador' : 'indicadores'}: '
        '$improvingCount em melhora, '
        '$stableCount estáveis e '
        '$worseningCount em piora.';
  }
}
