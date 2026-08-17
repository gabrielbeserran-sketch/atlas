import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_atlas_score.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_farm_summary.dart';

class TechnicalExecutiveDiagnosis {
  const TechnicalExecutiveDiagnosis({
    required this.status,
    required this.headline,
    required this.summary,
    required this.strongPoints,
    required this.riskPoints,
    required this.officialDecision,
    required this.nextReviewLabel,
  });

  final String status;
  final String headline;
  final String summary;
  final List<String> strongPoints;
  final List<String> riskPoints;
  final String officialDecision;
  final String nextReviewLabel;

  factory TechnicalExecutiveDiagnosis.fromData({
    required TechnicalFarmSummary summary,
    required TechnicalAtlasScore score,
    double? balanceVariationPercent,
  }) {
    final ordered = [...score.pillars]
      ..sort((a, b) => b.score.compareTo(a.score));
    final strongPoints = ordered
        .where((pillar) => pillar.score >= 75)
        .take(3)
        .map(
          (pillar) =>
              '${pillar.name}: ${pillar.roundedScore}/100 — desempenho consistente.',
        )
        .toList();

    final riskPoints = <String>[];
    if (summary.overdueHealthReturns > 0) {
      riskPoints.add(
        '${summary.overdueHealthReturns} retorno(s) sanitário(s) atrasado(s).',
      );
    }
    if (summary.overdueReproductionEvents > 0) {
      riskPoints.add(
        '${summary.overdueReproductionEvents} evento(s) reprodutivo(s) atrasado(s).',
      );
    }
    if (summary.outOfStockItems > 0) {
      riskPoints.add('${summary.outOfStockItems} produto(s) sem saldo.');
    }
    if (summary.overdueAccounts > 0) {
      riskPoints.add('${summary.overdueAccounts} conta(s) vencida(s).');
    }
    if (summary.balance < 0) {
      riskPoints.add('Saldo financeiro negativo no período analisado.');
    }
    if (summary.activeAnimals > 0 && summary.averageWeight <= 0) {
      riskPoints.add('Rebanho ativo sem base de pesagens suficiente.');
    }
    if (riskPoints.isEmpty) {
      final weakest = ordered.last;
      riskPoints.add(
        '${weakest.name}: ${weakest.roundedScore}/100 — principal oportunidade de melhoria.',
      );
    }

    final status = score.total >= 800
        ? 'Gestão controlada'
        : score.total >= 650
        ? 'Gestão em atenção'
        : 'Intervenção necessária';

    final headline = score.total >= 800
        ? 'A fazenda apresenta equilíbrio geral, com pontos específicos para evolução.'
        : score.total >= 650
        ? 'A operação está funcional, mas há riscos que exigem acompanhamento próximo.'
        : 'A operação possui riscos relevantes e precisa de ações corretivas imediatas.';

    final trendText = balanceVariationPercent == null
        ? 'sem base financeira anterior suficiente para comparação'
        : balanceVariationPercent >= 0
        ? 'com melhora de ${balanceVariationPercent.toStringAsFixed(1)}% no saldo em relação ao período anterior'
        : 'com piora de ${balanceVariationPercent.abs().toStringAsFixed(1)}% no saldo em relação ao período anterior';

    final summaryText =
        'Atlas Score de ${score.total}/1000 (${score.classification}), $trendText. '
        'O diagnóstico combina indicadores de rebanho, reprodução, sanidade, nutrição, financeiro e estoque.';

    final officialDecision = score.priorityActions.isEmpty
        ? 'Manter o monitoramento e atualizar os registros da fazenda.'
        : '${score.priorityActions.first.title}. ${score.priorityActions.first.expectedImpact}.';

    return TechnicalExecutiveDiagnosis(
      status: status,
      headline: headline,
      summary: summaryText,
      strongPoints: strongPoints.isEmpty
          ? const ['Nenhum pilar atingiu nível forte neste período.']
          : strongPoints,
      riskPoints: riskPoints.take(4).toList(growable: false),
      officialDecision: officialDecision,
      nextReviewLabel: score.total < 650
          ? 'Reavaliar em 7 dias'
          : 'Reavaliar em 30 dias',
    );
  }
}
