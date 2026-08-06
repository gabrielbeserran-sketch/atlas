import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_commercial_operations/domain/models/atlas_commercial_operation_record.dart';

class AtlasCommercialOperationAnalytics {
  const AtlasCommercialOperationAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.grossAmount,
    required this.netAmount,
    required this.totalQuantity,
    required this.totalDistanceKm,
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
  final double totalDistanceKm;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasCommercialOperationAnalyticsService {
  const AtlasCommercialOperationAnalyticsService();

  AtlasCommercialOperationAnalytics analyze({
    required AtlasCommercialOperationModule module,
    required List<AtlasCommercialOperationRecord> records,
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

    final totalDistanceKm = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.distanceKm,
    );

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

    return AtlasCommercialOperationAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      pendingCount: pending,
      alertCount: alerts,
      grossAmount: grossAmount,
      netAmount: netAmount,
      totalQuantity: totalQuantity,
      totalDistanceKm: totalDistanceKm,
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
    required AtlasCommercialOperationModule module,
    required List<AtlasCommercialOperationRecord> records,
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
          AtlasCommercialOperationModule.digitalAuction =>
            const [
              'Valide lote, comissão, condição de pagamento e documentação antes da publicação.',
              'Registre lance vencedor, aceite, pagamento e entrega com trilha de auditoria.',
            ],
          AtlasCommercialOperationModule.livestockLogistics =>
            const [
              'Confirme veículo, lotação, rota, motorista, documentação e plano de contingência.',
              'Monitore tempo, paradas, temperatura, bem-estar e comprovante de entrega.',
            ],
          AtlasCommercialOperationModule.originCertification =>
            const [
              'Mantenha evidências da propriedade, lote, manejo, sanidade e cadeia de custódia.',
              'Controle validade, auditoria, não conformidades e renovação dos certificados.',
            ],
          AtlasCommercialOperationModule.ruralCrm => const [
              'Registre origem do lead, próxima atividade, responsável e probabilidade de fechamento.',
              'Acompanhe relacionamento, recompra, satisfação e oportunidades de pós-venda.',
            ],
        },
      );
    }

    return items;
  }
}
