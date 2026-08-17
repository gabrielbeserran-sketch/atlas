import 'package:projeto_atlas/features/decision_intelligence_lab/domain/models/atlas_decision_scenario.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasStrategyExecutionPlan {
  const AtlasStrategyExecutionPlan({
    required this.id,
    required this.sourceScenarioId,
    required this.farmId,
    required this.farmName,
    required this.title,
    required this.description,
    required this.area,
    required this.createdAt,
    required this.startDate,
    required this.targetDate,
    required this.budget,
    required this.expectedNetGain,
    required this.expectedRoi,
    required this.confidence,
    required this.risk,
    required this.owner,
    required this.status,
    required this.phases,
    required this.gates,
  });

  final String id;
  final String sourceScenarioId;
  final String farmId;
  final String farmName;
  final String title;
  final String description;
  final AtlasFarmAuditArea area;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime targetDate;
  final double budget;
  final double expectedNetGain;
  final double expectedRoi;
  final double confidence;
  final AtlasDecisionRisk risk;
  final String owner;
  final AtlasStrategyExecutionStatus status;
  final List<AtlasStrategyExecutionPhase> phases;
  final List<AtlasStrategyDecisionGate> gates;

  int get totalMilestones {
    return phases.fold<int>(0, (sum, phase) => sum + phase.milestones.length);
  }

  int get completedMilestones {
    return phases.fold<int>(
      0,
      (sum, phase) =>
          sum +
          phase.milestones
              .where(
                (milestone) =>
                    milestone.status == AtlasStrategyMilestoneStatus.completed,
              )
              .length,
    );
  }

  double get progressPercent {
    if (totalMilestones == 0) {
      return 0;
    }

    return completedMilestones / totalMilestones * 100;
  }

  double get committedBudget {
    return phases.fold<double>(0, (sum, phase) => sum + phase.budget);
  }

  AtlasStrategyExecutionPlan copyWith({
    AtlasStrategyExecutionStatus? status,
    List<AtlasStrategyExecutionPhase>? phases,
    List<AtlasStrategyDecisionGate>? gates,
  }) {
    return AtlasStrategyExecutionPlan(
      id: id,
      sourceScenarioId: sourceScenarioId,
      farmId: farmId,
      farmName: farmName,
      title: title,
      description: description,
      area: area,
      createdAt: createdAt,
      startDate: startDate,
      targetDate: targetDate,
      budget: budget,
      expectedNetGain: expectedNetGain,
      expectedRoi: expectedRoi,
      confidence: confidence,
      risk: risk,
      owner: owner,
      status: status ?? this.status,
      phases: phases ?? this.phases,
      gates: gates ?? this.gates,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sourceScenarioId': sourceScenarioId,
      'farmId': farmId,
      'farmName': farmName,
      'title': title,
      'description': description,
      'area': area.name,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'budget': budget,
      'expectedNetGain': expectedNetGain,
      'expectedRoi': expectedRoi,
      'confidence': confidence,
      'risk': risk.name,
      'owner': owner,
      'status': status.name,
      'phases': phases.map((item) => item.toJson()).toList(),
      'gates': gates.map((item) => item.toJson()).toList(),
    };
  }

  factory AtlasStrategyExecutionPlan.fromJson(Map<String, dynamic> json) {
    return AtlasStrategyExecutionPlan(
      id: json['id'] as String? ?? '',
      sourceScenarioId: json['sourceScenarioId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Fazenda',
      title: json['title'] as String? ?? 'Plano estratégico',
      description: json['description'] as String? ?? '',
      area: AtlasFarmAuditArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasFarmAuditArea.operational,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      targetDate:
          DateTime.tryParse(json['targetDate'] as String? ?? '') ??
          DateTime.now(),
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      expectedNetGain: (json['expectedNetGain'] as num?)?.toDouble() ?? 0,
      expectedRoi: (json['expectedRoi'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      risk: AtlasDecisionRisk.values.firstWhere(
        (item) => item.name == json['risk'],
        orElse: () => AtlasDecisionRisk.moderate,
      ),
      owner: json['owner'] as String? ?? 'Gestor da fazenda',
      status: AtlasStrategyExecutionStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => AtlasStrategyExecutionStatus.planned,
      ),
      phases: (json['phases'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => AtlasStrategyExecutionPhase.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      gates: (json['gates'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => AtlasStrategyDecisionGate.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class AtlasStrategyExecutionPhase {
  const AtlasStrategyExecutionPhase({
    required this.id,
    required this.title,
    required this.objective,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.responsible,
    required this.milestones,
  });

  final String id;
  final String title;
  final String objective;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final String responsible;
  final List<AtlasStrategyMilestone> milestones;

  AtlasStrategyExecutionPhase copyWith({
    List<AtlasStrategyMilestone>? milestones,
  }) {
    return AtlasStrategyExecutionPhase(
      id: id,
      title: title,
      objective: objective,
      startDate: startDate,
      endDate: endDate,
      budget: budget,
      responsible: responsible,
      milestones: milestones ?? this.milestones,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'objective': objective,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'responsible': responsible,
      'milestones': milestones.map((item) => item.toJson()).toList(),
    };
  }

  factory AtlasStrategyExecutionPhase.fromJson(Map<String, dynamic> json) {
    return AtlasStrategyExecutionPhase(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      responsible: json['responsible'] as String? ?? 'Equipe da fazenda',
      milestones: (json['milestones'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => AtlasStrategyMilestone.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class AtlasStrategyMilestone {
  const AtlasStrategyMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.successCriterion,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String successCriterion;
  final AtlasStrategyMilestoneStatus status;

  AtlasStrategyMilestone copyWith({AtlasStrategyMilestoneStatus? status}) {
    return AtlasStrategyMilestone(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      successCriterion: successCriterion,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'successCriterion': successCriterion,
      'status': status.name,
    };
  }

  factory AtlasStrategyMilestone.fromJson(Map<String, dynamic> json) {
    return AtlasStrategyMilestone(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      successCriterion: json['successCriterion'] as String? ?? '',
      status: AtlasStrategyMilestoneStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => AtlasStrategyMilestoneStatus.pending,
      ),
    );
  }
}

class AtlasStrategyDecisionGate {
  const AtlasStrategyDecisionGate({
    required this.id,
    required this.title,
    required this.reviewDate,
    required this.criteria,
    required this.decision,
  });

  final String id;
  final String title;
  final DateTime reviewDate;
  final List<String> criteria;
  final AtlasStrategyGateDecision decision;

  AtlasStrategyDecisionGate copyWith({AtlasStrategyGateDecision? decision}) {
    return AtlasStrategyDecisionGate(
      id: id,
      title: title,
      reviewDate: reviewDate,
      criteria: criteria,
      decision: decision ?? this.decision,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'reviewDate': reviewDate.toIso8601String(),
      'criteria': criteria,
      'decision': decision.name,
    };
  }

  factory AtlasStrategyDecisionGate.fromJson(Map<String, dynamic> json) {
    return AtlasStrategyDecisionGate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      reviewDate:
          DateTime.tryParse(json['reviewDate'] as String? ?? '') ??
          DateTime.now(),
      criteria: (json['criteria'] as List? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      decision: AtlasStrategyGateDecision.values.firstWhere(
        (item) => item.name == json['decision'],
        orElse: () => AtlasStrategyGateDecision.pending,
      ),
    );
  }
}

enum AtlasStrategyExecutionStatus {
  planned,
  active,
  paused,
  completed,
  cancelled,
}

enum AtlasStrategyMilestoneStatus { pending, inProgress, completed, blocked }

enum AtlasStrategyGateDecision { pending, go, adjust, hold, stop }

String atlasStrategyExecutionStatusLabel(AtlasStrategyExecutionStatus status) {
  switch (status) {
    case AtlasStrategyExecutionStatus.planned:
      return 'Planejado';
    case AtlasStrategyExecutionStatus.active:
      return 'Em execução';
    case AtlasStrategyExecutionStatus.paused:
      return 'Pausado';
    case AtlasStrategyExecutionStatus.completed:
      return 'Concluído';
    case AtlasStrategyExecutionStatus.cancelled:
      return 'Cancelado';
  }
}

String atlasStrategyMilestoneStatusLabel(AtlasStrategyMilestoneStatus status) {
  switch (status) {
    case AtlasStrategyMilestoneStatus.pending:
      return 'Pendente';
    case AtlasStrategyMilestoneStatus.inProgress:
      return 'Em andamento';
    case AtlasStrategyMilestoneStatus.completed:
      return 'Concluído';
    case AtlasStrategyMilestoneStatus.blocked:
      return 'Bloqueado';
  }
}

String atlasStrategyGateDecisionLabel(AtlasStrategyGateDecision decision) {
  switch (decision) {
    case AtlasStrategyGateDecision.pending:
      return 'Pendente';
    case AtlasStrategyGateDecision.go:
      return 'Avançar';
    case AtlasStrategyGateDecision.adjust:
      return 'Ajustar';
    case AtlasStrategyGateDecision.hold:
      return 'Aguardar';
    case AtlasStrategyGateDecision.stop:
      return 'Interromper';
  }
}
