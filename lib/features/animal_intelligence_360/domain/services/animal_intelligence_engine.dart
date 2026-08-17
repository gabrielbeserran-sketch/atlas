class AnimalIntelligenceEngine {
  const AnimalIntelligenceEngine._();

  static double? calculateGmd({
    required double firstWeight,
    required double lastWeight,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final days = lastDate.difference(firstDate).inDays;
    if (days <= 0) return null;
    return (lastWeight - firstWeight) / days;
  }

  static double? projectWeight({
    required double currentWeight,
    required double? gmd,
    required int days,
  }) {
    if (gmd == null) return null;
    final projected = currentWeight + gmd * days;
    return projected < 0 ? 0 : projected;
  }

  static int score360({
    required int weightCount,
    required int healthCount,
    required int reproductionCount,
    required int nutritionCount,
    required int documentCount,
    required int photoCount,
    required int movementCount,
    required double? gmd,
    required double bodyConditionScore,
    required int criticalAlerts,
  }) {
    var score = 20;

    if (weightCount >= 2) score += 15;
    if (weightCount >= 4) score += 5;
    if (healthCount > 0) score += 10;
    if (reproductionCount > 0) score += 10;
    if (nutritionCount > 0) score += 10;
    if (documentCount > 0) score += 8;
    if (photoCount > 0) score += 5;
    if (movementCount > 0) score += 4;
    if (bodyConditionScore > 0) score += 5;

    if (gmd != null) {
      if (gmd > 0.5) {
        score += 8;
      } else if (gmd > 0) {
        score += 4;
      } else if (gmd < 0) {
        score -= 12;
      }
    }

    score -= criticalAlerts * 5;
    return score.clamp(0, 100).toInt();
  }

  static List<String> recommendations({
    required int weightCount,
    required int healthCount,
    required int reproductionCount,
    required int nutritionCount,
    required int documentCount,
    required double? gmd,
    required double bodyConditionScore,
    required bool female,
    required int expiredDocuments,
    required int openTasks,
  }) {
    final items = <String>[];

    if (weightCount < 2) {
      items.add(
        'Cadastre duas pesagens em datas diferentes para calcular o GMD.',
      );
    }
    if (gmd != null && gmd < 0) {
      items.add(
        'Investigue imediatamente a perda de peso: consumo, sanidade, competição e lote.',
      );
    }
    if (healthCount == 0) {
      items.add(
        'Complete o histórico sanitário e configure o calendário preventivo.',
      );
    }
    if (female && reproductionCount == 0) {
      items.add('Cadastre a situação reprodutiva e o último manejo da matriz.');
    }
    if (nutritionCount == 0) {
      items.add('Cadastre a dieta, o custo diário e a meta de ganho.');
    }
    if (documentCount == 0) {
      items.add(
        'Inclua documentos oficiais, sanitários e comerciais do animal.',
      );
    }
    if (expiredDocuments > 0) {
      items.add('Regularize $expiredDocuments documento(s) vencido(s).');
    }
    if (bodyConditionScore <= 0) {
      items.add(
        'Informe o escore corporal para melhorar o diagnóstico nutricional e reprodutivo.',
      );
    }
    if (openTasks > 0) {
      items.add(
        'Existem $openTasks tarefa(s) aberta(s) na agenda operacional.',
      );
    }
    if (items.isEmpty) {
      items.add(
        'Não há ação crítica imediata; mantenha o calendário e a qualidade dos registros.',
      );
    }

    return items;
  }

  static String diagnosis({
    required int score,
    required double? gmd,
    required int criticalAlerts,
  }) {
    if (criticalAlerts > 0) {
      return 'Atenção prioritária: existem alertas críticos que exigem ação e registro de resolução.';
    }
    if (gmd != null && gmd < 0) {
      return 'Desempenho em deterioração: a série de pesagens indica perda de peso.';
    }
    if (score >= 80) {
      return 'Situação consistente: boa completude de dados e indicadores controlados.';
    }
    if (score >= 60) {
      return 'Situação intermediária: o animal está acompanhado, mas ainda há lacunas relevantes.';
    }
    return 'Base insuficiente ou risco elevado: priorize dados essenciais e pendências operacionais.';
  }
}
