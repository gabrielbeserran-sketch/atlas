import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';

class AtlasDigitalTwinScoreService {
  const AtlasDigitalTwinScoreService();

  double calculateOverall(
    AtlasFarmHealth health,
  ) {
    final weighted =
        health.animal * 0.18 +
        health.sanitary * 0.20 +
        health.reproductive * 0.17 +
        health.financial * 0.18 +
        health.inventory * 0.12 +
        health.operational * 0.15;

    return _bounded(weighted);
  }

  AtlasDigitalTwinTrend calculateTrend({
    required double previousScore,
    required double currentScore,
  }) {
    final variation =
        currentScore - previousScore;

    if (variation >= 0.8) {
      return AtlasDigitalTwinTrend.improving;
    }

    if (variation <= -0.8) {
      return AtlasDigitalTwinTrend.worsening;
    }

    return AtlasDigitalTwinTrend.stable;
  }

  double apply(
    double current,
    double variation,
  ) {
    return _bounded(current + variation);
  }

  double _bounded(double value) {
    return value.clamp(0.0, 100.0).toDouble();
  }
}
