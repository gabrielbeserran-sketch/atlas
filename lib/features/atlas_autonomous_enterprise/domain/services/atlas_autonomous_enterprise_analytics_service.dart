import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_autonomous_enterprise/domain/models/atlas_autonomous_enterprise_record.dart';

class AtlasAutonomousEnterpriseAnalytics {
  const AtlasAutonomousEnterpriseAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.financialImpact,
    required this.totalQuantity,
    required this.averageConfidence,
    required this.averageRisk,
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
  final double averageConfidence;
  final double averageRisk;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasAutonomousEnterpriseAnalyticsService {
  const AtlasAutonomousEnterpriseAnalyticsService();

  AtlasAutonomousEnterpriseAnalytics analyze({
    required AtlasAutonomousEnterpriseModule module,
    required List<AtlasAutonomousEnterpriseRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((feature) => feature.trim().isNotEmpty)
        .toSet();

    final double coveragePercent = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operationalCount =
        moduleRecords.where((record) => record.isOperational).length;

    final pendingCount = moduleRecords.where((record) {
      return !record.isOperational && !record.isCritical;
    }).length;

    final alertCount = moduleRecords.fold<int>(
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

    final double averageConfidence = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.confidencePercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    final double averageRisk = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.riskPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    final double averageProgress = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.progressPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    var score = 30;
    score += math.min(30, coveragePercent.round() * 30 ~/ 100);
    score += math.min(25, operationalCount * 5);
    score += math.min(10, averageProgress.round() ~/ 10);
    score += math.min(10, averageConfidence.round() ~/ 10);
    score -= math.min(35, alertCount * 5);
    score -= math.min(15, averageRisk.round() ~/ 10);
    score = score.clamp(0, 100).toInt();

    return AtlasAutonomousEnterpriseAnalytics(
      coveragePercent: coveragePercent,
      recordCount: moduleRecords.length,
      operationalCount: operationalCount,
      pendingCount: pendingCount,
      alertCount: alertCount,
      financialImpact: financialImpact,
      totalQuantity: totalQuantity,
      averageConfidence: averageConfidence,
      averageRisk: averageRisk,
      averageProgress: averageProgress,
      score: score,
      recommendations: _recommendations(
        module: module,
        records: moduleRecords,
        represented: represented,
        alerts: alertCount,
      ),
    );
  }

  List<String> _recommendations({
    required AtlasAutonomousEnterpriseModule module,
    required List<AtlasAutonomousEnterpriseRecord> records,
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
        'Existem $alerts alertas, falhas ou bloqueios; priorize responsáveis, prazo e plano de resposta.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      items.addAll(
        switch (module) {
          AtlasAutonomousEnterpriseModule.aiOrchestrator =>
            const [
              'Mantenha aprovação humana para decisões de alto impacto, baixa confiança ou risco elevado.',
              'Registre premissas, evidências, resultado esperado e retorno real de cada decisão.',
              'Use políticas claras, limites operacionais e trilha completa de auditoria.',
            ],
          AtlasAutonomousEnterpriseModule
                .enterpriseReleaseCenter =>
            const [
              'Bloqueie a publicação quando testes, segurança, backup ou plano de rollback estiverem incompletos.',
              'Use checklist de produção com responsável, evidência e aprovação para cada item.',
              'Acompanhe erros, desempenho, adoção e suporte após cada lançamento.',
            ],
        },
      );
    }

    return items;
  }
}
