import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_reproductive_ai/domain/models/atlas_reproductive_prediction_case.dart';
import 'package:projeto_atlas/features/atlas_reproductive_ai/domain/services/atlas_reproductive_ai_engine.dart';

void main() {
  const engine = AtlasReproductiveAiEngine();

  AtlasReproductivePredictionCase buildCase({
    double bodyConditionScore = 3.25,
    int daysPostpartum = 60,
    int serviceCount = 1,
    bool cycleRegular = true,
    bool heatSigns = true,
    String healthRisk = 'Baixo',
    String semenQuality = 'Alta',
  }) {
    return AtlasReproductivePredictionCase(
      id: '1',
      date: '04/08/2026',
      title: 'Teste',
      status: 'Servida',
      category: 'Matriz',
      bodyConditionScore: bodyConditionScore,
      daysPostpartum: daysPostpartum,
      daysSinceLastService: 0,
      serviceCount: serviceCount,
      cycleRegular: cycleRegular,
      heatSigns: heatSigns,
      previousPregnancyLoss: false,
      protocolType: 'IATF',
      semenQuality: semenQuality,
      technicianExperience: 'Alta',
      healthRisk: healthRisk,
      notes: '',
      responsible: '',
      createdAt: '',
      updatedAt: '',
    );
  }

  test('produces favorable reproductive prediction', () {
    final result = engine.predict(buildCase());

    expect(result.iatfSuccessProbabilityPercent, greaterThanOrEqualTo(60));
    expect(result.expectedCalvingDate, isNotNull);
    expect(result.confidencePercent, inInclusiveRange(0, 100));
  });

  test('reduces prediction for risk scenario', () {
    final favorable = engine.predict(buildCase());
    final risky = engine.predict(
      buildCase(
        bodyConditionScore: 2.0,
        daysPostpartum: 20,
        serviceCount: 4,
        cycleRegular: false,
        heatSigns: false,
        healthRisk: 'Alto',
        semenQuality: 'Baixa',
      ),
    );

    expect(
      risky.pregnancyProbabilityPercent,
      lessThan(favorable.pregnancyProbabilityPercent),
    );
    expect(risky.riskFactors, isNotEmpty);
  });
}
