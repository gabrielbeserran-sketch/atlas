class ExecutiveDecisionData {
  const ExecutiveDecisionData({
    required this.generatedAt,
    required this.scopeLabel,
    required this.consultantScore,
    required this.priorityActions,
    required this.farmRiskRanking,
    required this.responsibleRiskRanking,
    required this.categoryRiskRanking,
    required this.predictions,
    required this.heatMapItems,
    required this.executiveAssistant,
    required this.summary,
  });

  final String generatedAt;
  final String scopeLabel;

  final ExecutiveDecisionScore consultantScore;

  final List<ExecutivePriorityAction> priorityActions;

  final List<ExecutiveDecisionRankingItem> farmRiskRanking;

  final List<ExecutiveDecisionRankingItem> responsibleRiskRanking;

  final List<ExecutiveDecisionRankingItem> categoryRiskRanking;

  final List<ExecutivePredictionData> predictions;

  final List<ExecutiveHeatMapItem> heatMapItems;

  final ExecutiveAssistantMessage executiveAssistant;

  final ExecutiveDecisionSummary summary;

  bool get hasCriticalDecisions {
    return priorityActions.any((item) {
      return item.priorityLevel == ExecutiveDecisionLevel.critical;
    });
  }

  bool get hasPredictions {
    return predictions.isNotEmpty;
  }

  bool get hasHeatMap {
    return heatMapItems.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt,
      'scopeLabel': scopeLabel,
      'consultantScore': consultantScore.toJson(),
      'priorityActions': priorityActions.map((item) {
        return item.toJson();
      }).toList(),
      'farmRiskRanking': farmRiskRanking.map((item) {
        return item.toJson();
      }).toList(),
      'responsibleRiskRanking': responsibleRiskRanking.map((item) {
        return item.toJson();
      }).toList(),
      'categoryRiskRanking': categoryRiskRanking.map((item) {
        return item.toJson();
      }).toList(),
      'predictions': predictions.map((item) {
        return item.toJson();
      }).toList(),
      'heatMapItems': heatMapItems.map((item) {
        return item.toJson();
      }).toList(),
      'executiveAssistant': executiveAssistant.toJson(),
      'summary': summary.toJson(),
    };
  }

  factory ExecutiveDecisionData.fromJson(Map<String, dynamic> json) {
    return ExecutiveDecisionData(
      generatedAt: json['generatedAt']?.toString() ?? '',
      scopeLabel: json['scopeLabel']?.toString() ?? '',
      consultantScore: ExecutiveDecisionScore.fromJson(
        Map<String, dynamic>.from(json['consultantScore'] as Map? ?? const {}),
      ),
      priorityActions: _parseList(
        json['priorityActions'],
        ExecutivePriorityAction.fromJson,
      ),
      farmRiskRanking: _parseList(
        json['farmRiskRanking'],
        ExecutiveDecisionRankingItem.fromJson,
      ),
      responsibleRiskRanking: _parseList(
        json['responsibleRiskRanking'],
        ExecutiveDecisionRankingItem.fromJson,
      ),
      categoryRiskRanking: _parseList(
        json['categoryRiskRanking'],
        ExecutiveDecisionRankingItem.fromJson,
      ),
      predictions: _parseList(
        json['predictions'],
        ExecutivePredictionData.fromJson,
      ),
      heatMapItems: _parseList(
        json['heatMapItems'],
        ExecutiveHeatMapItem.fromJson,
      ),
      executiveAssistant: ExecutiveAssistantMessage.fromJson(
        Map<String, dynamic>.from(
          json['executiveAssistant'] as Map? ?? const {},
        ),
      ),
      summary: ExecutiveDecisionSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
      ),
    );
  }
}

class ExecutiveDecisionScore {
  const ExecutiveDecisionScore({
    required this.value,
    required this.label,
    required this.level,
    required this.explanation,
    required this.components,
  });

  final double value;
  final String label;

  final ExecutiveDecisionLevel level;

  final String explanation;

