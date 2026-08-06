import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_environmental_ai/domain/models/atlas_environmental_ai_record.dart';
import 'package:projeto_atlas/features/atlas_environmental_ai/domain/services/atlas_environmental_ai_engine.dart';

void main() {
  const engine = AtlasEnvironmentalAiEngine();

  AtlasEnvironmentalAiRecord buildRecord(
    AtlasEnvironmentalAiModule module, {
    double temperature = 0,
    double rainfall = 0,
    double humidity = 0,
    double primary = 0,
    double secondary = 0,
    double area = 10,
    double stocking = 1,
  }) {
    return AtlasEnvironmentalAiRecord(
      id: '1',
      module: module,
      feature: module.features.first,
      title: 'Teste',
      date: '04/08/2026',
      status: 'Monitorado',
      temperatureCelsius: temperature,
      rainfallMillimeters: rainfall,
      humidityPercent: humidity,
      primaryValue: primary,
      secondaryValue: secondary,
      areaHectares: area,
      stockingRateUaHa: stocking,
      referenceName: 'Referência',
      unit: '',
      notes: '',
      createdAt: '',
      updatedAt: '',
    );
  }

  test('detects climatic stress', () {
    final result = engine.evaluate(
      buildRecord(
        AtlasEnvironmentalAiModule.climate,
        temperature: 38,
        rainfall: 5,
        humidity: 90,
      ),
    );

    expect(result.riskLevel, isNot('Baixo'));
    expect(result.recommendations, isNotEmpty);
  });

  test('calculates ideal stocking rate', () {
    final result = engine.evaluate(
      buildRecord(
        AtlasEnvironmentalAiModule.pasture,
        primary: 20,
        secondary: 5000,
        stocking: 1,
      ),
    );

    expect(result.primaryProjection, greaterThan(0));
    expect(result.score, inInclusiveRange(0, 100));
  });

  test('evaluates satellite indicators', () {
    final result = engine.evaluate(
      buildRecord(
        AtlasEnvironmentalAiModule.satellite,
        primary: 0.7,
        secondary: 55,
      ),
    );

    expect(result.primaryProjection, greaterThan(0));
    expect(result.confidencePercent, inInclusiveRange(0, 100));
  });
}
