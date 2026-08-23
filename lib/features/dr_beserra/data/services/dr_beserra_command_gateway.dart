import 'package:projeto_atlas/features/dr_beserra/data/services/dr_beserra_contextual_intelligence_service.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_command.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_daily_routine.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_contextual_insight.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_daily_routine_service.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_language_service.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_operation_draft.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_operation_parser.dart';
import 'package:projeto_atlas/features/farm_handling/data/services/farm_handling_enterprise_service.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_enterprise_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';

class DrBeserraCommandGateway {
  DrBeserraCommandGateway({
    FarmAgendaStorageService? agendaService,
    AnimalEnterpriseService? animalService,
    HerdEnterpriseService? herdService,
    AnimalHealthStorageService? healthService,
    AnimalReproductionStorageService? reproductionService,
    FarmHandlingEnterpriseService? handlingService,
    DrBeserraLanguageService languageService =
        const DrBeserraLanguageService(),
    DrBeserraOperationParser operationParser =
        const DrBeserraOperationParser(),
    DrBeserraDailyRoutineService routineService =
        const DrBeserraDailyRoutineService(),
    DrBeserraContextualIntelligenceService? contextualService,
  }) : _agenda = agendaService ?? FarmAgendaStorageService(),
       _animals = animalService ?? AnimalEnterpriseService(),
       _herd = herdService ?? HerdEnterpriseService(),
       _health = healthService ?? AnimalHealthStorageService(),
       _reproduction =
           reproductionService ?? AnimalReproductionStorageService(),
       _handling = handlingService ?? FarmHandlingEnterpriseService(),
       _language = languageService,
       _operationParser = operationParser,
       _routine = routineService,
       _contextual =
           contextualService ?? DrBeserraContextualIntelligenceService();

  final FarmAgendaStorageService _agenda;
  final AnimalEnterpriseService _animals;
  final HerdEnterpriseService _herd;
  final AnimalHealthStorageService _health;
  final AnimalReproductionStorageService _reproduction;
  final FarmHandlingEnterpriseService _handling;
  final DrBeserraLanguageService _language;
  final DrBeserraOperationParser _operationParser;
  final DrBeserraDailyRoutineService _routine;
  final DrBeserraContextualIntelligenceService _contextual;

