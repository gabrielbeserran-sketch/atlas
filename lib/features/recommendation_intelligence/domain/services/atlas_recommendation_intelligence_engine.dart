import 'dart:math' as math;

import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/knowledge_learning/domain/models/atlas_knowledge_case.dart';
import 'package:projeto_atlas/features/recommendation_intelligence/domain/models/atlas_intelligent_recommendation.dart';

class AtlasRecommendationIntelligenceEngine {
  const AtlasRecommendationIntelligenceEngine();

  AtlasRecommendationPortfolio generate({
    required AtlasFarmAudit audit,
    required List<AtlasKnowledgeCase> knowledgeCases,
  }) {
    final results = <AtlasIntelligentRecommendation>[];

    final orderedAreas = List<AtlasFarmAuditAreaResult>.from(
      audit.areaResults,
    )..sort(
        (first, second) =>
            first.score.compareTo(second.score),
      );

    for (final areaResult in orderedAreas) {
      if (areaResult.score >= 85 &&
          results.length >= 3) {
        continue;
      }

      final relatedCases = knowledgeCases
          .where(
            (item) => item.area == areaResult.area,
          )
          .toList();

      results.add(
        _buildRecommendation(
          audit: audit,
          areaResult: areaResult,
          relatedCases: relatedCases,
        ),
      );

      if (results.length >= 8) {
        break;
      }
    }

    results.sort(
      (first, second) {
        final priorityComparison =
            _priorityWeight(second.priority).compareTo(
          _priorityWeight(first.priority),
        );

        if (priorityComparison != 0) {
          return priorityComparison;
        }

        return second.confidence.compareTo(
          first.confidence,
        );
      },
    );

    return AtlasRecommendationPortfolio(
      farmId: audit.farmId,
      farmName: audit.farmName,
      generatedAt: DateTime.now(),
      auditIndex: audit.overallIndex,
      recommendations: results,
    );
  }

  AtlasIntelligentRecommendation _buildRecommendation({
    required AtlasFarmAudit audit,
    required AtlasFarmAuditAreaResult areaResult,
    required List<AtlasKnowledgeCase> relatedCases,
  }) {
    final successCases = relatedCases
        .where((item) => item.success)
        .toList();

    final successRate = relatedCases.isEmpty
        ? _baselineSuccessRate(areaResult.score)
        : successCases.length /
            relatedCases.length *
            100;

    final averageResponseDays = relatedCases.isEmpty
        ? _baselineResponseDays(areaResult.area)
        : relatedCases.fold<double>(
              0,
              (sum, item) => sum + item.responseDays,
            ) /
            relatedCases.length;

    final averageEconomicGain = relatedCases.isEmpty
        ? _baselineEconomicGain(
            areaResult.area,
            areaResult.score,
          )
        : relatedCases.fold<double>(
              0,
              (sum, item) => sum + item.economicGain,
            ) /
            relatedCases.length;

    final confidence = _confidence(
      caseCount: relatedCases.length,
      successRate: successRate,
      areaScore: areaResult.score,
    );

    final strongestCase =
        _strongestCase(relatedCases);

    final targetScore = math.max(
      areaResult.score,
      areaResult.score < 60 ? 75 : 85,
    ).toDouble();

    final priority =
        _priorityFromScore(areaResult.score);

    return AtlasIntelligentRecommendation(
      id:
          'recommendation_${audit.id}_${areaResult.area.name}',
      farmId: audit.farmId,
      farmName: audit.farmName,
      generatedAt: DateTime.now(),
      area: areaResult.area,
      title:
          'Melhorar ${atlasFarmAuditAreaLabel(areaResult.area)}',
      diagnosis: areaResult.summary,
      recommendedProtocol: _protocolTitle(
        areaResult.area,
      ),
      justification: strongestCase == null
          ? 'A recomendação foi construída a partir da auditoria atual e das regras técnicas do Atlas. A confiança aumentará conforme novos casos forem concluídos.'
          : 'A recomendação considera ${relatedCases.length} caso(s) semelhante(s). O caso de maior referência apresentou melhora de ${strongestCase.improvement.toStringAsFixed(1)} pontos.',
      priority: priority,
      confidence: confidence,
      similarCases: relatedCases.length,
      successRate: successRate,
      averageResponseDays: averageResponseDays,
      expectedEconomicGain: averageEconomicGain,
      currentScore: areaResult.score,
      targetScore: targetScore,
      steps: _stepsForArea(areaResult.area),
      risks: _risksForArea(areaResult.area),
      evidence: _buildEvidence(
        relatedCases: relatedCases,
        strongestCase: strongestCase,
        successRate: successRate,
      ),
    );
  }