  final List<ExecutiveScoreComponent> components;

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'level': level.name,
      'explanation': explanation,
      'components': components.map((item) {
        return item.toJson();
      }).toList(),
    };
  }

  factory ExecutiveDecisionScore.fromJson(Map<String, dynamic> json) {
    return ExecutiveDecisionScore(
      value: _parseDouble(json['value']),
      label: json['label']?.toString() ?? '',
      level: _parseEnum(
        ExecutiveDecisionLevel.values,
        json['level']?.toString(),
        ExecutiveDecisionLevel.normal,
      ),
      explanation: json['explanation']?.toString() ?? '',
      components: _parseList(
        json['components'],
        ExecutiveScoreComponent.fromJson,
      ),
    );
  }
}

class ExecutiveScoreComponent {
  const ExecutiveScoreComponent({
    required this.id,
    required this.title,
    required this.value,
    required this.weight,
    required this.weightedValue,
    required this.description,
  });

  final String id;
  final String title;

  final double value;
  final double weight;
  final double weightedValue;

  final String description;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'weight': weight,
      'weightedValue': weightedValue,
      'description': description,
    };
  }

  factory ExecutiveScoreComponent.fromJson(Map<String, dynamic> json) {
    return ExecutiveScoreComponent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      value: _parseDouble(json['value']),
      weight: _parseDouble(json['weight']),
      weightedValue: _parseDouble(json['weightedValue']),
      description: json['description']?.toString() ?? '',
    );
  }
}

class ExecutivePriorityAction {
  const ExecutivePriorityAction({
    required this.position,
    required this.actionId,
    required this.title,
    required this.description,
    required this.farmName,
    required this.responsible,
    required this.deadline,
    required this.category,
    required this.status,
    required this.priorityScore,
    required this.riskScore,
    required this.opportunityScore,
    required this.delayProbability,
    required this.estimatedImpact,
    required this.priorityLevel,
    required this.reasons,
    required this.recommendedAction,
  });

  final int position;

  final String actionId;
  final String title;
  final String description;

  final String farmName;
  final String responsible;
  final String deadline;
  final String category;
  final String status;

  final double priorityScore;
  final double riskScore;
  final double opportunityScore;
  final double delayProbability;
  final double estimatedImpact;

  final ExecutiveDecisionLevel priorityLevel;

  final List<String> reasons;
  final String recommendedAction;

  bool get isCritical {
    return priorityLevel == ExecutiveDecisionLevel.critical;
  }

  bool get isLikelyToDelay {
    return delayProbability >= 0.70;
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'actionId': actionId,
      'title': title,
      'description': description,
      'farmName': farmName,
      'responsible': responsible,
      'deadline': deadline,
      'category': category,
      'status': status,
      'priorityScore': priorityScore,
      'riskScore': riskScore,
      'opportunityScore': opportunityScore,
      'delayProbability': delayProbability,
      'estimatedImpact': estimatedImpact,
      'priorityLevel': priorityLevel.name,
      'reasons': reasons,
      'recommendedAction': recommendedAction,
    };
  }

  factory ExecutivePriorityAction.fromJson(Map<String, dynamic> json) {
    return ExecutivePriorityAction(
      position: _parseInt(json['position']),
      actionId: json['actionId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      farmName: json['farmName']?.toString() ?? '',
      responsible: json['responsible']?.toString() ?? '',
      deadline: json['deadline']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      priorityScore: _parseDouble(json['priorityScore']),
      riskScore: _parseDouble(json['riskScore']),
      opportunityScore: _parseDouble(json['opportunityScore']),
      delayProbability: _parseDouble(json['delayProbability']),
      estimatedImpact: _parseDouble(json['estimatedImpact']),
      priorityLevel: _parseEnum(
        ExecutiveDecisionLevel.values,
        json['priorityLevel']?.toString(),
        ExecutiveDecisionLevel.normal,
      ),
      reasons: _parseStringList(json['reasons']),
      recommendedAction: json['recommendedAction']?.toString() ?? '',
    );
  }
}

