class AtlasExecutiveKpi {
  const AtlasExecutiveKpi({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.value,
    required this.unit,
    required this.targetValue,
    required this.direction,
    required this.trend,
    required this.trendPercent,
    required this.status,
    required this.weight,
    required this.generatedAt,
    this.previousValue,
    this.sourceLabel = '',
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasExecutiveKpiCategory category;

  final double value;
  final double? previousValue;
  final String unit;

  final double targetValue;

  final AtlasExecutiveKpiDirection direction;
  final AtlasExecutiveKpiTrend trend;

  final double trendPercent;

  final AtlasExecutiveKpiStatus status;

  final double weight;

  final DateTime generatedAt;

  final String sourceLabel;

  double get targetAchievementPercent {
    if (targetValue == 0) {
      return 0;
    }

    final result = switch (direction) {
      AtlasExecutiveKpiDirection.higherIsBetter => value / targetValue * 100,
      AtlasExecutiveKpiDirection.lowerIsBetter =>
        value <= 0 ? 100 : targetValue / value * 100,
      AtlasExecutiveKpiDirection.neutral =>
        100 -
            ((value - targetValue).abs() /
                targetValue.abs().clamp(1.0, double.infinity) *
                100),
    };

    return result.clamp(0.0, 150.0).toDouble();
  }

  bool get isCritical {
    return status == AtlasExecutiveKpiStatus.critical;
  }

  bool get isPositive {
    return status == AtlasExecutiveKpiStatus.excellent ||
        status == AtlasExecutiveKpiStatus.adequate;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmName': farmName,
      'title': title,
      'description': description,
      'category': category.name,
      'value': value,
      'previousValue': previousValue,
      'unit': unit,
      'targetValue': targetValue,
      'direction': direction.name,
      'trend': trend.name,
      'trendPercent': trendPercent,
      'status': status.name,
      'weight': weight,
      'generatedAt': generatedAt.toIso8601String(),
      'sourceLabel': sourceLabel,
    };
  }
}

class AtlasExecutiveFarmKpiSummary {
  const AtlasExecutiveFarmKpiSummary({
    required this.farmName,
    required this.score,
    required this.status,
    required this.totalKpis,
    required this.excellent,
    required this.adequate,
    required this.attention,
    required this.critical,
    required this.mainPositiveKpi,
    required this.mainCriticalKpi,
  });

  final String farmName;

  final double score;

  final AtlasExecutiveKpiStatus status;

  final int totalKpis;
  final int excellent;
  final int adequate;
  final int attention;
  final int critical;

  final AtlasExecutiveKpi? mainPositiveKpi;
  final AtlasExecutiveKpi? mainCriticalKpi;

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'score': score,
      'status': status.name,
      'totalKpis': totalKpis,
      'excellent': excellent,
      'adequate': adequate,
      'attention': attention,
      'critical': critical,
      'mainPositiveKpi': mainPositiveKpi?.toJson(),
      'mainCriticalKpi': mainCriticalKpi?.toJson(),
    };
  }
}

class AtlasExecutiveKpiCategorySummary {
  const AtlasExecutiveKpiCategorySummary({
    required this.category,
    required this.label,
    required this.score,
    required this.status,
    required this.totalKpis,
    required this.criticalKpis,
    required this.bestKpi,
    required this.worstKpi,
  });

  final AtlasExecutiveKpiCategory category;
  final String label;

  final double score;
  final AtlasExecutiveKpiStatus status;

  final int totalKpis;
  final int criticalKpis;

  final AtlasExecutiveKpi? bestKpi;
  final AtlasExecutiveKpi? worstKpi;

  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'label': label,
      'score': score,
      'status': status.name,
      'totalKpis': totalKpis,
      'criticalKpis': criticalKpis,
      'bestKpi': bestKpi?.toJson(),
      'worstKpi': worstKpi?.toJson(),
    };
  }
}

class AtlasExecutiveKpiDashboardData {
  const AtlasExecutiveKpiDashboardData({
    required this.generatedAt,
    required this.operationScore,
    required this.operationStatus,
    required this.summary,
    required this.kpis,
    required this.farms,
    required this.categories,
    required this.criticalKpis,
    required this.positiveHighlights,
  });

  final DateTime generatedAt;

  final double operationScore;

  final AtlasExecutiveKpiStatus operationStatus;

