class AtlasExecutionMeetingDecision {
  const AtlasExecutionMeetingDecision({
    required this.id,
    required this.title,
    required this.description,
    required this.responsibleName,
    this.responsibleId,
    required this.dueAt,
    required this.completed,
    required this.linkedActionId,
  });

  final String id;
  final String title;
  final String description;
  final String responsibleName;
  final String? responsibleId;
  final DateTime? dueAt;
  final bool completed;
  final String? linkedActionId;

  AtlasExecutionMeetingDecision copyWith({
    String? title,
    String? description,
    String? responsibleName,
    String? responsibleId,
    bool clearResponsibleId = false,
    DateTime? dueAt,
    bool clearDueAt = false,
    bool? completed,
    String? linkedActionId,
    bool clearLinkedActionId = false,
  }) {
    return AtlasExecutionMeetingDecision(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      responsibleName: responsibleName ?? this.responsibleName,
      responsibleId: clearResponsibleId
          ? null
          : responsibleId ?? this.responsibleId,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      completed: completed ?? this.completed,
      linkedActionId: clearLinkedActionId
          ? null
          : linkedActionId ?? this.linkedActionId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'responsibleName': responsibleName,
      'responsibleId': responsibleId,
      'dueAt': dueAt?.toIso8601String(),
      'completed': completed,
      'linkedActionId': linkedActionId,
    };
  }

  factory AtlasExecutionMeetingDecision.fromMap(Map<String, dynamic> map) {
    return AtlasExecutionMeetingDecision(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      responsibleName: map['responsibleName']?.toString() ?? '',
      responsibleId: map['responsibleId']?.toString(),
      dueAt: DateTime.tryParse(map['dueAt']?.toString() ?? ''),
      completed: map['completed'] == true,
      linkedActionId: map['linkedActionId']?.toString(),
    );
  }
}
