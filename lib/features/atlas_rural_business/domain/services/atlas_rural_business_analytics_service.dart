import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_rural_business/domain/models/atlas_rural_business_record.dart';

class AtlasRuralBusinessAnalytics {
  const AtlasRuralBusinessAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.grossAmount,
    required this.netAmount,
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
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasRuralBusinessAnalyticsService {
  const AtlasRuralBusinessAnalyticsService();

  AtlasRuralBusinessAnalytics analyze({
    required AtlasRuralBusinessModule module,
    required List<AtlasRuralBusinessRecord> records,
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

    return AtlasRuralBusinessAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      pendingCount: pending,
      alertCount: alerts,
      grossAmount: grossAmount,
      netAmount: netAmount,
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
    required AtlasRuralBusinessModule module,
    required List<AtlasRuralBusinessRecord> records,
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
      items.add('Cadastre o primeiro registro do ${module.packageLabel}.');
    } else {
      items.addAll(switch (module) {
        AtlasRuralBusinessModule.ruralCredit => const [
          'Compare CET, prazo, carência, garantias e fluxo de caixa antes da contratação.',
          'Mantenha documentos, proposta, aprovação e cronograma vinculados.',
        ],
        AtlasRuralBusinessModule.ruralInsurance => const [
          'Compare cobertura, exclusões, franquia, vigência e procedimento de sinistro.',
          'Registre evidências e comunique eventos dentro dos prazos da apólice.',
        ],
        AtlasRuralBusinessModule.digitalContracts => const [
          'Revise partes, objeto, valores, prazos, multas e responsabilidades antes da assinatura.',
          'Mantenha versão, evidências de aprovação e trilha de alterações.',
        ],
        AtlasRuralBusinessModule.livestockMarketplace => const [
          'Valide identidade, sanidade, documentação, pagamento e logística antes do fechamento.',
          'Registre proposta, contraproposta, condições e avaliação pós-negócio.',
        ],
      });
    }

    return items;
  }
}
