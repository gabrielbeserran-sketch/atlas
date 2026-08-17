import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_geospatial_platform/domain/models/atlas_geospatial_record.dart';

class AtlasGeospatialAnalytics {
  const AtlasGeospatialAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.totalAreaHectares,
    required this.averageMetric,
    required this.averageQuality,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double totalAreaHectares;
  final double averageMetric;
  final double averageQuality;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasGeospatialAnalyticsService {
  const AtlasGeospatialAnalyticsService();

  AtlasGeospatialAnalytics analyze({
    required AtlasGeospatialModule module,
    required List<AtlasGeospatialRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((feature) => feature.trim().isNotEmpty)
        .toSet();

    final coverage = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operational = moduleRecords
        .where((record) => record.isOperational)
        .length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total + record.alertCount + (record.isCritical ? 1 : 0),
    );

    final totalArea = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.areaHectares,
    );

    final averageMetric = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                  .map((record) => record.metricValue)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    final averageQuality = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                  .map((record) => record.qualityPercent)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    final averageProgress = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                  .map((record) => record.progressPercent)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    var score = 30;
    score += math.min(30, coverage.round() * 30 ~/ 100);
    score += math.min(25, operational * 5);
    score += math.min(10, averageQuality.round() ~/ 10);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(40, alerts * 6);
    score = score.clamp(0, 100).toInt();

    return AtlasGeospatialAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      totalAreaHectares: totalArea,
      averageMetric: averageMetric,
      averageQuality: averageQuality,
      averageProgress: averageProgress,
      score: score,
      recommendations: _recommendations(
        module: module,
        records: moduleRecords,
        represented: represented,
        alerts: alerts,
      ),
    );
  }

  List<String> _recommendations({
    required AtlasGeospatialModule module,
    required List<AtlasGeospatialRecord> records,
    required Set<String> represented,
    required int alerts,
  }) {
    final items = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        items.add('Implantar ou registrar: $feature.');
      }
    }

    if (alerts > 0) {
      items.add(
        'Existem $alerts alertas ou registros inconsistentes; revise dados e validação de campo.',
      );
    }

    if (records.isEmpty) {
      items.add('Cadastre o primeiro registro do ${module.packageLabel}.');
      return items;
    }

    items.addAll(switch (module) {
      AtlasGeospatialModule.gisMaps => const [
        'Padronize sistema de coordenadas, unidades e fontes.',
        'Valide limites importantes com levantamento de campo.',
      ],
      AtlasGeospatialModule.smartPaddocks => const [
        'Atualize área, lotação e disponibilidade de forragem.',
        'Use alertas para evitar superlotação e descanso insuficiente.',
      ],
      AtlasGeospatialModule.automaticRotation => const [
        'Considere dias de ocupação, descanso e condição real da pastagem.',
        'Mantenha aprovação humana para alterações operacionais.',
      ],
      AtlasGeospatialModule.pasturePlanning => const [
        'Conecte calendário, espécie, solo, chuva e meta de produção.',
        'Registre reforma, adubação e recuperação por área.',
      ],
      AtlasGeospatialModule.ndvi => const [
        'Considere nuvens, resolução e data da imagem.',
        'Valide anomalias relevantes com inspeção de campo.',
      ],
      AtlasGeospatialModule.biomass => const [
        'Calibre estimativas com amostras reais de matéria seca.',
        'Evite usar uma única leitura como decisão definitiva.',
      ],
      AtlasGeospatialModule.soil => const [
        'Associe amostras a coordenadas, profundidade e laboratório.',
        'Valide recomendações de correção com responsável técnico.',
      ],
      AtlasGeospatialModule.slope => const [
        'Combine declividade, solo, chuva e cobertura vegetal.',
        'Evite uso inadequado em áreas com risco de erosão.',
      ],
      AtlasGeospatialModule.irrigation => const [
        'Compare demanda hídrica, chuva e lâmina aplicada.',
        'Monitore eficiência e falhas de distribuição.',
      ],
      AtlasGeospatialModule.territorialPlanning => const [
        'Integre produção, infraestrutura e áreas protegidas.',
        'Documente premissas e restrições de cada cenário.',
      ],
    });

    return items;
  }
}
