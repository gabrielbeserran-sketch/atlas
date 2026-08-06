class AnimalOperationalTask {
  const AnimalOperationalTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.responsible,
    required this.completed,
    required this.createdAt,
    required this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String dueDate;
  final String responsible;
  final bool completed;
  final String createdAt;
  final String completedAt;

  AnimalOperationalTask copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? dueDate,
    String? responsible,
    bool? completed,
    String? createdAt,
    String? completedAt,
  }) {
    return AnimalOperationalTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      responsible: responsible ?? this.responsible,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'dueDate': dueDate,
      'responsible': responsible,
      'completed': completed,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  factory AnimalOperationalTask.fromMap(
    Map<String, dynamic> map,
  ) {
    return AnimalOperationalTask(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Geral',
      priority: map['priority']?.toString() ?? 'Média',
      dueDate: map['dueDate']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      completed: map['completed'] == true,
      createdAt: map['createdAt']?.toString() ?? '',
      completedAt: map['completedAt']?.toString() ?? '',
    );
  }
}
