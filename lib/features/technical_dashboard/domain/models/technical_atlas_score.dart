import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_farm_summary.dart';

class TechnicalAtlasScorePillar {
  const TechnicalAtlasScorePillar({
    required this.name,
    required this.score,
    required this.weightPercent,
    required this.recommendation,
  });

  final String name;
  final double score;
  final int weightPercent;
  final String recommendation;

  int get roundedScore => score.round().clamp(0, 100);
}

class TechnicalAtlasPriorityAction {
  const TechnicalAtlasPriorityAction({
    required this.area,
    required this.title,
    required this.description,
    required this.priority,
    required this.deadlineLabel,
    required this.expectedImpact,
  });

  final String area;
  final String title;
  final String description;
  final int priority;
  final String deadlineLabel;
  final String expectedImpact;

  String get priorityLabel {
    if (priority >= 3) return 'Urgente';
    if (priority == 2) return 'Alta';
    return 'Moderada';
  }
}

class TechnicalAtlasScore {
  const TechnicalAtlasScore({
    required this.total,
    required this.classification,
    required this.pillars,
    required this.recommendations,
    required this.priorityActions,
  });

  final int total;
  final String classification;
  final List<TechnicalAtlasScorePillar> pillars;
  final List<String> recommendations;
  final List<TechnicalAtlasPriorityAction> priorityActions;

  factory TechnicalAtlasScore.fromSummary(TechnicalFarmSummary summary) {
    final herd = _herdScore(summary);
    final reproduction = _reproductionScore(summary);
    final health = _healthScore(summary);
    final nutrition = _nutritionScore(summary);
    final finance = _financeScore(summary);
    final inventory = _inventoryScore(summary);

    final pillars = <TechnicalAtlasScorePillar>[
      TechnicalAtlasScorePillar(
        name: 'Rebanho',
        score: herd,
        weightPercent: 20,
        recommendation: summary.activeAnimals == 0
            ? 'Cadastre animais ativos para consolidar os indicadores do rebanho.'
            : summary.averageWeight <= 0
                ? 'Atualize as pesagens dos animais ativos.'
                : 'Mantenha as pesagens e os cadastros do rebanho atualizados.',
      ),
      TechnicalAtlasScorePillar(
        name: 'Reprodução',
        score: reproduction,
        weightPercent: 20,
        recommendation: summary.overdueReproductionEvents > 0
            ? 'Regularize ${summary.overdueReproductionEvents} evento(s) reprodutivo(s) atrasado(s).'
            : summary.reproductionRecords == 0
                ? 'Registre os eventos reprodutivos da fazenda.'
                : 'Acompanhe os próximos eventos e diagnósticos reprodutivos.',
      ),
      TechnicalAtlasScorePillar(
        name: 'Sanidade',
        score: health,
        weightPercent: 20,
        recommendation: summary.overdueHealthReturns > 0
            ? 'Regularize ${summary.overdueHealthReturns} retorno(s) sanitário(s) atrasado(s).'
            : summary.quarantines > 0
                ? 'Acompanhe ${summary.quarantines} animal(is) em quarentena.'
                : 'Mantenha o calendário sanitário em dia.',
      ),
      TechnicalAtlasScorePillar(
        name: 'Nutrição',
        score: nutrition,
        weightPercent: 15,
        recommendation: summary.nutritionPlans == 0
            ? 'Cadastre ao menos um plano nutricional para os animais ativos.'
            : summary.nutritionAnimals < summary.activeAnimals
                ? 'Revise a cobertura dos planos nutricionais sobre o rebanho ativo.'
                : 'Monitore consumo e custo diário das dietas.',
      ),
      TechnicalAtlasScorePillar(
        name: 'Financeiro',
        score: finance,
        weightPercent: 15,
        recommendation: summary.overdueAccounts > 0
            ? 'Regularize ${summary.overdueAccounts} conta(s) vencida(s).'
            : summary.balance < 0
                ? 'As despesas superam as receitas no período analisado.'
                : 'Mantenha receitas, despesas e vencimentos atualizados.',
      ),
      TechnicalAtlasScorePillar(
        name: 'Estoque',
        score: inventory,
        weightPercent: 10,
        recommendation: summary.outOfStockItems > 0
            ? 'Reponha ${summary.outOfStockItems} produto(s) sem saldo.'
            : summary.lowStockItems > 0
                ? 'Reponha ${summary.lowStockItems} produto(s) abaixo do mínimo.'
                : 'Mantenha níveis mínimos e movimentações atualizados.',
      ),
    ];

    final weighted = pillars.fold<double>(
      0,
      (sum, pillar) => sum + pillar.score * pillar.weightPercent / 100,
    );
    final total = (weighted * 10).round().clamp(0, 1000);

    final ordered = [...pillars]..sort((a, b) => a.score.compareTo(b.score));
    final recommendations = ordered
        .where((pillar) => pillar.score < 85)
        .take(3)
        .map((pillar) => pillar.recommendation)
        .toList();

    return TechnicalAtlasScore(
      total: total,
      classification: _classification(total),
      pillars: pillars,
      recommendations: recommendations.isEmpty
          ? const [
              'Os indicadores estão equilibrados. Continue atualizando os registros.',
            ]
          : recommendations,
      priorityActions: _buildPriorityActions(summary, pillars),
    );
  }

