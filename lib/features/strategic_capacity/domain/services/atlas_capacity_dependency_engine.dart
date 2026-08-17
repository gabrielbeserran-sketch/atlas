import 'package:projeto_atlas/features/strategic_capacity/domain/models/atlas_capacity_dependency.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';

class AtlasCapacityDependencyEngine {
  const AtlasCapacityDependencyEngine();

  AtlasCapacityAssessment assess({
    required List<AtlasStrategyExecutionPlan> plans,
    double availableWeeklyHours = 160,
  }) {
    final activePlans = plans
        .where(
          (plan) =>
              plan.status == AtlasStrategyExecutionStatus.active ||
              plan.status == AtlasStrategyExecutionStatus.planned ||
              plan.status == AtlasStrategyExecutionStatus.paused,
        )
        .toList();

    final items =
        activePlans.map((plan) {
          final remainingMilestones = plan.phases.fold<int>(
            0,
            (sum, phase) =>
                sum +
                phase.milestones
                    .where(
                      (milestone) =>
                          milestone.status !=
                          AtlasStrategyMilestoneStatus.completed,
                    )
                    .length,
          );

          final remainingDays = plan.targetDate
              .difference(DateTime.now())
              .inDays
              .clamp(1, 10000);

          final requiredHours =
              (remainingMilestones * 6 +
                      plan.gates
                              .where(
                                (gate) =>
                                    gate.decision ==
                                    AtlasStrategyGateDecision.pending,
                              )
                              .length *
                          4 +
                      _riskLoad(plan) +
                      _deadlinePressure(remainingDays))
                  .clamp(0.0, 300.0)
                  .toDouble();

          final teamLoadPercent = availableWeeklyHours <= 0
              ? 100.0
              : requiredHours / availableWeeklyHours * 100;

          final overloaded =
              teamLoadPercent > 35 ||
              remainingMilestones >= 8 ||
              remainingDays < 30 && remainingMilestones >= 4;

          return AtlasCapacityItem(
            plan: plan,
            requiredHours: requiredHours,
            teamLoadPercent: teamLoadPercent,
            remainingMilestones: remainingMilestones,
            remainingDays: remainingDays,
            overloaded: overloaded,
            recommendation: _recommendation(
              overloaded: overloaded,
              teamLoadPercent: teamLoadPercent,
              remainingMilestones: remainingMilestones,
              remainingDays: remainingDays,
            ),
          );
        }).toList()..sort(
          (first, second) =>
              second.teamLoadPercent.compareTo(first.teamLoadPercent),
        );

    final dependencies = _dependencies(activePlans);
    final conflicts = _conflicts(plans: activePlans, items: items);

    return AtlasCapacityAssessment(
      generatedAt: DateTime.now(),
      items: items,
      dependencies: dependencies,
      conflicts: conflicts,
      totalCapacityDemand: items.fold<double>(
        0,
        (sum, item) => sum + item.requiredHours,
      ),
      availableCapacity: availableWeeklyHours,
    );
  }

  double _riskLoad(AtlasStrategyExecutionPlan plan) {
    switch (plan.risk.name) {
      case 'low':
        return 4;
      case 'moderate':
        return 10;
      case 'high':
        return 20;
      case 'critical':
        return 30;
    }

    return 10;
  }

  double _deadlinePressure(int remainingDays) {
    if (remainingDays <= 15) {
      return 30;
    }

    if (remainingDays <= 30) {
      return 20;
    }

    if (remainingDays <= 60) {
      return 10;
    }

    return 4;
  }

  String _recommendation({
    required bool overloaded,
    required double teamLoadPercent,
    required int remainingMilestones,
    required int remainingDays,
  }) {
    if (!overloaded) {
      return 'Capacidade compatível com a execução atual.';
    }

    if (remainingDays < 30) {
      return 'Reduzir o escopo imediato e priorizar apenas os marcos críticos.';
    }

    if (teamLoadPercent > 50) {
      return 'Redistribuir responsáveis ou pausar uma estratégia concorrente.';
    }

    if (remainingMilestones >= 8) {
      return 'Dividir a estratégia em ondas menores de execução.';
    }

    return 'Revisar capacidade semanal e disponibilidade da equipe.';
  }

