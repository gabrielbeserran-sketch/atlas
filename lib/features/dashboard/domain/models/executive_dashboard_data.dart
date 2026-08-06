class ExecutiveDashboardData {
  const ExecutiveDashboardData({
    required this.generatedAt,
    required this.scopeLabel,
    required this.kpis,
    required this.alerts,
    required this.recommendations,
    required this.responsibleRanking,
    required this.farmRanking,
    required this.priorityRanking,
    required this.statusDistribution,
    required this.monthlyEvolution,
    required this.weeklyEvolution,
    required this.generalPerformanceIndex,
    required this.productivityTrend,
    required this.delayTrend,
  });

  final String generatedAt;
  final String scopeLabel;

  final List<ExecutiveKpiData> kpis;
  final List<ExecutiveAlertData> alerts;
  final List<ExecutiveRecommendationData> recommendations;

  final List<ExecutiveRankingItem> responsibleRanking;

  final List<ExecutiveRankingItem> farmRanking;

  final List<ExecutiveRankingItem> priorityRanking;

  final List<ExecutiveDistributionItemData> statusDistribution;

  final List<ExecutiveEvolutionPoint> monthlyEvolution;

  final List<ExecutiveEvolutionPoint> weeklyEvolution;

  final double generalPerformanceIndex;

  final ExecutiveTrendData productivityTrend;
  final ExecutiveTrendData delayTrend;

  bool get hasAlerts {
    return alerts.isNotEmpty;
  }

  bool get hasRecommendations {
    return recommendations.isNotEmpty;
  }

  bool get hasMonthlyEvolution {
    return monthlyEvolution.isNotEmpty;
  }

  bool get hasWeeklyEvolution {
    return weeklyEvolution.isNotEmpty;
  }

  ExecutiveKpiData? findKpi(String id) {
    for (final kpi in kpis) {
      if (kpi.id == id) {
        return kpi;
      }
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt,
      'scopeLabel': scopeLabel,
      'kpis': kpis.map((item) {
        return item.toJson();
      }).toList(),
      'alerts': alerts.map((item) {
        return item.toJson();
      }).toList(),
      'recommendations': recommendations.map((item) {
        return item.toJson();
      }).toList(),
      'responsibleRanking': responsibleRanking.map((item) {
        return item.toJson();
      }).toList(),
      'farmRanking': farmRanking.map((item) {
        return item.toJson();
      }).toList(),
      'priorityRanking': priorityRanking.map((item) {
        return item.toJson();
      }).toList(),
      'statusDistribution': statusDistribution.map((item) {
        return item.toJson();
      }).toList(),
      'monthlyEvolution': monthlyEvolution.map((item) {
        return item.toJson();
      }).toList(),
      'weeklyEvolution': weeklyEvolution.map((item) {
        return item.toJson();
      }).toList(),
      'generalPerformanceIndex': generalPerformanceIndex,
      'productivityTrend': productivityTrend.toJson(),
      'delayTrend': delayTrend.toJson(),
    };
  }

  factory ExecutiveDashboardData.fromJson(Map<String, dynamic> json) {
    return ExecutiveDashboardData(
      generatedAt: json['generatedAt']?.toString() ?? '',
      scopeLabel: json['scopeLabel']?.toString() ?? '',
      kpis: _parseList(json['kpis'], ExecutiveKpiData.fromJson),
      alerts: _parseList(json['alerts'], ExecutiveAlertData.fromJson),
      recommendations: _parseList(
        json['recommendations'],
        ExecutiveRecommendationData.fromJson,
      ),
      responsibleRanking: _parseList(
        json['responsibleRanking'],
        ExecutiveRankingItem.fromJson,
      ),
      farmRanking: _parseList(
        json['farmRanking'],
        ExecutiveRankingItem.fromJson,
      ),
      priorityRanking: _parseList(
        json['priorityRanking'],
        ExecutiveRankingItem.fromJson,
      ),
      statusDistribution: _parseList(
        json['statusDistribution'],
        ExecutiveDistributionItemData.fromJson,
      ),
      monthlyEvolution: _parseList(
        json['monthlyEvolution'],
        ExecutiveEvolutionPoint.fromJson,
      ),
      weeklyEvolution: _parseList(
        json['weeklyEvolution'],
        ExecutiveEvolutionPoint.fromJson,
      ),
      generalPerformanceIndex: _parseDouble(json['generalPerformanceIndex']),
      productivityTrend: ExecutiveTrendData.fromJson(
        Map<String, dynamic>.from(
          json['productivityTrend'] as Map? ?? const {},
        ),
      ),
      delayTrend: ExecutiveTrendData.fromJson(
        Map<String, dynamic>.from(json['delayTrend'] as Map? ?? const {}),
      ),
    );
  }
}

