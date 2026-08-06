import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_global_platform/domain/models/atlas_global_platform_record.dart';

class AtlasGlobalPlatformAnalytics {
  const AtlasGlobalPlatformAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.averagePrimaryValue,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double averagePrimaryValue;
  final int score;
  final List<String> recommendations;
}

class AtlasGlobalPlatformAnalyticsService {
  const AtlasGlobalPlatformAnalyticsService();

  AtlasGlobalPlatformAnalytics analyze(
    List<AtlasGlobalPlatformRecord> records,
  ) {
    final represented = records
        .map((record) => record.feature)
        .toSet();

    final coverage = represented.length *
        100 /
        AtlasGlobalPlatformFeature.values.length;

    final operational =
        records.where((record) => record.isOperational).length;
    final alerts =
        records.where((record) => record.isCritical).length;

    final values = records
        .map((record) => record.primaryValue)
        .where((value) => value != 0)
        .toList(growable: false);

    final average = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    var score = 30;
    score += math.min(40, coverage.round() * 40 ~/ 100);
    score += math.min(25, operational * 5);
    score -= math.min(35, alerts * 10);
    score = score.clamp(0, 100).toInt();

    return AtlasGlobalPlatformAnalytics(
      coveragePercent: coverage,
      recordCount: records.length,
      operationalCount: operational,
      alertCount: alerts,
      averagePrimaryValue: average,
      score: score,
      recommendations: _recommendations(
        records: records,
        represented: represented,
        alerts: alerts,
      ),
    );
  }

  List<String> _recommendations({
    required List<AtlasGlobalPlatformRecord> records,
    required Set<AtlasGlobalPlatformFeature> represented,
    required int alerts,
  }) {
    final items = <String>[];

    for (final feature
        in AtlasGlobalPlatformFeature.values) {
      if (!represented.contains(feature)) {
        items.add(
          'Implantar ou registrar: ${feature.title}.',
        );
      }
    }

    if (alerts > 0) {
      items.add(
        'Existem $alerts registros críticos, bloqueados, '
        'offline ou em atenção.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro componente da Plataforma '
        'Atlas Global para iniciar o Command Center.',
      );
    } else {
      items.addAll(const [
        'Centralize permissões e escopos antes de liberar integrações externas.',
        'Use credenciais rotativas, limites de requisição e auditoria na API pública.',
        'Homologue integrações antes de disponibilizá-las no marketplace.',
        'Mantenha o Command Center orientado por risco, impacto e urgência.',
        'Separe rigorosamente tenant, empresa, fazenda e carteira autorizada.',
      ]);
    }

    return items;
  }
}
