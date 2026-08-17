import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_automation_operations/domain/models/atlas_automation_record.dart';

class AtlasAutomationAnalytics {
  const AtlasAutomationAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasAutomationAnalyticsService {
  const AtlasAutomationAnalyticsService();

  AtlasAutomationAnalytics analyze({
    required AtlasAutomationModule module,
    required List<AtlasAutomationRecord> records,
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

    final operational = moduleRecords
        .where((record) => record.isOperational)
        .length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total + record.alertCount + (record.isCritical ? 1 : 0),
    );

    final averageProgress = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                  .map((record) => record.progressPercent)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    var score = 30;
    score += math.min(35, coverage.round() * 35 ~/ 100);
    score += math.min(25, operational * 5);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(35, alerts * 5);
    score = score.clamp(0, 100).toInt();

    return AtlasAutomationAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
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
    required AtlasAutomationModule module,
    required List<AtlasAutomationRecord> records,
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
        'Existem $alerts alertas operacionais; priorize falhas, bloqueios e dispositivos offline.',
      );
    }

    if (records.isEmpty) {
      items.add('Cadastre o primeiro registro do ${module.packageLabel}.');
    } else {
      items.addAll(switch (module) {
        AtlasAutomationModule.drone => const [
          'Valide plano de voo, autonomia, área, clima e restrições antes da operação.',
          'Confirme em campo contagens e alertas produzidos pelas imagens.',
        ],
        AtlasAutomationModule.iot => const [
          'Monitore conectividade, bateria, última leitura e qualidade do sensor.',
          'Mantenha fila offline e reconciliação de dados no Gateway Atlas.',
        ],
        AtlasAutomationModule.managementAutomation => const [
          'Automatize apenas protocolos previamente aprovados e com responsável definido.',
          'Mantenha opção de intervenção manual e trilha de auditoria.',
        ],
        AtlasAutomationModule.workflow => const [
          'Defina entrada, responsável, prazo, aprovação e evidência para cada processo.',
          'Use indicadores de tempo, retrabalho e conformidade para melhoria contínua.',
        ],
      });
    }

    return items;
  }
}
