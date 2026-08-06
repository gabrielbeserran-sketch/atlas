import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_predictive_ai_suite/domain/models/atlas_predictive_ai_record.dart';

class AtlasPredictiveAiResult {
  const AtlasPredictiveAiResult({
    required this.score,
    required this.primaryProjection,
    required this.secondaryProjection,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.riskLevel,
    required this.confidencePercent,
    required this.recommendations,
    required this.explanations,
  });

  final int score;
  final double primaryProjection;
  final double secondaryProjection;
  final String primaryLabel;
  final String secondaryLabel;
  final String riskLevel;
  final int confidencePercent;
  final List<String> recommendations;
  final List<String> explanations;
}

class AtlasPredictiveAiEngine {
  const AtlasPredictiveAiEngine();

  AtlasPredictiveAiResult evaluate(
    AtlasPredictiveAiRecord record,
  ) {
    return switch (record.module) {
      AtlasPredictiveAiModule.nutrition =>
        _nutrition(record),
      AtlasPredictiveAiModule.economics =>
        _economics(record),
      AtlasPredictiveAiModule.commercialization =>
        _commercialization(record),
    };
  }

  AtlasPredictiveAiResult _nutrition(
    AtlasPredictiveAiRecord record,
  ) {
    final weight = record.primaryInput;
    final targetGain = record.secondaryInput;
    final intake = record.tertiaryInput;
    final dailyCost = record.costValue;

    final double expectedIntake =
        weight > 0 ? weight * 0.025 : 0.0;
    final double feedEfficiency =
        intake > 0 ? targetGain / intake : 0.0;
    final double expectedCost =
        dailyCost *
        math.max(1, record.periodDays).toDouble();
    final double wastePercent =
        expectedIntake > 0 && intake > 0
            ? math
                .max(
                  0.0,
                  (intake - expectedIntake) /
                      expectedIntake *
                      100.0,
                )
                .toDouble()
            : 0.0;

    var score = 50;
    final recommendations = <String>[];
    final explanations = <String>[];

    if (weight > 0) {
      score += 10;
      explanations.add(
        'Peso informado: ${weight.toStringAsFixed(1)} kg.',
      );
    }
    if (targetGain > 0) {
      score += 10;
      explanations.add(
        'Meta de ganho: ${targetGain.toStringAsFixed(3)} kg/dia.',
      );
    }
    if (intake > 0 && expectedIntake > 0) {
      final deviation =
          ((intake - expectedIntake).abs() / expectedIntake) *
              100;
      if (deviation <= 15) {
        score += 20;
      } else {
        score -= 15;
        recommendations.add(
          'Revisar consumo informado em relação ao peso corporal.',
        );
      }
    }
    if (wastePercent > 10) {
      score -= 15;
      recommendations.add(
        'Investigar possível desperdício acima de 10%.',
      );
    }
    if (feedEfficiency <= 0 && intake > 0) {
      recommendations.add(
        'Defina meta de ganho para calcular eficiência alimentar.',
      );
    }
    if (recommendations.isEmpty) {
      recommendations.add(
        'Manter acompanhamento de consumo, ganho real e custo por kg produzido.',
      );
    }

    score = score.clamp(0, 100).toInt();

    return AtlasPredictiveAiResult(
      score: score,
      primaryProjection: expectedIntake,
      secondaryProjection: expectedCost,
      primaryLabel: 'Consumo previsto (kg/dia)',
      secondaryLabel:
          'Custo projetado no período (R\$)',
      riskLevel: score < 45
          ? 'Alto'
          : score < 70
              ? 'Moderado'
              : 'Baixo',
      confidencePercent: math.min(
        90,
        35 +
            [
              weight > 0,
              targetGain > 0,
              intake > 0,
              dailyCost > 0,
              record.periodDays > 0,
            ].where((item) => item).length *
                10,
      ),
      recommendations: recommendations,
      explanations: [
        ...explanations,
        if (feedEfficiency > 0)
          'Eficiência estimada: '
              '${feedEfficiency.toStringAsFixed(3)} '
              'kg de ganho/kg consumido.',
        if (wastePercent > 0)
          'Desvio positivo de consumo: '
              '${wastePercent.toStringAsFixed(1)}%.',
      ],
    );
  }

