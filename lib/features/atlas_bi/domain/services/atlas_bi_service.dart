import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasBiService {
  const AtlasBiService();

  AtlasBiData build({
    required AtlasBiInput input,
    DateTime? now,
  }) {
    final indicators = input.indicators.map((item) {
      return _buildIndicator(item);
    }).toList();

    final rankings = _buildRankings(indicators);

    final score = _operationScore(rankings);

    final status = _statusFromScore(score);

    return AtlasBiData(
      generatedAt: now ?? DateTime.now(),
      title: 'Atlas BI',
      summary: _buildSummary(
        score: score,
        status: status,
        indicators: indicators,
        rankings: rankings,
        insights: input.insights,
      ),
      score: score,
      status: status,
      indicators: indicators,
      rankings: rankings,
      insights: _orderInsights(input.insights),
    );
  }

  AtlasBiIndicator _buildIndicator(
    AtlasBiIndicatorInput input,
  ) {
    final orderedSeries = [...input.series]
      ..sort(
        (first, second) =>
            first.recordedAt.compareTo(
          second.recordedAt,
        ),
      );

    final previousValue =
        orderedSeries.length >= 2
            ? orderedSeries[
                    orderedSeries.length - 2]
                .value
            : null;

    final variationPercent =
        _variationPercent(
      currentValue: input.currentValue,
      previousValue: previousValue,
    );

    final achievement =
        _targetAchievement(
      currentValue: input.currentValue,
      targetValue: input.targetValue,
      higherIsBetter:
          input.higherIsBetter,
    );

    final status =
        _statusFromAchievement(achievement);

    final trend = _trendFromVariation(
      variationPercent,
      previousValue != null,
    );

    return AtlasBiIndicator(
      id: input.id,
      farmName: input.farmName,
      title: input.title,
      description: input.description,
      category: input.category,
      unit: input.unit,
      currentValue: input.currentValue,
      previousValue: previousValue,
      targetValue: input.targetValue,
      variationPercent:
          variationPercent,
      targetAchievementPercent:
          achievement,
      trend: trend,
      status: status,
      series: List.unmodifiable(
        orderedSeries,
      ),
    );
  }

  List<AtlasBiFarmRanking> _buildRankings(
    List<AtlasBiIndicator> indicators,
  ) {
    final grouped =
        <String, List<AtlasBiIndicator>>{};

    for (final indicator in indicators) {
      grouped.putIfAbsent(
        indicator.farmName,
        () => [],
      );

      grouped[indicator.farmName]!.add(
        indicator,
      );
    }

    final temporary =
        <_FarmScore>[];

    for (final entry in grouped.entries) {
      final values = entry.value;

      final score = values.isEmpty
          ? 0.0
          : values.fold<double>(
                0,
                (sum, item) =>
                    sum +
                    item
                        .targetAchievementPercent,
              ) /
              values.length;

      final positive = values.where((item) {
        return item.status ==
                AtlasBiStatus.excellent ||
            item.status ==
                AtlasBiStatus.adequate;
      }).length;

      final critical = values.where((item) {
        return item.status ==
            AtlasBiStatus.critical;
      }).length;

      temporary.add(
        _FarmScore(
          farmName: entry.key,
          score: score
              .clamp(0.0, 100.0)
              .toDouble(),
          positiveIndicators: positive,
          criticalIndicators: critical,
        ),
      );
    }

    temporary.sort(
      (first, second) =>
          second.score.compareTo(
        first.score,
      ),
    );

    return List.generate(
      temporary.length,
      (index) {
        final item = temporary[index];

        return AtlasBiFarmRanking(
          position: index + 1,
          farmName: item.farmName,
          score: item.score,
          status:
              _statusFromScore(item.score),
          positiveIndicators:
              item.positiveIndicators,
          criticalIndicators:
              item.criticalIndicators,
        );
      },
    );
  }

  List<AtlasBiInsight> _orderInsights(
    List<AtlasBiInsight> insights,
  ) {
    final result = [...insights];

    result.sort((first, second) {
      final firstWeight =
          _priorityWeight(first.priority);

      final secondWeight =
          _priorityWeight(second.priority);

      if (firstWeight != secondWeight) {
        return secondWeight.compareTo(
          firstWeight,
        );
      }

      return second.confidencePercent
          .compareTo(
        first.confidencePercent,
      );
    });

    return result;
  }

  double _operationScore(
    List<AtlasBiFarmRanking> rankings,
  ) {
    if (rankings.isEmpty) {
      return 0;
    }

    final total = rankings.fold<double>(
      0,
      (sum, item) => sum + item.score,
    );

    return (total / rankings.length)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _variationPercent({
    required double currentValue,
    required double? previousValue,
  }) {
    if (previousValue == null ||
        previousValue == 0) {
      return 0;
    }

    return ((currentValue -
                previousValue) /
            previousValue.abs() *
            100)
        .toDouble();
  }

  double _targetAchievement({
    required double currentValue,
    required double targetValue,
    required bool higherIsBetter,
  }) {
    if (targetValue == 0) {
      return 0;
    }

    final value = higherIsBetter
        ? currentValue / targetValue * 100
        : currentValue <= 0
            ? 120.0
            : targetValue /
                currentValue *
                100;

    return value
        .clamp(0.0, 120.0)
        .toDouble();
  }

  AtlasBiStatus _statusFromAchievement(
    double value,
  ) {
    if (value >= 100) {
      return AtlasBiStatus.excellent;
    }

    if (value >= 80) {
      return AtlasBiStatus.adequate;
    }

    if (value >= 60) {
      return AtlasBiStatus.attention;
    }

    return AtlasBiStatus.critical;
  }

  AtlasBiStatus _statusFromScore(
    double score,
  ) {
    if (score >= 90) {
      return AtlasBiStatus.excellent;
    }

    if (score >= 75) {
      return AtlasBiStatus.adequate;
    }

    if (score >= 55) {
      return AtlasBiStatus.attention;
    }

    return AtlasBiStatus.critical;
  }

  AtlasBiTrend _trendFromVariation(
    double variation,
    bool hasPrevious,
  ) {
    if (!hasPrevious) {
      return AtlasBiTrend.unavailable;
    }

    if (variation >= 10) {
      return AtlasBiTrend.strongUp;
    }

    if (variation >= 2) {
      return AtlasBiTrend.up;
    }

    if (variation <= -10) {
      return AtlasBiTrend.strongDown;
    }

    if (variation <= -2) {
      return AtlasBiTrend.down;
    }

    return AtlasBiTrend.stable;
  }

  int _priorityWeight(
    AtlasBiPriority priority,
  ) {
    switch (priority) {
      case AtlasBiPriority.low:
        return 1;

      case AtlasBiPriority.medium:
        return 2;

      case AtlasBiPriority.high:
        return 3;

      case AtlasBiPriority.critical:
        return 4;
    }
  }

  String _buildSummary({
    required double score,
    required AtlasBiStatus status,
    required List<AtlasBiIndicator>
        indicators,
    required List<AtlasBiFarmRanking>
        rankings,
    required List<AtlasBiInsight>
        insights,
  }) {
    final critical = indicators.where((item) {
      return item.status ==
          AtlasBiStatus.critical;
    }).length;

    final positive = indicators.where((item) {
      return item.status ==
              AtlasBiStatus.excellent ||
          item.status ==
              AtlasBiStatus.adequate;
    }).length;

    return 'O Atlas BI consolidou '
        '${indicators.length} indicadores de '
        '${rankings.length} fazendas, com score '
        '${score.toStringAsFixed(0)}/100 e situação '
        '${atlasBiStatusLabel(status).toLowerCase()}. '
        '$positive indicadores apresentam desempenho positivo, '
        '$critical estão em situação crítica e '
        '${insights.length} insights foram identificados.';
  }
}

class _FarmScore {
  const _FarmScore({
    required this.farmName,
    required this.score,
    required this.positiveIndicators,
    required this.criticalIndicators,
  });

  final String farmName;
  final double score;
  final int positiveIndicators;
  final int criticalIndicators;
}
