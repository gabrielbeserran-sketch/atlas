import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_sustainability_ecosystem/domain/models/atlas_ecosystem_record.dart';

class AtlasEcosystemAnalytics {
  const AtlasEcosystemAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.completedCount,
    required this.alertCount,
    required this.averagePrimaryValue,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int completedCount;
  final int alertCount;
  final double averagePrimaryValue;
  final int score;
  final List<String> recommendations;
}

class AtlasEcosystemAnalyticsService {
  const AtlasEcosystemAnalyticsService();

  AtlasEcosystemAnalytics analyze({
    required AtlasEcosystemModule module,
    required List<AtlasEcosystemRecord> records,
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

    final completed = moduleRecords
        .where((record) => record.isCompleted)
        .length;
    final alerts = moduleRecords.where((record) => record.isCritical).length;

    final values = moduleRecords
        .map((record) => record.primaryValue)
        .where((value) => value != 0)
        .toList(growable: false);

    final average = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    var score = 35;
    score += math.min(35, coverage.round() * 35 ~/ 100);
    score += math.min(20, completed * 4);
    score -= math.min(30, alerts * 10);
    score = score.clamp(0, 100).toInt();

    return AtlasEcosystemAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      completedCount: completed,
      alertCount: alerts,
      averagePrimaryValue: average,
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
    required AtlasEcosystemModule module,
    required List<AtlasEcosystemRecord> records,
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
        'Existem $alerts registros em atenção, crítico ou desconectado; '
        'priorize diagnóstico e plano de ação.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel} '
        'para iniciar os indicadores.',
      );
    } else {
      items.addAll(switch (module) {
        AtlasEcosystemModule.sustainability => const [
          'Associe indicadores ambientais à produção por hectare e por arroba.',
          'Mantenha evidências, responsáveis e periodicidade de medição.',
        ],
        AtlasEcosystemModule.iot => const [
          'Valide conectividade, horário da última leitura e qualidade do dado.',
          'Defina rotina offline e reconciliação para dispositivos desconectados.',
        ],
        AtlasEcosystemModule.consultancy => const [
          'Vincule cada visita a diagnóstico, plano de ação, prazo e responsável.',
          'Compare clientes por indicadores equivalentes e preserve confidencialidade.',
        ],
      });
    }

    return items;
  }
}
