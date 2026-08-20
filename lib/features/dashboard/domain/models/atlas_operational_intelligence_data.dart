class AtlasOperationalActionData {
  const AtlasOperationalActionData({
    required this.position,
    required this.priorityScore,
    required this.severity,
    required this.area,
    required this.title,
    required this.recommendedAction,
    required this.entityType,
    required this.entityId,
    required this.dueAt,
  });

  final int position;
  final int priorityScore;
  final String severity;
  final String area;
  final String title;
  final String recommendedAction;
  final String entityType;
  final String entityId;
  final DateTime? dueAt;

  factory AtlasOperationalActionData.fromMap(Map<String, dynamic> map) {
    return AtlasOperationalActionData(
      position: _asInt(map['position']),
      priorityScore: _asInt(map['priority_score']),
      severity: map['severity']?.toString() ?? 'low',
      area: map['area']?.toString() ?? 'Operação',
      title: map['title']?.toString() ?? 'Ação operacional',
      recommendedAction: map['recommended_action']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      dueAt: _asDateTime(map['due_at']),
    );
  }
}

class AtlasOperationalAlertData {
  const AtlasOperationalAlertData({
    required this.id,
    required this.code,
    required this.area,
    required this.severity,
    required this.priorityScore,
    required this.title,
    required this.description,
    required this.recommendedAction,
    required this.entityType,
    required this.entityId,
    required this.dueAt,
  });

  final String id;
  final String code;
  final String area;
  final String severity;
  final int priorityScore;
  final String title;
  final String description;
  final String recommendedAction;
  final String entityType;
  final String entityId;
  final DateTime? dueAt;

  factory AtlasOperationalAlertData.fromMap(Map<String, dynamic> map) {
    return AtlasOperationalAlertData(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      area: map['area']?.toString() ?? 'Operação',
      severity: map['severity']?.toString() ?? 'low',
      priorityScore: _asInt(map['priority_score']),
      title: map['title']?.toString() ?? 'Alerta operacional',
      description: map['description']?.toString() ?? '',
      recommendedAction: map['recommended_action']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      dueAt: _asDateTime(map['due_at']),
    );
  }
}

class AtlasOperationalIntelligenceData {
  const AtlasOperationalIntelligenceData({
    required this.farmId,
    required this.generatedAt,
    required this.operationalScore,
    required this.operationalLevel,
    required this.animals,
    required this.activeAnimals,
    required this.lots,
    required this.income,
    required this.expense,
    required this.balance,
    required this.alertTotal,
    required this.criticalAlerts,
    required this.highAlerts,
    required this.mediumAlerts,
    required this.lowAlerts,
    required this.alertsByArea,
    required this.pregnancyRatePercent,
    required this.pregnantFemales,
    required this.eligibleFemales,
    required this.averageWeightKg,
    required this.averageGmdKgDay,
    required this.costPerActiveAnimal,
    required this.criticalStockItems,
    required this.openTasks,
    required this.overdueTasks,
    required this.nutritionMonthlyCost,
    required this.topActions,
    required this.alerts,
  });

  final String farmId;
  final DateTime? generatedAt;
  final int operationalScore;
  final String operationalLevel;
  final int animals;
  final int activeAnimals;
  final int lots;
  final double income;
  final double expense;
  final double balance;
  final int alertTotal;
  final int criticalAlerts;
  final int highAlerts;
  final int mediumAlerts;
  final int lowAlerts;
  final Map<String, int> alertsByArea;

  // V15 — indicadores executivos consolidados.
  final double pregnancyRatePercent;
  final int pregnantFemales;
  final int eligibleFemales;
  final double averageWeightKg;
  final double averageGmdKgDay;
  final double costPerActiveAnimal;
  final int criticalStockItems;
  final int openTasks;
  final int overdueTasks;
  final double nutritionMonthlyCost;

  final List<AtlasOperationalActionData> topActions;
  final List<AtlasOperationalAlertData> alerts;

  bool get hasCriticalAlerts => criticalAlerts > 0;
  bool get hasHighPriorityAlerts => criticalAlerts + highAlerts > 0;

  factory AtlasOperationalIntelligenceData.fromResponses({
    required Map<String, dynamic> summary,
    required Map<String, dynamic> alertsResponse,
  }) {
    final herd = _map(summary['herd']);
    final finance = _map(summary['finance']);
    final alertSummary = _map(summary['alerts']);
    final executive = _map(summary['executive']);
    final byAreaRaw = _map(alertSummary['by_area']);

    return AtlasOperationalIntelligenceData(
      farmId: summary['farm_id']?.toString() ?? '',
      generatedAt: _asDateTime(summary['generated_at']),
      operationalScore: _asInt(summary['operational_score']),
      operationalLevel: summary['operational_level']?.toString() ?? 'unknown',
      animals: _asInt(herd['animals']),
      activeAnimals: _asInt(herd['active_animals']),
      lots: _asInt(herd['lots']),
      income: _asDouble(finance['income']),
      expense: _asDouble(finance['expense']),
      balance: _asDouble(finance['balance']),
      alertTotal: _asInt(alertSummary['total']),
      criticalAlerts: _asInt(alertSummary['critical']),
      highAlerts: _asInt(alertSummary['high']),
      mediumAlerts: _asInt(alertSummary['medium']),
      lowAlerts: _asInt(alertSummary['low']),
      alertsByArea: byAreaRaw.map((key, value) => MapEntry(key, _asInt(value))),
      pregnancyRatePercent: _asDouble(executive['pregnancy_rate_percent']),
      pregnantFemales: _asInt(executive['pregnant_females']),
      eligibleFemales: _asInt(executive['eligible_females']),
      averageWeightKg: _asDouble(executive['average_weight_kg']),
      averageGmdKgDay: _asDouble(executive['average_gmd_kg_day']),
      costPerActiveAnimal: _asDouble(executive['cost_per_active_animal']),
      criticalStockItems: _asInt(executive['critical_stock_items']),
      openTasks: _asInt(executive['open_tasks']),
      overdueTasks: _asInt(executive['overdue_tasks']),
      nutritionMonthlyCost: _asDouble(executive['nutrition_monthly_cost']),
      topActions: _list(summary['top_actions'])
          .map(AtlasOperationalActionData.fromMap)
          .toList(growable: false),
      alerts: _list(alertsResponse['alerts'])
          .map(AtlasOperationalAlertData.fromMap)
          .toList(growable: false),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDateTime(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
