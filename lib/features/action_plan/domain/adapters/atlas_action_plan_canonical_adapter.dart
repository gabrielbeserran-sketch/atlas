import 'package:projeto_atlas/core/contracts/atlas_action_contract.dart';
import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/contracts/atlas_decision_contract.dart';
import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

/// Adapta decisões canônicas para o plano operacional já existente.
///
/// Este adaptador não cria novas regras de inteligência. Ele apenas converte
/// decisões previamente classificadas pelo Decision Engine V2 em missões do
/// módulo Action Plan, preservando prioridade, prazo, impacto e origem.
class AtlasActionPlanCanonicalAdapter {
  const AtlasActionPlanCanonicalAdapter();

  AtlasActionPlan fromDecisions({
    required List<AtlasDecisionContract> decisions,
    required String farmId,
    required String farmName,
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();
    final farmDecisions = decisions
        .where((decision) =>
            decision.farmId == farmId ||
            (decision.farmId.isEmpty && decision.farmName == farmName))
        .toList()
      ..sort((a, b) {
        final byPriority =
            _priorityWeight(b.priority).compareTo(_priorityWeight(a.priority));
        if (byPriority != 0) {
          return byPriority;
        }
        final byScore = b.decisionScore.compareTo(a.decisionScore);
        return byScore != 0 ? byScore : a.deadline.compareTo(b.deadline);
      });

    return AtlasActionPlan(
      id: 'canonical_action_plan_${farmId}_${now.microsecondsSinceEpoch}',
      farmId: farmId,
      farmName: farmName,
      auditId: 'canonical_decisions',
      createdAt: now,
      updatedAt: now,
      missions: farmDecisions.map(_decisionToMission).toList(),
    );
  }

  List<AtlasActionContract> toCanonicalActions(AtlasActionPlan plan) {
    return plan.missions
        .map((mission) => _missionToContract(plan, mission))
        .toList(growable: false);
  }

  AtlasActionMission _decisionToMission(AtlasDecisionContract decision) {
    return AtlasActionMission(
      id: 'mission_${decision.id}',
      title: decision.title,
      description: _missionDescription(decision),
      area: _areaFromText(decision.category),
      priority: _auditPriority(decision.priority),
      status: AtlasMissionStatus.pending,
      responsible: _responsible(_areaFromText(decision.category)),
      startDate: decision.generatedAt,
      dueDate: decision.deadline,
      expectedImpact: decision.expectedFinancialImpact,
      checklist: _decisionChecklist(decision),
    );
  }

  AtlasActionContract _missionToContract(
    AtlasActionPlan plan,
    AtlasActionMission mission,
  ) {
    return AtlasActionContract(
      id: mission.id,
      farmId: plan.farmId,
      farmName: plan.farmName,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
      title: mission.title,
      description: mission.description,
      area: atlasFarmAuditAreaLabel(mission.area),
      sourceModule: plan.auditId == 'canonical_decisions'
          ? 'decision_engine_v2'
          : 'farm_audit',
      sourceReferenceId: plan.auditId,
      priority: _canonicalPriority(mission.priority),
      horizon: _horizonFromDueDate(mission.dueDate),
      status: _canonicalStatus(mission.status),
      responsible: mission.responsible,
      startDate: mission.startDate,
      dueDate: mission.dueDate,
      expectedImpact: mission.expectedImpact,
      expectedFinancialImpact: mission.expectedImpact,
      checklist: mission.checklist
          .map(
            (item) => AtlasActionChecklistContract(
              id: item.id,
              title: item.title,
              completed: item.completed,
            ),
          )
          .toList(growable: false),
      completedAt: mission.completedAt,
    );
  }

  String _missionDescription(AtlasDecisionContract decision) {
    final parts = <String>[
      decision.description,
      if (decision.reasoning.trim().isNotEmpty)
        'Justificativa: ${decision.reasoning}',
      if (decision.expectedResult.trim().isNotEmpty)
        'Resultado esperado: ${decision.expectedResult}',
    ];
    return parts.join('\n\n');
  }

  List<AtlasMissionChecklistItem> _decisionChecklist(
    AtlasDecisionContract decision,
  ) {
    final items = <String>[
      'Confirmar responsável e recursos necessários',
      ...decision.dependencies.map((item) => 'Validar dependência: $item'),
      'Executar a decisão priorizada',
      'Registrar evidências da execução',
      'Reavaliar o resultado alcançado',
    ];

    return List.generate(
      items.length,
      (index) => AtlasMissionChecklistItem(
        id: '${decision.id}_checklist_$index',
        title: items[index],
        completed: false,
      ),
      growable: false,
    );
  }

  AtlasFarmAuditArea _areaFromText(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('sanit') || normalized.contains('saúde')) {
      return AtlasFarmAuditArea.sanitary;
    }
    if (normalized.contains('reprodu')) {
      return AtlasFarmAuditArea.reproduction;
    }
    if (normalized.contains('nutri')) {
      return AtlasFarmAuditArea.nutrition;
    }
    if (normalized.contains('pasto') || normalized.contains('pastag')) {
      return AtlasFarmAuditArea.pastures;
    }
    if (normalized.contains('financ') || normalized.contains('custo')) {
      return AtlasFarmAuditArea.financial;
    }
    if (normalized.contains('estoque') || normalized.contains('invent')) {
      return AtlasFarmAuditArea.inventory;
    }
    if (normalized.contains('genét')) {
      return AtlasFarmAuditArea.genetics;
    }
    if (normalized.contains('bem-estar')) {
      return AtlasFarmAuditArea.animalWelfare;
    }
    if (normalized.contains('biosseg')) {
      return AtlasFarmAuditArea.biosecurity;
    }
    if (normalized.contains('pessoa') || normalized.contains('equipe')) {
      return AtlasFarmAuditArea.people;
    }
    if (normalized.contains('sustent')) {
      return AtlasFarmAuditArea.sustainability;
    }
    return AtlasFarmAuditArea.operational;
  }

