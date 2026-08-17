import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_quality_release/domain/models/atlas_quality_release_record.dart';

class AtlasQualityReleaseAnalytics {
  const AtlasQualityReleaseAnalytics({
    required this.moduleCoveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.failureCount,
    required this.alertCount,
    required this.averageProgress,
    required this.averagePassRate,
    required this.averageTestCoverage,
    required this.averageRisk,
    required this.score,
    required this.recommendations,
  });

  final double moduleCoveragePercent;
  final int recordCount;
  final int operationalCount;
  final int failureCount;
  final int alertCount;
  final double averageProgress;
  final double averagePassRate;
  final double averageTestCoverage;
  final double averageRisk;
  final int score;
  final List<String> recommendations;
}

class AtlasQualityReleaseAnalyticsService {
  const AtlasQualityReleaseAnalyticsService();

  AtlasQualityReleaseAnalytics analyze({
    required AtlasQualityReleaseModule module,
    required List<AtlasQualityReleaseRecord> records,
  }) {
    final items = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = items
        .map((record) => record.feature)
        .where((value) => value.trim().isNotEmpty)
        .toSet();

    final moduleCoverage = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operational = items.where((record) => record.isOperational).length;

    final failures = items.fold<int>(
      0,
      (total, record) => total + record.failureCount,
    );

    final alerts = items.fold<int>(
      0,
      (total, record) =>
          total + record.alertCount + (record.isCritical ? 1 : 0),
    );

    double averageOf(double Function(AtlasQualityReleaseRecord) selector) {
      if (items.isEmpty) return 0;
      return items.map(selector).reduce((a, b) => a + b) / items.length;
    }

    final progress = averageOf((record) => record.progressPercent.toDouble());
    final passRate = averageOf((record) => record.passRatePercent);
    final testCoverage = averageOf((record) => record.coveragePercent);
    final risk = averageOf((record) => record.riskPercent);

    var score = 30;
    score += math.min(20, moduleCoverage.round() * 20 ~/ 100);
    score += math.min(15, progress.round() * 15 ~/ 100);
    score += math.min(20, passRate.round() * 20 ~/ 100);
    score += math.min(15, testCoverage.round() * 15 ~/ 100);
    score += math.min(10, operational * 2);
    score -= math.min(25, failures * 3);
    score -= math.min(25, alerts * 4);
    score -= math.min(20, risk.round() * 20 ~/ 100);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[
      for (final feature in module.features)
        if (!represented.contains(feature)) 'Implantar ou registrar: $feature.',
      if (failures > 0)
        'Existem $failures falhas registradas; corrija e repita os testes.',
      if (alerts > 0)
        'Existem $alerts alertas de qualidade; priorize os críticos.',
      if (items.isEmpty)
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      'Mantenha evidências, responsável, ambiente e critério de aprovação.',
      'Não publique uma versão sem testes repetíveis e rollback definido.',
      'Use dados de homologação, nunca dados reais sensíveis, nos testes.',
    ];

    return AtlasQualityReleaseAnalytics(
      moduleCoveragePercent: moduleCoverage,
      recordCount: items.length,
      operationalCount: operational,
      failureCount: failures,
      alertCount: alerts,
      averageProgress: progress,
      averagePassRate: passRate,
      averageTestCoverage: testCoverage,
      averageRisk: risk,
      score: score,
      recommendations: recommendations,
    );
  }
}