  Future<DrBeserraReply> interpret({
    required FarmData farm,
    required String text,
  }) async {
    final command = _language.parse(text);

    switch (command.intent) {
      case DrBeserraIntent.todayTasks:
        return _tasksForDay(
          farm: farm,
          day: DateTime.now(),
          dayLabel: 'Hoje',
        );

      case DrBeserraIntent.tomorrowTasks:
        final now = DateTime.now();
        return _tasksForDay(
          farm: farm,
          day: DateTime(now.year, now.month, now.day + 1),
          dayLabel: 'Amanhã',
        );

      case DrBeserraIntent.overdueTasks:
        return _overdueTasks(farm);

      case DrBeserraIntent.priorityTasksToday:
        return _priorityTasksToday(farm);

      case DrBeserraIntent.contextualAttention:
        final insight = await _contextual.attentionToday(farm);
        return DrBeserraReply(
          message: _contextualReply(insight),
          routeLabel: insight.routeLabel,
        );

      case DrBeserraIntent.matricesOverview:
        final insight = await _contextual.matricesOverview(farm);
        return DrBeserraReply(
          message: _contextualReply(insight),
          routeLabel: insight.routeLabel,
        );

      case DrBeserraIntent.worstLot:
        final insight = await _contextual.worstLot(farm);
        return DrBeserraReply(
          message: _contextualReply(insight),
          routeLabel: insight.routeLabel,
        );

      case DrBeserraIntent.financialPressure:
        final insight = await _contextual.financialPressure(farm);
        return DrBeserraReply(
          message: _contextualReply(insight),
          routeLabel: insight.routeLabel,
        );

      case DrBeserraIntent.completeTask:
        return _prepareTaskCompletion(
          farm: farm,
          subject: command.subject,
        );

      case DrBeserraIntent.openAgenda:
        return const DrBeserraReply(
          message:
              'Posso abrir a Agenda. Lá ficam os compromissos oficiais da fazenda.',
          routeLabel: 'Agenda',
        );

      case DrBeserraIntent.openHandling:
      case DrBeserraIntent.openHealth:
      case DrBeserraIntent.openReproduction:
        final operation = _operationParser.parse(
          intent: command.intent,
          rawText: command.rawText,
        );
        if (operation == null) {
          return DrBeserraReply(
            message: _navigationMessage(command.intent),
            routeLabel: _routeForIntent(command.intent),
          );
        }
        if (!operation.isComplete) {
          return DrBeserraReply(
            message:
                'Entendi a operação, mas ainda faltam: '
                '${operation.missingFields.join(', ')}. '
                '${_operationExample(operation.kind)}',
          );
        }
        return DrBeserraReply(
          message:
              'Entendi: ${operation.summary}. '
              'Confira os dados abaixo antes de gravar.',
          confirmationOperation: operation,
          confirmationOperationTitle: operation.summary,
        );

      case DrBeserraIntent.openHerd:
        return const DrBeserraReply(
          message:
              'Posso abrir o Rebanho para localizar o animal ou o lote.',
          routeLabel: 'Rebanho',
        );

      case DrBeserraIntent.openNutrition:
        return const DrBeserraReply(
          message:
              'Entendi que é um assunto de nutrição. Vou abrir Nutrição para você consultar dietas, consumo e registros oficiais.',
          routeLabel: 'Nutrição',
        );

      case DrBeserraIntent.openFinance:
        return const DrBeserraReply(
          message:
              'Entendi que é um assunto financeiro. Vou abrir Financeiro para consultar receitas, despesas, custos e resultados.',
          routeLabel: 'Financeiro',
        );

      case DrBeserraIntent.openInventory:
        return const DrBeserraReply(
          message:
              'Entendi que você quer consultar insumos ou produtos. Vou abrir Estoque.',
          routeLabel: 'Estoque',
        );

      case DrBeserraIntent.openField:
        return const DrBeserraReply(
          message:
              'Entendi que é um assunto de pasto, piquete ou área de produção. Vou abrir Campo.',
          routeLabel: 'Campo',
        );

      case DrBeserraIntent.openIntelligence:
        return const DrBeserraReply(
          message:
              'Vou abrir Inteligência para você avaliar indicadores e desempenho da fazenda.',
          routeLabel: 'Inteligência',
        );

      case DrBeserraIntent.openReports:
        return const DrBeserraReply(
          message:
              'Vou abrir Relatórios para consultar consolidações e exportações.',
          routeLabel: 'Relatórios',
        );

      case DrBeserraIntent.openConsulting:
        return const DrBeserraReply(
          message:
              'Vou abrir Consultoria. Lá fica o contato com o responsável veterinário e o atendimento técnico.',
          routeLabel: 'Consultoria',
        );

      case DrBeserraIntent.unknown:
        return const DrBeserraReply(
          message:
              'Não tive certeza do que você quis dizer. Pode falar como você falaria no dia a dia: “qual a lida de amanhã?”, “terminei vacinação”, “pesar o lote”, “ver os custos” ou “ver os indicadores”.',
        );
    }
  }

