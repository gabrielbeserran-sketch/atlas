import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';

enum DrBeserraRoutinePriority {
  critical,
  high,
  normal,
  low,
}

class DrBeserraRoutineItem {
  const DrBeserraRoutineItem({
    required this.task,
    required this.priority,
    required this.overdue,
    required this.requiresTechnicalRecord,
    required this.ownerModule,
  });

  final FarmAgendaData task;
  final DrBeserraRoutinePriority priority;
  final bool overdue;
  final bool requiresTechnicalRecord;
  final String ownerModule;

  String get priorityLabel => switch (priority) {
        DrBeserraRoutinePriority.critical => 'URGENTE',
        DrBeserraRoutinePriority.high => 'ALTA',
        DrBeserraRoutinePriority.normal => 'NORMAL',
        DrBeserraRoutinePriority.low => 'BAIXA',
      };
}
