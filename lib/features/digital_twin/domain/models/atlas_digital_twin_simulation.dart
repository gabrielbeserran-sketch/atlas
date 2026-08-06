import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';

class AtlasDigitalTwinSimulationRequest {
  const AtlasDigitalTwinSimulationRequest({
    required this.title,
    required this.area,
    required this.changePercent,
    required this.investmentValue,
    required this.horizonDays,
  });

  final String title;
  final AtlasDigitalTwinArea area;
  final double changePercent;
  final double investmentValue;
  final int horizonDays;
}

class AtlasDigitalTwinSimulationResult {
  const AtlasDigitalTwinSimulationResult({
    required this.request,
    required this.currentScore,
    required this.projectedScore,
    required this.scoreVariation,
    required this.projectedFinancialImpact,
    required this.riskReductionPercent,
    required this.confidencePercent,
    required this.recommendation,
    required this.generatedAt,
  });

  final AtlasDigitalTwinSimulationRequest request;
  final double currentScore;
  final double projectedScore;
  final double scoreVariation;
  final double projectedFinancialImpact;
  final double riskReductionPercent;
  final double confidencePercent;
  final String recommendation;
  final DateTime generatedAt;
}

class AtlasDigitalTwinAreaInsight {
  const AtlasDigitalTwinAreaInsight({
    required this.area,
    required this.score,
    required this.status,
    required this.recommendation,
  });

  final AtlasDigitalTwinArea area;
  final double score;
  final String status;
  final String recommendation;
}