  Future<DrBeserraReply> confirmOperation({
    required FarmData farm,
    required DrBeserraOperationDraft operation,
    String relatedTaskId = '',
    String relatedTaskTitle = '',
  }) async {
    final farmId = farm.id?.trim() ?? '';
    if (farmId.isEmpty) {
      throw StateError('A fazenda ativa não possui ID oficial.');
    }
    if (!operation.isComplete) {
      throw StateError(
        'A operação ainda possui campos obrigatórios pendentes.',
      );
    }

    final technicalReply = switch (operation.kind) {
      DrBeserraOperationKind.health =>
        await _confirmHealth(farm: farm, operation: operation),
      DrBeserraOperationKind.reproduction =>
        await _confirmReproduction(farm: farm, operation: operation),
      DrBeserraOperationKind.handlingLotMovement =>
        await _confirmHandlingMovement(farm: farm, operation: operation),
    };

    if (relatedTaskId.trim().isEmpty) {
      return technicalReply;
    }

    final agendaConfirmed = await _tryCompleteRelatedAgendaTask(
      farm: farm,
      taskId: relatedTaskId,
    );

    if (!agendaConfirmed) {
      return DrBeserraReply(
        message:
            '${technicalReply.message} '
            'O registro técnico foi confirmado, mas a Agenda não confirmou '
            'a baixa de “${relatedTaskTitle.trim().isEmpty ? 'atividade relacionada' : relatedTaskTitle}”. '
            'Não repita o manejo. Abra a Agenda para reconciliar a pendência.',
        routeLabel: 'Agenda',
      );
    }

    return DrBeserraReply(
      message:
          '${technicalReply.message} '
          'A atividade “${relatedTaskTitle.trim().isEmpty ? 'relacionada' : relatedTaskTitle}” '
          'também foi concluída e confirmada na Agenda.',
    );
  }


  Future<DrBeserraReply> _confirmHealth({
    required FarmData farm,
    required DrBeserraOperationDraft operation,
  }) async {
    final context = await _resolveAnimalContext(
      farm: farm,
      tag: operation.animalTag,
    );

    final created = await _health.createRecord(
      farmName: farm.name,
      groupName: context.group.name,
      farmId: farm.id!.trim(),
      animalId: context.animal.id,
      lotId: context.animal.lotId,
      record: AnimalHealthData(
        id: '',
        type: operation.eventType,
        date: _todayDisplay(),
        product: operation.product,
        dose: operation.dose,
        responsible: operation.responsible,
        notes: 'Registrado pelo Dr. Beserra após confirmação explícita.',
      ),
    );

    if (!created.synced || created.id.trim().isEmpty) {
      throw StateError(
        'O servidor não confirmou o registro sanitário.',
      );
    }

    return DrBeserraReply(
      message:
          '${operation.eventType} do brinco ${context.animal.tag} '
          'foi registrada e confirmada na Sanidade oficial.',
    );
  }

  Future<DrBeserraReply> _confirmReproduction({
    required FarmData farm,
    required DrBeserraOperationDraft operation,
  }) async {
    final context = await _resolveAnimalContext(
      farm: farm,
      tag: operation.animalTag,
    );

    final reproductiveStatus =
        operation.eventType == 'Diagnóstico de gestação'
            ? (operation.result == 'Positivo' ? 'pregnant' : 'open')
            : '';

    final created = await _reproduction.createRecord(
      farmName: farm.name,
      groupName: context.group.name,
      animalId: context.animal.id,
      record: AnimalReproductionData(
        id: '',
        type: operation.eventType,
        date: _todayDisplay(),
        result: operation.result,
        bullOrSemen: operation.sireReference,
        responsible: operation.responsible,
        notes: 'Registrado pelo Dr. Beserra após confirmação explícita.',
        protocolName: operation.protocol,
        reproductiveStatus: reproductiveStatus,
      ),
    );

    if (!created.synced || created.id.trim().isEmpty) {
      throw StateError(
        'O servidor não confirmou o registro reprodutivo.',
      );
    }

    return DrBeserraReply(
      message:
          '${operation.eventType} do brinco ${context.animal.tag} '
          'foi registrada e confirmada na Reprodução oficial.',
    );
  }

