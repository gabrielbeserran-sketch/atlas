import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_governance_operations/domain/models/atlas_governance_operation_record.dart';

class AtlasGovernanceOperationAnalytics {
  const AtlasGovernanceOperationAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.grossAmount,
    required this.netAmount,
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
  final double grossAmount;
  final double netAmount;
  final int totalQuantity;
  final double averageScore;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasGovernanceOperationAnalyticsService {
  const AtlasGovernanceOperationAnalyticsService();

  AtlasGovernanceOperationAnalytics analyze({
    required AtlasGovernanceOperationModule module,
    required List<AtlasGovernanceOperationRecord> records,
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

    final grossAmount = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.amount,
    );

    final netAmount = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.netAmount,
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

    return AtlasGovernanceOperationAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      pendingCount: pending,
      alertCount: alerts,
      grossAmount: grossAmount,
      netAmount: netAmount,
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
    required AtlasGovernanceOperationModule module,
    required List<AtlasGovernanceOperationRecord> records,
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
        'Existem $alerts alertas, vencimentos ou situações críticas; priorize o tratamento.',
      );
    }

    if (records.isEmpty) {
      items.add('Cadastre o primeiro registro do ${module.packageLabel}.');
    } else {
      items.addAll(switch (module) {
        AtlasGovernanceOperationModule.qualityManagement => const [
          'Padronize procedimentos, critérios de inspeção e evidências obrigatórias.',
          'Trate causa raiz, responsável, prazo e eficácia de cada ação corretiva.',
        ],
        AtlasGovernanceOperationModule.compliance => const [
          'Associe riscos a controles, responsáveis, evidências e frequência de revisão.',
          'Mantenha ocorrências protegidas, auditáveis e com plano de resposta.',
        ],
        AtlasGovernanceOperationModule.projectPortfolio => const [
          'Priorize projetos por valor, urgência, risco, esforço e dependências.',
          'Monitore marcos, orçamento, recursos, benefícios e desvios.',
        ],
        AtlasGovernanceOperationModule.workforceManagement => const [
          'Planeje capacidade, escalas, metas e responsabilidades de forma transparente.',
          'Registre feedback, desempenho, ocorrências e ações de desenvolvimento.',
        ],
        AtlasGovernanceOperationModule.trainingAcademy => const [
          'Defina trilhas por função, pré-requisitos, avaliação e validade do certificado.',
          'Acompanhe lacunas de competência e evolução do plano individual.',
        ],
      });
    }

    return items;
  }
}
