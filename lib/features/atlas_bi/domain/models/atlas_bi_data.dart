class AtlasBiData {
  const AtlasBiData({
    required this.generatedAt,
    required this.title,
    required this.summary,
    required this.score,
    required this.status,
    required this.indicators,
    required this.rankings,
    required this.insights,
  });

  final DateTime generatedAt;
  final String title;
  final String summary;

  final double score;
  final AtlasBiStatus status;

  final List<AtlasBiIndicator> indicators;
  final List<AtlasBiFarmRanking> rankings;
  final List<AtlasBiInsight> insights;

  bool get hasData {
    return indicators.isNotEmpty || rankings.isNotEmpty || insights.isNotEmpty;
  }

  List<AtlasBiIndicator> get criticalIndicators {
    return indicators.where((item) {
      return item.status == AtlasBiStatus.critical;
    }).toList();
  }

  List<AtlasBiIndicator> get positiveIndicators {
    return indicators.where((item) {
      return item.status == AtlasBiStatus.excellent ||
          item.status == AtlasBiStatus.adequate;
    }).toList();
  }

  AtlasBiFarmRanking? get leadingFarm {
    if (rankings.isEmpty) {
      return null;
    }

    return rankings.first;
  }
}

class AtlasBiIndicator {
  const AtlasBiIndicator({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.unit,
    required this.currentValue,
    required this.previousValue,
    required this.targetValue,
    required this.variationPercent,
    required this.targetAchievementPercent,
    required this.trend,
    required this.status,
    required this.series,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;

  final String unit;

  final double currentValue;
  final double? previousValue;
  final double targetValue;

  final double variationPercent;
  final double targetAchievementPercent;

  final AtlasBiTrend trend;
  final AtlasBiStatus status;

  final List<AtlasBiSeriesPoint> series;
}

class AtlasBiSeriesPoint {
  const AtlasBiSeriesPoint({required this.recordedAt, required this.value});

  final DateTime recordedAt;
  final double value;
}

class AtlasBiFarmRanking {
  const AtlasBiFarmRanking({
    required this.position,
    required this.farmName,
    required this.score,
    required this.status,
    required this.positiveIndicators,
    required this.criticalIndicators,
  });

  final int position;
  final String farmName;

  final double score;
  final AtlasBiStatus status;

  final int positiveIndicators;
  final int criticalIndicators;
}

class AtlasBiInsight {
  const AtlasBiInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.priority,
    required this.confidencePercent,
    required this.recommendation,
    this.farmName,
  });

  final String id;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasBiInsightType type;
  final AtlasBiPriority priority;

  final double confidencePercent;

  final String recommendation;
  final String? farmName;
}

class AtlasBiInput {
  const AtlasBiInput({required this.indicators, required this.insights});

  final List<AtlasBiIndicatorInput> indicators;
  final List<AtlasBiInsight> insights;
}

class AtlasBiIndicatorInput {
  const AtlasBiIndicatorInput({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.unit,
    required this.currentValue,
    required this.targetValue,
    required this.higherIsBetter,
    required this.series,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;

  final String unit;

  final double currentValue;
  final double targetValue;

  final bool higherIsBetter;

  final List<AtlasBiSeriesPoint> series;
}

enum AtlasBiCategory {
  production,
  reproduction,
  health,
  finance,
  management,
  inventory,
  pasture,
  intelligence,
}

enum AtlasBiStatus { excellent, adequate, attention, critical }

enum AtlasBiTrend { strongUp, up, stable, down, strongDown, unavailable }

enum AtlasBiInsightType { opportunity, risk, anomaly, trend, recommendation }

enum AtlasBiPriority { low, medium, high, critical }

String atlasBiCategoryLabel(AtlasBiCategory category) {
  switch (category) {
    case AtlasBiCategory.production:
      return 'Produção';

    case AtlasBiCategory.reproduction:
      return 'Reprodução';

    case AtlasBiCategory.health:
      return 'Saúde';

    case AtlasBiCategory.finance:
      return 'Financeiro';

    case AtlasBiCategory.management:
      return 'Gestão';

    case AtlasBiCategory.inventory:
      return 'Estoque';

    case AtlasBiCategory.pasture:
      return 'Pastagem';

    case AtlasBiCategory.intelligence:
      return 'Inteligência';
  }
}

String atlasBiStatusLabel(AtlasBiStatus status) {
  switch (status) {
    case AtlasBiStatus.excellent:
      return 'Excelente';

    case AtlasBiStatus.adequate:
      return 'Adequado';

    case AtlasBiStatus.attention:
      return 'Atenção';

    case AtlasBiStatus.critical:
      return 'Crítico';
  }
}

String atlasBiTrendLabel(AtlasBiTrend trend) {
  switch (trend) {
    case AtlasBiTrend.strongUp:
      return 'Alta forte';

    case AtlasBiTrend.up:
      return 'Alta';

    case AtlasBiTrend.stable:
      return 'Estável';

    case AtlasBiTrend.down:
      return 'Queda';

    case AtlasBiTrend.strongDown:
      return 'Queda forte';

    case AtlasBiTrend.unavailable:
      return 'Sem histórico';
  }
}

String atlasBiInsightTypeLabel(AtlasBiInsightType type) {
  switch (type) {
    case AtlasBiInsightType.opportunity:
      return 'Oportunidade';

    case AtlasBiInsightType.risk:
      return 'Risco';

    case AtlasBiInsightType.anomaly:
      return 'Anomalia';

    case AtlasBiInsightType.trend:
      return 'Tendência';

    case AtlasBiInsightType.recommendation:
      return 'Recomendação';
  }
}
