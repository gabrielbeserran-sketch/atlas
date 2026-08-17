import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert.dart';

class AtlasExecutiveAlertState {
  const AtlasExecutiveAlertState({
    required this.alertId,
    required this.farmName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.responsibleName = '',
    this.notes = '',
    this.customDeadline,
  });

  final String alertId;
  final String farmName;

  final AtlasExecutiveAlertTreatmentStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  final String responsibleName;
  final String notes;

  final DateTime? customDeadline;

  bool get isOpen {
    return status == AtlasExecutiveAlertTreatmentStatus.newAlert ||
        status == AtlasExecutiveAlertTreatmentStatus.acknowledged ||
        status == AtlasExecutiveAlertTreatmentStatus.inTreatment;
  }

  bool get isResolved {
    return status == AtlasExecutiveAlertTreatmentStatus.resolved;
  }

  bool get isDiscarded {
    return status == AtlasExecutiveAlertTreatmentStatus.discarded;
  }

  bool get isOverdue {
    final deadline = customDeadline;

    return isOpen && deadline != null && deadline.isBefore(DateTime.now());
  }

  Duration? get resolutionDuration {
    final resolved = resolvedAt;

    if (resolved == null) {
      return null;
    }

    return resolved.difference(createdAt);
  }

  AtlasExecutiveAlertState copyWith({
    String? alertId,
    String? farmName,
    AtlasExecutiveAlertTreatmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    bool clearResolvedAt = false,
    String? responsibleName,
    String? notes,
    DateTime? customDeadline,
    bool clearCustomDeadline = false,
  }) {
    return AtlasExecutiveAlertState(
      alertId: alertId ?? this.alertId,
      farmName: farmName ?? this.farmName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: clearResolvedAt ? null : resolvedAt ?? this.resolvedAt,
      responsibleName: responsibleName ?? this.responsibleName,
      notes: notes ?? this.notes,
      customDeadline: clearCustomDeadline
          ? null
          : customDeadline ?? this.customDeadline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'farmName': farmName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'responsibleName': responsibleName,
      'notes': notes,
      'customDeadline': customDeadline?.toIso8601String(),
    };
  }

  factory AtlasExecutiveAlertState.fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString() ?? '';

    return AtlasExecutiveAlertState(
      alertId: json['alertId']?.toString() ?? '',
      farmName: json['farmName']?.toString() ?? '',
      status: AtlasExecutiveAlertTreatmentStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => AtlasExecutiveAlertTreatmentStatus.newAlert,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      resolvedAt: DateTime.tryParse(json['resolvedAt']?.toString() ?? ''),
      responsibleName: json['responsibleName']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      customDeadline: DateTime.tryParse(
        json['customDeadline']?.toString() ?? '',
      ),
    );
  }
}

class AtlasExecutiveAlertTreatmentItem {
  const AtlasExecutiveAlertTreatmentItem({
    required this.alert,
    required this.state,
  });

  final AtlasExecutiveAlert alert;
  final AtlasExecutiveAlertState state;

  bool get isOpen {
    return state.isOpen;
  }

  bool get isResolved {
    return state.isResolved;
  }

  bool get isDiscarded {
    return state.isDiscarded;
  }

  bool get isOverdue {
    return state.isOverdue;
  }
}

class AtlasExecutiveAlertTreatmentProgress {
  const AtlasExecutiveAlertTreatmentProgress({
    required this.total,
    required this.newAlerts,
    required this.acknowledged,
    required this.inTreatment,
    required this.resolved,
    required this.discarded,
    required this.overdue,
    required this.resolutionPercent,
    required this.averageResolutionHours,
  });

  final int total;
  final int newAlerts;
  final int acknowledged;
  final int inTreatment;
  final int resolved;
  final int discarded;
  final int overdue;

  final double resolutionPercent;
  final double averageResolutionHours;

  bool get hasAlerts {
    return total > 0;
  }
}

enum AtlasExecutiveAlertTreatmentStatus {
  newAlert,
  acknowledged,
  inTreatment,
  resolved,
  discarded,
}

String atlasExecutiveAlertTreatmentStatusLabel(
  AtlasExecutiveAlertTreatmentStatus status,
) {
  switch (status) {
    case AtlasExecutiveAlertTreatmentStatus.newAlert:
      return 'Novo';

    case AtlasExecutiveAlertTreatmentStatus.acknowledged:
      return 'Reconhecido';

    case AtlasExecutiveAlertTreatmentStatus.inTreatment:
      return 'Em tratamento';

    case AtlasExecutiveAlertTreatmentStatus.resolved:
      return 'Resolvido';

    case AtlasExecutiveAlertTreatmentStatus.discarded:
      return 'Descartado';
  }
}
