import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_benchmark.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasBiBenchmarkService {
  const AtlasBiBenchmarkService();

  AtlasBiBenchmarkData build({
    required AtlasBiData data,
    DateTime? now,
  }) {
    final grouped = <String, List<AtlasBiIndicator>>{};

    for (final indicator in data.indicators) {
      grouped.putIfAbsent(
        indicator.farmName,
        () => [],
      );

      grouped[indicator.farmName]!.add(indicator);
    }

    final temporary = grouped.entries.map((entry) {
      final indicators = entry.value;

      final score = indicators.isEmpty
          ? 0.0
          : indicators.fold<double>(
                0,
                (sum, item) =>
                    sum +
                    item.targetAchievementPercent,
              ) /
              indicators.length;

      final orderedByPerformance = [...indicators]
        ..sort(
          (first, second) =>
              second.targetAchievementPercent
                  .compareTo(
            first.targetAchievementPercent,
          ),
        );

      final strong = indicators.where((item) {
        return item.status ==
                AtlasBiStatus.excellent ||
            item.status ==
                AtlasBiStatus.adequate;
      }).length;

      final attention = indicators.where((item) {
        return item.status ==
            AtlasBiStatus.attention;
      }).length;

      final critical = indicators.where((item) {
        return item.status ==
            AtlasBiStatus.critical;
      }).length;

      return _TemporaryFarm(
        farmName: entry.key,
        score: score
            .clamp(0.0, 100.0)
            .toDouble(),
        strongIndicators: strong,
        attentionIndicators: attention,
        criticalIndicators: critical,
        bestIndicatorTitle:
            orderedByPerformance.isEmpty
                ? null
                : orderedByPerformance.first.title,
        mainGapTitle:
            orderedByPerformance.isEmpty
                ? null
                : orderedByPerformance.last.title,
      );
    }).toList()
      ..sort(
        (first, second) =>
            second.score.compareTo(
          first.score,
        ),
      );

    final leaderScore =
        temporary.isEmpty ? 0.0 : temporary.first.score;

    final farms = List.generate(
      temporary.length,
      (index) {
        final item = temporary[index];

        return AtlasBiBenchmarkFarm(
          position: index + 1,
          farmName: item.farmName,
          score: item.score,
          distanceFromLeader:
              (leaderScore - item.score)
                  .clamp(0.0, 100.0)
                  .toDouble(),
          status: _statusFromScore(item.score),
          strongIndicators:
              item.strongIndicators,
          attentionIndicators:
              item.attentionIndicators,
          criticalIndicators:
              item.criticalIndicators,
          bestIndicatorTitle:
              item.bestIndicatorTitle,
          mainGapTitle: item.mainGapTitle,
        );
      },
    );

    final benchmarkIndicators =
        _buildIndicatorBenchmarks(
      data.indicators,
    );

    final averageScore = farms.isEmpty
        ? 0.0
        : farms.fold<double>(
              0,
              (sum, item) => sum + item.score,
            ) /
            farms.length;

    return AtlasBiBenchmarkData(
      generatedAt: now ?? DateTime.now(),
      summary: _buildSummary(
        farms: farms,
        averageScore: averageScore,
      ),
      farms: farms,
      indicators: benchmarkIndicators,
      leadingFarmName:
          farms.isEmpty ? null : farms.first.farmName,
      averageScore: averageScore,
    );
  }

  List<AtlasBiBenchmarkOpportunity>
      buildOpportunities({
    required AtlasBiBenchmarkData benchmark,
    int limit = 20,
  }) {
    final opportunities =
        <AtlasBiBenchmarkOpportunity>[];

    for (final indicator in benchmark.indicators) {
      for (final result in indicator.farmResults) {
        if (result.distanceFromReferencePercent <= 0) {
          continue;
        }

        opportunities.add(
          AtlasBiBenchmarkOpportunity(
            farmName: result.farmName,
            indicatorTitle: indicator.title,
            category: indicator.category,
            currentValue: result.currentValue,
            referenceValue:
                indicator.referenceValue,
            unit: indicator.unit,
            gapPercent:
                result.distanceFromReferencePercent,
            recommendation:
                'Comparar práticas com ${indicator.bestFarmName ?? 'a fazenda de referência'}, '
                'identificar diferenças operacionais e criar um plano para reduzir a distância.',
          ),
        );
      }
    }

    opportunities.sort(
      (first, second) =>
          second.gapPercent.compareTo(
        first.gapPercent,
      ),
    );

    return opportunities.take(limit).toList();
  }

  List<AtlasBiBenchmarkIndicator>
      _buildIndicatorBenchmarks(
    List<AtlasBiIndicator> indicators,
  ) {
    final grouped =
        <String, List<AtlasBiIndicator>>{};

    for (final indicator in indicators) {
      final key =
          '${indicator.title}::${indicator.category.name}';

      grouped.putIfAbsent(
        key,
        () => [],
      );

      grouped[key]!.add(indicator);
    }

    final result =
        <AtlasBiBenchmarkIndicator>[];

    for (final entry in grouped.entries) {
      final values = entry.value;

      if (values.isEmpty) {
        continue;
      }

      final ordered = [...values]
        ..sort(
          (first, second) =>
              second.targetAchievementPercent
                  .compareTo(
            first.targetAchievementPercent,
          ),
        );

      final reference = ordered.first;
      final worst = ordered.last;

      final averageValue =
          values.fold<double>(
                0,
                (sum, item) =>
                    sum + item.currentValue,
              ) /
              values.length;

      final farmResults = values.map((item) {
        final distance =
            reference.targetAchievementPercent -
                item.targetAchievementPercent;

        return AtlasBiBenchmarkFarmResult(
          farmName: item.farmName,
          currentValue: item.currentValue,
          targetAchievementPercent:
              item.targetAchievementPercent,
          distanceFromReferencePercent:
              distance
                  .clamp(0.0, 120.0)
                  .toDouble(),
          status: item.status,
        );
      }).toList()
        ..sort(
          (first, second) => second
              .targetAchievementPercent
              .compareTo(
            first.targetAchievementPercent,
          ),
        );

      result.add(
        AtlasBiBenchmarkIndicator(
          indicatorId: reference.id,
          title: reference.title,
          category: reference.category,
          unit: reference.unit,
          referenceValue:
              reference.currentValue,
          averageValue: averageValue,
          bestFarmName:
              reference.farmName,
          worstFarmName: worst.farmName,
          farmResults: farmResults,
        ),
      );
    }

    result.sort(
      (first, second) =>
          first.title.compareTo(second.title),
    );

    return result;
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

  String _buildSummary({
    required List<AtlasBiBenchmarkFarm> farms,
    required double averageScore,
  }) {
    if (farms.isEmpty) {
      return 'Ainda não existem fazendas suficientes para gerar o benchmarking.';
    }

    final leader = farms.first;

    return 'O benchmarking comparou ${farms.length} '
        '${farms.length == 1 ? 'fazenda' : 'fazendas'}, '
        'com média de ${averageScore.toStringAsFixed(0)}/100. '
        '${leader.farmName} lidera o ranking com '
        '${leader.score.toStringAsFixed(0)}/100.';
  }
}

class _TemporaryFarm {
  const _TemporaryFarm({
    required this.farmName,
    required this.score,
    required this.strongIndicators,
    required this.attentionIndicators,
    required this.criticalIndicators,
    required this.bestIndicatorTitle,
    required this.mainGapTitle,
  });

  final String farmName;
  final double score;

  final int strongIndicators;
  final int attentionIndicators;
  final int criticalIndicators;

  final String? bestIndicatorTitle;
  final String? mainGapTitle;
}
