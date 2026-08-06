class ReportActionItemData {
  const ReportActionItemData({
    required this.id,
    required this.farmName,
    required this.title,
    required this.action,
    required this.responsible,
    required this.deadline,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.completedAt,
    required this.notes,
    required this.source,
  });

  final String id;
  final String farmName;
  final String title;
  final String action;
  final String responsible;
  final String deadline;
  final String priority;
  final String status;
  final String createdAt;
  final String completedAt;
  final String notes;
  final String source;

  bool get isPending {
    return status == 'Pendente';
  }

  bool get isInProgress {
    return status == 'Em andamento';
  }

  bool get isCompleted {
    return status == 'Concluída';
  }

  bool get isCancelled {
    return status == 'Cancelada';
  }

  bool get isOpen {
    return !isCompleted && !isCancelled;
  }

  bool get isUrgent {
    return priority == 'Muito alta' || priority == 'Urgente';
  }

  bool get hasDeadline {
    return deadline.trim().isNotEmpty;
  }

  bool get isOverdue {
    if (!isOpen || !hasDeadline) {
      return false;
    }

    final parsedDeadline = tryParseActionDate(deadline);

    if (parsedDeadline == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    return parsedDeadline.isBefore(today);
  }

  ReportActionItemData copyWith({
    String? id,
    String? farmName,
    String? title,
    String? action,
    String? responsible,
    String? deadline,
    String? priority,
    String? status,
    String? createdAt,
    String? completedAt,
    String? notes,
    String? source,
  }) {
    return ReportActionItemData(
      id: id ?? this.id,
      farmName: farmName ?? this.farmName,
      title: title ?? this.title,
      action: action ?? this.action,
      responsible: responsible ?? this.responsible,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      source: source ?? this.source,
    );
  }

  ReportActionItemData markAsPending() {
    return copyWith(status: 'Pendente', completedAt: '');
  }

  ReportActionItemData markAsInProgress() {
    return copyWith(status: 'Em andamento', completedAt: '');
  }

  ReportActionItemData markAsCompleted() {
    return copyWith(
      status: 'Concluída',
      completedAt: formatActionDate(DateTime.now()),
    );
  }

  ReportActionItemData markAsCancelled() {
    return copyWith(status: 'Cancelada', completedAt: '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmName': farmName,
      'title': title,
      'action': action,
      'responsible': responsible,
      'deadline': deadline,
      'priority': priority,
      'status': status,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'notes': notes,
      'source': source,
    };
  }

  factory ReportActionItemData.fromJson(Map<String, dynamic> json) {
    return ReportActionItemData(
      id: json['id']?.toString() ?? '',
      farmName: json['farmName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      responsible: json['responsible']?.toString() ?? '',
      deadline: json['deadline']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Média',
      status: json['status']?.toString() ?? 'Pendente',
      createdAt: json['createdAt']?.toString() ?? '',
      completedAt: json['completedAt']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Relatório',
    );
  }
}

DateTime? tryParseActionDate(String value) {
  final parts = value.trim().split('/');

  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return null;
  }

  final date = DateTime(year, month, day);

  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}

String formatActionDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String createReportActionId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}

int compareReportActions(
  ReportActionItemData first,
  ReportActionItemData second,
) {
  final firstStatusWeight = reportActionStatusWeight(first);

  final secondStatusWeight = reportActionStatusWeight(second);

  if (firstStatusWeight != secondStatusWeight) {
    return firstStatusWeight.compareTo(secondStatusWeight);
  }

  final firstPriorityWeight = reportActionPriorityWeight(first.priority);

  final secondPriorityWeight = reportActionPriorityWeight(second.priority);

  if (firstPriorityWeight != secondPriorityWeight) {
    return secondPriorityWeight.compareTo(firstPriorityWeight);
  }

  final firstDate = tryParseActionDate(first.deadline) ?? DateTime(2100);

  final secondDate = tryParseActionDate(second.deadline) ?? DateTime(2100);

  return firstDate.compareTo(secondDate);
}

int reportActionStatusWeight(ReportActionItemData action) {
  if (action.isOverdue) {
    return 0;
  }

  switch (action.status) {
    case 'Em andamento':
      return 1;

    case 'Pendente':
      return 2;

    case 'Concluída':
      return 3;

    case 'Cancelada':
      return 4;

    default:
      return 5;
  }
}

int reportActionPriorityWeight(String priority) {
  switch (priority) {
    case 'Muito alta':
    case 'Urgente':
      return 4;

    case 'Alta':
      return 3;

    case 'Média':
    case 'Normal':
      return 2;

    case 'Baixa':
    case 'Acompanhamento':
      return 1;

    default:
      return 0;
  }
}
