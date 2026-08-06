import 'dart:convert';

enum AtlasConsultancyStage {
  initialContact,
  diagnosis,
  planning,
  execution,
  monitoring,
  reporting,
  completed,
}

extension AtlasConsultancyStageLabel on AtlasConsultancyStage {
  String get label {
    switch (this) {
      case AtlasConsultancyStage.initialContact:
        return 'Contato inicial';
      case AtlasConsultancyStage.diagnosis:
        return 'Diagnóstico';
      case AtlasConsultancyStage.planning:
        return 'Planejamento';
      case AtlasConsultancyStage.execution:
        return 'Execução';
      case AtlasConsultancyStage.monitoring:
        return 'Monitoramento';
      case AtlasConsultancyStage.reporting:
        return 'Relatórios';
      case AtlasConsultancyStage.completed:
        return 'Concluída';
    }
  }
}

class AtlasConsultancyVisit {
  const AtlasConsultancyVisit({
    required this.id,
    required this.date,
    required this.summary,
    required this.completed,
  });

  final String id;
  final DateTime date;
  final String summary;
  final bool completed;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'date': date.toIso8601String(),
        'summary': summary,
        'completed': completed,
      };

  factory AtlasConsultancyVisit.fromMap(Map<String, dynamic> map) {
    return AtlasConsultancyVisit(
      id: map['id'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      summary: map['summary'] as String? ?? '',
      completed: map['completed'] as bool? ?? false,
    );
  }
}

class AtlasConsultancyAction {
  const AtlasConsultancyAction({
    required this.id,
    required this.title,
    required this.responsible,
    required this.deadline,
    required this.completed,
  });

  final String id;
  final String title;
  final String responsible;
  final DateTime deadline;
  final bool completed;

  AtlasConsultancyAction copyWith({bool? completed}) {
    return AtlasConsultancyAction(
      id: id,
      title: title,
      responsible: responsible,
      deadline: deadline,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'responsible': responsible,
        'deadline': deadline.toIso8601String(),
        'completed': completed,
      };

  factory AtlasConsultancyAction.fromMap(Map<String, dynamic> map) {
    return AtlasConsultancyAction(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      responsible: map['responsible'] as String? ?? '',
      deadline:
          DateTime.tryParse(map['deadline'] as String? ?? '') ?? DateTime.now(),
      completed: map['completed'] as bool? ?? false,
    );
  }
}

class AtlasConsultancyCase {
  const AtlasConsultancyCase({
    required this.id,
    required this.clientName,
    required this.farmName,
    required this.stage,
    required this.createdAt,
    required this.visits,
    required this.actions,
    required this.notes,
  });

  final String id;
  final String clientName;
  final String farmName;
  final AtlasConsultancyStage stage;
  final DateTime createdAt;
  final List<AtlasConsultancyVisit> visits;
  final List<AtlasConsultancyAction> actions;
  final String notes;

  AtlasConsultancyCase copyWith({
    AtlasConsultancyStage? stage,
    List<AtlasConsultancyVisit>? visits,
    List<AtlasConsultancyAction>? actions,
  }) {
    return AtlasConsultancyCase(
      id: id,
      clientName: clientName,
      farmName: farmName,
      stage: stage ?? this.stage,
      createdAt: createdAt,
      visits: visits ?? this.visits,
      actions: actions ?? this.actions,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'clientName': clientName,
        'farmName': farmName,
        'stage': stage.name,
        'createdAt': createdAt.toIso8601String(),
        'visits': visits.map((item) => item.toMap()).toList(),
        'actions': actions.map((item) => item.toMap()).toList(),
        'notes': notes,
      };

  String toJson() => jsonEncode(toMap());

  factory AtlasConsultancyCase.fromMap(Map<String, dynamic> map) {
    return AtlasConsultancyCase(
      id: map['id'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      farmName: map['farmName'] as String? ?? '',
      stage: AtlasConsultancyStage.values.firstWhere(
        (item) => item.name == map['stage'],
        orElse: () => AtlasConsultancyStage.initialContact,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      visits: ((map['visits'] as List<dynamic>?) ?? <dynamic>[])
          .map((item) => AtlasConsultancyVisit.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      actions: ((map['actions'] as List<dynamic>?) ?? <dynamic>[])
          .map((item) => AtlasConsultancyAction.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      notes: map['notes'] as String? ?? '',
    );
  }

  factory AtlasConsultancyCase.fromJson(String source) {
    return AtlasConsultancyCase.fromMap(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }
}
