import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasAiTrackedAction {
  const AtlasAiTrackedAction({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.expectedResult,
    required this.area,
    required this.deadlineDays,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.completedAt,
    this.notes = '',
    this.sourceQuestion = '',
  });

  final String id;
  final String farmName;

  final String title;
  final String description;
  final String expectedResult;

  final AtlasFarmAnalysisArea area;

  final int deadlineDays;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  final AtlasAiTrackedActionStatus status;

  final String notes;
  final String sourceQuestion;

  DateTime get dueDate {
    return createdAt.add(
      Duration(days: deadlineDays),
    );
  }

  bool get isOpen {
    return status ==
            AtlasAiTrackedActionStatus.pending ||
        status ==
            AtlasAiTrackedActionStatus.inProgress;
  }

  bool get isCompleted {
    return status ==
        AtlasAiTrackedActionStatus.completed;
  }

  bool get isOverdue {
    return isOpen &&
        dueDate.isBefore(DateTime.now());
  }

  AtlasAiTrackedAction copyWith({
    String? id,
    String? farmName,
    String? title,
    String? description,
    String? expectedResult,
    AtlasFarmAnalysisArea? area,
    int? deadlineDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    AtlasAiTrackedActionStatus? status,
    String? notes,
    String? sourceQuestion,
  }) {
    return AtlasAiTrackedAction(
      id: id ?? this.id,
      farmName: farmName ?? this.farmName,
      title: title ?? this.title,
      description:
          description ?? this.description,
      expectedResult:
          expectedResult ?? this.expectedResult,
      area: area ?? this.area,
      deadlineDays:
          deadlineDays ?? this.deadlineDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt
          ? null
          : completedAt ?? this.completedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      sourceQuestion:
          sourceQuestion ?? this.sourceQuestion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmName': farmName,
      'title': title,
      'description': description,
      'expectedResult': expectedResult,
      'area': area.name,
      'deadlineDays': deadlineDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt':
          completedAt?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'sourceQuestion': sourceQuestion,
    };
  }

  factory AtlasAiTrackedAction.fromJson(
    Map<String, dynamic> json,
  ) {
    final areaName =
        json['area']?.toString() ?? '';

    final statusName =
        json['status']?.toString() ?? '';

    return AtlasAiTrackedAction(
      id: json['id']?.toString() ?? '',
      farmName:
          json['farmName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      expectedResult:
          json['expectedResult']?.toString() ?? '',
      area:
          AtlasFarmAnalysisArea.values.firstWhere(
        (item) => item.name == areaName,
        orElse: () =>
            AtlasFarmAnalysisArea.general,
      ),
      deadlineDays:
          _readInt(json['deadlineDays'], 1),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
            json['updatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? '',
      ),
      status:
          AtlasAiTrackedActionStatus.values
              .firstWhere(
        (item) => item.name == statusName,
        orElse: () =>
            AtlasAiTrackedActionStatus.pending,
      ),
      notes: json['notes']?.toString() ?? '',
      sourceQuestion:
          json['sourceQuestion']?.toString() ?? '',
    );
  }

  static int _readInt(
    dynamic value,
    int fallback,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }
}

class AtlasAiActionProgress {
  const AtlasAiActionProgress({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.overdue,
    required this.completionPercent,
  });

  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int overdue;

  final double completionPercent;

  bool get hasActions {
    return total > 0;
  }
}

enum AtlasAiTrackedActionStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

String atlasAiTrackedActionStatusLabel(
  AtlasAiTrackedActionStatus status,
) {
  switch (status) {
    case AtlasAiTrackedActionStatus.pending:
      return 'Pendente';

    case AtlasAiTrackedActionStatus.inProgress:
      return 'Em andamento';

    case AtlasAiTrackedActionStatus.completed:
      return 'Concluída';

    case AtlasAiTrackedActionStatus.cancelled:
      return 'Cancelada';
  }
}
