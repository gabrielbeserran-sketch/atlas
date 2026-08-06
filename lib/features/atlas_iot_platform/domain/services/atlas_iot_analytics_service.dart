import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_iot_platform/domain/models/atlas_iot_record.dart';

class AtlasIotAnalytics {
  const AtlasIotAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.averageSignal,
    required this.averageBattery,
    required this.averageMetric,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double averageSignal;
  final double averageBattery;
  final double averageMetric;
  final int score;
  final List<String> recommendations;
}

class AtlasIotAnalyticsService {
  const AtlasIotAnalyticsService();

  AtlasIotAnalytics analyze({
    required AtlasIotModule module,
    required List<AtlasIotRecord> records,
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

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0),
    );

    final averageSignal = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.signalPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    final averageBattery = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.batteryPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    final averageMetric = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.metricValue)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    var score = 30;
    score += math.min(30, coverage.round() * 30 ~/ 100);
    score += math.min(25, operational * 5);
    score += math.min(10, averageSignal.round() ~/ 10);
    score += math.min(10, averageBattery.round() ~/ 10);
    score -= math.min(40, alerts * 6);
    score = score.clamp(0, 100).toInt();

    return AtlasIotAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      averageSignal: averageSignal,
      averageBattery: averageBattery,
      averageMetric: averageMetric,
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
    required AtlasIotModule module,
    required List<AtlasIotRecord> records,
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
        'Existem $alerts alertas ou dispositivos em situação crítica.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
      return items;
    }

    items.addAll(
      switch (module) {
        AtlasIotModule.smartScales => const [
            'Valide calibração e unidade antes de aceitar leituras.',
            'Registre falhas de sincronização e pesos fora do padrão.',
          ],
        AtlasIotModule.rfidTags => const [
            'Garanta associação única entre brinco e animal.',
            'Audite leituras duplicadas, perdas e substituições.',
          ],
        AtlasIotModule.smartCollars => const [
            'Monitore bateria, sinal e aderência do dispositivo.',
            'Use alertas comportamentais como apoio de triagem.',
          ],
        AtlasIotModule.environmentalSensors => const [
            'Posicione sensores em locais representativos.',
            'Calibre regularmente temperatura, umidade e gases.',
          ],
        AtlasIotModule.waterSensors => const [
            'Combine nível, vazão e qualidade para reduzir falsos alertas.',
            'Inspecione fisicamente quando houver risco de abastecimento.',
          ],
        AtlasIotModule.energySensors => const [
            'Revise picos, quedas e consumo fora do padrão.',
            'Mantenha plano de contingência para falhas elétricas.',
          ],
        AtlasIotModule.weatherStations => const [
            'Registre local, altura, manutenção e horário de sincronização.',
            'Compare leituras com fontes meteorológicas de referência.',
          ],
        AtlasIotModule.drones => const [
            'Planeje voos com autorização, segurança e checklist.',
            'Associe imagens a data, local e objetivo da inspeção.',
          ],
        AtlasIotModule.satellites => const [
            'Considere resolução, nuvens e data da imagem.',
            'Valide mudanças relevantes com inspeção de campo.',
          ],
        AtlasIotModule.iotCommandCenter => const [
            'Priorize dispositivos críticos e alertas acionáveis.',
            'Mantenha saúde da rede, bateria e sincronização visíveis.',
          ],
      },
    );

    return items;
  }
}