  AtlasPredictiveAiResult _economics(
    AtlasPredictiveAiRecord record,
  ) {
    final initialInvestment = record.primaryInput;
    final monthlyRevenue = record.revenueValue;
    final monthlyCost = record.costValue;
    final int months =
        math.max(1, record.periodDays ~/ 30).toInt();

    final monthlyProfit = monthlyRevenue - monthlyCost;
    final projectedProfit =
        monthlyProfit * months - initialInvestment;
    final double roi = initialInvestment > 0
        ? projectedProfit / initialInvestment * 100.0
        : 0.0;
    final double paybackMonths = monthlyProfit > 0
        ? initialInvestment / monthlyProfit
        : 0.0;

    var score = 50;
    final recommendations = <String>[];
    final explanations = <String>[
      'Lucro mensal estimado: '
          'R\$ ${monthlyProfit.toStringAsFixed(2)}.',
      'Horizonte considerado: $months mês(es).',
    ];

    if (monthlyProfit > 0) {
      score += 20;
    } else {
      score -= 30;
      recommendations.add(
        'Receitas não cobrem os custos mensais.',
      );
    }

    if (roi >= 20) {
      score += 20;
    } else if (roi < 0) {
      score -= 20;
      recommendations.add(
        'O cenário apresenta ROI negativo.',
      );
    }

    if (paybackMonths > 0 && paybackMonths <= 24) {
      score += 10;
    } else if (paybackMonths > 36) {
      score -= 10;
      recommendations.add(
        'Payback superior a 36 meses; revise premissas.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Validar as premissas com histórico real antes da decisão.',
      );
    }

    score = score.clamp(0, 100).toInt();

    return AtlasPredictiveAiResult(
      score: score,
      primaryProjection: projectedProfit,
      secondaryProjection: roi,
      primaryLabel: 'Lucro projetado (R\$)',
      secondaryLabel: 'ROI projetado (%)',
      riskLevel: score < 45
          ? 'Alto'
          : score < 70
              ? 'Moderado'
              : 'Baixo',
      confidencePercent: math.min(
        90,
        35 +
            [
              initialInvestment > 0,
              monthlyRevenue > 0,
              monthlyCost > 0,
              record.periodDays > 0,
            ].where((item) => item).length *
                12,
      ),
      recommendations: recommendations,
      explanations: [
        ...explanations,
        if (paybackMonths > 0)
          'Payback estimado: '
              '${paybackMonths.toStringAsFixed(1)} meses.',
      ],
    );
  }

  AtlasPredictiveAiResult _commercialization(
    AtlasPredictiveAiRecord record,
  ) {
    final liveWeight = record.primaryInput;
    final yieldPercent = record.secondaryInput;
    final arrobaPrice = record.tertiaryInput;
    final transactionCost = record.costValue;

    final carcassWeight =
        liveWeight * (yieldPercent / 100);
    final double arrobas = carcassWeight / 15.0;
    final double grossRevenue = arrobas * arrobaPrice;
    final double netRevenue =
        grossRevenue - transactionCost;
    final double netPerArroba =
        arrobas > 0 ? netRevenue / arrobas : 0.0;

    var score = 50;
    final recommendations = <String>[];
    final explanations = <String>[];

    if (liveWeight > 0) {
      score += 10;
      explanations.add(
        'Peso vivo considerado: '
            '${liveWeight.toStringAsFixed(1)} kg.',
      );
    }
    if (yieldPercent >= 50 && yieldPercent <= 60) {
      score += 15;
    } else if (yieldPercent > 0) {
      score -= 10;
      recommendations.add(
        'Revisar rendimento de carcaça informado.',
      );
    }
    if (arrobaPrice > 0) {
      score += 15;
    } else {
      score -= 20;
      recommendations.add(
        'Informe o preço esperado da arroba.',
      );
    }
    if (transactionCost > grossRevenue && grossRevenue > 0) {
      score -= 30;
      recommendations.add(
        'Custos da negociação superam a receita bruta.',
      );
    }
    if (netPerArroba > 0) {
      score += 10;
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Compare comprador, prazo de pagamento, frete, descontos e rendimento.',
      );
    }

    score = score.clamp(0, 100).toInt();

    return AtlasPredictiveAiResult(
      score: score,
      primaryProjection: netRevenue,
      secondaryProjection: netPerArroba,
      primaryLabel: 'Receita líquida estimada (R\$)',
      secondaryLabel: 'Valor líquido por arroba (R\$)',
      riskLevel: score < 45
          ? 'Alto'
          : score < 70
              ? 'Moderado'
              : 'Baixo',
      confidencePercent: math.min(
        90,
        35 +
            [
              liveWeight > 0,
              yieldPercent > 0,
              arrobaPrice > 0,
              transactionCost >= 0,
              record.referenceName.isNotEmpty,
            ].where((item) => item).length *
                10,
      ),
      recommendations: recommendations,
      explanations: [
        ...explanations,
        'Carcaça estimada: '
            '${carcassWeight.toStringAsFixed(1)} kg.',
        'Arrobas estimadas: '
            '${arrobas.toStringAsFixed(2)}.',
        if (record.referenceName.isNotEmpty)
          'Referência comercial: ${record.referenceName}.',
      ],
    );
  }
}
