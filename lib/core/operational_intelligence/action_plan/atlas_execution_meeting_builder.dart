import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting.dart';

class AtlasExecutionMeetingBuilder {
  const AtlasExecutionMeetingBuilder();

  AtlasExecutionMeeting build({
    required List<AtlasCommandCenterAction> actions,
    String? farmName,
    DateTime? meetingAt,
  }) {
    final now = DateTime.now();
    final open = actions.where((item) => item.isOpen).toList()
      ..sort((first, second) {
        if (first.isOverdue != second.isOverdue) {
          return first.isOverdue ? -1 : 1;
        }

        return second.priority.index.compareTo(
          first.priority.index,
        );
      });

    final agenda = <String>[
      'Revisar indicadores gerais da execução.',
      if (open.any((item) => item.isOverdue))
        'Definir resposta para ações atrasadas.',
      if (open.any((item) => !item.hasResponsible))
        'Definir responsáveis para ações abertas.',
      if (open.any((item) => item.progressPercent == 0))
        'Iniciar ações ainda sem progresso.',
      ...open.take(5).map(
            (item) =>
                'Acompanhar: ${item.title}',
          ),
    ];

    return AtlasExecutionMeeting(
      id: 'execution_meeting_${now.microsecondsSinceEpoch}',
      farmName: farmName,
      createdAt: now,
      meetingAt: meetingAt ?? now,
      title: 'Reunião de execução',
      participants: const <String>[],
      summary: '',
      agendaItems: agenda,
      decisions: const [],
      closed: false,
    );
  }
}
