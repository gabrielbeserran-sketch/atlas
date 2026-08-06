import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_environmental_ai/domain/models/atlas_environmental_ai_record.dart';

class AtlasEnvironmentalAiResult {
  const AtlasEnvironmentalAiResult({
    required this.score,
    required this.riskLevel,
    required this.primaryProjection,
    required this.secondaryProjection,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.confidencePercent,
    required this.recommendations,
    required this.explanations,
  });

  final int score;
  final String riskLevel;
  final double primaryProjection;
  final double secondaryProjection;
  final String primaryLabel;
  final String secondaryLabel;
  final int confidencePercent;
  final List<String> recommendations;
  final List<String> explanations;
}

class AtlasEnvironmentalAiEngine {
  const AtlasEnvironmentalAiEngine();

  AtlasEnvironmentalAiResult evaluate(
    AtlasEnvironmentalAiRecord record,
  ) {
    return switch (record.module) {
      AtlasEnvironmentalAiModule.climate =>
        _climate(record),
      AtlasEnvironmentalAiModule.pasture =>
        _pasture(record),
      AtlasEnvironmentalAiModule.satellite =>
        _satellite(record),
    };
  }

  AtlasEnvironmentalAiResult _climate(
    AtlasEnvironmentalAiRecord record,
  ) {
    var score = 75;
    final recommendations = <String>[];
    final explanations = <String>[];

    final heatStressIndex =
        record.temperatureCelsius + record.humidityPercent * 0.1;

    if (record.temperatureCelsius >= 35) {
      score -= 25;
      recommendations.add(
        'Reforçar sombra, água e horários de manejo para reduzir estresse térmico.',
      );
      explanations.add('Temperatura muito elevada.');
    } else if (record.temperatureCelsius <= 5 &&
        record.temperatureCelsius != 0) {
      score -= 20;
      recommendations.add(
        'Revisar proteção contra frio, vento e disponibilidade energética.',
      );
      explanations.add('Temperatura muito baixa.');
    }

    if (record.rainfallMillimeters < 20) {
      score -= 18;
      recommendations.add(
        'Planejar reserva forrageira e ajuste de lotação para cenário seco.',
      );
      explanations.add('Baixa precipitação acumulada.');
    } else if (record.rainfallMillimeters > 250) {
      score -= 12;
      recommendations.add(
        'Monitorar alagamento, barro, casco e perdas de forragem.',
      );
      explanations.add('Precipitação acumulada elevada.');
    }

    if (record.humidityPercent >= 85 &&
        record.temperatureCelsius >= 28) {
      score -= 15;
      recommendations.add(
        'Intensificar prevenção contra estresse térmico e doenças associadas.',
      );
      explanations.add(
        'Combinação de calor e umidade desfavorável.',
      );
    }

    final weightImpactPercent = math.max(
      -25.0,
      math.min(
        10.0,
        (score - 70) * 0.5,
      ),
    );

    final reproductiveImpactPercent = math.max(
      -30.0,
      math.min(
        8.0,
        (score - 70) * 0.6,
      ),
    );

    if (recommendations.isEmpty) {
      recommendations.add(
        'Manter monitoramento climático e revisar o plano preventivo semanalmente.',
      );
    }

    score = score.clamp(0, 100).toInt();

    return AtlasEnvironmentalAiResult(
      score: score,
      riskLevel: _risk(score),
      primaryProjection: weightImpactPercent,
      secondaryProjection: reproductiveImpactPercent,
      primaryLabel: 'Impacto estimado no ganho (%)',
      secondaryLabel:
          'Impacto estimado na reprodução (%)',
      confidencePercent: _confidence(record),
      recommendations: recommendations,
      explanations: [
        ...explanations,
        'Índice térmico simplificado: '
            '${heatStressIndex.toStringAsFixed(1)}.',
        'A estimativa depende da raça, categoria, manejo e adaptação.',
      ],
    );
  }