  final String summary;

  final List<AtlasExecutiveKpi> kpis;

  final List<AtlasExecutiveFarmKpiSummary> farms;

  final List<AtlasExecutiveKpiCategorySummary> categories;

  final List<AtlasExecutiveKpi> criticalKpis;

  final List<AtlasExecutiveKpi> positiveHighlights;

  bool get hasData {
    return kpis.isNotEmpty;
  }

  AtlasExecutiveFarmKpiSummary? get leadingFarm {
    if (farms.isEmpty) {
      return null;
    }

    return farms.first;
  }

  AtlasExecutiveFarmKpiSummary? get mostCriticalFarm {
    if (farms.isEmpty) {
      return null;
    }

    final ordered = [...farms]
      ..sort((first, second) {
        if (first.critical != second.critical) {
          return second.critical.compareTo(first.critical);
        }

        return first.score.compareTo(second.score);
      });

    return ordered.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'operationScore': operationScore,
      'operationStatus': operationStatus.name,
      'summary': summary,
      'kpis': kpis.map((item) {
        return item.toJson();
      }).toList(),
      'farms': farms.map((item) {
        return item.toJson();
      }).toList(),
      'categories': categories.map((item) {
        return item.toJson();
      }).toList(),
      'criticalKpis': criticalKpis.map((item) {
        return item.toJson();
      }).toList(),
      'positiveHighlights': positiveHighlights.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class AtlasExecutiveFarmKpiInput {
  const AtlasExecutiveFarmKpiInput({
    required this.farmName,
    required this.kpis,
  });

  final String farmName;

  final List<AtlasExecutiveKpiInput> kpis;
}

class AtlasExecutiveKpiInput {
  const AtlasExecutiveKpiInput({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.value,
    required this.unit,
    required this.targetValue,
    required this.direction,
    this.previousValue,
    this.weight = 1,
    this.sourceLabel = '',
  });

  final String id;

  final String title;
  final String description;

  final AtlasExecutiveKpiCategory category;

  final double value;
  final double? previousValue;
  final String unit;

  final double targetValue;

  final AtlasExecutiveKpiDirection direction;

  final double weight;

  final String sourceLabel;
}

enum AtlasExecutiveKpiCategory {
  production,
  reproduction,
  health,
  finance,
  management,
  intelligence,
}

enum AtlasExecutiveKpiDirection { higherIsBetter, lowerIsBetter, neutral }

enum AtlasExecutiveKpiTrend {
  strongUp,
  up,
  stable,
  down,
  strongDown,
  unavailable,
}

enum AtlasExecutiveKpiStatus { excellent, adequate, attention, critical }

String atlasExecutiveKpiCategoryLabel(AtlasExecutiveKpiCategory category) {
  switch (category) {
    case AtlasExecutiveKpiCategory.production:
      return 'Produção';

    case AtlasExecutiveKpiCategory.reproduction:
      return 'Reprodução';

    case AtlasExecutiveKpiCategory.health:
      return 'Saúde';

    case AtlasExecutiveKpiCategory.finance:
      return 'Financeiro';

    case AtlasExecutiveKpiCategory.management:
      return 'Gestão';

    case AtlasExecutiveKpiCategory.intelligence:
      return 'Inteligência';
  }
}

String atlasExecutiveKpiStatusLabel(AtlasExecutiveKpiStatus status) {
  switch (status) {
    case AtlasExecutiveKpiStatus.excellent:
      return 'Excelente';

    case AtlasExecutiveKpiStatus.adequate:
      return 'Adequado';

    case AtlasExecutiveKpiStatus.attention:
      return 'Atenção';

    case AtlasExecutiveKpiStatus.critical:
      return 'Crítico';
  }
}

String atlasExecutiveKpiTrendLabel(AtlasExecutiveKpiTrend trend) {
  switch (trend) {
    case AtlasExecutiveKpiTrend.strongUp:
      return 'Alta forte';

    case AtlasExecutiveKpiTrend.up:
      return 'Alta';

    case AtlasExecutiveKpiTrend.stable:
      return 'Estável';

    case AtlasExecutiveKpiTrend.down:
      return 'Queda';

    case AtlasExecutiveKpiTrend.strongDown:
      return 'Queda forte';

    case AtlasExecutiveKpiTrend.unavailable:
      return 'Sem histórico';
  }
}
