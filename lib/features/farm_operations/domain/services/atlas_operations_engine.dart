import '../models/atlas_farm_operation.dart';

class AtlasOperationsSummary {
  const AtlasOperationsSummary({
    required this.total,
    required this.today,
    required this.inProgress,
    required this.completed,
    required this.overdue,
    required this.plannedCost,
    required this.actualCost,
    required this.averageProgress,
  });
  final int total, today, inProgress, completed, overdue;
  final double plannedCost, actualCost, averageProgress;
}

class AtlasOperationsEngine {
  const AtlasOperationsEngine();
  AtlasOperationsSummary summarize(List<AtlasFarmOperation> items) {
    final now = DateTime.now();
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final planned = items.fold<double>(0, (s, e) => s + e.plannedCost);
    final actual = items.fold<double>(0, (s, e) => s + e.actualCost);
    final progress = items.isEmpty
        ? 0.0
        : items.fold<double>(0, (s, e) => s + e.progress) / items.length;
    return AtlasOperationsSummary(
      total: items.length,
      today: items.where((e) => sameDay(e.scheduledAt, now)).length,
      inProgress: items
          .where((e) => e.status == AtlasOperationStatus.inProgress)
          .length,
      completed: items
          .where((e) => e.status == AtlasOperationStatus.completed)
          .length,
      overdue: items.where((e) => e.isOverdue).length,
      plannedCost: planned,
      actualCost: actual,
      averageProgress: progress,
    );
  }
}
