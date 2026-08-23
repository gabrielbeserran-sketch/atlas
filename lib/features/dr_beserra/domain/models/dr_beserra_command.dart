import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_operation_draft.dart';

enum DrBeserraIntent {
  todayTasks,
  tomorrowTasks,
  overdueTasks,
  priorityTasksToday,
  contextualAttention,
  matricesOverview,
  worstLot,
  financialPressure,
  completeTask,
  openAgenda,
  openHandling,
  openHealth,
  openReproduction,
  openHerd,
  openNutrition,
  openFinance,
  openInventory,
  openField,
  openIntelligence,
  openReports,
  openConsulting,
  unknown,
}

class DrBeserraCommand {
  const DrBeserraCommand({
    required this.intent,
    required this.rawText,
    this.subject = '',
  });

  final DrBeserraIntent intent;
  final String rawText;
  final String subject;
}

class DrBeserraReply {
  const DrBeserraReply({
    required this.message,
    this.routeLabel,
    this.confirmationTaskId,
    this.confirmationTaskTitle,
    this.confirmationOperation,
    this.confirmationOperationTitle,
    this.relatedTaskId,
    this.relatedTaskTitle,
  });

  final String message;
  final String? routeLabel;
  final String? confirmationTaskId;
  final String? confirmationTaskTitle;
  final DrBeserraOperationDraft? confirmationOperation;
  final String? confirmationOperationTitle;
  final String? relatedTaskId;
  final String? relatedTaskTitle;

  bool get requiresConfirmation =>
      confirmationTaskId?.trim().isNotEmpty == true ||
      confirmationOperation != null;
}
