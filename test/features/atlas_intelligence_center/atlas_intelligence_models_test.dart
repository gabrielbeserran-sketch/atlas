import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_intelligence_center/domain/models/atlas_intelligence_models.dart';

void main() {
  test('converte recomendação auditável', () {
    final item = AtlasAiRecommendation.fromMap({
      'id': 'rec-1',
      'area': 'health',
      'title': 'Revisar calendário',
      'confidence': 0.8,
      'priority': 'high',
      'evidence': ['sem eventos recentes'],
      'limitations': ['dados incompletos'],
    });
    expect(item.id, 'rec-1');
    expect(item.confidence, 0.8);
    expect(item.evidence, isNotEmpty);
    expect(item.limitations, isNotEmpty);
  });

  test('converte simulação empresarial', () {
    final result = AtlasAiSimulation.fromMap({
      'projected_variation': 12000,
      'roi_percent': 40,
      'confidence': 0.7,
    });
    expect(result.projectedVariation, 12000);
    expect(result.roiPercent, 40);
  });

  test('traduz evidência operacional estruturada para leitura humana', () {
    final item = AtlasAiRecommendation.fromMap({
      'id': 'rec-2',
      'area': 'general',
      'title': 'Acompanhar operação',
      'confidence': 0.72,
      'priority': 'low',
      'evidence': [
        {
          'herd': {'active_animals': 4, 'females': 3},
          'health': {'events': 2},
          'quality': {'weight_coverage_percent': 100, 'animal_count': 4},
        },
      ],
    });

    expect(item.evidence.single, contains('Rebanho ativo: 4'));
    expect(item.evidence.single, contains('Eventos sanitários: 2'));
    expect(item.evidence.single, contains('Cobertura de pesagem: 100%'));
  });
}
