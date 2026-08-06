import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_finance_enterprise/domain/models/atlas_finance_enterprise_record.dart';

class AtlasFinanceEnterpriseAnalytics {
  const AtlasFinanceEnterpriseAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.totalPlanned,
    required this.totalActual,
    required this.totalProjected,
    required this.totalReference,
    required this.averageRisk,
    required this.averageConfidence,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double totalPlanned;
  final double totalActual;
  final double totalProjected;
  final double totalReference;
  final double averageRisk;
  final double averageConfidence;
  final double averageProgress;
  final int score;
  final List<String> recommendations;

  double get consolidatedDeviation => totalActual - totalPlanned;

  double get consolidatedDeviationPercent {
    if (totalPlanned == 0) return 0.0;
    return consolidatedDeviation * 100 / totalPlanned.abs();
  }
}

class AtlasFinanceEnterpriseAnalyticsService {
  const AtlasFinanceEnterpriseAnalyticsService();

  AtlasFinanceEnterpriseAnalytics analyze({
    required AtlasFinanceEnterpriseModule module,
    required List<AtlasFinanceEnterpriseRecord> records,
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

    double averageOf(
      double Function(AtlasFinanceEnterpriseRecord) selector,
    ) {
      if (moduleRecords.isEmpty) return 0.0;
      return moduleRecords
              .map(selector)
              .reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final totalPlanned = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.plannedValue,
    );
    final totalActual = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.actualValue,
    );
    final totalProjected = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.projectedValue,
    );
    final totalReference = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.referenceValue,
    );

    final averageRisk =
        averageOf((record) => record.riskPercent);
    final averageConfidence =
        averageOf((record) => record.confidencePercent);
    final averageProgress =
        averageOf((record) => record.progressPercent.toDouble());

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(
      15,
      averageConfidence.round() * 15 ~/ 100,
    );
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(25, alerts * 5);
    score -= math.min(15, averageRisk.round() * 15 ~/ 100);
    score = score.clamp(0, 100).toInt();

    return AtlasFinanceEnterpriseAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      totalPlanned: totalPlanned,
      totalActual: totalActual,
      totalProjected: totalProjected,
      totalReference: totalReference,
      averageRisk: averageRisk,
      averageConfidence: averageConfidence,
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
    required AtlasFinanceEnterpriseModule module,
    required List<AtlasFinanceEnterpriseRecord> records,
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
        'Existem $alerts alertas ou registros críticos; revise premissas, vencimentos e responsáveis.',
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
        AtlasFinanceEnterpriseModule.projectedCashFlow =>
          const [
            'Atualize premissas de receitas, despesas e datas de realização.',
            'Destaque períodos com necessidade de caixa e baixa liquidez.',
          ],
        AtlasFinanceEnterpriseModule.consolidatedCashFlow =>
          const [
            'Evite duplicidade ao consolidar empresas e fazendas.',
            'Separe caixa operacional, investimentos e financiamentos.',
          ],
        AtlasFinanceEnterpriseModule.annualBudget =>
          const [
            'Registre premissas e responsáveis por cada centro de custo.',
            'Faça revisões periódicas sem apagar o orçamento original.',
          ],
        AtlasFinanceEnterpriseModule.actualVsPlanned =>
          const [
            'Priorize desvios materiais e recorrentes.',
            'Associe cada desvio relevante a causa e plano corretivo.',
          ],
        AtlasFinanceEnterpriseModule.economicSimulations =>
          const [
            'Documente claramente premissas de cada cenário.',
            'Teste sensibilidade de preço, produção, custo e juros.',
          ],
        AtlasFinanceEnterpriseModule.bankingIndicators =>
          const [
            'Acompanhe endividamento, cobertura e capacidade de pagamento.',
            'Compare indicadores internos com condições contratadas.',
          ],
        AtlasFinanceEnterpriseModule.roi =>
          const [
            'Considere fluxo de caixa, prazo e valor do dinheiro no tempo.',
            'Compare alternativas com o mesmo horizonte e premissas.',
          ],
        AtlasFinanceEnterpriseModule.ebitda =>
          const [
            'Padronize classificação de receitas, custos e despesas.',
            'Separe itens recorrentes de ajustes extraordinários.',
          ],
        AtlasFinanceEnterpriseModule.assetValuation =>
          const [
            'Registre fonte, data e método de avaliação dos ativos.',
            'Revise valor patrimonial após mudanças relevantes.',
          ],
        AtlasFinanceEnterpriseModule.enterpriseFinanceCenter =>
          const [
            'Centralize alertas de liquidez, orçamento e endividamento.',
            'Priorize decisões por impacto, risco e prazo.',
          ],
      },
    );

    return items;
  }
}
