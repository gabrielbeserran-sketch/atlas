import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_precision_livestock/domain/models/atlas_precision_livestock_record.dart';

class AtlasPrecisionLivestockAnalytics {
  const AtlasPrecisionLivestockAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.averageConfidence,
    required this.averageRisk,
    required this.averageCurrent,
    required this.averageProjected,
    required this.totalFinancialImpact,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double averageConfidence;
  final double averageRisk;
  final double averageCurrent;
  final double averageProjected;
  final double totalFinancialImpact;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasPrecisionLivestockAnalyticsService {
  const AtlasPrecisionLivestockAnalyticsService();

  AtlasPrecisionLivestockAnalytics analyze({
    required AtlasPrecisionLivestockModule module,
    required List<AtlasPrecisionLivestockRecord> records,
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
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0),
    );

    double averageOf(
      double Function(AtlasPrecisionLivestockRecord) selector,
    ) {
      if (moduleRecords.isEmpty) return 0.0;

      return moduleRecords
              .map(selector)
              .reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final averageConfidence =
        averageOf((record) => record.confidencePercent);
    final averageRisk =
        averageOf((record) => record.riskPercent);
    final averageCurrent =
        averageOf((record) => record.currentValue);
    final averageProjected =
        averageOf((record) => record.projectedValue);
    final averageProgress =
        averageOf((record) => record.progressPercent.toDouble());

    final totalFinancialImpact = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.financialImpact,
    );

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, averageConfidence.round() * 15 ~/ 100);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(25, alerts * 5);
    score -= math.min(15, averageRisk.round() * 15 ~/ 100);
    score = score.clamp(0, 100).toInt();

    return AtlasPrecisionLivestockAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      averageConfidence: averageConfidence,
      averageRisk: averageRisk,
      averageCurrent: averageCurrent,
      averageProjected: averageProjected,
      totalFinancialImpact: totalFinancialImpact,
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
    required AtlasPrecisionLivestockModule module,
    required List<AtlasPrecisionLivestockRecord> records,
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
        'Existem $alerts alertas ou registros de alto risco; priorize revisão e validação de campo.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
      return items;
    }

    items.addAll(
      switch (module) {
        AtlasPrecisionLivestockModule.weightPrediction => const [
            'Calibre a projeção com pesagens confiáveis e intervalos regulares.',
            'Exiba horizonte, confiança e desvio esperado junto ao peso projetado.',
          ],
        AtlasPrecisionLivestockModule.dailyGainPrediction => const [
            'Compare ganho observado, projetado e meta por categoria.',
            'Investigue quedas persistentes de GMD antes de ajustar o manejo.',
          ],
        AtlasPrecisionLivestockModule.estimatedIntake => const [
            'Considere peso vivo, dieta, clima, categoria e disponibilidade.',
            'Valide estimativas com medições reais sempre que possível.',
          ],
        AtlasPrecisionLivestockModule.feedEfficiency => const [
            'Compare indivíduos somente em condições de manejo equivalentes.',
            'Separe eficiência biológica de resultado econômico.',
          ],
        AtlasPrecisionLivestockModule.feedConversion => const [
            'Relacione consumo, ganho e custo no mesmo período.',
            'Revise animais ou lotes persistentemente ineficientes.',
          ],
        AtlasPrecisionLivestockModule.animalWelfare => const [
            'Combine comportamento, locomoção, conforto e interação social.',
            'Transforme alertas em inspeção e ação de manejo.',
          ],
        AtlasPrecisionLivestockModule.earlyDiseaseDetection => const [
            'Use o módulo como apoio de triagem, não como diagnóstico definitivo.',
            'Encaminhe sinais relevantes para avaliação médico-veterinária.',
          ],
        AtlasPrecisionLivestockModule.heatStress => const [
            'Associe clima, comportamento, consumo e disponibilidade de sombra e água.',
            'Aja preventivamente antes dos períodos de maior risco.',
          ],
        AtlasPrecisionLivestockModule.mortalityRisk => const [
            'Documente fatores, horizonte e incerteza da estimativa.',
            'Priorize intervenções clínicas e de manejo em animais de alto risco.',
          ],
        AtlasPrecisionLivestockModule.generalEfficiencyIndex => const [
            'Mostre pesos e limites de cada componente do índice.',
            'Evite decisão automática sem análise humana dos indicadores.',
          ],
      },
    );

    return items;
  }
}
