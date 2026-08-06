import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';

class AtlasCommandCenterActionAnalytics {
  const AtlasCommandCenterActionAnalytics({
    required this.generatedAt,
    required this.total,
    required this.open,
    required this.completed,
    required this.cancelled,
    required this.blocked,
    required this.overdue,
    required this.completionRatePercent,
    required this.averageCompletionHours,
    required this.byPriority,
    required this.byStatus,
    required this.byModule,
    required this.withResponsible,
    required this.averageProgressPercent,
    required this.expectedFinancialImpact,
    required this.executionHealthPercent,
  });

  final DateTime generatedAt;
  final int total;
  final int open;
  final int completed;
  final int cancelled;
  final int blocked;
  final int overdue;
  final double completionRatePercent;
  final double averageCompletionHours;
  final Map<AtlasCanonicalPriority, int> byPriority;
  final Map<AtlasCanonicalStatus, int> byStatus;
  final Map<String, int> byModule;
  final int withResponsible;
  final double averageProgressPercent;
  final double expectedFinancialImpact;
  final double executionHealthPercent;

  bool get hasData => total > 0;
}
