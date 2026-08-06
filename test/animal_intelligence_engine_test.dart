import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_intelligence_360/domain/services/animal_intelligence_engine.dart';

void main() {
  group('AnimalIntelligenceEngine', () {
    test('calcula GMD com datas válidas', () {
      final gmd = AnimalIntelligenceEngine.calculateGmd(
        firstWeight: 300,
        lastWeight: 330,
        firstDate: DateTime(2026, 1, 1),
        lastDate: DateTime(2026, 1, 31),
      );
      expect(gmd, 1);
    });

    test('não calcula GMD sem intervalo positivo', () {
      final gmd = AnimalIntelligenceEngine.calculateGmd(
        firstWeight: 300,
        lastWeight: 330,
        firstDate: DateTime(2026, 1, 1),
        lastDate: DateTime(2026, 1, 1),
      );
      expect(gmd, isNull);
    });

    test('score permanece entre zero e cem', () {
      final score = AnimalIntelligenceEngine.score360(
        weightCount: 10,
        healthCount: 10,
        reproductionCount: 10,
        nutritionCount: 10,
        documentCount: 10,
        photoCount: 10,
        movementCount: 10,
        gmd: 1,
        bodyConditionScore: 3,
        criticalAlerts: 0,
      );
      expect(score, inInclusiveRange(0, 100));
    });

    test('projeção usa o GMD', () {
      final projected = AnimalIntelligenceEngine.projectWeight(
        currentWeight: 400,
        gmd: 1,
        days: 30,
      );
      expect(projected, 430);
    });
  });
}
