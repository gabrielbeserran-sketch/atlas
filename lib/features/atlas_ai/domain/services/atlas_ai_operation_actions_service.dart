import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_operation_actions.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasAiOperationActionsService {
  const AtlasAiOperationActionsService();

  AtlasAiOperationActions build({
    required List<AtlasAiTrackedAction> actions,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final progress = _buildOperationProgress(actions);

    final farms = _buildFarmSummaries(actions);

    final priorities = _buildPriorityActions(
      actions: actions,
      now: currentTime,
    );

    final areas = _buildAreaSummaries(actions);

    return AtlasAiOperationActions(
      generatedAt: currentTime,
      summary: _buildSummary(
        progress: progress,
        farms: farms,
        priorities: priorities,
      ),
      progress: progress,
      farms: farms,
      priorityActions: priorities,
      areaSummaries: areas,
    );
  }

  AtlasAiOperationActionProgress _buildOperationProgress(
    List<AtlasAiTrackedAction> actions,
  ) {
    final pending = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.pending;
    }).length;

    final inProgress = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.inProgress;
    }).length;

    final completed = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.completed;
    }).length;

    final cancelled = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.cancelled;
    }).length;

    final overdue = actions.where((item) {
      return item.isOverdue;
    }).length;

    final validTotal = actions.length - cancelled;

    final completionPercent = validTotal <= 0
        ? 0.0
        : completed / validTotal * 100;

    return AtlasAiOperationActionProgress(
      total: actions.length,
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      cancelled: cancelled,
      overdue: overdue,
      completionPercent: completionPercent.clamp(0.0, 100.0),
    );
  }

  List<AtlasAiFarmActionSummary> _buildFarmSummaries(
    List<AtlasAiTrackedAction> actions,
  ) {
    final grouped = <String, List<AtlasAiTrackedAction>>{};

    for (final action in actions) {
      grouped.putIfAbsent(action.farmName, () => []);

      grouped[action.farmName]!.add(action);
    }

    final result = <AtlasAiFarmActionSummary>[];

    for (final entry in grouped.entries) {
      final farmActions = entry.value;

      final progress = _buildOperationProgress(farmActions);

      final nextAction = _nextAction(farmActions);

      final priorityScore =
          progress.overdue * 18 +
          progress.pending * 6 +
          progress.inProgress * 3 +
          (100 - progress.completionPercent) * 0.35;

      result.add(
        AtlasAiFarmActionSummary(
          farmName: entry.key,
          total: progress.total,
          pending: progress.pending,
          inProgress: progress.inProgress,
          completed: progress.completed,
          cancelled: progress.cancelled,
          overdue: progress.overdue,
          completionPercent: progress.completionPercent,
          priorityScore: priorityScore.clamp(0.0, 100.0),
          nextActionTitle: nextAction?.title,
        ),
      );
    }

    result.sort(
      (first, second) => second.priorityScore.compareTo(first.priorityScore),
    );

    return result;
  }

  List<AtlasAiOperationPriorityAction> _buildPriorityActions({
    required List<AtlasAiTrackedAction> actions,
    required DateTime now,
  }) {
    final open = actions.where((item) {
      return item.isOpen;
    }).toList();

    final scored = open.map((action) {
      final daysToDue = action.dueDate.difference(now).inDays;

      var score = 0.0;

      if (action.isOverdue) {
        score += 60;
        score += (-daysToDue).clamp(0, 30) * 1.2;
      } else {
        score += (30 - daysToDue.clamp(0, 30)) * 0.9;
      }

      if (action.status == AtlasAiTrackedActionStatus.inProgress) {
        score += 12;
      }

      if (action.notes.trim().isEmpty) {
        score += 4;
      }

      return _ScoredAction(action: action, score: score.clamp(0.0, 100.0));
    }).toList()..sort((first, second) => second.score.compareTo(first.score));

    return List.generate(scored.length, (index) {
      final item = scored[index];

      return AtlasAiOperationPriorityAction(
        position: index + 1,
        action: item.action,
        priorityScore: item.score,
        reason: _priorityReason(item.action),
      );
    });
  }

  List<AtlasAiAreaActionSummary> _buildAreaSummaries(
    List<AtlasAiTrackedAction> actions,
  ) {
    final grouped = <AtlasFarmAnalysisArea, List<AtlasAiTrackedAction>>{};

    for (final action in actions) {
      grouped.putIfAbsent(action.area, () => []);

      grouped[action.area]!.add(action);
    }

    final result = <AtlasAiAreaActionSummary>[];

    for (final entry in grouped.entries) {
      final items = entry.value;

      result.add(
        AtlasAiAreaActionSummary(
          area: entry.key,
          label: atlasFarmAreaLabel(entry.key),
          total: items.length,
          open: items.where((item) {
            return item.isOpen;
          }).length,
          completed: items.where((item) {
            return item.isCompleted;
          }).length,
          overdue: items.where((item) {
            return item.isOverdue;
          }).length,
        ),
      );
    }

    result.sort((first, second) {
      if (first.overdue != second.overdue) {
        return second.overdue.compareTo(first.overdue);
      }

      return second.open.compareTo(first.open);
    });

    return result;
  }

  AtlasAiTrackedAction? _nextAction(List<AtlasAiTrackedAction> actions) {
    final open =
        actions.where((item) {
          return item.isOpen;
        }).toList()..sort((first, second) {
          if (first.isOverdue != second.isOverdue) {
            return first.isOverdue ? -1 : 1;
          }

          return first.dueDate.compareTo(second.dueDate);
        });

    return open.isEmpty ? null : open.first;
  }

  String _priorityReason(AtlasAiTrackedAction action) {
    if (action.isOverdue) {
      final delay = DateTime.now().difference(action.dueDate).inDays;

      return 'Ação atrasada há '
          '$delay '
          '${delay == 1 ? 'dia' : 'dias'}.';
    }

    if (action.status == AtlasAiTrackedActionStatus.inProgress) {
      return 'Ação em andamento com prazo em '
          '${_formatDate(action.dueDate)}.';
    }

    return 'Ação pendente com prazo em '
        '${_formatDate(action.dueDate)}.';
  }

  String _buildSummary({
    required AtlasAiOperationActionProgress progress,
    required List<AtlasAiFarmActionSummary> farms,
    required List<AtlasAiOperationPriorityAction> priorities,
  }) {
    if (progress.total == 0) {
      return 'Ainda não existem ações acompanhadas na operação.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A operação possui ${progress.total} '
      '${progress.total == 1 ? 'ação acompanhada' : 'ações acompanhadas'}. ',
    );

    buffer.write(
      'O progresso geral é de '
      '${progress.completionPercent.toStringAsFixed(0)}%, '
      'com ${progress.completed} concluídas, '
      '${progress.inProgress} em andamento, '
      '${progress.pending} pendentes e '
      '${progress.overdue} atrasadas. ',
    );

    if (farms.isNotEmpty) {
      buffer.write(
        'A fazenda com maior necessidade de acompanhamento é '
        '${farms.first.farmName}. ',
      );
    }

    if (priorities.isNotEmpty) {
      buffer.write(
        'A próxima ação recomendada é '
        '"${priorities.first.action.title}", '
        'na ${priorities.first.action.farmName}.',
      );
    }

    return buffer.toString().trim();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _ScoredAction {
  const _ScoredAction({required this.action, required this.score});

  final AtlasAiTrackedAction action;
  final double score;
}
