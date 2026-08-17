import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/predictive/domain/models/atlas_predictive_scenario.dart';

class AtlasAiFarmContext {
  const AtlasAiFarmContext({
    required this.generatedAt,
    required this.farmName,
    required this.score,
    required this.level,
    required this.executiveSummary,
    required this.simpleSummary,
    required this.mainPriority,
    required this.areaContexts,
    required this.risks,
    required this.bottlenecks,
    required this.opportunities,
    required this.strengths,
    required this.shortTermActions,
    required this.mediumTermActions,
    required this.longTermActions,
    required this.predictiveScenarios,
    required this.suggestedQuestions,
  });

  final DateTime generatedAt;
  final String farmName;

  final double score;
  final AtlasDiagnosticLevel level;

  final String executiveSummary;
  final String simpleSummary;

  final AtlasAiPriorityContext mainPriority;

  final List<AtlasAiAreaContext> areaContexts;
  final List<AtlasAiInsightContext> risks;
  final List<AtlasAiInsightContext> bottlenecks;
  final List<AtlasAiInsightContext> opportunities;
  final List<AtlasAiInsightContext> strengths;

  final List<AtlasAiActionContext> shortTermActions;
  final List<AtlasAiActionContext> mediumTermActions;
  final List<AtlasAiActionContext> longTermActions;

  final List<AtlasAiPredictiveContext> predictiveScenarios;

  final List<String> suggestedQuestions;

  bool get hasPredictiveScenarios {
    return predictiveScenarios.isNotEmpty;
  }

  bool get hasCriticalRisk {
    return risks.any((item) {
      return item.level == AtlasDiagnosticLevel.critical;
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'farmName': farmName,
      'score': score,
      'level': level.name,
      'executiveSummary': executiveSummary,
      'simpleSummary': simpleSummary,
      'mainPriority': mainPriority.toJson(),
      'areaContexts': areaContexts.map((item) {
        return item.toJson();
      }).toList(),
      'risks': risks.map((item) {
        return item.toJson();
      }).toList(),
      'bottlenecks': bottlenecks.map((item) {
        return item.toJson();
      }).toList(),
      'opportunities': opportunities.map((item) {
        return item.toJson();
      }).toList(),
      'strengths': strengths.map((item) {
        return item.toJson();
      }).toList(),
      'shortTermActions': shortTermActions.map((item) {
        return item.toJson();
      }).toList(),
      'mediumTermActions': mediumTermActions.map((item) {
        return item.toJson();
      }).toList(),
      'longTermActions': longTermActions.map((item) {
        return item.toJson();
      }).toList(),
      'predictiveScenarios': predictiveScenarios.map((item) {
        return item.toJson();
      }).toList(),
      'suggestedQuestions': suggestedQuestions,
    };
  }

  String toStructuredText() {
    final buffer = StringBuffer();

    buffer.writeln('FAZENDA: $farmName');
    buffer.writeln('SCORE: ${score.toStringAsFixed(0)}/100');
    buffer.writeln('NÍVEL: ${atlasDiagnosticLevelLabel(level)}');
    buffer.writeln();
    buffer.writeln('RESUMO EXECUTIVO');
    buffer.writeln(executiveSummary);
    buffer.writeln();
    buffer.writeln('PRIORIDADE PRINCIPAL');
    buffer.writeln(mainPriority.title);
    buffer.writeln(mainPriority.description);
    buffer.writeln('RECOMENDAÇÃO: ${mainPriority.recommendation}');
    buffer.writeln();

    if (areaContexts.isNotEmpty) {
      buffer.writeln('ÁREAS');
      for (final area in areaContexts) {
        buffer.writeln(
          '- ${area.title}: '
          '${area.score.toStringAsFixed(0)}/100. '
          '${area.analysis} '
          'Recomendação: ${area.recommendation}',
        );
      }
      buffer.writeln();
    }

    _writeInsights(buffer: buffer, title: 'RISCOS', items: risks);

    _writeInsights(buffer: buffer, title: 'GARGALOS', items: bottlenecks);

    _writeInsights(
      buffer: buffer,
      title: 'OPORTUNIDADES',
      items: opportunities,
    );

    _writeActions(
      buffer: buffer,
      title: 'PLANO DE 7 DIAS',
      items: shortTermActions,
    );

    _writeActions(
      buffer: buffer,
      title: 'PLANO DE 30 DIAS',
      items: mediumTermActions,
    );

    _writeActions(
      buffer: buffer,
      title: 'PLANO DE 90 DIAS',
      items: longTermActions,
    );

    if (predictiveScenarios.isNotEmpty) {
      buffer.writeln('CENÁRIOS PREDITIVOS');

      for (final item in predictiveScenarios) {
        buffer.writeln(
          '- ${item.title}: '
          'score projetado ${item.projectedScore.toStringAsFixed(0)}, '
          'variação ${item.scoreVariation >= 0 ? '+' : ''}'
          '${item.scoreVariation.toStringAsFixed(1)}, '
          'redução de risco '
          '${item.riskReductionPercent.toStringAsFixed(0)}%, '
          'confiança ${item.confidence.toStringAsFixed(0)}%.',
        );
      }

      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  static void _writeInsights({
    required StringBuffer buffer,
    required String title,
    required List<AtlasAiInsightContext> items,
  }) {
    if (items.isEmpty) {
      return;
    }

    buffer.writeln(title);

    for (final item in items) {
      buffer.writeln(
        '- ${item.title}: ${item.description} '
        'Recomendação: ${item.recommendation}',
      );
    }

    buffer.writeln();
  }

  static void _writeActions({
    required StringBuffer buffer,
    required String title,
    required List<AtlasAiActionContext> items,
  }) {
    if (items.isEmpty) {
      return;
    }

    buffer.writeln(title);

    for (final item in items) {
      buffer.writeln(
        '${item.position}. ${item.title}: '
        '${item.description} '
        'Resultado esperado: ${item.expectedResult}',
      );
    }

    buffer.writeln();
  }
}

class AtlasAiPriorityContext {
  const AtlasAiPriorityContext({
    required this.title,
    required this.description,
    required this.recommendation,
    required this.area,
    required this.level,
    required this.score,
  });

  final String title;
  final String description;
  final String recommendation;

  final AtlasFarmAnalysisArea area;
  final AtlasDiagnosticLevel level;

  final double score;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'area': area.name,
      'level': level.name,
      'score': score,
    };
  }
}

class AtlasAiAreaContext {
  const AtlasAiAreaContext({
    required this.title,
    required this.area,
    required this.score,
    required this.level,
    required this.analysis,
    required this.recommendation,
  });