  Future<DrBeserraReply> _confirmHandlingMovement({
    required FarmData farm,
    required DrBeserraOperationDraft operation,
  }) async {
    final farmId = farm.id!.trim();
    final results = await Future.wait<dynamic>([
      _animals.listAnimals(farmId: farmId, lotId: ''),
      _herd.listGroups(farmId),
    ]);
    final animals = results[0] as List<AnimalData>;
    final groups = results[1] as List<HerdGroupData>;

    final selected = animals.where((animal) {
      return _tagInsideRange(
        animal.tag,
        operation.earringStart,
        operation.earringEnd,
      );
    }).toList(growable: false);

    if (selected.isEmpty) {
      throw StateError(
        'Nenhum animal foi encontrado no intervalo informado.',
      );
    }

    final destination = _resolveGroupByName(
      groups,
      operation.destinationLotName,
    );
    if (selected.every((animal) => animal.lotId == destination.id)) {
      throw StateError(
        'Todos os animais selecionados já pertencem ao lote de destino.',
      );
    }

    final result = await _handling.execute(
      payload: <String, dynamic>{
        'farm_id': farmId,
        'action': 'lot_movement',
        'animal_ids': selected.map((animal) => animal.id).toList(),
        'responsible': operation.responsible,
        'notes': 'Registrado pelo Dr. Beserra após confirmação explícita.',
        'reason': 'Movimentação solicitada por conversa',
        'to_lot_id': destination.id,
      },
    );

    if (result.handlingId.trim().isEmpty ||
        result.affectedCount != selected.length) {
      throw StateError(
        'O servidor não confirmou a movimentação de todos os animais.',
      );
    }

    return DrBeserraReply(
      message:
          'Manejo confirmado: ${result.affectedCount} animal(is) '
          'movido(s) para ${destination.name}.',
    );
  }

  Future<_ResolvedAnimalContext> _resolveAnimalContext({
    required FarmData farm,
    required String tag,
  }) async {
    final farmId = farm.id?.trim() ?? '';
    final results = await Future.wait<dynamic>([
      _animals.listAnimals(farmId: farmId, lotId: ''),
      _herd.listGroups(farmId),
    ]);
    final animals = results[0] as List<AnimalData>;
    final groups = results[1] as List<HerdGroupData>;

    final normalizedTag = _language.normalize(tag).replaceAll(' ', '');
    final matches = animals.where((animal) {
      final candidate =
          _language.normalize(animal.tag).replaceAll(' ', '');
      return candidate == normalizedTag;
    }).toList(growable: false);

    if (matches.isEmpty) {
      throw StateError('Não encontrei o brinco $tag na fazenda ativa.');
    }
    if (matches.length > 1) {
      throw StateError(
        'Encontrei mais de um animal com o brinco $tag. '
        'Abra o Rebanho para corrigir a duplicidade.',
      );
    }

    final animal = matches.single;
    final group = groups.where((item) => item.id == animal.lotId).firstOrNull;
    if (group == null) {
      throw StateError(
        'O lote oficial do brinco ${animal.tag} não foi encontrado.',
      );
    }

    return _ResolvedAnimalContext(animal: animal, group: group);
  }

  HerdGroupData _resolveGroupByName(
    List<HerdGroupData> groups,
    String name,
  ) {
    final normalized = _language.normalize(name);
    final exact = groups.where(
      (group) => _language.normalize(group.name) == normalized,
    ).toList(growable: false);

    if (exact.length == 1) return exact.single;
    if (exact.length > 1) {
      throw StateError(
        'Existe mais de um lote com o nome “$name”.',
      );
    }

    final partial = groups.where((group) {
      final candidate = _language.normalize(group.name);
      return candidate.contains(normalized) || normalized.contains(candidate);
    }).toList(growable: false);

    if (partial.length == 1) return partial.single;
    if (partial.isEmpty) {
      throw StateError('Não encontrei o lote “$name” na fazenda ativa.');
    }
    throw StateError(
      'Encontrei mais de um lote parecido com “$name”. '
      'Diga o nome completo do lote.',
    );
  }

  bool _tagInsideRange(String tag, String start, String end) {
    final tagNumber = _numberFromTag(tag);
    final startNumber = _numberFromTag(start);
    final endNumber = _numberFromTag(end);

    if (tagNumber != null && startNumber != null && endNumber != null) {
      final min = startNumber < endNumber ? startNumber : endNumber;
      final max = startNumber > endNumber ? startNumber : endNumber;
      return tagNumber >= min && tagNumber <= max;
    }

    final value = _language.normalize(tag);
    final first = _language.normalize(start);
    final last = _language.normalize(end);
    final min = first.compareTo(last) <= 0 ? first : last;
    final max = first.compareTo(last) > 0 ? first : last;
    return value.compareTo(min) >= 0 && value.compareTo(max) <= 0;
  }

