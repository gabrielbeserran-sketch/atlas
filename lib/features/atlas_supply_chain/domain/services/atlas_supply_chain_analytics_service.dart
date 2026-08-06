import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_supply_chain/domain/models/atlas_supply_chain_record.dart';

class AtlasSupplyChainAnalytics {
  const AtlasSupplyChainAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.completedCount,
    required this.alertCount,
    required this.totalValue,
    required this.averageValue,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int completedCount;
  final int alertCount;
  final double totalValue;
  final double averageValue;
  final int score;
  final List<String> recommendations;
}

class AtlasSupplyChainAnalyticsService {
  const AtlasSupplyChainAnalyticsService();

  AtlasSupplyChainAnalytics analyze({
    required AtlasSupplyChainModule module,
    required List<AtlasSupplyChainRecord> records,
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
        : represented.length * 100 / module.features.length;

    final completed =
        moduleRecords.where((record) => record.isCompleted).length;
    final alerts =
        moduleRecords.where((record) => record.isCritical).length;

    final total = moduleRecords.fold<double>(
      0,
      (sum, record) => sum + record.totalValue,
    );

    final average =
        moduleRecords.isEmpty ? 0.0 : total / moduleRecords.length;

    var score = 35;
    score += math.min(35, coverage.round() * 35 ~/ 100);
    score += math.min(20, completed * 4);
    score -= math.min(30, alerts * 10);
    score = score.clamp(0, 100).toInt();

    return AtlasSupplyChainAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      completedCount: completed,
      alertCount: alerts,
      totalValue: total,
      averageValue: average,
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
    required AtlasSupplyChainModule module,
    required List<AtlasSupplyChainRecord> records,
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
        'Existem $alerts registros em Atenção ou Crítico; '
        'revise responsáveis, prazos e documentos.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel} '
        'para iniciar os indicadores.',
      );
    } else {
      items.addAll(
        switch (module) {
          AtlasSupplyChainModule.purchases => const [
              'Compare pelo menos três fornecedores quando o valor justificar a cotação.',
              'Vincule aprovação, recebimento e histórico de preço à mesma compra.',
            ],
          AtlasSupplyChainModule.commercialization => const [
              'Compare peso, preço por unidade e custos para apurar a margem real da venda.',
              'Mantenha contratos, romaneios e recebimentos vinculados ao negócio.',
            ],
          AtlasSupplyChainModule.logistics => const [
              'Confirme GTA, capacidade do veículo, origem, destino e janela de transporte.',
              'Compare custo por quilômetro e por animal entre rotas e transportadores.',
            ],
        },
      );
    }

    return items;
  }
}
