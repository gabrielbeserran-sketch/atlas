import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_advanced_ai/domain/models/atlas_advanced_ai_record.dart';

class AtlasAdvancedAiAnalytics {
  const AtlasAdvancedAiAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.validatedCount,
    required this.pendingCount,
    required this.alertCount,
    required this.averageConfidence,
    required this.averageRisk,
    required this.totalEstimatedImpact,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int validatedCount;
  final int pendingCount;
  final int alertCount;
  final double averageConfidence;
  final double averageRisk;
  final double totalEstimatedImpact;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasAdvancedAiAnalyticsService {
  const AtlasAdvancedAiAnalyticsService();

  AtlasAdvancedAiAnalytics analyze({
    required AtlasAdvancedAiModule module,
    required List<AtlasAdvancedAiRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((feature) => feature.trim().isNotEmpty)
        .toSet();

    final double coveragePercent = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final validatedCount = moduleRecords
        .where((record) => record.isOperational)
        .length;

    final pendingCount = moduleRecords.where((record) {
      return !record.isOperational && !record.isCritical;
    }).length;

    final alertCount = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isReviewOverdue ? 1 : 0),
    );

    final double averageConfidence = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.confidencePercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    final double averageRisk = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.riskPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    final totalEstimatedImpact = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.estimatedImpact,
    );

    final double averageProgress = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                .map((record) => record.progressPercent)
                .reduce((a, b) => a + b) /
            moduleRecords.length;

    var score = 30;
    score += math.min(25, coveragePercent.round() * 25 ~/ 100);
    score += math.min(20, validatedCount * 4);
    score += math.min(15, averageConfidence.round() * 15 ~/ 100);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(25, alertCount * 5);
    score -= math.min(15, averageRisk.round() * 15 ~/ 100);
    score = score.clamp(0, 100).toInt();

    return AtlasAdvancedAiAnalytics(
      coveragePercent: coveragePercent,
      recordCount: moduleRecords.length,
      validatedCount: validatedCount,
      pendingCount: pendingCount,
      alertCount: alertCount,
      averageConfidence: averageConfidence,
      averageRisk: averageRisk,
      totalEstimatedImpact: totalEstimatedImpact,
      averageProgress: averageProgress,
      score: score,
      recommendations: _recommendations(
        module: module,
        records: moduleRecords,
        represented: represented,
        alerts: alertCount,
      ),
    );
  }

  List<String> _recommendations({
    required AtlasAdvancedAiModule module,
    required List<AtlasAdvancedAiRecord> records,
    required Set<String> represented,
    required int alerts,
  }) {
    final items = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        items.add('Implantar ou registrar: $feature.');
      }
    }

    if (alerts > 0) {
      items.add(
        'Existem $alerts alertas, revisões vencidas ou situações de baixa confiança.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
      return items;
    }

    items.addAll(
      switch (module) {
        AtlasAdvancedAiModule.conversationalAssistant => const [
            'Mantenha registro do contexto, da pergunta e da ação sugerida.',
            'Não execute ações críticas sem confirmação explícita.',
          ],
        AtlasAdvancedAiModule.farmContextChat => const [
            'Separe contexto da empresa, fazenda, lote e animal.',
            'Mostre as fontes usadas para cada resposta relevante.',
          ],
        AtlasAdvancedAiModule.healthDecisionSupport => const [
            'Use o módulo apenas como apoio de triagem.',
            'Diagnóstico e tratamento exigem avaliação veterinária.',
          ],
        AtlasAdvancedAiModule.reproductiveIntelligence => const [
            'Valide dados de ciclo, histórico e exame antes da recomendação.',
            'Protocolos devem ser aprovados pelo responsável técnico.',
          ],
        AtlasAdvancedAiModule.nutritionalIntelligence => const [
            'Considere peso, categoria, consumo, alimento e objetivo produtivo.',
            'Ajustes de dieta exigem validação profissional.',
          ],
        AtlasAdvancedAiModule.geneticIntelligence => const [
            'Documente objetivos de seleção e qualidade dos dados genealógicos.',
            'Revise risco de consanguinidade antes do acasalamento.',
          ],
        AtlasAdvancedAiModule.financialIntelligence => const [
            'Separe fatos, premissas e projeções.',
            'Valide recomendações com registros financeiros confiáveis.',
          ],
        AtlasAdvancedAiModule.strategicIntelligence => const [
            'Conecte cada recomendação a objetivo, responsável e prazo.',
            'Revise o plano quando as premissas mudarem.',
          ],
        AtlasAdvancedAiModule.climateIntelligence => const [
            'Registre fonte, horário e validade do dado meteorológico.',
            'Não confunda previsão com garantia operacional.',
          ],
        AtlasAdvancedAiModule.explainableAi => const [
            'Mostre motivos, evidências, limitações e incertezas.',
            'Mantenha revisão humana para decisões de alto impacto.',
          ],
      },
    );

    return items;
  }
}