  int? _numberFromTag(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  String _todayDisplay() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String _navigationMessage(DrBeserraIntent intent) {
    return switch (intent) {
      DrBeserraIntent.openHealth =>
        'Entendi que é um assunto de sanidade. Vou abrir Sanidade.',
      DrBeserraIntent.openReproduction =>
        'Entendi que é um assunto de reprodução. Vou abrir Reprodução.',
      DrBeserraIntent.openHandling =>
        'Entendi que é um manejo. Vou abrir Realizar manejo.',
      _ => 'Vou abrir o módulo correspondente.',
    };
  }

  String _routeForIntent(DrBeserraIntent intent) {
    return switch (intent) {
      DrBeserraIntent.openHealth => 'Sanidade',
      DrBeserraIntent.openReproduction => 'Reprodução',
      DrBeserraIntent.openHandling => 'Realizar manejo',
      _ => '',
    };
  }

  String _operationExample(DrBeserraOperationKind kind) {
    return switch (kind) {
      DrBeserraOperationKind.health =>
        'Exemplo: “vacinar brinco 101 com aftosa dose 5 ml responsável João”.',
      DrBeserraOperationKind.reproduction =>
        'Exemplo: “fazer IATF no brinco 101 responsável João”.',
      DrBeserraOperationKind.handlingLotMovement =>
        'Exemplo: “mover brincos 100 a 120 para lote Recria responsável João”.',
    };
  }

  Future<DrBeserraReply> confirmTaskCompletion({
    required FarmData farm,
    required String taskId,
  }) async {
    final farmId = farm.id?.trim() ?? '';
    if (farmId.isEmpty) {
      throw StateError('A fazenda ativa não possui ID oficial.');
    }

    final tasks = await _agenda.loadTasks(
      farm.name,
      farmId: farmId,
    );
    final task = tasks.where((item) => item.id == taskId).firstOrNull;
    if (task == null) {
      throw StateError(
        'A tarefa não foi encontrada ao confirmar. Atualize a Agenda e tente novamente.',
      );
    }
    if (task.isCompleted) {
      return DrBeserraReply(
        message: '“${task.title}” já está concluída.',
      );
    }

    final routineItem = _routine.buildItem(task);
    if (routineItem.requiresTechnicalRecord) {
      throw StateError(
        'Essa atividade exige registro técnico em '
        '${routineItem.ownerModule} antes da baixa na Agenda.',
      );
    }

    final updated = await _agenda.updateTask(
      farmName: farm.name,
      farmId: farmId,
      task: task.copyWith(status: 'Concluída'),
    );

    if (!updated.isCompleted) {
      throw StateError(
        'O servidor não confirmou a conclusão da tarefa.',
      );
    }

    return DrBeserraReply(
      message:
          'Pronto. “${updated.title}” foi concluída e confirmada na Agenda oficial.',
    );
  }

  Future<DrBeserraReply> _tasksForDay({
    required FarmData farm,
    required DateTime day,
    required String dayLabel,
  }) async {
    final tasks = await _loadFarmTasks(farm);
    final items = _routine.forDay(tasks, day);

    if (items.isEmpty) {
      return DrBeserraReply(
        message:
            'Não encontrei compromisso pendente para ${dayLabel.toLowerCase()} na Agenda oficial.',
        routeLabel: 'Agenda',
      );
    }

    return DrBeserraReply(
      message: _routineMessage(
        title: '$dayLabel você tem ${items.length} atividade(s):',
        items: items,
      ),
    );
  }

  Future<DrBeserraReply> _overdueTasks(FarmData farm) async {
    final tasks = await _loadFarmTasks(farm);
    final items = _routine.overdue(tasks);

    if (items.isEmpty) {
      return const DrBeserraReply(
        message: 'Não encontrei atividade atrasada na Agenda oficial.',
      );
    }

    return DrBeserraReply(
      message: _routineMessage(
        title: 'Encontrei ${items.length} atividade(s) atrasada(s):',
        items: items,
      ),
    );
  }

  Future<DrBeserraReply> _priorityTasksToday(FarmData farm) async {
    final tasks = await _loadFarmTasks(farm);
    final items = _routine.prioritiesToday(tasks);

    if (items.isEmpty) {
      return const DrBeserraReply(
        message: 'Não encontrei atividade pendente para hoje.',
        routeLabel: 'Agenda',
      );
    }

    return DrBeserraReply(
      message: _routineMessage(
        title: 'Prioridade de hoje:',
        items: items,
      ),
    );
  }

  String _routineMessage({
    required String title,
    required List<DrBeserraRoutineItem> items,
  }) {
    final lines = <String>[title];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final task = item.task;
      final time = task.time.trim().isEmpty ? 'sem horário' : task.time.trim();
      final responsible = task.responsible.trim().isEmpty
          ? ''
          : ' — ${task.responsible.trim()}';
      final technical = item.requiresTechnicalRecord
          ? ' — registrar em ${item.ownerModule}'
          : '';
      lines.add(
        '${index + 1}. [${item.priorityLabel}] $time — '
        '${task.title}$responsible$technical',
      );
    }
    lines.add(
      'As prioridades vêm da Agenda oficial: atraso e prioridade cadastrada '
      'pesam mais. O Dr. Beserra não inventa urgência.',
    );
    return lines.join('\n');
  }

