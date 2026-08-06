import 'atlas_performance_kpi.dart';

enum AtlasPerformanceAlertSeverity { info, attention, critical }

class AtlasPerformanceAlert {
  const AtlasPerformanceAlert({required this.title, required this.message, required this.severity, this.kpiId});
  final String title;
  final String message;
  final AtlasPerformanceAlertSeverity severity;
  final String? kpiId;
}

class AtlasKpiEvaluation {
  const AtlasKpiEvaluation({required this.kpi, required this.status, required this.achievement});
  final AtlasPerformanceKpi kpi;
  final AtlasKpiStatus status;
  final double achievement;
}

class AtlasPerformanceScorecard {
  const AtlasPerformanceScorecard({
    required this.overallScore,
    required this.productiveScore,
    required this.financialScore,
    required this.operationalScore,
    required this.strategicScore,
    required this.evaluations,
    required this.alerts,
  });
  final double overallScore;
  final double productiveScore;
  final double financialScore;
  final double operationalScore;
  final double strategicScore;
  final List<AtlasKpiEvaluation> evaluations;
  final List<AtlasPerformanceAlert> alerts;
}