class ExecutiveKpiData {
  const ExecutiveKpiData({
    required this.id,
    required this.title,
    required this.value,
    required this.numericValue,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.change,
    required this.changeLabel,
  });

  final String id;
  final String title;
  final String value;
  final double numericValue;
  final String subtitle;

  final ExecutiveKpiType type;
  final ExecutiveIndicatorStatus status;

  final double change;
  final String changeLabel;

  bool get hasChange {
    return change != 0;
  }

  bool get isImproving {
    return change > 0;
  }

  bool get isDeclining {
    return change < 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'numericValue': numericValue,
      'subtitle': subtitle,
      'type': type.name,
      'status': status.name,
      'change': change,
      'changeLabel': changeLabel,
    };
  }

  factory ExecutiveKpiData.fromJson(Map<String, dynamic> json) {
    return ExecutiveKpiData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      numericValue: _parseDouble(json['numericValue']),
      subtitle: json['subtitle']?.toString() ?? '',
      type: _parseEnum(
        ExecutiveKpiType.values,
        json['type']?.toString(),
        ExecutiveKpiType.number,
      ),
      status: _parseEnum(
        ExecutiveIndicatorStatus.values,
        json['status']?.toString(),
        ExecutiveIndicatorStatus.normal,
      ),
      change: _parseDouble(json['change']),
      changeLabel: json['changeLabel']?.toString() ?? '',
    );
  }
}

class ExecutiveAlertData {
  const ExecutiveAlertData({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.severity,
    required this.count,
    required this.actionLabel,
    required this.route,
  });

  final String id;
  final String title;
  final String message;
  final String category;

  final ExecutiveAlertSeverity severity;

  final int count;
  final String actionLabel;
  final String route;

  bool get isCritical {
    return severity == ExecutiveAlertSeverity.critical;
  }

  bool get isWarning {
    return severity == ExecutiveAlertSeverity.warning;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'severity': severity.name,
      'count': count,
      'actionLabel': actionLabel,
      'route': route,
    };
  }

  factory ExecutiveAlertData.fromJson(Map<String, dynamic> json) {
    return ExecutiveAlertData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      severity: _parseEnum(
        ExecutiveAlertSeverity.values,
        json['severity']?.toString(),
        ExecutiveAlertSeverity.information,
      ),
      count: _parseInt(json['count']),
      actionLabel: json['actionLabel']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
    );
  }
}

class ExecutiveRecommendationData {
  const ExecutiveRecommendationData({
    required this.id,
    required this.title,
    required this.message,
    required this.recommendedAction,
    required this.priority,
    required this.category,
    required this.confidence,
  });

  final String id;
  final String title;
  final String message;
  final String recommendedAction;

  final ExecutiveRecommendationPriority priority;

  final String category;
  final double confidence;

  bool get isHighPriority {
    return priority == ExecutiveRecommendationPriority.high ||
        priority == ExecutiveRecommendationPriority.critical;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'recommendedAction': recommendedAction,
      'priority': priority.name,
      'category': category,
      'confidence': confidence,
    };
  }

  factory ExecutiveRecommendationData.fromJson(Map<String, dynamic> json) {
    return ExecutiveRecommendationData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      recommendedAction: json['recommendedAction']?.toString() ?? '',
      priority: _parseEnum(
        ExecutiveRecommendationPriority.values,
        json['priority']?.toString(),
        ExecutiveRecommendationPriority.medium,
      ),
      category: json['category']?.toString() ?? '',
      confidence: _parseDouble(json['confidence']),
    );
  }
}

class ExecutiveRankingItem {
  const ExecutiveRankingItem({
    required this.position,
    required this.label,
    required this.value,
    required this.secondaryValue,
    required this.percentage,
    required this.status,
  });

  final int position;
  final String label;
  final double value;
  final double secondaryValue;
  final double percentage;

