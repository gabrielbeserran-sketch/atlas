import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_farm_context.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/predictive/domain/models/atlas_predictive_scenario.dart';

class AtlasAiContextService {
  const AtlasAiContextService();

  AtlasAiFarmContext buildFarmContext({
    required AtlasFarmIntelligenceData intelligence,
    required AtlasDiagnosticData diagnostic,
    AtlasPredictiveScenarioRanking? predictiveRanking,
    DateTime? now,
  }) {
    final predictive = predictiveRanking?.results ?? const [];

    return AtlasAiFarmContext(
      generatedAt: now ?? DateTime.now(),
      farmName: diagnostic.scopeLabel,
      score: diagnostic.score,
      level: diagnostic.level,
      executiveSummary: _buildExecutiveSummary(
        diagnostic: diagnostic,
        predictiveRanking: predictiveRanking,
      ),
      simpleSummary: _buildSimpleSummary(diagnostic: diagnostic),
      mainPriority: AtlasAiPriorityContext(
        title: diagnostic.mainPriority.title,
        description: diagnostic.mainPriority.description,
        recommendation: diagnostic.mainPriority.recommendation,
        area: diagnostic.mainPriority.area,
        level: diagnostic.mainPriority.level,
        score: diagnostic.mainPriority.score,
      ),
      areaContexts: diagnostic.areas.map((item) {
        return AtlasAiAreaContext(
          title: item.title,
          area: item.sourceArea,
          score: item.score,
          level: item.level,
          analysis: item.analysis,
          recommendation: item.recommendation,
        );
      }).toList(),
      risks: _mapInsights(diagnostic.risks),
      bottlenecks: _mapInsights(diagnostic.bottlenecks),
      opportunities: _mapInsights(diagnostic.opportunities),
      strengths: _mapInsights(diagnostic.strengths),
      shortTermActions: _mapActions(diagnostic.plan7Days),
      mediumTermActions: _mapActions(diagnostic.plan30Days),
      longTermActions: _mapActions(diagnostic.plan90Days),
      predictiveScenarios: predictive.map((item) {
        return AtlasAiPredictiveContext(
          title: item.request.title,
          description: item.request.description,
          type: item.request.type,
          projectedScore: item.projectedScore,
          scoreVariation: item.scoreVariation,
          financialImpact: item.financialImpact.probableValue,
          riskReductionPercent: item.riskReductionPercent,
          confidence: item.confidence,
          effort: item.effort,
          recommendation: item.recommendation,
        );
      }).toList(),
      suggestedQuestions: _buildSuggestedQuestions(
        intelligence: intelligence,
        diagnostic: diagnostic,
        predictiveRanking: predictiveRanking,
      ),
    );
  }

  List<AtlasAiInsightContext> _mapInsights(
    List<AtlasDiagnosticInsight> source,
  ) {
    return source.map((item) {
      return AtlasAiInsightContext(
        title: item.title,
        description: item.description,
        recommendation: item.recommendation,
        area: item.area,
        level: item.level,
        impactScore: item.impactScore,
      );
    }).toList();
  }

  List<AtlasAiActionContext> _mapActions(List<AtlasDiagnosticAction> source) {
    return source.map((item) {
      return AtlasAiActionContext(
        position: item.position,
        title: item.title,
        description: item.description,
        expectedResult: item.expectedResult,
        area: item.area,
        horizon: item.horizon,
        level: item.level,
      );
    }).toList();
  }

  String _buildExecutiveSummary({
    required AtlasDiagnosticData diagnostic,
    required AtlasPredictiveScenarioRanking? predictiveRanking,
  }) {
    final buffer = StringBuffer();

    buffer.write(diagnostic.summary);

    if (diagnostic.risks.isNotEmpty) {
      buffer.write(
        ' Foram identificados ${diagnostic.risks.length} '
        '${diagnostic.risks.length == 1 ? 'risco' : 'riscos'} '
        'e ${diagnostic.bottlenecks.length} '
        '${diagnostic.bottlenecks.length == 1 ? 'gargalo' : 'gargalos'}.',
      );
    }

    final best = predictiveRanking?.bestScenario;

    if (best != null) {
      buffer.write(
        ' Entre os cenários simulados, a melhor decisão é '
        '"${best.request.title}", com projeção de '
        '${best.scoreVariation >= 0 ? '+' : ''}'
        '${best.scoreVariation.toStringAsFixed(1)} pontos no score.',
      );
    }

    return buffer.toString().trim();
  }

  String _buildSimpleSummary({required AtlasDiagnosticData diagnostic}) {
    final level = atlasDiagnosticLevelLabel(diagnostic.level).toLowerCase();

    final buffer = StringBuffer();

    buffer.write(
      'A fazenda está em situação $level, com '
      '${diagnostic.score.toStringAsFixed(0)} pontos de 100. ',
    );

    buffer.write(
      'O assunto mais importante agora é '
      '${diagnostic.mainPriority.title.toLowerCase()}. ',
    );

    buffer.write(
      'A primeira ação recomendada é '
      '${diagnostic.mainPriority.recommendation}',
    );

    return buffer.toString();
  }

  List<String> _buildSuggestedQuestions({
    required AtlasFarmIntelligenceData intelligence,
    required AtlasDiagnosticData diagnostic,
    required AtlasPredictiveScenarioRanking? predictiveRanking,
  }) {
    final questions = <String>[
      'Qual é o maior problema da fazenda hoje?',
      'O que devo priorizar nos próximos 7 dias?',
      'Explique o diagnóstico em linguagem simples.',
      'Quais riscos podem gerar prejuízo?',
      'Quais pontos fortes devem ser preservados?',
    ];

    if (intelligence.finance.balance < 0) {
      questions.add('Por que o resultado financeiro está negativo?');
    } else {
      questions.add('Como posso melhorar ainda mais o resultado financeiro?');
    }

    if (intelligence.agenda.overdueCount > 0) {
      questions.add('Quais atrasos precisam ser resolvidos primeiro?');
    }

    if (intelligence.inventory.expiredCount > 0 ||
        intelligence.inventory.nearExpirationCount > 0) {
      questions.add('Como reduzir as perdas no estoque?');
    }

    if (intelligence.herd.registrationCoverage < 95) {
      questions.add('Quais dados do rebanho precisam ser completados?');
    }

    if (predictiveRanking?.bestScenario != null) {
      questions.add(
        'Por que o cenário '
        '"${predictiveRanking!.bestScenario!.request.title}" '
        'é a melhor decisão?',
      );
    }

    final weakestAreas = [...diagnostic.areas]
      ..sort((first, second) => first.score.compareTo(second.score));

    if (weakestAreas.isNotEmpty) {
      questions.add('Como melhorar ${weakestAreas.first.title.toLowerCase()}?');
    }

    return questions.take(10).toList();
  }
}
