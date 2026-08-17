import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_supply_logistics_enterprise/domain/models/atlas_supply_logistics_record.dart';

class AtlasSupplyLogisticsAnalytics {
  const AtlasSupplyLogisticsAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.overdueCount,
    required this.totalQuantity,
    required this.totalPlannedValue,
    required this.totalActualValue,
    required this.totalCalculatedCost,
    required this.averageProgress,
    required this.averageQuality,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final int overdueCount;
  final double totalQuantity;
  final double totalPlannedValue;
  final double totalActualValue;
  final double totalCalculatedCost;
  final double averageProgress;
  final double averageQuality;
  final int score;
  final List<String> recommendations;

  double get valueDeviation => totalActualValue - totalPlannedValue;
}

class AtlasSupplyLogisticsAnalyticsService {
  const AtlasSupplyLogisticsAnalyticsService();

  AtlasSupplyLogisticsAnalytics analyze({
    required AtlasSupplyLogisticsModule module,
    required List<AtlasSupplyLogisticsRecord> records,
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

    final overdue = moduleRecords.where((record) => record.isOverdue).length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isOverdue ? 1 : 0),
    );

    double averageOf(double Function(AtlasSupplyLogisticsRecord) selector) {
      if (moduleRecords.isEmpty) return 0;
      return moduleRecords.map(selector).reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final totalQuantity = moduleRecords.fold<double>(
      0,
      (total, record) => total + record.quantity,
    );
    final totalPlanned = moduleRecords.fold<double>(
      0,
      (total, record) => total + record.plannedValue,
    );
    final totalActual = moduleRecords.fold<double>(
      0,
      (total, record) => total + record.actualValue,
    );
    final totalCalculatedCost = moduleRecords.fold<double>(
      0,
      (total, record) => total + record.totalCost,
    );

    final averageProgress = averageOf(
      (record) => record.progressPercent.toDouble(),
    );
    final averageQuality = averageOf((record) => record.qualityPercent);

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, averageProgress.round() * 15 ~/ 100);
    score += math.min(10, averageQuality.round() ~/ 10);
    score -= math.min(30, alerts * 5);
    score -= math.min(15, overdue * 5);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        recommendations.add('Implantar ou registrar: $feature.');
      }
    }

    if (overdue > 0) {
      recommendations.add(
        'Existem $overdue registros vencidos; revise prazos, fornecedores e entregas.',
      );
    }

    if (alerts > 0) {
      recommendations.add(
        'Existem $alerts alertas; priorize riscos de estoque, validade e logística.',
      );
    }

    if (moduleRecords.isEmpty) {
      recommendations.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      recommendations.addAll(switch (module) {
        AtlasSupplyLogisticsModule.intelligentPurchasing => const [
          'Conecte solicitação, cotação, aprovação, pedido e recebimento.',
          'Registre centro de custo e responsável pela compra.',
        ],
        AtlasSupplyLogisticsModule.supplierManagement => const [
          'Avalie qualidade, prazo, preço e conformidade.',
          'Mantenha documentos e contatos atualizados.',
        ],
        AtlasSupplyLogisticsModule.automatedQuotation => const [
          'Compare custo total, não apenas preço unitário.',
          'Considere frete, prazo e condição de pagamento.',
        ],
        AtlasSupplyLogisticsModule.purchaseApproval => const [
          'Defina regras por valor, categoria e centro de custo.',
          'Mantenha histórico de aprovação e justificativa.',
        ],
        AtlasSupplyLogisticsModule.multiWarehouseStock => const [
          'Controle saldo, reserva e transferência por depósito.',
          'Evite estoque negativo e movimentações sem origem.',
        ],
        AtlasSupplyLogisticsModule.batchesAndExpiry => const [
          'Registre lote, fabricação, validade e fornecedor.',
          'Priorize consumo por validade e criticidade.',
        ],
        AtlasSupplyLogisticsModule.intelligentInventory => const [
          'Realize contagens cíclicas e trate divergências.',
          'Mantenha justificativa e aprovação para ajustes.',
        ],
        AtlasSupplyLogisticsModule.transportLogistics => const [
          'Registre carga, rota, veículo, motorista e ocorrência.',
          'Acompanhe prazo, custo e confirmação de entrega.',
        ],
        AtlasSupplyLogisticsModule.fuelManagement => const [
          'Compare abastecimento, consumo e horímetro.',
          'Investigue desvios por máquina, operação e período.',
        ],
        AtlasSupplyLogisticsModule.supplyLogisticsCenter => const [
          'Centralize compras, estoque, transporte e combustível.',
          'Priorize ruptura, validade, atraso e sobrecusto.',
        ],
      });
    }

    return AtlasSupplyLogisticsAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      overdueCount: overdue,
      totalQuantity: totalQuantity,
      totalPlannedValue: totalPlanned,
      totalActualValue: totalActual,
      totalCalculatedCost: totalCalculatedCost,
      averageProgress: averageProgress,
      averageQuality: averageQuality,
      score: score,
      recommendations: recommendations,
    );
  }
}
