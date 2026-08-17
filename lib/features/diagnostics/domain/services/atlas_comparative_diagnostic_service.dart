import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_comparative_diagnostic_data.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasComparativeDiagnosticService {
  const AtlasComparativeDiagnosticService();

  AtlasComparativeDiagnosticData buildComparison({
    required List<AtlasDiagnosticData> diagnostics,
    DateTime? now,
  }) {
    final validDiagnostics = diagnostics.where((item) {
      return item.scopeLabel.trim().isNotEmpty;
    }).toList();

    if (validDiagnostics.isEmpty) {
      return AtlasComparativeDiagnosticData(
        generatedAt: now ?? DateTime.now(),
        operationAverageScore: 0,
        operationLevel: AtlasDiagnosticLevel.critical,
        summary:
            'Não existem diagnósticos suficientes para comparar as fazendas.',
        ranking: const [],
        areaComparisons: const [],
        highlights: const [],
        priorities: const [],
      );
    }

    final averageScore =
        validDiagnostics.fold<double>(0, (sum, item) => sum + item.score) /
        validDiagnostics.length;

    final ranking = _buildRanking(
      diagnostics: validDiagnostics,
      averageScore: averageScore,
    );

    final areaComparisons = _buildAreaComparisons(
      diagnostics: validDiagnostics,
    );

    final highlights = _buildHighlights(
      diagnostics: validDiagnostics,
      ranking: ranking,
      areas: areaComparisons,
      averageScore: averageScore,
    );

    final priorities = _buildPriorities(
      diagnostics: validDiagnostics,
      averageScore: averageScore,
    );

    return AtlasComparativeDiagnosticData(
      generatedAt: now ?? DateTime.now(),
      operationAverageScore: averageScore,
      operationLevel: _levelFromScore(averageScore),
      summary: _buildSummary(
        diagnostics: validDiagnostics,
        ranking: ranking,
        areas: areaComparisons,
        averageScore: averageScore,
      ),
      ranking: ranking,
      areaComparisons: areaComparisons,
      highlights: highlights,
      priorities: priorities,
    );
  }

  List<AtlasComparativeFarmRanking> _buildRanking({
    required List<AtlasDiagnosticData> diagnostics,
    required double averageScore,
  }) {
    final ordered = [...diagnostics]
      ..sort((first, second) => second.score.compareTo(first.score));

    return List.generate(ordered.length, (index) {
      final item = ordered[index];

      final criticalRiskCount = item.risks.where((risk) {
        return risk.level == AtlasDiagnosticLevel.critical;
      }).length;

      return AtlasComparativeFarmRanking(
        position: index + 1,
        farmName: item.scopeLabel,
        score: item.score,
        level: item.level,
        differenceFromAverage: item.score - averageScore,
        mainPriority: item.mainPriority.title,
        criticalRiskCount: criticalRiskCount,
        bottleneckCount: item.bottlenecks.length,
        opportunityCount: item.opportunities.length,
      );
    });
  }

  List<AtlasComparativeAreaData> _buildAreaComparisons({
    required List<AtlasDiagnosticData> diagnostics,
  }) {
    final areas = <AtlasFarmAnalysisArea, List<_FarmAreaScore>>{};

    for (final diagnostic in diagnostics) {
      for (final area in diagnostic.areas) {
        areas.putIfAbsent(area.sourceArea, () => []);

        areas[area.sourceArea]!.add(
          _FarmAreaScore(
            farmName: diagnostic.scopeLabel,
            title: area.title,
            score: area.score,
          ),
        );
      }
    }

    final result = <AtlasComparativeAreaData>[];

    for (final entry in areas.entries) {
      final scores = entry.value;

      if (scores.isEmpty) {
        continue;
      }

      final ordered = [...scores]
        ..sort((first, second) => second.score.compareTo(first.score));

      final average =
          scores.fold<double>(0, (sum, item) => sum + item.score) /
          scores.length;

      final best = ordered.first;
      final worst = ordered.last;

      result.add(
        AtlasComparativeAreaData(
          area: entry.key,
          title: best.title,
          averageScore: average,
          bestFarmName: best.farmName,
          bestScore: best.score,
          worstFarmName: worst.farmName,
          worstScore: worst.score,
          amplitude: best.score - worst.score,
          level: _levelFromScore(average),
        ),
      );
    }

    result.sort(
      (first, second) => first.averageScore.compareTo(second.averageScore),
    );

    return result;
  }

  List<AtlasComparativeHighlight> _buildHighlights({
    required List<AtlasDiagnosticData> diagnostics,
    required List<AtlasComparativeFarmRanking> ranking,
    required List<AtlasComparativeAreaData> areas,
    required double averageScore,
  }) {
    final highlights = <AtlasComparativeHighlight>[];

    if (ranking.isNotEmpty) {
      final leader = ranking.first;

      highlights.add(
        AtlasComparativeHighlight(
          id: 'leader_farm',
          title: '${leader.farmName} lidera a operação',
          description:
              'A propriedade ocupa a 1ª posição com '
              '${leader.score.toStringAsFixed(0)} pontos, '
              '${leader.differenceFromAverage.abs().toStringAsFixed(0)} pontos acima da média.',
          recommendation:
              'Identifique e documente as práticas que sustentam esse resultado para replicá-las.',
          type: AtlasComparativeHighlightType.leader,
          level: AtlasDiagnosticLevel.excellent,
          farmName: leader.farmName,
          area: null,
        ),
      );

      final critical = ranking.last;

      if (critical.score < averageScore) {
        highlights.add(
          AtlasComparativeHighlight(
            id: 'critical_farm',
            title: '${critical.farmName} exige maior atenção',
            description:
                'A propriedade está '
                '${critical.differenceFromAverage.abs().toStringAsFixed(0)} pontos abaixo da média da operação.',
            recommendation:
                'Priorize o diagnóstico principal e os gargalos desta propriedade.',
            type: AtlasComparativeHighlightType.warning,
            level: critical.level,
            farmName: critical.farmName,
            area: null,
          ),
        );
      }
    }

    for (final area in areas) {
      if (area.amplitude >= 20) {
        highlights.add(
          AtlasComparativeHighlight(
            id: 'imbalance_${area.area.name}',
            title: 'Grande diferença em ${area.title.toLowerCase()}',
            description:
                '${area.bestFarmName} possui ${area.bestScore.toStringAsFixed(0)} pontos, '
                'enquanto ${area.worstFarmName} possui ${area.worstScore.toStringAsFixed(0)}.',
            recommendation:
                'Compare os processos das duas fazendas e replique as práticas da líder.',
            type: AtlasComparativeHighlightType.imbalance,
            level: AtlasDiagnosticLevel.attention,
            farmName: area.worstFarmName,
            area: area.area,
          ),
        );
      }
    }

    final opportunityDiagnostic = [...diagnostics]
      ..sort(
        (first, second) =>
            second.opportunities.length.compareTo(first.opportunities.length),
      );

    if (opportunityDiagnostic.isNotEmpty &&
        opportunityDiagnostic.first.opportunities.isNotEmpty) {
      final farm = opportunityDiagnostic.first;

      highlights.add(
        AtlasComparativeHighlight(
          id: 'opportunity_farm',
          title: '${farm.scopeLabel} concentra oportunidades',
          description:
              'Foram identificadas ${farm.opportunities.length} oportunidades de melhoria.',
          recommendation:
              'Priorize as oportunidades com maior impacto e menor esforço de execução.',
          type: AtlasComparativeHighlightType.opportunity,
          level: AtlasDiagnosticLevel.stable,
          farmName: farm.scopeLabel,
          area: null,
        ),
      );
    }

    return highlights;
  }

  List<AtlasComparativePriority> _buildPriorities({
    required List<AtlasDiagnosticData> diagnostics,
    required double averageScore,
  }) {
    final candidates = <_PriorityCandidate>[];

    for (final diagnostic in diagnostics) {
      final scoreGap = (averageScore - diagnostic.score).clamp(0.0, 100.0);

      final criticalRiskCount = diagnostic.risks.where((risk) {
        return risk.level == AtlasDiagnosticLevel.critical;
      }).length;

      final priorityScore =
          diagnostic.mainPriority.score * 0.55 +
          scoreGap * 0.25 +
          criticalRiskCount * 6 +
          diagnostic.bottlenecks.length * 3;

      candidates.add(
        _PriorityCandidate(
          farmName: diagnostic.scopeLabel,
          priority: diagnostic.mainPriority,
          score: priorityScore.clamp(0.0, 100.0),
        ),
      );
    }

    candidates.sort((first, second) => second.score.compareTo(first.score));

    return List.generate(candidates.length, (index) {
      final item = candidates[index];

      return AtlasComparativePriority(
        position: index + 1,
        farmName: item.farmName,
        title: item.priority.title,
        description: item.priority.description,
        recommendation: item.priority.recommendation,
        area: item.priority.area,
        level: item.priority.level,
        priorityScore: item.score,
      );
    });
  }

  String _buildSummary({
    required List<AtlasDiagnosticData> diagnostics,
    required List<AtlasComparativeFarmRanking> ranking,
    required List<AtlasComparativeAreaData> areas,
    required double averageScore,
  }) {
    final buffer = StringBuffer();

    buffer.write(
      'Foram comparadas ${diagnostics.length} '
      '${diagnostics.length == 1 ? 'fazenda' : 'fazendas'}. ',
    );

    buffer.write(
      'A média da operação é de '
      '${averageScore.toStringAsFixed(0)} pontos. ',
    );

    if (ranking.isNotEmpty) {
      buffer.write(
        '${ranking.first.farmName} ocupa a primeira posição com '
        '${ranking.first.score.toStringAsFixed(0)} pontos, enquanto '
        '${ranking.last.farmName} apresenta o menor score, com '
        '${ranking.last.score.toStringAsFixed(0)} pontos. ',
      );
    }

    if (areas.isNotEmpty) {
      final weakestArea = areas.first;

      buffer.write(
        'A área com menor média é '
        '${weakestArea.title.toLowerCase()}, com '
        '${weakestArea.averageScore.toStringAsFixed(0)} pontos.',
      );
    }

    return buffer.toString().trim();
  }

  AtlasDiagnosticLevel _levelFromScore(double score) {
    if (score >= 85) {
      return AtlasDiagnosticLevel.excellent;
    }

    if (score >= 70) {
      return AtlasDiagnosticLevel.stable;
    }

    if (score >= 50) {
      return AtlasDiagnosticLevel.attention;
    }

    return AtlasDiagnosticLevel.critical;
  }
}

class _FarmAreaScore {
  const _FarmAreaScore({
    required this.farmName,
    required this.title,
    required this.score,
  });

  final String farmName;
  final String title;
  final double score;
}

class _PriorityCandidate {
  const _PriorityCandidate({
    required this.farmName,
    required this.priority,
    required this.score,
  });

  final String farmName;
  final AtlasDiagnosticPriority priority;
  final double score;
}