  AtlasKnowledgeCase? _strongestCase(
    List<AtlasKnowledgeCase> cases,
  ) {
    if (cases.isEmpty) {
      return null;
    }

    final ordered = List<AtlasKnowledgeCase>.from(
      cases,
    )..sort(
        (first, second) {
          final firstScore =
              first.improvement + first.economicGain / 10000;
          final secondScore =
              second.improvement + second.economicGain / 10000;

          return secondScore.compareTo(firstScore);
        },
      );

    return ordered.first;
  }

  List<String> _buildEvidence({
    required List<AtlasKnowledgeCase> relatedCases,
    required AtlasKnowledgeCase? strongestCase,
    required double successRate,
  }) {
    if (relatedCases.isEmpty) {
      return <String>[
        'Ainda não existem casos históricos suficientes para esta área.',
        'Confiança inicial baseada na gravidade da auditoria e em regras técnicas.',
        'O resultado desta intervenção poderá alimentar a memória do Atlas.',
      ];
    }

    return <String>[
      '${relatedCases.length} caso(s) semelhante(s) analisado(s).',
      'Taxa histórica de sucesso de ${successRate.toStringAsFixed(1)}%.',
      if (strongestCase != null)
        'Melhor referência: ${strongestCase.farmName}, com ganho de ${strongestCase.improvement.toStringAsFixed(1)} pontos.',
      if (strongestCase != null &&
          strongestCase.lessons.isNotEmpty)
        'Lição principal: ${strongestCase.lessons.first}',
    ];
  }

  double _confidence({
    required int caseCount,
    required double successRate,
    required double areaScore,
  }) {
    final caseEvidence =
        (caseCount * 7).clamp(0, 35).toDouble();

    final successEvidence =
        (successRate * 0.35).clamp(0.0, 35.0);

    final urgencyEvidence =
        ((85 - areaScore) * 0.25)
            .clamp(0.0, 15.0);

    return (35 +
            caseEvidence +
            successEvidence +
            urgencyEvidence)
        .clamp(45.0, 98.0)
        .toDouble();
  }

  double _baselineSuccessRate(double score) {
    if (score < 45) {
      return 62;
    }

    if (score < 60) {
      return 70;
    }

    if (score < 75) {
      return 78;
    }

    return 84;
  }

  double _baselineResponseDays(
    AtlasFarmAuditArea area,
  ) {
    switch (area) {
      case AtlasFarmAuditArea.reproduction:
      case AtlasFarmAuditArea.genetics:
        return 60;
      case AtlasFarmAuditArea.pastures:
      case AtlasFarmAuditArea.sustainability:
        return 45;
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.biosecurity:
        return 30;
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.animalWelfare:
        return 35;
      case AtlasFarmAuditArea.financial:
      case AtlasFarmAuditArea.inventory:
      case AtlasFarmAuditArea.operational:
      case AtlasFarmAuditArea.people:
        return 21;
    }
  }

  double _baselineEconomicGain(
    AtlasFarmAuditArea area,
    double score,
  ) {
    final gap =
        (85 - score).clamp(0.0, 60.0).toDouble();

    switch (area) {
      case AtlasFarmAuditArea.reproduction:
        return gap * 6500;
      case AtlasFarmAuditArea.financial:
        return gap * 6000;
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.biosecurity:
        return gap * 5200;
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.pastures:
        return gap * 4800;
      case AtlasFarmAuditArea.operational:
      case AtlasFarmAuditArea.people:
        return gap * 4000;
      case AtlasFarmAuditArea.genetics:
        return gap * 3500;
      case AtlasFarmAuditArea.animalWelfare:
        return gap * 3200;
      case AtlasFarmAuditArea.inventory:
        return gap * 2800;
      case AtlasFarmAuditArea.sustainability:
        return gap * 2600;
    }
  }