  Future<DrBeserraReply> _prepareTaskCompletion({
    required FarmData farm,
    required String subject,
  }) async {
    if (subject.trim().isEmpty) {
      return const DrBeserraReply(
        message:
            'Diga qual atividade terminou. Exemplo: “terminei vacinação”.',
      );
    }

    final tasks = await _loadFarmTasks(farm);
    final normalizedSubject = _language.normalize(subject);
    final candidates = tasks.where((task) {
      if (task.isCompleted || task.isCancelled) return false;
      return _taskMatchesSubject(task, normalizedSubject);
    }).toList();

    if (candidates.isEmpty) {
      return DrBeserraReply(
        message:
            'Não encontrei uma atividade pendente parecida com “$subject”. Vou abrir a Agenda para você conferir.',
        routeLabel: 'Agenda',
      );
    }

    if (candidates.length > 1) {
      final names = candidates.take(5).map((item) => '• ${item.title}').join('\n');
      return DrBeserraReply(
        message:
            'Encontrei mais de uma atividade parecida. Diga o nome com mais detalhe:\n$names',
        routeLabel: 'Agenda',
      );
    }

    final task = candidates.single;
    final routineItem = _routine.buildItem(task);

    if (!routineItem.requiresTechnicalRecord) {
      return DrBeserraReply(
        message:
            'Entendi que você terminou “${task.title}”. Confirmo a conclusão na Agenda?',
        confirmationTaskId: task.id,
        confirmationTaskTitle: task.title,
      );
    }

    final technicalIntent = _intentForOwnerModule(routineItem.ownerModule);
    if (technicalIntent == null) {
      return DrBeserraReply(
        message:
            '“${task.title}” exige registro em ${routineItem.ownerModule}. '
            'Não vou dar baixa só na Agenda porque isso criaria duas verdades. '
            'Vou abrir o módulo oficial para concluir o registro técnico.',
        routeLabel: routineItem.ownerModule,
      );
    }

    final operation = _operationParser.parse(
      intent: technicalIntent,
      rawText: subject,
    );

    if (operation == null || !operation.isComplete) {
      final missing = operation?.missingFields ?? const <String>[];
      final missingText = missing.isEmpty
          ? ''
          : ' Ainda faltam: ${missing.join(', ')}.';
      final example = operation == null
          ? _operationExampleForOwner(routineItem.ownerModule)
          : _operationExample(operation.kind);
      return DrBeserraReply(
        message:
            '“${task.title}” exige o registro técnico em ${routineItem.ownerModule} '
            'antes da baixa na Agenda.$missingText $example',
      );
    }

    return DrBeserraReply(
      message:
          'Encontrei a atividade “${task.title}” e montei o registro técnico: '
          '${operation.summary}. Se você confirmar, primeiro registro em '
          '${routineItem.ownerModule}; somente depois de o servidor confirmar '
          'eu concluo a Agenda.',
      confirmationOperation: operation,
      confirmationOperationTitle: operation.summary,
      relatedTaskId: task.id,
      relatedTaskTitle: task.title,
    );
  }

