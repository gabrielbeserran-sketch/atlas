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
}
