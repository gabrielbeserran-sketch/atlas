import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_veterinary_ai/domain/models/atlas_veterinary_case.dart';

class AtlasVeterinaryHypothesis {
  const AtlasVeterinaryHypothesis({
    required this.name,
    required this.score,
    required this.reasons,
    required this.nextChecks,
  });

  final String name;
  final int score;
  final List<String> reasons;
  final List<String> nextChecks;
}

class AtlasVeterinaryAssessment {
  const AtlasVeterinaryAssessment({
    required this.triageLevel,
    required this.triageScore,
    required this.summary,
    required this.hypotheses,
    required this.immediateActions,
    required this.redFlags,
    required this.confidencePercent,
  });

  final String triageLevel;
  final int triageScore;
  final String summary;
  final List<AtlasVeterinaryHypothesis> hypotheses;
  final List<String> immediateActions;
  final List<String> redFlags;
  final int confidencePercent;
}

class AtlasVeterinaryAiEngine {
  const AtlasVeterinaryAiEngine();

  AtlasVeterinaryAssessment assess(
    AtlasVeterinaryCase clinicalCase,
  ) {
    final symptoms = clinicalCase.symptoms
        .map((item) => item.trim().toLowerCase())
        .toSet();

    final redFlags = <String>[];
    var triageScore = 0;

    if (clinicalCase.temperatureCelsius >= 40.5) {
      triageScore += 25;
      redFlags.add('Hipertermia importante.');
    } else if (clinicalCase.temperatureCelsius > 0 &&
        clinicalCase.temperatureCelsius < 37.0) {
      triageScore += 30;
      redFlags.add('Hipotermia.');
    }

    if (clinicalCase.respiratoryRateBpm >= 60) {
      triageScore += 25;
      redFlags.add('Frequência respiratória muito elevada.');
    }

    if (clinicalCase.heartRateBpm >= 120) {
      triageScore += 20;
      redFlags.add('Frequência cardíaca muito elevada.');
    }

    if (clinicalCase.hydration == 'Grave') {
      triageScore += 25;
      redFlags.add('Desidratação grave.');
    } else if (clinicalCase.hydration == 'Moderada') {
      triageScore += 12;
    }

    if (clinicalCase.locomotion == 'Não consegue ficar em pé') {
      triageScore += 35;
      redFlags.add('Animal incapaz de permanecer em estação.');
    }

    if (symptoms.contains('dificuldade respiratória')) {
      triageScore += 30;
      redFlags.add('Dificuldade respiratória.');
    }

    if (symptoms.contains('sangramento')) {
      triageScore += 25;
      redFlags.add('Sangramento.');
    }

    triageScore = triageScore.clamp(0, 100).toInt();

    final hypotheses = <AtlasVeterinaryHypothesis>[
      _respiratoryHypothesis(clinicalCase, symptoms),
      _digestiveHypothesis(clinicalCase, symptoms),
      _infectiousHypothesis(clinicalCase, symptoms),
      _locomotorHypothesis(clinicalCase, symptoms),
      _metabolicHypothesis(clinicalCase, symptoms),
    ]..sort((first, second) => second.score.compareTo(first.score));

    final meaningful = hypotheses
        .where((item) => item.score > 0)
        .take(5)
        .toList(growable: false);

    final triageLevel = switch (triageScore) {
      >= 70 => 'Emergência',
      >= 40 => 'Urgente',
      >= 20 => 'Prioritário',
      _ => 'Rotina',
    };

    final immediateActions = <String>[
      if (triageScore >= 70)
        'Acione imediatamente o médico-veterinário responsável.',
      if (triageScore >= 40)
        'Mantenha o animal identificado, em observação e com acesso seguro à água.',
      if (symptoms.contains('dificuldade respiratória'))
        'Evite condução forçada e reduza estresse e poeira.',
      if (clinicalCase.hydration != 'Normal')
        'Avalie hidratação e necessidade de fluidoterapia exclusivamente com orientação veterinária.',
      if (meaningful.isEmpty)
        'Complete sinais clínicos, exame físico e histórico antes de concluir qualquer conduta.',
      'Não administrar medicamentos sem prescrição e confirmação profissional.',
    ];

    final evidencePoints = clinicalCase.symptoms.length +
        (clinicalCase.temperatureCelsius > 0 ? 1 : 0) +
        (clinicalCase.heartRateBpm > 0 ? 1 : 0) +
        (clinicalCase.respiratoryRateBpm > 0 ? 1 : 0) +
        (clinicalCase.durationHours > 0 ? 1 : 0);

    final confidence = math.min(90, 25 + evidencePoints * 8);

    return AtlasVeterinaryAssessment(
      triageLevel: triageLevel,
      triageScore: triageScore,
      summary:
          'Apoio à triagem baseado nos sinais informados. '
          'Não substitui exame clínico, diagnóstico ou prescrição veterinária.',
      hypotheses: meaningful,
      immediateActions: immediateActions,
      redFlags: redFlags,
      confidencePercent: confidence,
    );
  }

