enum AtlasKpiCategory { productive, financial, operational, strategic }
enum AtlasKpiDirection { higherIsBetter, lowerIsBetter, targetRange }
enum AtlasKpiStatus { excellent, onTarget, attention, critical }

class AtlasPerformanceKpi {
  const AtlasPerformanceKpi({
    required this.id,
    required this.farmId,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentValue,
    required this.targetValue,
    required this.previousValue,
    required this.direction,
    required this.updatedAt,
    this.minimumTarget,
    this.maximumTarget,
    this.notes = '',
  });

  final String id;
  final String farmId;
  final String name;
  final AtlasKpiCategory category;
  final String unit;
  final double currentValue;
  final double targetValue;
  final double previousValue;
  final AtlasKpiDirection direction;
  final DateTime updatedAt;
  final double? minimumTarget;
  final double? maximumTarget;
  final String notes;

  double get variation => previousValue == 0 ? 0 : ((currentValue - previousValue) / previousValue) * 100;

  AtlasPerformanceKpi copyWith({
    String? id, String? farmId, String? name, AtlasKpiCategory? category,
    String? unit, double? currentValue, double? targetValue,
    double? previousValue, AtlasKpiDirection? direction, DateTime? updatedAt,
    double? minimumTarget, double? maximumTarget, String? notes,
  }) => AtlasPerformanceKpi(
    id: id ?? this.id, farmId: farmId ?? this.farmId, name: name ?? this.name,
    category: category ?? this.category, unit: unit ?? this.unit,
    currentValue: currentValue ?? this.currentValue,
    targetValue: targetValue ?? this.targetValue,
    previousValue: previousValue ?? this.previousValue,
    direction: direction ?? this.direction, updatedAt: updatedAt ?? this.updatedAt,
    minimumTarget: minimumTarget ?? this.minimumTarget,
    maximumTarget: maximumTarget ?? this.maximumTarget, notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id, 'farmId': farmId, 'name': name, 'category': category.name,
    'unit': unit, 'currentValue': currentValue, 'targetValue': targetValue,
    'previousValue': previousValue, 'direction': direction.name,
    'updatedAt': updatedAt.toIso8601String(), 'minimumTarget': minimumTarget,
    'maximumTarget': maximumTarget, 'notes': notes,
  };

  factory AtlasPerformanceKpi.fromJson(Map<String, dynamic> json) => AtlasPerformanceKpi(
    id: json['id'] as String, farmId: (json['farmId'] as String?) ?? '',
    name: json['name'] as String,
    category: AtlasKpiCategory.values.byName((json['category'] as String?) ?? 'productive'),
    unit: (json['unit'] as String?) ?? '',
    currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0,
    targetValue: (json['targetValue'] as num?)?.toDouble() ?? 0,
    previousValue: (json['previousValue'] as num?)?.toDouble() ?? 0,
    direction: AtlasKpiDirection.values.byName((json['direction'] as String?) ?? 'higherIsBetter'),
    updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
    minimumTarget: (json['minimumTarget'] as num?)?.toDouble(),
    maximumTarget: (json['maximumTarget'] as num?)?.toDouble(),
    notes: (json['notes'] as String?) ?? '',
  );
}
