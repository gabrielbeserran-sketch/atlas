class FarmAgendaData {
  const FarmAgendaData({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.responsible,
    required this.priority,
    required this.status,
    required this.notes,
  });

  final String id;
  final String title;
  final String category;
  final String date;
  final String time;
  final String responsible;
  final String priority;
  final String status;
  final String notes;

  bool get isCompleted {
    return status == 'Concluída';
  }

  bool get isPending {
    return status == 'Pendente';
  }

  bool get isCancelled {
    return status == 'Cancelada';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date,
      'time': time,
      'responsible': responsible,
      'priority': priority,
      'status': status,
      'notes': notes,
    };
  }

  factory FarmAgendaData.fromMap(Map<String, dynamic> map) {
    return FarmAgendaData(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'Outro',
      date: map['date'] as String,
      time: map['time'] as String? ?? '',
      responsible: map['responsible'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Normal',
      status: map['status'] as String? ?? 'Pendente',
      notes: map['notes'] as String? ?? '',
    );
  }

  FarmAgendaData copyWith({
    String? id,
    String? title,
    String? category,
    String? date,
    String? time,
    String? responsible,
    String? priority,
    String? status,
    String? notes,
  }) {
    return FarmAgendaData(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      responsible: responsible ?? this.responsible,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
