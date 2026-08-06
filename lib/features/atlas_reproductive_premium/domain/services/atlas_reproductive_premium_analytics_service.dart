import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_reproductive_premium/domain/models/atlas_reproductive_premium_record.dart';

class AtlasReproductivePremiumAnalytics {
  const AtlasReproductivePremiumAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.averageConfidence,
    required this.averageSuccess,
    required this.totalCost,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double averageConfidence;
  final double averageSuccess;
  final double totalCost;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasReproductivePremiumAnalyticsService {
  const AtlasReproductivePremiumAnalyticsService();

  AtlasReproductivePremiumAnalytics analyze({
    required AtlasReproductivePremiumModule module,
    required List<AtlasReproductivePremiumRecord> records,
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

    final averageConfidence = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.confidencePercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    final averageSuccess = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.successPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    final totalCost = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.cost,
    );

    final averageProgress = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.progressPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    var score = 30;
    score += math.min(30, coverage.round() * 30 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(10, averageConfidence.round() ~/ 10);
    score += math.min(10, averageSuccess.round() ~/ 10);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(40, alerts * 6);
    score = score.clamp(0, 100).toInt();

    return AtlasReproductivePremiumAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      averageConfidence: averageConfidence,
      averageSuccess: averageSuccess,
      totalCost: totalCost,
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
    required AtlasReproductivePremiumModule module,
    required List<AtlasReproductivePremiumRecord> records,
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
        'Existem $alerts alertas ou registros críticos; revise protocolos, responsáveis e evidências.',
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
        AtlasReproductivePremiumModule.advancedIatf => const [
            'Valide elegibilidade, protocolo, lote e cronograma antes da execução.',
            'Audite inseminações, diagnóstico e resultado por matriz.',
          ],
        AtlasReproductivePremiumModule.individualFertility => const [
            'Use histórico suficiente antes de classificar fertilidade individual.',
            'Considere idade, condição corporal, sanidade e manejo.',
          ],
        AtlasReproductivePremiumModule.embryos => const [
            'Mantenha rastreabilidade completa de origem, classificação e destino.',
            'Registre armazenamento, movimentação e responsável técnico.',
          ],
        AtlasReproductivePremiumModule.ivf => const [
            'Separe indicadores de aspiração, fertilização e cultivo.',
            'Compare laboratório, doadora, touro e lote de produção.',
          ],
        AtlasReproductivePremiumModule.embryoTransfer => const [
            'Acompanhe sincronização, qualidade do embrião e condição da receptora.',
            'Calcule taxa de prenhez por técnico, protocolo e origem.',
          ],
        AtlasReproductivePremiumModule.geneticCatalog => const [
            'Padronize índices, unidades, confiabilidade e data da avaliação.',
            'Diferencie mérito genético, disponibilidade e condição comercial.',
          ],
        AtlasReproductivePremiumModule.intelligentMating => const [
            'Defina objetivos claros e limites máximos de consanguinidade.',
            'Revise defeitos recessivos e compatibilidade antes da recomendação.',
          ],
        AtlasReproductivePremiumModule.geneticPrediction => const [
            'Informe confiabilidade e base de comparação de cada predição.',
            'Valide cenários com dados genealógicos e produtivos consistentes.',
          ],
        AtlasReproductivePremiumModule.continuousBreeding => const [
            'Meça ganho genético por geração e revise critérios periodicamente.',
            'Conecte seleção, descarte e metas econômicas do sistema.',
          ],
        AtlasReproductivePremiumModule.reproductiveCenter => const [
            'Priorize alertas com maior impacto reprodutivo e financeiro.',
            'Mantenha agenda, indicadores e decisões em um painel único.',
          ],
      },
    );

    return items;
  }
}
