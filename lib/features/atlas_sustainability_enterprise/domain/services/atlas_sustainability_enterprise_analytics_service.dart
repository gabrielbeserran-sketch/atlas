import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_sustainability_enterprise/domain/models/atlas_sustainability_enterprise_record.dart';

class AtlasSustainabilityEnterpriseAnalytics {
  const AtlasSustainabilityEnterpriseAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.totalCurrentValue,
    required this.totalBaselineValue,
    required this.totalTargetValue,
    required this.averageQuality,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double totalCurrentValue;
  final double totalBaselineValue;
  final double totalTargetValue;
  final double averageQuality;
  final double averageProgress;
  final int score;
  final List<String> recommendations;

  double get consolidatedChangePercent {
    if (totalBaselineValue == 0) return 0.0;

    return (totalCurrentValue - totalBaselineValue) *
        100 /
        totalBaselineValue.abs();
  }
}

class AtlasSustainabilityEnterpriseAnalyticsService {
  const AtlasSustainabilityEnterpriseAnalyticsService();

  AtlasSustainabilityEnterpriseAnalytics analyze({
    required AtlasSustainabilityEnterpriseModule module,
    required List<AtlasSustainabilityEnterpriseRecord> records,
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
          (record.isCritical ? 1 : 0) +
          (record.isOverdue ? 1 : 0),
    );

    double averageOf(
      double Function(
        AtlasSustainabilityEnterpriseRecord,
      ) selector,
    ) {
      if (moduleRecords.isEmpty) return 0.0;

      return moduleRecords
              .map(selector)
              .reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final totalCurrent = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.currentValue,
    );
    final totalBaseline = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.baselineValue,
    );
    final totalTarget = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.targetValue,
    );

    final averageQuality =
        averageOf((record) => record.qualityPercent);
    final averageProgress =
        averageOf((record) => record.progressPercent.toDouble());

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, averageQuality.round() * 15 ~/ 100);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(35, alerts * 5);
    score = score.clamp(0, 100).toInt();

    return AtlasSustainabilityEnterpriseAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      totalCurrentValue: totalCurrent,
      totalBaselineValue: totalBaseline,
      totalTargetValue: totalTarget,
      averageQuality: averageQuality,
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
    required AtlasSustainabilityEnterpriseModule module,
    required List<AtlasSustainabilityEnterpriseRecord> records,
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
        'Existem $alerts alertas, vencimentos ou não conformidades; revise responsáveis, evidências e prazos.',
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
        AtlasSustainabilityEnterpriseModule.carbonFootprint =>
          const [
            'Padronize fatores de emissão, período e limites do inventário.',
            'Separe redução real, remoção e compensação.',
          ],
        AtlasSustainabilityEnterpriseModule.greenhouseGasInventory =>
          const [
            'Documente fontes, escopos e metodologia de cálculo.',
            'Mantenha rastreabilidade dos dados usados no inventário.',
          ],
        AtlasSustainabilityEnterpriseModule.waterManagement =>
          const [
            'Meça captação, consumo, qualidade e reuso por atividade.',
            'Priorize perdas, risco de abastecimento e eficiência.',
          ],
        AtlasSustainabilityEnterpriseModule.energyEfficiency =>
          const [
            'Compare consumo, produção e origem da energia.',
            'Avalie eficiência antes de recomendar novos investimentos.',
          ],
        AtlasSustainabilityEnterpriseModule.wasteManagement =>
          const [
            'Classifique resíduos, riscos, volume e destinação.',
            'Registre comprovantes e oportunidades de reaproveitamento.',
          ],
        AtlasSustainabilityEnterpriseModule.biodiversity =>
          const [
            'Associe observações a área, data e evidência.',
            'Valide intervenções com profissionais ambientais.',
          ],
        AtlasSustainabilityEnterpriseModule.environmentalCompliance =>
          const [
            'Controle licenças, condicionantes e evidências por prazo.',
            'Trate não conformidades com responsável e plano corretivo.',
          ],
        AtlasSustainabilityEnterpriseModule.sustainabilityCertifications =>
          const [
            'Mapeie requisitos, auditorias e validade de cada certificado.',
            'Não confunda preparação interna com certificação emitida.',
          ],
        AtlasSustainabilityEnterpriseModule.sustainableTraceability =>
          const [
            'Registre origem, fornecedores, evidências e destino.',
            'Evite lacunas na cadeia de custódia.',
          ],
        AtlasSustainabilityEnterpriseModule.esgCenter =>
          const [
            'Integre ambiente, pessoas e governança no mesmo painel.',
            'Priorize metas por impacto, risco e materialidade.',
          ],
      },
    );

    return items;
  }
}