  static List<TechnicalAtlasPriorityAction> _buildPriorityActions(
    TechnicalFarmSummary summary,
    List<TechnicalAtlasScorePillar> pillars,
  ) {
    final actions = <TechnicalAtlasPriorityAction>[];

    if (summary.outOfStockItems > 0) {
      actions.add(TechnicalAtlasPriorityAction(
        area: 'Estoque',
        title: 'Repor produtos sem saldo',
        description:
            '${summary.outOfStockItems} produto(s) estão indisponíveis e podem interromper rotinas técnicas.',
        priority: 3,
        deadlineLabel: 'Hoje',
        expectedImpact: 'Evita interrupções operacionais',
      ));
    }
    if (summary.overdueHealthReturns > 0) {
      actions.add(TechnicalAtlasPriorityAction(
        area: 'Sanidade',
        title: 'Regularizar retornos sanitários',
        description:
            '${summary.overdueHealthReturns} retorno(s) estão atrasados e precisam de revisão.',
        priority: 3,
        deadlineLabel: 'Em até 24 horas',
        expectedImpact: 'Reduz risco sanitário',
      ));
    }
    if (summary.overdueReproductionEvents > 0) {
      actions.add(TechnicalAtlasPriorityAction(
        area: 'Reprodução',
        title: 'Executar eventos reprodutivos atrasados',
        description:
            '${summary.overdueReproductionEvents} evento(s) aguardam execução ou atualização.',
        priority: 3,
        deadlineLabel: 'Em até 24 horas',
        expectedImpact: 'Protege o calendário reprodutivo',
      ));
    }
    if (summary.overdueAccounts > 0) {
      actions.add(TechnicalAtlasPriorityAction(
        area: 'Financeiro',
        title: 'Regularizar contas vencidas',
        description:
            '${summary.overdueAccounts} conta(s) vencida(s) podem gerar juros e comprometer o caixa.',
        priority: 3,
        deadlineLabel: 'Hoje',
        expectedImpact: 'Reduz perdas financeiras',
      ));
    }
    if (summary.balance < 0) {
      actions.add(TechnicalAtlasPriorityAction(
        area: 'Financeiro',
        title: 'Revisar despesas do período',
        description:
            'O saldo está negativo. Identifique as maiores despesas e defina cortes ou ajustes.',
        priority: 2,
        deadlineLabel: 'Nesta semana',
        expectedImpact: 'Recupera equilíbrio do caixa',
      ));
    }
    if (summary.lowStockItems > 0) {
      actions.add(TechnicalAtlasPriorityAction(
        area: 'Estoque',
        title: 'Programar reposição preventiva',
        description:
            '${summary.lowStockItems} produto(s) estão abaixo do estoque mínimo.',
        priority: 2,
        deadlineLabel: 'Nesta semana',
        expectedImpact: 'Previne rupturas de estoque',
      ));
    }
    if (summary.activeAnimals > 0 && summary.averageWeight <= 0) {
      actions.add(const TechnicalAtlasPriorityAction(
        area: 'Rebanho',
        title: 'Atualizar pesagens do rebanho',
        description:
            'Os animais ativos não possuem base de peso suficiente para análise produtiva.',
        priority: 2,
        deadlineLabel: 'Nos próximos 7 dias',
        expectedImpact: 'Melhora decisões produtivas',
      ));
    }
    if (summary.activeAnimals > 0 && summary.nutritionPlans == 0) {
      actions.add(const TechnicalAtlasPriorityAction(
        area: 'Nutrição',
        title: 'Criar plano nutricional',
        description:
            'Não há plano nutricional ativo para acompanhar consumo e custo alimentar.',
        priority: 2,
        deadlineLabel: 'Nos próximos 7 dias',
        expectedImpact: 'Melhora desempenho e controle de custos',
      ));
    }

    if (actions.isEmpty) {
      final weakest = [...pillars]..sort((a, b) => a.score.compareTo(b.score));
      actions.add(TechnicalAtlasPriorityAction(
        area: weakest.first.name,
        title: 'Fortalecer o pilar ${weakest.first.name}',
        description: weakest.first.recommendation,
        priority: 1,
        deadlineLabel: 'Neste mês',
        expectedImpact: 'Eleva o Atlas Score',
      ));
    }

    actions.sort((a, b) => b.priority.compareTo(a.priority));
    return actions.take(5).toList(growable: false);
  }

