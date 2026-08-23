import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_daily_routine.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_language_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';

class DrBeserraDailyRoutineService {
  const DrBeserraDailyRoutineService({
    this.language = const DrBeserraLanguageService(),
  });

  final DrBeserraLanguageService language;

  List<DrBeserraRoutineItem> forDay(
    List<FarmAgendaData> tasks,
    DateTime day, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final targetKey = _dateKey(day);

    final items = tasks
        .where(
          (task) =>
              _taskDateKey(task.date) == targetKey &&
              !task.isCancelled &&
              !task.isCompleted,
        )
        .map((task) => buildItem(task, now: reference))
        .toList();

    items.sort(_compare);
    return items;
  }

  List<DrBeserraRoutineItem> overdue(
    List<FarmAgendaData> tasks, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);

    final items = tasks.where((task) {
      if (task.isCancelled || task.isCompleted) return false;
      final due = parseTaskDate(task.date);
      if (due == null) return false;
      return due.isBefore(today);
    }).map((task) => buildItem(task, now: reference)).toList();

    items.sort(_compare);
    return items;
  }

  List<DrBeserraRoutineItem> prioritiesToday(
    List<FarmAgendaData> tasks, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final items = forDay(tasks, reference, now: reference);
    final prioritized = items
        .where(
          (item) =>
              item.priority == DrBeserraRoutinePriority.critical ||
              item.priority == DrBeserraRoutinePriority.high,
        )
        .toList();

    return prioritized.isEmpty ? items.take(3).toList() : prioritized;
  }

  DrBeserraRoutineItem buildItem(
    FarmAgendaData task, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final due = parseTaskDate(task.date);
    final today = DateTime(reference.year, reference.month, reference.day);
    final isOverdue = due != null && due.isBefore(today);
    final owner = ownerModule(task);

    return DrBeserraRoutineItem(
      task: task,
      priority: priorityOf(task, overdue: isOverdue),
      overdue: isOverdue,
      requiresTechnicalRecord: requiresTechnicalRecord(task),
      ownerModule: owner,
    );
  }

  DrBeserraRoutinePriority priorityOf(
    FarmAgendaData task, {
    required bool overdue,
  }) {
    final priority = language.normalize(task.priority);
    if (overdue || priority.contains('urgent')) {
      return DrBeserraRoutinePriority.critical;
    }
    if (priority.contains('alta') || priority.contains('high')) {
      return DrBeserraRoutinePriority.high;
    }
    if (priority.contains('baixa') || priority.contains('low')) {
      return DrBeserraRoutinePriority.low;
    }
    return DrBeserraRoutinePriority.normal;
  }

  bool requiresTechnicalRecord(FarmAgendaData task) {
    final owner = ownerModule(task);
    return owner == 'Sanidade' ||
        owner == 'Reprodução' ||
        owner == 'Realizar manejo' ||
        owner == 'Nutrição' ||
        owner == 'Estoque';
  }

  String ownerModule(FarmAgendaData task) {
    final source = language.normalize(task.sourceType);
    final category = language.normalize(task.category);
    final title = language.normalize(task.title);
    final combined = '$source $category $title';

    if (_containsAny(combined, const [
      'health',
      'sanidad',
      'vacin',
      'vermifug',
      'tratament',
    ])) {
      return 'Sanidade';
    }

    if (_containsAny(combined, const [
      'reproduction',
      'reproduc',
      'iatf',
      'insemin',
      'gestacao',
    ])) {
      return 'Reprodução';
    }

    if (_containsAny(combined, const [
      'handling',
      'manejo',
      'moviment',
      'pesag',
      'lote',
    ])) {
      return 'Realizar manejo';
    }

    if (_containsAny(combined, const [
      'nutrition',
      'nutric',
      'dieta',
      'racao',
      'suplement',
    ])) {
      return 'Nutrição';
    }

    if (_containsAny(combined, const [
      'inventory',
      'estoque',
      'insumo',
    ])) {
      return 'Estoque';
    }

    return 'Agenda';
  }

  DateTime? parseTaskDate(String value) {
    final local = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (local != null) {
      final day = int.tryParse(local.group(1)!);
      final month = int.tryParse(local.group(2)!);
      final year = int.tryParse(local.group(3)!);
      if (day == null || month == null || year == null) return null;
      final parsed = DateTime(year, month, day);
      if (parsed.day != day || parsed.month != month || parsed.year != year) {
        return null;
      }
      return parsed;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final localDate = parsed.toLocal();
    return DateTime(localDate.year, localDate.month, localDate.day);
  }

  int _compare(DrBeserraRoutineItem a, DrBeserraRoutineItem b) {
    final byPriority = _priorityScore(b.priority).compareTo(
      _priorityScore(a.priority),
    );
    if (byPriority != 0) return byPriority;

    final byTime = a.task.time.compareTo(b.task.time);
    if (byTime != 0) return byTime;
    return a.task.title.compareTo(b.task.title);
  }

  int _priorityScore(DrBeserraRoutinePriority priority) => switch (priority) {
        DrBeserraRoutinePriority.critical => 4,
        DrBeserraRoutinePriority.high => 3,
        DrBeserraRoutinePriority.normal => 2,
        DrBeserraRoutinePriority.low => 1,
      };

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _taskDateKey(String value) {
    final parsed = parseTaskDate(value);
    return parsed == null ? '' : _dateKey(parsed);
  }

  bool _containsAny(String text, List<String> values) =>
      values.any(text.contains);
}
