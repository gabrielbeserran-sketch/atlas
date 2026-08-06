
import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_intelligence_reports_experience/domain/models/atlas_intelligence_reports_record.dart';

class AtlasIntelligenceReportsAnalytics {
  const AtlasIntelligenceReportsAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.averageCurrentValue,
    required this.averageTargetValue,
    required this.averageGap,
    required this.averageConfidence,
    required this.averageRisk,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double averageCurrentValue;
  final double averageTargetValue;
  final double averageGap;
  final double averageConfidence;
  final double averageRisk;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasIntelligenceReportsAnalyticsService {
  const AtlasIntelligenceReportsAnalyticsService();

  AtlasIntelligenceReportsAnalytics analyze({
    required AtlasIntelligenceReportsModule module,
    required List<AtlasIntelligenceReportsRecord> records,
  }) {
    final items = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = items
        .map((record) => record.feature)
        .where((value) => value.trim().isNotEmpty)
        .toSet();

    final coverage = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operational =
        items.where((record) => record.isOperational).length;

    final alerts = items.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0),
    );

    double averageOf(
      double Function(AtlasIntelligenceReportsRecord) selector,
    ) {
      if (items.isEmpty) return 0;
      return items.map(selector).reduce((a, b) => a + b) /
          items.length;
    }

    final current = averageOf((record) => record.currentValue);
    final target = averageOf((record) => record.targetValue);
    final gap = averageOf((record) => record.gap);
    final confidence =
        averageOf((record) => record.confidencePercent);
    final risk = averageOf((record) => record.riskPercent);
    final progress =
        averageOf((record) => record.progressPercent.toDouble());

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, progress.round() * 15 ~/ 100);
    score += math.min(15, confidence.round() * 15 ~/ 100);
    score -= math.min(30, alerts * 5);
    score -= math.min(20, risk.round() * 20 ~/ 100);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[
      for (final feature in module.features)
        if (!represented.contains(feature))
          'Implantar ou registrar: $feature.',
      if (alerts > 0)
        'Existem $alerts alertas; revise fontes, regras, permissões e responsáveis.',
      if (items.isEmpty)
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      'Mantenha fonte, período, fórmula e unidade de cada indicador.',
      'Registre premissas, confiança e limitações das recomendações.',
      'Proteja relatórios, exportações e links compartilhados.',
    ];

    return AtlasIntelligenceReportsAnalytics(
      coveragePercent: coverage,
      recordCount: items.length,
      operationalCount: operational,
      alertCount: alerts,
      averageCurrentValue: current,
      averageTargetValue: target,
      averageGap: gap,
      averageConfidence: confidence,
      averageRisk: risk,
      averageProgress: progress,
      score: score,
      recommendations: recommendations,
    );
  }
}