  final ExecutiveIndicatorStatus status;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'label': label,
      'value': value,
      'secondaryValue': secondaryValue,
      'percentage': percentage,
      'status': status.name,
    };
  }

  factory ExecutiveRankingItem.fromJson(Map<String, dynamic> json) {
    return ExecutiveRankingItem(
      position: _parseInt(json['position']),
      label: json['label']?.toString() ?? '',
      value: _parseDouble(json['value']),
      secondaryValue: _parseDouble(json['secondaryValue']),
      percentage: _parseDouble(json['percentage']),
      status: _parseEnum(
        ExecutiveIndicatorStatus.values,
        json['status']?.toString(),
        ExecutiveIndicatorStatus.normal,
      ),
    );
  }
}

class ExecutiveDistributionItemData {
  const ExecutiveDistributionItemData({
    required this.label,
    required this.value,
    required this.percentage,
    required this.category,
    required this.status,
  });

  final String label;
  final double value;
  final double percentage;
  final String category;

  final ExecutiveIndicatorStatus status;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'percentage': percentage,
      'category': category,
      'status': status.name,
    };
  }

  factory ExecutiveDistributionItemData.fromJson(Map<String, dynamic> json) {
    return ExecutiveDistributionItemData(
      label: json['label']?.toString() ?? '',
      value: _parseDouble(json['value']),
      percentage: _parseDouble(json['percentage']),
      category: json['category']?.toString() ?? '',
      status: _parseEnum(
        ExecutiveIndicatorStatus.values,
        json['status']?.toString(),
        ExecutiveIndicatorStatus.normal,
      ),
    );
  }
}

class ExecutiveEvolutionPoint {
  const ExecutiveEvolutionPoint({
    required this.date,
    required this.label,
    required this.createdCount,
    required this.completedCount,
    required this.overdueCount,
    required this.completionRate,
  });

  final String date;
  final String label;

  final int createdCount;
  final int completedCount;
  final int overdueCount;

  final double completionRate;

  int get balance {
    return completedCount - createdCount;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'label': label,
      'createdCount': createdCount,
      'completedCount': completedCount,
      'overdueCount': overdueCount,
      'completionRate': completionRate,
    };
  }

  factory ExecutiveEvolutionPoint.fromJson(Map<String, dynamic> json) {
    return ExecutiveEvolutionPoint(
      date: json['date']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      createdCount: _parseInt(json['createdCount']),
      completedCount: _parseInt(json['completedCount']),
      overdueCount: _parseInt(json['overdueCount']),
      completionRate: _parseDouble(json['completionRate']),
    );
  }
}

class ExecutiveTrendData {
  const ExecutiveTrendData({
    required this.direction,
    required this.percentage,
    required this.currentValue,
    required this.previousValue,
    required this.label,
    required this.interpretation,
  });

  final ExecutiveTrendDirection direction;

  final double percentage;
  final double currentValue;
  final double previousValue;

  final String label;
  final String interpretation;

  bool get isStable {
    return direction == ExecutiveTrendDirection.stable;
  }

  bool get isIncreasing {
    return direction == ExecutiveTrendDirection.increasing;
  }

  bool get isDecreasing {
    return direction == ExecutiveTrendDirection.decreasing;
  }

  Map<String, dynamic> toJson() {
    return {
      'direction': direction.name,
      'percentage': percentage,
      'currentValue': currentValue,
      'previousValue': previousValue,
      'label': label,
      'interpretation': interpretation,
    };
  }

  factory ExecutiveTrendData.fromJson(Map<String, dynamic> json) {
    return ExecutiveTrendData(
      direction: _parseEnum(
        ExecutiveTrendDirection.values,
        json['direction']?.toString(),
        ExecutiveTrendDirection.stable,
      ),
      percentage: _parseDouble(json['percentage']),
      currentValue: _parseDouble(json['currentValue']),
      previousValue: _parseDouble(json['previousValue']),
      label: json['label']?.toString() ?? '',
      interpretation: json['interpretation']?.toString() ?? '',
    );
  }
}

enum ExecutiveKpiType { number, percentage, currency, duration, score }

enum ExecutiveIndicatorStatus { positive, normal, attention, critical }

enum ExecutiveAlertSeverity { information, warning, critical }

enum ExecutiveRecommendationPriority { low, medium, high, critical }

enum ExecutiveTrendDirection { increasing, stable, decreasing }

List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) {
    return [];
  }

  return value.whereType<Map>().map((item) {
    return parser(Map<String, dynamic>.from(item));
  }).toList();
}

T _parseEnum<T extends Enum>(List<T> values, String? value, T fallback) {
  if (value == null) {
    return fallback;
  }

  for (final item in values) {
    if (item.name == value) {
      return item;
    }
  }

  return fallback;
}

double _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
