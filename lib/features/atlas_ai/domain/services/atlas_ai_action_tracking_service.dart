import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_memory.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_response.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';

class AtlasAiActionTrackingService {
  const AtlasAiActionTrackingService();

  List<AtlasAiTrackedAction> importFromMemory({
    required String farmName,
    required AtlasAiMemory memory,
    required List<AtlasAiTrackedAction> existingActions,
    DateTime? now,
  }) {
    final result = [...existingActions];
    final currentTime = now ?? DateTime.now();

    for (final action in memory.pendingActions) {
      final exists = result.any((item) {
        return _sameAction(
          item.title,
          item.area.name,
          action.title,
          action.area.name,
        );
      });

      if (exists) {
        continue;
      }

      result.add(
        AtlasAiTrackedAction(
          id: _buildId(
            farmName: farmName,
            title: action.title,
            createdAt: currentTime,
          ),
          farmName: farmName,
          title: action.title,
          description: action.description,
          expectedResult: action.expectedResult,
          area: action.area,
          deadlineDays: action.deadlineDays,
          createdAt: currentTime,
          updatedAt: currentTime,
          status: AtlasAiTrackedActionStatus.pending,
          sourceQuestion: action.sourceQuestion,
        ),
      );
    }

    return result;
  }

  List<AtlasAiTrackedAction> importFromResponse({
    required String farmName,
    required AtlasAiResponse response,
    required List<AtlasAiTrackedAction> existingActions,
    DateTime? now,
  }) {
    final result = [...existingActions];
    final currentTime = now ?? DateTime.now();

    for (final action in response.actionPlan) {
      final exists = result.any((item) {
        return _sameAction(
          item.title,
          item.area.name,
          action.title,
          action.area.name,
        );
      });

      if (exists) {
        continue;
      }

      result.add(
        AtlasAiTrackedAction(
          id: _buildId(
            farmName: farmName,
            title: action.title,
            createdAt: currentTime,
          ),
          farmName: farmName,
          title: action.title,
          description: action.description,
          expectedResult: action.expectedResult,
          area: action.area,
          deadlineDays: action.deadlineDays,
          createdAt: currentTime,
          updatedAt: currentTime,
          status: AtlasAiTrackedActionStatus.pending,
          sourceQuestion: response.question,
        ),
      );
    }

    return result;
  }

  AtlasAiTrackedAction updateStatus({
    required AtlasAiTrackedAction action,
    required AtlasAiTrackedActionStatus status,
    String? notes,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    return action.copyWith(
      status: status,
      notes: notes,
      updatedAt: currentTime,
      completedAt: status == AtlasAiTrackedActionStatus.completed
          ? currentTime
          : null,
      clearCompletedAt: status != AtlasAiTrackedActionStatus.completed,
    );
  }

  AtlasAiTrackedAction updateNotes({
    required AtlasAiTrackedAction action,
    required String notes,
    DateTime? now,
  }) {
    return action.copyWith(
      notes: notes.trim(),
      updatedAt: now ?? DateTime.now(),
    );
  }

  AtlasAiActionProgress calculateProgress(List<AtlasAiTrackedAction> actions) {
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

    return AtlasAiActionProgress(
      total: actions.length,
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      cancelled: cancelled,
      overdue: overdue,
      completionPercent: completionPercent.clamp(0.0, 100.0),
    );
  }

  String buildProgressSummary({
    required String farmName,
    required List<AtlasAiTrackedAction> actions,
  }) {
    final progress = calculateProgress(actions);

    if (!progress.hasActions) {
      return 'Ainda não existem ações acompanhadas para a $farmName.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A $farmName possui ${progress.total} '
      '${progress.total == 1 ? 'ação acompanhada' : 'ações acompanhadas'}. ',
    );

    buffer.write(
      '${progress.completed} '
      '${progress.completed == 1 ? 'foi concluída' : 'foram concluídas'}, ',
    );

    buffer.write(
      '${progress.inProgress} '
      '${progress.inProgress == 1 ? 'está em andamento' : 'estão em andamento'} ',
    );

    buffer.write(
      'e ${progress.pending} '
      '${progress.pending == 1 ? 'permanece pendente' : 'permanecem pendentes'}. ',
    );

    if (progress.overdue > 0) {
      buffer.write(
        '${progress.overdue} '
        '${progress.overdue == 1 ? 'ação está atrasada' : 'ações estão atrasadas'}. ',
      );
    }

    buffer.write(
      'O progresso geral é de '
      '${progress.completionPercent.toStringAsFixed(0)}%.',
    );

    return buffer.toString();
  }

  bool _sameAction(
    String firstTitle,
    String firstArea,
    String secondTitle,
    String secondArea,
  ) {
    return _normalize(firstTitle) == _normalize(secondTitle) &&
        firstArea == secondArea;
  }

  String _buildId({
    required String farmName,
    required String title,
    required DateTime createdAt,
  }) {
    return '${_normalize(farmName)}_'
        '${_normalize(title)}_'
        '${createdAt.microsecondsSinceEpoch}';
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