class ExecutiveDecisionRankingItem {
  const ExecutiveDecisionRankingItem({
    required this.position,
    required this.label,
    required this.riskScore,
    required this.opportunityScore,
    required this.openCount,
    required this.overdueCount,
    required this.urgentCount,
    required this.level,
    required this.explanation,
  });

  final int position;
  final String label;

  final double riskScore;
  final double opportunityScore;

  final int openCount;
  final int overdueCount;
  final int urgentCount;

  final ExecutiveDecisionLevel level;

  final String explanation;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'label': label,
      'riskScore': riskScore,
      'opportunityScore': opportunityScore,
      'openCount': openCount,
      'overdueCount': overdueCount,
      'urgentCount': urgentCount,
      'level': level.name,
      'explanation': explanation,
    };
  }

  factory ExecutiveDecisionRankingItem.fromJson(Map<String, dynamic> json) {
    return ExecutiveDecisionRankingItem(
      position: _parseInt(json['position']),
      label: json['label']?.toString() ?? '',
      riskScore: _parseDouble(json['riskScore']),
      opportunityScore: _parseDouble(json['opportunityScore']),
      openCount: _parseInt(json['openCount']),
      overdueCount: _parseInt(json['overdueCount']),
      urgentCount: _parseInt(json['urgentCount']),
      level: _parseEnum(
        ExecutiveDecisionLevel.values,
        json['level']?.toString(),
        ExecutiveDecisionLevel.normal,
      ),
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class ExecutivePredictionData {
  const ExecutivePredictionData({
    required this.id,
    required this.title,
    required this.description,
    required this.targetType,
    required this.targetLabel,
    required this.probability,
    required this.horizonDays,
    required this.level,
    required this.recommendedAction,
    required this.evidence,
  });

  final String id;
  final String title;
  final String description;

  final ExecutivePredictionTargetType targetType;

  final String targetLabel;

  final double probability;
  final int horizonDays;

  final ExecutiveDecisionLevel level;

  final String recommendedAction;
  final List<String> evidence;

  bool get isHighProbability {
    return probability >= 0.70;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetType': targetType.name,
      'targetLabel': targetLabel,
      'probability': probability,
      'horizonDays': horizonDays,
      'level': level.name,
      'recommendedAction': recommendedAction,
      'evidence': evidence,
    };
  }

  factory ExecutivePredictionData.fromJson(Map<String, dynamic> json) {
    return ExecutivePredictionData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      targetType: _parseEnum(
        ExecutivePredictionTargetType.values,
        json['targetType']?.toString(),
        ExecutivePredictionTargetType.action,
      ),
      targetLabel: json['targetLabel']?.toString() ?? '',
      probability: _parseDouble(json['probability']),
      horizonDays: _parseInt(json['horizonDays']),
      level: _parseEnum(
        ExecutiveDecisionLevel.values,
        json['level']?.toString(),
        ExecutiveDecisionLevel.normal,
      ),
      recommendedAction: json['recommendedAction']?.toString() ?? '',
      evidence: _parseStringList(json['evidence']),
    );
  }
}

class ExecutiveHeatMapItem {
  const ExecutiveHeatMapItem({
    required this.id,
    required this.label,
    required this.group,
    required this.score,
    required this.level,
    required this.openCount,
    required this.overdueCount,
    required this.urgentCount,
    required this.summary,
  });

  final String id;
  final String label;
  final String group;

  final double score;

  final ExecutiveDecisionLevel level;

  final int openCount;
  final int overdueCount;
  final int urgentCount;

