import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_climate_enterprise/domain/models/atlas_climate_enterprise_record.dart';

class AtlasClimateEnterpriseAnalytics {
  const AtlasClimateEnterpriseAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.averageCurrent,
    required this.averageProjected,
    required this.averageProbability,
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
  final double averageCurrent;
  final double averageProjected;
  final double averageProbability;
  final double averageConfidence;
  final double averageRisk;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasClimateEnterpriseAnalyticsService {
  const AtlasClimateEnterpriseAnalyticsService();

  AtlasClimateEnterpriseAnalytics analyze({
    required AtlasClimateEnterpriseModule module,
    required List<AtlasClimateEnterpriseRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((value) => value.trim().isNotEmpty)
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

    double averageOf(double Function(AtlasClimateEnterpriseRecord) selector) {
      if (moduleRecords.isEmpty) return 0;
      return moduleRecords.map(selector).reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final averageCurrent = averageOf((record) => record.currentValue);
    final averageProjected = averageOf((record) => record.projectedValue);
    final averageProbability = averageOf((record) => record.probabilityPercent);
    final averageConfidence = averageOf((record) => record.confidencePercent);
    final averageRisk = averageOf((record) => record.riskPercent);
    final averageProgress = averageOf(
      (record) => record.progressPercent.toDouble(),
    );

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, averageConfidence.round() * 15 ~/ 100);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(25, alerts * 5);
    score -= math.min(15, averageRisk.round() * 15 ~/ 100);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        recommendations.add('Implantar ou registrar: $feature.');
      }
    }

    if (alerts > 0) {
      recommendations.add(
        'Existem $alerts alertas ou situações de alto risco; revise dados, responsáveis e ações.',
      );
    }

    if (moduleRecords.isEmpty) {
      recommendations.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      recommendations.addAll(switch (module) {
        AtlasClimateEnterpriseModule.climateIntelligence => const [
          'Conecte clima observado, tendência e impacto produtivo.',
          'Registre a fonte e a confiança de cada recomendação.',
        ],
        AtlasClimateEnterpriseModule.advancedMeteorology => const [
          'Diferencie observação, previsão e estimativa.',
          'Mantenha horário, localização e fonte dos dados.',
        ],
        AtlasClimateEnterpriseModule.intelligentForagePlanning => const [
          'Compare demanda animal, oferta e reserva estratégica.',
          'Revise o plano quando chuva, lotação ou produção mudarem.',
        ],
        AtlasClimateEnterpriseModule.aiPastureManagement => const [
          'Valide recomendações com inspeção de campo.',
          'Considere descanso, lotação e condição real do pasto.',
        ],
        AtlasClimateEnterpriseModule.climateEnvironmentalIndicators => const [
          'Padronize fórmula, unidade, período e limites de cada indicador.',
          'Evite interpretar uma métrica isoladamente.',
        ],
        _ => const [
          'Documente premissas, fonte e incerteza.',
          'Mantenha revisão humana para decisões operacionais.',
        ],
      });
    }

    return AtlasClimateEnterpriseAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      averageCurrent: averageCurrent,
      averageProjected: averageProjected,
      averageProbability: averageProbability,
      averageConfidence: averageConfidence,
      averageRisk: averageRisk,
      averageProgress: averageProgress,
      score: score,
      recommendations: recommendations,
    );
  }
}
