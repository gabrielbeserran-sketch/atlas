import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_daily_routine.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_command.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_daily_routine_service.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_language_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';

FarmAgendaData task({
  required String id,
  required String title,
  required String category,
  required String date,
  String time = '',
  String responsible = '',
  String priority = 'Normal',
  String status = 'Pendente',
  String sourceType = '',
  String sourceId = '',
}) =>
    FarmAgendaData(
      id: id,
      title: title,
      category: category,
      date: date,
      time: time,
      responsible: responsible,
      priority: priority,
      status: status,
      notes: '',
      sourceType: sourceType,
      sourceId: sourceId,
    );

void main() {
  const routine = DrBeserraDailyRoutineService();
  const language = DrBeserraLanguageService();
  final now = DateTime(2026, 8, 23, 10);

  test('rotina diária ordena por prioridade e horário', () {
    final tasks = <FarmAgendaData>[
      task(
        id: '1',
        title: 'Conferir cerca',
        category: 'Manutenção',
        date: '23/08/2026',
        time: '08:00',
        priority: 'Normal',
      ),
      task(
        id: '2',
        title: 'Vacinação Recria',
        category: 'Sanidade',
        date: '23/08/2026',
        time: '14:00',
        priority: 'Alta',
      ),
      task(
        id: '3',
        title: 'Conferir cocho',
        category: 'Nutrição',
        date: '23/08/2026',
        time: '07:00',
        priority: 'Urgente',
      ),
    ];

    final items = routine.forDay(tasks, now, now: now);
    expect(items.length, 3);
    expect(items[0].task.id, '3');
    expect(items[0].priority, DrBeserraRoutinePriority.critical);
    expect(items[1].task.id, '2');
    expect(items[2].task.id, '1');
  });

  test('tarefas atrasadas viram prioridade crítica sem inventar dados', () {
    final tasks = <FarmAgendaData>[
      task(
        id: 'old',
        title: 'Visita técnica',
        category: 'Outro',
        date: '21/08/2026',
        priority: 'Baixa',
      ),
      task(
        id: 'today',
        title: 'Conferir bebedouro',
        category: 'Outro',
        date: '23/08/2026',
      ),
    ];

    final overdue = routine.overdue(tasks, now: now);
    expect(overdue.length, 1);
    expect(overdue.single.task.id, 'old');
    expect(overdue.single.priority, DrBeserraRoutinePriority.critical);
  });

  test('atividade técnica possui módulo dono e não é baixa simples', () {
    final health = routine.buildItem(
      task(
        id: 'h',
        title: 'Vacinação do lote',
        category: 'Sanidade',
        date: '23/08/2026',
      ),
      now: now,
    );
    final reproduction = routine.buildItem(
      task(
        id: 'r',
        title: 'IATF matrizes',
        category: 'Reprodução',
        date: '23/08/2026',
      ),
      now: now,
    );
    final ordinary = routine.buildItem(
      task(
        id: 'a',
        title: 'Reunião com gerente',
        category: 'Outro',
        date: '23/08/2026',
      ),
      now: now,
    );

    expect(health.requiresTechnicalRecord, isTrue);
    expect(health.ownerModule, 'Sanidade');
    expect(reproduction.requiresTechnicalRecord, isTrue);
    expect(reproduction.ownerModule, 'Reprodução');
    expect(ordinary.requiresTechnicalRecord, isFalse);
    expect(ordinary.ownerModule, 'Agenda');
  });

  test('linguagem entende atrasos, prioridade e o que falta hoje', () {
    expect(
      language.parse('o que ficou atrasado?').intent,
      DrBeserraIntent.overdueTasks,
    );
    expect(
      language.parse('qual a prioridade hoje?').intent,
      DrBeserraIntent.priorityTasksToday,
    );
    expect(
      language.parse('o que falta fazer hoje?').intent,
      DrBeserraIntent.todayTasks,
    );
  });

  test('gateway usa correspondência semântica para conclusão diária', () {
    final gateway = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_command_gateway.dart',
    ).readAsStringSync();

    expect(gateway.contains('bool _taskMatchesSubject('), isTrue);
    expect(gateway.contains('titleTokens.intersection(subjectTokens)'), isTrue);
    expect(gateway.contains('_routine.ownerModule(task)'), isTrue);
  });

  test('gateway bloqueia baixa técnica isolada e reconcilia pós-write', () {
    final gateway = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_command_gateway.dart',
    ).readAsStringSync();

    expect(
      gateway.contains('if (routineItem.requiresTechnicalRecord)'),
      isTrue,
    );
    expect(gateway.contains('_tryCompleteRelatedAgendaTask('), isTrue);
    expect(gateway.contains('relatedTaskId'), isTrue);
    expect(
      gateway.contains(
        'O registro técnico foi confirmado, mas a Agenda não confirmou',
      ),
      isTrue,
    );
    expect(
      gateway.contains('Não repita o manejo. Abra a Agenda'),
      isTrue,
    );
  });

  test('voz continua sem conhecer a rotina de escrita', () {
    final voice = File(
      'lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart',
    ).readAsStringSync();

    expect(voice.contains('FarmAgendaStorageService'), isFalse);
    expect(voice.contains('DrBeserraDailyRoutineService'), isFalse);
    expect(voice.contains('confirmOperation('), isFalse);
  });
}
