import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';

class AtlasExecutiveKpiService {
  const AtlasExecutiveKpiService();

  AtlasExecutiveKpiDashboardData build({
    required List<AtlasExecutiveFarmKpiInput>
        farms,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();

    final kpis = farms
        .expand((farm) {
          return farm.kpis.map((input) {
            return _buildKpi(
              farmName: farm.farmName,
              input: input,
              generatedAt: generatedAt,
            );
          });
        })
        .toList();

    final farmSummaries =
        _buildFarmSummaries(kpis);

    final categorySummaries =
        _buildCategorySummaries(kpis);

    final operationScore =
        _weightedScore(kpis);

    final operationStatus =
        _statusFromScore(operationScore);

    final criticalKpis = kpis
        .where((item) => item.isCritical)
        .toList()
      ..sort(
        (first, second) =>
            first.targetAchievementPercent
                .compareTo(
          second.targetAchievementPercent,
        ),
      );

    final positiveHighlights = kpis
        .where((item) {
          return item.status ==
              AtlasExecutiveKpiStatus.excellent;
        })
        .toList()
      ..sort(
        (first, second) =>
            second.targetAchievementPercent
                .compareTo(
          first.targetAchievementPercent,
        ),
      );

    return AtlasExecutiveKpiDashboardData(
      generatedAt: generatedAt,
      operationScore: operationScore,
      operationStatus: operationStatus,
      summary: _buildSummary(
        score: operationScore,
        status: operationStatus,
        farms: farmSummaries,
        criticalKpis: criticalKpis,
        positiveHighlights:
            positiveHighlights,
      ),
      kpis: kpis,
      farms: farmSummaries,
      categories: categorySummaries,
      criticalKpis:
          criticalKpis.take(10).toList(),
      positiveHighlights:
          positiveHighlights.take(10).toList(),
    );
  }

  AtlasExecutiveKpi _buildKpi({
    required String farmName,
    required AtlasExecutiveKpiInput input,
    required DateTime generatedAt,
  }) {
    final trendPercent = _trendPercent(
      currentValue: input.value,
      previousValue: input.previousValue,
    );

    return AtlasExecutiveKpi(
      id: '${_normalize(farmName)}_${input.id}',
      farmName: farmName,
      title: input.title,
      description: input.description,
      category: input.category,
      value: input.value,
      previousValue: input.previousValue,
      unit: input.unit,
      targetValue: input.targetValue,
      direction: input.direction,
      trend: _trendFromPercent(
        trendPercent: trendPercent,
        direction: input.direction,
        hasPrevious:
            input.previousValue != null,
      ),
      trendPercent: trendPercent,
      status: _evaluateStatus(
        value: input.value,
        targetValue: input.targetValue,
        direction: input.direction,
      ),
      weight: input.weight,
      generatedAt: generatedAt,
      sourceLabel: input.sourceLabel,
    );
  }

  List<AtlasExecutiveFarmKpiSummary>
      _buildFarmSummaries(
    List<AtlasExecutiveKpi> kpis,
  ) {
    final grouped =
        <String, List<AtlasExecutiveKpi>>{};

    for (final kpi in kpis) {
      grouped.putIfAbsent(
        kpi.farmName,
        () => [],
      );

      grouped[kpi.farmName]!.add(kpi);
    }

    final result =
        <AtlasExecutiveFarmKpiSummary>[];

    for (final entry in grouped.entries) {
      final items = entry.value;

      final score = _weightedScore(items);

      final excellent = items.where((item) {
        return item.status ==
            AtlasExecutiveKpiStatus.excellent;
      }).length;

      final adequate = items.where((item) {
        return item.status ==
            AtlasExecutiveKpiStatus.adequate;
      }).length;

      final attention = items.where((item) {
        return item.status ==
            AtlasExecutiveKpiStatus.attention;
      }).length;

      final critical = items.where((item) {
        return item.status ==
            AtlasExecutiveKpiStatus.critical;
      }).length;

      final positive = items
          .where((item) => item.isPositive)
          .toList()
        ..sort(
          (first, second) =>
              second.targetAchievementPercent
                  .compareTo(
            first.targetAchievementPercent,
          ),
        );

      final negative = items
          .where((item) {
            return item.status ==
                    AtlasExecutiveKpiStatus
                        .attention ||
                item.status ==
                    AtlasExecutiveKpiStatus
                        .critical;
          })
          .toList()
        ..sort(
          (first, second) =>
              first.targetAchievementPercent
                  .compareTo(
            second.targetAchievementPercent,
          ),
        );

      result.add(
        AtlasExecutiveFarmKpiSummary(
          farmName: entry.key,
          score: score,
          status: _statusFromScore(score),
          totalKpis: items.length,
          excellent: excellent,
          adequate: adequate,
          attention: attention,
          critical: critical,
          mainPositiveKpi:
              positive.isEmpty
                  ? null
                  : positive.first,
          mainCriticalKpi:
              negative.isEmpty
                  ? null
                  : negative.first,
        ),
      );
    }

    result.sort(
      (first, second) =>
          second.score.compareTo(first.score),
    );

    return result;
  }

  List<AtlasExecutiveKpiCategorySummary>
      _buildCategorySummaries(
    List<AtlasExecutiveKpi> kpis,
  ) {
    final grouped = <
        AtlasExecutiveKpiCategory,
        List<AtlasExecutiveKpi>>{};

    for (final kpi in kpis) {
      grouped.putIfAbsent(
        kpi.category,
        () => [],
      );

      grouped[kpi.category]!.add(kpi);
    }

    final result =
        <AtlasExecutiveKpiCategorySummary>[];

    for (final entry in grouped.entries) {
      final items = entry.value;

      final orderedBest = [...items]
        ..sort(
          (first, second) =>
              second.targetAchievementPercent
                  .compareTo(
            first.targetAchievementPercent,
          ),
        );

      final orderedWorst = [...items]
        ..sort(
          (first, second) =>
              first.targetAchievementPercent
                  .compareTo(
            second.targetAchievementPercent,
          ),
        );

      final score = _weightedScore(items);

      result.add(
        AtlasExecutiveKpiCategorySummary(
          category: entry.key,
          label: atlasExecutiveKpiCategoryLabel(
            entry.key,
          ),
          score: score,
          status: _statusFromScore(score),
          totalKpis: items.length,
          criticalKpis: items.where((item) {
            return item.status ==
                AtlasExecutiveKpiStatus.critical;
          }).length,
          bestKpi:
              orderedBest.isEmpty
                  ? null
                  : orderedBest.first,
          worstKpi:
              orderedWorst.isEmpty
                  ? null
                  : orderedWorst.first,
        ),
      );
    }

    result.sort(
      (first, second) {
        if (first.criticalKpis !=
            second.criticalKpis) {
          return second.criticalKpis.compareTo(
            first.criticalKpis,
          );
        }

        return first.score.compareTo(
          second.score,
        );
      },
    );

    return result;
  }

  double _weightedScore(
    List<AtlasExecutiveKpi> kpis,
  ) {
    if (kpis.isEmpty) {
      return 0;
    }

    final totalWeight = kpis.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );

    if (totalWeight <= 0) {
      return 0;
    }

    final weightedResult =
        kpis.fold<double>(
          0,
          (sum, item) {
            final score = item
                .targetAchievementPercent
                .clamp(0.0, 100.0);

            return sum + score * item.weight;
          },
        ) /
        totalWeight;

    return weightedResult.clamp(0.0, 100.0).toDouble();
  }

