import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasPerformanceSnapshot {
  const AtlasPerformanceSnapshot({
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.executionScore,
    required this.planProgress,
    required this.onTimeRate,
    required this.realizedImpact,
    required this.expectedImpact,
    required this.kpis,
    required this.alerts,
  });

  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final double executionScore;
  final double planProgress;
  final double onTimeRate;
  final double realizedImpact;
  final double expectedImpact;
  final List<AtlasPerformanceKpi> kpis;
  final List<AtlasPerformanceAlert> alerts;
}

class AtlasPerformanceKpi {
  const AtlasPerformanceKpi({
    required this.id,
    required this.title,
    required this.area,
    required this.unit,
    required this.beforeValue,
    required this.currentValue,
    required this.targetValue,
    required this.trend,
    required this.interpretation,
  });

  final String id;
  final String title;
  final AtlasFarmAuditArea area;
  final String unit;
  final double beforeValue;
  final double currentValue;
  final double targetValue;
  final AtlasPerformanceTrend trend;
  final String interpretation;

  double get variation => currentValue - beforeValue;
  double get targetProgress {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.2).toDouble();
  }
}

class AtlasPerformanceAlert {
  const AtlasPerformanceAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.area,
  });

  final String id;
  final String title;
  final String message;
  final AtlasPerformanceAlertSeverity severity;
  final AtlasFarmAuditArea area;
}

enum AtlasPerformanceTrend { improving, stable, worsening }

enum AtlasPerformanceAlertSeverity { information, attention, high, critical }

String atlasPerformanceTrendLabel(AtlasPerformanceTrend trend) {
  switch (trend) {
    case AtlasPerformanceTrend.improving:
      return 'Melhorando';
    case AtlasPerformanceTrend.stable:
      return 'Estável';
    case AtlasPerformanceTrend.worsening:
      return 'Piorando';
  }
}

String atlasPerformanceAlertSeverityLabel(
  AtlasPerformanceAlertSeverity severity,
) {
  switch (severity) {
    case AtlasPerformanceAlertSeverity.information:
      return 'Informativo';
    case AtlasPerformanceAlertSeverity.attention:
      return 'Atenção';
    case AtlasPerformanceAlertSeverity.high:
      return 'Alto';
    case AtlasPerformanceAlertSeverity.critical:
      return 'Crítico';
  }
}
