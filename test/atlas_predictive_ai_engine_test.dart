import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_predictive_ai_suite/domain/models/atlas_predictive_ai_record.dart';
import 'package:projeto_atlas/features/atlas_predictive_ai_suite/domain/services/atlas_predictive_ai_engine.dart';

void main() {
  const engine = AtlasPredictiveAiEngine();

  AtlasPredictiveAiRecord buildRecord(
    AtlasPredictiveAiModule module, {
    double primary = 0,
    double secondary = 0,
    double tertiary = 0,
    double cost = 0,
    double revenue = 0,
    int periodDays = 90,
  }) {
    return AtlasPredictiveAiRecord(
      id: '1',
      module: module,
      feature: module.features.first,
      title: 'Teste',
      date: '04/08/2026',
      status: 'Ativo',
      primaryInput: primary,
      secondaryInput: secondary,
      tertiaryInput: tertiary,
      costValue: cost,
      revenueValue: revenue,
      periodDays: periodDays,
      referenceName: 'Referência',
      unit: '',
      notes: '',
      createdAt: '',
      updatedAt: '',
    );
  }

  test('calculates nutritional projection', () {
    final result = engine.evaluate(
      buildRecord(
        AtlasPredictiveAiModule.nutrition,
        primary: 400,
        secondary: 1.0,
        tertiary: 10,
        cost: 8,
        periodDays: 30,
      ),
    );

    expect(result.primaryProjection, greaterThan(0));
    expect(result.score, inInclusiveRange(0, 100));
  });

  test('calculates economic ROI', () {
    final result = engine.evaluate(
      buildRecord(
        AtlasPredictiveAiModule.economics,
        primary: 10000,
        cost: 2000,
        revenue: 3500,
        periodDays: 365,
      ),
    );

    expect(result.secondaryProjection, isNot(equals(0)));
    expect(result.confidencePercent, inInclusiveRange(0, 100));
  });

  test('calculates commercialization revenue', () {
    final result = engine.evaluate(
      buildRecord(
        AtlasPredictiveAiModule.commercialization,
        primary: 500,
        secondary: 52,
        tertiary: 300,
        cost: 500,
      ),
    );

    expect(result.primaryProjection, greaterThan(0));
    expect(result.secondaryProjection, greaterThan(0));
  });
}
