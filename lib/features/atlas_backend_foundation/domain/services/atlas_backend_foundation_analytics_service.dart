
import 'dart:math' as math;
import 'package:projeto_atlas/features/atlas_backend_foundation/domain/models/atlas_backend_foundation_record.dart';

class AtlasBackendFoundationAnalytics {
  const AtlasBackendFoundationAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.averageProgress,
    required this.averageAvailability,
    required this.averageErrorRate,
    required this.averageLatency,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double averageProgress;
  final double averageAvailability;
  final double averageErrorRate;
  final double averageLatency;
  final int score;
  final List<String> recommendations;
}

class AtlasBackendFoundationAnalyticsService {
  const AtlasBackendFoundationAnalyticsService();

  AtlasBackendFoundationAnalytics analyze({
    required AtlasBackendFoundationModule module,
    required List<AtlasBackendFoundationRecord> records,
  }) {
    final items = records.where((e) => e.module == module).toList();
    final represented = items.map((e) => e.feature).where((e) => e.isNotEmpty).toSet();
    final coverage = module.features.isEmpty ? 0.0 : represented.length * 100 / module.features.length;
    final operational = items.where((e) => e.isOperational).length;
    final alerts = items.fold<int>(0, (sum, e) => sum + e.alertCount + (e.isCritical ? 1 : 0));

    double avg(double Function(AtlasBackendFoundationRecord) select) {
      if (items.isEmpty) return 0;
      return items.map(select).reduce((a, b) => a + b) / items.length;
    }

    final progress = avg((e) => e.progressPercent.toDouble());
    final availability = avg((e) => e.availabilityPercent);
    final errorRate = avg((e) => e.errorRatePercent);
    final latency = avg((e) => e.latencyMs);

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, progress.round() * 15 ~/ 100);
    score += math.min(15, availability.round() * 15 ~/ 100);
    score -= math.min(25, alerts * 5);
    score -= math.min(15, errorRate.round());
    score = score.clamp(0, 100);

    final recommendations = <String>[
      for (final feature in module.features)
        if (!represented.contains(feature)) 'Implantar ou registrar: $feature.',
      if (alerts > 0) 'Existem $alerts alertas técnicos; revise erros, disponibilidade e responsáveis.',
      if (items.isEmpty) 'Cadastre o primeiro registro do ${module.packageLabel}.',
      'Mantenha desenvolvimento, homologação e produção separados.',
      'Não armazene credenciais no código-fonte.',
      'Valide toda operação no servidor antes de persistir.',
    ];

    return AtlasBackendFoundationAnalytics(
      coveragePercent: coverage,
      recordCount: items.length,
      operationalCount: operational,
      alertCount: alerts,
      averageProgress: progress,
      averageAvailability: availability,
      averageErrorRate: errorRate,
      averageLatency: latency,
      score: score,
      recommendations: recommendations,
    );
  }
}