  final String title;
  final AtlasFarmAnalysisArea area;

  final double score;
  final AtlasDiagnosticLevel level;

  final String analysis;
  final String recommendation;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'area': area.name,
      'score': score,
      'level': level.name,
      'analysis': analysis,
      'recommendation': recommendation,
    };
  }
}

class AtlasAiInsightContext {
  const AtlasAiInsightContext({
    required this.title,
    required this.description,
    required this.recommendation,
    required this.area,
    required this.level,
    required this.impactScore,
  });

  final String title;
  final String description;
  final String recommendation;

  final AtlasFarmAnalysisArea area;
  final AtlasDiagnosticLevel level;

  final double impactScore;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'area': area.name,
      'level': level.name,
      'impactScore': impactScore,
    };
  }
}

class AtlasAiActionContext {
  const AtlasAiActionContext({
    required this.position,
    required this.title,
    required this.description,
    required this.expectedResult,
    required this.area,
    required this.horizon,
    required this.level,
  });

  final int position;

  final String title;
  final String description;
  final String expectedResult;

  final AtlasFarmAnalysisArea area;
  final AtlasDiagnosticHorizon horizon;
  final AtlasDiagnosticLevel level;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'title': title,
      'description': description,
      'expectedResult': expectedResult,
      'area': area.name,
      'horizon': horizon.name,
      'level': level.name,
    };
  }
}

class AtlasAiPredictiveContext {
  const AtlasAiPredictiveContext({
    required this.title,
    required this.description,
    required this.type,
    required this.projectedScore,
    required this.scoreVariation,
    required this.financialImpact,
    required this.riskReductionPercent,
    required this.confidence,
    required this.effort,
    required this.recommendation,
  });

  final String title;
  final String description;

  final AtlasPredictiveScenarioType type;

  final double projectedScore;
  final double scoreVariation;
  final double financialImpact;
  final double riskReductionPercent;
  final double confidence;

  final AtlasPredictiveEffort effort;

  final String recommendation;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'projectedScore': projectedScore,
      'scoreVariation': scoreVariation,
      'financialImpact': financialImpact,
      'riskReductionPercent': riskReductionPercent,
      'confidence': confidence,
      'effort': effort.name,
      'recommendation': recommendation,
    };
  }
}
