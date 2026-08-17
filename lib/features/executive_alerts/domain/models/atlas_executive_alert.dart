import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasExecutiveAlert {
  const AtlasExecutiveAlert({
    required this.id,
    required this.generatedAt,
    required this.farmName,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.type,
    required this.severity,
    required this.area,
    required this.priorityScore,
    required this.responseDeadlineDays,
    required this.sourceLabel,
    this.numericValue,
    this.unitLabel,
  });

  final String id;
  final DateTime generatedAt;

  final String farmName;

  final String title;
  final String description;
  final String recommendation;

  final AtlasExecutiveAlertType type;
  final AtlasExecutiveAlertSeverity severity;

  final AtlasFarmAnalysisArea area;

  final double priorityScore;

  final int responseDeadlineDays;

  final String sourceLabel;

  final double? numericValue;
  final String? unitLabel;

  bool get isCritical {
    return severity == AtlasExecutiveAlertSeverity.critical;
  }

  bool get requiresImmediateAction {
    return isCritical || responseDeadlineDays <= 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'generatedAt': generatedAt.toIso8601String(),
      'farmName': farmName,
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'type': type.name,
      'severity': severity.name,
      'area': area.name,
      'priorityScore': priorityScore,
      'responseDeadlineDays': responseDeadlineDays,
      'sourceLabel': sourceLabel,
      'numericValue': numericValue,
      'unitLabel': unitLabel,
    };
  }
}

class AtlasExecutiveAlertSummary {
  const AtlasExecutiveAlertSummary({
    required this.generatedAt,
    required this.summary,
    required this.total,
    required this.informational,
    required this.attention,
    required this.high,
    required this.critical,
    required this.alerts,
    required this.farms,
    required this.areas,
  });

  final DateTime generatedAt;
  final String summary;

  final int total;
  final int informational;
  final int attention;
  final int high;
  final int critical;

  final List<AtlasExecutiveAlert> alerts;

  final List<AtlasExecutiveFarmAlertSummary> farms;

  final List<AtlasExecutiveAreaAlertSummary> areas;

  bool get hasAlerts {
    return alerts.isNotEmpty;
  }

  AtlasExecutiveAlert? get mainAlert {
    if (alerts.isEmpty) {
      return null;
    }

    return alerts.first;
  }

  AtlasExecutiveFarmAlertSummary? get mostCriticalFarm {
    if (farms.isEmpty) {
      return null;
    }

    return farms.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'summary': summary,
      'total': total,
      'informational': informational,
      'attention': attention,
      'high': high,
      'critical': critical,
      'alerts': alerts.map((item) {
        return item.toJson();
      }).toList(),
      'farms': farms.map((item) {
        return item.toJson();
      }).toList(),
      'areas': areas.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class AtlasExecutiveFarmAlertSummary {
  const AtlasExecutiveFarmAlertSummary({
    required this.farmName,
    required this.total,
    required this.critical,
    required this.high,
    required this.attention,
    required this.priorityScore,
    required this.mainAlertTitle,
  });

  final String farmName;

  final int total;
  final int critical;
  final int high;
  final int attention;

  final double priorityScore;

  final String? mainAlertTitle;

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'total': total,
      'critical': critical,
      'high': high,
      'attention': attention,
      'priorityScore': priorityScore,
      'mainAlertTitle': mainAlertTitle,
    };
  }
}

class AtlasExecutiveAreaAlertSummary {
  const AtlasExecutiveAreaAlertSummary({
    required this.area,
    required this.label,
    required this.total,
    required this.critical,
    required this.high,
  });

  final AtlasFarmAnalysisArea area;
  final String label;

  final int total;
  final int critical;
  final int high;

  Map<String, dynamic> toJson() {
    return {
      'area': area.name,
      'label': label,
      'total': total,
      'critical': critical,
      'high': high,
    };
  }
}

enum AtlasExecutiveAlertType {
  diagnosticRisk,
  trackedActionOverdue,
  agendaOverdue,
  agendaUrgent,
  inventoryExpired,
  inventoryNearExpiration,
  negativeFinancialResult,
  herdRegistrationGap,
  paddockProblem,
  healthSchedule,
  healthWithdrawal,
  healthQuarantine,
  reproductionSchedule,
  mainPriority,
}

enum AtlasExecutiveAlertSeverity { informational, attention, high, critical }

String atlasExecutiveAlertSeverityLabel(AtlasExecutiveAlertSeverity severity) {
  switch (severity) {
    case AtlasExecutiveAlertSeverity.informational:
      return 'Informativo';

    case AtlasExecutiveAlertSeverity.attention:
      return 'Atenção';

    case AtlasExecutiveAlertSeverity.high:
      return 'Alto';

    case AtlasExecutiveAlertSeverity.critical:
      return 'Crítico';
  }
}

AtlasDiagnosticLevel atlasExecutiveAlertSeverityToDiagnosticLevel(
  AtlasExecutiveAlertSeverity severity,
) {
  switch (severity) {
    case AtlasExecutiveAlertSeverity.informational:
      return AtlasDiagnosticLevel.stable;

    case AtlasExecutiveAlertSeverity.attention:
      return AtlasDiagnosticLevel.attention;

    case AtlasExecutiveAlertSeverity.high:
    case AtlasExecutiveAlertSeverity.critical:
      return AtlasDiagnosticLevel.critical;
  }
}
