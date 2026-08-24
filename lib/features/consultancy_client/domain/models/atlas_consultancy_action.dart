class AtlasConsultancyAction {
  const AtlasConsultancyAction({
    required this.id,
    required this.farmId,
    required this.title,
    required this.description,
    required this.area,
    required this.priority,
    required this.status,
    required this.dueAt,
    required this.completedAt,
    required this.expectedResult,
    required this.actualResult,
    required this.agendaTaskId,
    required this.replayed,
  });

  final String id;
  final String farmId;
  final String title;
  final String description;
  final String area;
  final String priority;
  final String status;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String expectedResult;
  final String actualResult;
  final String agendaTaskId;
  final bool replayed;

  bool get isCompleted => status == 'completed';
  bool get isOpen => !isCompleted && status != 'cancelled';

  factory AtlasConsultancyAction.fromMap(Map<String, dynamic> map) {
    return AtlasConsultancyAction(
      id: map['id']?.toString() ?? '',
      farmId: map['farm_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Ação da consultoria',
      description: map['description']?.toString() ?? '',
      area: map['area']?.toString() ?? 'general',
      priority: map['priority']?.toString() ?? 'medium',
      status: map['status']?.toString() ?? 'open',
      dueAt: DateTime.tryParse(map['due_at']?.toString() ?? '')?.toLocal(),
      completedAt: DateTime.tryParse(
        map['completed_at']?.toString() ?? '',
      )?.toLocal(),
      expectedResult: map['expected_result']?.toString() ?? '',
      actualResult: map['actual_result']?.toString() ?? '',
      agendaTaskId: map['agenda_task_id']?.toString() ?? '',
      replayed: map['replayed'] == true,
    );
  }
}
