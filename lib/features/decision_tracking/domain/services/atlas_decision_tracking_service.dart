import 'package:projeto_atlas/features/decision_engine/domain/models/atlas_decision_engine_data.dart';
import 'package:projeto_atlas/features/decision_tracking/domain/models/atlas_decision_tracking_data.dart';

class AtlasDecisionTrackingService {
  const AtlasDecisionTrackingService();

  AtlasDecisionExecution approve({
    required AtlasDecisionRecommendation decision,
    DateTime? approvedAt,
  }) {
    final currentTime = approvedAt ?? DateTime.now();

    return AtlasDecisionExecution(
      id:
          'execution_${decision.id}_${currentTime.millisecondsSinceEpoch}',
      decisionId: decision.id,
      farmName: decision.farmName,
      title: decision.title,
      description: decision.description,
      category: decision.category,
      priority: decision.priority,
      status:
          AtlasDecisionExecutionStatus.approved,
      approvedAt: currentTime,
      startedAt: null,
      deadline: currentTime.add(
        Duration(days: decision.deadlineDays),
      ),
      completedAt: null,
      progressPercent: 0,
      expectedFinancialImpact:
          decision.expectedFinancialImpact,
      realizedFinancialImpact: 0,
      expectedResult: decision.expectedResult,
      resultSummary: '',
      steps: decision.executionPlan.map((step) {
        return AtlasDecisionExecutionStepState(
          position: step.position,
          title: step.title,
          description: step.description,
          deadlineDays: step.deadlineDays,
          expectedResult: step.expectedResult,
          completed: false,
          completedAt: null,
          responsibleName: step.responsibleName,
        );
      }).toList(),
      measurements: const [],
      notes: '',
    );
  }

  AtlasDecisionExecution start({
    required AtlasDecisionExecution execution,
    DateTime? startedAt,
  }) {
    return execution.copyWith(
      status:
          AtlasDecisionExecutionStatus.inProgress,
      startedAt: startedAt ?? DateTime.now(),
    );
  }

  AtlasDecisionExecution toggleStep({
    required AtlasDecisionExecution execution,
    required int position,
    DateTime? changedAt,
  }) {
    final currentTime = changedAt ?? DateTime.now();

    final steps = execution.steps.map((step) {
      if (step.position != position) {
        return step;
      }

      final completed = !step.completed;

      return step.copyWith(
        completed: completed,
        completedAt:
            completed ? currentTime : null,
      );
    }).toList();

    final completedCount = steps.where((step) {
      return step.completed;
    }).length;

    final progress = steps.isEmpty
        ? 0.0
        : completedCount / steps.length * 100;

    final allCompleted =
        steps.isNotEmpty &&
            completedCount == steps.length;

    return execution.copyWith(
      steps: steps,
      progressPercent:
          progress.clamp(0.0, 100.0).toDouble(),
      status: allCompleted
          ? AtlasDecisionExecutionStatus.completed
          : AtlasDecisionExecutionStatus.inProgress,
      completedAt:
          allCompleted ? currentTime : null,
    );
  }

  AtlasDecisionExecution addMeasurement({
    required AtlasDecisionExecution execution,
    required AtlasDecisionMeasurement measurement,
  }) {
    final measurements = [
      ...execution.measurements,
      measurement,
    ]..sort(
        (first, second) =>
            first.recordedAt.compareTo(
          second.recordedAt,
        ),
      );

    return execution.copyWith(
      measurements: measurements,
    );
  }

  AtlasDecisionExecution registerResult({
    required AtlasDecisionExecution execution,
    required double realizedFinancialImpact,
    required String resultSummary,
    DateTime? completedAt,
  }) {
    return execution.copyWith(
      status:
          AtlasDecisionExecutionStatus.completed,
      completedAt: completedAt ?? DateTime.now(),
      progressPercent: 100,
      realizedFinancialImpact:
          realizedFinancialImpact,
      resultSummary: resultSummary,
    );
  }

  AtlasDecisionExecution updateDelayStatus({
    required AtlasDecisionExecution execution,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (execution.status ==
            AtlasDecisionExecutionStatus.completed ||
        execution.status ==
            AtlasDecisionExecutionStatus.cancelled) {
      return execution;
    }

    if (currentTime.isAfter(execution.deadline)) {
      return execution.copyWith(
        status:
            AtlasDecisionExecutionStatus.delayed,
      );
    }

    return execution;
  }

  AtlasDecisionTrackingData buildSummary({
    required List<AtlasDecisionExecution>
        executions,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final normalized = executions.map((item) {
      return updateDelayStatus(
        execution: item,
        now: currentTime,
      );
    }).toList();

    final expectedImpact =
        normalized.fold<double>(
      0,
      (sum, item) =>
          sum + item.expectedFinancialImpact,
    );

    final realizedImpact =
        normalized.fold<double>(
      0,
      (sum, item) =>
          sum + item.realizedFinancialImpact,
    );

    final activeCount =
        normalized.where((item) {
      return item.status ==
              AtlasDecisionExecutionStatus
                  .approved ||
          item.status ==
              AtlasDecisionExecutionStatus
                  .inProgress ||
          item.status ==
              AtlasDecisionExecutionStatus
                  .delayed;
    }).length;

    final completedCount =
        normalized.where((item) {
      return item.status ==
          AtlasDecisionExecutionStatus.completed;
    }).length;

    final executionRate = normalized.isEmpty
        ? 0.0
        : completedCount /
            normalized.length *
            100;

    final successfulCount =
        normalized.where((item) {
      return item.status ==
              AtlasDecisionExecutionStatus
                  .completed &&
          item.financialAchievementPercent >= 80;
    }).length;

    final successRate = completedCount == 0
        ? 0.0
        : successfulCount /
            completedCount *
            100;

    return AtlasDecisionTrackingData(
      generatedAt: currentTime,
      summary:
          'O acompanhamento possui ${normalized.length} decisões, '
          '$activeCount em execução, $completedCount concluídas, '
          '${executionRate.toStringAsFixed(0)}% de taxa de execução e '
          '${successRate.toStringAsFixed(0)}% de sucesso financeiro.',
      executions: normalized,
      totalExpectedImpact: expectedImpact,
      totalRealizedImpact: realizedImpact,
      executionRatePercent:
          executionRate
              .clamp(0.0, 100.0)
              .toDouble(),
      successRatePercent:
          successRate
              .clamp(0.0, 100.0)
              .toDouble(),
    );
  }
}
