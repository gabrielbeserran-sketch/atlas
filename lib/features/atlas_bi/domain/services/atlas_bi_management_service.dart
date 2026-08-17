import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_management_summary.dart';

class AtlasBiManagementService {
  const AtlasBiManagementService();

  AtlasBiManagementSummary build(AtlasBiData data) {
    final indicators = data.indicators;
    final positiveTrends = indicators.where((item) {
      return item.trend == AtlasBiTrend.up ||
          item.trend == AtlasBiTrend.strongUp;
    }).length;
    final negativeTrends = indicators.where((item) {
      return item.trend == AtlasBiTrend.down ||
          item.trend == AtlasBiTrend.strongDown;
    }).length;
    final onTarget = indicators.where((item) {
      return item.targetAchievementPercent >= 100;
    }).length;

    final categories = <AtlasBiCategorySummary>[];
    for (final category in AtlasBiCategory.values) {
      final categoryItems = indicators.where((item) {
        return item.category == category;
      }).toList();
      if (categoryItems.isEmpty) {
        continue;
      }
      final total = categoryItems.fold<double>(0, (sum, item) {
        return sum + item.targetAchievementPercent;
      });
      categories.add(
        AtlasBiCategorySummary(
          category: category,
          averageAchievement: total / categoryItems.length,
          indicatorCount: categoryItems.length,
          criticalCount: categoryItems.where((item) {
            return item.status == AtlasBiStatus.critical;
          }).length,
        ),
      );
    }
    categories.sort((a, b) {
      return a.averageAchievement.compareTo(b.averageAchievement);
    });

    final priorities = <AtlasBiManagementPriority>[];
    final sortedIndicators = List<AtlasBiIndicator>.from(indicators)
      ..sort((a, b) {
        final statusComparison = _statusWeight(
          b.status,
        ).compareTo(_statusWeight(a.status));
        if (statusComparison != 0) {
          return statusComparison;
        }
        return a.targetAchievementPercent.compareTo(b.targetAchievementPercent);
      });

    for (final indicator in sortedIndicators.take(5)) {
      if (indicator.status == AtlasBiStatus.excellent) {
        continue;
      }
      priorities.add(
        AtlasBiManagementPriority(
          title: indicator.title,
          description:
              '${indicator.farmName}: ${indicator.currentValue.toStringAsFixed(1)} ${indicator.unit}, com ${indicator.targetAchievementPercent.toStringAsFixed(0)}% da meta.',
          category: indicator.category,
          urgency: indicator.status == AtlasBiStatus.critical
              ? AtlasBiPriority.critical
              : indicator.status == AtlasBiStatus.attention
              ? AtlasBiPriority.high
              : AtlasBiPriority.medium,
          recommendedAction:
              'Revisar o indicador, confirmar a causa operacional e definir uma ação com responsável e prazo.',
        ),
      );
    }

    return AtlasBiManagementSummary(
      generatedAt: DateTime.now(),
      score: data.score,
      statusLabel: atlasBiStatusLabel(data.status),
      positiveTrends: positiveTrends,
      negativeTrends: negativeTrends,
      onTargetIndicators: onTarget,
      offTargetIndicators: indicators.length - onTarget,
      categorySummaries: categories,
      priorities: priorities,
    );
  }

  int _statusWeight(AtlasBiStatus status) {
    switch (status) {
      case AtlasBiStatus.critical:
        return 4;
      case AtlasBiStatus.attention:
        return 3;
      case AtlasBiStatus.adequate:
        return 2;
      case AtlasBiStatus.excellent:
        return 1;
    }
  }
}
