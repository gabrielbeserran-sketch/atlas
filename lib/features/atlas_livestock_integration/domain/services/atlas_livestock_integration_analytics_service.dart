import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_livestock_integration/domain/models/atlas_livestock_integration_record.dart';

class AtlasLivestockIntegrationAnalytics {
  const AtlasLivestockIntegrationAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.pendingCount,
    required this.averageProgress,
    required this.averageSuccessRate,
    required this.averageRisk,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final int pendingCount;
  final double averageProgress;
  final double averageSuccessRate;
  final double averageRisk;
  final int score;
  final List<String> recommendations;
}

class AtlasLivestockIntegrationAnalyticsService {
  const AtlasLivestockIntegrationAnalyticsService();

  AtlasLivestockIntegrationAnalytics analyze({
    required AtlasLivestockIntegrationModule module,
    required List<AtlasLivestockIntegrationRecord> records,
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

    final operational = items.where((record) => record.isOperational).length;

    final alerts = items.fold<int>(
      0,
      (total, record) =>
          total + record.alertCount + (record.isCritical ? 1 : 0),
    );

    final pending = items.fold<int>(
      0,
      (total, record) => total + record.pendingCount,
    );

    double averageOf(
      double Function(AtlasLivestockIntegrationRecord) selector,
    ) {
      if (items.isEmpty) return 0;

      return items.map(selector).reduce((a, b) => a + b) / items.length;
    }

    final progress = averageOf((record) => record.progressPercent.toDouble());
    final success = averageOf((record) => record.successRatePercent);
    final risk = averageOf((record) => record.riskPercent);

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, progress.round() * 15 ~/ 100);
    score += math.min(15, success.round() * 15 ~/ 100);
    score -= math.min(30, alerts * 5);
    score -= math.min(15, pending);
    score -= math.min(20, risk.round() * 20 ~/ 100);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[
      for (final feature in module.features)
        if (!represented.contains(feature)) 'Implantar ou registrar: $feature.',
      if (alerts > 0)
        'Existem $alerts alertas de integração; revise falhas, duplicidades e dependências.',
      if (pending > 0)
        'Existem $pending operações pendentes; revise fila, confirmação e consistência.',
      if (items.isEmpty)
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      'Mantenha origem, destino, responsável e evidência de cada integração.',
      'Evite registros duplicados usando identificadores idempotentes.',
      'Valide reflexos automáticos antes de confirmar alterações críticas.',
    ];

    return AtlasLivestockIntegrationAnalytics(
      coveragePercent: coverage,
      recordCount: items.length,
      operationalCount: operational,
      alertCount: alerts,
      pendingCount: pending,
      averageProgress: progress,
      averageSuccessRate: success,
      averageRisk: risk,
      score: score,
      recommendations: recommendations,
    );
  }
}
