import 'atlas_execution_plan.dart';

class AtlasExecutionAlert {
  const AtlasExecutionAlert({
    required this.title,
    required this.message,
    required this.severity,
  });
  final String title;
  final String message;
  final AtlasExecutionPriority severity;
}

class AtlasExecutionAnalysis {
  const AtlasExecutionAnalysis({
    required this.progress,
    required this.spi,
    required this.cpi,
    required this.plannedCost,
    required this.actualCost,
    required this.completed,
    required this.delayed,
    required this.blocked,
    required this.criticalPath,
    required this.alerts,
  });
  final double progress;
  final double spi;
  final double cpi;
  final double plannedCost;
  final double actualCost;
  final int completed;
  final int delayed;
  final int blocked;
  final List<AtlasExecutionTask> criticalPath;
  final List<AtlasExecutionAlert> alerts;
}
