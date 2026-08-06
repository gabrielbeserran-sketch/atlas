class ReportActionHistoryData {
  const ReportActionHistoryData({
    required this.id,
    required this.actionId,
    required this.actionTitle,
    required this.eventType,
    required this.description,
    required this.previousValue,
    required this.newValue,
    required this.createdAt,
    required this.createdBy,
    required this.source,
  });

  final String id;
  final String actionId;
  final String actionTitle;
  final String eventType;
  final String description;
  final String previousValue;
  final String newValue;
  final String createdAt;
  final String createdBy;
  final String source;

  bool get isCreation {
    return eventType == 'Criação';
  }

  bool get isStatusChange {
    return eventType == 'Status';
  }

  bool get isDeadlineChange {
    return eventType == 'Prazo';
  }

  bool get isResponsibleChange {
    return eventType == 'Responsável';
  }

  bool get isPriorityChange {
    return eventType == 'Prioridade';
  }

  bool get isNotesChange {
    return eventType == 'Observação';
  }

  bool get isCompletion {
    return eventType == 'Conclusão';
  }

  bool get isCancellation {
    return eventType == 'Cancelamento';
  }

  ReportActionHistoryData copyWith({
    String? id,
    String? actionId,
    String? actionTitle,
    String? eventType,
    String? description,
    String? previousValue,
    String? newValue,
    String? createdAt,
    String? createdBy,
    String? source,
  }) {
    return ReportActionHistoryData(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      actionTitle: actionTitle ?? this.actionTitle,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      previousValue: previousValue ?? this.previousValue,
      newValue: newValue ?? this.newValue,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionId': actionId,
      'actionTitle': actionTitle,
      'eventType': eventType,
      'description': description,
      'previousValue': previousValue,
      'newValue': newValue,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'source': source,
    };
  }

  factory ReportActionHistoryData.fromJson(Map<String, dynamic> json) {
    return ReportActionHistoryData(
      id: json['id']?.toString() ?? '',
      actionId: json['actionId']?.toString() ?? '',
      actionTitle: json['actionTitle']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      previousValue: json['previousValue']?.toString() ?? '',
      newValue: json['newValue']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}

String createReportActionHistoryId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}

String formatReportActionHistoryDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  final second = date.second.toString().padLeft(2, '0');

  return '$day/$month/${date.year} '
      '$hour:$minute:$second';
}

DateTime? tryParseReportActionHistoryDateTime(String value) {
  final parts = value.trim().split(' ');

  if (parts.length != 2) {
    return null;
  }

  final dateParts = parts[0].split('/');
  final timeParts = parts[1].split(':');

  if (dateParts.length != 3 || timeParts.length < 2) {
    return null;
  }

  final day = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final year = int.tryParse(dateParts[2]);

  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  final second = timeParts.length >= 3 ? int.tryParse(timeParts[2]) ?? 0 : 0;

  if (day == null ||
      month == null ||
      year == null ||
      hour == null ||
      minute == null) {
    return null;
  }

  final date = DateTime(year, month, day, hour, minute, second);

  if (date.day != day ||
      date.month != month ||
      date.year != year ||
      date.hour != hour ||
      date.minute != minute) {
    return null;
  }

  return date;
}

int compareReportActionHistory(
  ReportActionHistoryData first,
  ReportActionHistoryData second,
) {
  final firstDate =
      tryParseReportActionHistoryDateTime(first.createdAt) ?? DateTime(2000);

  final secondDate =
      tryParseReportActionHistoryDateTime(second.createdAt) ?? DateTime(2000);

  return secondDate.compareTo(firstDate);
}

ReportActionHistoryData createActionCreatedHistory({
  required String actionId,
  required String actionTitle,
  required String source,
  String createdBy = 'Usuário',
}) {
  return ReportActionHistoryData(
    id: createReportActionHistoryId(),
    actionId: actionId,
    actionTitle: actionTitle,
    eventType: 'Criação',
    description: 'A ação foi criada para acompanhamento.',
    previousValue: '',
    newValue: 'Pendente',
    createdAt: formatReportActionHistoryDateTime(DateTime.now()),
    createdBy: createdBy,
    source: source,
  );
}