  final String summary;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'group': group,
      'score': score,
      'level': level.name,
      'openCount': openCount,
      'overdueCount': overdueCount,
      'urgentCount': urgentCount,
      'summary': summary,
    };
  }

  factory ExecutiveHeatMapItem.fromJson(Map<String, dynamic> json) {
    return ExecutiveHeatMapItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      score: _parseDouble(json['score']),
      level: _parseEnum(
        ExecutiveDecisionLevel.values,
        json['level']?.toString(),
        ExecutiveDecisionLevel.normal,
      ),
      openCount: _parseInt(json['openCount']),
      overdueCount: _parseInt(json['overdueCount']),
      urgentCount: _parseInt(json['urgentCount']),
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class ExecutiveAssistantMessage {
  const ExecutiveAssistantMessage({
    required this.greeting,
    required this.headline,
    required this.message,
    required this.mainPriority,
    required this.secondaryPriority,
    required this.estimatedGain,
    required this.callToAction,
  });

  final String greeting;
  final String headline;
  final String message;

  final String mainPriority;
  final String secondaryPriority;

  final double estimatedGain;

  final String callToAction;

  Map<String, dynamic> toJson() {
    return {
      'greeting': greeting,
      'headline': headline,
      'message': message,
      'mainPriority': mainPriority,
      'secondaryPriority': secondaryPriority,
      'estimatedGain': estimatedGain,
      'callToAction': callToAction,
    };
  }

  factory ExecutiveAssistantMessage.fromJson(Map<String, dynamic> json) {
    return ExecutiveAssistantMessage(
      greeting: json['greeting']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      mainPriority: json['mainPriority']?.toString() ?? '',
      secondaryPriority: json['secondaryPriority']?.toString() ?? '',
      estimatedGain: _parseDouble(json['estimatedGain']),
      callToAction: json['callToAction']?.toString() ?? '',
    );
  }
}

class ExecutiveDecisionSummary {
  const ExecutiveDecisionSummary({
    required this.criticalActionCount,
    required this.highRiskFarmCount,
    required this.highRiskResponsibleCount,
    required this.predictedDelayCount,
    required this.totalEstimatedImpact,
    required this.averagePriorityScore,
    required this.averageRiskScore,
    required this.averageOpportunityScore,
  });

  final int criticalActionCount;
  final int highRiskFarmCount;
  final int highRiskResponsibleCount;
  final int predictedDelayCount;

  final double totalEstimatedImpact;

  final double averagePriorityScore;
  final double averageRiskScore;
  final double averageOpportunityScore;

  Map<String, dynamic> toJson() {
    return {
      'criticalActionCount': criticalActionCount,
      'highRiskFarmCount': highRiskFarmCount,
      'highRiskResponsibleCount': highRiskResponsibleCount,
      'predictedDelayCount': predictedDelayCount,
      'totalEstimatedImpact': totalEstimatedImpact,
      'averagePriorityScore': averagePriorityScore,
      'averageRiskScore': averageRiskScore,
      'averageOpportunityScore': averageOpportunityScore,
    };
  }

  factory ExecutiveDecisionSummary.fromJson(Map<String, dynamic> json) {
    return ExecutiveDecisionSummary(
      criticalActionCount: _parseInt(json['criticalActionCount']),
      highRiskFarmCount: _parseInt(json['highRiskFarmCount']),
      highRiskResponsibleCount: _parseInt(json['highRiskResponsibleCount']),
      predictedDelayCount: _parseInt(json['predictedDelayCount']),
      totalEstimatedImpact: _parseDouble(json['totalEstimatedImpact']),
      averagePriorityScore: _parseDouble(json['averagePriorityScore']),
      averageRiskScore: _parseDouble(json['averageRiskScore']),
      averageOpportunityScore: _parseDouble(json['averageOpportunityScore']),
    );
  }
}

enum ExecutiveDecisionLevel { excellent, good, normal, attention, critical }

enum ExecutivePredictionTargetType {
  action,
  farm,
  responsible,
  category,
  indicator,
}

List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) {
    return [];
  }

  return value.whereType<Map>().map((item) {
    return parser(Map<String, dynamic>.from(item));
  }).toList();
}

List<String> _parseStringList(dynamic value) {
  if (value is! List) {
    return [];
  }

  return value.map((item) {
    return item.toString();
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