  AtlasEnvironmentalAiResult _pasture(
    AtlasEnvironmentalAiRecord record,
  ) {
    final degradationIndex = record.primaryValue;
    final forageMass = record.secondaryValue;
    final currentStocking = record.stockingRateUaHa;
    final area = record.areaHectares;

    var score = 80;
    final recommendations = <String>[];
    final explanations = <String>[];

    if (degradationIndex >= 70) {
      score -= 40;
      recommendations.add(
        'Priorizar diagnóstico de solo e plano de recuperação da área.',
      );
      explanations.add('Índice de degradação muito elevado.');
    } else if (degradationIndex >= 40) {
      score -= 20;
      recommendations.add(
        'Revisar fertilidade, invasoras, cobertura e manejo de entrada e saída.',
      );
      explanations.add('Degradação moderada.');
    }

    final idealStocking = forageMass > 0
        ? math.max(0.2, forageMass / 4000)
        : math.max(0.2, 1.0 - degradationIndex / 100);

    if (currentStocking > idealStocking * 1.2) {
      score -= 20;
      recommendations.add(
        'Reduzir temporariamente a lotação ou ampliar a oferta de forragem.',
      );
      explanations.add('Lotação acima da estimativa ideal.');
    }

    final double availabilityDays =
        currentStocking > 0 &&
                forageMass > 0 &&
                area > 0
            ? (forageMass * area) /
                (currentStocking * area * 450.0) *
                30.0
            : 0.0;

    if (availabilityDays > 0 && availabilityDays < 20) {
      score -= 15;
      recommendations.add(
        'Programar mudança de lote ou suplementação antes da queda de oferta.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Manter medições de massa de forragem, descanso e taxa de lotação.',
      );
    }

    score = score.clamp(0, 100).toInt();

    return AtlasEnvironmentalAiResult(
      score: score,
      riskLevel: _risk(score),
      primaryProjection: idealStocking,
      secondaryProjection: availabilityDays,
      primaryLabel: 'Lotação ideal estimada (UA/ha)',
      secondaryLabel:
          'Disponibilidade estimada (dias)',
      confidencePercent: _confidence(record),
      recommendations: recommendations,
      explanations: [
        ...explanations,
        if (area > 0)
          'Área analisada: ${area.toStringAsFixed(2)} ha.',
        if (forageMass > 0)
          'Massa de forragem informada: '
              '${forageMass.toStringAsFixed(0)} kg MS/ha.',
      ],
    );
  }

  AtlasEnvironmentalAiResult _satellite(
    AtlasEnvironmentalAiRecord record,
  ) {
    final ndvi = record.primaryValue;
    final moisture = record.secondaryValue;

    var score = 50;
    final recommendations = <String>[];
    final explanations = <String>[];

    if (ndvi >= 0.65) {
      score += 35;
      explanations.add('NDVI compatível com boa cobertura vegetal.');
    } else if (ndvi >= 0.4) {
      score += 15;
      recommendations.add(
        'Acompanhar tendência do NDVI antes de aumentar a lotação.',
      );
      explanations.add('NDVI intermediário.');
    } else if (ndvi > 0) {
      score -= 20;
      recommendations.add(
        'Investigar baixa cobertura vegetal, solo exposto ou estresse hídrico.',
      );
      explanations.add('NDVI baixo.');
    } else {
      score -= 15;
      recommendations.add(
        'Informe um NDVI válido entre -1 e 1.',
      );
    }

    if (moisture < 20 && moisture > 0) {
      score -= 20;
      recommendations.add(
        'Verificar risco de déficit hídrico na área monitorada.',
      );
      explanations.add('Umidade estimada baixa.');
    } else if (moisture > 80) {
      score -= 10;
      recommendations.add(
        'Monitorar saturação, encharcamento ou drenagem deficiente.',
      );
      explanations.add('Umidade estimada muito alta.');
    }

    final biomassIndex = math.max(
      0.0,
      ndvi * 100 * (moisture > 0 ? moisture / 100 : 0.5),
    );

    final environmentalAlert = score < 45 ? 1.0 : 0.0;

    if (recommendations.isEmpty) {
      recommendations.add(
        'Manter série histórica de imagens e confirmar os alertas em campo.',
      );
    }

    score = score.clamp(0, 100).toInt();

    return AtlasEnvironmentalAiResult(
      score: score,
      riskLevel: _risk(score),
      primaryProjection: biomassIndex,
      secondaryProjection: environmentalAlert,
      primaryLabel: 'Índice relativo de biomassa',
      secondaryLabel: 'Alerta ambiental (0 ou 1)',
      confidencePercent: _confidence(record),
      recommendations: recommendations,
      explanations: [
        ...explanations,
        if (record.referenceName.isNotEmpty)
          'Imagem/referência: ${record.referenceName}.',
        'Os índices devem ser conferidos com observação de campo.',
      ],
    );
  }

  String _risk(int score) {
    return switch (score) {
      < 40 => 'Alto',
      < 70 => 'Moderado',
      _ => 'Baixo',
    };
  }

  int _confidence(AtlasEnvironmentalAiRecord record) {
    final fields = <bool>[
      record.date.isNotEmpty,
      record.referenceName.isNotEmpty,
      record.primaryValue != 0,
      record.secondaryValue != 0,
      record.areaHectares > 0,
      record.temperatureCelsius != 0 ||
          record.rainfallMillimeters != 0 ||
          record.humidityPercent != 0,
    ].where((item) => item).length;

    return math.min(90, 30 + fields * 10);
  }
}
