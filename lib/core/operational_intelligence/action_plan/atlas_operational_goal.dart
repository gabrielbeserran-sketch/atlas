enum AtlasOperationalArea {
  herd,
  reproduction,
  health,
  nutrition,
  stock,
  finance,
  general,
}

String atlasOperationalAreaLabel(AtlasOperationalArea area) {
  switch (area) {
    case AtlasOperationalArea.herd:
      return 'Rebanho';
    case AtlasOperationalArea.reproduction:
      return 'Reprodução';
    case AtlasOperationalArea.health:
      return 'Sanidade';
    case AtlasOperationalArea.nutrition:
      return 'Nutrição';
    case AtlasOperationalArea.stock:
      return 'Estoque';
    case AtlasOperationalArea.finance:
      return 'Financeiro';
    case AtlasOperationalArea.general:
      return 'Geral';
  }
}

enum AtlasGoalPeriod { monthly, quarterly, annual }

String atlasGoalPeriodLabel(AtlasGoalPeriod period) {
  switch (period) {
    case AtlasGoalPeriod.monthly:
      return 'Mensal';
    case AtlasGoalPeriod.quarterly:
      return 'Trimestral';
    case AtlasGoalPeriod.annual:
      return 'Anual';
  }
}

enum AtlasGoalMetricType { percentage, quantity, currency, score }

String atlasGoalMetricTypeLabel(AtlasGoalMetricType type) {
  switch (type) {
    case AtlasGoalMetricType.percentage:
      return 'Percentual';
    case AtlasGoalMetricType.quantity:
      return 'Quantidade';
    case AtlasGoalMetricType.currency:
      return 'Valor financeiro';
    case AtlasGoalMetricType.score:
      return 'Pontuação';
  }
}

class AtlasOperationalGoal {
  const AtlasOperationalGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.period,
    required this.metricType,
    required this.targetValue,
    required this.currentValue,
    required this.startAt,
    required this.endAt,
    required this.farmName,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final AtlasOperationalArea area;
  final AtlasGoalPeriod period;
  final AtlasGoalMetricType metricType;
  final double targetValue;
  final double currentValue;
  final DateTime startAt;
  final DateTime endAt;
  final String? farmName;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progressPercent {
    if (targetValue <= 0) {
      return 0;
    }

    return (currentValue / targetValue * 100).clamp(0.0, 100.0);
  }

  bool get isCompleted => targetValue > 0 && currentValue >= targetValue;

  bool get isOverdue => !isCompleted && endAt.isBefore(DateTime.now());

  AtlasOperationalGoal copyWith({
    String? title,
    String? description,
    AtlasOperationalArea? area,
    AtlasGoalPeriod? period,
    AtlasGoalMetricType? metricType,
    double? targetValue,
    double? currentValue,
    DateTime? startAt,
    DateTime? endAt,
    String? farmName,
    bool replaceFarmName = false,
    bool? active,
    DateTime? updatedAt,
  }) {
    return AtlasOperationalGoal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      area: area ?? this.area,
      period: period ?? this.period,
      metricType: metricType ?? this.metricType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      farmName: replaceFarmName ? farmName : this.farmName,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'area': area.name,
      'period': period.name,
      'metricType': metricType.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'farmName': farmName,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AtlasOperationalGoal.fromMap(Map<String, dynamic> map) {
    return AtlasOperationalGoal(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      area: AtlasOperationalArea.values.firstWhere(
        (value) => value.name == map['area']?.toString(),
        orElse: () => AtlasOperationalArea.general,
      ),
      period: AtlasGoalPeriod.values.firstWhere(
        (value) => value.name == map['period']?.toString(),
        orElse: () => AtlasGoalPeriod.monthly,
      ),
      metricType: AtlasGoalMetricType.values.firstWhere(
        (value) => value.name == map['metricType']?.toString(),
        orElse: () => AtlasGoalMetricType.percentage,
      ),
      targetValue: _readDouble(map['targetValue']),
      currentValue: _readDouble(map['currentValue']),
      startAt:
          DateTime.tryParse(map['startAt']?.toString() ?? '') ?? DateTime.now(),
      endAt:
          DateTime.tryParse(map['endAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      farmName: map['farmName']?.toString(),
      active: map['active'] != false,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
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
