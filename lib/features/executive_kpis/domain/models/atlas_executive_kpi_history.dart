import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';

class AtlasExecutiveKpiHistoryPoint {
  const AtlasExecutiveKpiHistoryPoint({
    required this.kpiId,
    required this.farmName,
    required this.title,
    required this.category,
    required this.value,
    required this.targetValue,
    required this.unit,
    required this.status,
    required this.recordedAt,
  });

  final String kpiId;
  final String farmName;
  final String title;

  final AtlasExecutiveKpiCategory category;

  final double value;
  final double targetValue;
  final String unit;

  final AtlasExecutiveKpiStatus status;

  final DateTime recordedAt;

  Map<String, dynamic> toJson() {
    return {
      'kpiId': kpiId,
      'farmName': farmName,
      'title': title,
      'category': category.name,
      'value': value,
      'targetValue': targetValue,
      'unit': unit,
      'status': status.name,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory AtlasExecutiveKpiHistoryPoint.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category']?.toString() ?? '';

    final statusName = json['status']?.toString() ?? '';

    return AtlasExecutiveKpiHistoryPoint(
      kpiId: json['kpiId']?.toString() ?? '',
      farmName: json['farmName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: AtlasExecutiveKpiCategory.values.firstWhere(
        (item) => item.name == categoryName,
        orElse: () => AtlasExecutiveKpiCategory.intelligence,
      ),
      value: _readDouble(json['value']),
      targetValue: _readDouble(json['targetValue']),
      unit: json['unit']?.toString() ?? '',
      status: AtlasExecutiveKpiStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => AtlasExecutiveKpiStatus.attention,
      ),
      recordedAt:
          DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasExecutiveKpiHistorySeries {
  const AtlasExecutiveKpiHistorySeries({
    required this.kpiId,
    required this.farmName,
    required this.title,
    required this.category,
    required this.unit,
    required this.points,
    required this.currentValue,
    required this.previousValue,
    required this.variationPercent,
    required this.trend,
  });

  final String kpiId;
  final String farmName;
  final String title;

  final AtlasExecutiveKpiCategory category;
  final String unit;

  final List<AtlasExecutiveKpiHistoryPoint> points;

  final double currentValue;
  final double? previousValue;
  final double variationPercent;

  final AtlasExecutiveKpiTrend trend;

  bool get hasHistory {
    return points.length >= 2;
  }

  DateTime? get firstRecordedAt {
    if (points.isEmpty) {
      return null;
    }

    return points.first.recordedAt;
  }

  DateTime? get lastRecordedAt {
    if (points.isEmpty) {
      return null;
    }

    return points.last.recordedAt;
  }
}

class AtlasExecutiveKpiHistorySummary {
  const AtlasExecutiveKpiHistorySummary({
    required this.generatedAt,
    required this.series,
    required this.improvingCount,
    required this.stableCount,
    required this.worseningCount,
    required this.summary,
  });

  final DateTime generatedAt;

  final List<AtlasExecutiveKpiHistorySeries> series;

  final int improvingCount;
  final int stableCount;
  final int worseningCount;

  final String summary;

  bool get hasHistory {
    return series.any((item) => item.hasHistory);
  }

  List<AtlasExecutiveKpiHistorySeries> get improvingSeries {
    return series.where((item) {
      return item.trend == AtlasExecutiveKpiTrend.up ||
          item.trend == AtlasExecutiveKpiTrend.strongUp;
    }).toList();
  }

  List<AtlasExecutiveKpiHistorySeries> get worseningSeries {
    return series.where((item) {
      return item.trend == AtlasExecutiveKpiTrend.down ||
          item.trend == AtlasExecutiveKpiTrend.strongDown;
    }).toList();
  }
}
