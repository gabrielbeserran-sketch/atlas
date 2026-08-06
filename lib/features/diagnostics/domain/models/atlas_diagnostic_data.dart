import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasDiagnosticData {
  const AtlasDiagnosticData({
    required this.generatedAt,
    required this.scopeLabel,
    required this.score,
    required this.level,
    required this.title,
    required this.summary,
    required this.mainDiagnosis,
    required this.mainPriority,
    required this.areas,
    required this.risks,
    required this.bottlenecks,
    required this.opportunities,
    required this.strengths,
    required this.plan7Days,
    required this.plan30Days,
    required this.plan90Days,
  });

  final DateTime generatedAt;
  final String scopeLabel;

  final double score;
  final AtlasDiagnosticLevel level;

  final String title;
  final String summary;
  final String mainDiagnosis;

  final AtlasDiagnosticPriority mainPriority;

  final List<AtlasDiagnosticArea> areas;
  final List<AtlasDiagnosticInsight> risks;
  final List<AtlasDiagnosticInsight> bottlenecks;
  final List<AtlasDiagnosticInsight> opportunities;
  final List<AtlasDiagnosticInsight> strengths;

  final List<AtlasDiagnosticAction> plan7Days;
  final List<AtlasDiagnosticAction> plan30Days;
  final List<AtlasDiagnosticAction> plan90Days;

  bool get hasCriticalRisk {
    return risks.any((item) {
      return item.level ==
          AtlasDiagnosticLevel.critical;
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt':
          generatedAt.toIso8601String(),
      'scopeLabel': scopeLabel,
      'score': score,
      'level': level.name,
      'title': title,
      'summary': summary,
      'mainDiagnosis': mainDiagnosis,
      'mainPriority':
          mainPriority.toJson(),
      'areas': areas.map((item) {
        return item.toJson();
      }).toList(),
      'risks': risks.map((item) {
        return item.toJson();
      }).toList(),
      'bottlenecks':
          bottlenecks.map((item) {
        return item.toJson();
      }).toList(),
      'opportunities':
          opportunities.map((item) {
        return item.toJson();
      }).toList(),
      'strengths': strengths.map((item) {
        return item.toJson();
      }).toList(),
      'plan7Days': plan7Days.map((item) {
        return item.toJson();
      }).toList(),
      'plan30Days':
          plan30Days.map((item) {
        return item.toJson();
      }).toList(),
      'plan90Days':
          plan90Days.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class AtlasDiagnosticArea {
  const AtlasDiagnosticArea({
    required this.id,
    required this.title,
    required this.score,
    required this.level,
    required this.analysis,
    required this.recommendation,
    required this.sourceArea,
  });

  final String id;
  final String title;

  final double score;
  final AtlasDiagnosticLevel level;

  final String analysis;
  final String recommendation;

  final AtlasFarmAnalysisArea sourceArea;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'score': score,
      'level': level.name,
      'analysis': analysis,
      'recommendation':
          recommendation,
      'sourceArea': sourceArea.name,
    };
  }
}

class AtlasDiagnosticInsight {
  const AtlasDiagnosticInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.level,
    required this.area,
    required this.impactScore,
  });

  final String id;
  final String title;
  final String description;
  final String recommendation;

  final AtlasDiagnosticLevel level;
  final AtlasFarmAnalysisArea area;

  final double impactScore;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recommendation':
          recommendation,
      'level': level.name,
      'area': area.name,
      'impactScore': impactScore,
    };
  }
}

class AtlasDiagnosticPriority {
  const AtlasDiagnosticPriority({
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
      'recommendation':
          recommendation,
      'area': area.name,
      'level': level.name,
      'score': score,
    };
  }
}

class AtlasDiagnosticAction {
  const AtlasDiagnosticAction({
    required this.id,
    required this.title,
    required this.description,
    required this.expectedResult,
    required this.area,
    required this.level,
    required this.horizon,
    required this.position,
  });

  final String id;
  final String title;
  final String description;
  final String expectedResult;

  final AtlasFarmAnalysisArea area;
  final AtlasDiagnosticLevel level;
  final AtlasDiagnosticHorizon horizon;

  final int position;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'expectedResult':
          expectedResult,
      'area': area.name,
      'level': level.name,
      'horizon': horizon.name,
      'position': position,
    };
  }
}

enum AtlasDiagnosticLevel {
  excellent,
  stable,
  attention,
  critical,
}

enum AtlasDiagnosticHorizon {
  sevenDays,
  thirtyDays,
  ninetyDays,
}

String atlasDiagnosticLevelLabel(
  AtlasDiagnosticLevel level,
) {
  switch (level) {
    case AtlasDiagnosticLevel.excellent:
      return 'Excelente';

    case AtlasDiagnosticLevel.stable:
      return 'Estável';

    case AtlasDiagnosticLevel.attention:
      return 'Atenção';

    case AtlasDiagnosticLevel.critical:
      return 'Crítico';
  }
}

String atlasDiagnosticHorizonLabel(
  AtlasDiagnosticHorizon horizon,
) {
  switch (horizon) {
    case AtlasDiagnosticHorizon.sevenDays:
      return 'Próximos 7 dias';

    case AtlasDiagnosticHorizon.thirtyDays:
      return 'Próximos 30 dias';

    case AtlasDiagnosticHorizon.ninetyDays:
      return 'Próximos 90 dias';
  }
}
