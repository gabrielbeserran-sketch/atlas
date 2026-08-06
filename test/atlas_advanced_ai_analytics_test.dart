import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_advanced_ai/domain/models/atlas_advanced_ai_record.dart';
import 'package:projeto_atlas/features/atlas_advanced_ai/domain/services/atlas_advanced_ai_analytics_service.dart';

void main() {
  const service = AtlasAdvancedAiAnalyticsService();

  test('calculates advanced AI analytics', () {
    final records = [
      AtlasAdvancedAiRecord(
        id: '1',
        module: AtlasAdvancedAiModule.explainableAi,
        feature: 'Motivos da recomendação',
        title: 'Recomendação explicada',
        date: '04/08/2026',
        status: 'Validado',
        responsible: 'Gestor',
        contextScope: 'Fazenda A',
        promptSummary: 'Analisar prioridade',
        recommendation: 'Executar ação',
        evidence: 'Histórico e indicadores',
        confidencePercent: 90,
        riskPercent: 20,
        estimatedImpact: 50000,
        priority: 5,
        progressPercent: 100,
        alertCount: 0,
        reviewDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasAdvancedAiRecord(
        id: '2',
        module: AtlasAdvancedAiModule.explainableAi,
        feature: 'Limitações do modelo',
        title: 'Revisão pendente',
        date: '04/08/2026',
        status: 'Atenção',
        responsible: '',
        contextScope: '',
        promptSummary: '',
        recommendation: '',
        evidence: '',
        confidencePercent: 50,
        riskPercent: 70,
        estimatedImpact: 10000,
        priority: 4,
        progressPercent: 50,
        alertCount: 1,
        reviewDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasAdvancedAiModule.explainableAi,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.validatedCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalEstimatedImpact, 60000);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
