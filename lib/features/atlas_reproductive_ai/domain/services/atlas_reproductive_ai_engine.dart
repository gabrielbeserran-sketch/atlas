import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_reproductive_ai/domain/models/atlas_reproductive_prediction_case.dart';

class AtlasReproductivePrediction {
  const AtlasReproductivePrediction({
    required this.heatProbabilityPercent,
    required this.pregnancyProbabilityPercent,
    required this.iatfSuccessProbabilityPercent,
    required this.expectedCalvingDate,
    required this.priority,
    required this.riskFactors,
    required this.positiveFactors,
    required this.recommendations,
    required this.confidencePercent,
  });

  final int heatProbabilityPercent;
  final int pregnancyProbabilityPercent;
  final int iatfSuccessProbabilityPercent;
  final DateTime? expectedCalvingDate;
  final String priority;
  final List<String> riskFactors;
  final List<String> positiveFactors;
  final List<String> recommendations;
  final int confidencePercent;
}

class AtlasReproductiveAiEngine {
  const AtlasReproductiveAiEngine();

  AtlasReproductivePrediction predict(
    AtlasReproductivePredictionCase data,
  ) {
    final risks = <String>[];
    final positives = <String>[];

    var heat = 45;
    var pregnancy = 45;
    var iatf = 45;

    if (data.bodyConditionScore >= 3 &&
        data.bodyConditionScore <= 3.75) {
      heat += 15;
      pregnancy += 15;
      iatf += 12;
      positives.add('Escore corporal em faixa favorável.');
    } else if (data.bodyConditionScore > 0 &&
        (data.bodyConditionScore < 2.5 ||
            data.bodyConditionScore > 4.25)) {
      heat -= 18;
      pregnancy -= 20;
      iatf -= 18;
      risks.add('Escore corporal desfavorável.');
    }

    if (data.daysPostpartum >= 45) {
      heat += 10;
      pregnancy += 8;
      positives.add('Período pós-parto compatível com retorno reprodutivo.');
    } else if (data.daysPostpartum > 0) {
      heat -= 15;
      pregnancy -= 12;
      iatf -= 10;
      risks.add('Pós-parto ainda curto.');
    }

    if (data.cycleRegular) {
      heat += 18;
      pregnancy += 10;
      positives.add('Ciclo informado como regular.');
    } else {
      heat -= 12;
      pregnancy -= 8;
      risks.add('Ciclo irregular ou não confirmado.');
    }

    if (data.heatSigns) {
      heat += 20;
      pregnancy += 6;
      positives.add('Sinais de cio observados.');
    }

    if (data.serviceCount >= 3) {
      pregnancy -= 18;
      iatf -= 15;
      risks.add('Múltiplos serviços sem confirmação de gestação.');
    }

    if (data.previousPregnancyLoss) {
      pregnancy -= 15;
      iatf -= 10;
      risks.add('Histórico de perda gestacional.');
    }

    if (data.healthRisk == 'Alto') {
      heat -= 10;
      pregnancy -= 20;
      iatf -= 18;
      risks.add('Risco sanitário alto.');
    } else if (data.healthRisk == 'Moderado') {
      pregnancy -= 8;
      iatf -= 6;
      risks.add('Risco sanitário moderado.');
    }

    if (data.semenQuality == 'Alta') {
      pregnancy += 10;
      iatf += 12;
      positives.add('Qualidade de sêmen favorável.');
    } else if (data.semenQuality == 'Baixa') {
      pregnancy -= 12;
      iatf -= 15;
      risks.add('Qualidade de sêmen desfavorável.');
    }

    if (data.technicianExperience == 'Alta') {
      iatf += 10;
      positives.add('Experiência técnica elevada.');
    } else if (data.technicianExperience == 'Baixa') {
      iatf -= 10;
      risks.add('Baixa experiência técnica informada.');
    }

    if (data.protocolType != 'Não informado') {
      iatf += 8;
      positives.add('Protocolo reprodutivo identificado.');
    }

    heat = heat.clamp(0, 100).toInt();
    pregnancy = pregnancy.clamp(0, 100).toInt();
    iatf = iatf.clamp(0, 100).toInt();

    final serviceDate = parseAtlasReproductiveDate(data.date);
    DateTime? expectedCalvingDate;

    if (data.daysSinceLastService >= 0 &&
        serviceDate.year > 1900 &&
        data.status == 'Servida') {
      expectedCalvingDate =
          serviceDate.add(const Duration(days: 283));
    }

    final priority = switch (math.min(
      heat,
      math.min(pregnancy, iatf),
    )) {
      < 35 => 'Alta',
      < 60 => 'Média',
      _ => 'Baixa',
    };

    final recommendations = <String>[
      if (data.bodyConditionScore < 2.5 &&
          data.bodyConditionScore > 0)
        'Priorizar recuperação do escore corporal antes de novo serviço.',
      if (data.bodyConditionScore > 4.25)
        'Reavaliar condição corporal e estratégia nutricional.',
      if (!data.cycleRegular)
        'Confirmar atividade ovariana e condição uterina com avaliação veterinária.',
      if (data.daysPostpartum > 0 &&
          data.daysPostpartum < 45)
        'Respeitar o período de recuperação pós-parto e reavaliar posteriormente.',
      if (data.serviceCount >= 3)
        'Investigar repetição de serviço, sanidade uterina, sêmen e execução.',
      if (data.healthRisk != 'Baixo')
        'Controlar o risco sanitário antes de intensificar o protocolo reprodutivo.',
      if (iatf >= 65)
        'Cenário favorável para continuidade do protocolo, sujeito à avaliação profissional.',
      if (risks.isEmpty)
        'Manter monitoramento, registros e confirmação diagnóstica.',
    ];

    final evidencePoints = <bool>[
      data.bodyConditionScore > 0,
      data.daysPostpartum > 0,
      data.daysSinceLastService >= 0,
      data.protocolType != 'Não informado',
      data.semenQuality != 'Não informado',
    ].where((value) => value).length;

    final confidence = math.min(90, 40 + evidencePoints * 10);

    return AtlasReproductivePrediction(
      heatProbabilityPercent: heat,
      pregnancyProbabilityPercent: pregnancy,
      iatfSuccessProbabilityPercent: iatf,
      expectedCalvingDate: expectedCalvingDate,
      priority: priority,
      riskFactors: risks,
      positiveFactors: positives,
      recommendations: recommendations,
      confidencePercent: confidence,
    );
  }
}
