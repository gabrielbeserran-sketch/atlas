import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin_simulation.dart';

class AtlasDigitalTwinV2Engine {
  const AtlasDigitalTwinV2Engine();

  List<AtlasDigitalTwinAreaInsight> buildInsights(AtlasDigitalTwin twin) {
    final values = <AtlasDigitalTwinArea, double>{
      AtlasDigitalTwinArea.animal: twin.health.animal,
      AtlasDigitalTwinArea.sanitary: twin.health.sanitary,
      AtlasDigitalTwinArea.reproductive: twin.health.reproductive,
      AtlasDigitalTwinArea.financial: twin.health.financial,
      AtlasDigitalTwinArea.inventory: twin.health.inventory,
      AtlasDigitalTwinArea.operational: twin.health.operational,
    };

    return values.entries.map((entry) {
      return AtlasDigitalTwinAreaInsight(
        area: entry.key,
        score: entry.value,
        status: _status(entry.value),
        recommendation: _recommendation(entry.key, entry.value),
      );
    }).toList();
  }

  AtlasDigitalTwinSimulationResult simulate({
    required AtlasDigitalTwin twin,
    required AtlasDigitalTwinSimulationRequest request,
  }) {
    final areaScore = _areaScore(twin, request.area);
    final normalizedChange = request.changePercent.clamp(-40.0, 40.0);
    final horizonFactor = (request.horizonDays / 365).clamp(0.10, 1.0);
    final investmentFactor = request.investmentValue <= 0
        ? 0.85
        : (1 + request.investmentValue / 250000).clamp(1.0, 1.40);

    final areaVariation = normalizedChange * 0.42 * horizonFactor * investmentFactor;
    final projectedAreaScore = (areaScore + areaVariation).clamp(0.0, 100.0);
    final overallWeight = _areaWeight(request.area);
    final scoreVariation = (projectedAreaScore - areaScore) * overallWeight;
    final projectedScore = (twin.overallScore + scoreVariation).clamp(0.0, 100.0);
    final financialImpact = request.investmentValue == 0
        ? normalizedChange * 850 * horizonFactor
        : request.investmentValue * (normalizedChange / 100) * 1.65;
    final riskReduction = normalizedChange <= 0
        ? 0.0
        : (normalizedChange * 0.72 * horizonFactor).clamp(0.0, 35.0);
    final confidence = (68 + horizonFactor * 14 - (normalizedChange.abs() * 0.18))
        .clamp(55.0, 91.0);

    return AtlasDigitalTwinSimulationResult(
      request: request,
      currentScore: twin.overallScore,
      projectedScore: projectedScore.toDouble(),
      scoreVariation: scoreVariation.toDouble(),
      projectedFinancialImpact: financialImpact.toDouble(),
      riskReductionPercent: riskReduction.toDouble(),
      confidencePercent: confidence.toDouble(),
      recommendation: _simulationRecommendation(
        request.area,
        scoreVariation.toDouble(),
        financialImpact.toDouble(),
      ),
      generatedAt: DateTime.now(),
    );
  }

  String executiveSummary(AtlasDigitalTwin twin) {
    final insights = buildInsights(twin)..sort((a, b) => a.score.compareTo(b.score));
    final weakest = insights.first;
    final criticalRisks = twin.risks.where((risk) {
      return risk.level == AtlasFarmRiskLevel.high ||
          risk.level == AtlasFarmRiskLevel.critical;
    }).length;

    return 'A propriedade apresenta score geral de ${twin.overallScore.toStringAsFixed(0)} pontos. '
        'A área que exige maior atenção é ${atlasDigitalTwinAreaLabel(weakest.area)}, '
        'com ${weakest.score.toStringAsFixed(0)} pontos. '
        'Existem $criticalRisks riscos altos ou críticos no momento.';
  }

  double _areaScore(AtlasDigitalTwin twin, AtlasDigitalTwinArea area) {
    switch (area) {
      case AtlasDigitalTwinArea.animal:
        return twin.health.animal;
      case AtlasDigitalTwinArea.sanitary:
        return twin.health.sanitary;
      case AtlasDigitalTwinArea.reproductive:
        return twin.health.reproductive;
      case AtlasDigitalTwinArea.financial:
        return twin.health.financial;
      case AtlasDigitalTwinArea.inventory:
        return twin.health.inventory;
      case AtlasDigitalTwinArea.operational:
        return twin.health.operational;
    }
  }

  double _areaWeight(AtlasDigitalTwinArea area) {
    switch (area) {
      case AtlasDigitalTwinArea.animal:
        return 0.18;
      case AtlasDigitalTwinArea.sanitary:
        return 0.20;
      case AtlasDigitalTwinArea.reproductive:
        return 0.17;
      case AtlasDigitalTwinArea.financial:
        return 0.18;
      case AtlasDigitalTwinArea.inventory:
        return 0.12;
      case AtlasDigitalTwinArea.operational:
        return 0.15;
    }
  }

  String _status(double score) {
    if (score >= 85) return 'Excelente';
    if (score >= 70) return 'Controlado';
    if (score >= 55) return 'Atenção';
    return 'Crítico';
  }

  String _recommendation(AtlasDigitalTwinArea area, double score) {
    if (score >= 85) {
      return 'Manter o protocolo atual e acompanhar a tendência mensal.';
    }

    switch (area) {
      case AtlasDigitalTwinArea.animal:
        return 'Revisar ganho médio diário, lotes e estratégia nutricional.';
      case AtlasDigitalTwinArea.sanitary:
        return 'Priorizar calendário sanitário, ocorrências e animais em observação.';
      case AtlasDigitalTwinArea.reproductive:
        return 'Revisar taxa de prenhez, intervalo entre partos e manejo de matrizes.';
      case AtlasDigitalTwinArea.financial:
        return 'Reavaliar custos por cabeça, margem e despesas sem retorno mensurável.';
      case AtlasDigitalTwinArea.inventory:
        return 'Conferir estoque crítico, consumo projetado e ponto de reposição.';
      case AtlasDigitalTwinArea.operational:
        return 'Organizar responsáveis, prazos e tarefas operacionais vencidas.';
    }
  }

  String _simulationRecommendation(
    AtlasDigitalTwinArea area,
    double scoreVariation,
    double financialImpact,
  ) {
    if (scoreVariation <= 0) {
      return 'O cenário não melhora o desempenho geral. Revise a premissa antes de executar.';
    }
    if (financialImpact < 0) {
      return 'Há ganho operacional, mas o impacto financeiro é negativo. Faça uma implantação gradual.';
    }
    return 'O cenário é favorável. Inicie um projeto-piloto em ${atlasDigitalTwinAreaLabel(area)} e acompanhe os indicadores semanalmente.';
  }
}
