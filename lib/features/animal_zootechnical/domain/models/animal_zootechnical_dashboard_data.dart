import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';

class AnimalZootechnicalDashboardData {
  const AnimalZootechnicalDashboardData({
    required this.currentWeight,
    required this.previousWeight,
    required this.weightVariation,
    required this.averageDailyGain,
    required this.projectedWeight30Days,
    required this.projectedWeight60Days,
    required this.projectedWeight90Days,
    required this.groupAverageWeight,
    required this.groupMedianWeight,
    required this.groupRank,
    required this.groupSize,
    required this.percentile,
    required this.weightHistory,
    required this.trend,
    required this.consistencyScore,
    required this.dataQuality,
  });

  final double currentWeight;
  final double? previousWeight;
  final double? weightVariation;
  final double? averageDailyGain;
  final double? projectedWeight30Days;
  final double? projectedWeight60Days;
  final double? projectedWeight90Days;
  final double groupAverageWeight;
  final double groupMedianWeight;
  final int groupRank;
  final int groupSize;
  final double percentile;
  final List<AnimalWeightData> weightHistory;
  final String trend;
  final double consistencyScore;
  final String dataQuality;

  bool get hasGrowthData => averageDailyGain != null;

  String get rankText {
    if (groupSize <= 0 || groupRank <= 0) return 'Sem comparação';
    return '$groupRankº de $groupSize';
  }

  String get percentileText {
    if (groupSize <= 1) return 'Sem comparação';
    return '${percentile.toStringAsFixed(0)}º percentil';
  }
}