  static double _herdScore(TechnicalFarmSummary s) {
    var score = 100.0;
    if (s.activeAnimals == 0) return 25;
    if (s.groupCount == 0) score -= 15;
    if (s.averageWeight <= 0) score -= 30;
    if (s.totalAnimals > 0 && s.activeAnimals / s.totalAnimals < 0.5) score -= 10;
    return score.clamp(0, 100).toDouble();
  }

  static double _reproductionScore(TechnicalFarmSummary s) {
    var score = 100.0;
    if (s.reproductionRecords == 0) score -= 35;
    score -= s.overdueReproductionEvents * 8;
    if (s.reproductionRecords > 0 && s.positivePregnancies == 0) score -= 15;
    return score.clamp(0, 100).toDouble();
  }

  static double _healthScore(TechnicalFarmSummary s) {
    var score = 100.0;
    if (s.healthRecords == 0) score -= 30;
    score -= s.overdueHealthReturns * 8;
    score -= s.quarantines * 4;
    score -= s.activeWithdrawals * 2;
    return score.clamp(0, 100).toDouble();
  }

  static double _nutritionScore(TechnicalFarmSummary s) {
    if (s.activeAnimals == 0) return 50;
    var score = 100.0;
    if (s.nutritionPlans == 0) return 35;
    final coverage = s.nutritionAnimals / s.activeAnimals;
    if (coverage < 1) score -= (1 - coverage.clamp(0, 1)) * 45;
    if (s.dailyFeedKg <= 0) score -= 15;
    return score.clamp(0, 100).toDouble();
  }

  static double _financeScore(TechnicalFarmSummary s) {
    var score = 100.0;
    if (s.income == 0 && s.expenses == 0) score -= 30;
    if (s.balance < 0) {
      final deficitRatio = s.expenses == 0 ? 1.0 : (-s.balance / s.expenses);
      score -= 25 + deficitRatio.clamp(0, 1) * 25;
    }
    score -= s.overdueAccounts * 8;
    return score.clamp(0, 100).toDouble();
  }

  static double _inventoryScore(TechnicalFarmSummary s) {
    var score = 100.0;
    if (s.inventoryItems == 0) return 40;
    final denominator = s.inventoryItems == 0 ? 1 : s.inventoryItems;
    score -= (s.lowStockItems / denominator) * 35;
    score -= (s.outOfStockItems / denominator) * 50;
    if (s.inventoryMovements == 0) score -= 10;
    return score.clamp(0, 100).toDouble();
  }

  static String _classification(int score) {
    if (score >= 900) return 'Excelente';
    if (score >= 800) return 'Muito bom';
    if (score >= 700) return 'Bom';
    if (score >= 600) return 'Atenção';
    return 'Crítico';
  }
}