  List<AtlasStrategyDependency> _dependencies(
    List<AtlasStrategyExecutionPlan> plans,
  ) {
    final dependencies = <AtlasStrategyDependency>[];

    for (final successor in plans) {
      for (final predecessor in plans) {
        if (predecessor.id == successor.id) {
          continue;
        }

        final relatedArea = predecessor.area == successor.area;
        final dateOverlap = predecessor.targetDate.isAfter(successor.startDate);

        if (!relatedArea || !dateOverlap) {
          continue;
        }

        final predecessorComplete =
            predecessor.status == AtlasStrategyExecutionStatus.completed;

        final predecessorPaused =
            predecessor.status == AtlasStrategyExecutionStatus.paused ||
            predecessor.status == AtlasStrategyExecutionStatus.cancelled;

        dependencies.add(
          AtlasStrategyDependency(
            id: 'dependency_${predecessor.id}_${successor.id}',
            predecessorPlanId: predecessor.id,
            predecessorTitle: predecessor.title,
            successorPlanId: successor.id,
            successorTitle: successor.title,
            reason:
                'As duas estratégias atuam na mesma área e possuem cronogramas sobrepostos.',
            status: predecessorComplete
                ? AtlasStrategyDependencyStatus.satisfied
                : predecessorPaused
                ? AtlasStrategyDependencyStatus.blocked
                : AtlasStrategyDependencyStatus.pending,
          ),
        );
      }
    }

    return dependencies;
  }

  List<AtlasCapacityConflict> _conflicts({
    required List<AtlasStrategyExecutionPlan> plans,
    required List<AtlasCapacityItem> items,
  }) {
    final conflicts = <AtlasCapacityConflict>[];

    final overloaded = items.where((item) => item.overloaded).toList();

    if (overloaded.length >= 2) {
      conflicts.add(
        AtlasCapacityConflict(
          id: 'conflict_overload',
          title: 'Sobrecarga simultânea da equipe',
          description:
              '${overloaded.length} estratégias exigem capacidade elevada ao mesmo tempo.',
          planIds: overloaded.map((item) => item.plan.id).toList(),
          severity: overloaded.length >= 4
              ? AtlasCapacityConflictSeverity.critical
              : AtlasCapacityConflictSeverity.high,
          recommendation:
              'Priorizar por valor e risco, redistribuir responsáveis e escalonar cronogramas.',
        ),
      );
    }

    final budgetCompetition = plans.where((plan) => plan.budget >= 100000);

    if (budgetCompetition.length >= 2) {
      conflicts.add(
        AtlasCapacityConflict(
          id: 'conflict_budget',
          title: 'Concorrência por capital',
          description:
              'Múltiplas estratégias de alto investimento estão em execução simultânea.',
          planIds: budgetCompetition.map((item) => item.id).toList(),
          severity: AtlasCapacityConflictSeverity.high,
          recommendation:
              'Definir limite mensal de desembolso e liberar capital por gates.',
        ),
      );
    }

    for (var firstIndex = 0; firstIndex < plans.length; firstIndex++) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < plans.length;
        secondIndex++
      ) {
        final first = plans[firstIndex];
        final second = plans[secondIndex];

        final overlap =
            first.startDate.isBefore(second.targetDate) &&
            second.startDate.isBefore(first.targetDate);

        final sameOwner =
            first.owner.trim().toLowerCase() ==
            second.owner.trim().toLowerCase();

        if (overlap && sameOwner) {
          conflicts.add(
            AtlasCapacityConflict(
              id: 'conflict_owner_${first.id}_${second.id}',
              title: 'Responsável compartilhado',
              description:
                  '${first.owner} está alocado simultaneamente em "${first.title}" e "${second.title}".',
              planIds: <String>[first.id, second.id],
              severity: AtlasCapacityConflictSeverity.moderate,
              recommendation:
                  'Nomear líderes operacionais distintos ou escalonar as entregas.',
            ),
          );
        }
      }
    }

    return conflicts;
  }
}