  bool _taskMatchesSubject(
    FarmAgendaData task,
    String normalizedSubject,
  ) {
    final title = _language.normalize(task.title);
    final category = _language.normalize(task.category);

    if (title.contains(normalizedSubject) ||
        normalizedSubject.contains(title) ||
        category.contains(normalizedSubject) ||
        normalizedSubject.contains(category)) {
      return true;
    }

    const ignored = <String>{
      'para',
      'com',
      'sem',
      'dos',
      'das',
      'uma',
      'lote',
      'animal',
      'animais',
      'gado',
      'hoje',
      'amanha',
    };

    final titleTokens = title
        .split(' ')
        .where(
          (token) => token.length >= 4 && !ignored.contains(token),
        )
        .toSet();

    final subjectTokens = normalizedSubject
        .split(' ')
        .where(
          (token) => token.length >= 4 && !ignored.contains(token),
        )
        .toSet();

    final overlap = titleTokens.intersection(subjectTokens);
    if (overlap.isEmpty) return false;

    final owner = _routine.ownerModule(task);
    final intent = _language.parse(normalizedSubject).intent;
    final expectedIntent = _intentForOwnerModule(owner);

    if (expectedIntent != null) {
      return intent == expectedIntent;
    }

    return true;
  }

  DrBeserraIntent? _intentForOwnerModule(String ownerModule) {
    return switch (ownerModule) {
      'Sanidade' => DrBeserraIntent.openHealth,
      'Reprodução' => DrBeserraIntent.openReproduction,
      'Realizar manejo' => DrBeserraIntent.openHandling,
      _ => null,
    };
  }

  String _operationExampleForOwner(String ownerModule) {
    return switch (ownerModule) {
      'Sanidade' =>
        'Exemplo: “terminei vacinação brinco 101 com aftosa dose 5 ml responsável João”.',
      'Reprodução' =>
        'Exemplo: “terminei IATF brinco 101 responsável João”.',
      'Realizar manejo' =>
        'Exemplo: “terminei mover brincos 100 a 120 para lote Recria responsável João”.',
      _ => 'Abra o módulo oficial e complete os dados obrigatórios.',
    };
  }

  Future<bool> _tryCompleteRelatedAgendaTask({
    required FarmData farm,
    required String taskId,
  }) async {
    try {
      final farmId = farm.id?.trim() ?? '';
      if (farmId.isEmpty) return false;

      final tasks = await _agenda.loadTasks(
        farm.name,
        farmId: farmId,
      );
      final task = tasks.where((item) => item.id == taskId).firstOrNull;
      if (task == null) return false;
      if (task.isCompleted) return true;
      if (task.isCancelled) return false;

      final updated = await _agenda.updateTask(
        farmName: farm.name,
        farmId: farmId,
        task: task.copyWith(status: 'Concluída'),
      );
      return updated.isCompleted;
    } catch (_) {
      return false;
    }
  }

  String _contextualReply(DrBeserraContextualInsight insight) {
    final sources = insight.sources.isEmpty
        ? ''
        : '\nFontes: ${insight.sources.join(', ')}.';
    final sufficiency = insight.dataSufficient
        ? ''
        : '\nDados insuficientes para uma conclusão mais forte.';
    return '${insight.title}\n${insight.message}$sources$sufficiency';
  }

  Future<List<FarmAgendaData>> _loadFarmTasks(FarmData farm) {
    final farmId = farm.id?.trim() ?? '';
    if (farmId.isEmpty) {
      throw StateError('A fazenda ativa não possui ID oficial.');
    }
    return _agenda.loadTasks(farm.name, farmId: farmId);
  }


}

class _ResolvedAnimalContext {
  const _ResolvedAnimalContext({
    required this.animal,
    required this.group,
  });

  final AnimalData animal;
  final HerdGroupData group;
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