  AtlasFarmAuditPriority _priorityFromScore(
    double score,
  ) {
    if (score < 45) {
      return AtlasFarmAuditPriority.critical;
    }

    if (score < 60) {
      return AtlasFarmAuditPriority.high;
    }

    if (score < 75) {
      return AtlasFarmAuditPriority.moderate;
    }

    return AtlasFarmAuditPriority.low;
  }

  int _priorityWeight(
    AtlasFarmAuditPriority priority,
  ) {
    switch (priority) {
      case AtlasFarmAuditPriority.critical:
        return 4;
      case AtlasFarmAuditPriority.high:
        return 3;
      case AtlasFarmAuditPriority.moderate:
        return 2;
      case AtlasFarmAuditPriority.low:
        return 1;
    }
  }

  String _protocolTitle(AtlasFarmAuditArea area) {
    return 'Protocolo inteligente de '
        '${atlasFarmAuditAreaLabel(area)}';
  }

  List<String> _stepsForArea(
    AtlasFarmAuditArea area,
  ) {
    switch (area) {
      case AtlasFarmAuditArea.reproduction:
        return <String>[
          'Revisar indicadores reprodutivos por lote.',
          'Verificar escore corporal, manejo e calendário reprodutivo.',
          'Definir protocolo com responsável e prazo.',
          'Medir taxa de resposta após o próximo ciclo.',
        ];
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.biosecurity:
        return <String>[
          'Revisar ocorrências, calendário sanitário e riscos de entrada.',
          'Priorizar animais e lotes mais expostos.',
          'Executar o protocolo preventivo e corretivo.',
          'Registrar incidência, resposta e custo evitado.',
        ];
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.pastures:
        return <String>[
          'Avaliar oferta, qualidade e consumo dos alimentos.',
          'Relacionar dieta, pastagem e desempenho por lote.',
          'Corrigir o principal gargalo nutricional.',
          'Acompanhar ganho, escore corporal e custo.',
        ];
      case AtlasFarmAuditArea.financial:
      case AtlasFarmAuditArea.inventory:
        return <String>[
          'Reconciliar registros, custos e estoques.',
          'Identificar perdas, desvios e capital imobilizado.',
          'Aplicar controles e responsáveis.',
          'Comparar margem e fluxo de caixa antes e depois.',
        ];
      case AtlasFarmAuditArea.operational:
      case AtlasFarmAuditArea.people:
        return <String>[
          'Mapear o processo e seus responsáveis.',
          'Eliminar etapas sem controle ou padrão.',
          'Treinar a equipe e implantar checklist.',
          'Medir prazo, aderência e retrabalho.',
        ];
      case AtlasFarmAuditArea.animalWelfare:
        return <String>[
          'Identificar fatores de desconforto e risco.',
          'Priorizar manejo, instalações e lotação.',
          'Aplicar correções com baixo estresse.',
          'Monitorar comportamento e desempenho.',
        ];
      case AtlasFarmAuditArea.genetics:
        return <String>[
          'Definir objetivos produtivos e reprodutivos.',
          'Revisar critérios de seleção e acasalamento.',
          'Aplicar o plano genético por lote.',
          'Comparar desempenho das novas gerações.',
        ];
      case AtlasFarmAuditArea.sustainability:
        return <String>[
          'Mapear uso de recursos e principais desperdícios.',
          'Priorizar intervenções de maior retorno.',
          'Executar melhorias ambientais e produtivas.',
          'Medir eficiência e economia obtida.',
        ];
    }
  }

  List<String> _risksForArea(
    AtlasFarmAuditArea area,
  ) {
    return <String>[
      'Execução incompleta ou sem responsável definido.',
      'Ausência de registros para confirmar o resultado.',
      'Mudança de protocolo sem período suficiente de avaliação.',
      'Não considerar diferenças entre lotes e categorias.',
    ];
  }
}