  AtlasExecutiveKpiStatus _evaluateStatus({
    required double value,
    required double targetValue,
    required AtlasExecutiveKpiDirection
        direction,
  }) {
    if (targetValue == 0) {
      return AtlasExecutiveKpiStatus.attention;
    }

    final achievement = switch (direction) {
      AtlasExecutiveKpiDirection.higherIsBetter =>
        value / targetValue * 100,
      AtlasExecutiveKpiDirection.lowerIsBetter =>
        value <= 0
            ? 120
            : targetValue / value * 100,
      AtlasExecutiveKpiDirection.neutral =>
        100 -
            ((value - targetValue).abs() /
                    targetValue.abs()
                        .clamp(1.0, double.infinity) *
                100),
    };

    return _statusFromScore(
      achievement.clamp(0.0, 120.0).toDouble(),
    );
  }

  AtlasExecutiveKpiStatus _statusFromScore(
    double score,
  ) {
    if (score >= 100) {
      return AtlasExecutiveKpiStatus.excellent;
    }

    if (score >= 80) {
      return AtlasExecutiveKpiStatus.adequate;
    }

    if (score >= 60) {
      return AtlasExecutiveKpiStatus.attention;
    }

    return AtlasExecutiveKpiStatus.critical;
  }

  double _trendPercent({
    required double currentValue,
    required double? previousValue,
  }) {
    if (previousValue == null ||
        previousValue == 0) {
      return 0;
    }

    return (currentValue - previousValue) /
        previousValue.abs() *
        100;
  }

  AtlasExecutiveKpiTrend _trendFromPercent({
    required double trendPercent,
    required AtlasExecutiveKpiDirection
        direction,
    required bool hasPrevious,
  }) {
    if (!hasPrevious) {
      return AtlasExecutiveKpiTrend.unavailable;
    }

    final adjusted = switch (direction) {
      AtlasExecutiveKpiDirection.higherIsBetter =>
        trendPercent,
      AtlasExecutiveKpiDirection.lowerIsBetter =>
        -trendPercent,
      AtlasExecutiveKpiDirection.neutral =>
        -trendPercent.abs(),
    };

    if (adjusted >= 10) {
      return AtlasExecutiveKpiTrend.strongUp;
    }

    if (adjusted >= 2) {
      return AtlasExecutiveKpiTrend.up;
    }

    if (adjusted <= -10) {
      return AtlasExecutiveKpiTrend.strongDown;
    }

    if (adjusted <= -2) {
      return AtlasExecutiveKpiTrend.down;
    }

    return AtlasExecutiveKpiTrend.stable;
  }

  String _buildSummary({
    required double score,
    required AtlasExecutiveKpiStatus status,
    required List<AtlasExecutiveFarmKpiSummary>
        farms,
    required List<AtlasExecutiveKpi>
        criticalKpis,
    required List<AtlasExecutiveKpi>
        positiveHighlights,
  }) {
    if (farms.isEmpty) {
      return 'Ainda não existem indicadores suficientes para formar a visão executiva.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A operação possui score de KPIs de '
      '${score.toStringAsFixed(0)}/100, classificado como '
      '${atlasExecutiveKpiStatusLabel(status).toLowerCase()}. ',
    );

    buffer.write(
      '${criticalKpis.length} '
      '${criticalKpis.length == 1 ? 'indicador está crítico' : 'indicadores estão críticos'} ',
    );

    buffer.write(
      'e ${positiveHighlights.length} '
      '${positiveHighlights.length == 1 ? 'indicador superou a meta' : 'indicadores superaram a meta'}. ',
    );

    buffer.write(
      'A fazenda com melhor desempenho é '
      '${farms.first.farmName}, com '
      '${farms.first.score.toStringAsFixed(0)} pontos.',
    );

    return buffer.toString();
  }

  String _normalize(
    String value,
  ) {
    return value
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
        );
  }
}
