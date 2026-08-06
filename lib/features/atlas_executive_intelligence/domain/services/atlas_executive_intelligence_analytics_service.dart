import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_executive_intelligence/domain/models/atlas_executive_intelligence_record.dart';

class AtlasExecutiveIntelligenceAnalytics {
  const AtlasExecutiveIntelligenceAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.financialImpact,
    required this.totalQuantity,
    required this.averageScore,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int pendingCount;
  final int alertCount;
  final double financialImpact;
  final int totalQuantity;
  final double averageScore;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasExecutiveIntelligenceAnalyticsService {
  const AtlasExecutiveIntelligenceAnalyticsService();

  AtlasExecutiveIntelligenceAnalytics analyze({
    required AtlasExecutiveIntelligenceModule module,
    required List<AtlasExecutiveIntelligenceRecord> records,
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

    final operational =
        moduleRecords.where((record) => record.isOperational).length;

    final pending = moduleRecords.where((record) {
      return !record.isOperational && !record.isCritical;
    }).length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isOverdue ? 1 : 0),
    );

    final financialImpact = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.financialImpact,
    );

    final totalQuantity = moduleRecords.fold<int>(
      0,
      (total, record) => total + record.quantity,
    );

    final averageScore = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.scoreValue)
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
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(40, alerts * 6);
    score = score.clamp(0, 100).toInt();

    return AtlasExecutiveIntelligenceAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      pendingCount: pending,
      alertCount: alerts,
      financialImpact: financialImpact,
      totalQuantity: totalQuantity,
      averageScore: averageScore,
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
    required AtlasExecutiveIntelligenceModule module,
    required List<AtlasExecutiveIntelligenceRecord> records,
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
        'Existem $alerts alertas ou prioridades críticas; revise os responsáveis e prazos.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      items.addAll(
        switch (module) {
          AtlasExecutiveIntelligenceModule.enterpriseCrm =>
            const [
              'Mantenha próxima ação, responsável, valor potencial e probabilidade atualizados.',
              'Compare custo de atendimento, receita, satisfação e recorrência por cliente.',
            ],
          AtlasExecutiveIntelligenceModule.financialCenter =>
            const [
              'Concilie caixa, contas e centros de custo antes de projetar resultados.',
              'Compare realizado, orçamento e forecast com explicação dos desvios.',
            ],
          AtlasExecutiveIntelligenceModule.businessIntelligence =>
            const [
              'Defina fonte, fórmula, periodicidade e responsável para cada KPI.',
              'Use benchmarks comparáveis e preserve contexto ao interpretar tendências.',
            ],
          AtlasExecutiveIntelligenceModule.strategicCenter =>
            const [
              'Conecte objetivos, indicadores, iniciativas, responsáveis, riscos e orçamento.',
              'Revise cenários e prioridades sempre que premissas relevantes mudarem.',
            ],
          AtlasExecutiveIntelligenceModule.commandCenter =>
            const [
              'Centralize somente alertas acionáveis, com prioridade, dono e prazo.',
              'Use o score global como síntese; valide sempre os indicadores que o compõem.',
            ],
        },
      );
    }

    return items;
  }
}
