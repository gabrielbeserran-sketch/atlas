import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert_state.dart';

class AtlasExecutiveAlertTreatmentService {
  const AtlasExecutiveAlertTreatmentService();

  List<AtlasExecutiveAlertTreatmentItem> merge({
    required List<AtlasExecutiveAlert> alerts,
    required List<AtlasExecutiveAlertState> states,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final stateById = {for (final state in states) state.alertId: state};

    return alerts.map((alert) {
      final existing = stateById[alert.id];

      final state =
          existing ??
          AtlasExecutiveAlertState(
            alertId: alert.id,
            farmName: alert.farmName,
            status: AtlasExecutiveAlertTreatmentStatus.newAlert,
            createdAt: currentTime,
            updatedAt: currentTime,
            customDeadline: currentTime.add(
              Duration(days: alert.responseDeadlineDays),
            ),
          );

      return AtlasExecutiveAlertTreatmentItem(alert: alert, state: state);
    }).toList()..sort((first, second) {
      if (first.isOpen != second.isOpen) {
        return first.isOpen ? -1 : 1;
      }

      if (first.isOverdue != second.isOverdue) {
        return first.isOverdue ? -1 : 1;
      }

      return second.alert.priorityScore.compareTo(first.alert.priorityScore);
    });
  }

  AtlasExecutiveAlertState updateStatus({
    required AtlasExecutiveAlertState state,
    required AtlasExecutiveAlertTreatmentStatus status,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    return state.copyWith(
      status: status,
      updatedAt: currentTime,
      resolvedAt: status == AtlasExecutiveAlertTreatmentStatus.resolved
          ? currentTime
          : null,
      clearResolvedAt: status != AtlasExecutiveAlertTreatmentStatus.resolved,
    );
  }

  AtlasExecutiveAlertState updateResponsible({
    required AtlasExecutiveAlertState state,
    required String responsibleName,
    DateTime? now,
  }) {
    return state.copyWith(
      responsibleName: responsibleName.trim(),
      updatedAt: now ?? DateTime.now(),
    );
  }

  AtlasExecutiveAlertState updateNotes({
    required AtlasExecutiveAlertState state,
    required String notes,
    DateTime? now,
  }) {
    return state.copyWith(
      notes: notes.trim(),
      updatedAt: now ?? DateTime.now(),
    );
  }

  AtlasExecutiveAlertState updateDeadline({
    required AtlasExecutiveAlertState state,
    required DateTime? deadline,
    DateTime? now,
  }) {
    return state.copyWith(
      customDeadline: deadline,
      clearCustomDeadline: deadline == null,
      updatedAt: now ?? DateTime.now(),
    );
  }

  AtlasExecutiveAlertTreatmentProgress calculateProgress(
    List<AtlasExecutiveAlertTreatmentItem> items,
  ) {
    final newAlerts = items.where((item) {
      return item.state.status == AtlasExecutiveAlertTreatmentStatus.newAlert;
    }).length;

    final acknowledged = items.where((item) {
      return item.state.status ==
          AtlasExecutiveAlertTreatmentStatus.acknowledged;
    }).length;

    final inTreatment = items.where((item) {
      return item.state.status ==
          AtlasExecutiveAlertTreatmentStatus.inTreatment;
    }).length;

    final resolved = items.where((item) {
      return item.state.status == AtlasExecutiveAlertTreatmentStatus.resolved;
    }).length;

    final discarded = items.where((item) {
      return item.state.status == AtlasExecutiveAlertTreatmentStatus.discarded;
    }).length;

    final overdue = items.where((item) {
      return item.isOverdue;
    }).length;

    final validTotal = items.length - discarded;

    final resolutionPercent = validTotal <= 0
        ? 0.0
        : resolved / validTotal * 100;

    final durations = items
        .map((item) {
          return item.state.resolutionDuration;
        })
        .whereType<Duration>()
        .toList();

    final averageResolutionHours = durations.isEmpty
        ? 0.0
        : durations.fold<double>(
                0,
                (sum, duration) => sum + duration.inMinutes / 60,
              ) /
              durations.length;

    return AtlasExecutiveAlertTreatmentProgress(
      total: items.length,
      newAlerts: newAlerts,
      acknowledged: acknowledged,
      inTreatment: inTreatment,
      resolved: resolved,
      discarded: discarded,
      overdue: overdue,
      resolutionPercent: resolutionPercent.clamp(0.0, 100.0),
      averageResolutionHours: averageResolutionHours,
    );
  }

  String buildProgressSummary({
    required String farmName,
    required List<AtlasExecutiveAlertTreatmentItem> items,
  }) {
    final progress = calculateProgress(items);

    if (!progress.hasAlerts) {
      return 'Nenhum alerta está sendo acompanhado na $farmName.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A $farmName possui ${progress.total} '
      '${progress.total == 1 ? 'alerta acompanhado' : 'alertas acompanhados'}. ',
    );

    buffer.write(
      '${progress.resolved} '
      '${progress.resolved == 1 ? 'foi resolvido' : 'foram resolvidos'}, ',
    );

    buffer.write(
      '${progress.inTreatment} '
      '${progress.inTreatment == 1 ? 'está em tratamento' : 'estão em tratamento'} ',
    );

    buffer.write(
      'e ${progress.newAlerts} '
      '${progress.newAlerts == 1 ? 'permanece novo' : 'permanecem novos'}. ',
    );

    if (progress.overdue > 0) {
      buffer.write(
        '${progress.overdue} '
        '${progress.overdue == 1 ? 'tratamento está atrasado' : 'tratamentos estão atrasados'}. ',
      );
    }

    buffer.write(
      'A taxa de resolução é de '
      '${progress.resolutionPercent.toStringAsFixed(0)}%.',
    );

    return buffer.toString();
  }
}
