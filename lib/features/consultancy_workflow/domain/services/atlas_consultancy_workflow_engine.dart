import 'package:projeto_atlas/features/consultancy_workflow/domain/models/atlas_consultancy_case.dart';

class AtlasConsultancyWorkflowSummary {
  const AtlasConsultancyWorkflowSummary({
    required this.totalCases,
    required this.activeCases,
    required this.completedCases,
    required this.pendingActions,
    required this.overdueActions,
    required this.upcomingVisits,
    required this.executionRate,
  });

  final int totalCases;
  final int activeCases;
  final int completedCases;
  final int pendingActions;
  final int overdueActions;
  final int upcomingVisits;
  final double executionRate;
}

class AtlasConsultancyWorkflowEngine {
  const AtlasConsultancyWorkflowEngine();

  AtlasConsultancyWorkflowSummary summarize(List<AtlasConsultancyCase> cases) {
    final DateTime now = DateTime.now();
    final List<AtlasConsultancyAction> actions = cases
        .expand((item) => item.actions)
        .toList(growable: false);
    final int completedActions = actions.where((item) => item.completed).length;
    final int pendingActions = actions.where((item) => !item.completed).length;
    return AtlasConsultancyWorkflowSummary(
      totalCases: cases.length,
      activeCases: cases
          .where((item) => item.stage != AtlasConsultancyStage.completed)
          .length,
      completedCases: cases
          .where((item) => item.stage == AtlasConsultancyStage.completed)
          .length,
      pendingActions: pendingActions,
      overdueActions: actions
          .where((item) => !item.completed && item.deadline.isBefore(now))
          .length,
      upcomingVisits: cases
          .expand((item) => item.visits)
          .where((item) => !item.completed && item.date.isAfter(now))
          .length,
      executionRate: actions.isEmpty ? 0 : completedActions / actions.length,
    );
  }
}