  AtlasVeterinaryHypothesis _respiratoryHypothesis(
    AtlasVeterinaryCase clinicalCase,
    Set<String> symptoms,
  ) {
    var score = 0;
    final reasons = <String>[];

    if (symptoms.contains('tosse')) {
      score += 25;
      reasons.add('Tosse informada.');
    }
    if (symptoms.contains('secreção nasal')) {
      score += 20;
      reasons.add('Secreção nasal.');
    }
    if (symptoms.contains('dificuldade respiratória')) {
      score += 35;
      reasons.add('Dificuldade respiratória.');
    }
    if (clinicalCase.respiratoryRateBpm >= 40) {
      score += 15;
      reasons.add('Frequência respiratória elevada.');
    }
    if (clinicalCase.temperatureCelsius >= 39.5) {
      score += 10;
      reasons.add('Temperatura elevada.');
    }

    return AtlasVeterinaryHypothesis(
      name: 'Afecção respiratória',
      score: score.clamp(0, 100).toInt(),
      reasons: reasons,
      nextChecks: const [
        'Auscultação pulmonar.',
        'Caracterização da secreção nasal.',
        'Avaliação do lote e fatores ambientais.',
        'Exames complementares conforme decisão veterinária.',
      ],
    );
  }

  AtlasVeterinaryHypothesis _digestiveHypothesis(
    AtlasVeterinaryCase clinicalCase,
    Set<String> symptoms,
  ) {
    var score = 0;
    final reasons = <String>[];

    if (symptoms.contains('diarreia')) {
      score += 35;
      reasons.add('Diarreia.');
    }
    if (symptoms.contains('distensão abdominal')) {
      score += 35;
      reasons.add('Distensão abdominal.');
    }
    if (symptoms.contains('redução da ruminação')) {
      score += 25;
      reasons.add('Redução da ruminação.');
    }
    if (clinicalCase.appetite == 'Ausente') {
      score += 20;
      reasons.add('Apetite ausente.');
    }

    return AtlasVeterinaryHypothesis(
      name: 'Afecção digestiva',
      score: score.clamp(0, 100).toInt(),
      reasons: reasons,
      nextChecks: const [
        'Avaliar motilidade ruminal.',
        'Caracterizar fezes e distensão.',
        'Revisar dieta, acesso a água e mudanças recentes.',
        'Realizar exame clínico veterinário.',
      ],
    );
  }

  AtlasVeterinaryHypothesis _infectiousHypothesis(
    AtlasVeterinaryCase clinicalCase,
    Set<String> symptoms,
  ) {
    var score = 0;
    final reasons = <String>[];

    if (clinicalCase.temperatureCelsius >= 39.5) {
      score += 35;
      reasons.add('Febre ou hipertermia.');
    }
    if (symptoms.contains('apatia')) {
      score += 20;
      reasons.add('Apatia.');
    }
    if (symptoms.contains('linfonodos aumentados')) {
      score += 25;
      reasons.add('Linfonodos aumentados.');
    }
    if (clinicalCase.appetite == 'Ausente') {
      score += 15;
      reasons.add('Anorexia.');
    }

    return AtlasVeterinaryHypothesis(
      name: 'Processo infeccioso ou inflamatório',
      score: score.clamp(0, 100).toInt(),
      reasons: reasons,
      nextChecks: const [
        'Repetir temperatura e exame físico completo.',
        'Investigar outros animais afetados.',
        'Avaliar mucosas, linfonodos e foco provável.',
        'Solicitar exames conforme orientação veterinária.',
      ],
    );
  }

  AtlasVeterinaryHypothesis _locomotorHypothesis(
    AtlasVeterinaryCase clinicalCase,
    Set<String> symptoms,
  ) {
    var score = 0;
    final reasons = <String>[];

    if (symptoms.contains('claudicação')) {
      score += 40;
      reasons.add('Claudicação.');
    }
    if (symptoms.contains('edema de membro')) {
      score += 25;
      reasons.add('Edema de membro.');
    }
    if (clinicalCase.locomotion == 'Dificuldade') {
      score += 20;
      reasons.add('Dificuldade de locomoção.');
    }
    if (clinicalCase.locomotion == 'Não consegue ficar em pé') {
      score += 45;
      reasons.add('Incapacidade de permanecer em estação.');
    }

    return AtlasVeterinaryHypothesis(
      name: 'Afecção locomotora',
      score: score.clamp(0, 100).toInt(),
      reasons: reasons,
      nextChecks: const [
        'Inspecionar cascos, articulações e membros.',
        'Avaliar dor, calor, edema e lesões.',
        'Evitar deslocamento desnecessário.',
        'Realizar avaliação veterinária direcionada.',
      ],
    );
  }

  AtlasVeterinaryHypothesis _metabolicHypothesis(
    AtlasVeterinaryCase clinicalCase,
    Set<String> symptoms,
  ) {
    var score = 0;
    final reasons = <String>[];

    if (symptoms.contains('tremores')) {
      score += 25;
      reasons.add('Tremores.');
    }
    if (symptoms.contains('fraqueza')) {
      score += 25;
      reasons.add('Fraqueza.');
    }
    if (clinicalCase.appetite == 'Ausente') {
      score += 15;
      reasons.add('Apetite ausente.');
    }
    if (clinicalCase.locomotion == 'Não consegue ficar em pé') {
      score += 30;
      reasons.add('Decúbito ou incapacidade de levantar.');
    }

    return AtlasVeterinaryHypothesis(
      name: 'Distúrbio metabólico ou sistêmico',
      score: score.clamp(0, 100).toInt(),
      reasons: reasons,
      nextChecks: const [
        'Revisar categoria, fase produtiva e dieta.',
        'Avaliar hidratação, mucosas e estado neurológico.',
        'Investigar histórico de parto e mudanças alimentares.',
        'Confirmar com exame clínico e laboratorial.',
      ],
    );
  }
}
