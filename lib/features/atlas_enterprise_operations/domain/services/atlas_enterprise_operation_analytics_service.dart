import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_enterprise_operations/domain/models/atlas_enterprise_operation_record.dart';

class AtlasEnterpriseOperationAnalytics {
  const AtlasEnterpriseOperationAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.grossAmount,
    required this.netAmount,
    required this.totalQuantity,
    required this.averageStockLevel,
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
  final double averageStockLevel;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasEnterpriseOperationAnalyticsService {
  const AtlasEnterpriseOperationAnalyticsService();

  AtlasEnterpriseOperationAnalytics analyze({
    required AtlasEnterpriseOperationModule module,
    required List<AtlasEnterpriseOperationRecord> records,
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

    final averageStockLevel = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.stockLevel)
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

    return AtlasEnterpriseOperationAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      pendingCount: pending,
      alertCount: alerts,
      grossAmount: grossAmount,
      netAmount: netAmount,
      totalQuantity: totalQuantity,
      averageStockLevel: averageStockLevel,
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
    required AtlasEnterpriseOperationModule module,
    required List<AtlasEnterpriseOperationRecord> records,
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
        'Existem $alerts alertas, vencimentos ou situações críticas; revise antes de concluir.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      items.addAll(
        switch (module) {
          AtlasEnterpriseOperationModule.procurement => const [
              'Compare preço, prazo, qualidade, frete, impostos e risco antes da aprovação.',
              'Mantenha requisição, cotação, pedido, recebimento e conferência vinculados.',
            ],
          AtlasEnterpriseOperationModule.supplierPortal => const [
              'Homologue fornecedores com documentos, referências, capacidade e histórico.',
              'Acompanhe prazo, qualidade, divergências, comunicação e desempenho.',
            ],
          AtlasEnterpriseOperationModule.inventoryIntelligence => const [
              'Defina estoque mínimo, ponto de reposição, validade e consumo previsto.',
              'Investigue divergências de inventário e produtos sem movimentação.',
            ],
          AtlasEnterpriseOperationModule.maintenance => const [
              'Priorize ativos críticos, manutenção preventiva e análise de falhas recorrentes.',
              'Registre peças, mão de obra, tempo parado e custo total da ordem.',
            ],
          AtlasEnterpriseOperationModule.fieldService => const [
              'Planeje responsável, deslocamento, materiais, checklist e evidências.',
              'Feche o chamado com assinatura, resultado, pendências e satisfação.',
            ],
        },
      );
    }

    return items;
  }
}