ReportActionHistoryData createActionStatusHistory({
  required String actionId,
  required String actionTitle,
  required String previousStatus,
  required String newStatus,
  required String source,
  String createdBy = 'Usuário',
}) {
  final eventType = newStatus == 'Concluída'
      ? 'Conclusão'
      : newStatus == 'Cancelada'
      ? 'Cancelamento'
      : 'Status';

  return ReportActionHistoryData(
    id: createReportActionHistoryId(),
    actionId: actionId,
    actionTitle: actionTitle,
    eventType: eventType,
    description:
        'O status da ação foi alterado de '
        '"$previousStatus" para "$newStatus".',
    previousValue: previousStatus,
    newValue: newStatus,
    createdAt: formatReportActionHistoryDateTime(DateTime.now()),
    createdBy: createdBy,
    source: source,
  );
}

ReportActionHistoryData createActionDeadlineHistory({
  required String actionId,
  required String actionTitle,
  required String previousDeadline,
  required String newDeadline,
  required String source,
  String createdBy = 'Usuário',
}) {
  return ReportActionHistoryData(
    id: createReportActionHistoryId(),
    actionId: actionId,
    actionTitle: actionTitle,
    eventType: 'Prazo',
    description: 'O prazo da ação foi alterado.',
    previousValue: previousDeadline.isEmpty ? 'Sem prazo' : previousDeadline,
    newValue: newDeadline.isEmpty ? 'Sem prazo' : newDeadline,
    createdAt: formatReportActionHistoryDateTime(DateTime.now()),
    createdBy: createdBy,
    source: source,
  );
}

ReportActionHistoryData createActionResponsibleHistory({
  required String actionId,
  required String actionTitle,
  required String previousResponsible,
  required String newResponsible,
  required String source,
  String createdBy = 'Usuário',
}) {
  return ReportActionHistoryData(
    id: createReportActionHistoryId(),
    actionId: actionId,
    actionTitle: actionTitle,
    eventType: 'Responsável',
    description: 'O responsável pela ação foi alterado.',
    previousValue: previousResponsible.isEmpty
        ? 'Sem responsável'
        : previousResponsible,
    newValue: newResponsible.isEmpty ? 'Sem responsável' : newResponsible,
    createdAt: formatReportActionHistoryDateTime(DateTime.now()),
    createdBy: createdBy,
    source: source,
  );
}

ReportActionHistoryData createActionPriorityHistory({
  required String actionId,
  required String actionTitle,
  required String previousPriority,
  required String newPriority,
  required String source,
  String createdBy = 'Usuário',
}) {
  return ReportActionHistoryData(
    id: createReportActionHistoryId(),
    actionId: actionId,
    actionTitle: actionTitle,
    eventType: 'Prioridade',
    description: 'A prioridade da ação foi alterada.',
    previousValue: previousPriority,
    newValue: newPriority,
    createdAt: formatReportActionHistoryDateTime(DateTime.now()),
    createdBy: createdBy,
    source: source,
  );
}

ReportActionHistoryData createActionNotesHistory({
  required String actionId,
  required String actionTitle,
  required String previousNotes,
  required String newNotes,
  required String source,
  String createdBy = 'Usuário',
}) {
  return ReportActionHistoryData(
    id: createReportActionHistoryId(),
    actionId: actionId,
    actionTitle: actionTitle,
    eventType: 'Observação',
    description: 'As observações da ação foram atualizadas.',
    previousValue: previousNotes,
    newValue: newNotes,
    createdAt: formatReportActionHistoryDateTime(DateTime.now()),
    createdBy: createdBy,
    source: source,
  );
}