  AtlasFarmAuditPriority _auditPriority(AtlasCanonicalPriority value) {
    switch (value) {
      case AtlasCanonicalPriority.low:
        return AtlasFarmAuditPriority.low;
      case AtlasCanonicalPriority.medium:
        return AtlasFarmAuditPriority.moderate;
      case AtlasCanonicalPriority.high:
        return AtlasFarmAuditPriority.high;
      case AtlasCanonicalPriority.critical:
        return AtlasFarmAuditPriority.critical;
    }
  }

  AtlasCanonicalPriority _canonicalPriority(AtlasFarmAuditPriority value) {
    switch (value) {
      case AtlasFarmAuditPriority.low:
        return AtlasCanonicalPriority.low;
      case AtlasFarmAuditPriority.moderate:
        return AtlasCanonicalPriority.medium;
      case AtlasFarmAuditPriority.high:
        return AtlasCanonicalPriority.high;
      case AtlasFarmAuditPriority.critical:
        return AtlasCanonicalPriority.critical;
    }
  }

  AtlasCanonicalStatus _canonicalStatus(AtlasMissionStatus value) {
    switch (value) {
      case AtlasMissionStatus.pending:
        return AtlasCanonicalStatus.pending;
      case AtlasMissionStatus.inProgress:
        return AtlasCanonicalStatus.inProgress;
      case AtlasMissionStatus.completed:
        return AtlasCanonicalStatus.completed;
      case AtlasMissionStatus.cancelled:
        return AtlasCanonicalStatus.cancelled;
    }
  }

  AtlasCanonicalHorizon _horizonFromDueDate(DateTime dueDate) {
    final difference = dueDate.difference(DateTime.now()).inDays;
    if (difference <= 1) {
      return AtlasCanonicalHorizon.today;
    }
    if (difference <= 7) {
      return AtlasCanonicalHorizon.week;
    }
    if (difference <= 30) {
      return AtlasCanonicalHorizon.month;
    }
    if (difference <= 90) {
      return AtlasCanonicalHorizon.quarter;
    }
    return AtlasCanonicalHorizon.longTerm;
  }

  int _priorityWeight(AtlasCanonicalPriority priority) {
    switch (priority) {
      case AtlasCanonicalPriority.low:
        return 1;
      case AtlasCanonicalPriority.medium:
        return 2;
      case AtlasCanonicalPriority.high:
        return 3;
      case AtlasCanonicalPriority.critical:
        return 4;
    }
  }

  String _responsible(AtlasFarmAuditArea area) {
    switch (area) {
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.reproduction:
      case AtlasFarmAuditArea.biosecurity:
      case AtlasFarmAuditArea.animalWelfare:
        return 'Médico-veterinário';
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.pastures:
        return 'Responsável técnico';
      case AtlasFarmAuditArea.financial:
      case AtlasFarmAuditArea.inventory:
        return 'Gestor da fazenda';
      default:
        return 'Equipe operacional';
    }
  }
}

extension AtlasActionPlanCanonicalExtension on AtlasActionPlan {
  List<AtlasActionContract> toCanonicalActions() {
    return const AtlasActionPlanCanonicalAdapter().toCanonicalActions(this);
  }
}
