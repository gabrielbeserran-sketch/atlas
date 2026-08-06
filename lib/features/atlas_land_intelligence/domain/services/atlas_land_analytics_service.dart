import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_land_intelligence/domain/models/atlas_land_record.dart';

class AtlasLandAnalytics {
  const AtlasLandAnalytics({
    required this.recordCount,
    required this.coveragePercent,
    required this.completedCount,
    required this.alertCount,
    required this.averagePrimaryValue,
    required this.score,
    required this.recommendations,
  });

  final int recordCount;
  final double coveragePercent;
  final int completedCount;
  final int alertCount;
  final double averagePrimaryValue;
  final int score;
  final List<String> recommendations;
}

class AtlasLandAnalyticsService {
  const AtlasLandAnalyticsService();

  AtlasLandAnalytics analyze({
    required AtlasLandModule module,
    required List<AtlasLandRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final representedFeatures = moduleRecords
        .map((record) => record.feature)
        .where((feature) => feature.trim().isNotEmpty)
        .toSet();

    final coverage = module.features.isEmpty
        ? 0.0
        : representedFeatures.length * 100 / module.features.length;

    final completed =
        moduleRecords.where((record) => record.isCompleted).length;
    final alerts =
        moduleRecords.where((record) => record.isCritical).length;

    final values = moduleRecords
        .map((record) => record.primaryValue)
        .where((value) => value != 0)
        .toList(growable: false);

    final average = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    var score = 35;
    score += math.min(35, coverage.round() * 35 ~/ 100);
    score += math.min(20, completed * 4);
    score -= math.min(30, alerts * 10);
    score = score.clamp(0, 100).toInt();

    return AtlasLandAnalytics(
      recordCount: moduleRecords.length,
      coveragePercent: coverage,
      completedCount: completed,
      alertCount: alerts,
      averagePrimaryValue: average,
      score: score,
      recommendations: _recommendations(
        module: module,
        records: moduleRecords,
        representedFeatures: representedFeatures,
        alerts: alerts,
      ),
    );
  }

  List<String> _recommendations({
    required AtlasLandModule module,
    required List<AtlasLandRecord> records,
    required Set<String> representedFeatures,
    required int alerts,
  }) {
    final items = <String>[];

    for (final feature in module.features) {
      if (!representedFeatures.contains(feature)) {
        items.add('Implantar ou registrar: $feature.');
      }
    }

    if (alerts > 0) {
      items.add(
        'Existem $alerts registros em Atenção ou Crítico; '
        'priorize revisão técnica e plano de ação.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro para iniciar os indicadores '
        'do ${module.packageLabel}.',
      );
    } else {
      items.addAll(
        switch (module) {
          AtlasLandModule.genetics => const [
              'Use pedigree, índices e objetivos do sistema para evitar decisões baseadas em um único indicador.',
              'Revise consanguinidade antes de confirmar qualquer acasalamento.',
            ],
          AtlasLandModule.pasture => const [
              'Compare taxa de lotação com oferta real de forragem e período de descanso.',
              'Registre entrada e saída dos lotes para melhorar a recomendação de rotação.',
            ],
          AtlasLandModule.agriculture => const [
              'Vincule custos, calendário e destino da produção ao planejamento pecuário.',
              'Compare área planejada, área executada e impacto no estoque de alimentos.',
            ],
        },
      );
    }

    return items;
  }
}
